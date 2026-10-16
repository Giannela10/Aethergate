# BALANCE REPORT 1.0

**Estado actual, 16-10-2026:** CIERRE DE CAMPAÑA 1.0 añade NEXO normal y una misión principal final. Las conclusiones fechadas 15-10 son el diagnóstico previo. NEXO está **PENDIENTE DE BALANCE HUMANO**; no se rebalancearon los elementos anteriores. Ver actualización de cierre al final y [CIERRE_CAMPANA_1_0.md](CIERRE_CAMPANA_1_0.md).

## RESUMEN EJECUTIVO

Auditoría de datos y pruebas automáticas, 2026-10-15, con godot-mcp-toolkit y Godot 4.7.2. Se conservan edificio y contenido. Hay 15 misiones, cinco bosses, 23 armas de catálogo, 51 pickups de arma, 779 sillas y 12 centros de vida. No se hicieron partidas humanas ni se enviaron datos a internet.

Duración provisional: principal 1–2,5 h; principal + secundarias 2–4 h; contenido disponible completo 3–6 h; postgame abierto. Son estimaciones por componentes, pendientes de cronometraje. No se fuerza 5–8 h añadiendo vida o esperas. El cierre real es archivo_subterraneo; no existe boss final NEXO.

## CRITICAL ISSUES

**B01 corregido:** aceptar documentos con mochila llena marcaba provided aunque receive_item fallara. Se reutiliza la entrega garantizada de recompensas. Al volver al Profesor también se recupera una clave inicial pendiente de una partida antigua, sin duplicarla. Es necesaria para TarjetaAcceso.

No se certifica ausencia universal de softlocks: la conectividad física de puertas, escaleras, ascensores y aulas necesita recorrido manual. QA de IDs/referencias dio cero errores; no sustituye navegación real.

## HIGH ISSUES

- **B02 corregido:** objetivos de boss reconocen data.bosses aunque falte su evento redundante en guardado antiguo.
- **B03 corregido:** lotes respetan capacidad; stacks llenos no crean entradas adicionales ni devuelven éxito; add_item devuelve cantidad añadida, no total poseído. Evita cobrar o consumir fuentes por un falso éxito.
- **B04 corregido:** guardar/cerrar durante intro/combate o muerte pendiente escribe estado coherente previo al duelo, incluidos mundo/progreso e inventario; al continuar el boss está neutral. Se informa antes de aceptar. Elegir checkpoint abandona snapshot para no afectar guardados futuros. Victoria conserva recompensas actuales y su ledger.
- **Abierto:** mínimos ofensivos teóricos de bosses muy cortos frente a los objetivos de diseño; medir primera victoria y porcentaje de tiempo golpeando antes de modificar HP/daño.
- **Abierto:** NEXO final y varios modos/bosses citados por el encargo no existen en el contenido actual. No se crean en esta etapa.

## ARMAS

Tabla completa de las 23 instancias en BALANCE_1_0.md y datos en reports/balance_1_0_data.json. **Sin cambios de daño, velocidad, durabilidad ni rareza.** Silla 34/0,75 s/4 impactos; Palo 22/0,6 s/14. Se mantienen sillas divertidas y frágiles: oferta abundante pero sin venta, sin conversión a créditos infinitos. 770/779 pasan aproximación local y raycast; falta demostrar rutas desde spawn.

Clases/peso/coste por tipo no están implementados como atributos; no se inventan. Las únicas tienen durabilidad/velocidad/bonus útiles. Cable y compra de Silla por 25 son candidatos de revisión, sin borrarlos o igualarlos. No existe taller de reparación/mejora de arma que balancear.

## ENEMIGOS

Nueve encuentros normales, HP reales 54,6–238, daño 6–21. Tabla TTK por arma en auditoría. Las armas comunes no eliminan de un golpe todos los roles. Especiales sí pueden eliminar rápidos anteriores; no se normaliza esa diferencia. Salto rápido del 3 → pesado del 4 pendiente de sensación. **Sin cambios de estadísticas ni densidad.**

## BOSSES

Revisados Punto, Chef, Bibliotecaria, Redes y Director. Chef 450 HP, Redes 550, Director 700, Punto 200; Bibliotecaria 125 y cinco aciertos de 25. Se conservan estadísticas, fases y cooldowns. La modificación común es la política de guardado/reintento y su explicación, no nuevas mecánicas.

