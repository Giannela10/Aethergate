# Vida estudiantil — fase 1: horario y asistencia

Esta entrega añade horario/asistencia al celular y guardado existentes.
No reemplaza campaña, misiones, NPC, personalización, combate ni inventario.
Las clases interactivas, reputación, conducta y fases posteriores siguen pendientes.

## Uso

P → Horario. La pantalla muestra LUNES, jornada, hora y asistencia.
Cada jornada repite este horario; no es obligatorio simular una semana:

| Hora | Materia | Lugar |
| --- | --- | --- |
| 09:00–09:30 | Programación | Sala 303, piso 3 |
| 11:00–11:30 | Redes | Punto de laboratorio académico compartido en Sala 303, piso 3 |
| 14:00–14:30 | Inglés | Punto académico del piso 5 |

No se construyó un laboratorio ni una sala nueva. Los dos puntos son nodos
sin colisión con un rótulo, en (39.4, 24.068, -128) y (-20, 48.125, -140).
E permite consultar la clase desde ellos. La distribución temática se conserva.

ASISTIR solo funciona durante los 30 minutos de la clase, a menos de tres metros
del punto y con alcance libre. No permite asistir desde otro piso o atravesando
paredes. IGNORAR AVISO descarta el recordatorio; es posible cambiar de opinión
y asistir mientras la clase esté abierta. No se interrumpe el combate.

## Hora y compatibilidad con otros relojes

En la carpeta auditada no se encontró un módulo de hora del campus. Se reutiliza
`data.stats.time_played`, ya guardado por la campaña, como referencia: 10 segundos
jugados por minuto académico y comienzo a las 08:50. No se usa fecha de Internet
ni tiempo con el juego cerrado. Pausar el juego detiene esa referencia como antes.
Las partidas antiguas comienzan el horario al instalar esta función; no acumulan
faltas retroactivas por las horas jugadas anteriormente.

El adaptador admite un reloj externo sin sustituirlo:

```gdscript
campaign.academics.time_provider = func():
    return {"day": reloj.dia, "minute": reloj.minutos_desde_medianoche}
```

El proveedor debe respetar las pausas de su reloj. Retrocederlo no borra faltas ni
permite registrar asistencia anterior al progreso ya contabilizado. La referencia
actual no implementa cambios de iluminación ni rutinas horarias de NPC.

## Asistencia y recompensas

Cada clase/jornada permite un registro. Al terminar su horario, si no se asistió,
se cuenta una falta una sola vez. El porcentaje es asistidas / (asistidas + perdidas).
Las clases futuras no reducen el porcentaje; sin registros se indica así.

Faltar no bloquea misiones, ascensores ni final de campaña. La primera asistencia
a cada materia entrega 25 XP y 10 créditos mediante `grant_reward` existente.
En jornadas siguientes la misma materia registra asistencia pero no vuelve a dar
ese premio. No hay objetos únicos ni recompensas infinitas.

Esta fase registra presencia; no simula una clase interactiva ni entrega notas.
No se encontró un sistema global de calificaciones en esta copia, por lo que no
se creó uno paralelo ni se presentan notas ficticias como resultados del jugador.

## Avisos

Hay un recordatorio por clase/jornada dentro de los diez minutos anteriores.
Se muestra sin abrir ventanas, con acceso P → Horario. Espera si hay combate
cercano, duelo, minijuego, ventana o aviso visible. Si ya pasó el inicio al poder
mostrarlo, no enseña un mensaje antiguo diciendo que aún faltan diez minutos.
Ignorar o asistir elimina el aviso pendiente de esa materia.

## Archivos y guardado

Nuevos: `scripts/campaign/academic_schedule.gd`,
`scripts/campaign/academic_class_point.gd`, `tests/academic_schedule.gd`.
Modificados: `campus_campaign.gd`, `student_phone.gd`, `phone_view.gd`,
`tests/student_phone.gd` y `tests/nueva_partida.gd`.

La app reutiliza la carcasa del teléfono, con nueve iconos en tres columnas.
La hora también aparece en la tarjeta principal del teléfono.
Nodo de ejecución `CampusCampaign/HorarioAcademico` y dos puntos de clase.
No cambia Main.tscn ni la geometría.

Campo aditivo `academics` en el mismo JSON y versión de campaña: origen de la
referencia, último minuto revisado, contadores, registros y recordatorios.
Nueva Partida reinicia esos campos. Se conservan los contadores históricos y se
recortan registros antiguos para no acumular una lista indefinida. La comprobación
se hace como máximo una vez por segundo; no se añade procesamiento a cada NPC.

## Pruebas

`tests/academic_schedule.gd`: 27 comprobaciones sin fallos, incluyendo hora inicial y ubicación
real accesible de Sala 303 y selección con E en ambos puntos, horario, duplicados, asistencia/faltas, nueva jornada,
recompensas limitadas, app, inventario y archivo de guardado temporal aislado.
Log `tests/academic_schedule.log`.
Pasaron también regresión de campaña, 31 comprobaciones del celular, Nueva
Partida y carga de 185 recursos propios en `tests/academic_phase1_*.log`.
Se revisó visualmente el teléfono con sus nueve aplicaciones mediante MCP.

Manual: abrir P → Horario; revisar materias y porcentaje, usar E en un punto,
intentar asistir antes de hora y desde lejos, asistir presencialmente, ignorar
otra clase y dejar pasar su fin, guardar/recargar y comprobar contadores.
En una partida de prueba, verificar que Nueva Partida reinicia la asistencia.

## Alcance pendiente

Fases 2–12: clases interactivas, calificaciones/evaluaciones, reputación/beneficios,
conducta/guardia/guardar arma, deportes, investigación, historias/acompañantes,
eventos, talleres, nuevas actividades académicas, diario, logros y trofeos.
No se añadieron minijuegos, misterios ni historias de NPC en esta fase.
