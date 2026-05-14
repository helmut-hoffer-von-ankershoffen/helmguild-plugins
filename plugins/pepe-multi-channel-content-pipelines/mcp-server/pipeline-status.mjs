#!/usr/bin/env node
// pipeline-status.mjs — bundled stdio MCP server shipped with the Pepe
// multi-channel-content-pipelines plugin.
//
// Demonstrates the AgentSkills + Claude Code plugin pattern of shipping
// a small purpose-built MCP server inside a plugin: the plugin's
// `.mcp.json` registers this script as a stdio MCP, and the runtime
// (Claude Code / Desktop) spawns it on plugin activation. The skills
// in this plugin can then call its tools without an out-of-band setup
// step.
//
// Tools exposed:
//   - pipeline_state   → summary of the configured pipeline-state dir
//   - pipeline_channels → static list of channels Pepe operates on
//
// Zero dependencies (pure stdlib). Implements the bare minimum of the
// MCP 2025-06-18 protocol over stdio:
//   - initialize / initialized
//   - tools/list
//   - tools/call
//
// State path is read from $PEPE_PIPELINE_STATE_DIR; nothing is written.

import { readFile, readdir, stat } from "node:fs/promises";
import { join } from "node:path";
import { homedir } from "node:os";
import { createInterface } from "node:readline";

const PROTOCOL_VERSION = "2025-06-18";
const SERVER_NAME = "pepe-pipeline-status";
const SERVER_VERSION = "0.1.0";

const CHANNELS = [
  { id: "instagram", purpose: "Reels + grid posts; reach + lifestyle" },
  { id: "x", purpose: "Threads + short takes; community" },
  { id: "website", purpose: "Long-form essays + manifesto" },
  { id: "youtube", purpose: "Long-form video + retention" },
];

function stateDir() {
  return process.env.PEPE_PIPELINE_STATE_DIR || join(homedir(), ".openclaw", "state", "instagram-media");
}

async function pipelineState(limit = 10) {
  const dir = stateDir();
  let exists = true;
  try {
    const st = await stat(dir);
    if (!st.isDirectory()) exists = false;
  } catch {
    exists = false;
  }
  if (!exists) {
    return { dir, exists: false, files: [], note: "Pipeline state dir is absent or unconfigured." };
  }
  const entries = await readdir(dir, { withFileTypes: true });
  const files = [];
  for (const e of entries) {
    if (!e.isFile()) continue;
    const path = join(dir, e.name);
    const st = await stat(path);
    files.push({ name: e.name, size: st.size, mtime: st.mtimeMs });
  }
  files.sort((a, b) => b.mtime - a.mtime);
  return {
    dir,
    exists: true,
    files: files.slice(0, limit).map((f) => ({
      name: f.name,
      size: f.size,
      mtime_iso: new Date(f.mtime).toISOString(),
    })),
    total_files: files.length,
  };
}

const TOOLS = [
  {
    name: "pipeline_state",
    description:
      "Snapshot of the configured content-pipeline state directory (filenames + sizes, no contents). Reads $PEPE_PIPELINE_STATE_DIR; safe / read-only.",
    inputSchema: {
      type: "object",
      properties: {
        limit: { type: "integer", description: "Max items to return (default 10).", default: 10, minimum: 1, maximum: 100 },
      },
    },
  },
  {
    name: "pipeline_channels",
    description: "List the channels Pepe operates content pipelines for (static; no I/O).",
    inputSchema: { type: "object", properties: {} },
  },
];

function send(msg) {
  process.stdout.write(JSON.stringify(msg) + "\n");
}

function reply(id, result) {
  send({ jsonrpc: "2.0", id, result });
}
function replyError(id, code, message) {
  send({ jsonrpc: "2.0", id, error: { code, message } });
}

async function handle(req) {
  const { id, method, params } = req;
  try {
    switch (method) {
      case "initialize":
        reply(id, {
          protocolVersion: PROTOCOL_VERSION,
          serverInfo: { name: SERVER_NAME, version: SERVER_VERSION },
          capabilities: { tools: {} },
        });
        return;
      case "notifications/initialized":
        return; // notification, no reply
      case "tools/list":
        reply(id, { tools: TOOLS });
        return;
      case "tools/call": {
        const name = params?.name;
        const args = params?.arguments || {};
        if (name === "pipeline_state") {
          const result = await pipelineState(args.limit ?? 10);
          reply(id, { content: [{ type: "text", text: JSON.stringify(result, null, 2) }] });
          return;
        }
        if (name === "pipeline_channels") {
          reply(id, { content: [{ type: "text", text: JSON.stringify(CHANNELS, null, 2) }] });
          return;
        }
        replyError(id, -32601, `unknown tool: ${name}`);
        return;
      }
      case "ping":
        reply(id, {});
        return;
      default:
        if (id != null) replyError(id, -32601, `method not found: ${method}`);
    }
  } catch (e) {
    if (id != null) replyError(id, -32603, String(e?.message || e));
  }
}

async function main() {
  const rl = createInterface({ input: process.stdin });
  // Track in-flight handlers so a stdin-close doesn't terminate the
  // process before pending async work (filesystem reads, mostly) has
  // flushed its responses to stdout.
  const inflight = new Set();
  rl.on("line", (line) => {
    line = line.trim();
    if (!line) return;
    let req;
    try {
      req = JSON.parse(line);
    } catch {
      return;
    }
    const p = handle(req).finally(() => inflight.delete(p));
    inflight.add(p);
  });
  rl.on("close", async () => {
    await Promise.allSettled([...inflight]);
    process.exit(0);
  });
}

main();
