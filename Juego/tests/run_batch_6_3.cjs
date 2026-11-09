const fs=require('fs'),path=require('path'),cp=require('child_process');
const project=path.resolve(__dirname,'..'),out=path.join(project,'reports/characters_6_3');
const batch=Number(process.argv[2]);if(![0,3,4,5,6,7].includes(batch))throw Error('Invalid batch');
const config=path.join(project,'scripts/juego/characters_6_3_rollout.json');
if(batch>0)fs.writeFileSync(config,JSON.stringify({batch,pilot_ids:['Auxiliar','Estudiante'],enabled:true})+'\n');
const bridge=path.join(__dirname,'visual_mcp_5.cjs');
function mcp(tool,arg){const args=[bridge,tool];if(arg)args.push(arg);return cp.execFileSync(process.execPath,args,{encoding:'utf8',timeout:65000,windowsHide:true});}
(async()=>{
 console.log(mcp('game_stop').trim());const start=Date.now();
 console.log(mcp('game_start','@'+path.join(__dirname,batch===0?'baseline_characters_6_3.json':'npc_validation_6_3.json')).trim());
 const coverage=path.join(out,`batch${batch}_coverage.json`),perf=path.join(out,`batch${batch}_main_performance.json`);
 const deadline=Date.now()+180000;
 while(Date.now()<deadline){
  if(fs.existsSync(perf)&&fs.statSync(perf).mtimeMs>=start&&fs.existsSync(coverage)&&fs.statSync(coverage).mtimeMs>=start){
   const rows=JSON.parse(fs.readFileSync(coverage)),changed=rows.filter(x=>Object.keys(x.remodel||{}).length);
   const failures=changed.filter(x=>x.bone_count!==53||!x.mesh_skin_valid||x.anatomy_valid!==true||Object.keys(x.poses||{}).length!==11||!Object.values(x.poses||{}).every(p=>Object.keys(p).length===5&&Object.values(p).every(b=>b.finite)));
   const dialogue=JSON.parse(fs.readFileSync(path.join(out,`batch${batch}_dialogue.json`)));
   const result={batch,representations:rows.length,remodelled:changed.length,failures:failures.map(x=>x.path),dialogue,performance:JSON.parse(fs.readFileSync(perf)),completed_at:new Date().toISOString()};
   fs.writeFileSync(path.join(out,`batch${batch}_validation.json`),JSON.stringify(result,null,2));console.log(JSON.stringify(result));
   if(failures.length||!dialogue.ui_busy||!dialogue.mission_not_accepted||dialogue.text!=='[E] Hablar con Auxiliar')process.exitCode=1;
   return;
  }
  await new Promise(resolve=>setTimeout(resolve,1000));
 }
 console.log(mcp('game_stop').trim());console.log(mcp('debugger_get_log').trim());throw Error('Batch did not produce fresh evidence');
})().catch(e=>{console.error(e.message);process.exitCode=1;});
