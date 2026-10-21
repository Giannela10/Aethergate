# PLAYTEST Y BALANCE 1.0 — recorrido manual

## DUOCGAMES EDUCATIVO 1.0 — 20-10-2026

Registro por correo añadido: prueba local con 21 checks sin fallos en
`reports/email_registration_tests.json` (respuestas simuladas, sin crear cuentas
reales). Escena de comprobación: `tests/EmailRegistrationCheck.tscn`.

- [ ] Login → Registrarse mantiene el fondo del campus y muestra nombre/correo/contraseñas ocultas.
- [ ] Correo inválido, contraseña corta y confirmación distinta muestran un error.
- [ ] Sin configurar Supabase se informa del requisito; no se crea ninguna cuenta local.
- [ ] Con Supabase real, registro envía confirmación; después se puede iniciar sesión.
- [ ] La cuenta nueva tiene role student y no puede elegir teacher/admin.
- [ ] Acceso con correo y Google conservan el mismo menú, guardado y cierre de sesión.

Pruebas automáticas: `tests/education_1_0.gd` y `tests/education_integration.gd`.
Resultados y límites en `reports/education_1_0_tests.json`,
`reports/education_integration_tests.json` y `reports/EDUCATION_1_0_VALIDATION.md`.
Las fixtures no equivalen a la validación de Google ni a un recorrido humano.

- [ ] F5 abre Login limpio; sin configuración informa el estado sin crashear.
- [ ] DEV STUDENT/TEACHER/ADMIN aparecen en debug y faltan en una exportación Release.
- [ ] Google real abre navegador, vuelve a localhost, carga perfil y menú correcto.
- [ ] Reiniciar renueva la sesión; revocar/expirar vuelve a Login.
- [ ] Logout borra sesión local y permite cambiar de cuenta sin borrar campaña.
- [ ] Cuenta student no puede cambiar role ni leer question_keys por REST.
- [ ] Docente asignado crea/edita/reactiva preguntas propias; otro docente no puede editarlas.
- [ ] Preview no registra intento; errores del avatar no bloquean el menú.
- [ ] Piso 3 por ascensor, escalera central, emergencia y descenso desde 4 pide el desafío.
- [ ] Incorrecta: explicación, sin daño/pérdidas, otra pregunta y opción de volver.
- [ ] Correcta: desbloqueo, guardar/cerrar/continuar sin repetir.
- [ ] Mando físico: foco, selección de alternativas, resultado y volver.
- [ ] Cortar Internet: reintento/fallback claramente identificado, sin fingir validación remota.
- [ ] Save antiguo mantiene inventario, misiones, Director y NEXO; Nueva partida conserva copia.
- [ ] Release no contiene demo_questions.json con claves, SQL ni configuración local real.

Configurar primero [Google/Supabase](GOOGLE_SUPABASE_SETUP.md). No marcar OAuth,
RLS real, sesión remota persistente ni exportación Release como PASS sin ejecutarlos.

## Checklist vigente — Academic Bosses 3.0

Todos los casos siguientes están **PENDIENTES DE PRUEBA HUMANA**. Registrar equipo, resolución, calidad, arma, mejoras, duración y muertes. Las ubicaciones antiguas de Inglés/Lenguaje/Ética del historial se sustituyen por las siguientes. No marcar PASS mediante fixture automática.

### Piso 3

- [ ] Bases de Datos neutral, E, iniciar/cancelar duelo.
- [ ] Registro Corrupto, copias falsas y Error de Conexión anunciados.
- [ ] Selección física de tabla, JOIN, fases 60%/30% y Consulta Final.
- [ ] LlaveDeDatos una sola vez, inventario y save/load.
- [ ] Algoritmos neutral, secuencia, BREAK/Bucle y Debug Mode.
- [ ] DepuradorPortatil, ralentización posterior y save/load.
- [ ] Basta Datos o Algoritmos para progresar; Redes permanece opcional y funcional.

### Piso 4

- [ ] Enfermería en norte/salud: presión, zonas, triaje ficticio y dispositivos.
- [ ] KitClinicoMejorado: botiquín +5, sin cambiar alimentos.
- [ ] Odontología en norte/salud: Taladro, Enjuague, placas y CARIES.
- [ ] ProtectorDental: empuje menor, daño intacto.
- [ ] Coordinador en Sala de Profesores: buscar tres docentes, hablar sin vencerlos, regresar y desbloquear duelo.
- [ ] Carpetazo, Documentos, Cambio de Sala y Horario Cambiado; premio MapaDocente.
- [ ] Mapa/celular solo indican sectores de profesores conocidos.

### Pisos 5 y 6

- [ ] Piso 5 sin boss de Inglés, misión general alcanzable y documentos/TarjetaAcceso intactos.
- [ ] Inglés en 6: combate, banco de preguntas, zonas A/B/C, tiempo y apertura.
- [ ] AudifonosDeTraduccion y guardado; conservación de AuricularesLinguisticos anterior.
- [ ] Ética en 6: A/B, PROTEGER/PERSEGUIR y consecuencias sin respuesta moral correcta.
- [ ] InsigniaDeIntegridad y conservación del premio antiguo InsigniaIntegridad.

### Piso 7

- [ ] Comunicación: Ruido, Mensaje Claro y Escucha Activa después de dos pulsos.
- [ ] InsigniaDeOratoria: una Comida extra en ayuda, sin duplicación al cargar.
- [ ] Matemáticas: operación, patrón, círculo seguro y ecuación final con presión moderada.
- [ ] CalculadoraAvanzada: pistas/tiempos compatibles, sin auto-resolver.
- [ ] Acceso7 conserva puerta y requisito TarjetaAcceso.

### Piso 8 y regresión

- [ ] Conexión: equipo, cable, adaptador y reiniciar.
- [ ] Antivirus breve mediante minijuego existente.
- [ ] PC01/02/03: comparar redes, rechazar corrección incorrecta y aceptar PC03.
- [ ] Progreso Director 0/3 → 3/3, bloqueo previo, intro y duelo original.
- [ ] CredencialDirector, USBInfectado, virus, Firewall y Pantallazo Azul intactos.
- [ ] Todos los profesores: cámara, espacio, salida, proyectiles contra paredes, señales legibles y ausencia de saturación.
- [ ] Muerte/reintento mediante UI: vida, estamina, arma, desgaste, consumibles y limpieza de objetivos.
- [ ] Save antiguo: victorias de Inglés/Lenguaje/Ética y Director conservadas, nuevos premios únicos y ascensores utilizables.
- [ ] Nueva partida limpia; ruta principal completa hasta NEXO intacta.
- [ ] Recorrido gráfico por todos los pisos y combates completos; medir FPS/memoria sin confundirlo con headless.

IDs, valores, efectos y evidencia automática: [ACADEMIC_BOSSES_3_0.md](ACADEMIC_BOSSES_3_0.md).

Actualización 16-10-2026: el archivo del −1 ya no termina la campaña; activa la misión del núcleo. Completar también **FINAL NEXO**, al final de esta lista. **NEXO: PENDIENTE DE BALANCE HUMANO.** Ninguna casilla manual queda aprobada por las pruebas automáticas.

