# PLAYTEST Y BALANCE 1.0

## Estado vigente — expansión académica 3.0, 19-10-2026

La distribución anterior es histórica. Ahora hay 15 bosses: se conservan nueve y se añaden Datos 500 HP, Algoritmos 525, Enfermería 475, Odontología 475, Coordinador 500 y Matemáticas 525. Inglés 450 y Ética 550 se trasladan al 6; Lenguaje se presenta como Habilidades de Comunicación en 7 conservando profesor_lenguaje/500. Chef sigue 350, Director 700, NEXO 1200; no se modifican sus estadísticas. Todos los valores nuevos siguen **PENDIENTES DE PLAYTEST HUMANO**.

No se retocan tablas base de armas, consumibles, enemigos, precios, XP ni créditos. Los premios dan efectos pequeños al poseerlos. Los bosses usan el premio común existente de 75 créditos/150 XP. Se exige Datos **o** Algoritmos, no ambos; los demás profesores nuevos son opcionales. Director exige tres pruebas previas, con compatibilidad para victorias antiguas. IDs, fases, efectos, límites y migración: [ACADEMIC_BOSSES_3_0.md](ACADEMIC_BOSSES_3_0.md). No extrapolar duración humana desde pruebas sintéticas.

**Actualización 16-10-2026:** se implementó CIERRE DE CAMPAÑA 1.0. NEXO existe ahora y sigue **PENDIENTE DE BALANCE HUMANO**. La auditoría del 15-10 siguiente se conserva como estado anterior; sus referencias a «NEXO no existe» y al archivo como final son históricas. Estado actual y cambios al final de este documento y en [CIERRE_CAMPANA_1_0.md](CIERRE_CAMPANA_1_0.md).

Fecha: 2026-10-15. Referencia: scripts, recursos, Main.tscn y ejecución aislada de tests/balance_audit.gd. No es un playthrough humano. Los cambios anteriores se conservan.

## Fase 1: estado inicial, sin ajustes

15 misiones: 9 principales, 6 secundarias; Documentos importantes es necesaria para el acceso 7. Cinco bosses, 23 armas de catálogo, 51 pickups de armas y 779 fuentes de sillas. Doce centros de vida, seis checkpoints y snapshot pre-duelo. Siete computadores obligatorios y uno secreto. QA de referencias: cero errores; esto no demuestra conectividad física.

Estimación analítica inicial: principal 1–2,5 h; principal y secundarias 2–4 h; contenido disponible completo 3–6 h. Postgame abierto sin duración cerrada. Componentes aproximados: traslado 20–45 min, encuentros 10–25, computadores 8–20, conversaciones/gestión 10–20, orientación/exploración adicional 12–40. Son hipótesis que se solapan y dependen de errores, lectura y rutas, no cronometrajes. Tres clases opcionales dependen del reloj y pueden añadir espera. No se fuerza la referencia de 5–8 horas.

## RUTA CRÍTICA

Nueva partida → hablar con Punto + recoger objeto + pc_intro → Punto y Chef → biblioteca + 3 LibroBiblioteca + Bibliotecaria → pc3 → pc4 → pc5 → pc6 → TarjetaAcceso (aceptar documentos con Profesor del 3, entregar a Funcionario del 5) → puerta acceso7 + pc7 → pc8 + Director → archivo_subterraneo en −1.

El Profesor de Redes es opcional. No se encontró boss NEXO, Profesor de Programación, bosses académicos adicionales, Boss Rush, NG+ ni selector Historia/Normal/Difícil. Tampoco taller de reparación/mejora de armas. No se implementan sustitutos en esta etapa. La ruta solicitada «hasta NEXO» no puede completarse en esta versión; el cierre real es el archivo.

## Hallazgos y registro de cambios

| ID | Severidad | Antes | Después aplicado | Razón / evidencia |
|---|---|---|---|---|
| B01 | CRITICAL | NPC marca provided antes de receive_item, que puede rechazar mochila llena | Reutilizar entrega garantizada existente y recuperar entrega pendiente | Documentos necesarios para TarjetaAcceso; riesgo de bloqueo permanente |
| B02 | HIGH | progress consulta eventos para boss aunque bosses[id] sea true | Aceptar estado persistido de derrota como ya ocurre con computadores | Compatibilidad de guardados antiguos sin evento redundante |
| B03 | HIGH | add_item informa total poseído; comprueba capacidad solo antes del lote | Devolver cantidad realmente añadida y respetar capacidad por entrada | Falsos éxitos de compra/recogida y lotes que exceden mochila |
| B04 | HIGH | save_game captura consumibles/vida intermedios del duelo | Serializar snapshot previo durante intro/combate/derrota pendiente | Cerrar/cargar no debe mezclar boss neutral con inventario agotado y posición de arena |
| B05 | MEDIUM | notify reemplaza mensaje anterior | Cola acotada por prioridad y deduplicación | Misiones y recompensas se pierden visualmente con avisos simultáneos |
| B06 | LOW | Escaneo contextual consulta métodos de objetos de otros pisos antes de descartarlos | Descartar piso antes de consultas | 779 sillas; mantener frecuencia y lógica |
| B07 | MEDIUM | Tutorial avanza mientras hay modal/boss/mensaje | Esperar oportunidad tranquila | Evitar perder explicaciones durante creación/diálogo |

Este registro se escribió antes de modificar código. B01–B07 están aplicados; evidencia y límites a continuación. No se ajustaron estadísticas sin evidencia suficiente.

