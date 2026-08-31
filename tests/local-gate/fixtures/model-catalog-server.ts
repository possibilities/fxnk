import { appendFileSync, renameSync, unlinkSync, writeFileSync } from "node:fs";

function requiredArgument(name: string): string {
  const index = process.argv.indexOf(name);
  const value = index === -1 ? undefined : process.argv[index + 1];
  if (!value) throw new Error(`${name} is required`);
  return value;
}

const readyFile = requiredArgument("--ready-file");
const requestsFile = requiredArgument("--requests-file");
const body = JSON.stringify({
  models: [{
    slug: "gpt-5.6-sol",
    visibility: "list",
    supported_in_api: true,
    supported_reasoning_levels: [{ effort: "high" }, { effort: "low" }],
    additional_speed_tiers: [],
    input_modalities: ["text"],
    context_window: 272000,
  }, {
    slug: "gpt-5.4-mini",
    visibility: "list",
    supported_in_api: true,
    supported_reasoning_levels: [{ effort: "low" }],
    additional_speed_tiers: [],
    input_modalities: ["text"],
    context_window: 128000,
  }],
});

const server = Bun.serve({
  hostname: "127.0.0.1",
  port: 0,
  fetch(request) {
    const url = new URL(request.url);
    if (request.method !== "GET" || url.pathname !== "/models") {
      return new Response("not found", { status: 404 });
    }
    appendFileSync(requestsFile, "GET /models\n", { mode: 0o600 });
    return new Response(body, {
      headers: { "content-type": "application/json" },
    });
  },
});

const readyTemp = `${readyFile}.${process.pid}.tmp`;
try {
  writeFileSync(readyTemp, `${server.port}\n`, { mode: 0o600 });
  renameSync(readyTemp, readyFile);
} catch (error) {
  try {
    unlinkSync(readyTemp);
  } catch {
    // The write may have failed before the temporary file existed.
  }
  throw error;
}

await new Promise<void>((resolve) => {
  process.once("SIGINT", resolve);
  process.once("SIGTERM", resolve);
});
server.stop(true);
