# DuocGames 6.3 — pies y remodelación de personajes

Implementación activa en Main con configuración de lote 7. **34 NPC humanos / 34 identificadores distintos** usan la nueva representación. El inventario contiene 57 representaciones, incluyendo cuerpos heredados ocultos y el protagonista; no son 57 personajes nuevos. Los diseños digitales/especiales y el protagonista conservan sus integraciones propias.

## 1. Recuperación y conservación de 6.2

Se revisó MAIN_CHARACTER_REMODEL_6_2.md y se verificó c7ea875. Se conservan recovery/characters_6_3 y recovery/characters_6_3_finish_20261106_123513. Esta continuación no repitió la importación ni reemplazó el protagonista. Los SHA-256 de Main.tscn, player.gd y gameplay_manager.gd coinciden con el punto inicial de esta continuación. No hubo push ni commit general del árbol del usuario.

## 2. Diagnóstico y corrección de pies

La implementación previa 6.3 ya corregía dos causas: aplanar erróneamente el segmento tobillo-dedos al transferir la pose inclinaba la suela, y ciertas superficies decorativas estaban por encima de su colisión. Se conserva la referencia horizontal correcta y el muestreo de la superficie visible. La cápsula y la física del jugador permanecen intactas.

## 3. Zapatillas e integración

character_footwear_6_3.gd utiliza geometría de zapatilla modelada por secciones, con puntera redondeada, talón, lengüeta, cordones, cubierta y suela diferenciadas. Tres superficies y cuatro binds: foot_l, ball_l, foot_r y ball_r. La corrección de apoyo resuelve visualmente la pierna y limita el anclaje temporal por alcance; no añade colisiones. El calzado anterior y sus assets siguen recuperables.

En esta continuación se corrigió la caché de cuerpos recortados: ya no conserva una malla pesada con morphs por cada instancia del mismo recurso. El contenido geométrico del protagonista se mantiene.

## 4. Inventario y arquitectura

Se buscaron fábricas en scripts, escenas principales/secundarias, NPC de campaña, estudiantes de rutina/aula/rescate, guardias, bibliotecaria, actores educativos, figurantes de eventos y simulaciones. [Inventario original](reports/characters_6_3/inventory_runtime.json), [fábricas](reports/characters_6_3/character_factories.json), [cobertura normalizada por nodo](reports/characters_6_3/coverage_by_character.json).

Los actores conservan ID, nombre, misión, materia, diálogo, señales y colisiones. npc_visual_6_3.gd adapta solo la representación. Cada humano dispone de pose independiente en Skeleton3D de 53 huesos; scripts, PackedScene, mallas fuente, geometrías horneadas y materiales se comparten cuando corresponde.

## 5. Lotes implementados

Lote 1: pies conservados y revalidados. Lote 2: pilotos Auxiliar/Estudiante conservados. Lote 3: profesores/mentores. Lote 4: estudiantes existentes y fábricas ambientales. Lote 5: funcionarios, personal de servicios, guardias, papelería y bibliotecaria. Lote 6: estudiante de rescate. Lote 7: revisión de especiales, manteniendo sus diseños específicos. Los JSON batch4_validation a batch7_validation registran las comprobaciones realizadas entre lotes.

## 6. Representaciones anteriores y especiales

Las simulaciones digitales, bugs y cuerpos lógicos heredados ocultos se conservan. Los mentores educativos siguen separados de las hitboxes de sus simulaciones. No se añadieron profesores, estudiantes permanentes ni recorridos. Las alturas sin estudiante inicial válido no se rellenaron artificialmente. Casos activos sin clasificar en la auditoría final: 0. El spawner de enemy.gd ligado a populate_entrance=false y la plantilla Character.tscn no utilizados por Main mantienen su visual anterior; no se activa ni modifica ese modo de combate.

## 7. Rostros y cuerpos

La semilla estable deriva del identificador. Se configuran morphs de nariz, mandíbula, mentón, pómulos, ojos, labios, boca, orejas y frente, con variaciones moderadas de proporciones y edad. Las formas se hornean una vez conservando skinning. La prueba de la fábrica produjo **9 geometrías distintas** para nueve perfiles; no se limita a cambiar materiales.

