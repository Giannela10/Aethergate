const fs=require('node:fs'),path=require('node:path');
const project=path.resolve(__dirname,'..');
const rel=fs.readFileSync(path.join(project,'reports/final_7_1/active_run.txt'),'utf8').trim().replace(/^Juego\//,'');
const out=path.join(project,rel),read=p=>fs.readFileSync(p,'utf8').replace(/^\uFEFF/,'').replaceAll('\r\n','\n');
const quests=read(path.join(project,'scripts/campaign/quest_manager.gd'));
const cleanQuests=quests.replace(/\t# pc5\/pc6\/pc7 are persistent IDs[\s\S]*?(?=\tdefinitions.academico3)/,'');
const lab=read(path.join(project,'scripts/education/teaching_lab_v4.gd'));
const cleanLab=lab.split('\n').filter(s=>!s.includes('# The screen bottom is 1.025')&&!s.includes('# display a real stand rather')&&!s.includes('box("BaseMonitor",')&&!s.includes('box("SoporteMonitor",')).join('\n');
const checks=[
 {test:'quest_source_only_caption_block',status:cleanQuests===read(path.join(out,'recovery/quest_manager.before.gd.txt'))?'PASS':'FAIL'},
 {test:'lab_source_only_monitor_stands',status:cleanLab===read(path.join(out,'recovery/teaching_lab_v4.before.gd.txt'))?'PASS':'FAIL'}
];
fs.writeFileSync(path.join(out,'source_integrity.json'),JSON.stringify(checks,null,2),{flag:'wx'});
if(checks.some(r=>r.status==='FAIL'))throw Error(JSON.stringify(checks));
const freshFile=path.join(out,'fresh_Main_checks_v2.json');
const fresh=fs.existsSync(freshFile)?JSON.parse(read(freshFile)):[];
if(fresh.length!==6||fresh.some(r=>r.status!=='PASS'))throw Error('Fresh Main checks incomplete/failing');
for(const name of ['FLOORS_3_TO_8_FINAL_REPORT.md',...Array.from({length:6},(_,i)=>`FLOOR_${i+3}_FINAL_AUDIT.md`)]){
 const file=path.join(project,name);let text=read(file).replaceAll('change_scope.json','change_scope_v2.json');
 if(name==='FLOORS_3_TO_8_FINAL_REPORT.md')text+='\n## Verificación final desde disco\n\nSe detuvo la fixture acumulada y se abrió una segunda instancia fresca de Main desde sus archivos actuales, con persistencia personal y nube desactivadas. Seis comprobaciones PASS: Main listo, aislamiento de guardados, 24 bases de monitores, 22 cuerpos de cerca, los tres textos opcionales UTF-8 y campaña sin Director/NEXO completados artificialmente. [Resultados]('+rel+'/fresh_Main_checks.json).\n\nComparación adicional de fuentes con recuperación: eliminando sólo el bloque nuevo de textos, QuestManager es idéntico al anterior; eliminando sólo comentarios y los dos soportes, TeachingLab es idéntico. [Integridad]('+rel+'/source_integrity.json).\n\nLa primera comparación de recuperación marcó cinco .gd.uid distintos porque Godot reimportó los scripts dentro de la copia y regeneró sus UID. Sus fuentes siguieron idénticas; los cinco UID del proyecto activo se verificaron contra HEAD y no cambiaron. change_scope_v2.json documenta ese método. No usar los UID regenerados de la carpeta de recuperación para restaurar: mantener los UID activos/HEAD. El primer change_scope.json conserva el diagnóstico FAIL inicial, no el resultado final.\n';
 fs.writeFileSync(file,text);
}
console.log(JSON.stringify({source_checks:checks,fresh_Main:fresh.length}));
