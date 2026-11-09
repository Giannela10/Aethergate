// Runs existing offline regression suites sequentially, after the MCP playtest stops.
const fs=require('node:fs'),path=require('node:path'),cp=require('node:child_process');
const project=path.resolve(__dirname,'..'),dir=path.join(project,'reports/visual_5');
const rendered=process.argv[3]==='rendered';
const suites=rendered?['placement_stairs_visual_check','rendered_gameplay_check']:process.argv[3]==='final'?['organizacion_pisos','placement_visual_check','library_layout_check','resource_reference_check']:process.argv[3]==='access'?['scene:tests/BasementAccessCheck.tscn','scene:tests/ElevatorBasementCheck.tscn','scene:LibraryAccessCheck.tscn','scene:AuditorioAccessCheck.tscn']:['gameplay_regression','inventory_regression','organizacion_pisos','placement_visual_check','library_layout_check','campaign_regression','piso8_recorridos','piso8_recorridos_floor6','piso8_recorridos_floor7','salidas_emergencia','guardado_lectura','cloud_save_check','persistent_queue_v4','resource_reference_check'];
const results=[];
for(const name of suites){
 const safeName=name.replace(/[:/]/g,'_');
 const started=Date.now(),log=path.join(dir,safeName+'.log');
 const script=name.replace(/_floor[67]$/,'');
 const args=[...(rendered?[]:['--headless']),'--fixed-fps','60','--path',project,...(name.startsWith('scene:')?['res://'+name.slice(6)]:['--script',`res://tests/${script}.gd`]),'--log-file',log];
 // These two legacy fixtures report completion but intentionally keep running.
 if(['scene:LibraryAccessCheck.tscn','scene:AuditorioAccessCheck.tscn'].includes(name))args.push('--quit-after','10000');
 if(/_floor[67]$/.test(name))args.push('--','--floor='+name.slice(-1));
 const r=cp.spawnSync(process.argv[2],args,{encoding:'utf8',timeout:120000,windowsHide:true,maxBuffer:8*1024*1024});
 const output=(r.stdout||'')+'\n'+(r.stderr||'');
 fs.writeFileSync(path.join(dir,safeName+'_process.log'),output);
 const errors=output.split(/\r?\n/).filter(l=>/^(?:SCRIPT ERROR|ERROR):/.test(l));
 const expected=name==='scene:tests/BasementAccessCheck.tscn'?'BASEMENT_ACCESS_RESULT':name==='scene:tests/ElevatorBasementCheck.tscn'?'ELEVATOR_BASEMENT_RESULT':name==='scene:LibraryAccessCheck.tscn'?'LIBRARY_ACCESS_RESULT':name==='scene:AuditorioAccessCheck.tscn'?'AUDITORIO_ACCESS_RESULT':null;
 const completed=expected?output.includes(expected):/RESULT|CAMPAIGN_REGRESSION|LIBRARY_LAYOUT_CHECK/.test(output);
 const reportedFailures=/"passed"\s*:\s*false|"failures"\s*:\s*\[(?!\s*\])|"failed"\s*:\s*\[(?!\s*\])/.test(output);
 const row={suite:name,exit_code:r.status,status:r.status===0&&errors.length===0&&completed&&!reportedFailures?'PASS AUTOMÁTICO':'FAIL',completed,reportedFailures,elapsed_ms:Date.now()-started,engine_errors:errors.length,timeout:r.error?.code==='ETIMEDOUT',summary:output.split(/\r?\n/).filter(l=>/RESULT|PASS|FAIL|checks=|failures|fallos/.test(l)).slice(-4)};
 results.push(row);fs.writeFileSync(path.join(dir,rendered?'rendered_regressions.json':process.argv[3]==='access'?'access_regressions.json':process.argv[3]==='final'?'final_regressions.json':'regressions.json'),JSON.stringify(results,null,2));console.log(JSON.stringify(row));
}