Todas las casillas comienzan pendientes. Las suites automáticas no equivalen a estas pruebas humanas. Guardar copia de la partida antes de Nueva partida; anotar versión/PC/resolución/calidad/FPS, tiempo activo, muertes, arma, curaciones, XP y créditos al entrar/salir de cada piso. Telemetría opt-in solo local en Ajustes; no se envía a internet.

## Sesión manual después de las correcciones — 18 pruebas

Fecha: __________ · Persona: __________ · Versión/commit: __________
Equipo: __________ · Resolución/calidad/FPS: __________ · Partida de prueba: __________

Marcar solo **PASS** o **FAIL** después de ejecutar cada prueba jugando. Ambas casillas vacías significan pendiente o no ejecutada; registrar el motivo en observaciones. Las validaciones automáticas anteriores no aprueban estas pruebas. Usar una copia de partida y mantener balance, scripts y escenas sin cambios.

Para las pruebas 11–13 hace falta un WorldItem accesible con varias unidades y capacidad de inventario controlada. Si no hay un lote disponible en la partida de prueba, dejar ambas casillas vacías y anotar «No ejecutada: falta lote de prueba»; no sustituir la sesión manual por el resultado de la fixture automática ni modificar contenido para esta sesión.

### 1. Chef Supremo: 350 HP

Hablar con el Chef en el casino del Piso 1 e iniciar el duelo. Comprobar nombre «Chef Supremo del Casino», barra completa y lectura **350 / 350**, sin usar el antiguo máximo de 450.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________________

### 2. Chef: fases al 60% y 30%

Reducir su vida jugando: fase 1 por encima de 210 HP; fase 2 al alcanzar o cruzar **210 HP (60%)**; fase 3 al alcanzar o cruzar **105 HP (30%)**. Registrar HP antes/después de cada transición; no exigir golpear exactamente el umbral ni confundir un salto de daño con una fase ausente.

- [ ] PASS
- [ ] FAIL

Observaciones (HP/transiciones): ___________________________________________

### 3. Chef: muerte y reintento

Morir contra el Chef y elegir reintentar desde la pantalla de muerte. Comprobar retorno al duelo, Chef a **350 HP y fase 1**, recursos/arma/desgaste previos restaurados y ausencia de bandejas sobrantes o recursos duplicados. Repetir una segunda derrota.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________________

### 4. Chef: recompensa y curación al vencer

Derrotarlo con vida del jugador incompleta. Comprobar curación hasta la vida máxima, recompensa existente (BandejaDelChef y LlaveCasino), actualización de misión y desbloqueo correspondiente. Guardar, cerrar y continuar: el Chef sigue derrotado y no se repiten premios.

- [ ] PASS
- [ ] FAIL

Observaciones (vida/recompensa): ___________________________________________

### 5. Piso 4: organización docente

Encontrar y completar **pc4: Organización docente**, clasificando documentos de profesores. Verificar instrucciones/opciones coherentes, ausencia del antiguo desafío de contraseña y avance de academico4 sin alterar la división Salud al norte/profesores en el otro sector.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________________

### 6. Piso 5: Inglés

Completar **pc5: Inglés, vocabulario**. Comprobar clasificación de palabras, feedback legible y ENGLISH_PREPARED; no debe presentarse como clasificación informática por extensiones. Para nuevas partidas, academico5 avanza al vencer al Profesor de Inglés; el computador es preparación opcional.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________________

### 7. Piso 6: Lenguaje

Completar **pc6: Lenguaje, comprensión lectora**. Comprobar texto/categorías, ausencia de contraseña y LECTURA_PREPARADA. La misión conserva seguridad6/«Práctica de Lenguaje» y habilita el Piso 7 al vencer al Profesor de Lenguaje, con o sin computador.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________________

### 8. Piso 7: Ética

Abrir acceso7 con TarjetaAcceso y completar **pc7: Ética, decisiones cotidianas**. Comprobar decisiones/valores, ausencia de Antivirus, tarjeta conservada y REFLEXION_PREVIA. El desbloqueo de 8 requiere además vencer al Profesor de Ética; el computador sigue opcional.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________________

### 9. Piso 8: documentos NEXO

Completar **pc8: NEXO, revisión de documentos**. Comprobar clasificación narrativa, ausencia de contraseña y NEXO_INFORMATION. direccion se completa venciendo al Director, con preparación opcional. El Director permanece en Piso 8 como excepción narrativa, sin convertir la actividad normal en otro desafío técnico.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________________

### 10. Piso 3: cuatro apuntes tecnológicos

Localizar caminando los apuntes de **Programación, Bases de Datos, Redes e IA**, leerlos y comprobar su registro. Verificar accesibilidad física y ausencia de duplicados; en una copia de partida donde ya se recogió alguno, cargar y comprobar que no reaparece por su traslado.

- [ ] PASS
- [ ] FAIL

Observaciones (cada apunte/acceso): ________________________________________

### 11. WorldItem: recogida parcial

Con un lote de **5 unidades** y espacio para **2**, recoger una vez: el inventario aumenta en 2 y el objeto conserva **3**, visible e interactivo con contexto **x3**. Liberar espacio y recoger el resto: recibe exactamente 3 y solo entonces el objeto desaparece. Registrar las cantidades iniciales/finales.

- [ ] PASS
- [ ] FAIL

Observaciones (objeto/cantidades): _________________________________________

### 12. WorldItem parcial: guardar y cargar

Usar otro lote o repetir desde una copia previa: recoger 2 de 5 y dejar 3. Guardar fuera de duelo, cerrar completamente, abrir y Continuar. Deben permanecer **3 en el mundo y las 2 recibidas en el inventario**, sin volver a 5 ni desaparecer. Liberar espacio, recoger las 3, guardar/cargar y comprobar que el lote agotado no reaparece.

- [ ] PASS
- [ ] FAIL

Observaciones (antes/después de cargar): ___________________________________

### 13. Inventario lleno

Llenar entradas y stacks aplicables. Intentar recoger un WorldItem: acepta **0**, no cambia su cantidad ni desaparece. Intentar comprar sin espacio: no cobra. Liberar espacio y comprobar recogida normal. Verificar también que los Documentos obligatorios se reciben y permiten obtener TarjetaAcceso aun con mochila llena.

- [ ] PASS
- [ ] FAIL

Observaciones (capacidad/objetos/créditos): _________________________________

### 14. Guardado durante campaña

Antes de salir, anotar piso/posición, vida, inventario/cantidades/desgaste, misiones, computadores, bosses, claves, XP y créditos. Tras una acción de progreso y autoguardado, cerrar y continuar: conservar esos datos sin repetir recompensas ni perder desbloqueos. Probar por separado cierre durante intro/combate de boss: debe recuperar el estado completo previo y boss neutral. Si se dispone de una copia con fallo de escritura controlado, comprobar aviso «No se pudo guardar la partida.» sin spam; si no, anotar ese subcaso pendiente.

- [ ] PASS
- [ ] FAIL

