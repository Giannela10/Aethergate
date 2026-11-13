// Project-scoped official MCP bridge. No credentials are printed.
const fs=require('node:fs'),path=require('node:path');
const project=path.resolve(__dirname,'..');
const cache=path.join(process.env.LOCALAPPDATA,'npm-cache','_npx');
const entry=fs.readdirSync(cache).map(n=>path.join(cache,n,'node_modules')).find(p=>fs.existsSync(path.join(p,'@npgamedev/godot-mcp-server/dist/index.js')));
const {Client}=require(path.join(entry,'@modelcontextprotocol/sdk/dist/cjs/client/index.js'));
const {StdioClientTransport}=require(path.join(entry,'@modelcontextprotocol/sdk/dist/cjs/client/stdio.js'));
const client=new Client({name:'DuocGamesVisual5',version:'5.0.0'});
const transport=new StdioClientTransport({command:process.execPath,args:[path.join(entry,'@npgamedev/godot-mcp-server/dist/index.js')],cwd:project,env:{...process.env,GODOT_MCP_PROJECT_PATH:project,...(process.env.DUOCGAMES_RUNTIME_PORT?{GODOT_MCP_RUNTIME_PORT:process.env.DUOCGAMES_RUNTIME_PORT}:{})},stderr:'pipe'});
(async()=>{try{await client.connect(transport);let catalog=(await client.listTools()).tools;
const suffix=process.argv[2];
if(suffix==='catalog'){console.log(JSON.stringify(catalog));return;}
if(suffix==='run'){
 const jobs=JSON.parse(fs.readFileSync(process.argv[3],'utf8').replace(/^\uFEFF/,''));
 for(const job of jobs){const selected=catalog.find(t=>t.name.endsWith(job.tool));if(!selected)throw Error('Unknown tool '+job.tool);
 const label=/\.call\('view','([^']+)'/.exec(job.arguments.code||'')?.[1];
 const capture=label?path.join(project,'reports/visual_5',fs.readFileSync(path.join(project,'reports/visual_5/phase.txt'),'utf8').trim()+'_'+label+'.png'):null;
 const previous=capture&&fs.existsSync(capture)?fs.statSync(capture).mtimeMs:0;
 const r=await client.callTool({name:selected.name,arguments:job.arguments},undefined,{timeout:55000});for(const c of r.content||[])if(c.type==='text')console.log(c.text);
 if(capture){const deadline=Date.now()+30000;while((!fs.existsSync(capture)||fs.statSync(capture).mtimeMs<=previous)&&Date.now()<deadline)await new Promise(resolve=>setTimeout(resolve,150));if(!fs.existsSync(capture)||fs.statSync(capture).mtimeMs<=previous)throw Error('Capture did not finish: '+label);}
 }
 return;
}
let tool=catalog.find(t=>t.name.endsWith(suffix));
if(!tool){const discover=catalog.find(t=>t.name.endsWith('discover_tools'));const group=suffix==='scene_close'?'cleanup':suffix.startsWith('editor_')?'editor_advanced':suffix.startsWith('lsp_')?'lsp_code_analysis':'runtime_advanced';await client.callTool({name:discover.name,arguments:{request:group}});catalog=(await client.listTools()).tools;tool=catalog.find(t=>t.name.endsWith(suffix));}
if(!tool)throw Error('Unknown tool '+suffix);
const input=process.argv[3]||'{}';
const result=await client.callTool({name:tool.name,arguments:JSON.parse((input.startsWith('@')?fs.readFileSync(input.slice(1),'utf8'):input).replace(/^\uFEFF/,''))},undefined,{timeout:55000});
for(const c of result.content||[])if(c.type==='text')console.log(c.text);
}finally{await client.close();}})().catch(e=>{console.error(e.message);process.exitCode=1;});