## PLAYER BASELINE (valores conservados)

Fuente: player.gd, player_combat.gd y campus_campaign.apply_upgrades. HP 100; caminar 2,5 m/s; correr 5,5; agachado 1,3; salto 5; gravedad 14. Estamina 100, regeneración 22/s, correr 14/s (7,14 s desde lleno), recuperación completa 4,55 s. Esquiva: coste 25, cooldown 0,7 s, movimiento/invulnerabilidad 0,22 s; no ventana adicional de Perfect Dodge implementada. Ataque normal sin arma 10, cooldown 0,32 s, animación 0,5 s con alternancia de brazos. Arma: cooldown mínimo 0,45 s y duración propia. Ataque fuerte: carga ≥0,45 s, coste 30, daño ×1,8, duración de golpe ×1,4. No hay coste por clase ni peso funcional. Sin bloqueo/parry, combos o resistencias defensivas implementadas en la lógica; sus estados visuales no son mecánicas.

Fuerza: +5% por mejora, máximo +25%, un multiplicador sin acumulación exponencial. Velocidad: +5% por mejora, máximo +25%; energética ×1,35 renovable, no acumulativa. Máximo correr con ambas: 9,28 m/s, pendiente comprobar escaleras/colisiones. Vida +20 por mejora (5); resistencia +20 (5); mochila 64 entradas +16 por mejora, máximo 144. Las recompensas usan la excepción de capacidad existente para no perder claves.

## ARMAS: instancias reales, no solo valores base del catálogo

Las clases LIGHT/MEDIUM/HEAVY/THROWABLE/SPECIAL no existen como atributo de combate en esta versión; «ND» lo indica sin inventar clasificación. Estamina: 0 normal / 30 fuerte para todas. Peso: no definido. DPS ideal = daño / max(0,45, swing), sin traslados, stagger, esquiva, carga o agotamiento de durabilidad. No equivale a DPS humano. Rareza ya aplicada por la instancia.

| ID | Nombre | Clase | Rareza | Daño | s/golpe | Durabilidad | Estamina | Peso | Especial | DPS ideal |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Palo | Palo | ND | COMÚN | 22 | 0.6 | 14 | 0 / 30 | ND | — | 36.67 |
| Silla | Silla | ND | COMÚN | 34 | 0.75 | 4 | 0 / 30 | ND | — | 45.33 |
| Bate | Bate de béisbol | ND | COMÚN | 30 | 0.65 | 12 | 0 / 30 | ND | — | 46.15 |
| Raqueta | Raqueta de tenis | ND | COMÚN | 24 | 0.55 | 10 | 0 / 30 | ND | — | 43.64 |
| PelotaBasquetbol | Pelota de básquetbol | ND | COMÚN | 18 | 0.5 | 16 | 0 / 30 | ND | Lanzable | 36 |
| PelotaBeisbol | Pelota de béisbol | ND | COMÚN | 20 | 0.45 | 16 | 0 / 30 | ND | Lanzable | 44.44 |
| PelotaTenis | Pelota de tenis | ND | COMÚN | 14 | 0.4 | 16 | 0 / 30 | ND | Lanzable | 31.11 |
| PelotaFutbol | Pelota de fútbol | ND | COMÚN | 20 | 0.5 | 16 | 0 / 30 | ND | Lanzable | 40 |
| PelotaRugby | Pelota de rugby | ND | COMÚN | 22 | 0.55 | 14 | 0 / 30 | ND | Lanzable | 40 |
| Disco | Disco volador | ND | COMÚN | 18 | 0.45 | 14 | 0 / 30 | ND | Lanzable | 40 |
| PaletaPingPong | Paleta de ping-pong | ND | POCO COMÚN | 20 | 0.48 | 22 | 0 / 30 | ND | — | 41.67 |
| Escoba | Escoba | ND | COMÚN | 24 | 0.7 | 30 | 0 / 30 | ND | — | 34.29 |
| Bandeja | Bandeja | ND | POCO COMÚN | 30.8 | 0.7 | 28 | 0 / 30 | ND | Lanzable | 44 |
| LibroPesado | LibroPesado | ND | POCO COMÚN | 33 | 0.7 | 25 | 0 / 30 | ND | — | 47.14 |
| Herramienta | Herramienta | ND | POCO COMÚN | 37.4 | 0.7 | 31 | 0 / 30 | ND | — | 53.43 |
| Teclado | Teclado | ND | RARA | 40 | 0.7 | 32 | 0 / 30 | ND | — | 57.14 |
| NotebookRoto | NotebookRoto | ND | RARA | 50 | 0.7 | 25 | 0 / 30 | ND | — | 71.43 |
| Cable | Cable | ND | POCO COMÚN | 26.4 | 0.7 | 36 | 0 / 30 | ND | — | 37.71 |
| LlaveInglesa | LlaveInglesa | ND | RARA | 55 | 0.7 | 44 | 0 / 30 | ND | — | 78.57 |
| ExtintorDorado | ExtintorDorado | ND | ESPECIAL | 67.2 | 0.7 | 63 | 0 / 30 | ND | — | 96 |
| BandejaDelChef | BandejaDelChef | ND | ESPECIAL | 58.8 | 0.7 | 56 | 0 / 30 | ND | Única; lanzable | 84 |
| PaletaProfesional | PaletaProfesional | ND | ESPECIAL | 39.2 | 0.45 | 54 | 0 / 30 | ND | Única; lanzable | 87.11 |
| TecladoAdministrador | TecladoAdministrador | ND | ESPECIAL | 58.8 | 0.7 | 56 | 0 / 30 | ND | Tecnología ×1,35 | 84 |

