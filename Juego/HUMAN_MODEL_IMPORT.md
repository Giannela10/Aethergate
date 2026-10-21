# Modelos humanos: perfil de importación 3.0

Se incorporó `res://assets/characters/human_pilot/human_pilot.glb`. Su inspección real confirmó que es geometría humana **estática**, sin rig, Skin ni clips. Para animarlo sigue siendo necesario un humano riggeado compatible o preparar una versión riggeada de este asset. No se descargan assets. Los rigs sintéticos de tests no son modelos humanos ni una validación artística.

## PILOTO HUMANO REAL 1.0: asset inspeccionado, rig pendiente

Godot importó el archivo suministrado como 18 MeshInstance3D, sin Skeleton3D, Skin ni AnimationPlayer; no contiene animaciones. Hay 1.121.607 vértices y 1.410.404 triángulos base, un material blanco sin mapas PBR. La escena `tests/HumanPilot.tscn` es un piloto separado: reutiliza Player/CharacterVisual, rechaza instalar el asset incompatible y conserva sus animaciones procedurales. Una vista estática explícita sirve solo para inspección y medición; no simula un humano animado.

La fuente mide aproximadamente 7,02968 unidades de alto. Solo en la vista estática se aplica escala 0,3840857 para coincidir con la cápsula existente de 2,7 m, se alinean los pies a Y=0 y se gira 180° en Y porque la fuente mira a +Z y el campus a -Z. No se modifica el GLB ni el edificio. No existen huesos a los que ligar arma/mochila/Head: sus pruebas funcionan únicamente en el fallback procedural.

La escala 0,3840857 pertenece al preview estático bajo HumanPilot, fuera de CharacterVisual. No copiarla sin revisar un futuro modelo instalado dentro del host, que ya tiene escala 1,5: habría que normalizar ese modelo a la altura local correspondiente para evitar escalarlo dos veces.

Ver `HUMAN_PILOT_REPORT.md`, `reports/human_pilot_inspection.json` y `reports/human_pilot_validation.json`. Las mediciones distinguen GLB estático de fallback procedural animado: no hay una medición de clips humanos que este asset no contiene. No reemplazar protagonista, NPC ni bosses. Antes de animarlo faltan rig, skinning, clips in-place y una revisión de densidad/LOD; no se riggea ni retargetea automáticamente el original.

## Contrato

Usar una escena .glb/.gltf importada como PackedScene con raíz Node3D, Skeleton3D con huesos reales, MeshInstance3D con Skin y pesos normalizados, y AnimationPlayer con clips compatibles. Unidades: metros; pies en Y=0, Y arriba, frente -Z. Aplicar escala/rotaciones en la herramienta de autoría. El host ya escala el personaje: ajustar el modelo dentro de su escena envolvente, sin cambiar cápsula, cámara ni velocidad del actor. Comprobar una altura humana aproximada de 1,7–1,85 m antes de aplicar la escala existente del host.

El adaptador también exige geometría con superficies: un rig vacío se rechaza antes de ocultar el fallback. La prueba sintética contiene una primitiva y huesos/clips de contrato; no demuestra skinning, retargeting ni calidad de un humano real.

Materiales StandardMaterial3D o equivalentes: albedo (sRGB), normal, roughness y metallic (datos lineales). Texturas opcionales; sin ellas usar colores/materiales actuales. Evitar materiales transparentes para toda la piel, múltiples materiales por pieza, luces propias, pelo con física y simulación de ropa. Preferir ropa skinned y pelo rígido/skinned. Preparar versiones de menor detalle antes de multiplicar NPC.

## Huesos y sockets

Jerarquía recomendada: Hips → Spine → Chest → Neck → Head; UpperArm_L → LowerArm_L → Hand_L; UpperArm_R → LowerArm_R → Hand_R; UpperLeg_L → LowerLeg_L → Foot_L; UpperLeg_R → LowerLeg_R → Foot_R. Los nombres son recomendaciones: el adaptador usa bindings explícitos y no obliga a renombrar el rig.

WeaponSocket e ItemSocket siguen siendo los nodos del host que usa el gameplay. Se enlazan a marcadores bajo BoneAttachment3D de Hand_R/Hand_L (o ambos a Hand_R si el contrato del arma lo requiere). BackpackSocket se enlaza a Chest/espalda; accesorios y cabello a Head. Los offsets de agarre pertenecen a la escena del modelo. No modificar la identidad del socket ni reprogramar inventario/armas. Un binding por ruta es relativo a la raíz importada. El flujo por hueso genera BoneAttachment3D y permite un offset local.

## Importación y animaciones