Observaciones (estado previo/cargado/subcasos pendientes): _________________

### 15. Muerte/reintento mediante UI

En otro encuentro disponible, morir y usar los botones reales de la pantalla de muerte. Probar reintento de boss y alternativa checkpoint: sin bloqueo del menú, ratón o movimiento; recursos restaurados según la opción; checkpoint abandona el reintento previo y las acciones posteriores se guardan correctamente.

- [ ] PASS
- [ ] FAIL

Observaciones (encuentro/opción/resultado): _________________________________

### 16. Minijuegos sin quedar tapados por HUD

Abrir y jugar pc4–pc8. Comprobar que objetivo, avisos, barra rápida e inventario no tapan instrucciones, tarjetas, botones ni feedback. Probar la resolución de la sesión y otra resolución disponible; cerrar y comprobar retorno del control normal.

- [ ] PASS
- [ ] FAIL

Observaciones (PC/resoluciones/recortes): __________________________________

### 17. Ascensores y progresión

Verificar llamadas, selección de destino, entrada, viaje y salida sin atasco/caída. Los pisos bloqueados se habilitan mediante las misiones originales: Inglés→6, Lenguaje→7 y puerta acceso7/Ética→8. Computadores superiores preparan pero no son obligatorios. Comprobar flags al cargar y descenso al −1; probar los tres ascensores.

- [ ] PASS
- [ ] FAIL

Observaciones (ascensor/piso/desbloqueo): __________________________________

### 18. Ruta física completa: Piso 1 → Piso 8 → −1

Recorrer jugando **1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → −1**, completando los requisitos de campaña, sin teletransporte de depuración. Incluir entrada/Punto/casino, biblioteca, documentos y apuntes del 3, actividades 4–8, Director y llegada a talleres/archivo del −1. Comprobar escaleras, puertas, descansos y accesos sin colisiones invisibles, caídas ni bloqueos; registrar trayecto, tiempo e incidencias. El archivo conduce a FINAL NEXO, cuyo checklist se conserva más abajo.

- [ ] PASS
- [ ] FAIL

Observaciones (ruta/tiempo/bloqueos): _______________________________________

## Ruta completa disponible

- [ ] Nueva partida: respaldo, apariencia, spawn seguro, 100 HP y 30 créditos iniciales.
- [ ] Tutorial: leer cinco consejos sin que desaparezcan dentro del menú/diálogo; no esperar todos para moverse.
- [ ] Movimiento: caminar, correr hasta agotar estamina, recuperar, agacharse, saltar, esquiva y cámara.
- [ ] Piso 1: recoger Palo o silla, equipar, usar inventario, cuatro quickslots, celular y mapa.
- [ ] Piso 1: pc_intro; hablar/declinar/aceptar Punto; vencer; Chef; victoria cura y conserva recompensa única.
- [ ] Ascensor a 2 desbloqueado; subir/bajar escaleras sin caer, puertas y llamadas de ascensor funcionan.
- [ ] Piso 2: tres libros distintos; quiz Bibliotecaria: error/acierto/feedback, derrota/reintento; victoria cinco aciertos.
- [ ] Piso 3: NPC Profesor y documentos; recoger cargador; Antivirus pc3; primera anomalía; clase opcional de Programación/Redes.
- [ ] Redes opcional: se puede omitir y seguir; probar routers/fases/ralentización y premio RouterPortatil.
- [ ] Piso 4: organización docente pc4; llaves; respetar salud al norte/profesores al otro sector; centro y checkpoint.
- [ ] Piso 5: vocabulario de Inglés pc5; entregar Documentos al Funcionario; TarjetaAcceso aun con mochila llena; clase opcional.
- [ ] Piso 6: comprensión lectora pc6, checkpoint cercano mediante centro de vida, CampusState MEDIUM.
- [ ] Piso 7: puerta acceso7 reconoce TarjetaAcceso, no la consume; decisiones de Ética pc7; desbloqueo de 8.
- [ ] Piso 8: revisión documental NEXO pc8; Director; obtener CredencialDirector y TecladoAdministrador; sala especial/puerta conserva acceso.
- [ ] Subterráneo −1: acceso por ascensor/escalera, checkpoint y talleres; archivo_subterraneo activa la principal final de NEXO.
- [ ] Archivo revela información sin iniciar combate ni restaurar todavía el campus; preparar equipo y continuar con FINAL NEXO.
- [ ] PC secreto opcional, USBMaestro; mapa postgame y viajes solo a destinos descubiertos, llegada segura.
- [ ] Guardar, cerrar proceso, abrir y Continuar después de cada piso: inventario, HP, misiones, bosses, reloj, NPC, cosméticos, XP/créditos, durabilidad, eventos y CampusState coherentes.

## Tiempo, diversión y dificultad

- [ ] Cronometrar principal hasta el archivo sin Redes ni coleccionables y contrastar la hipótesis anterior de 1–2,5 h; medir el nuevo tramo NEXO por separado, con reintentos/pausas separados. La duración total actual queda pendiente.
- [ ] Cronometrar secundarias y 100%; no sumar dos veces pc3/infectado ni Chef/casino.
- [ ] Primera hora incluye objeto, inventario, computador, NPC, primer duelo y un descubrimiento sin veinte menús consecutivos.
- [ ] Medir caminatas entrada→Punto/casino y 3→5; anotar tramos aburridos o más de 3 min sin decisión.
- [ ] Comparar pelea con Palo, Silla, LibroPesado y única, sin mejoras y con Fuerza máxima. ¿Hay ataques/armas sin propósito?
- [ ] Registrar tiempo de primera y segunda victoria de cada boss y porcentaje aproximado golpeando; no asumir 2–6 min.
- [ ] Pesados de 4/7/−1: resistencia justificada, posibilidad de evitar; nadie elimina de un ataque normal a vida completa.
- [ ] Esquiva: 0,22 s invulnerable, coste 25/cd 0,7; no spam ilimitado; fuerte cuesta 30 y compensa riesgo/carga.
- [ ] Centros durante boss rechazan; fuera de duelo medir abuso de curar junto a enemigo. Consumibles siguen siendo útiles.
- [ ] Comparar ingresos/gastos: poder comprar consumibles/mejoras sin conseguir las 25 mejoras demasiado pronto.
- [ ] Repetir PC, misión y victoria no duplica créditos; recargar enemigos y medir farming antes de decidir cambios.
- [ ] Notas/asistencia bajas o faltar no bloquean campaña; no esperar Inglés para seguir la principal.

## Softlocks y persistencia

