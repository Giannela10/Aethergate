const fs=require('fs'),assert=require('assert');
const root='Piso2/Biblioteca';
const baseline=require('child_process').execFileSync('git',['show','HEAD:Main.tscn'],{maxBuffer:64*1024*1024}).toString('utf8').split(/(?=^\[)/m);
const current=fs.readFileSync('Main.tscn','utf8').split(/(?=^\[)/m);
function key(b) {const name=b.match(/^\[node name="([^"]+)"/)?.[1];return name?b.match(/parent="([^"]+)"/)?.[1]+'/'+name:b.match(/^\[sub_resource .*id="([^"]+)"/)?.[1];}
const now=new Map(current.map(b=>[key(b),b]));let preserved=0;
for(const b of baseline) {
 const k=key(b);if(!k)continue;
 if(b.startsWith('[node ')) {
  const n=b.match(/name="([^"]+)"/)[1];
  const protectedLibrary=k.startsWith(root) && (b.includes('type="OmniLight3D"') || k.includes('/BossBibliotecaria') || k.includes('/EntradaVidrio') || k.includes('/PuertaVidrio') || (k.includes('/AcabadosReferencia/') && /Cielo|Luz|OmniLight/.test(n)) || ['ParedPosteriorVidrio','ParedDerechaFrente','ParedDerechaFondo','DintelEntradaVidrio'].includes(n));
  const unaffected=!k.startsWith(root) && !k.startsWith('Piso1/InteriorCoordinacion') && !k.startsWith('Piso1/PasilloDerechoYCapilla');
  if(protectedLibrary || unaffected) {assert.equal(now.get(k)?.trimEnd(),b.trimEnd(),'Protected node changed: '+k);preserved++;}
 } else if(b.startsWith('[sub_resource ') && now.get(k)?.trimEnd()!==b.trimEnd()) {
  // Changes from the earlier chapel task are already present in this working tree.
  // This migration must not modify any original library/shared material resource.
  const users=baseline.filter(v=>v.startsWith('[node ') && v.includes('SubResource("'+k+'")'));
  assert(users.length && users.every(v=>v.includes('parent="Piso1/PasilloDerechoYCapilla')),'Original resource modified: '+k);
 }
}
console.log('LIBRARY_SCOPE_AUDIT_OK preserved_nodes='+preserved+' original_materials/lighting/general_ceiling/doors/NPC/printing_room/other_floors unchanged');
