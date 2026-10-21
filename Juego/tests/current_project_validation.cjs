// Local, repeatable checks. Auth suites use synthetic fixtures only.
const {spawn} = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');
const exe = process.argv[2];
if (!exe) throw new Error('Pass the Godot executable path');
const scripts = ['remember_login_check','revision_scripts','resource_reference_check','campaign_regression','inventory_regression','gameplay_regression','guardado_lectura','nueva_partida','student_phone','campus_vivo','director_informatica_boss','nexo_final','organizacion_pisos'];
const scenes = ['SupabaseAuthCheck','EmailRegistrationCheck','SignupDiagnosticsUnit','UserRolesCheck','AcademicBossesCheck'];
const suites = [...scripts.map(name=>({name,args:['--script',`res://tests/${name}.gd`]})),...scenes.map(name=>({name,args:[`res://tests/${name}.tscn`],scene:true}))].filter(s=>!process.argv[3]||process.argv[3].split(',').includes(s.name));
const results = process.argv[3]&&fs.existsSync('reports/current_project_validation.json')?JSON.parse(fs.readFileSync('reports/current_project_validation.json','utf8')):{};
async function run(suite) {
 return new Promise(resolve=>{
  let output='', timedOut=false, stoppedOnResult=false;
  const child=spawn(exe,['--headless','--path','.',...suite.args],{windowsHide:true});
  const timer=setTimeout(()=>{timedOut=true;child.kill();},180000);
  const receive=data=>{
   output+=data.toString();
   if(suite.scene && /(?:RESULT|SCRIPT_REVIEW|SIGNUP_DIAGNOSTICS_UNIT)\s+\{[^\n]*\}/.test(output)) {stoppedOnResult=true;child.kill();}
  };
  child.stdout.on('data',receive);child.stderr.on('data',receive);
  child.on('error',e=>{output+=String(e);});
  child.on('close',code=>{
   clearTimeout(timer);
   fs.writeFileSync(path.join('reports',`current_${suite.name}.log`),output);
   const reports=[];
   for(const line of output.split(/\r?\n/)){
    if(!/(RESULT|SCRIPT_REVIEW|NEXO_FINAL|FLOOR_ORGANIZATION|SAVE_READING|CAMPAIGN_REGRESSION|SIGNUP_DIAGNOSTICS_UNIT)/.test(line))continue;
    const start=line.indexOf('{');if(start<0)continue;
    try {reports.push(JSON.parse(line.slice(start)));} catch{}
   }
   const scriptErrors=/SCRIPT ERROR|Parse Error/.test(output);
   const passed=reports.length>0 && reports.every(r=> !((r.failures||r.failed||[]).length)) && !scriptErrors && !timedOut;
   const director=suite.name==='director_informatica_boss' && output.includes('DIRECTOR INFORMATICA: OK (0 fallos)') && !scriptErrors && !timedOut;
   results[suite.name]={passed:passed||director,exit_code:code,timed_out:timedOut,stopped_on_result:stoppedOnResult,script_errors:scriptErrors,reports};
   fs.writeFileSync('reports/current_project_validation.json',JSON.stringify(results,null,2));
   console.log(suite.name,JSON.stringify(results[suite.name]));resolve();
  });
 });
}
(async()=>{let next=0;await Promise.all([0,1].map(async()=>{while(next<suites.length)await run(suites[next++]);}));process.exitCode=Object.values(results).every(r=>r.passed)?0:1;})();
