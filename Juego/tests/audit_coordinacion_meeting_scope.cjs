const fs=require('fs'),assert=require('assert'),crypto=require('crypto');
const root='Piso1/InteriorCoordinacion';
const blocks=fs.readFileSync('Main.tscn','utf8').split(/(?=^\[)/m);
const report=JSON.parse(fs.readFileSync('reports/coordinacion_meeting_layout.json','utf8'));
const outside=blocks.filter(b=>b.startsWith('[node ')&&!b.match(/parent="([^"]+)"/)?.[1].startsWith(root)).join('');
assert.equal(crypto.createHash('sha256').update(outside).digest('hex'),report.outside_scene_hash,'A node outside Coordination changed');
const baseline=require('child_process').execFileSync('git',['show','HEAD:Main.tscn'],{maxBuffer:64*1024*1024}).toString('utf8').split(/(?=^\[)/m);
function key(b){return b.match(/^\[node name="([^"]+)"/)?.[1]+'@'+b.match(/^\[node .*parent="([^"]+)"/)?.[1];}
const originals=new Map(baseline.filter(b=>b.startsWith('[node ')).map(b=>[key(b),b]));let protectedCount=0;
for(const b of blocks.filter(b=>b.startsWith('[node ')&&b.includes('parent="'+root))){
 const name=b.match(/name="([^"]+)"/)[1],parent=b.match(/parent="([^"]+)"/)[1];
 if(parent.includes('/SalaReuniones'))continue;
 const protectedNode=b.includes('type="OmniLight3D"') || (parent===root && (/^(PisoCoordinacion|TechoCoordinacion|ParedRecepcion|ParedEspera|DintelOficinas|PuertaMaderaAbierta|ManillaOficina|LuzReferencia|MeshInstance3D$)/.test(name)));
 if(protectedNode){assert.equal(b.trimEnd(),originals.get(key(b))?.trimEnd(),'Protected finish/light/structure changed: '+name);protectedCount++;}
}
console.log('COORD_MEETING_SCOPE_AUDIT_OK protected_nodes='+protectedCount+' outside_coordination_identical=true original_ceiling/finishes/lights/entrances preserved; ceiling_adjustment_pending=true');
