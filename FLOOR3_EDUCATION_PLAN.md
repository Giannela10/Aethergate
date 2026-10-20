# Piso 3 · plan educativo (sin construcción)

La temática vinculante es Informática y Telecomunicaciones. No se infiere otra
facultad por nombres históricos de nodos ni por el local existente.

## Auditoría de ubicación

Piso3 está en altura 23.9677. Main conserva Losas/Estructura, pasillos,
vestíbulo y puertas de tres ascensores, escalera central y emergencia. Existe
`EncuentroProfesorRedes` en el ala oriental. El runtime añade docentes de Datos
y Algoritmos con semillas de colocación en torno a X=-45/Z=-137 y
X=30/Z=-130, y busca posiciones transitables. No debe tomarse una semilla como
posición final garantizada.

`SalaDetrasLocal` tiene una sala numerada actualmente 303: su generador sitúa
el centro X=39.4/Z=-122.05 y una planta aproximada de 13.4 × 23.9 m, entre
muros X=32.5 y 46.3. También cierra el paso junto a ella. `LocalComidaReferencia`
incluye comedor, mostrador y decoración de referencia; conservarlo hasta medir
su función y recorridos. El 303 actual no debe renumerarse automáticamente.

## Propuesta de reservas

Son tamaños objetivo y zonas candidatas, **no un levantamiento que garantice
cabida**. Medir colisiones, huecos de escaleras y ventanas en editor antes de
construir. Dejar pasillos accesibles y salidas independientes del desafío.

| Espacio | Dimensión útil objetivo | Zona candidata y condicionantes |
|---|---|---|
| 301 Programación | 12 × 10 m | Ala este; revisar arena/semillas de Algoritmos y computadores existentes |
| 302 Bases de Datos | 12 × 10 m | Ala oeste; revisar arena de Datos y objetos de misión |
| 303 Redes y Telecomunicaciones | 13.4 × 23.9 m existentes | Evaluar adaptar SalaDetrasLocal; conservar mampara y cierre contiguo; revisar encuentro de Redes |
| 304 Ciberseguridad | 10 × 9 m | Reserva oeste contigua a laboratorios; validar estructura y luz libre |
| 305 Hardware y Soporte | 10 × 9 m | Reserva este fuera del comedor y evacuación; prever mesas/taller liviano |
| 306 Laboratorio General | 12 × 10 m | Reserva lateral tras medir ocupación de ambas alas |
| Servidor / Data Room | 4 × 5 m | Contiguo a Redes, lejos de rutas de emergencia; acceso supervisado |

No se fijan coordenadas de las cinco salas aún no medidas. El siguiente diseño
debe incluir mapa con AABB y pruebas de cápsula, no duplicar cajas sobre muros.

## Dependencias que deben conservarse

- `pc3`: actividad Antivirus, misión academico3 e infectado, USBInfectado y fase
  narrativa de CampusState. No cambiar ID ni eventos computer:pc3.
- Datos/Algoritmos: requisito academic_any del Piso 3, recompensas LlaveDeDatos
  y DepuradorPortatil y contactos. Conservar IDs de bosses y guardado durante
  la futura migración aunque cambie el personaje que recibe daño.
- Redes: routers, interferencias, minions, zona de duelo y recompensa; separar
  mentor de enemigos sin romper su controlador actual.
- Los objetos recogibles usan world_id y posiciones; moverlos requiere validar
  recogidos/remaining_quantity en saves antiguos. No regenerar IDs.
- Ascensores: autorización argumental existente y guardia educativa adicional.
  Escaleras centrales/emergencia y sus huecos son rutas estructurales.
- LocalComidaReferencia/SalaDetrasLocal: comprobar local_piso3_recorridos y las
  puertas actuales antes de desplazar mobiliario o repartir laboratorios.

## Docentes que actualmente admiten daño

Se encontraron take_hit en academic_action_boss/academic_boss y herencia del
enemigo, ProfesorRedesBoss y DirectorInformaticaBoss. Los actores correspondientes:
Datos, Algoritmos, Enfermería, Odontología, Coordinador de Profesores,
Matemáticas, Inglés, Ética y Lenguaje; además Redes y Director de Informática.
Las ubicaciones actuales se mantienen: informática en 3; salud norte y profesores
en sectores distintos de 4; Inglés/Ética en 6; Lenguaje/Matemáticas en 7;
Director en 8 por instrucción expresa. No se realiza conversión masiva.

## Conversión posterior

TEACHER (mentor invulnerable) → ACADEMIC_CHALLENGE (pregunta/misión) →
TRAINING_SIMULATION (controlador de boss reutilizado) → enemigos digitales,
hologramas, bugs, virus o NEXO → REWARD.

Conservar claves de progreso existentes y migrar el origen del evento boss
completado hacia simulación superada. Mantener recompensas de partidas previas,
reintento, guardado preduelo y acceso a pisos. Convertir primero un solo docente
del piloto, validar y después extender al resto. Ninguna sala se construye en
esta etapa.