1. Copiar los archivos con su licencia a una carpeta propia de assets; esperar la importación del editor.
2. Crear una escena heredada/envolvente. Verificar Skin, materiales, escala, orientación y clips en el inspector.
3. En importación avanzada, para retargeting usar BoneMap con SkeletonProfileHumanoid y asignar huesos; revisar rest pose y tracks. Reimportar manualmente una copia. Nunca modificar automáticamente el original ni activar root motion que desplace el actor además de su controlador.
4. Añadir marcadores/BoneAttachment3D o proporcionar bindings por hueso al adaptador.
5. Llamar `install_imported_visual(scene, clips, bindings)` en el CharacterVisual existente. Conservar el booleano de retorno; un rechazo mantiene el procedural. No cambiar Player/NPC AI/bosses para usar el modelo.
6. Probar caminar, escaleras, agacharse, saltar, arma, mochila, daño, muerte/reintento, diálogo y guardado antes de asignarlo a más actores.

Las claves del mapa de clips son MAYÚSCULAS y sus valores los nombres completos del AnimationPlayer (incluida biblioteca si corresponde). IDLE/WALK/RUN son obligatorios. Opcionales: CROUCH, CROUCH_WALK, JUMP, FALL, LAND, ATTACK_LIGHT, ATTACK_HEAVY, THROW, DODGE, HIT, DEATH, INTERACT, PICKUP, PHONE, SIT, TALK y estados BOSS_* / HIT_* existentes. Un estado sin clip usa el procedural; no significa que la animación humana esté implementada. AnimationTree mezcla locomoción y transiciones; los tiempos de impacto siguen en gameplay, no en tracks importados.

También se aceptan claves en minúsculas, normalizadas por el adaptador. Ejemplo (usar un PackedScene importado real en `scene`):

```gdscript
var clips = {"idle":"human/idle", "walk":"human/walk", "run":"human/run"}
var bindings = {
    "bones": {"Hand_R":"mixamorig_RightHand", "Chest":"mixamorig_Spine2"},
    "weapon_socket": {"bone":"Hand_R", "offset":Transform3D.IDENTITY},
    "item_socket": {"bone":"Hand_R"},
    "backpack_socket": {"bone":"Chest"},
    "hair_socket": {"bone":"Head"},
    "head_accessory_socket": {"bone":"Head"}
}
var installed = character_visual.install_imported_visual(scene, clips, bindings)
```

Completar `bones.Head` si el rig no lo llama Head; cada binding suministrado se valida y un hueso ausente rechaza la instalación. Alternativa compatible anterior: `"weapon_socket":"Rig/RightHandAttachment/Grip"`. Sockets opcionales omitidos siguen su fallback: suministrar Backpack/Head para integrarlos con el humano. Un reemplazo inválido conserva el modelo anterior, o el procedural si no había modelo. HairSocket/HeadAccessorySocket son puntos de integración, no assets de pelo nuevos. Las prendas skinned deben prepararse en la escena del humano; no se retargetean prendas automáticamente.

## Prendas, cara y calidad

Prendas futuras: shirt, hoodie, jacket, pants, shoes, backpack. Cada prenda skinned debe compartir rig/rest pose y Skin compatible; asignar skeleton a la misma instancia, sin crear otra IA. Las prendas se preparan dentro de la escena del modelo; `apply_appearance(profile)` adapta las categorías/colores existentes. No hay prendas externas implementadas si faltan assets.

BlendShapes/MorphTargets son opcionales: neutral, happy, angry, worried, surprised, tired. Un modelo puede implementar `set_expression(value)`, `set_blink(closed)` y `set_gaze(yaw,pitch)`; ignorar canales ausentes. Limitar ojos/cuello en el modelo; no rotar el esqueleto completo. La actualización secundaria se limita por LOD. Cabello/accesorio de cabeza pueden usar bindings de Head; el fallback conserva los estilos procedurales.

Para ArrayMesh, los blendshapes happy/angry/worried/surprised/tired se detectan y cachean al instalar; `bindings.expressions` permite mapear claves MAYÚSCULAS a otros nombres. NEUTRAL pone a cero esos canales. Es opcional; no se exige una cara con morphs. `set_gaze` y `set_blink` continúan siendo hooks del modelo, no movimientos forzados sobre huesos desconocidos.

CHARACTER_HIGH/MEDIUM/LOW corresponden a ALTO/MEDIO/BAJO existentes. Mantener PBR de recursos originales; para simplificar materiales de un GLB futuro suministrar variantes en su escena, evitando modificar recursos compartidos. Reducir sombras/detalles por distancia. Nunca ocultar un NPC de misión de forma permanente ni alterar su estado guardado.

El adaptador llama al hook opcional `set_visual_quality("CHARACTER_HIGH" | "CHARACTER_MEDIUM" | "CHARACTER_LOW")` al instalar/cambiar calidad. La escena humana puede seleccionar materiales HIGH PBR / MEDIUM simplificados y detalles LOW; estas variantes requieren recursos reales y no se generan automáticamente. Los ajustes existentes ya regulan distancia y sombras del procedural.

Assets pendientes para realismo superior: un humano riggeado con licencia, Skin/rest pose humanoide, clips in-place, prendas compatibles, cabello y texturas PBR; opcionalmente blendshapes y ojos separados. Validar primero UN piloto real; los tests de contrato no sustituyen esa prueba.
