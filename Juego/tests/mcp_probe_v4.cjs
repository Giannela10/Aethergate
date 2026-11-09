// Official cached MCP bridge, explicitly scoped to this project. Never log tokens.
const fs=require('node:fs'),path=require('node:path');
const project=path.resolve(__dirname,'..');
const cache=path.join(process.env.LOCALAPPDATA,'npm-cache','_npx');
const entry=fs.readdirSync(cache).map(name=>path.join(cache,name,'node_modules')).find(dir=>fs.existsSync(path.join(dir,'@npgamedev/godot-mcp-server/dist/index.js')));
if(!entry)throw Error('Official cached MCP bridge not found');
const {Client}=require(path.join(entry,'@modelcontextprotocol/sdk/dist/cjs/client/index.js'));
const {StdioClientTransport}=require(path.join(entry,'@modelcontextprotocol/sdk/dist/cjs/client/stdio.js'));
const client=new Client({name:'DuocGamesV4ReadOnlyAudit',version:'4.0.0'});
const transport=new StdioClientTransport({command:process.execPath,args:[path.join(entry,'@npgamedev/godot-mcp-server/dist/index.js')],cwd:project,env:{...process.env,GODOT_MCP_PROJECT_PATH:project,GODOT_MCP_EDITOR_PORT:'6550'},stderr:'pipe'});
const report={protocol:'MCP through official cached bridge',project:'Juego',read_only:true,connected:false,tool_success:false};
function decode(result){if(result.structuredContent)return result.structuredContent;for(const part of result.content||[])if(part.type==='text')try{return JSON.parse(part.text)}catch{}return null}
const timer=setTimeout(()=>{client.close().catch(()=>{});},25000);
(async()=>{try{
 await client.connect(transport);report.connected=true;
 const catalog=await client.listTools();
 const settings=catalog.tools.find(tool=>/project_get_settings$/.test(tool.name));
 if(!settings)throw Error('Settings tool unavailable');
 const result=await client.callTool({name:settings.name,arguments:{prefix:'application/'}},undefined,{timeout:15000});
 const data=decode(result);report.tool_success=!result.isError&&data?.success!==false;report.code=data?.code||null;
 if(report.tool_success){report.settings=data;const checker=catalog.tools.find(tool=>/script_check$/.test(tool.name));if(checker){const schema=checker.inputSchema.properties||{};const key=['file_path','path','script_path'].find(name=>schema[name]);if(key){const check=await client.callTool({name:checker.name,arguments:{[key]:'res://scripts/education/pending_save_journal.gd'}},undefined,{timeout:10000});report.script_check={isError:!!check.isError,result:decode(check)};}}}
}catch(error){report.error_code=error.code||'connection_failed';}
finally{clearTimeout(timer);await client.close().catch(()=>{});fs.writeFileSync(path.join(project,'reports/v4_mcp_probe.json'),JSON.stringify(report,null,2));console.log(JSON.stringify(report));process.exitCode=report.tool_success?0:1;}})();
