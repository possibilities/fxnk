import { resolve } from "node:path";

// Inventory the carried root E2E tests: every test in a root E2E owner whose
// text differs from the captured upstream. Upstream's own unchanged tests are
// hosted-CI observability; a test the fork added or edited is the fork's to
// prove locally. Output is one tab-separated line per owner:
//   <file>\t<count>\t<bun --test-name-pattern regex>
// The count is the number of carried tests the pattern must select; the gate
// requires exactly that many executions so a pattern that matches more or
// fewer tests fails closed.
// Two modes share one inventory:
//   carried-e2e-tests.ts <fx-worktree> <upstream-sha>
//     prints the carried inventory, one owner per line
//   carried-e2e-tests.ts verify <fx-worktree> <upstream-sha> <owner> <junit.xml>
//     proves that owner's bun junit report executed and passed every carried
//     test by name; an extra upstream test the pattern also selected must pass
//     too, and a carried test the report never executed fails closed.
const verifyMode = process.argv[2] === "verify";
const [worktreeArg, upstreamSha, verifyOwner, verifyReport] = process.argv.slice(verifyMode ? 3 : 2);
if (!worktreeArg || !/^[0-9a-f]{40}$/.test(upstreamSha ?? "") || (verifyMode && (!verifyOwner || !verifyReport))) {
  throw new Error(
    "usage: carried-e2e-tests.ts <fx-worktree> <upstream-sha> | verify <fx-worktree> <upstream-sha> <owner> <junit.xml>",
  );
}
const worktree = resolve(worktreeArg);

function git(args: string[]): { code: number; stdout: string } {
  const result = Bun.spawnSync(["git", "-C", worktree, ...args], { stdout: "pipe", stderr: "pipe" });
  return { code: result.exitCode, stdout: result.stdout.toString() };
}

