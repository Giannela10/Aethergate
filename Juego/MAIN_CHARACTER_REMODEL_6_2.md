# DuocGames 6.2 — protagonista con malla humana

## Resultado y referencia

**IMPLEMENTADO:** el jugador real usa ahora una malla humana con piel, UV, texturas y Skeleton3D de **53 huesos**. Sustituye el cuerpo visible compuesto por piezas de 6.0 para el atuendo principal. Se conserva el controlador físico y se reutilizan sus poses para animar la piel. No es un modelo estático ni una modificación exclusiva de colores.

Referencia inspeccionada: `C:/Users/despacho2-cd/Downloads/Ficha del protagonista DuocGames 6.2.png`, copiada como [reference.png](reports/main_character_6_2/reference.png). Se tomó como guía de proporciones, colores y prendas; sus ejemplos de movimiento no se trataron como animaciones existentes. No se copiaron logotipos.

**La semejanza no es exacta:** el cabello disponible es más corto y menos ondulado; el rostro es el del asset adaptado, no el de la ficha; el polerón tiene menos pliegues y detalle; el calzado no reproduce la geometría deportiva de la referencia; la mochila conserva una construcción simplificada. No se declara alcanzada la calidad artística completa de la imagen.

## Recuperación y auditoría

Checkpoint Git local: `recovery/main-character-6-2`, commit `c7ea87536c159c01d58728576164949447cec30f`. Incluye las fuentes seleccionadas del protagonista y Main al inicio de esta intervención, sobre HEAD, con índice separado. No se sustituyó el índice del usuario ni se hizo push. Copias en `../recovery/main_character_6_2/`.

Se confirmó que Main crea Player mediante gameplay_manager.gd y player.gd; `Character.tscn` no es el jugador utilizado. No existían modelos humanos GLB/GLTF/FBX/OBJ/BLEND reutilizables en el proyecto. La imagen adjunta es una imagen, no un recurso 3D.

Durante los playtests, el editor reserializó Main automáticamente. Se compararon sus 50 030 secciones ignorando orden, UIDs generados, sufijos de nodos físicos anónimos, representación de saltos de línea y redondeos de escritura. No aparecieron cambios semánticos dentro de esas tolerancias. Se conservó una copia de esa reserialización y se restauraron los bytes originales. [Auditoría](reports/main_character_6_2/main_serialization_audit.json).

## Modelo, fuente y licencia

