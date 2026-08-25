import { cp, mkdir, readFile, readdir, rm, writeFile } from "node:fs/promises";
import { execFile } from "node:child_process";
import path from "node:path";
import { promisify } from "node:util";
import { pathToFileURL } from "node:url";

const root = process.cwd();
const output = path.join(root, "wiki-dist");
const outputAssets = path.join(output, "assets");
const workerUrl = pathToFileURL(path.join(root, "dist/server/index.js"));
workerUrl.searchParams.set("bundle", Date.now().toString());
const run = promisify(execFile);

const { default: worker } = await import(workerUrl.href);
const response = await worker.fetch(
  new Request("http://localhost/", { headers: { accept: "text/html" } }),
  {
    ASSETS: {
      fetch: async () => new Response("Not found", { status: 404 }),
    },
  },
  {
    waitUntil() {},
    passThroughOnException() {},
  },
);

if (!response.ok) {
  throw new Error(`Unable to render the site for the wiki: HTTP ${response.status}`);
}

const rendered = await response.text();
const { stdout: revisionOutput } = await run("git", ["rev-parse", "HEAD"], {
  cwd: path.resolve(root, ".."),
});
const workshopRevision = revisionOutput.trim();
const portable = rendered
  .replaceAll("/assets/", "./assets/")
  .replace(
    "</head>",
    `<meta name="artifact-source-revision" content="${workshopRevision}" /></head>`,
  );

if (portable.includes('="/assets/')) {
  throw new Error("The rendered page still contains root-relative asset paths.");
}

await rm(output, { recursive: true, force: true });
await mkdir(output, { recursive: true });
await cp(path.join(root, "dist/client/assets"), outputAssets, {
  recursive: true,
});

async function makeAssetPathsPortable(directory) {
  for (const entry of await readdir(directory, { withFileTypes: true })) {
    const target = path.join(directory, entry.name);
    if (entry.isDirectory()) {
      await makeAssetPathsPortable(target);
      continue;
    }
    if (!/\.(?:css|js|json)$/.test(entry.name)) continue;

    const contents = await readFile(target, "utf8");
    const rewritten = contents.replaceAll("/assets/", "./");
    if (rewritten !== contents) await writeFile(target, rewritten, "utf8");
  }
}

await makeAssetPathsPortable(outputAssets);
await writeFile(path.join(output, "index.html"), portable, "utf8");

console.log(`Wiki bundle ready: ${output}`);