Palo: alcance 1,9 y 14 impactos; Silla: 1,7 y 4 impactos, 136 de daño total nominal. Bate: alcance 2,2, 12 impactos. Paleta normal: 20/0,48, 22 impactos; profesional: 39,2/0,45, 54 impactos. Bandeja del Chef: 58,8, 56 impactos; Teclado Administrador: 58,8, 56 impactos, 79,38 contra tecnología. Las únicas tienen utilidad sin necesitar ser todas las más rápidas. Extintor Dorado alcanza 67,2: puede eliminar de un golpe enemigos rápidos de pisos anteriores. Es una recompensa/objeto fuerte, no el comportamiento de todas las armas comunes.

Nicho débil a revisar: Cable comparte velocidad con otras armas modulares; gana durabilidad, pero pierde daño. La tienda ofrece Silla por 25 frente a Palo por 20 pese a cientos de sillas gratis: compra poco atractiva, no exploit de reventa. No se elimina la silla ni se igualan armas. No existe venta, reparación ni mejora +1/+2/+3: no inventar costes ni simular ese taller.

## ENEMIGOS, TTK y golpes soportados

TTK ideal de arma = (ceil(HP/daño)−1) × max(0,45,swing) + 0,5 × swing. Incluye el primer impacto a mitad de animación, sin trayecto, reacción o stagger. Puede requerir cambiar arma por durabilidad. El 9 de nombre interno corresponde a −1, cuyo escalado usa floor_number=10. No se mueve ningún encuentro.

| Piso | Variante | HP | Daño | Golpes letales a 100 HP | Palo | LibroPesado | ExtintorDorado |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | NORMAL | 68 | 6 | 17 | 4 golpes / 2.1 s | 3 golpes / 1.75 s | 2 golpes / 1.05 s |
| 2 | NORMAL | 76 | 7 | 15 | 4 golpes / 2.1 s | 3 golpes / 1.75 s | 2 golpes / 1.05 s |
| 3 | RÁPIDO | 54.6 | 8 | 13 | 3 golpes / 1.5 s | 2 golpes / 1.05 s | 1 golpes / 0.35 s |
| 4 | PESADO | 156.4 | 12.6 | 8 | 8 golpes / 4.5 s | 5 golpes / 3.15 s | 3 golpes / 1.75 s |
| 5 | DISTANCIA | 100 | 10 | 10 | 5 golpes / 2.7 s | 4 golpes / 2.45 s | 2 golpes / 1.05 s |
| 6 | RÁPIDO | 70.2 | 11 | 10 | 4 golpes / 2.1 s | 3 golpes / 1.75 s | 2 golpes / 1.05 s |
| 7 | PESADO | 197.2 | 16.8 | 6 | 9 golpes / 5.1 s | 6 golpes / 3.85 s | 3 golpes / 1.75 s |
| 8 | TECNOLÓGICO | 124 | 13 | 8 | 6 golpes / 3.3 s | 4 golpes / 2.45 s | 2 golpes / 1.05 s |
| −1 | PESADO | 238 | 21 | 5 | 11 golpes / 6.3 s | 8 golpes / 5.25 s | 4 golpes / 2.45 s |

Los nueve encuentros están separados y limitados a 12 m de su origen. Los enemigos de distancia/tecnología disparan cada 3,2 s entre 4 y 12 m y con visión. El pesado del 4 tiene 156,4 HP frente a 54,6 del rápido del 3: salto de resistencia por rol; revisar experiencia antes de reducirlo. No se encontró coordinador CHASER/FLANKER/HEAVY: no afirmar que existe cooperación de ese tipo. Sigilo sí usa visión/ruido/postura y distracciones; la ruta física de evasión queda pendiente.

## BOSSES revisados

Las cinco definiciones y controladores existen. Recompensa base por victoria: 75 créditos / 150 XP una vez, más recompensa propia; curación completa. Las duraciones siguientes son límites ofensivos ideales usando Palo, no tiempos de primera victoria ni objetivos de diseño. La disponibilidad de golpes, esquivas, cambios de arma, invocaciones y routers puede multiplicarlos.