// A test starts at `test(`, `it(`, or an owner's wrapper such as `tmuxTest(`
// or `serialTest(`, with an optional `.skipIf(...)`, `.each(...)`, `.only`,
// `.todo`, or `.skip` modifier, followed by its string or template name. A
// test's text runs to the next test start, so a change inside a test body
// marks that test as carried, while a change only to an owner's shared
// helpers marks every test in the owner.
const start =
  /(?<![\w.$])(?:test|it|[A-Za-z_][A-Za-z0-9_]*Test)(?:\.(?:skipIf|todoIf|each|only|skip|todo)(?:\([^()]*(?:\([^()]*\)[^()]*)*\))?)?\(\s*(["'`])((?:\\.|(?!\1)[^\\])*)\1/g;

type Entry = { name: string; template: boolean; text: string };

function inventory(source: string): Entry[] {
  const found: { index: number; name: string; template: boolean }[] = [];
  for (const match of source.matchAll(start)) {
    found.push({ index: match.index, name: match[2], template: match[1] === "`" });
  }
  return found.map((entry, position) => ({
    name: entry.name,
    template: entry.template,
    text: source.slice(entry.index, found[position + 1]?.index ?? source.length),
  }));
}

function escapeRegex(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

// bun matches the pattern against a test's full label: its describe names and
// its own name joined by single spaces. The pattern anchors on the label's end
// and on the space before the name, never on the label's start. A template
// name selects by its literal parts; each `${...}` matches any text.
function namePattern(entry: Entry): string {
  const body = entry.template
    ? entry.name.split(/\$\{[^}]*\}/).map(escapeRegex).join(".*")
    : escapeRegex(entry.name);
  return `(?:^| )${body}$`;
}

const listing = git(["ls-files", "--", "tests/e2e/*.test.ts"]);
if (listing.code !== 0) throw new Error("could not list root E2E owners");
const files = listing.stdout.split("\n").filter((line) => /^tests\/e2e\/[A-Za-z0-9._-]+\.test\.ts$/.test(line)).sort();
if (files.length === 0) throw new Error("no root E2E test owners found");

const lines: string[] = [];
const carriedByFile = new Map<string, Entry[]>();
let carried = 0;
for (const file of files) {
  if (verifyMode && file !== verifyOwner) continue;
  const currentText = await Bun.file(resolve(worktree, file)).text();
  const current = inventory(currentText);
  const upstream = git(["show", `${upstreamSha}:${file}`]);
  if (upstream.code === 0 && upstream.stdout === currentText) continue;
  if (current.length === 0) {
    throw new Error(`${file} differs from upstream but declares no test the inventory can name`);
  }
  const baseline = new Map<string, string[]>();
  if (upstream.code === 0) {
    for (const entry of inventory(upstream.stdout)) {
      const texts = baseline.get(entry.name) ?? [];
      texts.push(entry.text);
      baseline.set(entry.name, texts);
    }
  }
  const patterns = new Set<string>();
  const carriedEntries: Entry[] = [];
  for (const entry of current) {
    const texts = baseline.get(entry.name);
    const unchanged = texts !== undefined && texts.some((text) => text === entry.text);
    if (unchanged) continue;
    carriedEntries.push(entry);
    patterns.add(namePattern(entry));
  }
  if (carriedEntries.length === 0) {
    // The owner differs only outside its tests: shared helpers or fixtures
    // every test depends on. The whole owner is carried.
    for (const entry of current) {
      carriedEntries.push(entry);
      patterns.add(namePattern(entry));
    }
  }
  carriedByFile.set(file, carriedEntries);
  // Every entry sharing a name with a carried one is selected by the same
  // pattern, so the required count is the number of current entries the
  // selected patterns match, which the fail-closed count check re-verifies.
  const selected = current.filter((entry) => [...patterns].some((pattern) => new RegExp(pattern).test(entry.name)));
  carried += selected.length;
  lines.push(`${file}\t${selected.length}\t${[...patterns].join("|")}`);
}
if (carried === 0) throw new Error("no carried root E2E tests differ from upstream");

if (!verifyMode) {
  console.log(lines.join("\n"));
  console.error(`CARRIED-E2E ${carried} tests in ${lines.length} owners differ from upstream ${upstreamSha.slice(0, 12)}`);
  process.exit(0);
}

// Verify mode: bun's junit report lists every test of the owner; a test the
// name pattern did not select carries a <skipped/> child, a failing one a
// <failure/> or <error/> child. A carried test must appear executed and clean.
function unescapeXml(value: string): string {
  return value.replace(/&(quot|apos|lt|gt|amp|#(\d+));/g, (_, entity: string, code?: string) => {
    if (code) return String.fromCodePoint(Number(code));
    return { quot: '"', apos: "'", lt: "<", gt: ">", amp: "&" }[entity] ?? "";
  });
}
const report = await Bun.file(resolve(verifyReport)).text();
const executed: string[] = [];
let failed = 0;
for (const match of report.matchAll(/<testcase\b([^>]*?)(\/>|>([\s\S]*?)<\/testcase>)/g)) {
  const name = /\bname="([^"]*)"/.exec(match[1])?.[1];
  if (name === undefined) throw new Error(`${verifyReport}: a testcase has no name`);
  const body = match[3] ?? "";
  if (/<skipped\b/.test(body)) continue;
  if (/<(failure|error)\b/.test(body)) failed += 1;
  executed.push(unescapeXml(name));
}
const entries = carriedByFile.get(verifyOwner);
if (!entries || entries.length === 0) throw new Error(`${verifyOwner} carries no test to verify`);
const missing: string[] = [];
for (const entry of entries) {
  const bare = new RegExp(`^${namePattern(entry).slice("(?:^| )".length)}`);
  if (!executed.some((name) => bare.test(name))) missing.push(entry.name);
}
if (failed > 0) throw new Error(`${verifyOwner}: ${failed} executed test(s) failed`);
if (executed.length === 0) throw new Error(`${verifyOwner}: the report executed no test`);
if (missing.length > 0) {
  throw new Error(`${verifyOwner}: ${missing.length} carried test(s) never executed:\n  ${missing.join("\n  ")}`);
}
console.log(`CARRIED-E2E-VERIFIED ${verifyOwner} executed=${executed.length} carried=${entries.length}`);
