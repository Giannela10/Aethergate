const fs=require('fs'),path=require('path');const dir=path.resolve(__dirname,'../reports/characters_6_3');
const poses=JSON.parse(fs.readFileSync(path.join(dir,'after_feet.json'))),live=JSON.parse(fs.readFileSync(path.join(dir,'after_live_feet.json')));
const checks=[];
for(const state of ['idle','walk','run','land','crouch','attack']){
 const row=poses.find(x=>x.state===state);checks.push({state,pass:!!row&&row.shoes.length===1&&row.shoes[0].skin_binds===4&&Math.abs(row.shoes[0].render_clearance)<0.025});
}
for(const state of ['live_walk','live_run','live_land','live_crouch','live_attack','raised_marking','interior','library','inside_elevator','elevator_moving']){
 const row=live.find(x=>x.state===state);checks.push({state,pass:!!row&&row.shoes.length===1&&Math.abs(row.shoes[0].render_clearance)<0.025});
}
const jump=live.find(x=>x.state==='live_jump');checks.push({state:'jump airborne',pass:jump?.shoes[0]?.render_clearance>0.1});
checks.push({state:'stairs ascent',pass:live.find(x=>x.state==='stairs_ascending')?.rise>0.5});
const vec=text=>text.match(/-?\d+(?:\.\d+)?/g).map(Number);
const start=live.find(x=>x.state==='inside_elevator'),moving=live.find(x=>x.state==='elevator_moving');
checks.push({state:'actual cabin displacement',pass:vec(moving.origin)[1]-vec(start.origin)[1]>1});
const report={passed:checks.every(x=>x.pass),checks,limitations:['Foot clearance is for the combined two-shoe bounds; the stairs image has one planted foot and one swinging foot.','Short samples do not certify sliding-free movement over every surface.','Fresh-campaign unlock request is preserved; moving cabin uses the documented visual fixture.']};
fs.writeFileSync(path.join(dir,'feet_gate_final.json'),JSON.stringify(report,null,2));console.log(JSON.stringify(report));if(!report.passed)process.exitCode=1;