Redes conserva reducción hasta 70% con tres routers; desconexión instantánea, reconexión única en fase 2; pulso 7 s, interferencia 8 s, conexión 9 s y aviso 1,2 s. Director invoca dos virus una vez; USB causa 80 daño y stun 3 s, ventaja sin eliminar 700 HP. No hay Profesor de Programación ni boss final NEXO para validar. El quiz se prueba como quiz, sin inflar vida física.

## ECONOMÍA

Principal analítica: 1165 créditos antes de gastos, incluyendo documentos, cuatro bosses, siete PCs y archivo. Cinco ramas de mejoras completas cuestan 3500; no se compra todo con principal sola. Precios y recompensas **sin cambios**. Eventos tienen presupuesto total 24. Recompensas son idempotentes; venta no existe. Farming por recargar enemigos normales sigue posible: medir rentabilidad, no eliminar todo respawn automáticamente.

## XP

Principal analítica sin enemigos: 2015 XP, nivel 14. 150 XP por nivel; salud +5 por nivel, Fuerza solo mediante mejora (máximo +25%). Principal + coleccionables/secundarias/clases/Redes, sin farming/eventos: ~3080 XP, nivel 21; con nueve enemigos normales ~3170, nivel 22. Son sumas de fuentes, no telemetría de una partida. **Sin cambios de XP o curva.**

## CURACIÓN

Bebida 10 HP/5 créditos; Comida 30/10; Botiquín 50/25; Colación vida completa; energética +35% por 12 s. Stack 999, sin cooldown de consumo. Cada PC completado cura 25 HP una vez. Centros y victorias curan completo; centros bloqueados en duelos. **Sin cambios de consumibles ni precios.** Curación abundante y abuso junto a enemigos fuera de duelo: MEDIUM pendiente de playtest.

## MISIONES

Nueve principales y seis secundarias; documentos es obligatoria por dependencia pese a etiqueta secundaria. Se corrige entrega y compatibilidad de derrota; no se eliminan, trasladan ni reordenan misiones. Ruta exacta y tabla por misión en auditoría; checklist individual en PLAYTEST_1_0.md.

PACING ISSUE: repetición computador/subir en 3–7, vuelta por documentos si se ignora Profesor, recorrido inicial largo, densidad de HUD y falta de clímax final NEXO. No se añaden misiones para rellenar duración.

## MINIJUEGOS

Archivos 6–8 decisiones, Antivirus 8–12 aciertos/máximo dos virus, contraseña 4–5 dígitos. Clases actuales opcionales de Programación/Redes/Inglés; horario 10 s reales por minuto, sin bloqueo por faltar. Parámetros conservados. Tiempo/dificultad humana y accesibilidad de memoria/reacción pendientes.

## UI Y TUTORIAL

B05: cola máxima 16, deduplicación, prioridades CRITICAL/MISSION/REWARD/INFO; crítico interrumpe conservando aviso pendiente. Los avisos esperan mientras modal/intro ocultan el HUD. API notify anterior compatible. B07: tutorial espera a oportunidad sin modal, duelo o avisos pendientes. No se añade otro sistema de tutorial.

## RENDIMIENTO

B06: filtro de piso antes de métodos contextuales y distancia al cuadrado antes de raycast. 100 consultas en spawn: media 2001,69 → 605,51 µs (~70% en esa muestra); frecuencia 0,08 s conservada y 60 comprobaciones contextuales aprobadas. No es una mejora medida de FPS global.

Headless: 5577 ms hasta frame 120, 368,11 MiB de memoria estática, 44631 nodos, 15844 recursos. No mide GPU/VRAM ni rendimiento con render. Benchmark ahora evita leer/escribir partida del usuario. No se reestructura Main ni se implementa streaming. Medir pisos/render antes de proponer separación de escenas.

## GUARDADO

save_version=2 y migración existentes conservados; no nuevo formato incompatible. Pruebas: JSON real en fixture de duelo, estado del mundo consistente con inventario, checkpoint/snapshot, recompensas únicas, nueva partida, versiones futuras y lector con respaldo de JSON inválido. La regresión de campaña incluye cierre de escena y carga real. Cierre de aplicación con ventanas/render debe comprobarse manualmente.

