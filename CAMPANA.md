# DuocGames: campaña del campus

## Estado de esta versión

Las diez fases están integradas en `Main.tscn`. Se conservaron los pisos, las losas, las dimensiones del edificio, el rig procedural, los minijuegos y los sistemas anteriores. El contenido nuevo se instancia de forma determinista debajo de `Main/CampusCampaign`; no se regeneró el edificio. Los bosses reciben un hijo `BossDuelController`. Los tres accesos restringidos se añaden a puertas existentes en tiempo de ejecución.

Esto es una campaña funcional inicial: los diálogos son breves, el mapa es una lista de pisos y los modelos nuevos de objetos son procedurales. Requiere una pasada manual de balance y presentación; no equivale a una campaña narrativa terminada.

## 1. Sistemas implementados

- Interacción E centralizada, selección por prioridad, proximidad y alineación con cámara; comprueba paredes y altura. Un solo indicador contextual.
- Bosses neutrales e inmunes hasta aceptar el duelo. Diálogo, Ahora no, introducción con fade, barra de vida durante combate, fases existentes, victoria, recompensa única y estado persistente.
- Campaña principal de nueve etapas y seis secundarias, objetivos HUD, menú M y eventos reutilizables.
- WorldItem/WeaponPickup para armas físicas, consumibles, llaves, papelería y tarjetas; identidad persistente para impedir recogidas duplicadas al cargar.
- Rareza de armas, durabilidad individual, armas únicas y lanzamientos compatibles con Q.
- Tres puertas existentes restringidas, menú de destinos del ascensor y desbloqueos por progreso.
- Seis checkpoints, guardado extendido, menú Continuar/Nueva partida y reaparición sin pérdida de objetos.
- Veinte tarjetas, cuatro apuntes, cuatro áreas secretas y un computador secreto.
- Estamina, ataque fuerte al mantener clic y esquiva con Alt.
- XP, créditos, cinco mejoras, tres expendedoras, un vendedor y nueve enemigos distribuidos, con variantes normal, rápida, pesada, a distancia y tecnológica.
- Registro B, mapa Tab, pausa Esc, controles, opciones básicas, tutorial, logros y estadísticas.
- Nodos de ambiente y música de bosses, números de daño y slot de sonido de impacto.

## 2. Scripts nuevos

Todos bajo `scripts/campaign/`:

| Script | Responsabilidad |
|---|---|
| `campus_campaign.gd` | Orquestación, progreso, guardado, menús, recompensas y restauración |
| `interaction_controller.gd` | Acción contextual única |
| `boss_duel_controller.gd` | Estados y ciclo universal de duelo |
| `campaign_ui.gd` | Diálogos, introducción, vida de boss y notificaciones |
| `campus_content.gd` | Distribución determinista de contenido por piso |
| `world_item.gd`, `weapon_pickup.gd` | Recogibles e identidad persistente |
| `campus_weapon.gd` | Nuevas armas y rareza, reutilizando implementos deportivos |
| `quest.gd`, `quest_manager.gd`, `quest_ui.gd` | Definiciones, eventos, estados y menú de misiones |
| `npc.gd` | Diálogo, aceptación y entrega de objetos |
| `locked_access.gd` | KEY_ITEM, BOSS_REWARD, MISSION y ACCESS_LEVEL |
| `elevator_interaction.gd` | Llamada y selección de destino con E |
| `checkpoint.gd` | Activación y posición segura |
| `area_marker.gd` | Áreas y secretos |
| `player_combat.gd` | Estamina, carga de ataque y esquiva |
| `campus_vendor.gd` | Compra con créditos |
| `campus_enemy.gd` | Variantes de enemy.gd |
| `distraction.gd` | Lanzamiento de objetos que producen ruido |
| `campus_audio.gd` | Ambientes, atenuación y evento opcional |
| `campus_polish.gd` | Tutorial y feedback de daño |

Pruebas nuevas: `tests/campaign_smoke.gd` y `tests/campaign_regression.gd`.

## 3. Scripts existentes ampliados