| ID / Nombre | Piso | HP | Daño | Velocidad | Fases | Ataques | Cooldown | Ventaja | Recompensa extra | Tiempo analítico |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| punto / Encargado | 1 | 200 | 10 melee / 12 lanzamiento | 2,6 | Una | Melee / deportes | 1,2 / 2,4 s | Esquivar trayectoria | PaletaProfesional | ~5,7 s (10 impactos; una arma) |
| chef / Chef Supremo | 1 | 450 | 18/22/26 melee; 14/18 bandeja | 2,2/2,7/3,2 | 60% / 30% | Melee + bandeja desde fase 2 | 1,35/1/0,75; bandeja 3,5/2,5 s | Acercarse tras lanzamiento | BandejaDelChef + LlaveCasino | ~12,3 s; necesita 21 golpes y reponer Palo |
| bibliotecaria / Bibliotecaria | 2 | 125 | 25 por error | No combate físico | Quiz | 16 preguntas en banco; 5 aciertos | Sin límite global | Leer y repetir tras derrota | LibroEspecial | Hipótesis 2–5 min leyendo, no medido |
| profesor_redes / Profesor de Redes | 3 (opcional) | 550 | Melee 16/18/22; paquetes 12/15/18; pulso 8/10/12; pérdida 20 | 2,2/2,6/3,1 | 65% / <30% | Routers / paquetes / pulso / interferencia / conexión | Paquete 3,2/2,5/1,4; pulso 7; zona 8; pérdida 9 s | Desconectar routers con E | RouterPortatil | ~14,7 s sin escudo; ~50,1 s si 70% reducción constante; cambios de arma no incluidos |
| director / Director Informática | 8 | 700 | 20/24/32 melee; 16/20/25 digital; azul 36 | 2,6/3/3,6 | 60% / 30% | Melee / digital / dos virus / azul | Melee 1,3/1,1/0,8; digital 3/2,6/2,1; azul 7 s | USB y salir del círculo | CredencialDirector + TecladoAdministrador | ~18,9 s ideales; 32 impactos y cambios de Palo |

**HIGH pendiente de playtest:** los mínimos ofensivos son muy inferiores a 2–6 minutos. Las armas especiales y ataques fuertes pueden acortarlos aún más. No multiplicar HP para compensar sin medir disponibilidad de golpes y diversión. Tomar primera victoria, segundo intento y victoria con arma única; comparar porcentaje de tiempo golpeando. No son combates de 2–6 minutos demostrados.

Redes: factores de daño [1; 0,75; 0,5; 0,3] según 0–3 routers activos. E desconecta instantáneamente a 2,3 m, sin canalización. Reactiva un router una sola vez en fase 2, prueba cada 4 s. Pérdida de Conexión: aviso naranja de 1,2 s, radio 6 m, 20 daño y ralentización ×0,65 durante 3 s solo si hubo daño. No es obligatorio soportar todo el escudo pegando. Director: USB base 40 × debilidad 2 = 80 (11,4% de 700) + stun 3 s; cancela especiales configurados, no elimina automáticamente la pelea. Dos virus se invocan una sola vez al 60%, no invocación continua. Pantallazo Azul: 1,2 s de aviso, 36 daño, 7 s de cooldown. Chef mantiene bandejas y curación total. Bibliotecaria conserva feedback, reintento y preguntas; cuatro errores son letales a vida base, cinco aciertos bastan. No se exige quiz perfecto para siempre.

Señales: animaciones previas, discos de área, mensaje de especial y proyectiles. No se encontraron archivos de música/efectos externos; solo tonos procedurales del campus, por lo que mezcla musical y señales sonoras de cada ataque quedan pendientes. No declarar audio de boss validado.

## CURACIÓN y consumibles (sin ajustes de valores)

| ID | Efecto | Precio créditos | Stack máximo | Cooldown | Frecuencia conocida |
| --- | --- | --- | --- | --- | --- |
| Bebida | 10 HP | 5 | 999 | Sin cooldown | Máquinas/vendedor |
| Comida | 30 HP | 10 | 999 | Sin cooldown | Máquinas + 5 pickups de piso |
| Botiquin | 50 HP | 25 | 999 | Sin cooldown | Vendedor + 4 pickups + misión llaves |
| ColacionEspecial | Toda la vida | No en tiendas estándar | 999 | Sin cooldown | Contenido/prop disponible según escena |
| BebidaEnergetica | +35% velocidad / 12 s | 12 | 999 | Renueva, no acumula | Máquinas + misión cargador |

Comida ofrece 3 HP/crédito, Bebida y Botiquín 2 HP/crédito; Botiquín concentra curación en una pulsación. Cada computador completado también cura 25 HP una vez (GameplayManager.TASK_HEAL); los siete obligatorios ofrecen hasta 175 HP potenciales adicionales, sin reserva si ya se está lleno. Doce centros gratuitos reutilizables y victoria de boss curan al máximo; durante duelo el centro está bloqueado. Enemigos normales fuera de duelo no bloquean curación: MEDIUM, medir posibilidad de abusar retirándose. No se añade cooldown universal ni se cobra por centros sin playtest. Consumibles pueden usarse seguidos: revisar quickslots y riesgo de consumo durante animaciones. No consumen a vida completa.

## XP, CRÉDITOS y mejoras

Nivel = 1 + floor(XP / 150); requisito acumulado nivel N = (N−1)×150. Cada nivel añade 5 HP, no daño automático. Misiones principales: 630 créditos / 1130 XP. Documentos, obligatoria por dependencia: 40 / 70. Cuatro bosses obligatorios: 300 / 600. Siete PCs: 140 / 175. Archivo final: 25 / 40 por descubrimiento. Bienvenida: 30 créditos. Suma analítica principal sin enemigos/otros secretos: **1165 créditos / 2015 XP, nivel 14**, antes de gastos. Asume completar contenido una vez y activar sus handlers, no es una partida medida.

Niveles aproximados sin opcionales, contando documentos al llegar al 5: entrada 1; tras primer piso 3; llegada 3 ~5; llegada 5 ~7; llegada 8 ~10; tras Director ~12; archivo final 14. El orden de entrega y combates normales cambia estos números. En esta versión «llegada a NEXO» no aplica.

