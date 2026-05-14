#!/usr/bin/env node
// test-mcp-server-pipeline-status.mjs — exercise the bundled stdio MCP
// (../mcp-server/pipeline-status.mjs) over the same wire Claude Code
// uses post-install: spawn it, do the JSON-RPC handshake, list tools,
// call both tools, assert shapes.
//
// Pure Node stdlib via node --test. No deps.
//
// Run:
//   node --test tests/test-mcp-server-pipeline-status.mjs

import { test } from "node:test";
import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const SERVER = join(__dirname, "..", "mcp-server", "pipeline-status.mjs");

/** Run a list of JSON-RPC requests against the server and return its responses. */
async function rpc(requests, { env = {} } = {}) {
  const child = spawn("node", [SERVER], {
    stdio: ["pipe", "pipe", "pipe"],
    env: { ...process.env, ...env },
  });
  const lines = [];
  let buffer = "";
  child.stdout.on("data", (chunk) => {
    buffer += chunk.toString("utf8");
    let nl;
    while ((nl = buffer.indexOf("\n")) >= 0) {
      const line = buffer.slice(0, nl).trim();
      buffer = buffer.slice(nl + 1);
      if (line) lines.push(JSON.parse(line));
    }
  });
  for (const req of requests) {
    child.stdin.write(JSON.stringify(req) + "\n");
  }
  child.stdin.end();
  await new Promise((resolve) => child.on("close", resolve));
  return lines;
}

test("initialize → tools/list returns the three expected tools", async () => {
  const responses = await rpc([
    {
      jsonrpc: "2.0",
      id: 1,
      method: "initialize",
      params: { protocolVersion: "2025-06-18", capabilities: {}, clientInfo: { name: "t", version: "0" } },
    },
    { jsonrpc: "2.0", method: "notifications/initialized" },
    { jsonrpc: "2.0", id: 2, method: "tools/list" },
  ]);
  const init = responses.find((r) => r.id === 1);
  assert.ok(init?.result, "initialize must return a result");
  assert.equal(init.result.serverInfo.name, "pepe-pipeline-status");
  const list = responses.find((r) => r.id === 2);
  assert.ok(list?.result, "tools/list must return a result");
  const names = list.result.tools.map((t) => t.name).sort();
  assert.deepEqual(names, ["pipeline_channels", "pipeline_state", "setup_readiness"]);
});

test("pipeline_channels returns the five-skill channel list", async () => {
  const responses = await rpc([
    {
      jsonrpc: "2.0",
      id: 1,
      method: "initialize",
      params: { protocolVersion: "2025-06-18", capabilities: {}, clientInfo: { name: "t", version: "0" } },
    },
    { jsonrpc: "2.0", method: "notifications/initialized" },
    { jsonrpc: "2.0", id: 2, method: "tools/call", params: { name: "pipeline_channels", arguments: {} } },
  ]);
  const r = responses.find((x) => x.id === 2);
  assert.ok(r?.result, "tools/call must return a result");
  const payload = JSON.parse(r.result.content[0].text);
  const ids = payload.map((c) => c.id).sort();
  assert.deepEqual(ids, ["blog", "instagram", "strategy", "veo", "x"]);
  // Each channel names the skill it backs — proves the MCP list stays in
  // lockstep with the on-disk skills/ directory.
  for (const c of payload) {
    assert.ok(c.skill, `channel ${c.id} missing skill field`);
    assert.ok(c.purpose, `channel ${c.id} missing purpose field`);
  }
});

test("setup_readiness probes all channels and returns JSON", async () => {
  // --offline so the test doesn't try to hit Google / Meta / X.
  // Empty CREDENTIALS_ROOT → every channel reports `missing` cleanly.
  const tmpCreds = mkdtempSync(join(tmpdir(), "doctor-creds-"));
  const tmpState = mkdtempSync(join(tmpdir(), "doctor-state-"));
  try {
    const responses = await rpc(
      [
        {
          jsonrpc: "2.0",
          id: 1,
          method: "initialize",
          params: { protocolVersion: "2025-06-18", capabilities: {}, clientInfo: { name: "t", version: "0" } },
        },
        { jsonrpc: "2.0", method: "notifications/initialized" },
        {
          jsonrpc: "2.0",
          id: 2,
          method: "tools/call",
          params: { name: "setup_readiness", arguments: { offline: true } },
        },
      ],
      { env: { CREDENTIALS_ROOT: tmpCreds, PEPE_PIPELINE_STATE_DIR: tmpState } },
    );
    const r = responses.find((x) => x.id === 2);
    assert.ok(r?.result, "setup_readiness must return a result");
    const payload = JSON.parse(r.result.content[0].text);
    // exit_code 1 because empty tree → not every channel `ready`.
    assert.equal(payload.exit_code, 1);
    assert.ok(Array.isArray(payload.channels));
    const ids = payload.channels.map((c) => c.channel).sort();
    // setup-doctor probes 7 channels: the 5 publishing channels + the 2
    // upstream playbook skills (brand-identity, cameo-protocol). The
    // 5 in pipeline_channels are publishing channels only.
    assert.deepEqual(ids, [
      "blog",
      "brand-identity",
      "cameo-protocol",
      "instagram",
      "strategy",
      "veo",
      "x",
    ]);
    // Veo / Instagram / X / Blog / brand-identity all report `missing` against empty creds.
    for (const ch of ["veo", "instagram", "x", "blog", "brand-identity"]) {
      const row = payload.channels.find((c) => c.channel === ch);
      assert.equal(row.status, "missing", `${ch} should be missing`);
    }
    // cameo-protocol is optional — reports `skipped-offline` when no roster.
    const cameo = payload.channels.find((c) => c.channel === "cameo-protocol");
    assert.equal(cameo.status, "skipped-offline", "cameo-protocol should be skipped-offline (optional)");
  } finally {
    rmSync(tmpCreds, { recursive: true, force: true });
    rmSync(tmpState, { recursive: true, force: true });
  }
});