- `player.gd`: delegación de E, carga/esquiva, multiplicadores de daño y velocidad, distracciones y aislamiento del guardado en pruebas.
- `enemy.gd`: comprueba el controlador de duelo antes de IA, daño y golpes; los enemigos sin controlador mantienen su comportamiento.
- `boss_ayuda_estudiantil.gd`, `chef_supremo_casino.gd`, `director_informatica_boss.gd`: guardas de neutralidad; sus fases y ataques permanecen.
- `boss_bibliotecaria.gd`: entrada E delegada al controlador y evento de respuestas correctas; conserva preguntas, cámara y reglas originales.
- `credencial_director.gd`: sincronización con la campaña y migración del registro anterior.
- `inventory_item.gd`, `item_catalog.gd`, `inventory.gd`, `inventory_ui.gd`, `paleta_ping_pong.gd`, `inventory_pickup.gd`, `item_effect_receiver.gd`: catálogo ampliado, rareza, snapshot, capacidad, entrega de misiones, estados y neutralidad.
- `weapon.gd`, `computer.gd`, `npc_papeleria.gd`: evitan indicadores E superpuestos cuando existe el controlador central.
- `gameplay_manager.gd`: permite pruebas de campaña sin tocar el inventario de la partida; conserva cámara, HUD, combate y minijuegos.
- `puerta_vidrio_salas.gd`: respeta el bloqueo opcional; las demás puertas siguen automáticas.
- `ascensor_estudiantil.gd`: conserva cabina y desplazamiento; delega E y aplica desbloqueos de campaña.
- `minigame_ui.gd`, `game_files.gd`, `game_virus.gd`, `game_password.gd`: dificultad moderada por piso, con valores originales cuando no hay campaña.

`humanoid.gd` no se modificó en esta ampliación.

## 4. Escenas y nodos

Escena modificada: **Main.tscn**. No se modificaron las escenas compartidas de salas ni se borraron nodos existentes.

Se agregaron `CampusCampaign`, cuatro `BossDuelController` y `CampusCampaign/ZoneAudio` con cinco `AudioStreamPlayer3D` y `ImpactSound`. El resto del contenido se construye al ejecutar desde las definiciones guardadas en scripts. Las posiciones de contenido nuevo se ajustan hasta 6 m para encontrar suelo del mismo nivel y una cápsula libre. No se desplaza geometría del edificio. La comprobación automática verifica suelo y espacio, no todos los caminos posibles alrededor de muebles.

## 5. Armas colocadas

| Piso | Armas físicas nuevas |
|---|---|
| 1 | Palo, Silla, PaletaPingPong, Escoba, Bandeja |
| 2 | Silla, LibroPesado, Palo |
| 3 | Silla, Palo |
| 4 | Herramienta, Silla |
| 5 | Palo, Herramienta |
| 6 | Silla, LibroPesado |
| 7 | Palo, ExtintorDorado |
| 8 | Teclado, NotebookRoto, Cable |
| S | LlaveInglesa, Herramienta, ExtintorDorado |

La tabla recoge las **24 armas originales**. Se añadieron **27 más**, para un total de **51**: palo, silla y escoba cerca de la entrada, y tres armas adicionales en cada piso restante. Los IDs originales se conservan para las partidas guardadas. Además, `furniture_pickup.gd` permite tomar y equipar sillas del mobiliario, incluidas las del casino; retira sus colisiones y conserva la recogida al cargar. Las butacas fijas y bancos permanecen como mobiliario. Las coordenadas de las armas están en `campus_content.gd`, método `weapons`; el ajuste de suelo afecta únicamente a los objetos nuevos, sin desplazar las sillas existentes.

Rarezas: común, poco común, rara y especial. Las armas nuevas multiplican daño y durabilidad por 1.0, 1.1, 1.25 y 1.4 respectivamente; la velocidad depende del tipo. El arma equipada conserva su instancia y durabilidad. Al romperse se retira del inventario y se conserva el aviso existente. Q lanza implementos compatibles, incluida BandejaDelChef y PaletaProfesional. Sin arma equipada, Q puede gastar una bebida o una hoja impresa como distracción; no consume objetos clave.

## 6. Bosses y recompensas

| Boss | Tipo | Vida | Recompensa |
|---|---|---:|---|
| Encargado Punto Estudiantil | COMBAT | 200 | PaletaProfesional |
| Chef Supremo del Casino | COMBAT | 450 | BandejaDelChef, LlaveCasino y curación anterior |
| Bibliotecaria | QUIZ | 125 | LibroEspecial |
| Director de Carrera de Informática | COMBAT | 700 | CredencialDirector y TecladoAdministrador |

Cada victoria también entrega 75 créditos y 150 XP, además de eventuales recompensas de misión. El teclado tiene bonus contra enemigos tecnológicos. Las recompensas entran directamente a la mochila y no se pierden si se supera temporalmente su capacidad.

Estados: NEUTRAL → DIALOGUE → INTRO → COMBAT → DEFEATED. Ahora no vuelve a NEUTRAL. Morir restablece el duelo, limpia invocaciones y proyectiles del boss y devuelve al jugador al checkpoint. Un boss derrotado no repite recompensas al cargar.

El controlador exporta `boss_name`, `intro_text`, `subtitle`, `duel_type`, `max_health`, `reward`, `boss_id`, `intro_duration`, `music`, `defeated` y `special_rules`. COMBAT y QUIZ están usados. MINIGAME y FUTURE_TYPE son puntos de extensión: necesitan configurar `special_rules.start_method` y una integración concreta; sin ella el controlador avisa y no inicia un duelo vacío.

