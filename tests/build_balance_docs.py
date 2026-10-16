"""Render audit tables from the isolated Godot fixture; no gameplay writes."""
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if (ROOT / 'CIERRE_CAMPANA_1_0.md').exists():
    raise SystemExit('Baseline de balance conservado: el cierre tiene documentación posterior; no se sobrescribe.')
data = json.loads((ROOT / 'reports/balance_1_0_data.json').read_text(encoding='utf-8'))
def table(headers, rows):
    return '\n'.join(['| ' + ' | '.join(headers) + ' |', '| ' + ' | '.join(['---'] * len(headers)) + ' |'] + ['| ' + ' | '.join(str(x).replace('|', '/') for x in row) + ' |' for row in rows]) + '\n'
def number(value):
    return f'{value:.2f}'.rstrip('0').rstrip('.')
weapons = {w['id']: w for w in data['actual_weapons']}
rarities = ['COMÚN', 'POCO COMÚN', 'RARA', 'ESPECIAL']
appendix = '''
## PLAYER BASELINE (valores conservados)

Fuente: player.gd, player_combat.gd y campus_campaign.apply_upgrades. HP 100; caminar 2,5 m/s; correr 5,5; agachado 1,3; salto 5; gravedad 14. Estamina 100, regeneración 22/s, correr 14/s (7,14 s desde lleno), recuperación completa 4,55 s. Esquiva: coste 25, cooldown 0,7 s, movimiento/invulnerabilidad 0,22 s; no ventana adicional de Perfect Dodge implementada. Ataque normal sin arma 10, cooldown 0,32 s, animación 0,5 s con alternancia de brazos. Arma: cooldown mínimo 0,45 s y duración propia. Ataque fuerte: carga ≥0,45 s, coste 30, daño ×1,8, duración de golpe ×1,4. No hay coste por clase ni peso funcional. Sin bloqueo/parry, combos o resistencias defensivas implementadas en la lógica; sus estados visuales no son mecánicas.

Fuerza: +5% por mejora, máximo +25%, un multiplicador sin acumulación exponencial. Velocidad: +5% por mejora, máximo +25%; energética ×1,35 renovable, no acumulativa. Máximo correr con ambas: 9,28 m/s, pendiente comprobar escaleras/colisiones. Vida +20 por mejora (5); resistencia +20 (5); mochila 64 entradas +16 por mejora, máximo 144. Las recompensas usan la excepción de capacidad existente para no perder claves.

## ARMAS: instancias reales, no solo valores base del catálogo

Las clases LIGHT/MEDIUM/HEAVY/THROWABLE/SPECIAL no existen como atributo de combate en esta versión; «ND» lo indica sin inventar clasificación. Estamina: 0 normal / 30 fuerte para todas. Peso: no definido. DPS ideal = daño / max(0,45, swing), sin traslados, stagger, esquiva, carga o agotamiento de durabilidad. No equivale a DPS humano. Rareza ya aplicada por la instancia.

'''
rows = []
throwable = {'PelotaBasquetbol','PelotaBeisbol','PelotaTenis','PelotaFutbol','PelotaRugby','Disco','Bandeja','BandejaDelChef','PaletaProfesional'}
for w in weapons.values():
    special = 'Tecnología ×1,35' if w['id'] == 'TecladoAdministrador' else ('Única; lanzable' if w['unique'] and w['id'] in throwable else 'Lanzable' if w['id'] in throwable else 'Única' if w['unique'] else '—')
    rows.append([w['id'],w['name'],'ND',rarities[w['rarity']],number(w['damage']),number(w['swing']),w['durability'],'0 / 30','ND',special,number(w['dps_ideal'])])