## 8. Cabellos

Recursos encontrados en los NPC remodelados: `Sin cabello`, `hair_afro01`, `hair_bob01`, `hair_bob02`, `hair_braid01`, `hair_long01`, `hair_ponytail01`, `hair_short02`, `hair_short04`. La base dispone de ocho estilos, además de la opción sin cabello, con tonos del perfil. Se conserva una expresión neutral; no se incorpora captura facial ni simulación de cabello.

## 9. Prendas y accesorios

Prendas en uso: clothing_hoodie, clothing_jacket, clothing_shirt, clothing_tshirt; estudiantes combinan polera, polerón, camisa o chaqueta con pantalones. Se preservan mochilas, props, credenciales, libro de biblioteca y distintivos compatibles. Guardias usan chaqueta grafito. Odontología utiliza camisa clara compatible; se descartó la gabardina que se deformaba en sus poses.

Se alinearon los lentes con los ojos del modelo mediante el hueso de cabeza. Gorro del chef y accesorios de cabeza siguen ese mismo anclaje visual. Los audífonos cuentan con una nueva malla compartida de banda curva y copas, sustituyendo la barra desconectada anterior. No se añadieron colisiones cosméticas.

## 10. Animaciones

Se mantienen los estados y animadores existentes y se transfieren poses al rig humano. Los NPC basados en StudentVisual conservan conversación, lectura, escritura, celebración, asiento y computador. Guardia/bibliotecaria basados en Humanoid mantienen sus acciones disponibles; la prueba comprueba estabilidad cuando un contexto no existe, sin fingir una animación nueva.

