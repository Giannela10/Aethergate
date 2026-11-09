// Source-only recovery snapshot: no Git internals, configuration, saves or binaries.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),cp=require('node:child_process');
const root=process.cwd(),dest=path.join(root,'recovery','before_duocgames_4_0');
if(fs.existsSync(dest))throw Error('Recovery point already exists; never overwrite it');
const allowed=new Set(['.gd','.tscn','.tres','.gdshader','.sql','.md','.cjs','.ps1','.godot','.cfg']);
const excluded=new Set(['.git','.godot','.agents','.codex','.aws','config','recovery','node_modules']);
const files=[];
function walk(dir){for(const e of fs.readdirSync(dir,{withFileTypes:true})){const p=path.join(dir,e.name),rel=path.relative(root,p);if(e.isDirectory()){if(!excluded.has(e.name))walk(p);}else if(allowed.has(path.extname(e.name))&&!/auth_config|session|credential|secret|\.env|recovery_backup/i.test(e.name)){const data=fs.readFileSync(p);if(/(?:service_role|sb_secret_)[A-Za-z0-9_\-]{16,}|eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+|postgres(?:ql)?:\/\/[^\s]+@/.test(data.toString('utf8')))throw Error('Potential secret; snapshot aborted: '+rel);files.push({rel,data});}}}
walk(path.join(root,'Juego'));
fs.mkdirSync(dest,{recursive:true});
const manifest=[];
for(const {rel,data} of files){const target=path.join(dest,rel);fs.mkdirSync(path.dirname(target),{recursive:true});fs.writeFileSync(target,data);const sha=crypto.createHash('sha256').update(data).digest('hex');if(crypto.createHash('sha256').update(fs.readFileSync(target)).digest('hex')!==sha)throw Error('Verification failed: '+rel);manifest.push({path:rel,sha256:sha,bytes:data.length});}
fs.writeFileSync(path.join(dest,'manifest.json'),JSON.stringify({created_at:new Date().toISOString(),scope:'Source snapshot; excludes private configuration, user saves, Git internals, binaries and assets. Existing assets are left untouched.',files:manifest},null,2));
fs.writeFileSync(path.join(dest,'git-status.txt'),cp.execFileSync('git',['status','--porcelain'],{encoding:'utf8'}));
console.log(JSON.stringify({verified:true,files:files.length,recovery:dest}));