appendix += table(['ID','Nombre','Clase','Rareza','Daño','s/golpe','Durabilidad','Estamina','Peso','Especial','DPS ideal'],rows)
appendix += '''
Palo: alcance 1,9 y 14 impactos; Silla: 1,7 y 4 impactos, 136 de daño total nominal. Bate: alcance 2,2, 12 impactos. Paleta normal: 20/0,48, 22 impactos; profesional: 39,2/0,45, 54 impactos. Bandeja del Chef: 58,8, 56 impactos; Teclado Administrador: 58,8, 56 impactos, 79,38 contra tecnología. Las únicas tienen utilidad sin necesitar ser todas las más rápidas. Extintor Dorado alcanza 67,2: puede eliminar de un golpe enemigos rápidos de pisos anteriores. Es una recompensa/objeto fuerte, no el comportamiento de todas las armas comunes.

Nicho débil a revisar: Cable comparte velocidad con otras armas modulares; gana durabilidad, pero pierde daño. La tienda ofrece Silla por 25 frente a Palo por 20 pese a cientos de sillas gratis: compra poco atractiva, no exploit de reventa. No se elimina la silla ni se igualan armas. No existe venta, reparación ni mejora +1/+2/+3: no inventar costes ni simular ese taller.

## ENEMIGOS, TTK y golpes soportados

TTK ideal de arma = (ceil(HP/daño)−1) × max(0,45,swing) + 0,5 × swing. Incluye el primer impacto a mitad de animación, sin trayecto, reacción o stagger. Puede requerir cambiar arma por durabilidad. El 9 de nombre interno corresponde a −1, cuyo escalado usa floor_number=10. No se mueve ningún encuentro.

'''
rows=[]
for i,e in enumerate(data['enemies']):
    ttk=[]
    for wid in ['Palo','LibroPesado','ExtintorDorado']:
        w=weapons[wid]
        n=math.ceil(e['health']/w['damage'])
        ttk.append(f'{n} golpes / {number((n-1)*max(.45,w["swing"])+.5*w["swing"])} s')
    rows.append(['−1' if i==8 else i+1,['NORMAL','NORMAL','RÁPIDO','PESADO','DISTANCIA','RÁPIDO','PESADO','TECNOLÓGICO','PESADO'][i],number(e['health']),number(e['damage']),math.ceil(100/e['damage']),*ttk])
