// Public GETs only. Never authenticate a user, print credentials or execute a write RPC.
const fs=require('fs'),path=require('path');const project=path.resolve(__dirname,'..');
const config=JSON.parse(fs.readFileSync(path.join(project,'config/auth_config.json'),'utf8').replace(/^\uFEFF/,''));
const base=String(config.supabase_url||'').replace(/\/$/,''),key=config.supabase_publishable_key||config.supabase_anon_key;
const report={checked_at:new Date().toISOString(),public_get_only:true,configured:!!base&&!!key,authenticated_user:false,remote_bank_counts:'unknown_without_authorized_staff_session',probes:[]};
const routes=['/auth/v1/settings','/rest/v1/','/rest/v1/subjects?select=id,code,name,floor,active&limit=0','/rest/v1/learning_activities?select=id,subject_id,mentor_id,active&limit=0','/rest/v1/questions?select=id,subject_id,active&limit=0','/rest/v1/profiles?select=id&limit=0','/rest/v1/teacher_subjects?select=subject_id&limit=0','/rest/v1/learning_access?select=id&limit=0','/rest/v1/learning_attempts?select=id&limit=0','/rest/v1/campaign_saves?select=user_id&limit=0'];
(async()=>{await Promise.all(routes.map(async route=>{
 const row={route:route.split('?')[0],status:0};
 try{const r=await fetch(base+route,{method:'GET',headers:{apikey:key,Prefer:'count=exact'},signal:AbortSignal.timeout(10000)});row.status=r.status;const data=await r.json().catch(()=>null);row.error_code=typeof data?.code==='string'?data.code:undefined;row.count_header=r.headers.get('content-range');
 if(route==='/rest/v1/'&&r.ok&&data?.definitions){row.visible_schema=Object.fromEntries(Object.entries(data.definitions).map(([name,definition])=>[name,Object.keys(definition.properties||{})]));}
 }catch(e){row.transport_failure=e.cause?.code||e.name;}
 report.probes.push(row);
 }));report.probes.sort((a,b)=>a.route.localeCompare(b.route));report.reachable=report.probes.some(x=>x.status>0);
 fs.writeFileSync(path.join(project,fs.readFileSync(path.join(project,'reports/final_7_1/active_run.txt'),'utf8').trim().replace(/^Juego[\\/]/,''),'remote_readonly.json'),JSON.stringify(report,null,2));console.log(JSON.stringify(report));if(!report.reachable)process.exitCode=2;})().catch(()=>{console.error('Read-only probe could not complete; no credential output.');process.exitCode=1;});
