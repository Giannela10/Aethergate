// Executes existing regression suites and physical-route checks; no remote writes.
const {spawn}=require('node:child_process');
const fs=require('node:fs');
const exe=process.argv[2];
if(!exe)throw Error('Pass the Godot executable path');
const scripts=['campus_polish_regression','remember_login_check','revision_scripts','resource_reference_check','campaign_regression','inventory_regression','gameplay_regression','guardado_lectura','nueva_partida','student_phone','campus_vivo','director_informatica_boss','nexo_final','organizacion_pisos','education_1_0','education_integration','academic_schedule','balance_regression','chef_supremo_casino','contextual_interactions','personalizacion','chapel_layout_check','library_layout_check','coordinacion_layout_check','coordinacion_meeting_check','salidas_emergencia','piso5_escalera_recorrido','piso8_recorridos'];
const scenes=['SupabaseAuthCheck','EmailRegistrationCheck','SignupDiagnosticsUnit','UserRolesCheck','AcademicBossesCheck','UpperCampusCheck','BasementAccessCheck','ElevatorBasementCheck','SupabaseConnectionCheck'];
scripts.push('supabase_response_regression');
scripts.push('primera_mision');
scripts.push('placement_visual_check','camera_obstruction_check');
let suites=[...scripts.map(name=>({name,args:['--script',`res://tests/${name}.gd`]})),...scenes.map(name=>({name,args:[`res://tests/${name}.tscn`],scene:true}))];
suites.push(...['LibraryAccessCheck','AuditorioAccessCheck'].map(name=>({name,args:[`res://${name}.tscn`],scene:true})));
// Rendering is opt-in so the default command remains suitable for headless CI.
for(const name of ['visual_detail_check','rendered_gameplay_check','placement_stairs_visual_check'])if(process.argv[3]?.split(',').includes(name))suites.push({name,args:['--rendering-method','gl_compatibility','--script',`res://tests/${name}.gd`],rendered:true});
if(process.argv[3])suites=suites.filter(s=>process.argv[3].split(',').includes(s.name));
const results=process.argv[3]&&fs.existsSync('reports/detailed_validation.json')?JSON.parse(fs.readFileSync('reports/detailed_validation.json','utf8')):{};
async function run(suite){await new Promise(resolve=>{
 let output='',timedOut=false,finished=false;
 // Fixed FPS accelerates simulated time: never use it for real HTTP timeouts.
 const timing=suite.name==='SupabaseConnectionCheck'||suite.rendered?[]:['--fixed-fps','60'];
 const child=spawn(exe,[...(suite.rendered?[]:['--headless']),'--path','.',...timing,...suite.args],{windowsHide:true});
 const timer=setTimeout(()=>{timedOut=true;child.kill();},180000);
 const finalMarker={LibraryAccessCheck:'LIBRARY_ACCESS_RESULT',AuditorioAccessCheck:'AUDITORIO_ACCESS_RESULT'}[suite.name];
 function receive(chunk){output+=chunk.toString();if(/SCRIPT ERROR: Parse Error:|Failed to load script/.test(output)){child.kill();return;}const marker=finalMarker?new RegExp(finalMarker+'\\s+(?:\\{[^\\n]*\\}|\\[[^\\n]*\\])'):/(?:[A-Z_]+RESULT|SUPABASE_CONNECTION_CHECK|SIGNUP_DIAGNOSTICS_UNIT)\s+(?:\{[^\n]*\}|\[[^\n]*\])/;if(suite.scene&&marker.test(output)){finished=true;child.kill();}}
 child.stdout.on('data',receive);child.stderr.on('data',receive);
 child.on('error',e=>{output+=String(e);});
 child.on('close',code=>{
  clearTimeout(timer);
  fs.writeFileSync(`reports/detail_${suite.name}.log`,output);
  const reports=[];
  for(const line of output.split(/\r?\n/)){
   if(!/(?:RESULT|REVIEW|REGRESSION|SAVE_READING|FLOOR_ORGANIZATION|ACADEMIC_RESULT|SIGNUP_DIAGNOSTICS_UNIT|SUPABASE_CONNECTION_CHECK)/.test(line))continue;
   const start=line.search(/[\[{]/);if(start<0)continue;
   try{reports.push(JSON.parse(line.slice(start)));}catch{}
  }
  const errors=output.split(/\r?\n/).filter(l=>/^(?:SCRIPT ERROR:|ERROR:)/.test(l));
  const failedReports=reports.flat().some(r=>r.passed===false||r.auth_reachable===false||(Array.isArray(r.failures)&&r.failures.length)||(Array.isArray(r.failed)&&r.failed.length)||(Array.isArray(r.expansion_failures)&&r.expansion_failures.length));
  const skipped=/\bSKIPPED\b/.test(output);
  const passed=!skipped&&!timedOut&&!errors.length&&!failedReports&&(code===0||finished);
  results[suite.name]={passed,skipped,exit_code:code,timed_out:timedOut,stopped_after_result:finished,errors,reports};
  fs.writeFileSync('reports/detailed_validation.json',JSON.stringify(results,null,2));
  console.log(suite.name,JSON.stringify(results[suite.name]));resolve();
 });
});}
(async()=>{for(const suite of suites)await run(suite);process.exitCode=Object.values(results).every(r=>r.passed)?0:1;})();