appendix+=table(['Piso','Variante','HP','Daño','Golpes letales a 100 HP','Palo','LibroPesado','ExtintorDorado'],rows)
appendix+='''
Los nueve encuentros están separados y limitados a 12 m de su origen. Los enemigos de distancia/tecnología disparan cada 3,2 s entre 4 y 12 m y con visión. El pesado del 4 tiene 156,4 HP frente a 54,6 del rápido del 3: salto de resistencia por rol; revisar experiencia antes de reducirlo. No se encontró coordinador CHASER/FLANKER/HEAVY: no afirmar que existe cooperación de ese tipo. Sigilo sí usa visión/ruido/postura y distracciones; la ruta física de evasión queda pendiente.

## BOSSES revisados

Las cinco definiciones y controladores existen. Recompensa base por victoria: 75 créditos / 150 XP una vez, más recompensa propia; curación completa. Las duraciones siguientes son límites ofensivos ideales usando Palo, no tiempos de primera victoria ni objetivos de diseño. La disponibilidad de golpes, esquivas, cambios de arma, invocaciones y routers puede multiplicarlos.

'''
boss_rows=[
['punto / Encargado','1',200,'10 melee / 12 lanzamiento','2,6','Una','Melee / deportes','1,2 / 2,4 s','Esquivar trayectoria','PaletaProfesional','~5,7 s (10 impactos; una arma)'],
['chef / Chef Supremo','1',450,'18/22/26 melee; 14/18 bandeja','2,2/2,7/3,2','60% / 30%','Melee + bandeja desde fase 2','1,35/1/0,75; bandeja 3,5/2,5 s','Acercarse tras lanzamiento','BandejaDelChef + LlaveCasino','~12,3 s; necesita 21 golpes y reponer Palo'],
['bibliotecaria / Bibliotecaria','2',125,'25 por error','No combate físico','Quiz','16 preguntas en banco; 5 aciertos','Sin límite global','Leer y repetir tras derrota','LibroEspecial','Hipótesis 2–5 min leyendo, no medido'],
['profesor_redes / Profesor de Redes','3 (opcional)',550,'Melee 16/18/22; paquetes 12/15/18; pulso 8/10/12; pérdida 20','2,2/2,6/3,1','65% / <30%','Routers / paquetes / pulso / interferencia / conexión','Paquete 3,2/2,5/1,4; pulso 7; zona 8; pérdida 9 s','Desconectar routers con E','RouterPortatil','~14,7 s sin escudo; ~50,1 s si 70% reducción constante; cambios de arma no incluidos'],
['director / Director Informática','8',700,'20/24/32 melee; 16/20/25 digital; azul 36','2,6/3/3,6','60% / 30%','Melee / digital / dos virus / azul','Melee 1,3/1,1/0,8; digital 3/2,6/2,1; azul 7 s','USB y salir del círculo','CredencialDirector + TecladoAdministrador','~18,9 s ideales; 32 impactos y cambios de Palo']]
appendix+=table(['ID / Nombre','Piso','HP','Daño','Velocidad','Fases','Ataques','Cooldown','Ventaja','Recompensa extra','Tiempo analítico'],boss_rows)
appendix+='''
**HIGH pendiente de playtest:** los mínimos ofensivos son muy inferiores a 2–6 minutos. Las armas especiales y ataques fuertes pueden acortarlos aún más. No multiplicar HP para compensar sin medir disponibilidad de golpes y diversión. Tomar primera victoria, segundo intento y victoria con arma única; comparar porcentaje de tiempo golpeando. No son combates de 2–6 minutos demostrados.

Redes: factores de daño [1; 0,75; 0,5; 0,3] según 0–3 routers activos. E desconecta instantáneamente a 2,3 m, sin canalización. Reactiva un router una sola vez en fase 2, prueba cada 4 s. Pérdida de Conexión: aviso naranja de 1,2 s, radio 6 m, 20 daño y ralentización ×0,65 durante 3 s solo si hubo daño. No es obligatorio soportar todo el escudo pegando. Director: USB base 40 × debilidad 2 = 80 (11,4% de 700) + stun 3 s; cancela especiales configurados, no elimina automáticamente la pelea. Dos virus se invocan una sola vez al 60%, no invocación continua. Pantallazo Azul: 1,2 s de aviso, 36 daño, 7 s de cooldown. Chef mantiene bandejas y curación total. Bibliotecaria conserva feedback, reintento y preguntas; cuatro errores son letales a vida base, cinco aciertos bastan. No se exige quiz perfecto para siempre.

Señales: animaciones previas, discos de área, mensaje de especial y proyectiles. No se encontraron archivos de música/efectos externos; solo tonos procedurales del campus, por lo que mezcla musical y señales sonoras de cada ataque quedan pendientes. No declarar audio de boss validado.

## CURACIÓN y consumibles (sin ajustes de valores)

'''
appendix+=table(['ID','Efecto','Precio créditos','Stack máximo','Cooldown','Frecuencia conocida'],[
['Bebida','10 HP',5,999,'Sin cooldown','Máquinas/vendedor'],['Comida','30 HP',10,999,'Sin cooldown','Máquinas + 5 pickups de piso'],['Botiquin','50 HP',25,999,'Sin cooldown','Vendedor + 4 pickups + misión llaves'],['ColacionEspecial','Toda la vida','No en tiendas estándar',999,'Sin cooldown','Contenido/prop disponible según escena'],['BebidaEnergetica','+35% velocidad / 12 s',12,999,'Renueva, no acumula','Máquinas + misión cargador']])
appendix+='''
Comida ofrece 3 HP/crédito, Bebida y Botiquín 2 HP/crédito; Botiquín concentra curación en una pulsación. Cada computador completado también cura 25 HP una vez (GameplayManager.TASK_HEAL); los siete obligatorios ofrecen hasta 175 HP potenciales adicionales, sin reserva si ya se está lleno. Doce centros gratuitos reutilizables y victoria de boss curan al máximo; durante duelo el centro está bloqueado. Enemigos normales fuera de duelo no bloquean curación: MEDIUM, medir posibilidad de abusar retirándose. No se añade cooldown universal ni se cobra por centros sin playtest. Consumibles pueden usarse seguidos: revisar quickslots y riesgo de consumo durante animaciones. No consumen a vida completa.

## XP, CRÉDITOS y mejoras

Nivel = 1 + floor(XP / 150); requisito acumulado nivel N = (N−1)×150. Cada nivel añade 5 HP, no daño automático. Misiones principales: 630 créditos / 1130 XP. Documentos, obligatoria por dependencia: 40 / 70. Cuatro bosses obligatorios: 300 / 600. Siete PCs: 140 / 175. Archivo final: 25 / 40 por descubrimiento. Bienvenida: 30 créditos. Suma analítica principal sin enemigos/otros secretos: **1165 créditos / 2015 XP, nivel 14**, antes de gastos. Asume completar contenido una vez y activar sus handlers, no es una partida medida.

Niveles aproximados sin opcionales, contando documentos al llegar al 5: entrada 1; tras primer piso 3; llegada 3 ~5; llegada 5 ~7; llegada 8 ~10; tras Director ~12; archivo final 14. El orden de entrega y combates normales cambia estos números. En esta versión «llegada a NEXO» no aplica.

Cinco mejoras, cinco niveles cada una: precios 60/100/140/180/220; total por rama 700, conjunto 3500. La principal no financia todo. Una reparación básica no puede comprarse porque no hay reparación. Nueve enemigos normales añaden hasta 45/90 por limpieza; reaparecen al recargar, recompensa solo protegida por instancia: farming por recarga posible, rentabilidad humana pendiente. No se cambia respawn ni se quitan ingresos sin medir.

Seis secundarias juntas: 165 créditos / 265 XP; documentos ya contada en principal. Quinto boss opcional: +75/150. Veinte tarjetas: 100/200 y bonus final 200/300. Tres secretos adicionales: 75/120. PC secreto: 20/25 + USBMaestro, sin XP extra por su evento de secreto. Tres asistencias: máximo 30/75 por tipo de clase, no por día (ledger). Eventos: presupuesto global 24 créditos, 3 por ayuda exitosa, 5 XP por ayuda; no multiplicar por número de días. Aproximación principal + todo lo anterior, excluyendo eventos y farming: **1790 créditos / 3080 XP, nivel 21**, Incluyendo una limpieza de los nueve enemigos normales: 1835 créditos / 3170 XP, nivel 22. Hay variación por invocaciones y otros servicios. No es un máximo universal.

No hay venta de sillas, por tanto 779 sillas no equivalen a ingresos infinitos. Su oferta sí reduce necesidad de comprar armas. Regalos/secretos y recompensas usan IDs; la nueva regresión conserva idempotencia. La tienda ya rechaza pago cuando no entra un objeto; B03 corrige el falso éxito de stack lleno.

## MISIONES (duraciones como hipótesis, no cronometraje)

'''
floors={'inicio':'1','biblioteca':'2','academico3':'3','academico4':'4','academico5':'5','seguridad6':'6','acceso7':'7','direccion':'8','postgame':'−1','llaves':'1↔4','cargador':'2↔3','documentos':'3→5','implementos':'1,3–5','infectado':'3','casino':'1'}
durations={'inicio':'15–35 min','biblioteca':'8–20','academico3':'4–10','academico4':'4–10','academico5':'4–10','seguridad6':'4–10','acceso7':'5–15 (+documentos)','direccion':'8–20','postgame':'5–15','llaves':'5–12','cargador':'4–8','documentos':'5–12','implementos':'8–18','infectado':'2–6 (solapa pc3)','casino':'1–3 (solapa Chef)'}
appendix+=table(['ID','Nombre','Tipo','Piso','Pasos','Recompensa','Duración estimada','Necesaria'],[[q['id'],q['title'],'Principal' if q['main'] else 'Secundaria',floors[q['id']],'; '.join(r['text'] for r in q['requirements']),json.dumps(q['reward'],ensure_ascii=False),durations[q['id']],'Sí (dependencia)' if q['id']=='documentos' else 'Sí' if q['main'] else 'No'] for q in data['quests']])
appendix+='''
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
'''
audit = ROOT/'BALANCE_1_0.md'
initial = audit.read_text(encoding='utf-8').split('\n## PLAYER BASELINE')[0]
initial = initial.replace('Después previsto','Después aplicado').replace('Este registro describe decisiones antes de modificar código. Los resultados finales y las pruebas pendientes se añadirán después. No se ajustan estadísticas sin evidencia suficiente.','Este registro se escribió antes de modificar código. B01–B07 están aplicados; evidencia y límites a continuación. No se ajustaron estadísticas sin evidencia suficiente.')
audit.write_text(initial+appendix,encoding='utf-8')

