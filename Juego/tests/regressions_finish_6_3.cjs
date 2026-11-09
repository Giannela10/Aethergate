const fs=require('fs'),path=require('path'),cp=require('child_process');
const project=path.resolve(__dirname,'..'),out=path.join(project,'reports/characters_6_3');
const executable=process.argv[2];if(!executable)throw Error('Godot executable required');
const suites=['gameplay_regression','inventory_regression','personalizacion','guardado_lectura','nueva_partida','campaign_regression'];
const rows=[];
for(const suite of suites){
 const r=cp.spawnSync(executable,['--headless','--path',project,'--script',`res://tests/${suite}.gd`],{encoding:'utf8',windowsHide:true,timeout:120000,maxBuffer:8*1024*1024});
 const output=(r.stdout||'')+'\n'+(r.stderr||'');fs.writeFileSync(path.join(out,`final_${suite}.log`),output);
 const markers=output.split(/\r?\n/).filter(x=>/RESULT|CAMPAIGN_REGRESSION/.test(x));
 const errors=output.split(/\r?\n/).filter(x=>/^SCRIPT ERROR:|^ERROR:/.test(x));
 const reportedFailure=/"passed"\s*:\s*false|"failures"\s*:\s*\[(?!\s*\])/.test(output);
 const row={suite,pass:r.status===0&&markers.length>0&&errors.length===0&&!reportedFailure,exit_code:r.status,timeout:r.error?.code==='ETIMEDOUT',markers,errors};
 rows.push(row);console.log(JSON.stringify(row));fs.writeFileSync(path.join(out,'final_regressions.json'),JSON.stringify(rows,null,2));
}
if(rows.some(x=>!x.pass))process.exitCode=1;
