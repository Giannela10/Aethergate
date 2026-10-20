# Auditoría y plano de reorganización del Piso −1

## Auditoría de la escena actual

La escena activa es `Main.tscn`. El nivel se llama `PisoMenos1` y está a `Y = −12.0584`. Su losa ocupa aproximadamente `X = −84.8…84.3` y `Z = −162.45…−76.4`, unos `169 × 86 m`; el cielo/estructura de pisos superiores deja cerca de 12 m de altura hasta el nivel 1.

La escena ya contiene la losa y cuatro cierres perimetrales con colisión, una retícula de pilares, luminarias, la escalera central que baja desde Piso 1, su descanso inferior y protecciones de borde, la escalera de emergencia de varios tramos, los descansos y puertas con colisión, el vestíbulo y los accesos de los tres ascensores. No se deben reconstruir ni reemplazar esas piezas.

Las cabinas de ascensor están aproximadamente en `X = −10, 0, 10; Z = −157`. Sus puertas abren por el lado de `Z` creciente. Al salir, el personaje mira hacia `+Z` (sur del plano). Por tanto, en coordenadas del mundo, LEFT es `+X`, CENTER conserva el eje de salida y RIGHT es `−X`. La llegada de la escalera central ocupa aproximadamente `X = −20…19`, `Z = −138…−123`; se mantiene libre.

NEXO se crea desde `scripts/campaign/campus_campaign.gd` como `NexoFinalArea` en `(48, −12.018, −100)`. Su arena usa un radio aproximado de 10.5 m, mantiene el archivo, los tres terminales, acceso, checkpoint y el jefe; la misión describe la ubicación como la bahía industrial del sector este. Esta zona queda reservada y no se mueve.

El subterráneo actual no tiene locales, mesas de ping-pong, casilleros, salas técnicas, taller automotriz ni rampa vehicular. El generador solo construyó la caja de hormigón básica, las escaleras, las luminarias y las extensiones de los ascensores. `CampusCampaign` conserva las misiones y los flags; `NexoFinalArea` gestiona el archivo final, la credencial, el desbloqueo de puerta, el checkpoint y NEXO. La nueva arquitectura se agregará como decoración/espacios alrededor de esos nodos.

## Plano de distribución propuesto

Orientación referida al jugador que acaba de salir del ascensor (mirando a `+Z`):

| Zona | Coordenadas aproximadas | Criterio de ubicación |
|---|---:|---|
| Llegada y giro central | `X −20…20`, `Z −151…−120` | Dejar libre cabina, umbrales, salida, escalera central y desembarcos. |
| Mecánica automotriz (LEFT) | `X +25…+78`, `Z −148…−105` | El lado izquierdo del jugador es `+X`; módulos, vehículos y bancos de prueba. |
| Área común (CENTER) | `X −15…+24`, `Z −117…−84` | Dos ping-pong, mesas y sillas; lockers al fondo, junto a `Z −80`. |
| Negocio pequeño (RIGHT) | `X −45…−24`, `Z −140…−124` | Lado derecho equivale a `−X`; mantener los pasos de ascensor y escaleras. |
| Pasillo de salas | `X −72…−49`, `Z −123…−82` | Después del negocio; salas a la izquierda y lockers/servicios al lado opuesto del corredor. |
| Soldadura y estructuras | `X +24…+70`, `Z −98…−79` | Sector técnico oriental; separar visualmente pantallas y mesas de soldadura. |
| Bahía NEXO existente | centro `(48, −100)`, radio `10.5` | Área reservada sin geometría nueva que invada su espacio de duelo. |
| Rampa vehicular | `X −48…−28`, `Z −78…−34` | Cruza el borde norte del edificio y sube desde `Y −12.058` al terreno exterior `Y 0`; salida al exterior existente. |

Las coordenadas son un primer encaje en la huella real. Antes de fijar paredes se debe validar la visibilidad desde la salida y el espacio libre alrededor de la escalera, de las puertas, de las colisiones originales y de la reserva de NEXO. La rampa usa el suelo exterior ya existente, sin abrir los pisos 1–8 ni tocar el trazado de ascensores.

## Reglas de construcción

- Mantener todos los nodos existentes bajo `PisoMenos1`; agregar grupos visuales hijos con nombres propios y una marca de propiedad para poder auditar cada pieza.
- Usar módulos compartidos de lockers, luminarias, bandejas, cañerías y ductos; las filas repetidas se representan con recursos/materiales comunes y colisiones en tramos, no colisiones por cada detalle.
- Añadir colisión simple solo para límites de salas, mostrador, filas de lockers, mesas de ping-pong, vehículos/maquinaria y rampa. Los objetos elevados y detalles no llevan colisión.
- Mantener luces de sombra desactivadas, emissive para tubos y pocos puntos de luz locales. El taller usa grises de hormigón y metal, acentos amarillos/azules/rojos; el local usa una temperatura visual más cálida.
- NEXO, campaña, archivo, ascensores, puertas, escaleras y checkpoints conservan sus rutas, scripts, IDs y posiciones.

Esta referencia de implementación es una aproximación tridimensional construida con geometría procedural del proyecto; no se presenta como una copia fotográfica exacta.
