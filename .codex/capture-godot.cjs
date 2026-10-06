const fs = require('node:fs');
const path = require('node:path');
const entry = JSON.parse(fs.readFileSync(path.join(process.env.APPDATA, 'godot-mcp-toolkit/entries/e5ccc2e7eba8.json'), 'utf8'));
const ws = new WebSocket(`ws://127.0.0.1:${entry.port}`);
const savePath = process.argv[2] || 'res://.codex/pared-vidrio.png';
const timeout = setTimeout(() => { console.error('Screenshot timed out'); ws.close(); process.exitCode = 1; }, 25000);
ws.onopen = () => ws.send(JSON.stringify({auth: fs.readFileSync(entry.token_path, 'utf8').trim()}));
ws.onmessage = event => {
  const data = JSON.parse(event.data);
  if (data.result?.authed || data.authed) {
    ws.send(JSON.stringify({jsonrpc:'2.0', id:1, method:'editor.screenshot', params:{node_path:'.', image_response_mode:'disk', save_path:savePath, image_detail:'full'}}));
  } else if (data.id === 1) {
    console.log(JSON.stringify(data));
    clearTimeout(timeout);
    ws.close();
  }
};
ws.onerror = () => { console.error('WebSocket connection failed'); clearTimeout(timeout); process.exitCode = 1; };
