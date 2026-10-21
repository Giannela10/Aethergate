# Auditoría de limpieza de DuocGames

Fecha: 2026-10-20. Auditoría inicial: no se eliminó ningún archivo.

Se buscaron rutas res://, rutas relativas, nombres de archivo, nombres de suites entre comillas y UID de scripts en .tscn, .tres, .gd, project.godot, autoloads, tests y documentación. Incluye preload(), load() y ResourceLoader cuando usan cadenas literales. Las cargas construidas dinámicamente, class_name y ejecuciones manuales impiden considerar la ausencia de una referencia como prueba de inutilidad. Se excluyen cachés internos, addons y contenido de configuración privada.

## Resultado y decisiones

- 1543 archivos inventariados; 733 fuentes consultadas; 571 entradas clasificadas.
- No se ha demostrado que ningún script de producción o boss haya sido reemplazado de forma segura. Se conservan campaña, inventario, NEXO, save migration, assets y todas las pantallas de roles.
- AcademicBossesCheck está en SupabaseRegressionRunner; AcademicRegressionRunner conserva suites de campaña y guardado; AcademicExtraChecks hereda de ese runner y ejecuta accesos al subterráneo. Todos: TEST ONLY / KEEP.
- HumanPilot, HumanPilotCheck e HumanPilotInspect son herramientas aisladas que enlazan scripts y el GLB original. TEST ONLY / KEEP; no borrar sus assets. No se usan como protagonista de Main.
- Fixtures auth, roles, registro y diagnostics siguen enlazadas desde sus tests; TEST ONLY / KEEP. Los diagnostics de conexión que pueden acceder a Supabase no se ejecutaron en esta validación.
- Único candidato regenerable detectado: caché Python .pyc, si figura abajo. Se conserva durante esta auditoría inicial.
- No hay motivo para borrar 001_education_auth.sql, 002_profile_display_name.sql, 003_recover_missing_profiles.sql, 004_user_roles_admin.sql, 005_fix_admin_roles.sql ni 006_fix_admin_rpc_signature.sql.
- Se mantienen config/auth_config.json (privado/gitignored, si existe), config/auth_config.example.json y el soporte explícito de configuración externa/user://; no son duplicados equivalentes.

## Auth actual

Antes se persistía siempre el refresh token y se restauraba por URL. Ahora login_email acepta keep_signed_in=false. La casilla de Login empieza desmarcada. Solo se persisten URL, refresh token y remember_login=true con consentimiento; nunca contraseña, access token, identidad ni rol. Sesiones antiguas sin consentimiento se descartan sin error visible. Refresh de inicio inválido o perfil inaccesible limpia la sesión y mantiene la portada limpia. Durante una sesión sin persistencia se permite renovar tokens en memoria. Logout elimina identidad, tokens, expiración, perfil, consentimiento y vista solicitada, y solicita revocación remota local si tenía access token.

## Tabla de archivos

