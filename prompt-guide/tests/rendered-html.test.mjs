import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

const developmentPreviewMeta =
  /<meta(?=[^>]*\bname=["']codex-preview["'])(?=[^>]*\bcontent=["']development["'])[^>]*>/i;

async function render() {
  const workerUrl = new URL("../dist/server/index.js", import.meta.url);
  workerUrl.searchParams.set("test", `${process.pid}-${Date.now()}`);
  const { default: worker } = await import(workerUrl.href);

  return worker.fetch(
    new Request("http://localhost/", {
      headers: { accept: "text/html" },
    }),
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
}

test("server-renders the Fx Prompt Field Guide", async () => {
  const response = await render();
  assert.equal(response.status, 200);
  assert.match(response.headers.get("content-type") ?? "", /^text\/html\b/i);

  const html = await response.text();
  assert.match(html, /<title>Fx Prompt Field Guide<\/title>/i);
  assert.match(html, /Read the rules/);
  assert.match(html, /The policy microscope/);
  assert.match(html, /<button class="primary-link" type="button">Open the prompt/i);
  assert.match(html, /Tool results are evidence, not instructions\./);
  assert.match(html, /Four knots worth debating\./);
  assert.match(html, /src\/builtins\/context\.zig/);
  assert.match(html, /309a0e5ae420a625cb4ec6f77250f9f234284edf/);
  assert.doesNotMatch(html, developmentPreviewMeta);
  assert.doesNotMatch(html, /href="#(?:top|reader|identity|workspace|routing|interaction|safety|verification)"/);
  assert.doesNotMatch(html, /Your site is taking shape|react-loading-skeleton/);
});

test("removes starter-only code and metadata", async () => {
  const [page, layout, packageJson] = await Promise.all([
    readFile(new URL("../app/page.tsx", import.meta.url), "utf8"),
    readFile(new URL("../app/layout.tsx", import.meta.url), "utf8"),
    readFile(new URL("../package.json", import.meta.url), "utf8"),
  ]);

  assert.doesNotMatch(page, /_sites-preview|SkeletonPreview|codex-preview/);
  assert.match(page, /scrollToSection\("reader"\)/);
  assert.doesNotMatch(layout, /Starter Project|codex-preview|_sites-preview/);
  assert.doesNotMatch(packageJson, /react-loading-skeleton/);
  assert.match(packageJson, /"name": "fx-prompt-field-guide"/);
});
