const fs=require('fs'),path=require('path'),cp=require('child_process');const project=path.resolve(__dirname,'..');
const file='res://scripts/education/mentor_activity_v4.gd';
let code=fs.readFileSync(path.join(project,'scripts/education/mentor_activity_v4.gd'),'utf8').replaceAll('\r\n','\n');
code=code.replace('var activity: Dictionary','var activity: Dictionary\nvar practice_mode=false\nvar local_service=preload("res://scripts/education/local_practice_service.gd").new()\nvar page_generation=0');
code=code.replace('func open() -> void:',`func open() -> void:
	campaign.ui.dialog("ACTIVIDAD DEL DOCENTE","Elige la fuente. La práctica local es material original no validado por Duoc UC y no otorga desbloqueos oficiales.",["PRÁCTICA LOCAL","BANCO PUBLICADO","VOLVER"],[open_local,open_published,campaign.ui.close_modal],true)
func open_local() -> void:
	practice_mode=true
	_open_activity()
func open_published() -> void:
	practice_mode=false
	_open_activity()
func _open_activity() -> void:`);
code=code.replace('activity = await service.fetch(floor_number,"teacher_challenge",mentor_id)','page_generation+=1\n\tvar generation=page_generation\n\tactivity = local_service.fetch(floor_number,"teacher_challenge",mentor_id) if practice_mode else await service.fetch(floor_number,"teacher_challenge",mentor_id)\n\tif generation!=page_generation: return');
code=code.replace('campaign.ui.dialog("ACTIVIDAD NO DISPONIBLE",activity.error,["VOLVER"],[campaign.ui.close_modal],true)','campaign.ui.dialog("ACTIVIDAD NO DISPONIBLE",activity.error+" Un fallo de recuperación no demuestra un banco vacío.",["PRÁCTICA LOCAL","VOLVER"],[open_local,campaign.ui.close_modal],true)');
code=code.replace('"El resultado educativo se valida por separado de la simulación de combate."','"PRÁCTICA LOCAL · sin validación institucional ni recompensas oficiales." if practice_mode else "El resultado educativo se valida por separado de la simulación de combate."');
code=code.replace('var result := await service.submit(str(activity.id),value,"teacher_challenge")','var result: Dictionary = local_service.submit(str(activity.id),value,"teacher_challenge") if practice_mode else await service.submit(str(activity.id),value,"teacher_challenge")');
code=code.replace('[open,campaign.ui.close_modal]','[open_local if practice_mode else open_published,campaign.ui.close_modal]');
// Copy exact original spans for CRLF-sensitive MCP edits.
const basePath=path.join(project,'scripts/campaign/boss_duel_controller.gd');let base=fs.readFileSync(basePath,'utf8').replaceAll('\r\n','\n');
base=base.replace('campaign.ui.dialog(boss_name,missing,["Ahora no"],[campaign.ui.close_modal],true)','campaign.ui.dialog(boss_name,missing+"\\nPuedes practicar sin iniciar la simulación.",["ACTIVIDAD DEL DOCENTE","Ahora no"],[learn_from_mentor,campaign.ui.close_modal],true)');
base=base.replace('if boss_id=="director": campaign.ui.dialog','if boss_id in ["director","profesor_redes"]: campaign.ui.dialog');
base=base.replace('["Hasta luego"],[campaign.ui.close_modal],true)','["ACTIVIDAD DEL DOCENTE","Hasta luego"],[learn_from_mentor,campaign.ui.close_modal],true)');
const academicPath=path.join(project,'scripts/campaign/academic_boss_duel.gd');let academic=fs.readFileSync(academicPath,'utf8').replaceAll('\r\n','\n');
academic=academic.replace('["Continuar"],[campaign.ui.close_modal],true)','["ACTIVIDAD DEL DOCENTE","Continuar"],[learn,campaign.ui.close_modal],true)');
const jobs=[{tool:'script_write',arguments:{file_path:'res://scripts/education/local_practice_service.gd',content:fs.readFileSync(path.join(project,'scripts/education/local_practice_service.gd'),'utf8')}},{tool:'script_write',arguments:{file_path:file,content:code}},{tool:'script_write',arguments:{file_path:'res://scripts/campaign/boss_duel_controller.gd',content:base}},{tool:'script_write',arguments:{file_path:'res://scripts/campaign/academic_boss_duel.gd',content:academic}}];
const job=path.join(__dirname,'capstone_education_install.json');fs.writeFileSync(job,JSON.stringify(jobs));cp.execFileSync(process.execPath,[path.join(__dirname,'visual_mcp_5.cjs'),'run',job],{stdio:'inherit'});
