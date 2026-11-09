// Format 4 scene matrices store rows. Correct only the fourteen reviewed rotations.
const fs=require('node:fs'),path=require('node:path');
const file=path.resolve(__dirname,'../Main.tscn');let count=0;
let scene=fs.readFileSync(file,'utf8').replace(/^\[node [^\r\n]+\][\s\S]*?(?=^\[|$(?![\s\S]))/gm,b=>{
 const h=b.split('\n')[0];
 if(!(/parent="Piso[5-8]\/VestibuloAscensores"/.test(h)&&/name="(?:PlanoPisos|CartelPlano|CabeceraPlano)"/.test(h))&&!(/parent="Piso2\/AuditorioPiso2e\/AuditorioAmpliado"/.test(h)&&/name="LetreroEntrada/.test(h)))return b;
 const old='Transform3D(0, 0, -1, 0, 1, 0, 1, 0, 0,';
 if(!b.includes(old))throw Error('Unexpected transform in '+h);
 count++;return b.replace(old,'Transform3D(0, 0, 1, 0, 1, 0, -1, 0, 0,');
});
if(count!==14)throw Error('Expected 14 reviewed corrections, got '+count);
fs.writeFileSync(file,scene);console.log(JSON.stringify({corrected_scene_matrix_rows:count}));