| Archivo | Tipo | Referenciado por | Estado | Acción recomendada |
|---|---|---|---|---|
| ACADEMIC_BOSSES_3_0.md | md | BALANCE_1_0.md, BALANCE_REPORT_1_0.md, PLAYTEST_1_0.md, RESUMEN_JUEGO.md | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| ADMIN_PANEL.md | md | AUTH_ARCHITECTURE.md, EDUCATION_SYSTEM_1_0.md, GOOGLE_SUPABASE_SETUP.md | ACTUAL / KEEP | Conservar; fuente actual o evidencia de esta validación. Documentos auth anteriores deben leerse junto al nuevo comportamiento descrito en este informe. |
| AGENTS.md | md | INFORME_PARA_IA.md, PERSONAJES_2_0.md, supabase/seeds/001_subjects.sql | ACTUAL / KEEP | Conservar; fuente actual o evidencia de esta validación. Documentos auth anteriores deben leerse junto al nuevo comportamiento descrito en este informe. |
| ARQUITECTURA_REFERENCIAS_2026_10.md | md | RESUMEN_JUEGO.md | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| AuditorioAccessCheck.tscn | tscn | README.md | USED / KEEP | Conservar: dependencias encontradas. |
| AUTH_ARCHITECTURE.md | md | EDUCATION_SYSTEM_1_0.md, RESUMEN_JUEGO.md, ROLE_SYSTEM.md | ACTUAL / KEEP | Conservar; fuente actual o evidencia de esta validación. Documentos auth anteriores deben leerse junto al nuevo comportamiento descrito en este informe. |
| BALANCE_1_0.md | md | BALANCE_REPORT_1_0.md, RESUMEN_JUEGO.md, tests/build_balance_docs.py | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| BALANCE_REPORT_1_0.md | md | RESUMEN_JUEGO.md | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| BOSSES_SUPERIORES_2_0.md | md | BALANCE_1_0.md, BALANCE_REPORT_1_0.md, PERSONAJES_2_0.md, RESUMEN_JUEGO.md | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| CAMPANA.md | md | GUIA.md, README.md, REVISION.md | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| CAMPUS_VIVO_2_0.md | md | RESUMEN_JUEGO.md | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| CELULAR_Y_MENSAJES.md | md | RESUMEN_JUEGO.md | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| Character.tscn | tscn | INVENTARIO.md, REVISION.md, tests/gameplay_regression.gd | USED / KEEP | Conservar: dependencias encontradas. |
| CIERRE_CAMPANA_1_0.md | md | BALANCE_1_0.md, BALANCE_REPORT_1_0.md, RESUMEN_JUEGO.md, tests/build_balance_docs.py | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| config/auth_config.example.json | json | GOOGLE_SUPABASE_SETUP.md, tests/supabase_config_audit.py | USED / KEEP | Plantilla pública necesaria; no equivale al archivo privado. |
| config/auth_config.json | json | AUTH_ARCHITECTURE.md, EDUCATION_SYSTEM_1_0.md, GOOGLE_SUPABASE_SETUP.md, scripts/auth/auth_manager.gd, tests/supabase_config_audit.py | USED / KEEP | Configuración privada; no inspeccionada ni incluida en el informe. |
| EDUCATION_SYSTEM_1_0.md | md | RESUMEN_JUEGO.md | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| ERRORES.md | md | GUIA.md | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| FLOOR3_EDUCATION_PLAN.md | md | EDUCATION_SYSTEM_1_0.md, RESUMEN_JUEGO.md | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| GOOGLE_SUPABASE_SETUP.md | md | EDUCATION_SYSTEM_1_0.md, PLAYTEST_1_0.md, RESUMEN_JUEGO.md | ACTUAL / KEEP | Conservar; fuente actual o evidencia de esta validación. Documentos auth anteriores deben leerse junto al nuevo comportamiento descrito en este informe. |
| GUIA.md | md | INFORME_PARA_IA.md, README.md, REVISION.md | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| GUIA_CREAR_CONTENIDO.md | md | CAMPUS_VIVO_2_0.md, RESUMEN_JUEGO.md | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| HORARIO_Y_ASISTENCIA.md | md | RESUMEN_JUEGO.md | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| HUMAN_MODEL_IMPORT.md | md | PERSONAJES_2_0.md, RESUMEN_JUEGO.md | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| HUMAN_PILOT_REPORT.md | md | HUMAN_MODEL_IMPORT.md | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| INFORME_PARA_IA.md | md | Sin referencia literal detectada | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| INTERACCIONES_CONTEXTUALES.md | md | RESUMEN_JUEGO.md | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| interior_coordinacion_referencia.gd | gd | Main.tscn | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| INVENTARIO.md | md | CAMPANA.md, README.md | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| LibraryAccessCheck.tscn | tscn | README.md | USED / KEEP | Conservar: dependencias encontradas. |
| madera_amarilla.gdshader | gdshader | Main.tscn | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| Main.tscn | tscn | ACADEMIC_BOSSES_3_0.md, ARQUITECTURA_REFERENCIAS_2026_10.md, AuditorioAccessCheck.tscn, AUTH_ARCHITECTURE.md, BALANCE_1_0.md, BALANCE_REPORT_1_0.md, CAMPANA.md, CELULAR_Y_MENSAJES.md (+69) | USED / KEEP | Conservar: dependencias encontradas. |
| materials/entrance/celosia_posterior.gdshader | gdshader | Main.tscn, materials/entrance/MAT_Celosia_Posterior.tres, scripts/exterior/patio_posterior_duoc.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/cielo_listones_biblioteca.gdshader | gdshader | Main.tscn, materials/entrance/MAT_Cielo_Listones_Biblioteca.tres, scripts/compartidos/edicion/interiores_referencia_campus.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/ENV_Exterior_Duoc.tres | tres | Main.tscn | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/hormigon_costados.gdshader | gdshader | Main.tscn, scripts/exterior/costados_referencia_fotos.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/madera_auditorio.gdshader | gdshader | materials/entrance/MAT_Auditorium_Plywood.tres | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/madera_escalera.gdshader | gdshader | Main.tscn, materials/entrance/MAT_Madera_Escalera_Principal.tres, scripts/compartidos/edicion/acabados_escalera_principal.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/madera_salas_fotos.gdshader | gdshader | ARQUITECTURA_REFERENCIAS_2026_10.md, Main.tscn, scripts/exterior/arquitectura_fotos_octubre.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/MAT_Acero_Inoxidable_Ascensor.tres | tres | Main.tscn, scripts/compartidos/edicion/acabados_ascensores.gd, scripts/compartidos/edicion/interiores_referencia_campus.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/MAT_Aros_Naranjos.tres | tres | Main.tscn, scripts/exterior/patio_posterior_duoc.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/MAT_Asfalto_Estacionamientos.tres | tres | Main.tscn, scripts/exterior/patio_posterior_duoc.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/MAT_Auditorium_Plywood.tres | tres | Main.tscn, scripts/compartidos/edicion/elevar_base_auditorio.gd, scripts/pisos/piso_2/auditorio_piso_2e.gd, scripts/pisos/piso_5/terraza_piso_5_referencia.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/MAT_Auto_Azul.tres | tres | Main.tscn, scripts/exterior/patio_posterior_duoc.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/MAT_Auto_Blanco.tres | tres | Main.tscn, scripts/exterior/patio_posterior_duoc.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/MAT_Auto_Gris.tres | tres | Main.tscn, scripts/exterior/patio_posterior_duoc.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/MAT_Auto_Rojo.tres | tres | Main.tscn, scripts/exterior/patio_posterior_duoc.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/MAT_Cancha_Gris.tres | tres | Main.tscn, scripts/exterior/patio_posterior_duoc.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/MAT_Caseta_Crema.tres | tres | Main.tscn, scripts/exterior/patio_posterior_duoc.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/MAT_Celosia_Posterior.tres | tres | Main.tscn, scripts/exterior/estructura_y_acceso_posterior.gd, scripts/exterior/patio_posterior_duoc.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/MAT_Cielo_Listones_Biblioteca.tres | tres | Main.tscn, scripts/compartidos/edicion/interiores_referencia_campus.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/MAT_Columns_Concrete.tres | tres | Main.tscn, materials/entrance/asignaciones.json, scripts/compartidos/edicion/piso_menos_uno_y_emergencia.gd, scripts/exterior/aplicar_materiales_entrada.gd, scripts/exterior/estructura_y_acceso_posterior.gd, scripts/exterior/fachada_referencia_duoc.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/MAT_Concrete_Floor.tres | tres | Main.tscn, materials/entrance/asignaciones.json, scripts/exterior/aplicar_materiales_entrada.gd, scripts/exterior/estructura_y_acceso_posterior.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/MAT_Corridor_Cladding_Light.tres | tres | Main.tscn, scripts/compartidos/edicion/interiores_referencia_campus.gd, scripts/compartidos/edicion/sala_impresiones_y_vidrios.gd, scripts/pisos/piso_2/acabados_piso_dos.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/MAT_Detalle_Amarillo_Duoc.tres | tres | Main.tscn, scripts/compartidos/edicion/interiores_referencia_campus.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/MAT_Facade_Dark.tres | tres | materials/entrance/asignaciones.json, scripts/exterior/aplicar_materiales_entrada.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/MAT_Facade_Glass_Duoc.tres | tres | Main.tscn, scripts/exterior/fachada_referencia_duoc.gd, scripts/exterior/patio_posterior_duoc.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/MAT_Glass_Entrance.tres | tres | Main.tscn, scripts/compartidos/edicion/sala_impresiones_y_vidrios.gd, scripts/exterior/aplicar_materiales_entrada.gd, scripts/exterior/estructura_y_acceso_posterior.gd, scripts/exterior/fachada_referencia_duoc.gd, scripts/pisos/piso_2/acabados_piso_dos.gd, scripts/pisos/piso_4/piso_4_referencia.gd, scripts/pisos/piso_5/terraza_piso_5_referencia.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/MAT_Grass.tres | tres | Main.tscn, scripts/exterior/aplicar_materiales_entrada.gd, scripts/exterior/fachada_referencia_duoc.gd, scripts/exterior/patio_posterior_duoc.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/MAT_Hormigon_Patio.tres | tres | Main.tscn, scripts/exterior/patio_posterior_duoc.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/MAT_Interior_Floor_Dark.tres | tres | Main.tscn, scripts/compartidos/edicion/interiores_referencia_campus.gd, scripts/compartidos/edicion/piso_menos_uno_y_emergencia.gd, scripts/compartidos/edicion/reparar_continuidad_pisos.gd, scripts/exterior/estructura_y_acceso_posterior.gd, scripts/pisos/piso_1/interior_coordinacion.gd, scripts/pisos/piso_2/acabados_piso_dos.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/MAT_Lineas_Cancha.tres | tres | Main.tscn, scripts/exterior/patio_posterior_duoc.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/MAT_Lower_Wall_Light.tres | tres | materials/entrance/asignaciones.json, scripts/exterior/aplicar_materiales_entrada.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/MAT_Luz_Cabina.tres | tres | Main.tscn, scripts/compartidos/edicion/acabados_ascensores.gd, scripts/compartidos/edicion/interiores_referencia_campus.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/MAT_Madera_Biblioteca.tres | tres | Main.tscn, scripts/compartidos/edicion/interiores_referencia_campus.gd, scripts/compartidos/edicion/sala_impresiones_y_vidrios.gd, scripts/exterior/fachada_referencia_duoc.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/MAT_Madera_Escalera_Principal.tres | tres | Main.tscn, scripts/compartidos/edicion/acabados_escalera_principal.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/MAT_Meson_Biblioteca_Azul.tres | tres | Main.tscn, scripts/compartidos/edicion/interiores_referencia_campus.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/MAT_Metal_Dark.tres | tres | Main.tscn, materials/entrance/asignaciones.json, scripts/compartidos/edicion/barandas_pasillos.gd, scripts/compartidos/edicion/interiores_referencia_campus.gd, scripts/compartidos/edicion/sala_impresiones_y_vidrios.gd, scripts/exterior/aplicar_materiales_entrada.gd, scripts/exterior/estructura_y_acceso_posterior.gd, scripts/exterior/fachada_referencia_duoc.gd (+3) | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/MAT_Metal_Posterior.tres | tres | Main.tscn, scripts/exterior/patio_posterior_duoc.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/MAT_Neumaticos.tres | tres | Main.tscn, scripts/exterior/patio_posterior_duoc.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/MAT_Peldanos_Oscuros.tres | tres | Main.tscn, scripts/compartidos/edicion/acabados_escalera_principal.gd, scripts/compartidos/edicion/piso_menos_uno_y_emergencia.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/MAT_Piedra_Posterior.tres | tres | Main.tscn, scripts/exterior/estructura_y_acceso_posterior.gd, scripts/exterior/fachada_referencia_duoc.gd, tests/gameplay_regression.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/MAT_Puerta_Ascensor_Grafica.tres | tres | Main.tscn, scripts/compartidos/edicion/interiores_referencia_campus.gd, scripts/compartidos/edicion/sala_impresiones_y_vidrios.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/MAT_Reja_Posterior.tres | tres | Main.tscn, scripts/exterior/patio_posterior_duoc.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/MAT_Terrace_Paving.tres | tres | Main.tscn, scripts/exterior/estructura_y_acceso_posterior.gd, scripts/exterior/fachada_referencia_duoc.gd, scripts/pisos/piso_5/terraza_piso_5_referencia.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/MAT_Ventana_Biblioteca.tres | tres | Main.tscn, scripts/compartidos/edicion/interiores_referencia_campus.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/MAT_Vidrio_Acceso_Casino.tres | tres | Main.tscn, scripts/exterior/fachada_referencia_duoc.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/MAT_Vidrio_Autos.tres | tres | Main.tscn, scripts/exterior/patio_posterior_duoc.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/MAT_Vidrio_Panoramico_Ascensor.tres | tres | Main.tscn, scripts/compartidos/edicion/acabados_ascensores.gd, scripts/compartidos/edicion/interiores_referencia_campus.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/MAT_Vidrio_Posterior_Oscuro.tres | tres | Sin referencia literal detectada | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/MAT_Window_Dark.tres | tres | Main.tscn, scripts/exterior/aplicar_materiales_entrada.gd, scripts/exterior/fachada_referencia_duoc.gd, scripts/pisos/piso_2/acabados_piso_dos.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/MAT_Window_Upper.tres | tres | Main.tscn | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/MAT_Wood_Cladding.tres | tres | Main.tscn, scripts/exterior/fachada_referencia_duoc.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/muro_pasillo_claro.gdshader | gdshader | materials/entrance/MAT_Corridor_Cladding_Light.tres | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/pavimento_exterior_fotos.gdshader | gdshader | ARQUITECTURA_REFERENCIAS_2026_10.md, Main.tscn, scripts/exterior/arquitectura_fotos_octubre.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/pavimento_terraza.gdshader | gdshader | materials/entrance/MAT_Terrace_Paving.tres | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/piedra_estacionamiento.gdshader | gdshader | materials/entrance/MAT_Piedra_Posterior.tres | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/piso_fotos.gdshader | gdshader | ARQUITECTURA_REFERENCIAS_2026_10.md, Main.tscn, scripts/compartidos/edicion/unificar_piso_negro.gd, scripts/exterior/arquitectura_fotos_octubre.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/piso_interior_oscuro.gdshader | gdshader | materials/entrance/MAT_Interior_Floor_Dark.tres | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/piso_menos1_hormigon.gdshader | gdshader | Main.tscn, scripts/pisos/piso_menos_1/reconstruccion_visual_2026.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/revestimiento_duoc.gdshader | gdshader | materials/entrance/MAT_Wood_Cladding.tres | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/vidrio_costados_referencia.gdshader | gdshader | Main.tscn, scripts/compartidos/edicion/sala_impresiones_y_vidrios.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/vidrio_fachada_duoc.gdshader | gdshader | materials/entrance/MAT_Facade_Glass_Duoc.tres | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/entrance/vidrio_superior.gdshader | gdshader | materials/entrance/MAT_Window_Upper.tres | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| materials/piso5/carteleria_referencia.gdshader | gdshader | scripts/pisos/piso_5/TiendaEsquinaPiso5.tscn, scripts/pisos/piso_5/tienda_esquina_piso5.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| pasillo_capilla_piso_1.gd | gd | Sin referencia literal detectada | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| PERFORMANCE_PROFILE.md | md | BALANCE_REPORT_1_0.md, INFORME_PARA_IA.md, PERSONAJES_2_0.md, RESUMEN_JUEGO.md | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| PERSONAJES_2_0.md | md | BALANCE_1_0.md, BALANCE_REPORT_1_0.md, BOSSES_SUPERIORES_2_0.md, INFORME_PARA_IA.md, RESUMEN_JUEGO.md | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| PERSONALIZACION.md | md | RESUMEN_JUEGO.md | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| piso_gris_puntos.gdshader | gdshader | Main.tscn | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| PLAYTEST_1_0.md | md | BALANCE_1_0.md, BALANCE_REPORT_1_0.md, BOSSES_SUPERIORES_2_0.md, CIERRE_CAMPANA_1_0.md, PERSONAJES_2_0.md, RESUMEN_JUEGO.md, tests/build_balance_docs.py | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| project.godot | godot | AUTH_ARCHITECTURE.md, GUIA.md, INFORME_PARA_IA.md, README.md | USED / KEEP | Configuración raíz, entrypoint y autoloads: protegido expresamente por el usuario. |
| PROJECT_CLEANUP_AUDIT.md | md | ROLE_SYSTEM.md | ACTUAL / KEEP | Conservar; fuente actual o evidencia de esta validación. Documentos auth anteriores deben leerse junto al nuevo comportamiento descrito en este informe. |
| README.md | md | Sin referencia literal detectada | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| RecorridoCoordinacion.tscn | tscn | Sin referencia literal detectada | KEEP | Conservar: revisar cargas dinámicas y uso manual antes de retirar. |
| RENDIMIENTO.md | md | GUIA.md, INFORME_PARA_IA.md, README.md | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/academic_bosses_result.json | json | ACADEMIC_BOSSES_3_0.md, tests/academic_bosses_check.gd | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/academic_regressions.json | json | ACADEMIC_BOSSES_3_0.md, tests/academic_regression_runner.gd | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/ADMIN_ROLE_RPC_DIAGNOSIS.md | md | ADMIN_PANEL.md | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/arquitectura_antes.json | json | ARQUITECTURA_REFERENCIAS_2026_10.md, scripts/exterior/arquitectura_fotos_octubre.gd | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/arquitectura_editor_validacion.json | json | ARQUITECTURA_REFERENCIAS_2026_10.md, scripts/exterior/arquitectura_fotos_octubre.gd | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/arquitectura_regresiones.json | json | ARQUITECTURA_REFERENCIAS_2026_10.md, tests/arquitectura_fotos_preview.gd | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/arquitectura_validacion.json | json | ARQUITECTURA_REFERENCIAS_2026_10.md, tests/arquitectura_fotos_preview.gd | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/balance_1_0_data.json | json | BALANCE_REPORT_1_0.md, CIERRE_CAMPANA_1_0.md, PLAYTEST_1_0.md, RESUMEN_JUEGO.md, tests/build_balance_docs.py, tests/closure_probe.gd, tests/nexo_final.gd | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/campus_fixes_result.json | json | BALANCE_1_0.md, BALANCE_REPORT_1_0.md, PLAYTEST_1_0.md, RESUMEN_JUEGO.md, tests/campus_fixes.gd | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/campus_fixes_validation.md | md | Sin referencia literal detectada | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/closure_balance_data.json | json | BALANCE_1_0.md | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/closure_chairs.json | json | BALANCE_1_0.md, CIERRE_CAMPANA_1_0.md, PLAYTEST_1_0.md, tests/closure_probe.gd | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/coordinacion_meeting_layout.json | json | tests/audit_coordinacion_meeting_scope.cjs, tests/coordinacion_meeting_check.gd, tests/preserve_coord_ceiling_constraint.cjs, tests/reorganize_coordinacion_meeting.cjs | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/coordinacion_meeting_room.png | png | tests/coordinacion_meeting_preview.gd | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/coordinacion_open_office.png | png | tests/coordinacion_meeting_preview.gd | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/COSTADOS_REFERENCIA.md | md | ARQUITECTURA_REFERENCIAS_2026_10.md | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/costado_este_referencia.png | png | Sin referencia literal detectada | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/costado_oeste_referencia.png | png | Sin referencia literal detectada | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/current_AcademicBossesCheck.log | log | Sin referencia literal detectada | ACTUAL / KEEP | Conservar; fuente actual o evidencia de esta validación. Documentos auth anteriores deben leerse junto al nuevo comportamiento descrito en este informe. |
| reports/current_campaign_regression.log | log | Sin referencia literal detectada | ACTUAL / KEEP | Conservar; fuente actual o evidencia de esta validación. Documentos auth anteriores deben leerse junto al nuevo comportamiento descrito en este informe. |
| reports/current_campus_vivo.log | log | Sin referencia literal detectada | ACTUAL / KEEP | Conservar; fuente actual o evidencia de esta validación. Documentos auth anteriores deben leerse junto al nuevo comportamiento descrito en este informe. |
| reports/current_director_informatica_boss.log | log | Sin referencia literal detectada | ACTUAL / KEEP | Conservar; fuente actual o evidencia de esta validación. Documentos auth anteriores deben leerse junto al nuevo comportamiento descrito en este informe. |
| reports/current_EmailRegistrationCheck.log | log | Sin referencia literal detectada | ACTUAL / KEEP | Conservar; fuente actual o evidencia de esta validación. Documentos auth anteriores deben leerse junto al nuevo comportamiento descrito en este informe. |
| reports/current_gameplay_regression.log | log | Sin referencia literal detectada | ACTUAL / KEEP | Conservar; fuente actual o evidencia de esta validación. Documentos auth anteriores deben leerse junto al nuevo comportamiento descrito en este informe. |
| reports/current_guardado_lectura.log | log | Sin referencia literal detectada | ACTUAL / KEEP | Conservar; fuente actual o evidencia de esta validación. Documentos auth anteriores deben leerse junto al nuevo comportamiento descrito en este informe. |
| reports/current_inventory_regression.log | log | Sin referencia literal detectada | ACTUAL / KEEP | Conservar; fuente actual o evidencia de esta validación. Documentos auth anteriores deben leerse junto al nuevo comportamiento descrito en este informe. |
| reports/current_nexo_final.log | log | Sin referencia literal detectada | ACTUAL / KEEP | Conservar; fuente actual o evidencia de esta validación. Documentos auth anteriores deben leerse junto al nuevo comportamiento descrito en este informe. |
| reports/current_nueva_partida.log | log | Sin referencia literal detectada | ACTUAL / KEEP | Conservar; fuente actual o evidencia de esta validación. Documentos auth anteriores deben leerse junto al nuevo comportamiento descrito en este informe. |
| reports/current_organizacion_pisos.log | log | Sin referencia literal detectada | ACTUAL / KEEP | Conservar; fuente actual o evidencia de esta validación. Documentos auth anteriores deben leerse junto al nuevo comportamiento descrito en este informe. |
| reports/current_project_validation.json | json | tests/current_project_validation.cjs | ACTUAL / KEEP | Conservar; fuente actual o evidencia de esta validación. Documentos auth anteriores deben leerse junto al nuevo comportamiento descrito en este informe. |
| reports/current_remember_login_check.log | log | Sin referencia literal detectada | ACTUAL / KEEP | Conservar; fuente actual o evidencia de esta validación. Documentos auth anteriores deben leerse junto al nuevo comportamiento descrito en este informe. |
| reports/current_resource_reference_check.log | log | Sin referencia literal detectada | ACTUAL / KEEP | Conservar; fuente actual o evidencia de esta validación. Documentos auth anteriores deben leerse junto al nuevo comportamiento descrito en este informe. |
| reports/current_revision_scripts.log | log | Sin referencia literal detectada | ACTUAL / KEEP | Conservar; fuente actual o evidencia de esta validación. Documentos auth anteriores deben leerse junto al nuevo comportamiento descrito en este informe. |
| reports/current_SignupDiagnosticsUnit.log | log | Sin referencia literal detectada | ACTUAL / KEEP | Conservar; fuente actual o evidencia de esta validación. Documentos auth anteriores deben leerse junto al nuevo comportamiento descrito en este informe. |
| reports/current_student_phone.log | log | Sin referencia literal detectada | ACTUAL / KEEP | Conservar; fuente actual o evidencia de esta validación. Documentos auth anteriores deben leerse junto al nuevo comportamiento descrito en este informe. |
| reports/current_SupabaseAuthCheck.log | log | Sin referencia literal detectada | ACTUAL / KEEP | Conservar; fuente actual o evidencia de esta validación. Documentos auth anteriores deben leerse junto al nuevo comportamiento descrito en este informe. |
| reports/current_UserRolesCheck.log | log | Sin referencia literal detectada | ACTUAL / KEEP | Conservar; fuente actual o evidencia de esta validación. Documentos auth anteriores deben leerse junto al nuevo comportamiento descrito en este informe. |
| reports/education_1_0_tests.json | json | PLAYTEST_1_0.md, tests/education_1_0.gd | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/EDUCATION_1_0_VALIDATION.md | md | PLAYTEST_1_0.md | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/education_integration_tests.json | json | PLAYTEST_1_0.md, tests/education_integration.gd | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/email_registration_tests.json | json | PLAYTEST_1_0.md, tests/email_registration_check.gd | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/fotos_cafe.png | png | Sin referencia literal detectada | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/fotos_campaign_regression.log | log | Sin referencia literal detectada | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/fotos_entrada.png | png | Sin referencia literal detectada | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/fotos_escalera.png | png | Sin referencia literal detectada | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/fotos_estatua.png | png | Sin referencia literal detectada | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/fotos_interior.png | png | Sin referencia literal detectada | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/fotos_inventory_regression.log | log | Sin referencia literal detectada | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/fotos_library_probe.json | json | tests/arquitectura_fotos_preview.gd | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/fotos_organizacion_pisos.log | log | Sin referencia literal detectada | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/fotos_performance_startup.log | log | Sin referencia literal detectada | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/fotos_sala.png | png | Sin referencia literal detectada | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/human_pilot_fallback_sit.png | png | HUMAN_PILOT_REPORT.md | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/human_pilot_inspection.json | json | HUMAN_MODEL_IMPORT.md, HUMAN_PILOT_REPORT.md, tests/human_pilot_inspect.gd | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/human_pilot_source.json | json | HUMAN_PILOT_REPORT.md | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/human_pilot_static_front.png | png | HUMAN_PILOT_REPORT.md | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/human_pilot_validation.json | json | HUMAN_MODEL_IMPORT.md, HUMAN_PILOT_REPORT.md, tests/human_pilot_check.gd | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/library_counter_updated.png | png | tests/library_preview.gd | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/library_reading_updated.png | png | tests/library_preview.gd | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/library_rooms_updated.png | png | tests/library_preview.gd | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/library_shelves_updated.png | png | tests/library_preview.gd | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/login2_ui.json | json | EDUCATION_SYSTEM_1_0.md | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/performance_after.json | json | PERFORMANCE_PROFILE.md, tests/performance_regression.gd | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/performance_before.json | json | PERFORMANCE_PROFILE.md, tests/performance_regression.gd | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/performance_boss_patterns.json | json | PERFORMANCE_PROFILE.md, tests/performance_profile.gd | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/performance_current.json | json | tests/performance_profile.gd | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/performance_final_recheck.json | json | PERFORMANCE_PROFILE.md | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/performance_group1.json | json | PERFORMANCE_PROFILE.md | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/performance_group2.json | json | PERFORMANCE_PROFILE.md | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/performance_group3.json | json | PERFORMANCE_PROFILE.md | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/performance_initial_partial_scope.json | json | PERFORMANCE_PROFILE.md | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/performance_shadow40_probe.json | json | PERFORMANCE_PROFILE.md | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/performance_validation.json | json | PERFORMANCE_PROFILE.md | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/piso2_negro.png | png | Sin referencia literal detectada | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/piso8_negro.png | png | Sin referencia literal detectada | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/pisos_negros_unificados.json | json | scripts/compartidos/edicion/unificar_piso_negro.gd | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/PISOS_NEGROS_UNIFICADOS.md | md | Sin referencia literal detectada | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/PISO_MENOS1_AUDITORIA_DISTRIBUCION.md | md | Sin referencia literal detectada | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/piso_menos1_capturas/piso_menos1_automotive.png | png | Sin referencia literal detectada | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/piso_menos1_capturas/piso_menos1_automotive_workshop.png | png | Sin referencia literal detectada | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/piso_menos1_capturas/piso_menos1_business.png | png | Sin referencia literal detectada | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/piso_menos1_capturas/piso_menos1_corridor.png | png | Sin referencia literal detectada | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/piso_menos1_capturas/piso_menos1_elevators_center.png | png | Sin referencia literal detectada | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/piso_menos1_capturas/piso_menos1_elevators_left.png | png | Sin referencia literal detectada | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/piso_menos1_capturas/piso_menos1_machinery.png | png | Sin referencia literal detectada | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/piso_menos1_capturas/piso_menos1_mecanica.png | png | Sin referencia literal detectada | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/piso_menos1_capturas/piso_menos1_negocio.png | png | Sin referencia literal detectada | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/piso_menos1_capturas/piso_menos1_negocio_2.png | png | Sin referencia literal detectada | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/piso_menos1_capturas/piso_menos1_negocio_final.png | png | Sin referencia literal detectada | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/piso_menos1_capturas/piso_menos1_pingpong_lockers.png | png | Sin referencia literal detectada | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/piso_menos1_capturas/piso_menos1_ramp_base.png | png | Sin referencia literal detectada | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/piso_menos1_capturas/piso_menos1_ramp_exit.png | png | Sin referencia literal detectada | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/piso_menos1_capturas/piso_menos1_ramp_middle.png | png | Sin referencia literal detectada | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/piso_menos1_capturas/piso_menos1_salida.png | png | Sin referencia literal detectada | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/piso_menos1_capturas/piso_menos1_test_recovery.png | png | Sin referencia literal detectada | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/piso_menos1_capturas/piso_menos1_welding.png | png | Sin referencia literal detectada | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/PISO_MENOS1_RECONSTRUCCION_2026.md | md | Sin referencia literal detectada | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/piso_menos1_ruta_visual.json | json | tests/arquitectura_fotos_preview.gd | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/remember_login_check.log | log | tests/current_project_validation.cjs | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/remember_login_tests.json | json | tests/remember_login_check.gd | ACTUAL / KEEP | Conservar; fuente actual o evidencia de esta validación. Documentos auth anteriores deben leerse junto al nuevo comportamiento descrito en este informe. |
| reports/scene_reference_check.json | json | tests/resource_reference_check.gd | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/SIGNUP_DIAGNOSIS.md | md | Sin referencia literal detectada | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/signup_diagnostics_unit.json | json | AUTH_ARCHITECTURE.md, EDUCATION_SYSTEM_1_0.md, tests/signup_diagnostics_unit.gd | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/signup_runtime_diagnostics.json | json | AUTH_ARCHITECTURE.md, tests/signup_diagnostics_check.gd | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/supabase_auth_tests.json | json | EDUCATION_SYSTEM_1_0.md, tests/supabase_auth_check.gd | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/supabase_connection_check.json | json | tests/supabase_connection_check.gd | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/SUPABASE_REAL_CONNECTION_VALIDATION.md | md | Sin referencia literal detectada | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/supabase_regressions.json | json | EDUCATION_SYSTEM_1_0.md, tests/supabase_regression_runner.gd | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/tienda_piso5_095543.png | png | Sin referencia literal detectada | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/tienda_piso5_acceso_foto.json | json | tests/arquitectura_fotos_preview.gd | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/tienda_piso5_ajuste.json | json | scripts/pisos/piso_5/ajuste_tienda_foto_octubre.gd | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/tienda_piso5_ampliacion.json | json | scripts/pisos/piso_5/ajuste_tienda_foto_octubre.gd | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/tienda_piso5_ampliado.png | png | Sin referencia literal detectada | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/tienda_piso5_carteles_corregidos.png | png | Sin referencia literal detectada | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/tienda_piso5_emergencia.png | png | Sin referencia literal detectada | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/tienda_piso5_emergencia_pruebas.json | json | tests/arquitectura_fotos_preview.gd | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/TIENDA_PISO5_REFERENCIA.md | md | ARQUITECTURA_REFERENCIAS_2026_10.md | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/tienda_piso5_ubicacion_emergencia.json | json | scripts/pisos/piso_5/ajuste_tienda_foto_octubre.gd | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/upper_campus_result.json | json | BALANCE_1_0.md, BALANCE_REPORT_1_0.md, BOSSES_SUPERIORES_2_0.md, RESUMEN_JUEGO.md, tests/upper_campus_check.gd | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/upper_campus_validation.json | json | Sin referencia literal detectada | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/user_roles_tests.json | json | EDUCATION_SYSTEM_1_0.md, tests/user_roles_check.gd | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| reports/user_roles_ui.json | json | EDUCATION_SYSTEM_1_0.md | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| resources/live/campus_live.tres | tres | GUIA_CREAR_CONTENIDO.md, scripts/campaign/campus_campaign.gd, scripts/live/campus_live.gd, scripts/live/save_migration.gd, tests/campus_vivo.gd | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| resources/live/library_study.tres | tres | CAMPUS_VIVO_2_0.md, GUIA_CREAR_CONTENIDO.md, resources/live/campus_live.tres | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| resources/live/nexo_final.tres | tres | BALANCE_1_0.md, CIERRE_CAMPANA_1_0.md, RESUMEN_JUEGO.md, scripts/campaign/quest_manager.gd, scripts/live/campus_qol.gd, scripts/pisos/piso_menos_1/nexo_final_area.gd, tests/academic_regression_runner.gd, tests/current_project_validation.cjs (+3) | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| resources/live/profesor_etica.tres | tres | ACADEMIC_BOSSES_3_0.md, scripts/campaign/academic_expansion_data.gd, scripts/campaign/boss_visual_pass.gd, scripts/campaign/quest_manager.gd, scripts/campaign/upper_campus_bosses.gd, scripts/juego/character_appearance.gd, tests/academic_bosses_check.gd, tests/campus_fixes.gd (+1) | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| resources/live/profesor_ingles.tres | tres | ACADEMIC_BOSSES_3_0.md, HUMAN_PILOT_REPORT.md, PERFORMANCE_PROFILE.md, scripts/campaign/academic_expansion.gd, scripts/campaign/academic_expansion_data.gd, scripts/campaign/boss_visual_pass.gd, scripts/campaign/quest_manager.gd, scripts/campaign/upper_campus_bosses.gd (+5) | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| resources/live/profesor_lenguaje.tres | tres | ACADEMIC_BOSSES_3_0.md, scripts/campaign/academic_expansion_data.gd, scripts/campaign/boss_visual_pass.gd, scripts/campaign/quest_manager.gd, scripts/campaign/upper_campus_bosses.gd, scripts/juego/character_appearance.gd, scripts/live/campus_state.gd, tests/academic_bosses_check.gd (+2) | KEEP | Conservar; ausencia de referencia literal no demuestra código muerto. |
| RESUMEN_JUEGO.md | md | CELULAR_Y_MENSAJES.md, INFORME_PARA_IA.md | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| REVISION.md | md | GUIA.md, INFORME_PARA_IA.md, README.md | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| ROLE_SYSTEM.md | md | ADMIN_PANEL.md, AUTH_ARCHITECTURE.md, EDUCATION_SYSTEM_1_0.md, GOOGLE_SUPABASE_SETUP.md | ACTUAL / KEEP | Conservar; fuente actual o evidencia de esta validación. Documentos auth anteriores deben leerse junto al nuevo comportamiento descrito en este informe. |
| scenes/education/AdminDashboard.tscn | tscn | ADMIN_PANEL.md, EDUCATION_SYSTEM_1_0.md, scripts/auth/auth_manager.gd, scripts/education/education_shell.gd, tests/remember_login_check.gd, tests/RolePanelPreview.tscn, tests/roles_shell_fixture.gd, tests/supabase_auth_check.gd (+1) | USED / KEEP | Conservar: dependencias encontradas. |
| scenes/education/Login.tscn | tscn | AUTH_ARCHITECTURE.md, EDUCATION_SYSTEM_1_0.md, project.godot, scenes/education/AdminDashboard.tscn, scenes/education/PendingAccountScreen.tscn, scenes/education/StudentMainMenu.tscn, scenes/education/TeacherDashboard.tscn, scripts/education/academic_floor_gate.gd (+1) | USED / KEEP | Conservar: dependencias encontradas. |
| scenes/education/PendingAccountScreen.tscn | tscn | scripts/auth/auth_manager.gd, scripts/education/education_shell.gd, tests/roles_shell_fixture.gd, tests/user_roles_check.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scenes/education/StudentMainMenu.tscn | tscn | EDUCATION_SYSTEM_1_0.md, scripts/auth/auth_manager.gd, scripts/campaign/campus_campaign.gd, scripts/education/education_shell.gd, tests/remember_login_check.gd, tests/roles_shell_fixture.gd, tests/supabase_auth_check.gd, tests/user_roles_check.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scenes/education/TeacherDashboard.tscn | tscn | EDUCATION_SYSTEM_1_0.md, scripts/auth/auth_manager.gd, scripts/education/education_shell.gd, tests/remember_login_check.gd, tests/roles_shell_fixture.gd, tests/supabase_auth_check.gd, tests/user_roles_check.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/auth/auth_manager.gd | gd | EDUCATION_SYSTEM_1_0.md, project.godot, tests/education_1_0.gd, tests/email_auth_manager_fixture.gd, tests/email_registration_check.gd, tests/signup_diagnostics_unit.gd, tests/supabase_auth_check.gd, tests/supabase_session_fixture.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/auth/oauth_loopback.gd | gd | EDUCATION_SYSTEM_1_0.md, scripts/auth/auth_manager.gd, tests/education_1_0.gd, tests/roles_auth_fixture.gd, tests/supabase_session_fixture.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/auth/supabase_client.gd | gd | EDUCATION_SYSTEM_1_0.md, scripts/auth/auth_manager.gd, scripts/education/admin_service.gd, tests/signup_diagnostics_unit.gd, tests/supabase_auth_check.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/campaign/academic_action_boss.gd | gd | ACADEMIC_BOSSES_3_0.md, scripts/campaign/academic_expansion.gd, scripts/campaign/upper_campus_bosses.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/campaign/academic_boss.gd | gd | ACADEMIC_BOSSES_3_0.md, BOSSES_SUPERIORES_2_0.md, scripts/campaign/academic_action_boss.gd, tests/performance_profile.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/campaign/academic_boss_config.gd | gd | ACADEMIC_BOSSES_3_0.md, BOSSES_SUPERIORES_2_0.md, resources/live/profesor_etica.tres, resources/live/profesor_ingles.tres, resources/live/profesor_lenguaje.tres, scripts/campaign/academic_expansion.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/campaign/academic_boss_duel.gd | gd | ACADEMIC_BOSSES_3_0.md, BOSSES_SUPERIORES_2_0.md, scripts/campaign/academic_boss.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/campaign/academic_boss_projectile.gd | gd | BOSSES_SUPERIORES_2_0.md, scripts/campaign/academic_boss.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/campaign/academic_boss_zone.gd | gd | BOSSES_SUPERIORES_2_0.md, scripts/campaign/academic_boss.gd, scripts/pisos/piso_8/director_informatica_boss.gd, tests/characters3.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/campaign/academic_class_point.gd | gd | HORARIO_Y_ASISTENCIA.md, scripts/campaign/academic_schedule.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/campaign/academic_expansion.gd | gd | ACADEMIC_BOSSES_3_0.md, scripts/campaign/academic_expansion_data.gd, scripts/campaign/boss_duel_controller.gd, scripts/campaign/campus_campaign.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/campaign/academic_expansion_data.gd | gd | ACADEMIC_BOSSES_3_0.md, scripts/campaign/academic_action_boss.gd, scripts/campaign/academic_expansion.gd, scripts/campaign/student_phone.gd, scripts/inventory/item_catalog.gd, scripts/live/save_migration.gd, tests/academic_bosses_check.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/campaign/academic_objective.gd | gd | ACADEMIC_BOSSES_3_0.md, scripts/campaign/academic_action_boss.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/campaign/academic_schedule.gd | gd | HORARIO_Y_ASISTENCIA.md, scripts/campaign/campus_campaign.gd, tests/academic_regression_runner.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/campaign/appearance_menu.gd | gd | BOSSES_SUPERIORES_2_0.md, PERSONALIZACION.md, scripts/campaign/campus_campaign.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/campaign/appearance_station.gd | gd | scripts/campaign/campus_campaign.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/campaign/area_marker.gd | gd | CAMPANA.md, scripts/campaign/campus_content.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/campaign/boss_duel_controller.gd | gd | ACADEMIC_BOSSES_3_0.md, BOSSES_SUPERIORES_2_0.md, CAMPANA.md, Main.tscn, scripts/campaign/academic_boss_duel.gd, scripts/pisos/piso_3/profesor_redes_duel.gd, scripts/pisos/piso_menos_1/nexo_duel.gd, tests/performance_profile.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/campaign/boss_visual_pass.gd | gd | BOSSES_SUPERIORES_2_0.md, scripts/campaign/boss_duel_controller.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/campaign/campaign_ui.gd | gd | AUTH_ARCHITECTURE.md, CAMPANA.md, CELULAR_Y_MENSAJES.md, scripts/campaign/campus_campaign.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/campaign/campus_audio.gd | gd | CAMPANA.md, Main.tscn, scripts/campaign/campus_campaign.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/campaign/campus_campaign.gd | gd | ACADEMIC_BOSSES_3_0.md, AUTH_ARCHITECTURE.md, BOSSES_SUPERIORES_2_0.md, CAMPANA.md, CELULAR_Y_MENSAJES.md, CIERRE_CAMPANA_1_0.md, HORARIO_Y_ASISTENCIA.md, INFORME_PARA_IA.md (+23) | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/campaign/campus_content.gd | gd | ACADEMIC_BOSSES_3_0.md, CAMPANA.md, INFORME_PARA_IA.md, scripts/campaign/academic_expansion.gd, scripts/campaign/academic_schedule.gd, scripts/campaign/campus_campaign.gd, scripts/campaign/mission_guidance.gd, scripts/campaign/student_phone.gd (+6) | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/campaign/campus_enemy.gd | gd | CAMPANA.md, scripts/campaign/campus_content.gd, scripts/live/floor_activity_manager.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/campaign/campus_polish.gd | gd | CAMPANA.md, scripts/campaign/campus_campaign.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/campaign/campus_vendor.gd | gd | CAMPANA.md, scripts/campaign/campus_content.gd, scripts/campaign/interaction_controller.gd, tests/campaign_regression.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/campaign/campus_weapon.gd | gd | CAMPANA.md, scripts/inventory/inventory.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/campaign/checkpoint.gd | gd | CAMPANA.md, scripts/campaign/campus_campaign.gd, scripts/live/boss_retry.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/campaign/dialogue_camera_controller.gd | gd | scripts/campaign/campaign_ui.gd, scripts/pisos/piso_1/npc_papeleria.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/campaign/director_task_point.gd | gd | ACADEMIC_BOSSES_3_0.md, scripts/campaign/academic_expansion.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/campaign/distraction.gd | gd | CAMPANA.md, scripts/campaign/campus_campaign.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/campaign/elevator_interaction.gd | gd | CAMPANA.md, scripts/campaign/campus_campaign.gd, scripts/campaign/interaction_controller.gd, scripts/live/ambient_events.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/campaign/furniture_pickup.gd | gd | CAMPANA.md, scripts/campaign/campus_campaign.gd, scripts/campaign/interaction_controller.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/campaign/health_station.gd | gd | scripts/campaign/campus_content.gd, tests/balance_audit.gd, tests/campaign_regression.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/campaign/interaction_controller.gd | gd | CAMPANA.md, INTERACCIONES_CONTEXTUALES.md, scripts/campaign/campus_campaign.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/campaign/locked_access.gd | gd | CAMPANA.md, scripts/campaign/campus_campaign.gd, scripts/campaign/interaction_controller.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/campaign/mission_guidance.gd | gd | ACADEMIC_BOSSES_3_0.md, BOSSES_SUPERIORES_2_0.md, scripts/campaign/campus_campaign.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/campaign/npc.gd | gd | BOSSES_SUPERIORES_2_0.md, CAMPANA.md, GUIA_CREAR_CONTENIDO.md, scripts/campaign/academic_boss.gd, scripts/campaign/campus_content.gd, scripts/campaign/interaction_controller.gd, scripts/campaign/student_phone.gd, scripts/live/ambient_events.gd (+3) | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/campaign/phone_view.gd | gd | CELULAR_Y_MENSAJES.md, HORARIO_Y_ASISTENCIA.md, scripts/campaign/student_phone.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/campaign/player_combat.gd | gd | BALANCE_1_0.md, CAMPANA.md, INTERACCIONES_CONTEXTUALES.md, scripts/campaign/campus_campaign.gd, tests/build_balance_docs.py | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/campaign/quest.gd | gd | CAMPANA.md, GUIA_CREAR_CONTENIDO.md, scripts/campaign/quest_manager.gd, scripts/live/content_helpers.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/campaign/quest_manager.gd | gd | ACADEMIC_BOSSES_3_0.md, AUTH_ARCHITECTURE.md, BOSSES_SUPERIORES_2_0.md, CAMPANA.md, INFORME_PARA_IA.md, scripts/campaign/campus_campaign.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/campaign/quest_ui.gd | gd | CAMPANA.md, scripts/campaign/campus_campaign.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/campaign/seat_interactable.gd | gd | INTERACCIONES_CONTEXTUALES.md, scripts/campaign/campus_campaign.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/campaign/student_phone.gd | gd | ACADEMIC_BOSSES_3_0.md, AUTH_ARCHITECTURE.md, CELULAR_Y_MENSAJES.md, HORARIO_Y_ASISTENCIA.md, scripts/campaign/campus_campaign.gd, tests/academic_regression_runner.gd, tests/current_project_validation.cjs, tests/student_phone.gd (+1) | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/campaign/upper_campus_bosses.gd | gd | ACADEMIC_BOSSES_3_0.md, BOSSES_SUPERIORES_2_0.md, scripts/campaign/campus_campaign.gd, tests/upper_campus_check.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/campaign/weapon_pickup.gd | gd | CAMPANA.md, scripts/campaign/campus_campaign.gd, scripts/campaign/campus_content.gd, scripts/campaign/interaction_controller.gd, scripts/campaign/world_item.gd, scripts/juego/implemento_deportivo.gd, scripts/juego/player.gd, scripts/juego/player_seating.gd (+4) | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/campaign/world_item.gd | gd | CAMPANA.md, scripts/campaign/campus_content.gd, scripts/campaign/interaction_controller.gd, scripts/campaign/weapon_pickup.gd, tests/campus_fixes.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/compartidos/ascensor_estudiantil.gd | gd | AUTH_ARCHITECTURE.md, CAMPANA.md, Main.tscn | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/compartidos/edicion/acabados_ascensores.gd | gd | Main.tscn | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/compartidos/edicion/acabados_escalera_principal.gd | gd | Main.tscn | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/compartidos/edicion/barandas_pasillos.gd | gd | Main.tscn | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/compartidos/edicion/elevar_base_auditorio.gd | gd | Main.tscn | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/compartidos/edicion/interiores_referencia_campus.gd | gd | Main.tscn | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/compartidos/edicion/piso_menos_uno_y_emergencia.gd | gd | Main.tscn, scripts/organizacion/informacion_campus.gd, scripts/pisos/piso_1/INFORMACION.md, scripts/pisos/piso_2/INFORMACION.md, scripts/pisos/piso_3/INFORMACION.md, scripts/pisos/piso_4/INFORMACION.md, scripts/pisos/piso_5/INFORMACION.md, scripts/pisos/piso_6/INFORMACION.md (+3) | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/compartidos/edicion/reparar_continuidad_pisos.gd | gd | Main.tscn | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/compartidos/edicion/sala_impresiones_y_vidrios.gd | gd | Main.tscn | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/compartidos/edicion/unificar_piso_negro.gd | gd | Main.tscn | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/compartidos/lectura_guardado.gd | gd | AUTH_ARCHITECTURE.md, scripts/campaign/campus_campaign.gd, scripts/education/education_shell.gd, scripts/inventory/inventory.gd, scripts/juego/player.gd, tests/academic_bosses_check.gd, tests/academic_schedule.gd, tests/campus_fixes.gd (+4) | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/compartidos/puerta_emergencia.gd | gd | Main.tscn, scripts/compartidos/edicion/piso_menos_uno_y_emergencia.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/compartidos/puerta_vidrio_salas.gd | gd | ARQUITECTURA_REFERENCIAS_2026_10.md, CAMPANA.md, Main.tscn, scripts/compartidos/edicion/interiores_referencia_campus.gd, scripts/exterior/arquitectura_fotos_octubre.gd, scripts/pisos/piso_3/SalaDetrasLocal.tscn, scripts/pisos/piso_4/piso_4_referencia.gd, scripts/pisos/piso_8/PasilloReferencia.tscn (+3) | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/education/academic_floor_gate.gd | gd | EDUCATION_SYSTEM_1_0.md, scripts/campaign/campus_campaign.gd, tests/education_1_0.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/education/academic_progress.gd | gd | EDUCATION_SYSTEM_1_0.md, scripts/education/academic_floor_gate.gd, scripts/education/education_shell.gd, scripts/live/save_migration.gd, supabase/verify_education_auth.sql, tests/education_1_0.gd, tests/supabase_connection_check.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/education/admin_service.gd | gd | ADMIN_PANEL.md, scripts/education/education_shell.gd, tests/roles_shell_fixture.gd, tests/user_roles_check.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/education/education_shell.gd | gd | ADMIN_PANEL.md, AUTH_ARCHITECTURE.md, EDUCATION_SYSTEM_1_0.md, scenes/education/Login.tscn, tests/registration_shell_fixture.gd, tests/remember_login_shell_fixture.gd, tests/roles_shell_fixture.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/education/question_service.gd | gd | EDUCATION_SYSTEM_1_0.md, project.godot, tests/roles_shell_fixture.gd, tests/user_roles_check.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/education/question_view.gd | gd | EDUCATION_SYSTEM_1_0.md, scripts/education/academic_floor_gate.gd, scripts/education/education_shell.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/exterior/aplicar_materiales_entrada.gd | gd | Sin referencia literal detectada | KEEP | Conservar: revisar cargas dinámicas y uso manual antes de retirar. |
| scripts/exterior/arquitectura_fotos_octubre.gd | gd | ARQUITECTURA_REFERENCIAS_2026_10.md, Main.tscn, scripts/pisos/piso_5/ajuste_tienda_foto_octubre.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/exterior/costados_referencia_fotos.gd | gd | Main.tscn | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/exterior/estructura_y_acceso_posterior.gd | gd | Main.tscn | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/exterior/fachada_referencia_duoc.gd | gd | Main.tscn | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/exterior/guardia_torniquetes.gd | gd | Main.tscn, scripts/exterior/fachada_referencia_duoc.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/exterior/patio_posterior_duoc.gd | gd | Main.tscn | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/exterior/reja.gd | gd | Main.tscn | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/exterior/Torniquete.gd | gd | Main.tscn, scripts/exterior/aplicar_materiales_entrada.gd, scripts/exterior/estructura_y_acceso_posterior.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/inventory/inventory.gd | gd | ACADEMIC_BOSSES_3_0.md, CAMPANA.md, scripts/campaign/campus_campaign.gd, scripts/juego/player.gd, scripts/live/boss_retry.gd, scripts/pisos/piso_3/network_slow_status.gd, scripts/pisos/piso_8/credencial_director.gd, tests/education_1_0.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/inventory/InventoryPickup.tscn | tscn | INVENTARIO.md | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/inventory/inventory_item.gd | gd | CAMPANA.md, GUIA_CREAR_CONTENIDO.md, INVENTARIO.md, scripts/inventory/inventory.gd, scripts/inventory/inventory_ui.gd, scripts/inventory/item_catalog.gd, scripts/pisos/piso_3/router_portatil_item.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/inventory/inventory_pickup.gd | gd | CAMPANA.md, Main.tscn, scripts/campaign/campus_campaign.gd, scripts/campaign/interaction_controller.gd, scripts/campaign/world_item.gd, scripts/inventory/InventoryPickup.tscn, scripts/juego/player.gd, tests/inventory_regression.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/inventory/inventory_ui.gd | gd | CAMPANA.md, scripts/inventory/inventory.gd, scripts/juego/player.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/inventory/item_catalog.gd | gd | ACADEMIC_BOSSES_3_0.md, BOSSES_SUPERIORES_2_0.md, CAMPANA.md, INVENTARIO.md, scripts/campaign/campus_campaign.gd, scripts/campaign/campus_vendor.gd, scripts/campaign/campus_weapon.gd, scripts/campaign/npc.gd (+11) | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/inventory/item_effect_receiver.gd | gd | CAMPANA.md, INVENTARIO.md, Main.tscn, scripts/pisos/piso_3/network_slow_status.gd, scripts/pisos/piso_3/PROFESOR_REDES.md, scripts/pisos/piso_menos_1/nexo_boss.gd, tests/inventory_regression.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/inventory/key_access.gd | gd | INVENTARIO.md, tests/inventory_regression.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/inventory/paleta_ping_pong.gd | gd | CAMPANA.md, scripts/inventory/inventory.gd, scripts/inventory/item_catalog.gd, scripts/live/balance_tools.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/juego/campus_activity.gd | gd | scripts/juego/computer.gd, scripts/juego/minigame_ui.gd, tests/campus_fixes.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/juego/character.gd | gd | Character.tscn, REVISION.md | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/juego/character_activity_visual.gd | gd | scripts/campaign/boss_visual_pass.gd, scripts/juego/student_visual.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/juego/character_appearance.gd | gd | BOSSES_SUPERIORES_2_0.md, PERSONALIZACION.md, scripts/campaign/appearance_menu.gd, scripts/campaign/campus_campaign.gd, scripts/exterior/guardia_torniquetes.gd, scripts/juego/character_visual_presets.gd, scripts/juego/procedural_appearance_adapter.gd, tests/personajes2.gd (+3) | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/juego/character_body_3d.gd | gd | Sin referencia literal detectada | KEEP | Conservar: revisar cargas dinámicas y uso manual antes de retirar. |
| scripts/juego/character_visual_presets.gd | gd | BOSSES_SUPERIORES_2_0.md, PERSONAJES_2_0.md, scripts/campaign/academic_boss.gd, scripts/campaign/npc.gd, scripts/exterior/guardia_torniquetes.gd, scripts/live/ambient_presentation.gd, scripts/pisos/piso_1/npc_papeleria.gd, scripts/pisos/piso_8/director_informatica_boss.gd (+3) | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/juego/computer.gd | gd | CAMPANA.md, scripts/campaign/academic_expansion.gd, scripts/campaign/campus_campaign.gd, scripts/campaign/campus_content.gd, scripts/campaign/director_task_point.gd, scripts/campaign/interaction_controller.gd, scripts/campaign/mission_guidance.gd, scripts/campaign/quest_manager.gd (+18) | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/juego/contextual_pose.gd | gd | INTERACCIONES_CONTEXTUALES.md, scripts/juego/student_visual.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/juego/enemy.gd | gd | BOSSES_SUPERIORES_2_0.md, CAMPANA.md, INVENTARIO.md, scripts/campaign/academic_boss.gd, scripts/campaign/campus_content.gd, scripts/campaign/campus_enemy.gd, scripts/juego/gameplay_manager.gd, scripts/live/floor_activity_manager.gd (+8) | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/juego/gameplay_manager.gd | gd | ACADEMIC_BOSSES_3_0.md, CAMPANA.md, INVENTARIO.md, Main.tscn | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/juego/game_files.gd | gd | CAMPANA.md, scripts/juego/campus_activity.gd, scripts/juego/minigame_ui.gd, tests/gameplay_regression.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/juego/game_password.gd | gd | CAMPANA.md, scripts/juego/minigame_ui.gd, tests/gameplay_regression.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/juego/game_virus.gd | gd | CAMPANA.md, scripts/juego/minigame_ui.gd, tests/gameplay_regression.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/juego/humanoid.gd | gd | CAMPANA.md, INVENTARIO.md, scripts/exterior/guardia_torniquetes.gd, scripts/juego/enemy.gd, scripts/juego/player.gd, scripts/juego/student_visual.gd, scripts/pisos/piso_1/boss_ayuda_estudiantil.gd, scripts/pisos/piso_2/boss_bibliotecaria.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/juego/implemento_deportivo.gd | gd | INVENTARIO.md, Main.tscn, scripts/campaign/campus_weapon.gd, scripts/inventory/inventory.gd, scripts/inventory/item_catalog.gd, scripts/juego/proyectil_deportivo.gd, scripts/live/balance_tools.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/juego/imported_character_visual.gd | gd | BOSSES_SUPERIORES_2_0.md, RESUMEN_JUEGO.md, scripts/juego/student_visual.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/juego/look_at_controller.gd | gd | scripts/juego/humanoid.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/juego/minigame_ui.gd | gd | CAMPANA.md, scripts/juego/gameplay_manager.gd, tests/gameplay_regression.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/juego/Muro.gd | gd | Main.tscn | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/juego/player.gd | gd | ACADEMIC_BOSSES_3_0.md, BALANCE_1_0.md, CAMPANA.md, INTERACCIONES_CONTEXTUALES.md, INVENTARIO.md, scripts/compartidos/ascensor_estudiantil.gd, scripts/compartidos/puerta_emergencia.gd, scripts/compartidos/puerta_vidrio_salas.gd (+38) | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/juego/player_seating.gd | gd | INTERACCIONES_CONTEXTUALES.md, scripts/campaign/campus_campaign.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/juego/procedural_appearance_adapter.gd | gd | BOSSES_SUPERIORES_2_0.md, PERSONALIZACION.md, scripts/juego/student_visual.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/juego/proyectil_deportivo.gd | gd | scripts/juego/player.gd, scripts/pisos/piso_1/bandeja_chef_casino.gd, scripts/pisos/piso_1/boss_ayuda_estudiantil.gd, scripts/pisos/piso_8/proyectil_error_sistema.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/juego/student_visual.gd | gd | BOSSES_SUPERIORES_2_0.md, INTERACCIONES_CONTEXTUALES.md, INVENTARIO.md, PERSONALIZACION.md, scripts/campaign/academic_boss.gd, scripts/campaign/appearance_menu.gd, scripts/campaign/npc.gd, scripts/juego/player.gd (+5) | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/juego/weapon.gd | gd | CAMPANA.md, INVENTARIO.md, scripts/inventory/inventory.gd, scripts/inventory/item_catalog.gd, scripts/inventory/paleta_ping_pong.gd, scripts/juego/gameplay_manager.gd, scripts/juego/implemento_deportivo.gd, scripts/juego/player.gd (+5) | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/live/ambient_events.gd | gd | scripts/live/campus_live.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/live/ambient_presentation.gd | gd | scripts/live/ambient_events.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/live/ambient_situation.gd | gd | scripts/live/ambient_events.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/live/arena_return.gd | gd | scripts/live/boss_retry.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/live/balance_tools.gd | gd | scripts/live/campus_live.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/live/boss_data.gd | gd | GUIA_CREAR_CONTENIDO.md | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/live/boss_retry.gd | gd | scripts/live/campus_live.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/live/campus_display.gd | gd | scripts/live/reactive_world.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/live/campus_live.gd | gd | scripts/campaign/campus_campaign.gd, scripts/live/save_migration.gd, tests/campus_vivo.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/live/campus_localization.gd | gd | AUTH_ARCHITECTURE.md, GUIA_CREAR_CONTENIDO.md, scripts/live/campus_live.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/live/campus_qol.gd | gd | ACADEMIC_BOSSES_3_0.md, scripts/live/campus_live.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/live/campus_settings.gd | gd | AUTH_ARCHITECTURE.md, scripts/live/campus_live.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/live/campus_state.gd | gd | AUTH_ARCHITECTURE.md, BOSSES_SUPERIORES_2_0.md, scripts/live/campus_live.gd, tests/campus_vivo.gd, tests/nexo_final.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/live/content_helpers.gd | gd | GUIA_CREAR_CONTENIDO.md | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/live/event_catalog.gd | gd | scripts/live/ambient_events.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/live/event_data.gd | gd | GUIA_CREAR_CONTENIDO.md, resources/live/library_study.tres, scripts/live/ambient_events.gd, scripts/live/content_helpers.gd, scripts/live/event_catalog.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/live/floor_activity_manager.gd | gd | PERFORMANCE_PROFILE.md, scripts/live/campus_live.gd, tests/characters3.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/live/gameplay_director.gd | gd | scripts/live/campus_live.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/live/id_registry.gd | gd | scripts/live/content_helpers.gd, scripts/live/qa_tools.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/live/live_config.gd | gd | resources/live/campus_live.tres | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/live/npc_data.gd | gd | GUIA_CREAR_CONTENIDO.md | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/live/qa_tools.gd | gd | scripts/live/campus_live.gd, tests/upper_campus_check.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/live/reactive_world.gd | gd | scripts/live/campus_live.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/live/save_migration.gd | gd | ACADEMIC_BOSSES_3_0.md, AUTH_ARCHITECTURE.md, scripts/campaign/campus_campaign.gd, scripts/live/campus_live.gd, tests/academic_bosses_check.gd, tests/campus_vivo.gd, tests/education_1_0.gd, tests/nexo_final.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/live/story_moment.gd | gd | GUIA_CREAR_CONTENIDO.md, scripts/live/story_moments.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/live/story_moments.gd | gd | scripts/campaign/campus_campaign.gd, scripts/live/campus_live.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/organizacion/informacion_campus.gd | gd | Main.tscn | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/organizacion/informacion_piso.gd | gd | Main.tscn | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/organizacion/nodos_campus.gd | gd | scripts/compartidos/edicion/acabados_ascensores.gd, scripts/compartidos/edicion/acabados_escalera_principal.gd, scripts/compartidos/edicion/barandas_pasillos.gd, scripts/compartidos/edicion/elevar_base_auditorio.gd, scripts/compartidos/edicion/interiores_referencia_campus.gd, scripts/compartidos/edicion/piso_menos_uno_y_emergencia.gd, scripts/compartidos/edicion/reparar_continuidad_pisos.gd, scripts/compartidos/edicion/sala_impresiones_y_vidrios.gd (+17) | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_1/arma_ayuda_estudiantil.gd | gd | Sin referencia literal detectada | KEEP | Conservar: revisar cargas dinámicas y uso manual antes de retirar. |
| scripts/pisos/piso_1/bandeja_chef_casino.gd | gd | scripts/pisos/piso_1/chef_supremo_casino.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_1/boss_ayuda_estudiantil.gd | gd | CAMPANA.md, Main.tscn | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_1/casino_referencia.gd | gd | Main.tscn, tests/casino_referencia.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_1/chef_supremo_casino.gd | gd | CAMPANA.md, INVENTARIO.md, Main.tscn, tests/academic_regression_runner.gd, tests/chef_supremo_casino.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_1/INFORMACION.md | md | INFORME_PARA_IA.md, README.md, REVISION.md, scripts/organizacion/informacion_campus.gd, scripts/pisos/README.md, tests/organizacion_pisos.gd | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| scripts/pisos/piso_1/interior_coordinacion.gd | gd | interior_coordinacion_referencia.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_1/inventario_papeleria.gd | gd | scripts/juego/player.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_1/npc_papeleria.gd | gd | CAMPANA.md, Main.tscn, scripts/exterior/estructura_y_acceso_posterior.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_1/puerta_vidrio_ayuda.gd | gd | Main.tscn | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_2/acabados_piso_dos.gd | gd | Main.tscn | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_2/auditorio_piso_2e.gd | gd | Main.tscn | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_2/boss_bibliotecaria.gd | gd | CAMPANA.md, Main.tscn, tests/library_layout_check.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_2/INFORMACION.md | md | INFORME_PARA_IA.md, README.md, REVISION.md, scripts/organizacion/informacion_campus.gd, scripts/pisos/README.md, tests/organizacion_pisos.gd | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| scripts/pisos/piso_3/encuentro_profesor_redes.gd | gd | Main.tscn, scripts/pisos/piso_3/PROFESOR_REDES.md | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_3/INFORMACION.md | md | INFORME_PARA_IA.md, README.md, REVISION.md, scripts/organizacion/informacion_campus.gd, scripts/pisos/README.md, tests/organizacion_pisos.gd | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| scripts/pisos/piso_3/LocalComidaReferencia.tscn | tscn | Main.tscn, tests/generar_local_piso3.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_3/local_comida_referencia.gd | gd | scripts/pisos/piso_3/LocalComidaReferencia.tscn, tests/generar_local_piso3.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_3/network_data_packet.gd | gd | scripts/pisos/piso_3/PROFESOR_REDES.md, scripts/pisos/piso_3/profesor_redes_boss.gd, scripts/pisos/piso_menos_1/nexo_boss.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_3/network_interference_zone.gd | gd | scripts/pisos/piso_3/PROFESOR_REDES.md, scripts/pisos/piso_3/profesor_redes_boss.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_3/network_router_interactable.gd | gd | scripts/campaign/interaction_controller.gd, scripts/pisos/piso_3/encuentro_profesor_redes.gd, scripts/pisos/piso_3/PROFESOR_REDES.md | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_3/network_slow_status.gd | gd | ACADEMIC_BOSSES_3_0.md, scripts/campaign/academic_boss.gd, scripts/pisos/piso_3/PROFESOR_REDES.md, scripts/pisos/piso_3/profesor_redes_boss.gd, tests/academic_bosses_check.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_3/ProfesorRedesCheck.tscn | tscn | scripts/pisos/piso_3/PROFESOR_REDES.md | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_3/ProfesorRedesPreview.tscn | tscn | scripts/pisos/piso_3/PROFESOR_REDES.md | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_3/PROFESOR_REDES.md | md | scripts/pisos/piso_3/INFORMACION.md | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| scripts/pisos/piso_3/profesor_redes_boss.gd | gd | scripts/pisos/piso_3/encuentro_profesor_redes.gd, scripts/pisos/piso_3/PROFESOR_REDES.md | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_3/profesor_redes_duel.gd | gd | scripts/pisos/piso_3/PROFESOR_REDES.md, scripts/pisos/piso_3/profesor_redes_boss.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_3/router_portatil_item.gd | gd | scripts/pisos/piso_3/encuentro_profesor_redes.gd, scripts/pisos/piso_3/PROFESOR_REDES.md | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_3/SalaDetrasLocal.tscn | tscn | Main.tscn, tests/generar_sala_detras_local.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_3/sala_detras_local.gd | gd | scripts/pisos/piso_3/SalaDetrasLocal.tscn, tests/generar_sala_detras_local.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_3/test_profesor_redes.gd | gd | scripts/pisos/piso_3/ProfesorRedesCheck.tscn, scripts/pisos/piso_3/ProfesorRedesPreview.tscn, scripts/pisos/piso_3/PROFESOR_REDES.md | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_4/INFORMACION.md | md | INFORME_PARA_IA.md, README.md, REVISION.md, scripts/organizacion/informacion_campus.gd, scripts/pisos/README.md, tests/organizacion_pisos.gd | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| scripts/pisos/piso_4/piso_4_borrar_losa_morada.gd | gd | Main.tscn | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_4/piso_4_correccion_central.gd | gd | Sin referencia literal detectada | KEEP | Conservar: revisar cargas dinámicas y uso manual antes de retirar. |
| scripts/pisos/piso_4/piso_4_docentes.gd | gd | Main.tscn, scripts/pisos/piso_4/piso_4_borrar_losa_morada.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_4/piso_4_fila_frontal.gd | gd | Main.tscn | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_4/piso_4_referencia.gd | gd | Main.tscn, scripts/pisos/piso_4/piso_4_correccion_central.gd, scripts/pisos/piso_4/piso_4_docentes.gd, scripts/pisos/piso_4/piso_4_fila_frontal.gd, scripts/pisos/piso_4/piso_4_retirar_tramo_marcado.gd, scripts/pisos/piso_4/piso_4_salas_centrales.gd, scripts/pisos/piso_4/piso_4_salas_centrales_restauradas.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_4/piso_4_retirar_tramo_marcado.gd | gd | Main.tscn | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_4/piso_4_salas_centrales.gd | gd | Sin referencia literal detectada | KEEP | Conservar: revisar cargas dinámicas y uso manual antes de retirar. |
| scripts/pisos/piso_4/piso_4_salas_centrales_restauradas.gd | gd | Main.tscn | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_5/adaptar_desembarco_tienda.gd | gd | Main.tscn | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_5/ajuste_tienda_foto_octubre.gd | gd | Main.tscn | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_5/INFORMACION.md | md | INFORME_PARA_IA.md, README.md, REVISION.md, scripts/organizacion/informacion_campus.gd, scripts/pisos/README.md, tests/organizacion_pisos.gd | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| scripts/pisos/piso_5/terraza_piso_5_referencia.gd | gd | Main.tscn | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_5/TiendaEsquinaPiso5.tscn | tscn | Main.tscn, tests/generar_tienda_piso5.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_5/tienda_esquina_piso5.gd | gd | scripts/pisos/piso_5/TiendaEsquinaPiso5.tscn, tests/generar_tienda_piso5.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_6/INFORMACION.md | md | INFORME_PARA_IA.md, README.md, REVISION.md, scripts/organizacion/informacion_campus.gd, scripts/pisos/README.md, tests/organizacion_pisos.gd | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| scripts/pisos/piso_7/INFORMACION.md | md | INFORME_PARA_IA.md, README.md, REVISION.md, scripts/organizacion/informacion_campus.gd, scripts/pisos/README.md, tests/organizacion_pisos.gd | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| scripts/pisos/piso_8/baldosas_oscuras.gdshader | gdshader | scripts/pisos/piso_3/LocalComidaReferencia.tscn, scripts/pisos/piso_5/TiendaEsquinaPiso5.tscn, scripts/pisos/piso_8/INFORMACION.md, scripts/pisos/piso_8/PasilloReferencia.tscn, scripts/pisos/piso_8/pasillo_referencia.gd, scripts/pisos/piso_8/piso_8_completo.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_8/credencial_director.gd | gd | CAMPANA.md, Main.tscn, tests/director_informatica_boss.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_8/director_informatica_boss.gd | gd | BOSSES_SUPERIORES_2_0.md, CAMPANA.md, INVENTARIO.md, Main.tscn, scripts/pisos/piso_8/INFORMACION.md, tests/academic_regression_runner.gd, tests/current_project_validation.cjs, tests/director_informatica_boss.gd (+2) | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_8/INFORMACION.md | md | INFORME_PARA_IA.md, README.md, REVISION.md, scripts/organizacion/informacion_campus.gd, scripts/pisos/README.md, tests/organizacion_pisos.gd | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| scripts/pisos/piso_8/paneles_beige.gdshader | gdshader | scripts/pisos/piso_3/SalaDetrasLocal.tscn, scripts/pisos/piso_8/PasilloReferencia.tscn, scripts/pisos/piso_8/piso_8_completo.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_8/PasilloReferencia.tscn | tscn | Main.tscn, scripts/pisos/piso_6/INFORMACION.md, scripts/pisos/piso_7/INFORMACION.md, scripts/pisos/piso_8/INFORMACION.md, tests/generar_piso8.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_8/pasillo_referencia.gd | gd | scripts/pisos/piso_8/piso_8_completo.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_8/piso_8_completo.gd | gd | scripts/pisos/piso_3/local_comida_referencia.gd, scripts/pisos/piso_3/sala_detras_local.gd, scripts/pisos/piso_5/tienda_esquina_piso5.gd, scripts/pisos/piso_8/INFORMACION.md, scripts/pisos/piso_8/PasilloReferencia.tscn, tests/generar_piso8.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_8/proyectil_error_sistema.gd | gd | BOSSES_SUPERIORES_2_0.md, scripts/campaign/academic_boss_projectile.gd, scripts/campaign/campus_enemy.gd, scripts/pisos/piso_3/network_data_packet.gd, scripts/pisos/piso_8/director_informatica_boss.gd, scripts/pisos/piso_8/INFORMACION.md | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_8/virus_director.gd | gd | scripts/campaign/campus_weapon.gd, scripts/pisos/piso_8/director_informatica_boss.gd, scripts/pisos/piso_8/INFORMACION.md | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_menos_1/INFORMACION.md | md | INFORME_PARA_IA.md, README.md, REVISION.md, scripts/organizacion/informacion_campus.gd, scripts/pisos/README.md, tests/organizacion_pisos.gd | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| scripts/pisos/piso_menos_1/nexo_boss.gd | gd | scripts/pisos/piso_menos_1/nexo_final_area.gd, tests/arquitectura_fotos_preview.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_menos_1/nexo_config.gd | gd | CIERRE_CAMPANA_1_0.md, resources/live/nexo_final.tres | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_menos_1/nexo_duel.gd | gd | scripts/pisos/piso_menos_1/nexo_boss.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_menos_1/nexo_final_area.gd | gd | INFORME_PARA_IA.md, scripts/campaign/campus_campaign.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_menos_1/nexo_terminal.gd | gd | scripts/pisos/piso_menos_1/nexo_final_area.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_menos_1/nexo_zone.gd | gd | scripts/pisos/piso_menos_1/nexo_boss.gd | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/piso_menos_1/reconstruccion_visual_2026.gd | gd | Main.tscn | USED / KEEP | Conservar: dependencias encontradas. |
| scripts/pisos/README.md | md | README.md | HISTÓRICO / KEEP | Evidencia del proyecto de título; no afirmar vigencia funcional sin reproducirla. |
| supabase/bootstrap/SET_FIRST_ADMIN.sql | sql | EDUCATION_SYSTEM_1_0.md, GOOGLE_SUPABASE_SETUP.md, ROLE_SYSTEM.md | KEEP | Conservar diagnóstico/verificación SQL; aún útil para RPC y permisos. |
| supabase/diagnostics/CHECK_ADMIN_ROLE_RPC.sql | sql | ADMIN_PANEL.md | KEEP | Conservar diagnóstico/verificación SQL; aún útil para RPC y permisos. |
| supabase/migrations/001_education_auth.sql | sql | AUTH_ARCHITECTURE.md, GOOGLE_SUPABASE_SETUP.md | KEEP | Historial SQL: no borrar, incluidas 001–006. |
| supabase/migrations/002_profile_display_name.sql | sql | AUTH_ARCHITECTURE.md, GOOGLE_SUPABASE_SETUP.md | KEEP | Historial SQL: no borrar, incluidas 001–006. |
| supabase/migrations/003_recover_missing_profiles.sql | sql | AUTH_ARCHITECTURE.md, GOOGLE_SUPABASE_SETUP.md | KEEP | Historial SQL: no borrar, incluidas 001–006. |
| supabase/migrations/004_user_roles_admin.sql | sql | EDUCATION_SYSTEM_1_0.md, GOOGLE_SUPABASE_SETUP.md, ROLE_SYSTEM.md, supabase/migrations/005_fix_admin_roles.sql, tests/user_roles_check.gd | KEEP | Historial SQL: no borrar, incluidas 001–006. |
| supabase/migrations/005_fix_admin_roles.sql | sql | ADMIN_PANEL.md, tests/user_roles_check.gd | KEEP | Historial SQL: no borrar, incluidas 001–006. |
| supabase/migrations/006_fix_admin_rpc_signature.sql | sql | Sin referencia literal detectada | KEEP | Historial SQL: no borrar, incluidas 001–006. |
| supabase/seeds/001_subjects.sql | sql | GOOGLE_SUPABASE_SETUP.md | KEEP | Conservar diagnóstico/verificación SQL; aún útil para RPC y permisos. |
| supabase/seeds/002_demo_questions.sql | sql | GOOGLE_SUPABASE_SETUP.md | KEEP | Conservar diagnóstico/verificación SQL; aún útil para RPC y permisos. |
| supabase/verify_education_auth.sql | sql | AUTH_ARCHITECTURE.md, GOOGLE_SUPABASE_SETUP.md | KEEP | Conservar diagnóstico/verificación SQL; aún útil para RPC y permisos. |
| supabase/verify_user_roles_admin.sql | sql | Sin referencia literal detectada | KEEP | Conservar diagnóstico/verificación SQL; aún útil para RPC y permisos. |
| tests/AcademicBossesCheck.tscn | tscn | tests/current_project_validation.cjs, tests/supabase_regression_runner.gd | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/AcademicExtraChecks.tscn | tscn | Sin referencia literal detectada | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/AcademicRegressionRunner.tscn | tscn | Sin referencia literal detectada | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/academic_bosses_check.gd | gd | tests/AcademicBossesCheck.tscn | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/academic_extra_checks.gd | gd | tests/AcademicExtraChecks.tscn | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/academic_regression_runner.gd | gd | tests/AcademicRegressionRunner.tscn, tests/academic_extra_checks.gd | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/academic_schedule.gd | gd | HORARIO_Y_ASISTENCIA.md, scripts/campaign/campus_campaign.gd, tests/academic_regression_runner.gd | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/access_probe.gd | gd | CIERRE_CAMPANA_1_0.md, tests/balance_audit.gd, tests/basement_access.gd, tests/closure_probe.gd, tests/elevator_basement.gd, tests/library_access_check.gd, tests/local_piso3_recorridos.gd, tests/nexo_final.gd (+3) | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/ArquitecturaFotosPreview.tscn | tscn | ARQUITECTURA_REFERENCIAS_2026_10.md | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/arquitectura_fotos_preview.gd | gd | ARQUITECTURA_REFERENCIAS_2026_10.md, tests/ArquitecturaFotosPreview.tscn | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/auditorio_access_check.gd | gd | AuditorioAccessCheck.tscn | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/balance_audit.gd | gd | BALANCE_1_0.md | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/balance_regression.gd | gd | tests/academic_regression_runner.gd | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/BasementAccessCheck.tscn | tscn | README.md, tests/academic_regression_runner.gd | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/basement_access.gd | gd | ACADEMIC_BOSSES_3_0.md, tests/BasementAccessCheck.tscn | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/campaign_regression.gd | gd | ARQUITECTURA_REFERENCIAS_2026_10.md, CAMPANA.md, GUIA.md, PERSONALIZACION.md, tests/academic_regression_runner.gd, tests/arquitectura_fotos_preview.gd, tests/current_project_validation.cjs, tests/supabase_regression_runner.gd | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/campaign_smoke.gd | gd | CAMPANA.md | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/CampusFixesCheck.tscn | tscn | BALANCE_1_0.md, BALANCE_REPORT_1_0.md, PLAYTEST_1_0.md, RESUMEN_JUEGO.md | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/campus_fixes.gd | gd | BALANCE_1_0.md, BALANCE_REPORT_1_0.md, PLAYTEST_1_0.md, RESUMEN_JUEGO.md, tests/CampusFixesCheck.tscn | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/campus_vivo.gd | gd | CAMPUS_VIVO_2_0.md, GUIA_CREAR_CONTENIDO.md, tests/academic_regression_runner.gd, tests/current_project_validation.cjs, tests/supabase_regression_runner.gd | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/casino_referencia.gd | gd | Main.tscn | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/chair_access_probe.gd | gd | CIERRE_CAMPANA_1_0.md, tests/balance_audit.gd, tests/closure_probe.gd, tests/nexo_final.gd | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/chapel_layout_check.gd | gd | Sin referencia literal detectada | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/characters3.gd | gd | PERFORMANCE_PROFILE.md | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/chef_supremo_casino.gd | gd | CAMPANA.md, INVENTARIO.md, Main.tscn, tests/academic_regression_runner.gd | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/closure_probe.gd | gd | Sin referencia literal detectada | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/ContextualPreview.tscn | tscn | INTERACCIONES_CONTEXTUALES.md | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/contextual_interactions.gd | gd | INTERACCIONES_CONTEXTUALES.md | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/contextual_preview.gd | gd | tests/ContextualPreview.tscn | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/coordinacion_layout_check.gd | gd | Sin referencia literal detectada | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/coordinacion_meeting_check.gd | gd | Sin referencia literal detectada | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/coordinacion_meeting_preview.gd | gd | Sin referencia literal detectada | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/CostadosPreview.tscn | tscn | Sin referencia literal detectada | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/costados_preview.gd | gd | tests/arquitectura_fotos_preview.gd, tests/CostadosPreview.tscn | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/director_informatica_boss.gd | gd | BOSSES_SUPERIORES_2_0.md, CAMPANA.md, INVENTARIO.md, Main.tscn, scripts/pisos/piso_8/INFORMACION.md, tests/academic_regression_runner.gd, tests/current_project_validation.cjs, tests/inventory_regression.gd (+1) | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/education_1_0.gd | gd | PLAYTEST_1_0.md, tests/supabase_regression_runner.gd | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/education_gate_fixture.gd | gd | tests/education_1_0.gd | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/education_integration.gd | gd | PLAYTEST_1_0.md | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/ElevatorBasementCheck.tscn | tscn | README.md, tests/academic_regression_runner.gd | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/elevator_basement.gd | gd | ACADEMIC_BOSSES_3_0.md, tests/ElevatorBasementCheck.tscn | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/EmailRegistrationCheck.tscn | tscn | PLAYTEST_1_0.md, tests/current_project_validation.cjs | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/email_auth_client_fixture.gd | gd | tests/email_auth_manager_fixture.gd, tests/supabase_session_fixture.gd | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/email_auth_manager_fixture.gd | gd | tests/email_registration_check.gd, tests/registration_shell_fixture.gd | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/email_registration_check.gd | gd | tests/EmailRegistrationCheck.tscn | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/gameplay_regression.gd | gd | CAMPANA.md, GUIA.md, INVENTARIO.md, README.md, tests/academic_regression_runner.gd, tests/current_project_validation.cjs, tests/supabase_regression_runner.gd | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/generar_local_piso3.gd | gd | scripts/pisos/piso_3/INFORMACION.md | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/generar_piso8.gd | gd | scripts/pisos/piso_8/INFORMACION.md | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/generar_sala_detras_local.gd | gd | Sin referencia literal detectada | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/generar_tienda_piso5.gd | gd | Sin referencia literal detectada | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/guardado_lectura.gd | gd | tests/academic_regression_runner.gd, tests/current_project_validation.cjs, tests/supabase_regression_runner.gd | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/HumanPilot.tscn | tscn | HUMAN_MODEL_IMPORT.md, HUMAN_PILOT_REPORT.md, tests/human_pilot.gd | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/HumanPilotCheck.tscn | tscn | HUMAN_PILOT_REPORT.md | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/HumanPilotInspect.tscn | tscn | Sin referencia literal detectada | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/human_pilot.gd | gd | HUMAN_PILOT_REPORT.md, tests/HumanPilot.tscn, tests/human_pilot_check.gd | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/human_pilot_check.gd | gd | tests/HumanPilotCheck.tscn | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/human_pilot_inspect.gd | gd | tests/HumanPilotInspect.tscn | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/inventory_regression.gd | gd | CAMPANA.md, GUIA.md, INVENTARIO.md, tests/academic_regression_runner.gd, tests/arquitectura_fotos_preview.gd, tests/current_project_validation.cjs, tests/supabase_regression_runner.gd | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/library_access_check.gd | gd | LibraryAccessCheck.tscn | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/library_layout_check.gd | gd | Sin referencia literal detectada | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/library_preview.gd | gd | Sin referencia literal detectada | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/local_piso3_recorridos.gd | gd | scripts/pisos/piso_3/INFORMACION.md | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/NexoVisualCheck.tscn | tscn | Sin referencia literal detectada | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/nexo_final.gd | gd | CIERRE_CAMPANA_1_0.md, scripts/campaign/quest_manager.gd, scripts/live/campus_qol.gd, tests/academic_regression_runner.gd, tests/current_project_validation.cjs, tests/nexo_visual_check.gd, tests/supabase_regression_runner.gd | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/nexo_visual_check.gd | gd | tests/NexoVisualCheck.tscn | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/nueva_partida.gd | gd | GUIA.md, HORARIO_Y_ASISTENCIA.md, PERSONALIZACION.md, tests/academic_regression_runner.gd, tests/current_project_validation.cjs, tests/supabase_regression_runner.gd | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/organizacion_pisos.gd | gd | GUIA.md, README.md, scripts/pisos/README.md, tests/academic_regression_runner.gd, tests/arquitectura_fotos_preview.gd, tests/current_project_validation.cjs, tests/supabase_regression_runner.gd | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/PerformanceProfile.tscn | tscn | PERFORMANCE_PROFILE.md | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/performance_profile.gd | gd | PERFORMANCE_PROFILE.md, tests/PerformanceProfile.tscn | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/performance_regression.gd | gd | PERFORMANCE_PROFILE.md | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/performance_startup.gd | gd | RENDIMIENTO.md, tests/academic_regression_runner.gd, tests/arquitectura_fotos_preview.gd | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/personajes2.gd | gd | PERFORMANCE_PROFILE.md, PERSONAJES_2_0.md | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/personalizacion.gd | gd | PERSONALIZACION.md | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/PersonalizacionPreview.tscn | tscn | PERSONALIZACION.md | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/personalizacion_preview.gd | gd | tests/PersonalizacionPreview.tscn | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/PhonePreview.tscn | tscn | CELULAR_Y_MENSAJES.md | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/phone_preview.gd | gd | CELULAR_Y_MENSAJES.md, tests/PhonePreview.tscn | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/piso5_escalera_recorrido.gd | gd | Sin referencia literal detectada | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/piso8_recorridos.gd | gd | scripts/pisos/piso_6/INFORMACION.md, scripts/pisos/piso_7/INFORMACION.md, scripts/pisos/piso_8/INFORMACION.md | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/primera_mision.gd | gd | Sin referencia literal detectada | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/recorrido_coordinacion.gd | gd | RecorridoCoordinacion.tscn | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/registration_shell_fixture.gd | gd | tests/signup_diagnostics_unit.gd | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/remember_login_check.gd | gd | AUTH_ARCHITECTURE.md, tests/current_project_validation.cjs | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/remember_login_shell_fixture.gd | gd | tests/remember_login_check.gd | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/resource_reference_check.gd | gd | tests/current_project_validation.cjs | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/revision_scripts.gd | gd | GUIA.md, PERSONALIZACION.md, tests/academic_regression_runner.gd, tests/current_project_validation.cjs | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/RolePanelPreview.tscn | tscn | Sin referencia literal detectada | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/roles_auth_fixture.gd | gd | tests/roles_shell_fixture.gd, tests/user_roles_check.gd | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/roles_backend_fixture.gd | gd | tests/roles_auth_fixture.gd, tests/user_roles_check.gd | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/roles_shell_fixture.gd | gd | tests/RolePanelPreview.tscn, tests/user_roles_check.gd | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/salidas_emergencia.gd | gd | Sin referencia literal detectada | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/SignupDiagnosticsCheck.tscn | tscn | Sin referencia literal detectada | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/SignupDiagnosticsUnit.tscn | tscn | tests/current_project_validation.cjs | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/signup_diagnostics_check.gd | gd | tests/SignupDiagnosticsCheck.tscn | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/signup_diagnostics_unit.gd | gd | tests/SignupDiagnosticsUnit.tscn | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/student_phone.gd | gd | ACADEMIC_BOSSES_3_0.md, AUTH_ARCHITECTURE.md, CELULAR_Y_MENSAJES.md, HORARIO_Y_ASISTENCIA.md, scripts/campaign/campus_campaign.gd, tests/academic_regression_runner.gd, tests/current_project_validation.cjs, tests/supabase_regression_runner.gd | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/SupabaseAuthCheck.tscn | tscn | tests/current_project_validation.cjs | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/SupabaseConnectionCheck.tscn | tscn | Sin referencia literal detectada | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/SupabaseRegressionRunner.tscn | tscn | Sin referencia literal detectada | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/supabase_auth_check.gd | gd | tests/SupabaseAuthCheck.tscn | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/supabase_connection_check.gd | gd | tests/SupabaseConnectionCheck.tscn | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/supabase_regression_runner.gd | gd | tests/SupabaseRegressionRunner.tscn | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/supabase_session_fixture.gd | gd | tests/remember_login_check.gd, tests/roles_auth_fixture.gd, tests/supabase_auth_check.gd | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/tienda_piso5_acceso.gd | gd | Sin referencia literal detectada | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/UpperCampusCheck.tscn | tscn | BALANCE_1_0.md, BALANCE_REPORT_1_0.md, BOSSES_SUPERIORES_2_0.md, RESUMEN_JUEGO.md, tests/HumanPilotCheck.tscn, tests/PerformanceProfile.tscn | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/UpperVisualCheck.tscn | tscn | BOSSES_SUPERIORES_2_0.md | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/upper_campus_check.gd | gd | BOSSES_SUPERIORES_2_0.md, tests/human_pilot_check.gd, tests/performance_profile.gd, tests/UpperCampusCheck.tscn | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/upper_visual_probe.gd | gd | BOSSES_SUPERIORES_2_0.md, tests/UpperVisualCheck.tscn | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/UserRolesCheck.tscn | tscn | ROLE_SYSTEM.md, tests/current_project_validation.cjs | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/user_roles_check.gd | gd | tests/UserRolesCheck.tscn | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/verificar_fusion_main.gd | gd | Sin referencia literal detectada | TEST ONLY / KEEP | Conservar herramienta o regresión ejecutable manualmente; no se ha demostrado reemplazo. |
| tests/__pycache__/build_balance_docs.cpython-312.pyc | pyc | Sin referencia literal detectada | OBSOLETE / SAFE TO DELETE | Caché regenerable de Python; candidato seguro. No eliminado en esta auditoría inicial. |