Cinco mejoras, cinco niveles cada una: precios 60/100/140/180/220; total por rama 700, conjunto 3500. La principal no financia todo. Una reparación básica no puede comprarse porque no hay reparación. Nueve enemigos normales añaden hasta 45/90 por limpieza; reaparecen al recargar, recompensa solo protegida por instancia: farming por recarga posible, rentabilidad humana pendiente. No se cambia respawn ni se quitan ingresos sin medir.

Seis secundarias juntas: 165 créditos / 265 XP; documentos ya contada en principal. Quinto boss opcional: +75/150. Veinte tarjetas: 100/200 y bonus final 200/300. Tres secretos adicionales: 75/120. PC secreto: 20/25 + USBMaestro, sin XP extra por su evento de secreto. Tres asistencias: máximo 30/75 por tipo de clase, no por día (ledger). Eventos: presupuesto global 24 créditos, 3 por ayuda exitosa, 5 XP por ayuda; no multiplicar por número de días. Aproximación principal + todo lo anterior, excluyendo eventos y farming: **1790 créditos / 3080 XP, nivel 21**, Incluyendo una limpieza de los nueve enemigos normales: 1835 créditos / 3170 XP, nivel 22. Hay variación por invocaciones y otros servicios. No es un máximo universal.

No hay venta de sillas, por tanto 779 sillas no equivalen a ingresos infinitos. Su oferta sí reduce necesidad de comprar armas. Regalos/secretos y recompensas usan IDs; la nueva regresión conserva idempotencia. La tienda ya rechaza pago cuando no entra un objeto; B03 corrige el falso éxito de stack lleno.

## MISIONES (duraciones como hipótesis, no cronometraje)

| ID | Nombre | Tipo | Piso | Pasos | Recompensa | Duración estimada | Necesaria |
| --- | --- | --- | --- | --- | --- | --- | --- |
| inicio | Primer día | Principal | 1 | Habla con Punto Estudiantil; Recoge tu primer objeto; Completa el computador inicial; Derrota al Encargado; Habla y vence al Chef | {"credits": 60, "unlock": "2", "xp": 100} | 15–35 min | Sí |
| biblioteca | La guardiana del conocimiento | Principal | 2 | Visita la biblioteca; Busca tres libros; Supera el duelo de preguntas | {"credits": 60, "unlock": "3", "xp": 120} | 8–20 | Sí |
| academico3 | Etapa académica · Piso 3 | Principal | 3 | Llega al piso 3; Resuelve el desafío académico | {"credits": 40, "unlock": "4", "xp": 80} | 4–10 | Sí |
| academico4 | Etapa académica · Piso 4 | Principal | 4 | Llega al piso 4; Resuelve el desafío académico | {"credits": 40, "unlock": "5", "xp": 80} | 4–10 | Sí |
| academico5 | Etapa académica · Piso 5 | Principal | 5 | Llega al piso 5; Resuelve el desafío académico | {"credits": 40, "unlock": "6", "xp": 80} | 4–10 | Sí |
| seguridad6 | Práctica avanzada | Principal | 6 | Completa el desafío de seguridad | {"credits": 60, "unlock": "7", "xp": 100} | 4–10 | Sí |
| acceso7 | Acceso restringido | Principal | 7 | Abre el acceso restringido del Piso 7; Completa el computador del Piso 7 | {"credits": 80, "unlock": "8", "xp": 120} | 5–15 (+documentos) | Sí |
| direccion | Modo Administrador | Principal | 8 | Resuelve el desafío tecnológico; Habla y vence al Director | {"credits": 150, "unlock": "S", "xp": 250} | 8–20 | Sí |
| postgame | Archivos del subterráneo | Principal | −1 | Encuentra el archivo del subterráneo | {"credits": 100, "xp": 200} | 5–15 | Sí |
| llaves | Las llaves perdidas | Secundaria | 1↔4 | Entrega las llaves al auxiliar | {"credits": 25, "items": {"Botiquin": 1}, "xp": 40} | 5–12 | No |
| cargador | El cargador | Secundaria | 2↔3 | Entrega el cargador | {"credits": 20, "items": {"BebidaEnergetica": 1}, "xp": 30} | 4–8 | No |
| documentos | Documentos importantes | Secundaria | 3→5 | Entrega los documentos | {"credits": 40, "items": {"TarjetaAcceso": 1}, "xp": 70} | 5–12 | Sí (dependencia) |
| implementos | Implementos perdidos | Secundaria | 1,3–5 | Devuelve los tres implementos | {"credits": 35, "items": {"PaletaPingPong": 1}, "xp": 50} | 8–18 | No |
| infectado | Computador infectado | Secundaria | 3 | Elimina los virus | {"credits": 30, "items": {"USBInfectado": 1}, "xp": 50} | 2–6 (solapa pc3) | No |
| casino | Ayuda en el casino | Secundaria | 1 | Inicia el duelo con el Chef | {"credits": 15, "xp": 25} | 1–3 (solapa Chef) | No |

## MINIJUEGOS, PACING ISSUE y primera hora

Archivos: 6–8 elecciones según piso, sin temporizador global; hipótesis 30–90 s. Antivirus: 8–12 aciertos, máximo dos virus simultáneos, ventana 1,6→mínimo 1,3 s y aparición 0,7→mínimo 0,55 s; hipótesis 20–90 s con errores. Contraseña: cuatro dígitos hasta piso 6, cinco desde 7; memorizar 3,2–4 s o 5 s, reintento 3 s; hipótesis 15–60 s por sesión. No son minijuegos obligatorios de cinco minutos demostrados. Recompensa de PC 20/25 una vez; no farm al repetir uno completado.