- [ ] Llenar 64 entradas antes de aceptar Documentos: se entregan, se pueden devolver y obtener tarjeta.
- [ ] Cargar partida antigua con provided:documentos=true y sin Documentos; volver a Profesor recupera la clave una sola vez.
- [ ] Aceptar documentos primero con Funcionario, después hablar Profesor: entrega disponible.
- [ ] Claves no pueden soltarse/perderse; única/favorito pide confirmación o bloqueo correspondiente; inventario lleno no consume pickup.
- [ ] Guardado antiguo con bosses derrotados sin evento redundante avanza misión; computadores resueltos también.
- [ ] Cerrar durante intro/combate: Continuar devuelve al estado completo previo, boss neutral, sin pérdida/duplicado de objetos recogidos durante el duelo.
- [ ] Cerrar en pantalla de muerte de boss produce el mismo estado previo; vencer después paga una vez.
- [ ] Reintentar boss restaura consumibles/arma/durabilidad; reintentar checkpoint abandona snapshot y guardados posteriores reflejan nuevas acciones.
- [ ] Dos derrotas consecutivas y luego victoria: sin proyectiles/invocaciones sobrantes ni objetos duplicados.
- [ ] Guardado malformado conserva respaldo; versión futura no sobrescribe; probar solo con copia de fixture.

## Inventario

- [ ] Recoger sin perder cantidades, estado o durabilidad.
- [ ] Stack y límite 999 sin perder cantidades, estado o durabilidad.
- [ ] Equipar sin perder cantidades, estado o durabilidad.
- [ ] Soltar sin perder cantidades, estado o durabilidad.
- [ ] Romper sin perder cantidades, estado o durabilidad.
- [ ] Quickslot 1 sin perder cantidades, estado o durabilidad.
- [ ] Quickslot 2 sin perder cantidades, estado o durabilidad.
- [ ] Quickslot 3 sin perder cantidades, estado o durabilidad.
- [ ] Quickslot 4 sin perder cantidades, estado o durabilidad.
- [ ] Favorito sin perder cantidades, estado o durabilidad.
- [ ] Confirmación de única sin perder cantidades, estado o durabilidad.
- [ ] Comparador y efectos sin perder cantidades, estado o durabilidad.
- [ ] Mochila llena y compra rechazada sin perder cantidades, estado o durabilidad.
- [ ] Guardar sin perder cantidades, estado o durabilidad.
- [ ] Cargar sin perder cantidades, estado o durabilidad.

Reparar/mejorar armas no aplica: no existe ese servicio. Sí se prueban las cinco mejoras del jugador.

## Boss punto / Encargado

- [ ] diálogo y nombre.
- [ ] iniciar duelo e intro.
- [ ] ahora no: neutral, sin ataques.
- [ ] barra y daño correcto.
- [ ] fase 1.
- [ ] fase 2 (si aplica).
- [ ] fase 3 (si aplica).
- [ ] derrota del jugador.
- [ ] muerte/caída del boss o cierre del quiz.
- [ ] recompensa una sola vez y curación.
- [ ] guardado y carga tras victoria.
- [ ] reintento con snapshot.
- [ ] retorno a arena sin curación gratis.
- [ ] rematch: marcar N/A si no hay servicio.

## Boss chef / Chef Supremo

- [ ] diálogo y nombre.
- [ ] iniciar duelo e intro.
- [ ] ahora no: neutral, sin ataques.
- [ ] barra y daño correcto.
- [ ] fase 1.
- [ ] fase 2 (si aplica).
- [ ] fase 3 (si aplica).
- [ ] derrota del jugador.
- [ ] muerte/caída del boss o cierre del quiz.
- [ ] recompensa una sola vez y curación.
- [ ] guardado y carga tras victoria.
- [ ] reintento con snapshot.
- [ ] retorno a arena sin curación gratis.
- [ ] rematch: marcar N/A si no hay servicio.

## Boss bibliotecaria / Bibliotecaria

- [ ] diálogo y nombre.
- [ ] iniciar duelo e intro.
- [ ] ahora no: neutral, sin ataques.
- [ ] barra y daño correcto.
- [ ] fase 1.
- [ ] fase 2 (si aplica).
- [ ] fase 3 (si aplica).
- [ ] derrota del jugador.
- [ ] muerte/caída del boss o cierre del quiz.
- [ ] recompensa una sola vez y curación.
- [ ] guardado y carga tras victoria.
- [ ] reintento con snapshot.
- [ ] retorno a arena sin curación gratis.
- [ ] rematch: marcar N/A si no hay servicio.

## Boss profesor_redes / Profesor de Redes

- [ ] diálogo y nombre.
- [ ] iniciar duelo e intro.
- [ ] ahora no: neutral, sin ataques.
- [ ] barra y daño correcto.
- [ ] fase 1.
- [ ] fase 2 (si aplica).
- [ ] fase 3 (si aplica).
- [ ] derrota del jugador.
- [ ] muerte/caída del boss o cierre del quiz.
- [ ] recompensa una sola vez y curación.
- [ ] guardado y carga tras victoria.
- [ ] reintento con snapshot.
- [ ] retorno a arena sin curación gratis.
- [ ] rematch: marcar N/A si no hay servicio.
- [ ] Desconectar tres routers y reconocer reducción de escudo; una sola reconexión en fase 2.
- [ ] Pulso 7 s / interferencia 8 s / conexión 9 s; aviso 1,2 s legible y ralentización 3 s.

## Boss director / Director Informática

- [ ] diálogo y nombre.
- [ ] iniciar duelo e intro.
- [ ] ahora no: neutral, sin ataques.
- [ ] barra y daño correcto.
- [ ] fase 1.
- [ ] fase 2 (si aplica).
- [ ] fase 3 (si aplica).
- [ ] derrota del jugador.
- [ ] muerte/caída del boss o cierre del quiz.
- [ ] recompensa una sola vez y curación.
- [ ] guardado y carga tras victoria.
- [ ] reintento con snapshot.
- [ ] retorno a arena sin curación gratis.
- [ ] rematch: marcar N/A si no hay servicio.
- [ ] USB: 80 daño y 3 s de stun; quedan mecánicas por resolver. Dos virus como máximo por activación.
- [ ] Salir del círculo azul en 1,2 s sin depender de sonido.

## Misión inicio — Primer día

- [ ] iniciar / desbloquear requisito.
- [ ] objetivo comprensible y NPC localizable.
- [ ] progreso de cada paso.
- [ ] completar.
- [ ] recompensa única y entrada con mochila llena.
- [ ] guardar.
- [ ] cerrar y cargar sin repetir/perder progreso.

## Misión biblioteca — La guardiana del conocimiento

- [ ] iniciar / desbloquear requisito.
- [ ] objetivo comprensible y NPC localizable.
- [ ] progreso de cada paso.
- [ ] completar.
- [ ] recompensa única y entrada con mochila llena.
- [ ] guardar.
- [ ] cerrar y cargar sin repetir/perder progreso.

## Misión academico3 — Etapa académica · Piso 3

- [ ] iniciar / desbloquear requisito.
- [ ] objetivo comprensible y NPC localizable.
- [ ] progreso de cada paso.
- [ ] completar.
- [ ] recompensa única y entrada con mochila llena.
- [ ] guardar.
- [ ] cerrar y cargar sin repetir/perder progreso.

## Misión academico4 — Etapa académica · Piso 4

- [ ] iniciar / desbloquear requisito.
- [ ] objetivo comprensible y NPC localizable.
- [ ] progreso de cada paso.
- [ ] completar.
- [ ] recompensa única y entrada con mochila llena.
- [ ] guardar.
- [ ] cerrar y cargar sin repetir/perder progreso.