playtest='''# PLAYTEST Y BALANCE 1.0 — recorrido manual

Todas las casillas comienzan pendientes. Las suites automáticas no equivalen a estas pruebas humanas. Guardar copia de la partida antes de Nueva partida; anotar versión/PC/resolución/calidad/FPS, tiempo activo, muertes, arma, curaciones, XP y créditos al entrar/salir de cada piso. Telemetría opt-in solo local en Ajustes; no se envía a internet.

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
- [ ] Piso 4: contraseña pc4; llaves; respetar salud al norte/profesores al otro sector; centro y checkpoint.
- [ ] Piso 5: archivos pc5; entregar Documentos al Funcionario; TarjetaAcceso aun con mochila llena; Inglés opcional.
- [ ] Piso 6: computador pc6, checkpoint cercano mediante centro de vida, CampusState MEDIUM.
- [ ] Piso 7: puerta acceso7 reconoce TarjetaAcceso, no la consume; pc7; desbloqueo de 8.
- [ ] Piso 8: pc8; Director; obtener CredencialDirector y TecladoAdministrador; sala especial/puerta conserva acceso.
- [ ] Subterráneo −1: acceso por ascensor/escalera, checkpoint y talleres; archivo_subterraneo completa principal.
- [ ] Cierre real: RESTORED y cosmético NEXO desbloqueado sin cambiar ropa elegida. No existe combate final NEXO que probar.
- [ ] PC secreto opcional, USBMaestro; mapa postgame y viajes solo a destinos descubiertos, llegada segura.
- [ ] Guardar, cerrar proceso, abrir y Continuar después de cada piso: inventario, HP, misiones, bosses, reloj, NPC, cosméticos, XP/créditos, durabilidad, eventos y CampusState coherentes.

## Tiempo, diversión y dificultad

- [ ] Cronometrar principal completa sin Redes ni coleccionables; contrastar 1–2,5 h y registrar reintentos/pausas por separado.
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

'''
for action in ['recoger','stack y límite 999','equipar','soltar','romper','quickslot 1','quickslot 2','quickslot 3','quickslot 4','favorito','confirmación de única','comparador y efectos','mochila llena y compra rechazada','guardar','cargar']:
    playtest+=f'- [ ] {action.capitalize()} sin perder cantidades, estado o durabilidad.\n'