El USB mantiene la debilidad del Director: daño especial, parálisis y cancelación de Pantallazo Azul. Los receptores admiten resistencias e inmunidades configurables. `apply_status` prepara ralentizado, paralizado, aumentado y debilitado; velocidad/daño requieren que el receptor exponga una propiedad compatible. No todos los bosses tienen esas propiedades para todos los estados.

## 7. Misiones

Campaña principal: Primer día → Biblioteca → etapas académicas de pisos 3, 4 y 5 → seguridad del piso 6 → acceso del piso 7 → Dirección de Informática → archivos del subterráneo. Desbloquea destinos del ascensor de manera secuencial.

Secundarias:

| Misión | Inicio/entrega | Objetivo y recompensa |
|---|---|---|
| Las llaves perdidas | Auxiliar, Piso 1 | Llaves del Piso 4; Botiquín, XP y créditos |
| El cargador | Estudiante, Piso 2 | Cargador del Piso 3; energética, XP y créditos |
| Documentos importantes | Profesor, Piso 3 → Funcionario, Piso 5 | Entrega; TarjetaAcceso, XP y créditos |
| Implementos perdidos | MonitorDeportes, Piso 1 | Balón, paleta y raqueta de pisos 3–5; paleta, XP y créditos |
| Computador infectado | Técnico, Piso 3 | Antivirus; USBInfectado, XP y créditos |
| Ayuda en el casino | AyudanteCasino, Piso 1 | Iniciar duelo con Chef; XP y créditos |

La infraestructura admite NOT_STARTED, ACTIVE, COMPLETED y FAILED, requisitos con cantidades y eventos de hablar, recoger, enemigo, boss, computador, piso, responder, puerta, secreto y entrega. `fail_quest` queda disponible; las misiones actuales no fallan por límite de tiempo.

## 8. NPC

Ocho NPC nuevos: Auxiliar (1), Estudiante (2), Profesor (3), Funcionario (5), MonitorDeportes (1), Técnico (3), EstudiantePerdido (1) y AyudanteCasino (1). Cambian diálogo según la misión, aceptan entregas y evitan premios repetidos. Se conserva la papelería existente. El vendedor adicional utiliza el sistema de compras.

## 9. Tarjetas, notas y secretos

Veinte tarjetas persistentes: dos por piso 1–8 y cuatro en el subterráneo. Cada tarjeta da XP/créditos; reunir las veinte entrega ExtintorDorado y una recompensa adicional.

Apuntes de Programación (3), Base de Datos (4), Redes (6) e Inteligencia Artificial (8). Se incorporan a los apuntes de papelería. F los muestra si no hay un artículo equipado; también se pueden editar desde la mochila.

Secretos: rincón de biblioteca, estudio del Piso 6, sala especial del Piso 8, archivo del subterráneo y computador secreto del subterráneo. Este último entrega USBMaestro y un desbloqueo digital. No se construyó una habitación nueva ni se alteró una pared para simular pasajes.

## 10. Puertas y ascensores

- Piso 7, `PasilloReferencia/Sala805/PuertaSala`: TarjetaAcceso; evento `door:acceso7`.
- Piso 8, `PasilloReferencia/Sala805/PuertaSala`: TarjetaAcceso.
- Piso 8, `PasilloReferencia/Sala806/PuertaSala`: CredencialDirector.

Las llaves no se consumen. Las demás puertas conservan su comportamiento. LlaveCasino queda disponible para añadir otro acceso de casino; no se cerró su entrada principal.

Los ascensores conservan su movimiento y puertas físicos. E llama desde el rellano; dentro, E abre destinos 1–8 y S. Solo el piso 1 está habilitado al comienzo. Las misiones habilitan los siguientes. **Las escaleras no se bloquearon**: los bloqueos son de ascensor y de los tres accesos señalados, no una barrera física de toda la campaña.

## 11. Checkpoints y muerte

Entrada, biblioteca, casino, Piso 4, Piso 8 y subterráneo. Se activan por proximidad fuera de un duelo. Guardan posición segura y salud junto con el resto de la partida. Al morir aparece HAS CAÍDO con Reintentar desde checkpoint y Volver al menú. No se pierden objetos ni créditos. Se restablecen IA y fases de los bosses no derrotados; los enemigos normales conservan el estado de esa ejecución.

## 12. Guardado

`user://campus_campaign_v1.json`, versión 1, escrito primero a un temporal y luego renombrado. Incluye inventario y durabilidad, papelería/apuntes, eventos, misiones, bosses, recogibles, tarjetas, secretos, computadores, checkpoint, posición, salud, piso, créditos, XP, mejoras, tutorial, logros y estadísticas.

Se mantienen los archivos previos de inventario, papelería y credencial. Al no existir campaña se aprovecha el inventario anterior; la credencial antigua puede marcar al Director como derrotado. No se pueden reconstruir victorias antiguas que nunca se guardaron.

