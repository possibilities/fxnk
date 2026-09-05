import { resolve } from "node:path";

// Inventory the carried root E2E tests: every test in a root E2E owner whose
// text differs from the captured upstream. Upstream's own unchanged tests are
// hosted-CI observability; a test the fork added or edited is the fork's to
// prove locally. Output is one tab-separated line per owner:
//   <file>\t<count>\t<bun --test-name-pattern regex>
// The count is the number of carried tests the pattern must select; the gate
// requires exactly that many executions so a pattern that matches more or
// fewer tests fails closed.
const [worktreeArg, upstreamSha] = process.argv.slice(2);
if (!worktreeArg || !/^[0-9a-f]{40}$/.test(upstreamSha ?? "")) {
  throw new Error("usage: carried-e2e-tests.ts <fx-worktree> <upstream-sha>");
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

// A template name selects by its literal parts; each `${...}` matches any text.
function namePattern(entry: Entry): string {
  if (!entry.template) return `^${escapeRegex(entry.name)}$`;
  const parts = entry.name.split(/\$\{[^}]*\}/).map(escapeRegex);
  return `^${parts.join(".*")}$`;
}

const listing = git(["ls-files", "--", "tests/e2e/*.test.ts"]);
if (listing.code !== 0) throw new Error("could not list root E2E owners");
const files = listing.stdout.split("\n").filter((line) => /^tests\/e2e\/[A-Za-z0-9._-]+\.test\.ts$/.test(line)).sort();
if (files.length === 0) throw new Error("no root E2E test owners found");

const lines: string[] = [];
let carried = 0;
for (const file of files) {
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
  let count = 0;
  for (const entry of current) {
    const texts = baseline.get(entry.name);
    const unchanged = texts !== undefined && texts.some((text) => text === entry.text);
    if (unchanged) continue;
    count += 1;
    patterns.add(namePattern(entry));
  }
  if (count === 0) {
    // The owner differs only outside its tests: shared helpers or fixtures
    // every test depends on. The whole owner is carried.
    for (const entry of current) patterns.add(namePattern(entry));
  }
  // Every entry sharing a name with a carried one is selected by the same
  // pattern, so the required count is the number of current entries the
  // selected patterns match, which the fail-closed count check re-verifies.
  const selected = current.filter((entry) => [...patterns].some((pattern) => new RegExp(pattern).test(entry.name)));
  carried += selected.length;
  lines.push(`${file}\t${selected.length}\t${[...patterns].join("|")}`);
}
if (carried === 0) throw new Error("no carried root E2E tests differ from upstream");
console.log(lines.join("\n"));
console.error(`CARRIED-E2E ${carried} tests in ${lines.length} owners differ from upstream ${upstreamSha.slice(0, 12)}`);
