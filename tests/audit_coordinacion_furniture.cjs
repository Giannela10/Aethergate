const fs=require('fs');
const assert=require('assert');
const original=require('child_process').execFileSync('git',['show','HEAD:Main.tscn'],{maxBuffer:64*1024*1024}).toString('utf8').split(/(?=^\[)/m);
const current=fs.readFileSync('Main.tscn','utf8').split(/(?=^\[)/m);
function key(b) {const name=b.match(/^\[node name="([^"]+)"/)?.[1];return name ? b.match(/parent="([^"]+)"/)?.[1]+'/'+name : b.match(/^\[sub_resource .*id="([^"]+)"/)?.[1];}
const lookup=new Map(original.map(b=>[key(b),b]));
const currentLookup=new Map(current.map(b=>[key(b),b]));
const root='Piso1/InteriorCoordinacion';
const waitingParents=original.filter(b=>b.startsWith('[node ') && b.includes('parent="'+root+'"') && /, 65.6, 0, -11/.test(b)).map(b=>root+'/'+b.match(/name="([^"]+)"/)[1]);
if(process.argv.includes('--restore-waiting')) {
  for(let i=0;i<current.length;i++) {
    const parent=current[i].match(/^\[node .*parent="([^"]+)"/)?.[1];
    if(waitingParents.includes(parent)) current[i]=lookup.get(key(current[i]));
  }
  fs.writeFileSync('Main.tscn',current.join(''));
}
let protectedNodes=0;
for(const b of current) {
  const k=key(b); const old=lookup.get(k);
  if(!old || !b.startsWith('[node ')) continue;
  const name=b.match(/name="([^"]+)"/)[1];
  if(k.startsWith(root) && name!=='PuertaArmario' && /^(Piso|Techo|Pared|Mampara|Vinilo|Montante|Perfil|Dintel|Marco|Puerta|TiradorPuerta|Rotulo|Grafica|Division|Luz|MeshInstance3D$)/.test(name)) {
    assert.equal(b.trimEnd(),old.trimEnd(),'Protected architecture changed: '+k);protectedNodes++;
  }
  if(!k.startsWith(root) && !k.startsWith('Piso1/PasilloDerechoYCapilla')) assert.equal(b.trimEnd(),old.trimEnd(),'Unrelated node changed: '+k);
}
for(const b of original) {
  if(!b.startsWith('[sub_resource ')) continue;
  const k=key(b); const now=currentLookup.get(k);
  if(now?.trimEnd()===b.trimEnd()) continue;
  // Only earlier chapel changes may alter original resources; no coordination
  // resource is edited, including materials shared with the architecture.
  const refs=original.filter(n=>n.startsWith('[node ') && n.includes('SubResource("'+k+'")'));
  assert(refs.length && refs.every(n=>n.includes('parent="Piso1/PasilloDerechoYCapilla')),'Original non-chapel resource changed: '+k);
}
console.log('COORDINACION_SCOPE_OK protected_nodes='+protectedNodes+' original_materials/lighting/doors/unrelated_sectors unchanged');