Autoguardado por acciones importantes y cada 30 s fuera de combate/menús. No se guardan daño parcial de un boss, proyectiles en vuelo, enemigos normales muertos, temporizadores de consumibles, estamina o esquiva. La reaparición usa el checkpoint; Continuar usa la última posición guardada.

Nueva partida exige confirmación y deja `.bak` de la campaña anterior antes de reiniciar progreso e inventario. El guardado es de un solo slot.

## 13. Controles

| Tecla | Acción |
|---|---|
| E | Acción contextual única |
| M | Misiones |
| Tab | Mapa de pisos |
| B | Registro y estadísticas |
| U | Mejoras |
| Esc | Pausa / cerrar diálogo |
| Clic corto / J | Ataque normal |
| Mantener clic ≥0.45 s y soltar | Ataque fuerte: ×1.8 daño, 30 estamina |
| Alt | Esquiva: 25 estamina, 0.22 s de invulnerabilidad, enfriamiento 0.7 s |
| Shift | Correr: 14 estamina/s; recuperación 22/s |
| Q | Lanzar arma compatible o distracción sin arma |
| I / 1–4 / F | Mochila / accesos rápidos / apuntes |

WASD, salto, agacharse y cámara siguen disponibles.

## 14. Preparado para después

- Archivos reales de audio: asignar streams a `CampusCampaign/ZoneAudio` y `music` de cada boss. Sin archivos, los slots quedan silenciosos; no se añadieron sonidos inventados.
- Eventos aleatorios: desactivados por defecto. Existe temporizador opcional y rutina de parpadeo/restauración de luces; falta diseñar y activar eventos con consecuencias completas.
- Boss opcional del subterráneo y tipos de duelo futuros.
- LlaveCasino, USBMaestro y CredencialAntigua como base para accesos/objetos adicionales.
- Animaciones importadas, como se explicó en INVENTARIO.md.
- Refinar navegación de enemigos entre muebles; siguen usando colisiones y persecución del sistema anterior, no un nuevo NavigationMesh del edificio entero.

## 15. Verificación y límites

Se ejecutó la prueba de arranque al terminar cada fase y se corrigieron los errores antes de avanzar. Las pruebas de campaña incluyen neutralidad, cancelar/aceptar, victoria, preguntas, entregas, puertas, tarjeta única, muerte, esquiva, compras, recompensa idempotente, guardado y recarga con créditos/inventario/posición persistentes. La colocación prueba suelo y espacio libre. Se ejecutan además las regresiones de juego e inventario y las pruebas de Chef/Director.

Durante la integración se corrigieron la conversión de números JSON al cargar, una carrera de inicialización de controladores, la cancelación de diálogos, el estado de aturdimiento al reaparecer y la pérdida de propiedades exportadas durante recargas del editor. Las pruebas headless generan avisos del certificado de Windows y del registro local del plugin bajo el sandbox; se separan de errores de scripts.

Pruebas:

```text
godot --headless --path . --script res://tests/campaign_smoke.gd
godot --headless --path . --script res://tests/campaign_regression.gd
godot --headless --path . --script res://tests/gameplay_regression.gd
godot --headless --path . --script res://tests/inventory_regression.gd
godot --headless --path . --script res://tests/chef_supremo_casino.gd
godot --headless --path . --script res://tests/director_informatica_boss.gd
```

## 16. Prueba manual recomendada

1. Iniciar Main con F5. Revisar Continuar y, si se desea reiniciar, Nueva partida y su confirmación.
2. Acercarse al Chef y atacar antes de hablar: no debe recibir daño ni atacar. Probar Ahora no y regresar; luego Iniciar duelo, introducción y fases.
3. Verificar la Bibliotecaria: aceptación → preguntas, no combate físico. Ganar y regresar al juego con la cámara/ratón restaurados.
4. Recoger dos armas iguales, usarlas, cambiar, guardar, lanzar y romper una; revisar durabilidades individuales.
5. Seguir las misiones de llaves y documentos. Abrir un acceso sin consumir TarjetaAcceso.
6. Llamar el ascensor con E, entrar y abrir su menú; comprobar bloqueo y desbloqueo de destinos.
7. Activar un checkpoint, morir, reaparecer y verificar inventario; cerrar y volver a Continuar para comprobar posición y créditos.
8. Usar ataque fuerte, correr hasta agotar estamina, esquivar y lanzar una distracción.
9. Completar un computador normal y el secreto, comprar objetos, adquirir mejoras y revisar M/Tab/B/U/Esc.
10. Recorrer físicamente las posiciones de todos los pisos. Ajustar en `campus_content.gd` cualquier objeto que quede poco visible o poco natural: la prueba de espacio no sustituye el recorrido humano completo.
