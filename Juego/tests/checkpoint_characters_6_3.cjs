const fs=require('fs'),path=require('path'),cp=require('child_process'),crypto=require('crypto');
const root=path.resolve(__dirname,'../..'),dest=path.join(root,'recovery/characters_6_3');
if(fs.existsSync(path.join(dest,'checkpoint.json')))throw Error('Never overwrite an existing checkpoint');
fs.mkdirSync(dest,{recursive:true});
const files=[];
function walk(dir){for(const e of fs.readdirSync(path.join(root,dir),{withFileTypes:true})){const p=dir+'/'+e.name;if(e.isDirectory())walk(p);else if(/\.(gd|tscn|scn|tres|gdshader|md|json)$/.test(e.name))files.push(p);}}
walk('Juego/scripts/juego');walk('Juego/assets/characters/main_6_2/native');
files.push('Juego/Main.tscn','Juego/MAIN_CHARACTER_REMODEL_6_2.md','Juego/assets/characters/main_6_2/LICENSE-NOTES.md');
const manifest=[];for(const f of files){const b=fs.readFileSync(path.join(root,f)),target=path.join(dest,f);fs.mkdirSync(path.dirname(target),{recursive:true});fs.writeFileSync(target,b);manifest.push({file:f,sha256:crypto.createHash('sha256').update(b).digest('hex')});}
const env={...process.env,GIT_INDEX_FILE:path.join(dest,'checkpoint.index')};const git=args=>cp.execFileSync('git',args,{cwd:root,env,encoding:'utf8'}).trim();
git(['read-tree','HEAD']);git(['add','--',...files]);const tree=git(['write-tree']);const commit=git(['commit-tree',tree,'-p','HEAD','-m','Recovery before character remodel 6.3; current 6.2 visuals and native assets']);git(['update-ref','refs/heads/recovery/characters-6-3',commit]);
fs.writeFileSync(path.join(dest,'checkpoint.json'),JSON.stringify({commit,files:manifest,index_preserved:true,pushed:false},null,2));console.log(commit);
