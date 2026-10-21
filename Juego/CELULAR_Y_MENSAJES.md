# Celular y mensajes — primera etapa de inmersión

## Qué se implementó

P abre el celular y pausa usando CampaignUI; P o Cerrar devuelve el control.
La presentación usa una carcasa de teléfono vertical, fondo atenuado, pantalla
de aplicaciones con iconos vectoriales y navegación Atrás/Inicio/Cerrar.
Mapa, mensajes y demás páginas permanecen dentro de esa pantalla. La escala
se adapta al tamaño de ventana; los textos largos tienen desplazamiento.
No reemplaza una conversación, un duelo o un minijuego en curso. La tecla P
no se consume cuando el jugador está ocupado en otra interfaz.

Aplicaciones: mapa y misiones llaman a sus interfaces existentes; NEXO,
coleccionables y estadísticas abren el registro actual; ajustes usa Opciones.
Las aplicaciones incluyen botón para volver al celular. Mensajes y Contactos
son las páginas nuevas. No se añaden pisos ni nodos permanentes a Main.tscn.

Contactos registra solo NPC conocidos mediante el evento `talk` existente.
Al cargar recupera encuentros previos desde eventos, sin descubrir desconocidos.
Muestra nombre, rol, piso del NPC, progreso de encargo y último mensaje.
La relación mostrada representa conocimiento/progreso: todavía no es afinidad.

Al primer encuentro se recibe un mensaje con información que el NPC ya daba.
Al completar un encargo, los contactos relacionados pueden agradecerlo.
Nunca se introduce una pista de campaña que el jugador no haya descubierto.

La notificación NUEVO MENSAJE espera a que terminen combate cercano, duelo,
minijuego y ventanas. No abre diálogos ni cambia cámara. Si un mensaje queda sin
leer, se recupera al cargar. El historial retiene los últimos 200 mensajes y una
tabla de identificadores evita duplicar mensajes al repetir eventos o cargar.

## Archivos

- Nuevo: `scripts/campaign/student_phone.gd`.
- Presentación: `scripts/campaign/phone_view.gd`.
- `scripts/campaign/campaign_ui.gd` restaura su panel al salir del celular;
  los diálogos ajenos al teléfono conservan su presentación.
- Modificado: `scripts/campaign/campus_campaign.gd`: inicialización, evento,
  tecla P y texto de controles. Campo aditivo `phone` en el mismo guardado.
- Pruebas nuevas: `tests/student_phone.gd`, `tests/phone_preview.gd` y
  `tests/PhonePreview.tscn`.
- Documentación: este archivo y RESUMEN_JUEGO.md.

Nodo de ejecución: `CampusCampaign/CelularEstudiante`; las páginas reutilizan
el panel CampaignUI. No hay procesamiento individual por contacto o mensaje.
No se escanean NPC cada frame: el registro responde a eventos. Solo se evalúa
la notificación pendiente, con comprobación de peligro como máximo cada segundo.

## Integración para otros NPC/sistemas

```gdscript
# Registrar únicamente después de que el jugador conozca al personaje.
campaign.phone.register_contact("contacto_unico", "Nombre ficticio", "Rol", "3")
# El mismo ID no vuelve a entregar el mensaje.
campaign.phone.send_message("evento_unico", "contacto_unico", "Texto ya autorizado por el progreso")
```

`send_message` guarda la campaña actual al añadir un mensaje; registrar un
contacto manualmente sin enviar mensaje requiere el guardado habitual del
sistema que lo llama. NPC existentes se integran por eventos sin editar sus
diálogos ni controladores. Para NPC implementados en otra versión, conectar
estos dos métodos al encuentro correspondiente.

## Guardado y compatibilidad

`phone.contacts`, `phone.messages` y `phone.received` viven en el JSON de campaña.
Partidas anteriores sin `phone` reciben diccionarios/lista vacíos y recuperan
contactos desde eventos de conversación existentes. Leer un mensaje guarda
su estado; Nueva Partida usa los valores vacíos de la campaña.
Inventario y guardado general mantienen su implementación actual.

## Validación y prueba manual

Prueba de integración: 31 comprobaciones sin fallos; apertura mediante la entrada
P de campaña, aplicaciones, cancelación, contactos, piso habitual, lectura,
deduplicación, restauración, bloqueo de avisos durante duelo e invariantes de
inventario/misiones/bosses. Log: `tests/student_phone.log`.
Regresión general de campaña sin fallos: `tests/phone_campaign_regression.log`.
Nueva Partida comprueba también el reinicio de contactos y mensajes:
`tests/phone_nueva_partida.log`. Carga de 179 recursos propios sin fallos:
`tests/phone_revision_scripts.log`. Se revisó visualmente el menú mediante MCP.
Los tests usan guardados temporales del proyecto y deshabilitan persistencia
del inventario y credencial reales.

Prueba manual:
1. Abrir Main y pulsar P; revisar las ocho aplicaciones y volver/cerrar.
2. Hablar con Profesor/Estudiante u otro NPC; revisar Contactos y Mensajes.
3. Leer un mensaje, guardar, recargar y comprobar que no vuelve a estar sin leer.
4. Completar un encargo y revisar su agradecimiento sin duplicados.
5. Recibir un mensaje durante combate/minijuego: debe esperar para notificar.
6. Probar en una partida nueva de prueba y comprobar que no conserva contactos.

F6 en `tests/PhonePreview.tscn` abre una vista aislada sin leer ni escribir la
partida real. Durante el desarrollo hubo diagnósticos transitorios al conectar
métodos nuevos antes de escribirlos; la versión final valida sin errores.
Los avisos de certificados/registro MCP del entorno no son errores de gameplay.

## Pendiente / diferencia de versión

Esta entrega implementa la etapa 1 (celular/mensajes/contactos), no las 16 etapas.
Afinidad, decisiones, taller, combate avanzado, dificultad, Boss Rush, NG+, foto,
mando, accesibilidad, cinematográficas, slots, optimización global, QA y boss
secreto no se declaran implementados por esta entrega.

El usuario indica que NEXO, NPC dinámicos, ClassroomChallenge, final y postgame
ya existen. No se localizaron esos módulos en esta carpeta y se pidió su ruta o
rama. No se recrearon. Integraciones que necesitan esas implementaciones,
especialmente rutinas horarias y modos postgame, deben usar la versión correcta.
No se inventaron mediciones de FPS ni mejoras de rendimiento globales.