## Misión academico5 — Etapa académica · Piso 5

- [ ] iniciar / desbloquear requisito.
- [ ] objetivo comprensible y NPC localizable.
- [ ] progreso de cada paso.
- [ ] completar.
- [ ] recompensa única y entrada con mochila llena.
- [ ] guardar.
- [ ] cerrar y cargar sin repetir/perder progreso.

## Misión seguridad6 — Práctica de Lenguaje

- [ ] iniciar / desbloquear requisito.
- [ ] objetivo comprensible y NPC localizable.
- [ ] progreso de cada paso.
- [ ] completar.
- [ ] recompensa única y entrada con mochila llena.
- [ ] guardar.
- [ ] cerrar y cargar sin repetir/perder progreso.

## Misión acceso7 — Acceso restringido

- [ ] iniciar / desbloquear requisito.
- [ ] objetivo comprensible y NPC localizable.
- [ ] progreso de cada paso.
- [ ] completar.
- [ ] recompensa única y entrada con mochila llena.
- [ ] guardar.
- [ ] cerrar y cargar sin repetir/perder progreso.

## Misión direccion — Modo Administrador

- [ ] iniciar / desbloquear requisito.
- [ ] objetivo comprensible y NPC localizable.
- [ ] progreso de cada paso.
- [ ] completar.
- [ ] recompensa única y entrada con mochila llena.
- [ ] guardar.
- [ ] cerrar y cargar sin repetir/perder progreso.

## Misión postgame — Archivos del subterráneo

- [ ] iniciar / desbloquear requisito.
- [ ] objetivo comprensible y NPC localizable.
- [ ] progreso de cada paso.
- [ ] completar.
- [ ] recompensa única y entrada con mochila llena.
- [ ] guardar.
- [ ] cerrar y cargar sin repetir/perder progreso.

## Misión llaves — Las llaves perdidas

- [ ] iniciar / desbloquear requisito.
- [ ] objetivo comprensible y NPC localizable.
- [ ] progreso de cada paso.
- [ ] completar.
- [ ] recompensa única y entrada con mochila llena.
- [ ] guardar.
- [ ] cerrar y cargar sin repetir/perder progreso.

## Misión cargador — El cargador

- [ ] iniciar / desbloquear requisito.
- [ ] objetivo comprensible y NPC localizable.
- [ ] progreso de cada paso.
- [ ] completar.
- [ ] recompensa única y entrada con mochila llena.
- [ ] guardar.
- [ ] cerrar y cargar sin repetir/perder progreso.

## Misión documentos — Documentos importantes

- [ ] iniciar / desbloquear requisito.
- [ ] objetivo comprensible y NPC localizable.
- [ ] progreso de cada paso.
- [ ] completar.
- [ ] recompensa única y entrada con mochila llena.
- [ ] guardar.
- [ ] cerrar y cargar sin repetir/perder progreso.

## Misión implementos — Implementos perdidos

- [ ] iniciar / desbloquear requisito.
- [ ] objetivo comprensible y NPC localizable.
- [ ] progreso de cada paso.
- [ ] completar.
- [ ] recompensa única y entrada con mochila llena.
- [ ] guardar.
- [ ] cerrar y cargar sin repetir/perder progreso.

## Misión infectado — Computador infectado

- [ ] iniciar / desbloquear requisito.
- [ ] objetivo comprensible y NPC localizable.
- [ ] progreso de cada paso.
- [ ] completar.
- [ ] recompensa única y entrada con mochila llena.
- [ ] guardar.
- [ ] cerrar y cargar sin repetir/perder progreso.

## Misión casino — Ayuda en el casino

- [ ] iniciar / desbloquear requisito.
- [ ] objetivo comprensible y NPC localizable.
- [ ] progreso de cada paso.
- [ ] completar.
- [ ] recompensa única y entrada con mochila llena.
- [ ] guardar.
- [ ] cerrar y cargar sin repetir/perder progreso.

## Mundo, audio, UI y rendimiento

- [ ] NPC no bloquean puertas/ascensores; rutinas/poses y diálogos coherentes con piso y reloj; NPC de misión encontrables.
- [ ] Eventos: no durante boss/quiz/minijuego/cinemática/diálogo, máximo uno, espera 90–240 s posterior; únicos no se repiten al cargar.
- [ ] Pulso raro breve, sin daño; RESTORED limpia interferencias. Ningún raro es necesario para completar.
- [ ] Cola: misión antes de recompensa pendiente, deduplicación, prioridad crítica y lectura al salir de modal; no perder los cinco consejos.
- [ ] HUD legible con boss/objetivo/quickslots y daño simultáneos; 1080p, 1440p y 16:10 sin recortes.
- [ ] BAJO/MEDIO/ALTO; personajes y telegraphs siguen visibles; sin cambio inesperado de materiales.
- [ ] Ventana/sin bordes/fullscreen en ejecución independiente, cambio de monitor, guardar y reiniciar preferencias.
- [ ] Límite 30/60/120/ilimitado; medir FPS promedio y mínimos con render real en entrada, biblioteca, piso 4, pisos 6–8 y −1.
- [ ] Profiler: CPU/física/NavigationAgents/AnimationTree/LookAt y GPU luces/sombras/transparencias; 60 s por zona y durante proyectiles de boss.
- [ ] Memoria tras tres viajes completos entre pisos y 15 min de juego; no crecimiento continuo de objetos/proyectiles/avisos.
- [ ] Nueve sillas sin aproximación local: ocho en BoxesAyuda de Punto Estudiantil y una en Biblioteca/PuestosComputadores/Puesto19; IDs y coordenadas en reports/balance_1_0_data.json, chairs.local_failures. Probar ángulos alternativos; no eliminar sin revisar dependencias.
- [ ] Inventario/props/sillas recogidos no dejan colisión invisible; descender escaleras y entrar a aulas sin atasco.
- [ ] Audio: no hay banda musical/SFX externos para certificar mezcla; tonos procedurales discretos, telegraphs visibles sin audio.
- [ ] Consola sin errores de runtime; registrar warnings reales por separado de fixtures deliberadamente inválidos.

Las clases opcionales existentes y las actividades de Inglés, Lenguaje y Ética sí se prueban; ver la sesión manual de 18 pruebas al inicio. No asumir desafíos adicionales de Salud/talleres ni modos Historia/Difícil, NG+ o Boss Rush: no están implementados como contenido jugable actual. No marcar aprobados. NEXO normal sí existe desde CIERRE DE CAMPAÑA 1.0 y se prueba a continuación.

## FINAL NEXO

**PENDIENTE DE BALANCE HUMANO.** Las pruebas automáticas usan una fixture de progreso; no completan estas casillas. Cronometrar primer intento/victoria y anotar arma, mejoras, HP, Router/USB, curaciones, muertes y claridad de avisos.

