import { readdirSync } from "node:fs";
import { resolve } from "node:path";

// Compile without evaluating modules: even excluded/live tests must remain
// syntactically valid and their local imports must resolve.
const root = resolve(process.argv[2] ?? ".");
const directory = resolve(root, "tests/e2e");
const entrypoints = readdirSync(directory)
  .filter((name) => name.endsWith(".test.ts"))
  .sort()
  .map((name) => resolve(directory, name));
if (entrypoints.length === 0) throw new Error("no root E2E test owners found");
const result = await Bun.build({
  entrypoints,
  target: "bun",
  packages: "external",
  write: false,
});
if (!result.success) throw new AggregateError(result.logs, "E2E structure does not compile");

// Use the upstream owners of these distinct manifests. One shard plan checks
// membership for the entire suite, without running any test or training PGSO.
for (const [cwd, cmd] of [
  [directory, [process.execPath, "ci-shards.ts", "--shard-count", "4", "--shard-index", "0"]],
  [root, ["python3", "-m", "scripts.pgso.corpus", "--manifest", "scripts/pgso/corpus.json", "--list"]],
] as const) {
  const check = Bun.spawnSync([...cmd], { cwd, stdout: "pipe", stderr: "pipe" });
  if (check.exitCode !== 0) {
    process.stderr.write(check.stdout);
    process.stderr.write(check.stderr);
    throw new Error(`${cmd.join(" ")} exited ${check.exitCode}`);
  }
}
console.log(`E2E-STRUCTURE ${entrypoints.length} owners parsed; shard and PGSO membership valid`);