Actividades actuales: asistencia Programación/Redes (piso 3) e Inglés (5), opcionales, sin bloquear principal por nota/falta. No hay batería adicional de ClassroomChallenge/quiz Salud/Ética/Talleres que auditar. El reloj usa 10 s reales/minuto, arranca 08:50: día completo 4 h reales; jornada 09–18 dura 90 min. Inglés 14:00 aparece a ~51 min sin pausa: no esperar para terminar campaña.

PACING ISSUE P01 MEDIUM: pisos 3–7 repiten llegar + computador; no reordenar dependencias ni crear contenido en esta etapa. P02 MEDIUM: documentos añade 3→5, posible regreso al 3 si se ignora al profesor; la guía existente lo explica, comprobar encontrabilidad. P03 MEDIUM: entrada a Punto/casino al fondo del campus implica pasillo largo; medir andando y usando ascensor. P04 MEDIUM: UI suma guía/objetivo/nivel/créditos/tarjetas y otros HUD; cola evita avisos perdidos pero falta valorar densidad visual. P05 LOW: clases opcionales pueden inducir espera: horario declara que no bloquean. P06 HIGH: final solicitado NEXO no existe; no vender el archivo como boss/cinemática final.

Primera hora propuesta: movimiento/agacharse/salto → objeto e inventario → pc_intro → conversación y primer duelo → Chef → biblioteca y quiz → piso 3/anomalía/redes opcional. El tiempo real debe anotarse. Momentos existentes: primer duelo, descubrimientos de piso, anomalía tras pc3 o pista Redes, cambios tras pc6/Director, archivo final y restauración. No hay nuevas cinemáticas. Tutorial ahora espera a que no haya modal, boss o avisos pendientes; mantiene cinco consejos.

## CAMPUS VIVO, NPC, UI y rendimiento

Director: gap 90–240 s tras evento, duración variable de 60–180 s (estudio 120), uno simultáneo, gracia de combate 25 s; raro 0,025 por oportunidad elegible, no por segundo ni garantía cada 40 eventos. Debe bloquear boss/modal/minijuego/historia; tests de campus pasan. NORMAL → LOW (pc3/pista) → MEDIUM (pc6) → HIGH (Director) → RESTORED (postgame). NPC de misión permanecen en posiciones estables y el visual usa presets persistidos. No se añaden nuevas rutas ni decenas de NPC.

Sillas por piso: 1=11, 2=67, 3=55, 4=150, 5=28, 6=156, 7=156, 8=156, −1=0 del mobiliario detectado (sí hay pickups de arma silla en manifiesto). 770/779 pasan aproximación local con cápsula y raycast; 9 no pasan los cuatro candidatos ensayados. No demuestra camino desde spawn ni invalida por sí sola esas nueve. Todas se conservan.

Escaneo de interacción, 100 consultas cerca del spawn: media inicial 2001,69 µs; después 605,51 µs (~70% menos en esa muestra), sin cambio de cadencia 0,08 s. Solo se filtra altura antes de métodos y se usa distancia al cuadrado antes de raycast. Test contextual: 60/60. Una tercera ejecución registró 591,46 µs por consulta; la comparación anterior corresponde al primer par de muestras. No es benchmark global de CPU/GPU/FPS.

Carga headless posterior: recurso 3067 ms, instanciar acumulado 3372 ms, total 5577 ms a frame 120; memoria estática 368,11 MiB, 44631 nodos, 73363 objetos, 15844 recursos, 190 objetos de física activos. Renderer configurado gl_compatibility, sin renderizar GPU. Las cifras no son VRAM/RSS/FPS ni comparativa causal de memoria. Main mantiene todos los pisos cargados. Propuesta futura documentada: medir por piso antes de separar escenas/streaming; no hacerlo ahora. CSG, sombras, materiales y luces necesitan profiler gráfico; no se han reescrito.

Ajustes existentes conservados: BAJO LOD cerca/lejos 9/22 m, sin sombras cercanas de personaje y efectos ambientales; MEDIO 13/30, sombras/efectos; ALTO 16/35, sombras/efectos. No equivalen a cambiar todas las sombras del edificio. Límite 30/60/120/0 y ventana/sin bordes/fullscreen persistentes. 1080p/1440p se comprobaron por tamaño lógico en la suite del campus; inspección renderizada pendiente.

## GUARDADO, pruebas y cierre de fases

B01–B03 reproducidos antes: 4/4 expectativas fallaron en balance-reproduce.log; tras corregir, 4/4 pasan en fase 2. Nueva suite final balance_regression: 20 comprobaciones (entrega llena/antigua, cantidad/capacidad/stacks, cola y JSON de duelo). Save version continúa en 2, envelope legacy version=1, migración existente; no formato nuevo ni borrado de partidas. Cerrar durante intro/combate o muerte pendiente serializa estado previo completo de campaña + recursos previos + checkpoint preboss. No continúa combate a medias. Victoria guarda estado actual y ledger una vez. Reintentar checkpoint abandona snapshot; reintento de boss existente conserva consumibles/arma/durabilidad previos. El guardado principal es autoridad al cargar inventario; su archivo auxiliar no reemplaza la campaña.

