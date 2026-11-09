const fs=require('fs'),path=require('path'),cp=require('child_process');
const project=path.resolve(__dirname,'..'),dir=path.join(project,'reports/capstone');
const executable=process.argv[2];if(!executable)throw Error('Godot executable required');
const suites=['learning_activity_v4','education_1_0','education_integration','gameplay_regression','inventory_regression','personalizacion','campaign_regression','guardado_lectura','nueva_partida','student_phone','campus_v4','campus_vivo','organizacion_pisos','director_informatica_boss','nexo_final','performance_startup'];
const rows=[];
for(const suite of suites.filter(x=>!process.argv[3]||x===process.argv[3])){const started=Date.now();const logfile=path.join(dir,'general_'+suite+'.log');
 const r=cp.spawnSync(executable,['--headless','--path',project,'--script',`res://tests/${suite}.gd`,'--log-file',logfile],{encoding:'utf8',windowsHide:true,timeout:120000,maxBuffer:12*1024*1024});
 const output=(r.stdout||'')+'\n'+(r.stderr||'');fs.writeFileSync(path.join(dir,'general_'+suite+'_process.log'),output);
 const errors=output.split(/\r?\n/).filter(x=>/^SCRIPT ERROR:|^ERROR:/.test(x));
 const warnings=output.split(/\r?\n/).filter(x=>/^WARNING:/.test(x));
 const markers=output.split(/\r?\n/).filter(x=>/RESULT|REGRESSION|DIRECTOR INFORMATICA:|PERF total_ms/.test(x));
 const reportedFailure=/"passed"\s*:\s*false|"failures"\s*:\s*\[(?!\s*\])|"failed"\s*:\s*\[(?!\s*\])/.test(output);
 const row={suite,pass:r.status===0&&markers.length>0&&!reportedFailure&&errors.length===0,exit_code:r.status,timeout:r.error?.code==='ETIMEDOUT',elapsed_ms:Date.now()-started,errors,warnings,markers};
 rows.push(row);if(process.argv[3]){const existing=JSON.parse(fs.readFileSync(path.join(dir,'general_tests.json')));fs.writeFileSync(path.join(dir,'general_tests.json'),JSON.stringify(existing.map(x=>x.suite===suite?row:x),null,2));}else fs.writeFileSync(path.join(dir,'general_tests.json'),JSON.stringify(rows,null,2));console.log(JSON.stringify(row));
}
if(rows.some(x=>!x.pass))process.exitCode=1;
