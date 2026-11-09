const fs=require('fs'),path=require('path'),cp=require('child_process');
const bridge=path.join(__dirname,'visual_mcp_5.cjs');
const job=path.resolve(process.argv[2]),output=path.resolve(process.argv[3]);
function mcp(tool,arg){return cp.execFileSync(process.execPath,[bridge,tool,...(arg?[arg]:[])],{encoding:'utf8',timeout:65000,windowsHide:true});}
(async()=>{
 console.log(mcp('game_stop').trim());const began=Date.now();console.log(mcp('game_start','@'+job).trim());
 const deadline=Date.now()+180000;
 while(Date.now()<deadline){
  if(fs.existsSync(output)&&fs.statSync(output).mtimeMs>=began){const data=JSON.parse(fs.readFileSync(output));console.log(JSON.stringify({evidence:output,failures:data.failures,rows:Array.isArray(data)?data.length:data.rows?.length,distinct_body_geometries:data.distinct_body_geometries}));if(data.failures?.length)process.exitCode=1;return;}
  await new Promise(resolve=>setTimeout(resolve,1000));
 }
 console.log(mcp('game_stop').trim());console.log(mcp('debugger_get_log').trim());throw Error('Scene did not produce fresh evidence');
})().catch(e=>{console.error(e.message);process.exitCode=1;});
