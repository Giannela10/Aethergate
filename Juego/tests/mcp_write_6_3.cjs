const fs=require('fs'),path=require('path'),cp=require('child_process');
const local=path.resolve(process.argv[2]);
const resource='res://'+path.relative(path.resolve(__dirname,'..'),local).replaceAll('\\','/');
const content=fs.readFileSync(local,'utf8').replace(/^( +)/gm,spaces=>'\t'.repeat(spaces.length));
const job=path.join(__dirname,'mcp_write_6_3.json');
fs.writeFileSync(job,JSON.stringify({file_path:resource,content}));
cp.execFileSync(process.execPath,[path.join(__dirname,'visual_mcp_5.cjs'),'script_write','@'+job],{stdio:'inherit'});