## Coincidencias exactas de contenido

- reports/performance_after.json, reports/performance_current.json — KEEP: igualdad de contenido no implica intercambiabilidad de rutas.

## Sin referencias literales: revisión conservadora

Estos archivos NO se consideran SAFE TO DELETE: pueden ser entrypoints manuales, suites invocadas dinámicamente o usar class_name.

- pasillo_capilla_piso_1.gd
- RecorridoCoordinacion.tscn
- scripts/exterior/aplicar_materiales_entrada.gd
- scripts/juego/character_body_3d.gd
- scripts/pisos/piso_1/arma_ayuda_estudiantil.gd
- scripts/pisos/piso_4/piso_4_correccion_central.gd
- scripts/pisos/piso_4/piso_4_salas_centrales.gd
- tests/AcademicExtraChecks.tscn
- tests/AcademicRegressionRunner.tscn
- tests/chapel_layout_check.gd
- tests/closure_probe.gd
- tests/coordinacion_layout_check.gd
- tests/coordinacion_meeting_check.gd
- tests/coordinacion_meeting_preview.gd
- tests/CostadosPreview.tscn
- tests/generar_sala_detras_local.gd
- tests/generar_tienda_piso5.gd
- tests/HumanPilotInspect.tscn
- tests/library_layout_check.gd
- tests/library_preview.gd
- tests/NexoVisualCheck.tscn
- tests/piso5_escalera_recorrido.gd
- tests/primera_mision.gd
- tests/RolePanelPreview.tscn
- tests/salidas_emergencia.gd
- tests/SignupDiagnosticsCheck.tscn
- tests/SupabaseConnectionCheck.tscn
- tests/SupabaseRegressionRunner.tscn
- tests/tienda_piso5_acceso.gd
- tests/verificar_fusion_main.gd

