const fs=require('fs'),path=require('path');
const dir=path.resolve(__dirname,'../reports/characters_6_3'),rows=[];
for(const batch of [4,5,6,7]){
 const file=path.join(dir,`batch${batch}_validation.json`);if(!fs.existsSync(file))throw Error(`Missing batch ${batch}`);
 const result=JSON.parse(fs.readFileSync(file));
 if(result.failures.length)throw Error(`Batch ${batch} failed`);
 const coverage=JSON.parse(fs.readFileSync(path.join(dir,`batch${batch}_coverage.json`)));
 const active=coverage.filter(x=>x.visible&&!Object.keys(x.remodel||{}).length);
 const exceptions=active.map(x=>({id:x.id,path:x.path,reason:x.path.includes('/Player/')?'Protagonist separate 6.2 integration':'Unknown/special representation; preserved'}));
 rows.push({batch,remodelled:result.remodelled,exceptions});
}
fs.writeFileSync(path.join(dir,'rollout_summary.json'),JSON.stringify(rows,null,2));console.log(JSON.stringify(rows));
