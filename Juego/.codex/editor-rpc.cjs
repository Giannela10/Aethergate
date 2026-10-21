const fs = require('node:fs');
const path = require('node:path');
const entriesDir = path.join(process.env.APPDATA, 'godot-mcp-toolkit/entries');
const runtime = process.argv[3] === 'runtime';
const entry = fs.readdirSync(entriesDir).map(name => JSON.parse(fs.readFileSync(path.join(entriesDir, name), 'utf8'))).find(e => e._key === process.cwd().replaceAll('\\', '/').toLowerCase() && (runtime ? e.runtime_port > 0 : e.port > 0));
if (!entry) throw new Error('No editor registered for this project');
const requests = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const ws = new WebSocket(`ws://127.0.0.1:${runtime ? entry.runtime_port : entry.port}`);
let index = 0;
const timeout = setTimeout(() => { console.error('Editor request timed out'); ws.close(); process.exitCode = 1; }, 45000);
const next = () => {
  if (index === requests.length) { clearTimeout(timeout); ws.close(); return; }
  ws.send(JSON.stringify({ jsonrpc: '2.0', id: index + 1, ...requests[index] }));
};
const editorEntry = fs.readdirSync(entriesDir).map(name => JSON.parse(fs.readFileSync(path.join(entriesDir, name), 'utf8'))).find(e => e._key === process.cwd().replaceAll('\\', '/').toLowerCase() && e.port > 0);
ws.onopen = () => ws.send(JSON.stringify({ auth: fs.readFileSync(entry.token_path || editorEntry.token_path, 'utf8').trim() }));
ws.onmessage = event => {
  const data = JSON.parse(event.data);
  if (data.result?.authed || data.authed) next();
  else if (data.id === index + 1) { console.log(JSON.stringify(data)); if (data.error || data.result?.success === false) { clearTimeout(timeout); ws.close(); process.exitCode = 1; } else { index++; next(); } }
};
ws.onerror = () => { clearTimeout(timeout); console.error('Editor connection failed'); process.exitCode = 1; };