Datos obtenidos de [CharacterCreator / output](https://github.com/kblood/CharacterCreator/tree/master/output), de Kasper Olesen / kblood, derivados de los assets de MakeHuman Community / makehuman_system.

El autor libera los **GLB generados, sus texturas, morphs y datos de animación como CC0-1.0**. Su código tiene licencia GPL separada: **no se copió código del generador, plugin ni visor externo**. La conversión y adaptación de DuocGames se escribieron para este proyecto. [Declaración del autor](https://github.com/kblood/CharacterCreator/blob/master/LICENSE-NOTES.md), [procedencia local](assets/characters/main_6_2/SOURCE.md), `assets/characters/main_6_2/LICENSE-NOTES.md` y `asset_licenses.json`.

Archivos descargados: `base_body_anim.glb`, hoodie, T-shirt, jeans, shoes y cabellos short02, short04 y long01; también catálogos y documentación. [asset_hashes.json](reports/main_character_6_2/asset_hashes.json) verifica los originales contra los Git blob SHA publicados. [local_assets_manifest.json](reports/main_character_6_2/local_assets_manifest.json) registra SHA-256 y tamaños de las versiones locales convertidas.

Godot rechazó inicialmente `KHR_mesh_quantization`. Se decodificaron los accesores de morphs a floats, se conservaron siete morphs útiles y se fijaron sus valores iniciales. Godot GLTFDocument pudo entonces generar las escenas, que se guardaron como PackedScene nativos comprimidos. El juego carga **native/*.scn**, no los GLB incompatibles originales. Los intermediarios están en `source/`, excluidos de la importación automática mediante `.gdignore`.

## Archivos de producción

- **Nuevo** `scripts/juego/main_character_visual_6_2.gd`: integración exclusiva del jugador, conservación del visual anterior y cambio de opciones compatibles.
- **Nuevo** `scripts/juego/human_student_6_2.gd`: ensamblaje de mallas, materiales, morphs, skeleton compartido y retargeting.
- **Nuevo** `scripts/juego/shoe_material_6_2.gdshader`: acabado blanco/gris y variantes de color sobre las texturas del calzado.
- `scripts/juego/player.gd`: solo cambia el preload de `main_character_visual_6.gd` a `main_character_visual_6_2.gd` respecto al checkpoint.
- `scripts/campaign/appearance_menu.gd`: preview nuevo y valores cosméticos iniciales. Confirmación/cancelación y escritura de apariencia no cambiaron.
- **Nuevos assets** en `assets/characters/main_6_2/`: cuerpo, ropa, cabello y documentación de procedencia.

Main.tscn, humanoid.gd, student_visual.gd, el visual 6.0, CharacterAppearance y el adaptador compartido se conservan respecto al checkpoint. [source_audit.json](reports/main_character_6_2/source_audit.json). No se modificaron NPC, misiones, estadísticas, daño, economía, inventario funcional, login, Supabase ni guardado funcional.

## Mejoras implementadas

**Cuerpo y rostro:** topología humana continua, cuello integrado, nariz y orejas anatómicas, mandíbula, labios, ojos con iris/córnea, párpados y cejas del asset. Manos con dedos reales y pesos. Morph masculino moderado y variantes ligeras de rostro; parpadeo por morph. En primer plano sigue habiendo aliasing en cejas/pestañas y la textura de piel no coincide con la ficha.

**Cabello:** mallas texturizadas intercambiables y colores del perfil. Corto, lateral/rapado y largo reutilizan assets diferentes; algunas opciones comparten una aproximación. No hay simulación física ni cabello ondulado equivalente al de la referencia.

**Ropa:** polerón azul marino con capucha posterior, mangas y bordes de tejido, textura de bolsillo/costuras; jeans con textura de denim, costuras y bolsillos. Estas prendas tienen geometría ajustada y skinning, en lugar de cilindros superpuestos. El bolsillo del hoodie y parte de sus detalles son textura, no capas de tela completamente modeladas.

**Calzado:** malla importada de calzado casual con cordones, acabado blanco/gris, detalle oscuro y normal map cuando está disponible. No es una reconstrucción exacta de las zapatillas deportivas de la ficha.

**Mochila:** se reutiliza la mochila 6.0, conservando BackpackSocket, compartimento, bolsillo y cierres. Material más oscuro y tirantes elevados para el nuevo hombro. Sigue siendo una malla procedural simplificada; no se presenta como un asset externo nuevo.

**Materiales:** texturas reales del pack, StandardMaterial3D con rugosidad alta en tejido/denim y moderada en piel/cabello, especular contenido y material específico para calzado. No se pintó la ficha sobre geometría ni se importaron marcas de su calzado.

## Rig, animaciones y sockets

El Skeleton3D de 53 huesos y sus Skin/WEIGHTS reales se comparten entre cuerpo, prendas y cabello. Se conservan las articulaciones y eventos del controlador visual heredado y se transfieren sus poses al esqueleto, incluyendo manos, codos, rodillas y pies. Los dedos se cierran parcialmente al sujetar/golpear; al correr quedan más relajados. Se transfiere la pequeña respiración del torso.

El asset también incluye clips idle/walk/run/jump/fall/land y otros, conservados en el recurso. **El jugador integrado usa retargeting en vivo de sus poses existentes, no reproducción de todos esos clips ni motion capture nuevo.** Así se mantienen los tiempos funcionales de ataques e interacciones.

WeaponSocket e ItemSocket conservan su identidad y siguen el hueso de la mano con un desplazamiento calibrado; se conserva la base de orientación que esperan las armas existentes. Al volver al visual anterior recuperan sus padres y transformaciones originales. BackpackSocket y los sockets de cabeza se mantienen.

No se cambiaron cápsula, altura física, velocidades, salto, daño, hitboxes o cámara. Escala de Player/CharacterVisual **1.5**, cápsula de pie **2.7 × radio 0.45**; ajuste del modelo importado **1.07** y giro de orientación dentro del visual.

## Personalización y persistencia

La misma normalización, índices, restricciones y esquema appearance siguen vigentes. Nueva partida propone polerón, jeans azules, cabello oscuro, calzado blanco/gris y mochila oscura. Una partida existente conserva su selección: no se sobrescribe su atuendo guardado.

Para no eliminar opciones que todavía no tienen adaptación de mayor calidad, las prendas superiores especiales, outfits de recompensa, accesorios de cabeza/manos y calzado especial pueden activar **el visual 6.0 completo**. Es una limitación visible: no todo el armario fue convertido a la nueva malla. El perfil y las recompensas se conservan. La vista previa utiliza exactamente la misma clase que Player.

Se verificó el roundtrip de apariencia mediante un archivo user:// aislado y cambios repetidos sin acumulación de mallas. El flujo completo de guardar/salir/login/continuar con servicios remotos queda **PENDIENTE MANUAL**; no se afirma probado por el roundtrip aislado.

## Pruebas ejecutadas y evidencia

[Comparación con la referencia y 6.0](reports/main_character_6_2/comparison.html).

1. **Prototipo aislado:** HumanCandidate62 / BakeHuman62 / HumanSkinned62. Importación, rig, materiales y poses idle, walk, run, crouch, jump, attack, computer y pickup.
2. **Main instanciado:** MainCharacterRemodel62, sin persistencia personal. Antes usa el visual 6.0; después el nuevo. Perfil y cámaras comparables, registrados en los JSON.
3. **Entrada real del jugador:** Input.action_press sobre el controlador existente, con físicas activas: WALK a **2.5**, RUN a **5.5**, JUMP con desplazamiento vertical de aproximadamente **0.66**, CROUCH y ATTACK_LIGHT. El humano permaneció activo. Se congeló cada instante para encuadrar la captura; no son animaciones inferidas de la ficha.
4. **Combate/equipamiento:** recogida y equipamiento de un objeto real del inventario; identidad de sockets conservada; un evento de golpe en un ataque aislado; cambios de prenda sin perder referencias.
5. **Computador:** se llamó al método existente _use_computer y su señal abrió el minijuego, con Player ocupado y humano activo. Se canceló sin completar tarea. Esto verifica la integración de señal/minijuego, no la selección con teclado de todos los computadores.
6. **Arranque directo de Main:** Godot MCP devolvió el script `main_character_visual_6_2.gd` y **53 huesos**. Se cerró el menú y se aplicó el atuendo de referencia solo en memoria para la captura, con persistencia desactivada.

[functional.json](reports/main_character_6_2/functional.json) registra `failures: []`. No significa que se haya probado todo el juego.

Capturas: before_/after_ **front, left, right, back, face, game_camera, walking_campus**; after_live_ **walk, run, jump, crouch, attack**; after_zone_ **entrance, corridor, library, computer_lab, exterior**; **after_equipped**, **after_personalization**, **after_computer_interaction** y [main_direct.png](reports/main_character_6_2/main_direct.png). Las posiciones de zonas se comprobaron con safe_position y se alcanzaron mediante traslados de diagnóstico, no una ruta completa recorrida.

**VERIFICADO VISUALMENTE:** frontal, rostro, espalda, carrera real, ataque, equipamiento y biblioteca en los PNG, además de poses aisladas. Existen las otras capturas, pero no se declara revisión manual exhaustiva de todos los fotogramas ni todas las armas.

## Rendimiento

[performance_comparison.json](reports/main_character_6_2/performance_comparison.json) conserva las mediciones y sus condiciones. Hardware observado: GTX 1050, renderer Compatibility.

| Visual con atuendo comparable | 6.0 | 6.2 |
|---|---:|---:|
| Vértices visibles del jugador | 19 261 | 28 348 |
| Superficies visibles del jugador | 80 | 20 |
| Draw calls de la vista estática medida | 242 | 70 |

La primera comparación toma 90 intervalos con pose congelada; los intervalos se aproximan a **13.33 ms**, limitados por refresco de 75 Hz. El contador FPS del motor incluye historial de carga y no debe usarse como prueba de mejora/regresión a partir de esa muestra.

La medición adicional ejecuta animate() en cada frame, con **3 segundos de calentamiento y 180 intervalos** en la entrada del campus. Ambas versiones registraron **75 FPS y 13.333 ms de mediana**; draw calls de esa cámara: **2046 → 1873**. Son cámaras/condiciones distintas de la vista estática anterior. Se conserva el límite de refresco y se detiene la física/proceso de NPC: esto comprueba la animación continua del visual, pero no mide margen de GPU ni garantiza rendimiento de toda la campaña. El monitor TIME_PROCESS también incluye condiciones del bucle del motor y no se presenta como coste CPU exclusivo del rig.

Se redujeron los morphs importados a siete y se combinaron cuerpo/prendas en un esqueleto activo. Los recursos nativos suman aproximadamente **24.4 MB en disco**; esto no equivale a memoria GPU. No hay física de pelo/tela ni nuevos NPC. El visual anterior permanece oculto como recuperación y soporte del armario, por lo que aún tiene coste de nodos/animación.

## Pendientes reales

- Cabello con volumen ondulado equivalente a la ficha; diseño juvenil de rostro y piel más próximo a ella; mejorar aliasing de cejas/pestañas.
- Polerón con más pliegues y construcción de bolsillo/capucha, zapatillas deportivas específicas y mochila de mayor detalle.
- Adaptar todo el armario/accesorios a la malla nueva para eliminar los cambios al visual anterior.
- Animación facial de conversación; retargeting más fino de giros y manos para todas las armas; IK/contacto de pies y revisión prolongada de deslizamiento/penetración.
- Recorrido completo con físicas/combate y benchmark sin límite de refresco; guardado/carga de campaña completo, incluyendo servicios remotos.

Se entrega una mejora sustancial de malla, materiales y rig funcionando en Main. Las diferencias respecto a la ficha se mantienen explícitas; no se marca su fidelidad artística total como conseguida.
