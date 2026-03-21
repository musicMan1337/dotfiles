---
name: mcp:create
model: opus
description: Scaffold a new MCP server with hot-reload bootstrap. Triggers on: new mcp, create mcp, scaffold mcp, make an mcp server, build an mcp
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

# Create MCP Server

Scaffold a new MCP server project using the hot-reload bootstrap pattern. Every server you create will have a built-in `_reload` tool that swaps in new code and env vars without breaking the stdio pipe.

## Arguments

The user should provide:
- **name** — server name (e.g., `mcp-myservice`). Will be used as the directory name and package name.
- **language** — `ts` (TypeScript, default) or `js` (plain JavaScript)
- **location** — where to create it (default: `~/code/mcp/`)
- **tools** — description of what tools the server should expose

If any info is missing, ask. If the user describes what the MCP should do, infer the tool names and shapes from their description.

## Architecture

Every MCP server has two layers:

1. **`bootstrap.js`** — The entry point. Creates the McpServer, loads env, dynamically imports the tools module, registers tools with indirection, and exposes `_reload`. **This file never changes after scaffolding.**

2. **`tools.js` / `src/tools.ts`** — All tool definitions. This is what developers edit. On `_reload`, the bootstrap re-imports this module and swaps the handler references.

The bootstrap template lives at:
`!cat ~/.claude/commands/mcp/create/lib/bootstrap.js`

**Copy it verbatim** to new projects. Do not modify it unless the user asks.

## Tools Module Format

The tools module must export a default object where each key is a tool name and each value has `description`, `schema`, and `handler`:

### TypeScript (`src/tools.ts`):
```typescript
import { z } from "zod";

export default {
  "myserver_action": {
    description: "Does something useful",
    schema: {
      param1: z.string().describe("A required parameter"),
      param2: z.number().optional().describe("An optional parameter"),
    },
    handler: async ({ param1, param2 }: { param1: string; param2?: number }) => {
      // Implementation here
      return {
        content: [{ type: "text", text: `Result: ${param1}` }],
      };
    },
  },
};
```

### JavaScript (`tools.js`):
```javascript
import { z } from "zod";

export default {
  "myserver_action": {
    description: "Does something useful",
    schema: {
      param1: z.string().describe("A required parameter"),
    },
    handler: async ({ param1 }) => ({
      content: [{ type: "text", text: `Result: ${param1}` }],
    }),
  },
};
```

## Scaffolding Steps

### 1. Create project directory

```
~/code/mcp/mcp-{name}/
```

### 2. Copy bootstrap.js

Copy from `~/.claude/commands/mcp/create/lib/bootstrap.js` to the project root. Do not modify.

### 3. Generate package.json

```json
{
  "name": "mcp-{name}",
  "version": "1.0.0",
  "type": "module",
  "bin": "bootstrap.js",
  "scripts": {
    "build": "npx tsc",
    "start": "node bootstrap.js"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.12.1",
    "zod": "^3.23.0"
  },
  "devDependencies": {
    "@types/node": "^22.0.0",
    "typescript": "^5.7.0"
  }
}
```

For JS projects, remove `devDependencies`, `build` script, and TypeScript deps.

### 4. Generate tsconfig.json (TypeScript only)

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "Node16",
    "moduleResolution": "Node16",
    "outDir": "dist",
    "rootDir": "src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "declaration": true
  },
  "include": ["src"]
}
```

### 5. Create tools module

- **TypeScript:** `src/tools.ts` — compiled to `dist/tools.js` by `tsc`
- **JavaScript:** `tools.js` at project root

Generate tool definitions based on the user's description. Follow the export format above exactly.

### 6. Create .env (if needed)

```
# Environment variables — reloaded on _reload
MY_API_KEY=
MY_BASE_URL=http://localhost:3000
```

### 7. Create .gitignore

```
node_modules/
dist/
.env
```

### 8. Install dependencies

```bash
cd ~/code/mcp/mcp-{name} && npm install
```

### 9. Build (TypeScript only)

```bash
npm run build
```

### 10. Register the server

Ask the user if they want it registered globally or locally, then direct them to use `/mcp:add-global` or `/mcp:add-local`. The entry should be:

```json
{
  "type": "stdio",
  "command": "node",
  "args": ["/full/path/to/mcp-{name}/bootstrap.js"],
  "env": {}
}
```

## Gotchas

- **`_reload` swaps implementations, not tool definitions.** If you add or remove tools from the tools module, the new tools won't appear (and removed ones will error). Adding/removing tools requires a full Claude restart. Changing handler logic, descriptions, or schemas of existing tools works fine with `_reload`.
- **Tool names must be prefixed** with the server name in snake_case (e.g., `myservice_action`). This prevents collisions across MCP servers.
- **bootstrap.js is the entry point, not dist/index.js.** The `args` in claude.json must point to `bootstrap.js`, not the compiled output.
- **Each `_reload` leaks a small amount of memory** (Node.js caches each dynamic import URL). Negligible for dev use (dozens of reloads per session), but don't use this in production.
- **All logging goes to stderr.** `console.log()` writes to stdout which is the MCP protocol pipe. Always use `console.error()` for debug output.
- **The `.env` loader is intentionally simple.** It handles `KEY=value`, `KEY="value"`, and `# comments`. It does NOT handle multiline values, variable expansion, or export prefixes. Use a real dotenv library if you need those.
- **Zod is required.** The MCP SDK uses Zod for parameter validation. Every tool schema must use Zod types.
- **`"type": "module"` is required** in package.json. The bootstrap uses ESM imports.