- [ ] Encontrar archivo secreto: información de Proyecto NEXO correcta y legible; se puede releer en Registro.
- [ ] Nueva misión aparece: «Encuentra el núcleo de NEXO». Archivo conserva progreso/recompensa; no empieza combate.
- [ ] Acceso al núcleo: caminar a la bahía industrial este del −1; bloqueado sin progreso/credencial y autorizado al cumplirlos. Mapa muestra zona aproximada.
- [ ] Checkpoint: queda próximo al encuentro, con posición segura; guardar antes del duelo.
- [ ] Hablar con NEXO: nombre/textos y cámara legibles; no ataca al entrar o acercarse.
- [ ] Retirarse: mundo vuelve a normal, NEXO neutral, sin daño ni activación accidental.
- [ ] Iniciar duelo: Desactivar NEXO captura recursos/arma/durabilidad/quickslots/estamina y estado previo.
- [ ] Presentación: NEXO / NÚCLEO DEL SISTEMA, breve; cámara regresa sin atravesar paredes ni mover al jugador.
- [ ] Fase 1: paquete/pulso/zona reconocibles; aviso antes de daño, no saturación; distinguir zona peligrosa de suelo normal.
- [ ] Fase 2: «NEXO ESTÁ ANALIZANDO TUS DATOS», patrones simplificados con variedad y cooldown, sin todas las amenazas juntas.
- [ ] Fase 3: «SISTEMA CRÍTICO», iluminación y enlaces claros; protección parcial comprensible, no confundir HP mínimo 1 con bug.
- [ ] Terminal A: accesible caminando, E dentro de alcance y línea de visión; una sola desactivación.
- [ ] Terminal B: accesible caminando, reducción adicional de protección, sin atravesar núcleo/props.
- [ ] Terminal C: accesible caminando; después de las tres, «NÚCLEO EXPUESTO» y protección 0.
- [ ] Ataque final: Protocolo de Borrado da 2 s de aviso; zona exterior segura alcanzable; 30 de daño no se percibe como muerte instantánea.
- [ ] Muerte/reintento: NEXO · REINTENTAR restaura vida, cantidades, arma y desgaste, sin duplicar recursos; fases/enlaces/proyectiles se reinician. Probar dos derrotas seguidas y alternativa checkpoint.
- [ ] Derrotar NEXO: detiene ataques y amenazas, núcleo se apaga/controla visualmente sin desaparecer de golpe.
- [ ] Campaña completada: flag/misión/victoria se guardan antes de la secuencia; aparece NEXO DESACTIVADO / SISTEMAS RESTAURADOS.
- [ ] Estadísticas: comparar tiempo/nivel/misiones/bosses/secretos/tarjetas/apuntes/armas de escenario con registros. Porcentaje explícito sobre 102 entradas, sin sillas ni raros obligatorios.
- [ ] Créditos: ver y saltar en primera victoria; no obligatorios al cargar/revisar el núcleo.
- [ ] Continuar explorando: conservar secundarias, actividades, coleccionables y equipo; NEXO no vuelve a combatir en campaña normal.
- [ ] Campus restaurado: pantallas/luces normales, sin eventos NEXO; Director y Técnico comentan el resultado; cosmético no cambia ropa elegida.
- [ ] Guardar/cargar postgame: cerrar aplicación y volver a abrir; conservar campaign_completed, bosses.nexo, RESTORED, misión, recompensas, inventario, estadísticas y créditos vistos/omitidos.

### Variantes y regresiones humanas del final

- [ ] Vencer sin RouterPortatil ni USB: opcionales facilitan, no son requisito. Registrar tiempo y dificultad percibida.
- [ ] Router en mochila: no se consume y protección total baja de 54% a 36%; siguen siendo necesarios los tres enlaces.
- [ ] USB: consumo correcto, 60 antes de escudo y stun 2 s contra NEXO; no altera efecto previo contra Director.
- [ ] Cerrar durante intro/combate/muerte pendiente: al cargar, recursos y mundo previos coherentes, núcleo neutral y ningún premio duplicado.
- [ ] Cargar partida antigua con archivo ya completado: conserva todo, activa final pendiente; si faltaba CredencialDirector pese a victoria legítima se recupera, sin regalar XP/créditos.
- [ ] Sillas resueltas: caminar a los ocho casos de BoxesAyuda y Puesto19; recoger desde un lado/diagonal sin atravesar escritorio. IDs/puntos en reports/closure_chairs.json.
- [ ] Legibilidad con HUD real y cámara en 1080p/1440p, especialmente avisos de enlace/borrado y rótulos cerca de cámara.
- [ ] Rendimiento gráfico durante fase 3, proyectiles y zonas; medir FPS/mínimos sin extrapolar del headless.
- [ ] Menú principal y revisión de resultados/créditos desde el acceso/núcleo restaurado funcionan; no muestran Boss Rush/NG+ inexistentes.
- [ ] Registrar PACING ISSUE si trayecto, fases, terminales, diálogos o créditos se sienten largos, repetitivos o confusos. No declarar equilibrio por ausencia de errores.

## Correcciones de actividades, guardado y Chef — 16-10-2026

Esta actualización reemplaza los valores y actividades anteriores que se conservan como registro histórico.

- FIX: Actividades por piso. pc4 (game_id 2): organización docente; pc5 (0): vocabulario de Inglés; pc6 (2): comprensión lectora de Lenguaje; pc7 (1): decisiones de Ética; pc8 (2): revisión documental NEXO. Reutilizan la clasificación existente, su señal completed y el circuito finished(success). No se renumeran game_id, campaign_id, quest_id ni eventos computer:ID. pc_intro, pc3 y pc_secreto conservan sus juegos. Director permanece en piso 8.
- FIX: Apuntes. Apunte_datos pasa de piso 4 a 3, Apunte_redes de 6 a 3 y Apunte_ia de 8 a 3. Apunte_programacion ya estaba en 3. Se conservan world_id, item_id hoja_impresa, textos y flags collected; no se duplican.
- FIX: Error de autoguardado. Se comprueban apertura, escritura/flush, copia .bak y reemplazo .tmp → definitivo. Un fallo no marca éxito ni borra original/backup/temporal recuperable. Consola registra ruta y error; jugador recibe «No se pudo guardar la partida.» una sola vez por racha de fallos. Tras guardar correctamente se habilita un nuevo aviso. Nueva partida reutiliza el mismo escritor.
- FIX: WorldItem parcial. Se descuenta solo la cantidad aceptada; el sobrante permanece visible/interactivo y muestra xN. Solo al agotarse se marca collected y se emiten eventos de recogida especial/apunte. El JSON añade remaining_quantity[world_id]; collected sigue siendo booleano. Saves antiguos sin cantidad usan el valor original, salvo collected=true. Respawn explícito mantiene su comportamiento. Save_version sigue en 2 y el snapshot previo al boss incluye el nuevo diccionario.
- BALANCE: Chef Supremo HP reducido de 450 a 350, tanto actor como BossDuelController de Main.tscn. Tres fases conservadas a 60% y 30% (210/105 con el nuevo máximo). No cambian daño, velocidad, ataques, bandejas, cooldowns, recompensas, economía, XP, precios ni otros bosses.

