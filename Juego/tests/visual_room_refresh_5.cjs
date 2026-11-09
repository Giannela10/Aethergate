const fs=require('node:fs'),path=require('node:path');
const dir=path.resolve(__dirname,'../reports/visual_5');
const baseline=JSON.parse(fs.readFileSync(path.join(dir,'before_views.json'),'utf8'));
const jobs=[];
for(const v of baseline.filter(v=>/room_(046|054|062)_/.test(v.label))){
 const vec=s=>'Vector3'+s;
 jobs.push({tool:'execute_code',arguments:{code:`get_node('/root/VisualInspection5').call('view','${v.label}',${vec(v.camera)},${vec(v.target)})`}});
}
fs.writeFileSync(path.join(dir,'room_refresh_commands.json'),JSON.stringify(jobs,null,2));
