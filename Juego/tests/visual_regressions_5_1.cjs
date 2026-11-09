// Sequential offline suites. Rendered tests follow headless tests; personal saves are isolated by fixtures.
const fs=require('node:fs'),path=require('node:path'),cp=require('node:child_process');
const project=path.resolve(__dirname,'..'),dir=path.join(project,'reports/visual_5_1');
const scripts=['gameplay_regression','inventory_regression','organizacion_pisos','placement_visual_check','library_layout_check','campaign_regression','piso8_recorridos','piso8_recorridos_floor6','piso8_recorridos_floor7','salidas_emergencia','guardado_lectura','cloud_save_check','persistent_queue_v4','resource_reference_check','remember_login_check','education_integration','director_informatica_boss','nexo_final'];
const scenes=['tests/BasementAccessCheck.tscn','tests/ElevatorBasementCheck.tscn','LibraryAccessCheck.tscn','AuditorioAccessCheck.tscn','tests/UserRolesCheck.tscn','tests/AcademicBossesCheck.tscn'];
const jobs=[...scripts.map(s=>({name:s})),...scenes.map(s=>({name:s,scene:true})),...['placement_stairs_visual_check','rendered_gameplay_check'].map(s=>({name:s,rendered:true}))];
const markers={salidas_emergencia:'SALIDAS_EMERGENCIA ','tests/BasementAccessCheck.tscn':'BASEMENT_ACCESS_RESULT','tests/ElevatorBasementCheck.tscn':'ELEVATOR_BASEMENT_RESULT','LibraryAccessCheck.tscn':'LIBRARY_ACCESS_RESULT','AuditorioAccessCheck.tscn':'AUDITORIO_ACCESS_RESULT','tests/UserRolesCheck.tscn':'USER_ROLES_RESULT','tests/AcademicBossesCheck.tscn':'ACADEMIC_BOSSES_RESULT',director_informatica_boss:'DIRECTOR INFORMATICA: OK'};
const results=[];
for(const job of jobs){
 const safe=job.name.replace(/[/:]/g,'_'),started=Date.now(),script=job.name.replace(/_floor[67]$/,'');
 const args=[...(job.rendered?[]:['--headless']),'--fixed-fps','60','--path',project,...(job.scene?['res://'+job.name]:['--script',`res://tests/${script}.gd`]),'--log-file',path.join(dir,safe+'.log')];
 if(job.scene&&!/Basement/.test(job.name))args.push('--quit-after','10000');
 if(/_floor[67]$/.test(job.name))args.push('--','--floor='+job.name.slice(-1));
 const r=cp.spawnSync(process.argv[2],args,{encoding:'utf8',timeout:150000,windowsHide:true,maxBuffer:8*1024*1024});
 const output=(r.stdout||'')+'\n'+(r.stderr||'');fs.writeFileSync(path.join(dir,safe+'_process.log'),output);
 const errors=output.split(/\r?\n/).filter(l=>/^(?:SCRIPT ERROR|ERROR):/.test(l));
 const completed=markers[job.name]?output.includes(markers[job.name]):/RESULT|CAMPAIGN_REGRESSION|LIBRARY_LAYOUT_CHECK/.test(output);
 const reportedFailures=/"passed"\s*:\s*false|"failures"\s*:\s*\[(?!\s*\])|"failed"\s*:\s*\[(?!\s*\])/.test(output);
 const row={suite:job.name,status:r.status===0&&errors.length===0&&completed&&!reportedFailures?'PASS AUTOMÁTICO':'FAIL',exit_code:r.status,completed,engine_errors:errors.length,reportedFailures,rendered:!!job.rendered,timeout:r.error?.code==='ETIMEDOUT',elapsed_ms:Date.now()-started,summary:output.split(/\r?\n/).filter(l=>/RESULT|REGRESSION|LIBRARY_LAYOUT_CHECK|DIRECTOR INFORMATICA:/.test(l)).slice(-3)};
 results.push(row);fs.writeFileSync(path.join(dir,'regressions.json'),JSON.stringify(results,null,2));console.log(JSON.stringify(row));
}
