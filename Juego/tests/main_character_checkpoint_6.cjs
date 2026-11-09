const fs=require('fs'),cp=require('child_process'),path=require('path');
const root=path.resolve(__dirname,'../..');
const dir=path.join(root,'recovery/main_character_6_0');
fs.mkdirSync(dir,{recursive:true});
const files=['Juego/scripts/juego/student_visual.gd','Juego/scripts/juego/humanoid.gd','Juego/scripts/juego/procedural_appearance_adapter.gd','Juego/scripts/juego/player.gd','Juego/scripts/juego/character_appearance.gd','Juego/Main.tscn'];
for(const f of files){const dest=path.join(dir,f);fs.mkdirSync(path.dirname(dest),{recursive:true});fs.copyFileSync(path.join(root,f),dest);}
const env={...process.env,GIT_INDEX_FILE:path.join(dir,'checkpoint.index')};
const git=(args)=>cp.execFileSync('git',args,{cwd:root,env,encoding:'utf8'}).trim();
git(['read-tree','HEAD']);git(['add','--',...files]);
const tree=git(['write-tree']);
const commit=git(['commit-tree',tree,'-p','HEAD','-m','Recovery before main character remodel 6.0 (selected current sources)']);
git(['update-ref','refs/heads/recovery/main-character-6-0',commit]);
fs.writeFileSync(path.join(dir,'checkpoint.json'),JSON.stringify({commit,files,scope:'Selected current sources over HEAD; user index untouched. Full copies retained.'},null,2));
console.log(commit);