playtest+='\nReparar/mejorar armas no aplica: no existe ese servicio. Sí se prueban las cinco mejoras del jugador.\n'
for b in boss_rows:
    playtest+='\n## Boss '+b[0]+'\n\n'
    for action in ['diálogo y nombre','iniciar duelo e intro','ahora no: neutral, sin ataques','barra y daño correcto','fase 1','fase 2 (si aplica)','fase 3 (si aplica)','derrota del jugador','muerte/caída del boss o cierre del quiz','recompensa una sola vez y curación','guardado y carga tras victoria','reintento con snapshot','retorno a arena sin curación gratis','rematch: marcar N/A si no hay servicio']:
        playtest+='- [ ] '+action+'.\n'
    if b[0].startswith('profesor_redes'):
        playtest+='- [ ] Desconectar tres routers y reconocer reducción de escudo; una sola reconexión en fase 2.\n- [ ] Pulso 7 s / interferencia 8 s / conexión 9 s; aviso 1,2 s legible y ralentización 3 s.\n'
    if b[0].startswith('director'):
        playtest+='- [ ] USB: 80 daño y 3 s de stun; quedan mecánicas por resolver. Dos virus como máximo por activación.\n- [ ] Salir del círculo azul en 1,2 s sin depender de sonido.\n'
for q in data['quests']:
    playtest+='\n## Misión '+q['id']+' — '+q['title']+'\n\n'
    for action in ['iniciar / desbloquear requisito','objetivo comprensible y NPC localizable','progreso de cada paso','completar','recompensa única y entrada con mochila llena','guardar','cerrar y cargar sin repetir/perder progreso']:
        playtest+='- [ ] '+action+'.\n'
playtest+='''
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

Boss final NEXO, Programación, Inglés/Lenguaje/Ética/Salud/talleres, modos Historia/Difícil, NG+ y Boss Rush: N/A porque no están implementados como contenido jugable actual. No marcar aprobados.
'''
(ROOT/'PLAYTEST_1_0.md').write_text(playtest,encoding='utf-8')
out=ROOT/'reports'
out.mkdir(exist_ok=True)
(out/'balance_1_0_data.json').write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Balance tables, manual checklist and raw fixture data written.')
