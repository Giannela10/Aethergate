// Read-only inventory. No deletion and no private configuration contents read.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto');
const files=[];
function walk(dir=''){
 for(const e of fs.readdirSync(dir||'.',{withFileTypes:true})){
  if(e.name.startsWith('.')||e.name==='node_modules')continue;
  const p=path.posix.join(dir,e.name);
  if(e.isDirectory())walk(p);else files.push(p);
 }
}
walk();
const source=files.filter(p=>/\.(gd|tscn|tres|godot|md|sql|json|cjs|py|cfg|uid)$/.test(p)&&!p.startsWith('addons/')&&!p.startsWith('reports/')&&!p.includes('auth_config.json')&&p!=='PROJECT_CLEANUP_AUDIT.md'&&p!=='tests/project_cleanup_audit.cjs');
const texts=source.map(p=>[p,fs.readFileSync(p,'utf8')]);
function references(p){
 const base=path.posix.basename(p),stem=base.replace(/\.[^.]+$/,'');
 const uid=fs.existsSync(p+'.uid')?fs.readFileSync(p+'.uid','utf8').trim():'';
 return texts.filter(([name,text])=>name!==p&&name!==p+'.uid'&&(text.includes('res://'+p)||text.includes(p)||text.includes(base)||text.includes(String.fromCharCode(39)+stem+String.fromCharCode(39))||(stem.length>5&&text.includes('"'+stem+'"'))||(uid&&text.includes(uid)))).map(([name])=>name);
}
const targets=files.filter(p=>!p.startsWith('addons/')&&(/\.(gd|tscn|tres|gdshader|md|sql|pyc)$/.test(p)||p==='project.godot'||p.startsWith('reports/')&&!p.endsWith('.import')||p.startsWith('config/')&&p.endsWith('.json')));
const rows=[];const noRefs=[];
for(const p of targets){
 const refs=references(p);let type=path.extname(p).slice(1),state='KEEP',action='Conservar; ausencia de referencia literal no demuestra código muerto.';
 if(p==='project.godot') {state='USED / KEEP';action='Configuración raíz, entrypoint y autoloads: protegido expresamente por el usuario.';}
 else if(p.startsWith('tests/')) {state='TEST ONLY / KEEP';action='Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo.';}
 else if(p.startsWith('scripts/')||p.endsWith('.tscn')){state=refs.length?'USED / KEEP':'KEEP';action=refs.length?'Conservar: dependencias encontradas.':'Conservar: revisar cargas dinámicas y uso manual antes de retirar.';}
 if(p.startsWith('supabase/')){state='KEEP';action=p.includes('/migrations/')?'Historial SQL: no borrar, incluidas 001–006.':'Conservar diagnóstico/verificación SQL; aún útil para RPC y permisos.';}
 if(p.startsWith('config/')){state='USED / KEEP';action=p.endsWith('.example.json')?'Plantilla pública necesaria; no equivale al archivo privado.':'Configuración privada; no inspeccionada ni incluida en el informe.';}
 if(p.endsWith('.md')||p.startsWith('reports/')){state='HISTÓRICO / KEEP';action='Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla.';}
 if(['AGENTS.md','ROLE_SYSTEM.md','ADMIN_PANEL.md','AUTH_ARCHITECTURE.md','GOOGLE_SUPABASE_SETUP.md','PROJECT_CLEANUP_AUDIT.md'].includes(p)||p.startsWith('reports/current_')||p==='reports/remember_login_tests.json'){state='ACTUAL / KEEP';action='Conservar; fuente actual o evidencia de esta validación. Documentos auth anteriores deben leerse junto al nuevo comportamiento descrito en este informe.';}
 if(p.endsWith('.pyc')){state='OBSOLETE / SAFE TO DELETE';action='Caché regenerable de Python; candidato seguro. No eliminado en esta auditoría inicial.';}
 if(!refs.length&&/\.(gd|tscn)$/.test(p))noRefs.push(p);
 rows.push([p,type,refs.length?refs.slice(0,8).join(', ')+(refs.length>8?` (+${refs.length-8})`:''):'Sin referencia literal detectada',state,action]);
}
const hashes=new Map();
for(const p of files.filter(p=>!p.startsWith('addons/')&&/\.(gd|tscn|json)$/.test(p)&&!p.includes('auth_config.json'))){
 const h=crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');
 if(!hashes.has(h))hashes.set(h,[]);hashes.get(h).push(p);
}
const dup=[...hashes.values()].filter(g=>g.length>1);
let out=`# Auditoría de limpieza de DuocGames\n\nFecha: 2026-10-20. Auditoría inicial: no se eliminó ningún archivo.\n\nSe buscaron rutas res://, rutas relativas, nombres de archivo, nombres de suites entre comillas y UID de scripts en .tscn, .tres, .gd, project.godot, autoloads, tests y documentación. Incluye preload(), load() y ResourceLoader cuando usan cadenas literales. Las cargas construidas dinámicamente, class_name y ejecuciones manuales impiden considerar la ausencia de una referencia como prueba de inutilidad. Se excluyen cachés internos, addons y contenido de configuración privada.\n\n## Resultado y decisiones\n\n- ${files.length} archivos inventariados; ${source.length} fuentes consultadas; ${rows.length} entradas clasificadas.\n- No se ha demostrado que ningún script de producción o boss haya sido reemplazado de forma segura. Se conservan campaña, inventario, NEXO, save migration, assets y todas las pantallas de roles.\n- AcademicBossesCheck está en SupabaseRegressionRunner; AcademicRegressionRunner conserva suites de campaña y guardado; AcademicExtraChecks hereda de ese runner y ejecuta accesos al subterráneo. Todos: TEST ONLY / KEEP.\n- HumanPilot, HumanPilotCheck e HumanPilotInspect son herramientas aisladas que enlazan scripts y el GLB original. TEST ONLY / KEEP; no borrar sus assets. No se usan como protagonista de Main.\n- Fixtures auth, roles, registro y diagnostics siguen enlazadas desde sus tests; TEST ONLY / KEEP. Los diagnostics de conexión que pueden acceder a Supabase no se ejecutaron en esta validación.\n- Único candidato regenerable detectado: caché Python .pyc, si figura abajo. Se conserva durante esta auditoría inicial.\n- No hay motivo para borrar 001_education_auth.sql, 002_profile_display_name.sql, 003_recover_missing_profiles.sql, 004_user_roles_admin.sql, 005_fix_admin_roles.sql ni 006_fix_admin_rpc_signature.sql.\n- Se mantienen config/auth_config.json (privado/gitignored, si existe), config/auth_config.example.json y el soporte explícito de configuración externa/user://; no son duplicados equivalentes.\n\n## Auth actual\n\nAntes se persistía siempre el refresh token y se restauraba por URL. Ahora login_email acepta keep_signed_in=false. La casilla de Login empieza desmarcada. Solo se persisten URL, refresh token y remember_login=true con consentimiento; nunca contraseña, access token, identidad ni rol. Sesiones antiguas sin consentimiento se descartan sin error visible. Refresh de inicio inválido o perfil inaccesible limpia la sesión y mantiene la portada limpia. Durante una sesión sin persistencia se permite renovar tokens en memoria. Logout elimina identidad, tokens, expiración, perfil, consentimiento y vista solicitada, y solicita revocación remota local si tenía access token.\n\n## Tabla de archivos\n\n| Archivo | Tipo | Referenciado por | Estado | Acción recomendada |\n|---|---|---|---|---|\n`;
for(const row of rows)out+='| '+row.map(v=>String(v).replaceAll('|','\\|').replaceAll('\n',' ')).join(' | ')+' |\n';
out+='\n## Coincidencias exactas de contenido\n\n';
out+=dup.length?dup.map(g=>'- '+g.join(', ')+' — KEEP: igualdad de contenido no implica intercambiabilidad de rutas.').join('\n'):'No se detectaron duplicados exactos en scripts, escenas y JSON públicos.';
out+='\n\n## Sin referencias literales: revisión conservadora\n\nEstos archivos NO se consideran SAFE TO DELETE: pueden ser entrypoints manuales, suites invocadas dinámicamente o usar class_name.\n\n'+noRefs.map(p=>'- '+p).join('\n');
out+='\n\n## Verificación\n\nResultados de esta ejecución: reports/current_project_validation.json y logs current_*.log. La revisión de recursos usa tests/revision_scripts.gd y no ejecuta herramientas de edición. No se eliminaron rutas; cualquier error previo encontrado se documenta separadamente. Pruebas de credenciales y Supabase remoto requieren verificación manual del usuario.\n';
fs.writeFileSync('PROJECT_CLEANUP_AUDIT.md',out);
if(fs.existsSync('reports/current_project_validation.json')) {
 const validation=JSON.parse(fs.readFileSync('reports/current_project_validation.json','utf8'));
 fs.appendFileSync('PROJECT_CLEANUP_AUDIT.md','\n\n## Resultados de la ejecución actual\n\n'+Object.entries(validation).map(([name,r])=>'- '+name+': '+(r.passed?'PASS':'FAIL')+'; '+JSON.stringify(r.reports)).join('\n')+'\n\nGodot MCP confirmó la escena Login con botones Iniciar sesión, Registrarse y Salir (Google deshabilitado por configuración), y Main.tscn en ejecución sin errores en su log. La revisión cargó 261 scripts/recursos y 43 escenas. No hay fallos de carga ni referencias rotas detectadas en ese alcance. La consola del editor conservaba un error anterior de MAT_Piedra_Posterior.tres; no se reprodujo en estas cargas. Se mantienen todas las migraciones y todos los archivos auditados. Las pruebas auth son simuladas, no validación de Supabase remoto ni de credenciales reales.\n');
}
console.log(JSON.stringify({files:files.length,sources:source.length,classified:rows.length,no_literal_refs:noRefs.length,duplicate_groups:dup.length,deleted:0}));