Resultado por fase: 1 fixture audit + arranque MCP; 2 balance_regression; 3 gameplay_regression; 4 inventory_regression; 5 campaign_regression; 6 Chef/Director/Redes; 7 campaña (recompensa, compra, mejora existente) + lectura de economía; 8 academic_schedule/student_phone; 9 campus_vivo; 10 balance_audit/contextual_interactions; 11 balance_regression/campus_vivo/nueva_partida/guardado_lectura/revision_scripts; 12 documentación + arranque final MCP. Las fases sin cambios de números usaron esas comprobaciones, no nuevos recorridos humanos.

Regresiones ejecutadas: jugador, inventario, campaña (incluye guardado/carga real), Chef, Director, Redes 38, clases 27, celular 31, campus 52, visuales 59, interacciones 60; revisión de 219 scripts/recursos sin fallos. Las advertencias de JSON inválido de guardado_lectura son deliberadas y prueban respaldo; no errores de partida. MCP registró avisos de ventana embebida no redimensionable/movible; revisar modo independiente. Telemetría permanece local y apagada; pruebas usan persist=false o rutas de fixture, sin telemetría humana inventada.

Cambios reales B01–B07 aplicados. Estadísticas de player/armas/consumibles/enemigos/bosses, XP, precios, recompensas y geometría: **sin cambios**. No se ha certificado ausencia de todos los softlocks. Pendientes exactos en PLAYTEST_1_0.md, incluidas rutas físicas, duración, dificultad y diversión. Los hallazgos HIGH de duración de pelea y falta de final NEXO siguen abiertos.

## CIERRE DE CAMPAÑA 1.0 — 16-10-2026

El hallazgo «no existe final NEXO» queda resuelto como implementación, no como balance. Ahora hay 10 principales + 6 secundarias y seis bosses. Ruta nueva: **archivo_subterraneo → revelación guardada → nexo_final: Encuentra el núcleo de NEXO → acceso con progreso y CredencialDirector → elección de duelo → tres fases/enlaces → NEXO derrotado → campaign_completed → RESTORED y postgame**. El archivo conserva ID, estado y recompensas anteriores.

| Cambio | Antes | Después | Motivo |
|---|---|---|---|
| Validador de sillas | Cuatro candidatos a 0,9 m; 770/779 pasan | Cuatro radios hasta 2 m, 16 ángulos, cápsula/rayo/alcance; 779/779 pasan | Los candidatos antiguos se solapaban con sillas/escritorios; no faltaban IDs |
| Nueve sillas | Pendiente local | Recogida real e idempotencia comprobadas | No mover muebles, cambiar IDs ni convertir butacas fijas |
| Cierre | Archivo completaba último objetivo y restauraba campus | Archivo intermedio, una nueva principal y NEXO | Final jugable solicitado sin reconstruir −1 |
| Vida NEXO | No existía | **1200 HP configurables; PENDIENTE DE VALIDACIÓN HUMANA** | ~1,71× Director 700; tres fases con interacción |
| Progresión NEXO | No existía | 70% / 35%; tres enlaces de 18% protección cada uno | Introducción de ataques, aprendizaje y exposición final |
| Daño nuevo | No existía | Paquete 18, pulso 14, zona 10/s tras aviso, borrado 30 | Primera configuración, no balance certificado |
| Borrado | No existía | Aviso 2 s, radio 6,5 m, cooldown 13 s | Amenaza evitable sin muerte instantánea |
| Amenazas | No existía | Máximo 3 proyectiles / 1 zona / 1 preparación; sin repetición inmediata | Evitar saturación |
| RouterPortatil | Efecto reservado | Pasivo contra NEXO: 12% protección/enlace en vez de 18%, sin consumo | Recompensa opcional útil, nunca requisito |
| USBInfectado | Sin compatibilidad NEXO | Contra NEXO: ×1,5 (60 antes de escudo), stun 2 s y cancelación | Reutilizar ItemEffects sin cambiar efecto contra Director |
| Derrota/carga | Reintento genérico existente | Mismo snapshot/retry, reinicio de enlaces y limpieza de amenazas | Conservar cantidades, desgaste y recompensas únicas |
| Estadísticas finales | No había pantalla final | Cálculos de registros existentes y porcentaje explícito sobre 102 entradas | No inventar contadores de armas/tiempos humanos |

Datos: `resources/live/nexo_final.tres`; explicación completa: [CIERRE_CAMPANA_1_0.md](CIERRE_CAMPANA_1_0.md). La recompensa común del nuevo boss es 75 créditos/150 XP, sin recompensa adicional en la nueva misión. No cambiaron las 23 armas, consumibles, nueve enemigos, HP de los cinco bosses anteriores ni precios: comparación automatizada con el reporte histórico. Tampoco se modificaron XP/recompensas anteriores.

Las estimaciones de duración del 15-10 no incluyen el nuevo final; no se asigna duración real a NEXO hasta jugarlo. Sigue abierto el balance humano de todos los bosses. Las nueve sillas están resueltas localmente; falta recorrer sus accesos desde spawn.

Validación: NEXO 111 comprobaciones; balance 20; campus 52; visuales 59; interacciones 60; Redes 38; horario 27; celular 31 y regresiones de campaña/guardado, inventario, gameplay, Chef, Director y nueva partida aprobadas. Revisión de 226 scripts/recursos. Datos nuevos: `reports/closure_balance_data.json`; causas de sillas: `reports/closure_chairs.json`. Ninguna casilla de playtest humano se marca aprobada.

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
## BOSSES DE ACCIÓN Y PERSONAJES — actualización 16-10-2026