La telemetría permanece opt-in, local, limitada; no hay tiempos de campaña o muertes humanos inventados. Los fixtures no escriben la partida del usuario.

## VALIDACIÓN

Antes de corregir B01–B03: cuatro reproducciones fallaron; después pasan. Suite nueva final: 20/20. También pasan gameplay_regression, inventory_regression, campaign_regression, Chef, Director, Redes 38, horario 27, celular 31, campus 52, Personajes 2.0 59, interacciones 60, nueva partida, lector de guardado y revisión de 219 scripts/recursos. Registros balance-*.log en .godot. Arranques MCP sin errores de runtime observados; dos avisos del modo embebido impiden mover/redimensionar ventana, revisar ejecución independiente. Warnings de JSON corrupto en el test del lector son deliberados.

## RECOMENDACIONES

1. Seguir PLAYTEST_1_0.md de inicio a archivo final y registrar tiempos por tramo/boss; NEXO no puede marcarse aprobado.
2. Priorizar duración real de bosses, abuso de centros fuera de duelo y recorrido 3→5; ajustar solo con esas mediciones.
3. Medir FPS y profiler por piso, 1080p/1440p, modos de ventana y tres presets; no deducir FPS desde headless.
4. Revisar las nueve sillas sin candidato local y todas las rutas de acceso; no hacerlas decorativas automáticamente.
5. Diseñar futuro cierre NEXO fuera de esta etapa, conservando las dependencias actuales. No añadir horas artificiales mediante HP, espera o backtracking.

## CIERRE DE CAMPAÑA 1.0 — actualización 16-10-2026

La recomendación de crear el final se implementó en esta nueva etapa autorizada: archivo intermedio, misión nexo_final, acceso y arena en una bahía existente del este de −1, boss NEXO no humano, tres fases, tres terminales, victoria/créditos/estadísticas y postgame restaurado. No se añadieron los modos/bosses ausentes ni se reconstruyó el edificio.

Las nueve sillas no tenían IDs faltantes: la muestra a 0,9 m chocaba con asientos/respaldo o escritorios. La validación ampliada pasa 779/779 y la suite recoge los nueve casos reales sin duplicación. No se cambió mobiliario ni ID.

**NEXO: 1200 HP iniciales, PENDIENTE DE BALANCE HUMANO.** Fases 70%/35%, protección parcial por tres enlaces y obligación de desactivarlos; Protocolo de Borrado con aviso 2 s y 30 daño, no muerte instantánea. RouterPortatil y USB reales facilitan el encuentro sin ser obligatorios. Configuración completa y razones en BALANCE_1_0.md y [CIERRE_CAMPANA_1_0.md](CIERRE_CAMPANA_1_0.md).

Se conserva BossRetry, la política de guardado pre-duelo, rewards/ledger y migración de save_version 2. El final guarda campaign_completed, bosses.nexo y misión antes de la secuencia; al cargar NEXO permanece derrotado. Partidas antiguas conservan archivo/recompensas/cosméticos y reciben una principal final pendiente, sin restaurar el campus prematuramente.

Se compararon reportes antes/después: idénticos valores de las 23 armas, consumibles, nueve enemigos, HP de los cinco bosses anteriores y precios. XP, estadísticas y recompensas anteriores no se rebalancearon. El nuevo boss usa los 75 créditos/150 XP estándar; su misión no duplica recompensa.

Pruebas aprobadas: suite NEXO 111; balance 20; campus 52; Personajes 2.0 59; interacciones 60; Redes 38; horario 27; celular 31; además campaña con carga real, inventario, gameplay, Chef, Director, nueva partida y lectura/migración de guardado. Revisión 226 scripts/recursos. Capturas con toolkit confirmaron presentación básica/diálogo/barra/fase 3 en una fixture aislada, sin afirmar victoria humana o balance.

Pendientes: ruta física desde archivo, visibilidad con HUD/cámara, velocidad de lectura/reacción, seguridad de terminales, primera victoria, dificultad sin opcionales, rendimiento gráfico, créditos y cierre/reapertura reales. La duración anterior de campaña no incluye este final nuevo; cronometraje pendiente. Checklist **FINAL NEXO** en PLAYTEST_1_0.md.