Se aplican poses locales jerárquicas y se permite al motor actualizar el esqueleto una vez antes del render. Referencia: [Skeleton3D de Godot](https://docs.godotengine.org/en/stable/classes/class_skeleton3d.html). Una conversión incorrecta detectada durante la optimización se corrigió antes de ampliar los lotes y se añadió un control anatómico que detecta cuerpos colapsados.

## 11. Optimización y rendimiento

LOD de malla, materiales compartidos, caché de cuerpos fuente, distribución de actualizaciones por identificador y frecuencias visuales según distancia: 30 Hz cerca, 15 Hz a distancia media, unos 8 Hz más lejos y 2,5 Hz al fondo. Se conserva SLEEP y la separación por nivel. El rig auxiliar no se anima a una frecuencia mayor que el humano; ataques/daño/estados críticos mantienen sus tiempos. El protagonista sigue con su actualización propia. Sombras respetan la calidad y la distancia.

Benchmark63: misma escena y distribución de 1/5/15/30 personajes, 180 muestras tras calentamiento, vsync desactivado. FPS derivados de la mediana; memoria del monitor del motor, no memoria incremental exclusiva. [Datos finales](reports/characters_6_3/benchmark_final.json).

| NPC | Anterior ms | 6.3 ms | 6.3 p95 ms | FPS derivados 6.3 | Draw calls | Vídeo MiB |
|---|---:|---:|---:|---:|---:|---:|
| 1 | 0.436 | 0.650 | 0.793 | 1538.5 | 63 → 15 | 14.5 → 72.3 |
| 5 | 0.899 | 1.878 | 2.483 | 532.5 | 294 → 76 | 14.6 → 107.3 |
| 15 | 2.410 | 3.818 | 6.916 | 261.9 | 895 → 241 | 14.9 → 141.7 |
| 30 | 5.382 | 5.531 | 9.578 | 180.8 | 1791 → 473 | 15.3 → 188.6 |

Main, cámara comparable con físicas de actores congeladas: **8.296 → 8.151 ms**, p95 **15.486 → 17.869 ms**. Esta muestra no equivale a una campaña completa con todos los sistemas activos. La memoria inicial del caso de 30 NPC era aproximadamente 734 MB decimales; la caché compartida eliminó la mayor parte de esa retención. Los benchmarks intermedios anteriores a la revisión visual no se usan como evidencia final.

## 12. Assets y licencias

CharacterCreator/MakeHuman, Kasper Olesen/kblood. Los LICENSE-NOTES.md locales declaran CC0-1.0 para los datos GLB generados desde fuentes CC0, incluidos cuerpo, prendas, cabello, texturas y animaciones. El generador tiene GPL separada y no se incorporó su código. Se conservan procedencia y hashes en assets/characters/shared_6_3/provenance.json y documentación main_6_2. Calzado y nuevos audífonos son geometría creada para el proyecto. No se descargaron assets nuevos en esta continuación.

## 13. Archivos de producción modificados

- scripts/juego/npc_visual_6_3.gd: cobertura por rol, prendas, relevancia, accesorios y frecuencia visual.
- scripts/juego/human_npc_6_3.gd: caché de jerarquía y transferencia de poses locales.
- scripts/juego/humanoid.gd: presupuesto de representación para NPC y seguridad de la instalación diferida al retirar previews. Sin cambios a tiempos críticos de gameplay.
- scripts/juego/character_footwear_6_3.gd: compartir correctamente la caché de cuerpo cubierto.
- scripts/juego/character_headset_6_3.gd: nueva geometría compartida.
- scripts/juego/characters_6_3_rollout.json: lote 7 activado.

Se añadieron fixtures y escenas de diagnóstico bajo tests, datos/capturas bajo reports/characters_6_3 y este informe. Main.tscn, player.gd y gameplay_manager.gd permanecen idénticos por hash. Los modelos anteriores no se eliminaron.

## 14. Capturas antes/después

[Pies antes](reports/characters_6_3/before_feet_idle_right.png), [pies actuales](reports/characters_6_3/after_feet_idle_right.png), [Auxiliar](reports/characters_6_3/batch7_Auxiliar_front.png), [estudiante de aula](reports/characters_6_3/batch7_v4_lab_student_front.png), [bibliotecaria](reports/characters_6_3/batch7_bibliotecaria_face.png), [chef](reports/characters_6_3/batch7_chef_front.png), [profesor de Inglés](reports/characters_6_3/batch7_profesor_ingles_face.png), [rescate](reports/characters_6_3/batch7_v4_rescued_student_front.png).

Las capturas NPC son de Main instanciado con cámara de inspección, persistencia desactivada y actores congelados. Las capturas live_feet utilizan entradas reales del controlador; los traslados entre zonas se realizan mediante diagnóstico. No se presentan como un recorrido manual completo.

## 15. Pruebas ejecutadas

- 6/6 suites automáticas aprobadas sin errores de motor: gameplay, inventario, personalización, lectura de guardado, nueva partida y campaña. [Resultados](reports/characters_6_3/final_regressions.json).
- Lote final: 34 representaciones, 53 huesos, skin válido, transformaciones finitas y proporciones válidas en once estados. Se respetan contextos soportados por cada clase.
- Auxiliar: apertura real del diálogo, texto exacto [E] Hablar con Auxiliar y misión sin aceptar durante el fixture.
- Fábrica real de figurantes invocada sobre nueve alturas: 9 casos; apariencia estable tras serializar/reaplicar, una sola instancia y 9 mallas distintas. No añade personajes permanentes. [Datos](reports/characters_6_3/dynamic_factories_validation.json).
- Pies: fixture renderizado repetido con caminar, correr, salto, aterrizaje, agacharse, ataque, superficies decorativas, biblioteca, escalera y cabina/ascensor en movimiento. La solicitud de un piso puede estar bloqueada por campaña nueva; la prueba de movimiento aislado no modifica desbloqueos. [Datos](reports/characters_6_3/after_live_feet.json).
- Revisión visual de capturas de estudiantes, Odontología, biblioteca, seguridad, chef, Inglés y protagonista. La comprobación automatizada no sustituye la revisión artística de cada fotograma.

## 16. Límites y pruebas manuales pendientes

No se certifica ausencia de clipping en todas las combinaciones de ropa/armas ni foot sliding en recorridos prolongados. El armario especial del protagonista conserva el fallback 6.0 documentado en 6.2. Guardado/carga remotos, login y Supabase no se modificaron ni se probaron con una cuenta real. La prueba de campaña es automática y no equivale a jugarla completa. Se recomienda revisión artística prolongada de cabellos, uniformes y manos en contextos de asiento/escritura.

Las primeras pruebas dentro del aislamiento encontraron bloqueos de registros/certificados y un error de instalación diferida al retirar previews. Se corrigió el error y se repitieron las seis suites fuera del aislamiento con aprobación; sus resultados finales son los enlazados arriba.

## 17. Cobertura por nivel y personaje

| Nivel | Humanos remodelados iniciales | Identificadores | Fábrica dinámica |
|---|---:|---|---|
| -1 | 1 | v4_civilian_-1 | Probada |
| 1 | 10 | guard:Exterior/Caseta/PuestoRegistro/GuardiaRegistro, guard:Exterior/EntradaReferenciaDuoc/GuardiasTorniquetes/Guardia1, guard:Exterior/EntradaReferenciaDuoc/GuardiasTorniquetes/Guardia2, Auxiliar, MonitorDeportes, EstudiantePerdido, AyudanteCasino, v4_civilian_1, punto, chef | Probada |
| 2 | 4 | npc_papeleria, bibliotecaria, Estudiante, v4_civilian_2 | Probada |
| 3 | 8 | Profesor, Tecnico, v4_rescued_student, v4_civilian_3, v4_lab_student, profesor_datos, profesor_algoritmos, profesor_redes | Probada |
| 4 | 4 | v4_civilian_4, docente_enfermeria, docente_odontologia, coordinador_profesores | Probada |
| 5 | 2 | Funcionario, v4_civilian_5 | Probada |
| 6 | 2 | profesor_ingles, profesor_etica | Probada |
| 7 | 2 | profesor_lenguaje, profesor_matematicas | Probada |
| 8 | 1 | director | Probada |

Los pisos sin estudiante inicial no recibieron NPC nuevos; la fábrica compartida se prueba en las nueve alturas. Las entradas heredadas ocultas siguientes se conservan como respaldo de lógica/simulaciones, no son personajes adicionales pendientes de sustitución genérica.

| Nivel | ID | Rol | Nodo en Main | Representación | Interacción |
|---|---|---|---|---|---|
| 1 | CuerpoBoss | Ver script | Main/Piso1/SalaAyudaEstudiantil/BossAyudaEstudiantil/CuerpoBoss/VisualBoss | Visual heredado oculto; conservar |  |
| 1 | ChefSupremoCasino | Ver script | Main/Piso1/Casino/ChefSupremoCasino/VisualChef | Visual heredado oculto; conservar |  |
| 2 | npc_papeleria | VENDEDOR | Main/Piso2/SalaImpresiones/EncargadoPapeleria/CharacterVisual | Humano 6.3 |  |
| 2 | bibliotecaria | BIBLIOTECARIA | Main/Piso2/Biblioteca/BossBibliotecaria/@Node3D@326 | Humano 6.3 |  |
| 3 | ProfesorRedes | Ver script | Main/Piso3/EncuentroProfesorRedes/ProfesorRedes/@Node3D@436 | Visual heredado oculto; conservar |  |
| 3 | profesor_datos | DATOS | Main/Piso3/profesor_datos/CharacterVisual | Visual heredado oculto; conservar |  |
| 3 | profesor_algoritmos | ALGORITMOS | Main/Piso3/profesor_algoritmos/CharacterVisual | Visual heredado oculto; conservar |  |
| 4 | docente_enfermeria | ENFERMERIA | Main/Piso4/docente_enfermeria/CharacterVisual | Visual heredado oculto; conservar |  |
| 4 | docente_odontologia | ODONTOLOGIA | Main/Piso4/docente_odontologia/CharacterVisual | Visual heredado oculto; conservar |  |
| 4 | coordinador_profesores | COORDINADOR | Main/Piso4/coordinador_profesores/CharacterVisual | Visual heredado oculto; conservar |  |
| 6 | profesor_ingles | INGLES | Main/Piso6/profesor_ingles/CharacterVisual | Visual heredado oculto; conservar |  |
| 6 | profesor_etica | ETICA | Main/Piso6/profesor_etica/CharacterVisual | Visual heredado oculto; conservar |  |
| 7 | profesor_lenguaje | LENGUAJE | Main/Piso7/profesor_lenguaje/CharacterVisual | Visual heredado oculto; conservar |  |
| 7 | profesor_matematicas | MATEMATICAS | Main/Piso7/profesor_matematicas/CharacterVisual | Visual heredado oculto; conservar |  |
| 8 | director | DIRECTOR | Main/Piso8/EncuentroDirectorInformatica/DirectorInformaticaBoss/VisualDirectorFicticio | Visual heredado oculto; conservar |  |
| 2 | Player | Ver script | Main/GameplayManager/Player/CharacterVisual | Protagonista 6.2 + pies 6.3 |  |
| 1 | guard:Exterior/Caseta/PuestoRegistro/GuardiaRegistro | GUARDIA | Main/Exterior/Caseta/PuestoRegistro/GuardiaRegistro/@Node3D@3978 | Humano 6.3 |  |
| 1 | guard:Exterior/EntradaReferenciaDuoc/GuardiasTorniquetes/Guardia1 | GUARDIA | Main/Exterior/EntradaReferenciaDuoc/GuardiasTorniquetes/Guardia1/@Node3D@4176 | Humano 6.3 |  |
| 1 | guard:Exterior/EntradaReferenciaDuoc/GuardiasTorniquetes/Guardia2 | GUARDIA | Main/Exterior/EntradaReferenciaDuoc/GuardiasTorniquetes/Guardia2/@Node3D@4255 | Humano 6.3 |  |
| 1 | Auxiliar | FUNCIONARIO | Main/CampusCampaign/Auxiliar/CharacterVisual | Humano 6.3 | [E] Hablar con Auxiliar |
| 2 | Estudiante | ESTUDIANTE | Main/CampusCampaign/Estudiante/CharacterVisual | Humano 6.3 | [E] Hablar con Estudiante |
| 3 | Profesor | PROFESOR | Main/CampusCampaign/Profesor/CharacterVisual | Humano 6.3 | [E] Hablar con Profesor |
| 5 | Funcionario | FUNCIONARIO | Main/CampusCampaign/Funcionario/CharacterVisual | Humano 6.3 | [E] Hablar con Funcionario |
| 1 | MonitorDeportes | ESTUDIANTE | Main/CampusCampaign/MonitorDeportes/CharacterVisual | Humano 6.3 | [E] Hablar con MonitorDeportes |
| 3 | Tecnico | TECNICO | Main/CampusCampaign/Tecnico/CharacterVisual | Humano 6.3 | [E] Hablar con Tecnico |
| 1 | EstudiantePerdido | ESTUDIANTE | Main/CampusCampaign/EstudiantePerdido/CharacterVisual | Humano 6.3 | [E] Hablar con EstudiantePerdido |
| 1 | AyudanteCasino | VENDEDOR | Main/CampusCampaign/AyudanteCasino/CharacterVisual | Humano 6.3 | [E] Hablar con AyudanteCasino |
| 1 | EnemigoPiso1 | Ver script | Main/CampusCampaign/EnemigoPiso1/@Node3D@6015 | Simulación digital; conservar |  |
| 2 | EnemigoPiso2 | Ver script | Main/CampusCampaign/EnemigoPiso2/@Node3D@6100 | Simulación digital; conservar |  |
| 3 | EnemigoPiso3 | Ver script | Main/CampusCampaign/EnemigoPiso3/@Node3D@6185 | Simulación digital; conservar |  |
| 4 | EnemigoPiso4 | Ver script | Main/CampusCampaign/EnemigoPiso4/@Node3D@6270 | Simulación digital; conservar |  |
| 5 | EnemigoPiso5 | Ver script | Main/CampusCampaign/EnemigoPiso5/@Node3D@6355 | Simulación digital; conservar |  |
| 6 | EnemigoPiso6 | Ver script | Main/CampusCampaign/EnemigoPiso6/@Node3D@6440 | Simulación digital; conservar |  |
| 7 | EnemigoPiso7 | Ver script | Main/CampusCampaign/EnemigoPiso7/@Node3D@6525 | Simulación digital; conservar |  |
| 8 | EnemigoPiso8 | Ver script | Main/CampusCampaign/EnemigoPiso8/@Node3D@6610 | Simulación digital; conservar |  |
| -1 | EnemigoPiso9 | Ver script | Main/CampusCampaign/EnemigoPiso9/@Node3D@6695 | Simulación digital; conservar |  |
| 3 | v4_rescued_student | ESTUDIANTE | Main/CampusCampaign/DuocGames4/@Node@8144/@CharacterBody3D@8159/@Node3D@8161 | Humano 6.3 |  |
| -1 | v4_civilian_-1 | ESTUDIANTE | Main/CampusCampaign/DuocGames4/@Node@8298/@CharacterBody3D@8299/@Node3D@8301 | Humano 6.3 | [E] Conversar · estudiante |
| 1 | v4_civilian_1 | ESTUDIANTE | Main/CampusCampaign/DuocGames4/@Node@8298/@CharacterBody3D@8394/@Node3D@8396 | Humano 6.3 | [E] Conversar · estudiante |
| 2 | v4_civilian_2 | ESTUDIANTE | Main/CampusCampaign/DuocGames4/@Node@8298/@CharacterBody3D@8482/@Node3D@8484 | Humano 6.3 | [E] Conversar · estudiante |
| 3 | v4_civilian_3 | ESTUDIANTE | Main/CampusCampaign/DuocGames4/@Node@8298/@CharacterBody3D@8579/@Node3D@8581 | Humano 6.3 | [E] Conversar · estudiante |
| 4 | v4_civilian_4 | ESTUDIANTE | Main/CampusCampaign/DuocGames4/@Node@8298/@CharacterBody3D@8669/@Node3D@8671 | Humano 6.3 | [E] Conversar · estudiante |
| 5 | v4_civilian_5 | ESTUDIANTE | Main/CampusCampaign/DuocGames4/@Node@8298/@CharacterBody3D@8757/@Node3D@8759 | Humano 6.3 | [E] Conversar · estudiante |
| 3 | v4_lab_student | ESTUDIANTE | Main/CampusCampaign/DuocGames4/@Node@8298/@CharacterBody3D@8860/@Node3D@8862 | Humano 6.3 | [E] Conversar · estudiante |
| 6 | profesor_ingles | INGLES | Main/CampusCampaign/Mentor_profesor_ingles/@Node3D@8971 | Humano 6.3 |  |
| 7 | profesor_lenguaje | LENGUAJE | Main/CampusCampaign/Mentor_profesor_lenguaje/@Node3D@9096 | Humano 6.3 |  |
| 6 | profesor_etica | ETICA | Main/CampusCampaign/Mentor_profesor_etica/@Node3D@9212 | Humano 6.3 |  |
| 3 | profesor_datos | PROFESOR | Main/CampusCampaign/Mentor_profesor_datos/@Node3D@9326 | Humano 6.3 |  |
| 3 | profesor_algoritmos | PROFESOR | Main/CampusCampaign/Mentor_profesor_algoritmos/@Node3D@9451 | Humano 6.3 |  |
| 4 | docente_enfermeria | ENFERMERIA | Main/CampusCampaign/Mentor_docente_enfermeria/@Node3D@9579 | Humano 6.3 |  |
| 4 | docente_odontologia | ODONTOLOGIA | Main/CampusCampaign/Mentor_docente_odontologia/@Node3D@9684 | Humano 6.3 |  |
| 4 | coordinador_profesores | PROFESOR | Main/CampusCampaign/Mentor_coordinador_profesores/@Node3D@9789 | Humano 6.3 |  |
| 7 | profesor_matematicas | PROFESOR | Main/CampusCampaign/Mentor_profesor_matematicas/@Node3D@9913 | Humano 6.3 |  |
| 1 | punto | FUNCIONARIO | Main/CampusCampaign/Mentor_punto/@Node3D@10038 | Humano 6.3 |  |
| 1 | chef | VENDEDOR | Main/CampusCampaign/Mentor_chef/@Node3D@10150 | Humano 6.3 |  |
| 3 | profesor_redes | PROFESOR | Main/CampusCampaign/Mentor_profesor_redes/@Node3D@10267 | Humano 6.3 |  |
| 8 | director | DIRECTOR | Main/CampusCampaign/Mentor_director/@Node3D@10381 | Humano 6.3 |  |