test("setup_readiness with --channel narrows the probe", async () => {
  const tmpCreds = mkdtempSync(join(tmpdir(), "doctor-creds-"));
  const tmpState = mkdtempSync(join(tmpdir(), "doctor-state-"));
  try {
    const responses = await rpc(
      [
        {
          jsonrpc: "2.0",
          id: 1,
          method: "initialize",
          params: { protocolVersion: "2025-06-18", capabilities: {}, clientInfo: { name: "t", version: "0" } },
        },
        { jsonrpc: "2.0", method: "notifications/initialized" },
        {
          jsonrpc: "2.0",
          id: 2,
          method: "tools/call",
          params: { name: "setup_readiness", arguments: { offline: true, channel: "veo" } },
        },
      ],
      { env: { CREDENTIALS_ROOT: tmpCreds, PEPE_PIPELINE_STATE_DIR: tmpState } },
    );
    const r = responses.find((x) => x.id === 2);
    const payload = JSON.parse(r.result.content[0].text);
    assert.equal(payload.channels.length, 1);
    assert.equal(payload.channels[0].channel, "veo");
  } finally {
    rmSync(tmpCreds, { recursive: true, force: true });
    rmSync(tmpState, { recursive: true, force: true });
  }
});

test("pipeline_state reports the configured dir + recently-touched files", async () => {
  const dir = mkdtempSync(join(tmpdir(), "pipe-state-"));
  try {
    mkdirSync(join(dir, "sub"));
    writeFileSync(join(dir, "alpha.txt"), "a");
    writeFileSync(join(dir, "beta.txt"), "bb");
    writeFileSync(join(dir, "sub", "ignored.txt"), "(subdir is not walked)");
    const responses = await rpc(
      [
        {
          jsonrpc: "2.0",
          id: 1,
          method: "initialize",
          params: {
            protocolVersion: "2025-06-18",
            capabilities: {},
            clientInfo: { name: "t", version: "0" },
          },
        },
        { jsonrpc: "2.0", method: "notifications/initialized" },
        { jsonrpc: "2.0", id: 2, method: "tools/call", params: { name: "pipeline_state", arguments: { limit: 5 } } },
      ],
      { env: { PEPE_PIPELINE_STATE_DIR: dir } },
    );
    const r = responses.find((x) => x.id === 2);
    assert.ok(r?.result, "tools/call must return a result");
    const payload = JSON.parse(r.result.content[0].text);
    assert.equal(payload.dir, dir);
    assert.equal(payload.exists, true);
    const names = payload.files.map((f) => f.name).sort();
    assert.deepEqual(names, ["alpha.txt", "beta.txt"]);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test("pipeline_state with missing dir reports exists=false (no crash)", async () => {
  const responses = await rpc(
    [
      {
        jsonrpc: "2.0",
        id: 1,
        method: "initialize",
        params: { protocolVersion: "2025-06-18", capabilities: {}, clientInfo: { name: "t", version: "0" } },
      },
      { jsonrpc: "2.0", method: "notifications/initialized" },
      { jsonrpc: "2.0", id: 2, method: "tools/call", params: { name: "pipeline_state", arguments: {} } },
    ],
    { env: { PEPE_PIPELINE_STATE_DIR: "/does-not-exist/anywhere" } },
  );
  const r = responses.find((x) => x.id === 2);
  const payload = JSON.parse(r.result.content[0].text);
  assert.equal(payload.exists, false);
  assert.deepEqual(payload.files, []);
});

test("unknown tool returns -32601", async () => {
  const responses = await rpc([
    {
      jsonrpc: "2.0",
      id: 1,
      method: "initialize",
      params: { protocolVersion: "2025-06-18", capabilities: {}, clientInfo: { name: "t", version: "0" } },
    },
    { jsonrpc: "2.0", method: "notifications/initialized" },
    { jsonrpc: "2.0", id: 2, method: "tools/call", params: { name: "no-such-tool", arguments: {} } },
  ]);
  const r = responses.find((x) => x.id === 2);
  assert.ok(r?.error, "unknown tool must produce a JSON-RPC error");
  assert.equal(r.error.code, -32601);
});
