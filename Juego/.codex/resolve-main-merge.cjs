const fs = require('node:fs');
const cp = require('node:child_process');
const versions = [1,2,3].map(stage => cp.execFileSync('git',['show',`:${stage}:Main.tscn`],{encoding:'utf8',maxBuffer:40*1024*1024}));
function parse(text) {
  const blocks = text.replaceAll('\r\n','\n').split(/(?=^\[(?:gd_scene|ext_resource|sub_resource|node|connection)\b)/m).filter(x=>x.trim());
  const map = new Map();
  for (const block of blocks) {
    const header = block.slice(0,block.indexOf('\n'));
    const kind = header.match(/^\[(\w+)/)[1];
    const id = kind==='node' ? header.match(/unique_id=(\d+)/)?.[1] : header.match(/\sid="([^"]+)"/)?.[1];
    const key = kind+':'+(id || (kind==='gd_scene'?'root':header));
    if(map.has(key))throw Error('Duplicate key '+key);
    map.set(key,{header,body:block.slice(header.length).trim(),block});
  }
  return map;
}
const baseBefore = parse(versions[0]);
const localBefore = parse(versions[1]);
const renameIds = [...localBefore.keys()].filter(k=>k.startsWith('sub_resource:')&&!baseBefore.has(k)).map(k=>k.slice('sub_resource:'.length));
const renameSet = new Set(renameIds);
versions[1] = versions[1].replace(/\bid="([^"]+)"/g,(all,id)=>renameSet.has(id)?`id="merge_local_${id}"`:all).replace(/SubResource\("([^"]+)"\)/g,(all,id)=>renameSet.has(id)?`SubResource("merge_local_${id}")`:all);
const [base,local,remote] = versions.map(parse);
const keys = new Set([...base.keys(),...local.keys(),...remote.keys()]);
let conflicts=[];let edits={local:0,remote:0,both:0,localOnly:0,remoteOnly:0};
for(const key of keys){
 const b=base.get(key)?.block,l=local.get(key)?.block,r=remote.get(key)?.block;
 if(l===r)continue;
 if(l===b){edits.remote++;continue;}
 if(r===b){edits.local++;continue;}
 if(!b && !l){edits.remoteOnly++;continue;}
 if(!b && !r){edits.localOnly++;continue;}
 conflicts.push({key,base:base.get(key)?.header,local:local.get(key)?.header,remote:remote.get(key)?.header,localBody:local.get(key)?.body.slice(0,600),remoteBody:remote.get(key)?.body.slice(0,600)});
}
const nodeConflicts = conflicts.filter(c=>c.key.startsWith('node:'));
fs.writeFileSync('.codex/main-merge-analysis.json',JSON.stringify({sizes:[base.size,local.size,remote.size],edits,conflicts},null,2));
function nodePath(block){
 const name=block.header.match(/\bname="([^"]+)"/)[1];
 const parent=block.header.match(/\bparent="([^"]+)"/)?.[1];
 return parent===undefined?'.':parent==='.'?name:parent+'/'+name;
}
const pathChanges = [...local].filter(([k,b])=>k.startsWith('node:')&&remote.has(k)&&nodePath(b)!==nodePath(remote.get(k))).map(([k,b])=>[nodePath(b),nodePath(remote.get(k))]).sort((a,b)=>b[0].length-a[0].length);
function remapPath(p){for(const [old,newPath] of pathChanges) if(p===old||p.startsWith(old+'/'))return newPath+p.slice(old.length);return p;}
const selected = new Map();
const selectedSource = new Map();
for(const key of keys){
 const b=base.get(key)?.block,l=local.get(key)?.block,r=remote.get(key)?.block;
 let chosen;
 if(l===r)chosen=remote.get(key)||local.get(key);
 else if(l===b)chosen=remote.get(key);
 else if(r===b)chosen=local.get(key);
 else if(conflicts.some(c=>c.key===key)){
   if(key==='ext_resource:10_c6i3y'||key==='node:1292652261')chosen=remote.get(key);
   else throw Error('Unresolved '+key);
 }
 if(!chosen)continue;
 selectedSource.set(key,chosen===local.get(key)?'local':'remote');
 if(chosen===local.get(key)&&key.startsWith('node:')){
   const header=chosen.header.replace(/\bparent="([^"]+)"/,(all,p)=>`parent="${remapPath(p)}"`);
   chosen={...chosen,header,block:header+'\n'+chosen.body+'\n\n'};
 }
 selected.set(key,chosen);
}
// Los interiores se conservan completos de la rama local; la reorganización
// remota mantiene los mismos padres y actualiza los recursos externos.
const localInteriors=['Piso1/InteriorCoordinacion','Piso2/Biblioteca'];
const inInterior=p=>localInteriors.some(prefix=>p===prefix||p.startsWith(prefix+'/'));
for(const [key,block] of [...selected])if(key.startsWith('node:')&&inInterior(nodePath(block)))selected.delete(key);
for(const [key,block] of local)if(key.startsWith('node:')&&inInterior(nodePath(block))){
 const header=block.header.replace(/\bparent="([^"]+)"/,(all,p)=>`parent="${remapPath(p)}"`);
 selected.set(key,{...block,header,block:header+'\n'+block.body+'\n\n'});
 selectedSource.set(key,'local');
}
let nodes=[...selected].filter(([k])=>k.startsWith('node:'));
const occurrences=new Map();
for(const [key,block] of nodes){const p=nodePath(block);if(!occurrences.has(p))occurrences.set(p,[]);occurrences.get(p).push(key);}
const rebuiltRoots=[...occurrences].filter(([p,ids])=>ids.length>1).map(([p])=>p).sort((a,b)=>a.length-b.length);
const outerRoots=rebuiltRoots.filter((p,i)=>!rebuiltRoots.slice(0,i).some(root=>p.startsWith(root+'/')));
let discardedRebuilt=0;
for(const [key,block] of nodes)if(selectedSource.get(key)==='local'&&outerRoots.some(p=>nodePath(block)===p||nodePath(block).startsWith(p+'/'))){selected.delete(key);discardedRebuilt++;}
// Recuperar recursos aún utilizados por geometría remota conservada.
let addedResources=0;
for(let pass=0;pass<10;pass++){
 let added=0;
 for(const [key,block] of [...selected])for(const m of block.block.matchAll(/(SubResource|ExtResource)\("([^"]+)"\)/g)){
  const resourceKey=(m[1]==='SubResource'?'sub_resource:':'ext_resource:')+m[2];
  if(!selected.has(resourceKey)){
   const definition=remote.get(resourceKey)||local.get(resourceKey)||base.get(resourceKey);
   if(!definition)throw Error('Missing resource '+resourceKey);
   selected.set(resourceKey,definition);added++;addedResources++;
  }
 }
 if(!added)break;
}
nodes=[...selected].filter(([k])=>k.startsWith('node:'));
const paths=new Map(),duplicates=[];
for(const [key,block] of nodes){const p=nodePath(block);if(paths.has(p))duplicates.push({path:p,first:paths.get(p),second:key});else paths.set(p,key);}
const parentsMissing=nodes.filter(([k,b])=>{const p=b.header.match(/\bparent="([^"]+)"/)?.[1];return p!==undefined&&!paths.has(p);}).map(([k,b])=>b.header);
const refsMissing=[];
for(const [key,block] of selected)for(const m of block.block.matchAll(/(SubResource|ExtResource)\("([^"]+)"\)/g))if(!selected.has((m[1]==='SubResource'?'sub_resource:':'ext_resource:')+m[2]))refsMissing.push({key,ref:m[0]});
console.log(JSON.stringify({sizes:[base.size,local.size,remote.size],edits,conflicts:conflicts.map(c=>({key:c.key,local:c.local,remote:c.remote})),selected:selected.size,discardedRebuilt,addedResources,duplicates:duplicates.slice(0,10),duplicateCount:duplicates.length,parentsMissing:parentsMissing.slice(0,10),refsMissing:refsMissing.slice(0,10)},null,2));
if(process.argv.includes('--write')){
 if(duplicates.length||parentsMissing.length||refsMissing.length)throw Error('Invalid scene merge');
 const path=require('node:path'),os=require('node:os');
 const backup=fs.mkdtempSync(path.join(os.tmpdir(),'DuocGames-main-merge-'));
 fs.copyFileSync('Main.tscn',path.join(backup,'Main.conflicted.tscn'));
 for(let i=0;i<3;i++)fs.writeFileSync(path.join(backup,`stage-${i+1}.tscn`),versions[i]);
 const nonNodes=[],visited=new Set(),active=new Set();
 function resource(key){
  if(visited.has(key))return;
  if(active.has(key))throw Error('Cyclic resource '+key);
  active.add(key);
  const b=selected.get(key);
  for(const m of b.block.matchAll(/SubResource\("([^"]+)"\)/g))resource('sub_resource:'+m[1]);
  active.delete(key);visited.add(key);nonNodes.push(b.block.trim());
 }
 for(const [k,b] of selected)if(k.startsWith('gd_scene:')||k.startsWith('ext_resource:')){nonNodes.push(b.block.trim());visited.add(k);}
 for(const [k] of selected)if(k.startsWith('sub_resource:'))resource(k);
 nodes.sort((a,b)=>nodePath(a[1]).split('/').length-nodePath(b[1]).split('/').length);
 // La raíz debe preceder a todos los nodos de primer nivel.
 nodes.sort((a,b)=>nodePath(a[1])==='.'?-1:nodePath(b[1])==='.'?1:nodePath(a[1]).split('/').length-nodePath(b[1]).split('/').length);
 fs.writeFileSync('Main.tscn',[...nonNodes,...nodes.map(([k,b])=>b.block.trim())].join('\n\n')+'\n');
 console.log('MERGE_WRITTEN; BACKUP='+backup);
}
