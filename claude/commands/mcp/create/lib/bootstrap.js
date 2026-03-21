#!/usr/bin/env node

/**
 * MCP Bootstrap — Hot-reloadable MCP server loader.
 *
 * This file is the entry point. It stays alive and never changes.
 * Tool implementations live in a separate module that gets swapped
 * on _reload without breaking the stdio pipe.
 *
 * ~/.claude.json entry:
 *   "server-name": {
 *     "type": "stdio",
 *     "command": "node",
 *     "args": ["/path/to/this/bootstrap.js"]
 *   }
 */

import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { execSync } from "child_process";
import { readFileSync, existsSync } from "fs";
import { join, dirname } from "path";
import { fileURLToPath, pathToFileURL } from "url";

const __dir = dirname(fileURLToPath(import.meta.url));
const pkg = JSON.parse(readFileSync(join(__dir, "package.json"), "utf8"));

const server = new McpServer({
  name: pkg.name,
  version: pkg.version || "1.0.0",
});

// ── Env Loading ──────────────────────────────────────────────────────

function loadEnv() {
  const envPath = join(__dir, ".env");
  if (!existsSync(envPath)) return;
  const content = readFileSync(envPath, "utf8");
  for (const line of content.split("\n")) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;
    const eq = trimmed.indexOf("=");
    if (eq === -1) continue;
    const key = trimmed.slice(0, eq).trim();
    const val = trimmed.slice(eq + 1).trim().replace(/^["']|["']$/g, "");
    process.env[key] = val;
  }
}

// ── Tool Loading ─────────────────────────────────────────────────────

// Shared state — persists across reloads. Tools modules can export an
// init(shared) function to receive this object. Use it for runtime state
// that should survive a _reload (e.g., session cookies, auth tokens).
const shared = {};
const state = { handlers: {} };

async function loadTools() {
  // Build if TypeScript project
  if (existsSync(join(__dir, "tsconfig.json"))) {
    try {
      execSync("npm run build", { cwd: __dir, stdio: "pipe" });
    } catch (err) {
      const msg = err.stderr?.toString() || err.message;
      console.error("Build failed:", msg);
      return `Build failed: ${msg}`;
    }
  }

  // Resolve tools module — dist/tools.js (TS) or tools.js (JS)
  const distTools = join(__dir, "dist", "tools.js");
  const rootTools = join(__dir, "tools.js");
  const toolsPath = existsSync(distTools) ? distTools : rootTools;

  if (!existsSync(toolsPath)) {
    return `Tools module not found at ${toolsPath}`;
  }

  // Dynamic import with cache-bust (new URL each reload)
  const url = pathToFileURL(toolsPath).href + "?v=" + Date.now();
  const mod = await import(url);

  // Pass shared state to tools module if it exports init()
  if (typeof mod.init === "function") mod.init(shared);

  state.handlers = mod.default || mod;
  return null;
}

// ── Startup ──────────────────────────────────────────────────────────

async function main() {
  loadEnv();

  const err = await loadTools();
  if (err) {
    console.error(err);
    process.exit(1);
  }

  // Register tools with indirection — handlers swapped on reload
  for (const [name, def] of Object.entries(state.handlers)) {
    server.tool(name, def.description, def.schema || {}, async (params) => {
      return state.handlers[name].handler(params);
    });
  }

  // Built-in reload tool
  server.tool(
    "_reload",
    "Hot-reload server code and environment variables. Call after editing source files.",
    {},
    async () => {
      loadEnv();
      const err = await loadTools();
      if (err) return { content: [{ type: "text", text: err }], isError: true };
      return {
        content: [
          {
            type: "text",
            text: `Reloaded ${Object.keys(state.handlers).length} tools. Env vars refreshed.`,
          },
        ],
      };
    }
  );

  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error(`${pkg.name} running on stdio`);
}

main().catch((err) => {
  console.error("Fatal:", err);
  process.exit(1);
});