Validación nueva: tests/CampusFixesCheck.tscn y tests/campus_fixes.gd. Reporte de ejecución: reports/campus_fixes_result.json. Incluye inventario real lleno, 5 → acepta 2 → quedan 3, guardar/cargar campaña real, recoger sobrante, saves antiguos, claves, IDs/señales de los cinco perfiles, desbloqueos 7/8, apuntes, HUD/fases/reset Chef y fallo de reemplazo inyectado. Los errores de consola provocados expresamente por el test de guardado son esperados.

PENDIENTE DE PRUEBA MANUAL:

- [ ] Recorrer los pisos 3–8; comprobar accesibilidad de apuntes y lectura de actividades a distintas resoluciones.
- [ ] Completar la ruta de campaña jugando cada actividad; verificar ascensores y puertas con una partida personal respaldada.
- [ ] Chef: comprobar HUD 350/350, morir/reintentar y continuar una partida anterior; evaluar dificultad humana manteniendo el resto del balance.
- [ ] Probar aviso discreto ante un fallo real de disco/permisos y recuperación; la inyección automática no simula un corte de energía.
- [ ] Recoger parcialmente un lote en juego, salir/reabrir y recoger el resto tras liberar espacio.

Los resultados automáticos concretos y sus límites se registran a continuación; las casillas manuales permanecen pendientes.

Resultado automático verificado (16-10-2026): nueva fixture ejecutada mediante godot-mcp-toolkit: 73 comprobaciones, cero fallos (reports/campus_fixes_result.json). Regresiones aprobadas con resultados finales sin fallos en los logs: campaña, inventario, gameplay, Chef 350 HP, balance (20), lector de guardado, nueva partida, NEXO (111) y organización (9 pisos/596 rutas de nodos). Revisión de carga: 227 scripts/recursos. Los logs son tests/fixes_*.log (ignorados por Git); no se confunde la salida temprana del ejecutable gráfico con éxito: se comprobaron los marcadores de resultado de cada archivo.

FIX visual adicional demostrado con captura MCP: la capa de minijuegos (antes 20) quedaba debajo del HUD de inventario (26) y campaña (40). Ahora es 50; las opciones quedan delante del HUD. Se inspeccionaron Lenguaje y NEXO con renderizado. No altera estadísticas ni mecánicas. Las pruebas humanas completas y otras resoluciones siguen pendientes.


## PERSONAJES Y BOSSES SUPERIORES — sesión manual

Todo pendiente. Marcar PASS o FAIL solo después de jugar; ambas vacías = no ejecutado. Registrar versión, equipo, resolución, tiempo, arma, mejoras y muertes. Usar copia de partida. Los HP nuevos siguen PENDIENTES DE PLAYTEST HUMANO. No confundir fallback procedural con animación humana importada.

### PERSONAJES

**Protagonista visual correcto** — Silueta de estudiante, altura compatible, ropa elegida conservada y cápsula sin cambios.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________

**Caminar/correr** — Arranque, mezcla y parada suaves sin retrasar controles.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________

**Agacharse** — CROUCH/CROUCH_WALK, techo bajo y arma sin clipping grave.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________

**Saltar** — Salto, caída y aterrizaje; no desplazamiento por root motion.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________

**Escaleras** — Subir/bajar escaleras principales/emergencia y entrar a puertas.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________

**Armas en mano** — Socket sigue la mano; poses ligera/media/pesada/lanzable; golpe/daño/desgaste originales.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________

**Mochila** — Pegada a espalda, color elegido y balanceo sutil, sin flotar ni clipping fuerte.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________

**Personalización** — Prendas/pantalón/calzado/cabellos/colores/accesorios; preview, rotar, zoom, equipar, quitar y cancelar.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________

**Guardar/cargar apariencia** — Misma ropa/cabello/colores/mochila/accesorios tras cerrar y continuar; premios no autoequipados.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________

**NPC diferentes** — Identidad estable por ID tras cargar; evitar clones y comprobar LOD en otro piso.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________

**Profesores diferentes** — Inglés con tablet/audífonos, Lenguaje con libro, Ética sobria y Director formal con dispositivo.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________

**NPC sentados** — Asientos existentes, manos/props, levantarse y conservar interacción.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________

**Diálogo/cámara** — Mirada mutua limitada, nombre/texto y gestos; cámara cercana solo en diálogos importantes y retorno sin atravesar paredes.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________

### PISO 5 — Inglés

**Neutral** — No ataca ni recibe daño antes de aceptar; pose de trabajo y aspecto reconocibles.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________

**Diálogo** — E muestra nombre y opciones Iniciar duelo/Ahora no, mirada y cámara correctas.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________

**Ahora no** — Cierra conversación; no ataques, daño, bloqueo de controles ni snapshot consumido.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________

**Duelo** — Intro/nombre/HUD 450/450; arena transitable con cámara, paredes y salidas. Morir y reintentar desde UI restaura vida/arma/durabilidad/consumibles/quickslots.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________

**Fases** — SECOND PART/FINAL EXAM a 270/135 HP; Word Shot/Listen/Speak/Rush/Storm con huecos y cooldowns.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________

**Computador** — pc5: vocabulario de Inglés; game_id 0. Sigue completando/guardando su flag; no sustituye el boss por preguntas.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________

**Ventaja** — ENGLISH_PREPARED: Word Rush deja 2 s más de pausa. El duelo también se puede iniciar y ganar sin computador.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________

**Victoria** — Cuerpo/caída permanecen, amenazas limpias, curación, misión/piso desbloqueado, civiles restaurados y estado derrotado al cargar.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________

**Recompensa** — AuricularesLinguisticos y AudifonosAcademicos desbloqueados, sin autoequipar.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________

### PISO 6 — Lenguaje

**Neutral** — No ataca ni recibe daño antes de aceptar; pose de trabajo y aspecto reconocibles.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________

**Diálogo** — E muestra nombre y opciones Iniciar duelo/Ahora no, mirada y cámara correctas.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________

**Ahora no** — Cierra conversación; no ataques, daño, bloqueo de controles ni snapshot consumido.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________

**Duelo** — Intro/nombre/HUD 500/500; arena transitable con cámara, paredes y salidas. Morir y reintentar desde UI restaura vida/arma/durabilidad/consumibles/quickslots.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________

**Fases** — Fases a 300/150 HP; hojas/libro/páginas, tinta y línea editorial anunciados.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________

**Computador** — pc6: comprensión lectora; game_id 2. Sigue completando/guardando su flag; no sustituye el boss por preguntas.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________

**Ventaja** — LECTURA_PREPARADA: tinta 2 s/ralentización menor; comparar sin preparación. El duelo también se puede iniciar y ganar sin computador.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________

**Victoria** — Cuerpo/caída permanecen, amenazas limpias, curación, misión/piso desbloqueado, civiles restaurados y estado derrotado al cargar.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________

**Recompensa** — CuadernoDelEscritor y bolso cosmético, sin autoequipar.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________

### PISO 7 — Ética

**Neutral** — No ataca ni recibe daño antes de aceptar; pose de trabajo y aspecto reconocibles.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________

