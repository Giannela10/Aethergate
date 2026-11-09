// Read-only source inventory. A missing literal reference is a review candidate,
// never proof that an editor command, inherited method or reflected API is dead.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const root = path.resolve(__dirname, '..');
const files = [];
function walk(directory = '') {
  for (const entry of fs.readdirSync(path.join(root, directory), {withFileTypes: true})) {
    if (entry.name.startsWith('.') || ['addons', 'reports', 'config', '__pycache__'].includes(entry.name)) continue;
    const file = path.posix.join(directory, entry.name);
    if (entry.isDirectory()) walk(file);
    else if (/\.(gd|tscn|tres|gdshader|godot|cjs|py|uid)$/.test(file)) files.push(file);
  }
}
walk();
const sources = files.filter(file => !file.endsWith('.uid')).map(file => ({
  file, text: fs.readFileSync(path.join(root, file), 'utf8')
}));
const corpus = sources.map(source => source.text.replace(/^\s*#.*$/gm, '')).join('\n');
const production = sources.filter(source => source.file.endsWith('.gd') && !source.file.startsWith('tests/'));
const oneReferenceMembers = [];
const oneReferenceFunctions = [];
let functions = 0;
for (const {file, text} of production) {
  for (const match of text.matchAll(/^(?:(?:static )?func|var|const) (\w+)/gm)) {
    const name = match[1];
    const isFunction = match[0].includes('func ');
    if (isFunction) functions++;
    const uses = (corpus.match(new RegExp(`\\b${name}\\b`, 'g')) || []).length;
    if (uses !== 1) continue;
    const entry = {file, line: text.slice(0, match.index).split('\n').length, name};
    if (!isFunction) oneReferenceMembers.push(entry);
    else if (!name.startsWith('_')) oneReferenceFunctions.push(entry);
  }
}
const hashes = new Map();
for (const {file, text} of production) {
  const hash = crypto.createHash('sha256').update(text).digest('hex');
  hashes.set(hash, [...(hashes.get(hash) || []), file]);
}
const missingLiteralResources = [];
const absentStoragePaths = [];
for (const {file, text} of sources.filter(source => /\.(gd|tscn|tres|godot)$/.test(source.file))) {
  for (const match of text.matchAll(/res:\/\/([^"'\n\r]+\.(?:gd|tscn|tres|gdshader|json|svg|png|glb|gltf|wav|ogg))(?=["'])/g)) {
    if (fs.existsSync(path.join(root, match[1]))) continue;
    const line = text.slice(text.lastIndexOf('\n', match.index) + 1, text.indexOf('\n', match.index) < 0 ? text.length : text.indexOf('\n', match.index));
    const entry = {file, resource: match[1]};
    // Saves and test outputs are deliberately absent before/after execution.
    if ((/\b(?:save_path|path|file|SAVE|SCENE)\s*(?::=|=)/.test(line) || line.includes('FileAccess.WRITE')) && !/\b(?:load|preload)\s*\(/.test(line)) absentStoragePaths.push(entry);
    else missingLiteralResources.push(entry);
  }
}
const result = {
  scope: 'Project-owned source and resources; excludes private config, addons, reports and caches.',
  source_files: sources.length,
  production_scripts: production.length,
  production_functions: functions,
  duplicate_production_scripts: [...hashes.values()].filter(group => group.length > 1),
  missing_literal_resources: missingLiteralResources,
  absent_storage_destinations: absentStoragePaths,
  single_reference_members_for_review: oneReferenceMembers,
  single_reference_public_functions_for_review: oneReferenceFunctions,
  limitations: 'Literal analysis cannot resolve constructed paths, inherited calls, signals, editor commands or arbitrary reflection. Public candidates are retained for review; absence alone never triggers deletion.'
};
fs.writeFileSync(path.join(root, 'reports/code_usage_audit.json'), JSON.stringify(result, null, 2) + '\n');
console.log(JSON.stringify({source_files: result.source_files, production_scripts: production.length,
  production_functions: functions, duplicate_groups: result.duplicate_production_scripts.length,
  missing_literal_resources: missingLiteralResources.length, single_reference_members: oneReferenceMembers.length,
  public_entrypoints_for_review: oneReferenceFunctions.length}));
process.exitCode = missingLiteralResources.length ? 1 : 0;
