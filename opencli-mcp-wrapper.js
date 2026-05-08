#!/usr/bin/env node
import { execSync } from 'child_process';

const OPENCLI_CMD = process.env.OPENCLI_CMD || 'opencli';

// Cache tools list on startup
let toolsCache = null;

function getTools() {
  if (toolsCache) return toolsCache;
  try {
    const raw = execSync(`${OPENCLI_CMD} list --format json`, {
      encoding: 'utf-8',
      timeout: 30000,
    });
    toolsCache = JSON.parse(raw);
    return toolsCache;
  } catch (e) {
    return [];
  }
}

function mapTools() {
  const adapters = getTools();
  return adapters.map((a) => ({
    name: a.command.replace('/', '_'),
    description: `${a.description} [${a.strategy}]${a.browser ? ' (需要浏览器)' : ''}`,
    inputSchema: {
      type: 'object',
      properties: Object.fromEntries(
        a.args.map((arg) => [
          arg.name,
          {
            type: arg.type === 'str' ? 'string' : 'string',
            description: arg.help || arg.name,
          },
        ])
      ),
      required: a.args.filter((arg) => arg.required).map((arg) => arg.name),
    },
  }));
}

// JSON-RPC 2.0 over stdio
let buffer = '';
process.stdin.on('data', (chunk) => {
  buffer += chunk.toString();
  const lines = buffer.split('\n');
  buffer = lines.pop();
  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed) continue;
    try {
      const msg = JSON.parse(trimmed);
      handleMessage(msg);
    } catch {
      // skip invalid JSON
    }
  }
});

function send(id, result) {
  writeLine(JSON.stringify({ jsonrpc: '2.0', id, result }));
}

function sendError(id, code, message) {
  writeLine(JSON.stringify({ jsonrpc: '2.0', id, error: { code, message } }));
}

function writeLine(s) {
  process.stdout.write(s + '\n');
}

function handleMessage(msg) {
  const { id, method, params } = msg;

  switch (method) {
    case 'initialize':
      return send(id, {
        protocolVersion: '2024-11-05',
        capabilities: { tools: {} },
        serverInfo: { name: 'opencli-mcp', version: '1.0.0' },
      });

    case 'notifications/initialized':
    case 'notifications/cancelled':
      return; // no response for notifications

    case 'tools/list':
      return send(id, { tools: mapTools() });

    case 'tools/call': {
      const toolName = params.name;
      const args = params.arguments || {};
      // Find matching adapter
      const adapters = getTools();
      const adapter = adapters.find((a) => a.command.replace('/', '_') === toolName);
      if (!adapter) {
        return sendError(id, -32602, `Unknown tool: ${toolName}`);
      }

      // Build CLI command
      const positionalArg = adapter.args.find((a) => a.positional);
      const cliArgs = [];
      for (const arg of adapter.args) {
        const val = args[arg.name];
        if (val === undefined || val === null) continue;
        if (arg.positional) {
          cliArgs.push(val);
        } else {
          cliArgs.push(`--${arg.name}`, val);
        }
      }

      const cliCommand = adapter.command.replace('/', ' ');
      const cmd = `${OPENCLI_CMD} ${cliCommand} ${cliArgs.join(' ')} --format json`;
      try {
        const stdout = execSync(cmd, { encoding: 'utf-8', timeout: 60000 });
        let parsed;
        try {
          parsed = JSON.parse(stdout);
        } catch {
          parsed = stdout;
        }
        const text = typeof parsed === 'string' ? parsed : JSON.stringify(parsed, null, 2);
        return send(id, {
          content: [{ type: 'text', text }],
        });
      } catch (e) {
        const errMsg = e.stderr || e.message || String(e);
        return send(id, {
          content: [{ type: 'text', text: `Error: ${errMsg}` }],
          isError: true,
        });
      }
    }

    default:
      sendError(id, -32601, `Method not found: ${method}`);
  }
}