Estado actual: 16 misiones existentes y nueve bosses (seis anteriores + Profesor de Inglés/Piso 5, Lenguaje/Piso 6 y Ética/Piso 7). Los nuevos duelos son de acción, voluntarios al aceptar E/diálogo y con fases al 60%/30%; no son cuestionarios. HP iniciales 450/500/550, TODOS PENDIENTES DE PLAYTEST HUMANO. Director existente conserva 700 HP y añade FIREWALL/ACCESO DENEGADO con avisos; Chef permanece en 350 HP. No se cambian armas, consumibles, enemigos normales, precios ni recompensas anteriores. Los nuevos bosses usan premios académicos/cosméticos y el premio estándar existente de boss.

Computadores pc5/pc6/pc7/pc8 mantienen actividades de Inglés/Lenguaje/Ética/documentos NEXO, game_id 0/2/1/2, campaign_id, flags y señales. Son preparación opcional: ENGLISH_PREPARED retrasa 2 s el siguiente ataque tras Word Rush; LECTURA_PREPARADA reduce duración/ralentización de tinta; REFLEXION_PREVIA amplía elección física de zonas de 6 a 10 s; NEXO_INFORMATION reduce HP de los dos virus del Director de 50 a 40 al invocarlos. Las misiones academico5/seguridad6/acceso7/direccion conservan IDs, recompensas y cadena; los bosses pasan a ser su objetivo de acción. Los estados completados antiguos y desbloqueos se conservan. La puerta acceso7 sigue necesitando TarjetaAcceso. No se marca un computador como resuelto por vencer al boss.

Ética usa zonas físicas A (+20% daño, −15% defensa) y B (+20% defensa, −15% daño), sin opción correcta ni preguntas. Los efectos están limitados a su duelo y se limpian al reset. Todos reutilizan BossDuelController, guardado pre-duelo, checkpoint/BossRetry, recursos/arma/desgaste/quickslots, curación y premio único. No se reconstruyen pisos; ubicación con cápsula/suelo/rayos de continuidad. Ninguna prueba automática certifica el recorrido físico humano.

CharacterVisual amplía el rig y adaptador GLB existentes: torso/ojos más discretos, ropa articulada, camisa/sweater/chaqueta/uniforme ficticio/overol, pantalón/calzado, colores de mochila, audífonos/bolso/insignia/dispositivo. Perfiles estables por ID y guardados; no autoequipa premios al protagonista. AnimationTree importado conserva blend de locomoción y transiciones de salto/caída/aterrizaje; sin clips reales se mantiene fallback procedural. BLOCK/PARRY son soporte visual, no nuevas mecánicas. LookAt, diálogo/cámara y LOD se reutilizan; no se descargan assets.

Detalles y scripts: [BOSSES_SUPERIORES_2_0.md](BOSSES_SUPERIORES_2_0.md). Ropa, estados, workflow GLB y assets faltantes: [PERSONAJES_2_0.md](PERSONAJES_2_0.md). Prueba nueva: tests/UpperCampusCheck.tscn; resultados en reports/upper_campus_result.json. Las pruebas humanas siguen pendientes en PLAYTEST_1_0.md. Las secciones anteriores son historial y no deben usarse como valores actuales cuando difieran de esta actualización.
### Validación de esta ampliación

Godot 4.7.2, mediante godot-mcp-toolkit y ejecutable del editor (sin depender de PATH). Preview de nueve roles: sin fallos. Suite nueva UpperCampusCheck: 104 comprobaciones, sin fallos; nueve muestras transitables por arena, neutralidad/aceptación, fases 60/30, proyectiles/zonas con límites y sin daño anticipado, ventajas, elección física A/B, reintento real, premios únicos, guardado/carga, identidad/ropa, LOD y compatibilidad de etapas completadas.

Regresiones aprobadas y verificadas por marcador final del log: personajes (70), personalización, campaña, inventario, gameplay, Director, Chef 350, Campus Vivo (52), balance (20), nueva partida, NEXO (111), interacciones (60), recogidas parciales/guardado previo (74) y carga de 236 scripts/recursos. Logs tests/upper_*.log; los errores deliberados de fixture de escritura no se confunden con errores de partida. No basta el código de salida del ejecutable gráfico de Windows.

Medición orientativa headless: frame 120 a 5133 ms, 377,69 MiB de memoria estática, 45120 nodos; no es FPS gráfico ni comparación controlada con versiones anteriores. Una muestra estabilizada de la fixture renderizada en Piso 5 dio 19 FPS, 58,14 ms de proceso/2,81 ms de física y ~2132 MiB tras dos cargas de Main. Esa muestra no certifica rendimiento general ni 60 FPS: hace falta profiler/recorrido humano con hardware, resolución/calidad y memoria GPU controlados. La muestra de 1 FPS registrada justo al recargar corresponde al pico de carga, no al combate jugable.

Capturas MCP revisaron variantes de ropa y presentación neutral de Inglés. La apariencia continúa procedural/estilizada; no se afirma realismo fotográfico. Quedan manuales todos los casos añadidos al checklist: caminar/saltar/escaleras/armas, ropa y apariencia al cargar, NPC sentados, cámara, combate real con/sin preparación, rutas/puertas/arenas, muerte/reintento mediante UI, lectura de telegraphs, dificultad y FPS. Ninguna casilla humana se marca PASS.
