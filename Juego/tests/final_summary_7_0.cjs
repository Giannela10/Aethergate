const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),assert=require('node:assert/strict');
const repo=path.resolve(__dirname,'../..');
const root=path.join(repo,fs.readFileSync(path.join(__dirname,'../reports/final_7_0/active_run.txt'),'utf8').trim());
const read=name=>JSON.parse(fs.readFileSync(path.join(root,name),'utf8').replace(/^\uFEFF/,''));
const stats=values=>({count:values.length,min:Math.min(...values),max:Math.max(...values),mean:values.reduce((a,b)=>a+b,0)/values.length});
const before=read('before_animation.json'),after=read('verified_final_animation.json');
const cadence=read('verified_final_cadence.json');
assert(cadence.every(r=>r.passed),'Cadence does not match actual speed');
assert.deepEqual(before.bones,after.bones,'Imported bone names, hierarchy and rests changed');
const contact=read('final_ground/extra_checks.json').filter(r=>r.test.startsWith('continuous_4s_')).slice(-2).map(row=>{
 const all=[],stance=[];
 for(const s of row.detail.samples)for(const foot of Object.values(s.feet))if(foot.render_y!=null){const gap=foot.sole_y-foot.render_y;all.push(gap);if(!foot.swing)stance.push(gap)}
 assert(Math.min(...all)>-0.001,'Sole penetrates measured render surface');
 return {state:row.test,all_feet_clearance_m:stats(all),stance_clearance_m:stats(stance)};
});
const blocks=s=>new Map(s.replaceAll('\r\n','\n').split(/(?=^\[)/m).map(b=>[b.split('\n')[0],b]));
const original=blocks(fs.readFileSync(path.join(root,'Main.before.tscn.txt'),'utf8'));
const current=blocks(fs.readFileSync(path.join(repo,'Juego/Main.tscn'),'utf8'));
assert.equal(original.size,current.size,'Scene structure changed');
const changed=[];
for(const [key,value]of current)if(value!==original.get(key))changed.push(key);
assert.equal(changed.length,3,'Unexpected number of changed scene blocks');
assert(changed.every(k=>k.includes('BoxMesh_co32k')||k.includes('BoxShape3D_vcqyj')||k.includes('name="LosaInclinada"')&&k.includes('RampaVehicularExterior')),'Unrelated scene block modified');
const suites=read('cadence_regression/regressions.json');
assert.equal(suites.length,4);
for(const s of suites){assert(s.started&&!s.timeout&&!s.script_errors);assert(!s.tail.includes('ERROR:'));assert(/"failures":\s*\[\]/.test(s.tail),'Regression suite failed: '+s.suite)}
const floors=['PisoMenos1','Piso1','Piso2'].map(floor=>{
 const inventory=read('survey_'+floor+'_inventory.json');
 return {floor,nodes_in_inventory:inventory.length,mesh_instances:inventory.filter(r=>r.type==='MeshInstance3D').length,lights:inventory.filter(r=>/^(Omni|Directional|Spot)Light3D$/.test(r.type)).length,visible_lights_in_tree:inventory.filter(r=>/^(Omni|Directional|Spot)Light3D$/.test(r.type)&&r.visible).length,labels:inventory.filter(r=>r.type==='Label3D').length,note:'Tree visibility is not renderer-active light count. Inventory is not per-instance visual approval.'};
});
const summary={version:'7.0',date:'2026-11-13',project:'Juego/project.godot',bones_preserved:before.bones.length,cadence,contact,floors,regression_suites:suites.map(s=>({suite:s.suite,passed:true})),changed_scene_blocks:changed,transitions:read('transitions/transitions_done.json').rows.map(r=>({test:r.test,passed:r.passed,end:r.detail.end})),ramp_persisted:read('ramp_persisted_resource_check.json'),critical_pending:[{id:'M1-02',floor:-1,node:'Piso1/LosasYAccesos/LosaRecortada_46_1/Cuerpo',description:'Upper ramp head clearance blocked; structural opening and fall protection not changed.'}],performance:{before:before.rows.map(r=>({state:r.state,fps:r.fps,draw_calls:r.draw_calls})),after:after.rows.map(r=>({state:r.state,fps:r.fps,draw_calls:r.draw_calls})),claim:'No FPS improvement claimed; short isolated samples, not a sustained campus benchmark.'}};
assert(summary.ramp_persisted.passed);
fs.writeFileSync(path.join(root,'final_summary.json'),JSON.stringify(summary,null,2));
console.log(JSON.stringify({bones:summary.bones_preserved,suites:summary.regression_suites,changed_scene_blocks:changed.length,contact,critical_pending:summary.critical_pending},null,2));