## Verificación

Resultados de esta ejecución: reports/current_project_validation.json y logs current_*.log. La revisión de recursos usa tests/revision_scripts.gd y no ejecuta herramientas de edición. No se eliminaron rutas; cualquier error previo encontrado se documenta separadamente. Pruebas de credenciales y Supabase remoto requieren verificación manual del usuario.


## Resultados de la ejecución actual

- remember_login_check: PASS; [{"checks":15,"failures":[],"real_accounts_modified":0}]
- revision_scripts: PASS; [{"checked":261,"failures":[]}]
- inventory_regression: PASS; [{"failures":[],"passed":true}]
- gameplay_regression: PASS; [{"failures":[],"passed":true}]
- guardado_lectura: PASS; [{"failures":[]}]
- campaign_regression: PASS; [{"failures":[],"passed":true}]
- student_phone: PASS; [{"checks":31,"failures":[]}]
- nueva_partida: PASS; [{"failures":[]}]
- director_informatica_boss: PASS; []
- campus_vivo: PASS; [{"checks":52,"failures":[],"qa_review":["Check credential source and physical route: acceso7","Check credential source and physical route: nexo_core","Stairs, door connectivity and arena exits require an in-game traversal; no automatic geometry repair"]}]
- organizacion_pisos: PASS; [{"failures":[],"pisos":["Piso −1","Piso 1","Piso 2","Piso 3","Piso 4","Piso 5","Piso 6","Piso 7","Piso 8"],"rutas":596}]
- SupabaseAuthCheck: PASS; [{"checks":59,"failures":[],"real_accounts_created":0,"session_storage":"isolated in-memory fixture"}]
- EmailRegistrationCheck: PASS; [{"checks":21,"failures":[],"real_passwords_used":false,"remote_registration":"NOT TESTED: requires configured Supabase and SMTP"}]
- nexo_final: PASS; [{"checks":111,"failures":[]}]
- UserRolesCheck: PASS; [{"backend":"in-memory policy model plus SQL static checks; remote RLS NOT TESTED","checks":63,"failures":[],"real_users_created":0,"real_users_modified":0}]
- AcademicBossesCheck: PASS; [{"actors":["profesor_datos","profesor_algoritmos","docente_enfermeria","docente_odontologia","coordinador_profesores","profesor_matematicas","profesor_ingles","profesor_lenguaje","profesor_etica"],"checks":320,"expansion_failures":[],"failures":[],"stage":11}]
- SignupDiagnosticsUnit: PASS; [{"checks":47,"failures":[],"real_accounts_created":0}]
- resource_reference_check: PASS; [{"checked_scenes":43,"failures":[]}]

Godot MCP confirmó la escena Login con botones Iniciar sesión, Registrarse y Salir (Google deshabilitado por configuración), y Main.tscn en ejecución sin errores en su log. La revisión cargó 261 scripts/recursos y 43 escenas. No hay fallos de carga ni referencias rotas detectadas en ese alcance. La consola del editor conservaba un error anterior de MAT_Piedra_Posterior.tres; no se reprodujo en estas cargas. Se mantienen todas las migraciones y todos los archivos auditados. Las pruebas auth son simuladas, no validación de Supabase remoto ni de credenciales reales.
