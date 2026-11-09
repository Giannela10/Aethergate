const fs=require('fs'),path=require('path'),crypto=require('crypto'),cp=require('child_process');
const root=path.resolve(__dirname,'../..'),project=path.join(root,'Juego');
const stamp=new Date().toISOString().replaceAll(':','').replaceAll('.','');
const dest=path.join(root,'recovery','capstone_'+stamp);fs.mkdirSync(dest,{recursive:true});
const files=[];
function walk(folder){for(const e of fs.readdirSync(path.join(project,folder),{withFileTypes:true})){const p=path.join(folder,e.name);if(e.isDirectory())walk(p);else if(/\.(gd|tscn|tres|json|sql|md)$/.test(e.name))files.push(p);}}
for(const folder of ['scripts','resources/education','scenes/education','supabase'])if(fs.existsSync(path.join(project,folder)))walk(folder);
files.push('Main.tscn','project.godot');
const manifest=files.map(file=>{const bytes=fs.readFileSync(path.join(project,file));const target=path.join(dest,'Juego',file);fs.mkdirSync(path.dirname(target),{recursive:true});fs.writeFileSync(target,bytes);return {file:file.replaceAll('\\','/'),sha256:crypto.createHash('sha256').update(bytes).digest('hex')};});
const head=cp.execFileSync('git',['rev-parse','HEAD'],{cwd:root,encoding:'utf8'}).trim();
fs.writeFileSync(path.join(dest,'checkpoint.json'),JSON.stringify({created_at:new Date().toISOString(),head,files:manifest,no_push:true,index_preserved:true},null,2));
fs.mkdirSync(path.join(project,'reports/capstone'),{recursive:true});
fs.writeFileSync(path.join(project,'reports/capstone/checkpoint.json'),JSON.stringify({path:path.relative(root,dest).replaceAll('\\','/'),head,files:manifest.length},null,2));console.log(JSON.stringify({checkpoint:dest,files:manifest.length,head}));