**Diálogo** — E muestra nombre y opciones Iniciar duelo/Ahora no, mirada y cámara correctas.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________

**Ahora no** — Cierra conversación; no ataques, daño, bloqueo de controles ni snapshot consumido.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________

**Duelo** — Intro/nombre/HUD 550/550; arena transitable con cámara, paredes y salidas. Morir y reintentar desde UI restaura vida/arma/durabilidad/consumibles/quickslots.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________

**Fases** — Fases a 330/165 HP; Presión/Duda/Dilema; elegir A/B caminando, sin quiz ni opción correcta; efectos solo dentro del duelo.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________

**Computador** — pc7: decisiones de Ética; game_id 1; TarjetaAcceso sigue siendo necesaria para la puerta. Sigue completando/guardando su flag; no sustituye el boss por preguntas.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________

**Ventaja** — REFLEXION_PREVIA: 10 s para elegir en vez de 6; no exige acertar. El duelo también se puede iniciar y ganar sin computador.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________

**Victoria** — Cuerpo/caída permanecen, amenazas limpias, curación, misión/piso desbloqueado, civiles restaurados y estado derrotado al cargar.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________

**Recompensa** — InsigniaIntegridad y cosmético visible desbloqueados, sin autoequipar.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________

### PISO 8 — Director

**Neutral** — No ataca ni recibe daño antes de aceptar; pose de trabajo y aspecto reconocibles.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________

**Diálogo** — E muestra nombre y opciones Iniciar duelo/Ahora no, mirada y cámara correctas.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________

**Ahora no** — Cierra conversación; no ataques, daño, bloqueo de controles ni snapshot consumido.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________

**Duelo** — Intro/nombre/HUD 700/700; arena transitable con cámara, paredes y salidas. Morir y reintentar desde UI restaura vida/arma/durabilidad/consumibles/quickslots.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________

**Fases** — Fases a 420/210 HP; máximo 2 virus, FIREWALL/ACCESO DENEGADO anunciados, Modo Administrador y Pantallazo Azul conservados.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________

**Computador** — pc8: revisión documental NEXO; game_id 2. Sigue completando/guardando su flag; no sustituye el boss por preguntas.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________

**Ventaja** — NEXO_INFORMATION: virus invocados con 40 HP frente a 50 sin preparar; USBInfectado sigue funcionando. El duelo también se puede iniciar y ganar sin computador.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________

**Victoria** — Cuerpo/caída permanecen, amenazas limpias, curación, misión/piso desbloqueado, civiles restaurados y estado derrotado al cargar.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________

**Recompensa** — CredencialDirector y TecladoAdministrador originales, dispositivo cosmético opcional, sin duplicados.

- [ ] PASS
- [ ] FAIL

Observaciones: ____________________________________________________

**Compatibilidad y rendimiento:** probar una partida antigua con etapas/pisos ya completados: no se reabren ni se pierden desbloqueos; los nuevos profesores pendientes siguen disponibles. Medir FPS estables, mínimos, memoria y claridad de telegraphs en cada arena y otro piso. Una muestra durante carga no es un benchmark jugable.

## OPTIMIZACIÓN + PERSONAJES REALISTAS 3.0

PENDIENTE DE PRUEBA MANUAL. Registrar hardware, resolución, calidad, FPS aproximado estable y caídas; no usar FPS de carga como rendimiento jugable.

Hardware / resolución / calidad: __________________________________

**Piso 1**

- [ ] PASS
- [ ] FAIL

FPS aproximado / mínimo: __________  Observaciones: __________________________

**Piso 2**

- [ ] PASS
- [ ] FAIL

FPS aproximado / mínimo: __________  Observaciones: __________________________

**Piso 3**

- [ ] PASS
- [ ] FAIL

FPS aproximado / mínimo: __________  Observaciones: __________________________

**Piso 4**

- [ ] PASS
- [ ] FAIL

FPS aproximado / mínimo: __________  Observaciones: __________________________

**Piso 5 Boss: Vocabulary Storm**

- [ ] PASS
- [ ] FAIL

FPS aproximado / mínimo: __________  Observaciones: __________________________

**Piso 6 Boss: Tormenta de Páginas + tinta**

- [ ] PASS
- [ ] FAIL

FPS aproximado / mínimo: __________  Observaciones: __________________________

**Piso 7 Boss: zonas A/B y Dilema**

- [ ] PASS
- [ ] FAIL

FPS aproximado / mínimo: __________  Observaciones: __________________________

**Piso 8 Director: Firewall + Acceso Denegado + 2 virus**

- [ ] PASS
- [ ] FAIL

FPS aproximado / mínimo: __________  Observaciones: __________________________

**Subterráneo -1**

- [ ] PASS
- [ ] FAIL

FPS aproximado / mínimo: __________  Observaciones: __________________________

**Protagonista**

- [ ] PASS
- [ ] FAIL

FPS aproximado / mínimo: __________  Observaciones: __________________________

**Estudiantes**

- [ ] PASS
- [ ] FAIL

FPS aproximado / mínimo: __________  Observaciones: __________________________

**Profesores**

- [ ] PASS
- [ ] FAIL

FPS aproximado / mínimo: __________  Observaciones: __________________________

**Salud en sector norte Piso 4**

- [ ] PASS
- [ ] FAIL

FPS aproximado / mínimo: __________  Observaciones: __________________________

**Talleres en -1**

- [ ] PASS
- [ ] FAIL

FPS aproximado / mínimo: __________  Observaciones: __________________________

**Bosses reconocibles**

- [ ] PASS
- [ ] FAIL

FPS aproximado / mínimo: __________  Observaciones: __________________________

**Ropa y colores guardados**

- [ ] PASS
- [ ] FAIL

FPS aproximado / mínimo: __________  Observaciones: __________________________

**Cabello**

- [ ] PASS
- [ ] FAIL

FPS aproximado / mínimo: __________  Observaciones: __________________________

**Mochila**

- [ ] PASS
- [ ] FAIL

FPS aproximado / mínimo: __________  Observaciones: __________________________

**Armas y sockets**

- [ ] PASS
- [ ] FAIL

FPS aproximado / mínimo: __________  Observaciones: __________________________

**Cámara y escaleras**

- [ ] PASS
- [ ] FAIL

FPS aproximado / mínimo: __________  Observaciones: __________________________

**Diálogo y regreso de cámara**

- [ ] PASS
- [ ] FAIL

FPS aproximado / mínimo: __________  Observaciones: __________________________

**LOD: alejarse y volver / viajar entre pisos**

- [ ] PASS
- [ ] FAIL

FPS aproximado / mínimo: __________  Observaciones: __________________________

**Calidad ALTO / MEDIO / BAJO y sombras cercanas**

- [ ] PASS
- [ ] FAIL

FPS aproximado / mínimo: __________  Observaciones: __________________________

**Ruta física Piso 1 -> Piso 8 -> -1 sin perder interacción**

- [ ] PASS
- [ ] FAIL

FPS aproximado / mínimo: __________  Observaciones: __________________________
