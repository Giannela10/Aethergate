const fs=require('node:fs'),path=require('node:path'),cp=require('node:child_process');
const root=path.resolve(__dirname,'..');
const run=fs.readFileSync(path.join(root,'reports/final_7_1/active_run.txt'),'utf8').trim().replace(/^Juego\//,'');
const checks=[];
for(const name of ['FLOORS_3_TO_8_FINAL_REPORT.md',...Array.from({length:6},(_,i)=>`FLOOR_${i+3}_FINAL_AUDIT.md`)]){
 const content=fs.readFileSync(path.join(root,name),'utf8'),missing=[];
 for(const match of content.matchAll(/\]\(([^)]+)\)/g)){
  if(/^https?:/.test(match[1]))continue;
  if(!fs.existsSync(path.join(root,decodeURIComponent(match[1]))))missing.push(match[1]);
 }
 checks.push({test:name,status:missing.length?'FAIL':'PASS',missing_links:missing});
}
const fresh=JSON.parse(fs.readFileSync(path.join(root,run,'fresh_Main_checks_v2.json'),'utf8'));
checks.push({test:'fresh_Main_6_checks',status:fresh.length===6&&fresh.every(r=>r.status==='PASS')?'PASS':'FAIL'});
const diff=cp.spawnSync('git',['diff','--check'],{cwd:path.dirname(root),encoding:'utf8'});
checks.push({test:'git_diff_check',status:diff.status===0?'PASS':'FAIL',exit_code:diff.status,stdout:diff.stdout,stderr:diff.stderr});
const log=fs.readFileSync(path.join(root,run,'fresh_runtime_excerpt.txt'),'utf8');
checks.push({test:'fresh_runtime_no_script_errors',status:!log.includes('SCRIPT ERROR')&&!/^ERROR:/m.test(log)?'PASS':'FAIL'});
fs.writeFileSync(path.join(root,run,'deliverables_checks.json'),JSON.stringify(checks,null,2),{flag:'wx'});
console.log(JSON.stringify(checks,null,2));
if(checks.some(r=>r.status==='FAIL'))process.exitCode=1;
