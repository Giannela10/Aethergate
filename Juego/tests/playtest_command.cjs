const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '../reports/detailed_walkthrough_2026_10_26');
const argument = process.argv[2] || 'state';
const command = argument.startsWith('{') ? JSON.parse(argument) : {action:argument};
for (const argument of process.argv.slice(3)) {
  const separator = argument.indexOf('=');
  const key = argument.slice(0,separator), value = argument.slice(separator+1);
  command[key] = key === 'points' ? value.split(';').map(point=>point.split(',').map(Number))
    : ['position','target'].includes(key) ? value.split(',').map(Number)
    : /^(?:\d+(?:\.\d+)?|-\d+(?:\.\d+)?)$/.test(value) ? Number(value)
    : value === 'true' ? true : value === 'false' ? false : value;
}
command.id = command.id || `${Date.now()}_${command.action}`;
if (command.action === 'extension' && !command.script) {
  // Each edited helper gets a fresh resource path, avoiding Godot's failed-script cache.
  const source = fs.readFileSync(path.join(__dirname, 'detailed_walkthrough_extension.gd'));
  const hash = require('node:crypto').createHash('sha256').update(source).digest('hex').slice(0,12);
  const name = `.playtest_runtime_${hash}.gd`;
  fs.writeFileSync(path.join(__dirname,name),source);
  command.script = `res://tests/${name}`;
}
const temporary = path.join(root, 'command.tmp');
fs.writeFileSync(temporary, JSON.stringify(command));
fs.renameSync(temporary, path.join(root, 'command.json'));
const deadline = Date.now() + 180000;
async function main() {
  if (command.action === 'quit') { console.log('Inspection session stop requested.'); return; }
  while (Date.now() < deadline) {
    try {
      const response = JSON.parse(fs.readFileSync(path.join(root, 'response.json'), 'utf8'));
      if (response.id === command.id) {
        const s = response.state;
        const details = {...response.details};
        if (Array.isArray(details.trace)) { details.trace_samples=details.trace.length; delete details.trace; }
        if (Array.isArray(details.route)) { details.route_summary={segments:details.route.length,passed:details.route.filter(r=>r.reached).length,last:details.route.at(-1)}; delete details.route; }
        if (Array.isArray(details.targets)) { details.target_count=details.targets.length; delete details.targets; }
        console.log(JSON.stringify({id:response.id, details, player:s.player,
          health:s.health, dead:s.dead, busy:s.busy, paused:s.paused, objective:s.objective,
          buttons:s.buttons.map(button=>button.text), bosses:s.bosses, minigame:s.minigame}, null, 2));
        return;
      }
    } catch (error) { if (!['ENOENT','SyntaxError'].includes(error.code || error.name)) throw error; }
    await new Promise(resolve => setTimeout(resolve, 150));
  }
  throw Error(`Timed out waiting for ${command.id}`);
}
main().catch(error => { console.error(error.message); process.exitCode = 1; });
