# Informe integral de DuocGames

**Proyecto Aethergate · Estado del proyecto al 23 de noviembre de 2026**

DuocGames es un juego educativo 3D en tercera persona realizado en Godot. El jugador interpreta a un estudiante que recorre un campus inspirado en Duoc UC. El primer día funciona como introducción a la movilidad, los objetos y los encargos. Después, la campaña combina exploración, laboratorios y simulaciones hasta llegar al incidente NEXO. La misma aplicación ofrece paneles para docentes y administradores y guarda el avance de los estudiantes por cuenta.

## 1. Qué hace el jugador

1. **Entra al juego.** El arranque normal abre el inicio de sesión y dirige al menú que corresponde a la cuenta. Desde el menú del estudiante se puede iniciar o continuar la campaña. Las compilaciones de desarrollo tienen sesiones de prueba para revisar el juego y los paneles sin una cuenta real.
2. **Explora el campus.** El personaje camina, corre, salta y se agacha. La cámara es en tercera persona. El minimapa y el marcador de misión orientan hacia el próximo objetivo. Se puede hablar con personajes, recoger objetos, usar computadores, sentarse en puntos habilitados y llamar a los ascensores.
3. **Resuelve encargos y desafíos.** Hay actividades de búsqueda, inspección, diálogo, práctica académica, simulación y rescate. El jugador recibe experiencia, créditos, objetos, credenciales o acceso a áreas según la actividad. Las misiones principales abren el avance narrativo. El tablero de encargos y el celular dan acceso a objetivos complementarios.
4. **Continúa la historia de NEXO.** La ruta pasa por Punto Estudiantil, casino, biblioteca, laboratorios y los encuentros de los pisos superiores. El encuentro con el Director en el piso 8 y el archivo del subterráneo conducen al núcleo de NEXO. El final incluye el duelo del núcleo, cierre narrativo, créditos y continuación posterior.

La actualización educativa 4.0 documenta **10 misiones principales y 16 secundarias**. Entre las secundarias están el rescate de un estudiante encerrado, un laboratorio sin conexión, un programa infectado, una emergencia simulada, una presentación interrumpida y un taller descontrolado. [Campaña](CAMPANA.md) · [Implementación educativa 4.0](DUOCGAMES_4_0_REPORT.md)

### Controles principales

| Control | Acción |
| --- | --- |
| WASD o flechas | Moverse |
| Shift · Espacio · C o Ctrl | Correr, saltar y agacharse |
| Ratón y rueda | Mover la cámara y ajustar el zoom |
| E | Interactuar, recoger o usar un acceso cercano |
| J o clic izquierdo · Alt | Golpear y esquivar |
| I · 1–4 · F | Abrir la mochila, usar accesos rápidos y utilizar el artículo correspondiente, como los apuntes equipados |
| P · M · Tab · Esc | Celular, misiones, mapa y pausa |

Las teclas pueden cambiar de función según el contexto. En la cabina del ascensor, la selección de destinos permite ir al subterráneo y a los pisos superiores. [Guía de juego](GUIA.md)

## 2. Campus, recintos y desplazamiento

El campus tiene **nueve niveles transitables**. El subterráneo se identifica como piso −1 y los niveles superiores se numeran del 1 al 8. La escalera central, la de emergencia y los tres ascensores conectan distintos sectores. La rampa vehicular poniente vincula el subterráneo con el primer piso y el patio trasero.

| Zona | Identidad y contenido |
| --- | --- |
| Piso −1 | Mecánica automotriz, soldadura, estructuras metálicas, áreas de trabajo técnico y sector final de NEXO. |
| Piso 1 | Acceso principal, Punto Estudiantil, casino, coordinación y primeras actividades de campaña. |
| Piso 2 | Biblioteca, salas de estudio, auditorio, papelería y desafío de la bibliotecaria. |
| Piso 3 | Informática y Telecomunicaciones. Laboratorios de Programación 301, Bases de Datos 302, Redes 303, Ciberseguridad 304-B, Hardware y Soporte 305, Laboratorio General 306 y sala técnica de servidores. |
| Piso 4 | Enfermería y Odontología en el sector norte. Oficinas, coordinación y espacios de profesores en el sector docente. |
| Pisos 5–8 | Formación general y transversal, aulas, zonas de estudio, terrazas y servicios. El Director de Informática permanece en el piso 8. |
| Exterior | Accesos, patio posterior, jardines, cancha, estacionamientos y zona de motos. La rampa poniente tiene un tramo vehicular de 7,7 m de ancho, escalera lateral y una bajada ambientada como acceso de taller. |

Los recintos se organizan en la escena principal por piso y por zonas compartidas. Los accesos físicos y los requisitos de campaña determinan cuándo se puede avanzar hacia determinados sectores y objetivos. [Organización y temática de pisos](scripts/pisos/README.md) · [Escena del campus](Main.tscn)

## 3. Sistemas de juego

**Misiones y progresión.** El controlador de campaña recibe eventos de juego, como hablar, recoger, completar un computador o terminar una simulación. El gestor aplica esos eventos a los objetivos activos y actualiza el HUD, las misiones y los desbloqueos. Las recompensas de avance quedan registradas para evitar que completar el mismo hito vuelva a otorgarlas.

**Combate y simulaciones.** El sistema incluye golpes, esquiva, equipamiento con durabilidad, daño, señales anticipadas, fases de jefe y reintentos desde puntos de control. Los mentores académicos se presentan como personajes civiles y sus duelos se representan como simulaciones con entidades digitales. NEXO tiene su propio encuentro final. El modo aprendizaje adapta el daño y ofrece tiempo adicional. [Campaña](CAMPANA.md) · [Simulaciones y combate](DUOCGAMES_4_0_REPORT.md)

**Inventario y economía.** La mochila gestiona consumibles, implementos, objetos clave y útiles de papelería. Los artículos equipables tienen espacios rápidos y, cuando corresponde, durabilidad. Los consumibles restauran vida o aplican efectos. Las tarjetas y credenciales habilitan accesos. Los créditos, la experiencia y las mejoras acompañan la progresión. Los apuntes se conservan en la partida. [Inventario](INVENTARIO.md)

**Celular y vida del campus.** El teléfono reúne mapa, objetivos, contactos, mensajes, registro, horario y progreso académico. Algunas actividades dependen de un horario simulado y la asistencia es complementaria. Los personajes del entorno pueden caminar, conversar, usar el teléfono o participar en rutinas del laboratorio. El juego reduce la frecuencia de animación y rutinas a distancia y en otros pisos. [Celular y mensajes](CELULAR_Y_MENSAJES.md) · [Horario y asistencia](HORARIO_Y_ASISTENCIA.md) · [Campus vivo](CAMPUS_VIVO_2_0.md)

**Presentación y accesibilidad.** El protagonista tiene apariencia configurable y animaciones de locomoción, acciones y combate. Los personajes del campus usan modelos y materiales reutilizables, con una representación procedural disponible en los casos contemplados por el código. Hay música y efectos propios sintetizados, buses de volumen independientes, avisos visuales y perfiles gráficos. [Personalización](PERSONALIZACION.md) · [Personajes](CHARACTER_ANIMATION_FINAL_7_0.md) · [Audio y accesibilidad](DUOCGAMES_4_0_REPORT.md)

## 4. Cómo funciona la parte académica

El campus asocia asignaturas con salas, computadores y mentores. El alumno abre una actividad, revisa su consigna, entrega una respuesta y recibe retroalimentación. El banco de actividades admite selección múltiple, verdadero o falso, ordenamiento, identificación, asociación, secuencias, elección mediante zonas 3D y reflexión. Algunas actividades pueden otorgar experiencia o credenciales y, cuando corresponde, servir como requisito de acceso o de simulación. Las reflexiones y las prácticas tienen un tratamiento propio. El progreso muestra resultados del juego y de sus actividades, sin carácter de calificación institucional.

| Perfil | Qué puede hacer |
| --- | --- |
| Estudiante | Jugar, practicar, responder actividades, consultar resultados y revisar sus credenciales. |
| Docente | Gestionar preguntas y actividades de las asignaturas que tiene asignadas. Puede crear, editar, previsualizar y publicar contenido, incorporar imágenes y consultar estadísticas según las funciones habilitadas. |
| Administrador | Gestionar perfiles, roles y asignaciones docentes, administrar asignaturas y revisar auditoría y estadísticas según las funciones habilitadas. |
| Pendiente | Cuenta registrada a la espera de un rol que habilite el acceso correspondiente. |

En las actividades asociadas al servidor, el cliente recibe la consigna y lo necesario para responder. El servidor conserva la clave, valida el usuario y el contexto, registra el intento y devuelve la corrección. El modo de desarrollo y las prácticas locales permiten probar parte del flujo. [Sistema educativo](EDUCATION_SYSTEM_1_0.md) · [Paneles y actividades](DUOCGAMES_4_0_REPORT.md) · [Administración](ADMIN_PANEL.md)

## 5. Base técnica

El juego se ejecuta en **Godot 4.7 con GDScript**. El proyecto se ha probado con Godot 4.7.2 y usa el renderizador **GL Compatibility**. `Login.tscn` es la escena inicial. El menú abre `Main.tscn` al entrar al campus. Esta escena reúne el mapa, sus colisiones, los accesos, la iluminación y los sistemas compartidos. El gestor de juego crea y controla al jugador dentro de la escena.

| Capa | Archivos o carpetas | Responsabilidad |
| --- | --- | --- |
| Motor y arranque | `project.godot`, `scenes/education/` | Configuración, inicio de sesión y menús por rol. |
| Mundo | `Main.tscn`, `scripts/pisos/`, `scripts/exterior/` | Geometría, colisiones, ambientación y lógica espacial. |
| Jugabilidad | `scripts/juego/`, `scripts/compartidos/` | Jugador, cámara, personajes, combate, objetos, puertas y ascensores. |
| Campaña y rutinas | `scripts/campaign/`, `scripts/live/` | Misiones, diálogo, HUD, accesos, horario, eventos y configuración. |
| Educación y servicios | `scripts/auth/`, `scripts/education/` | Sesión, consultas, evaluación académica, paneles y persistencia. |
| Datos y pruebas | `supabase/`, `resources/`, `tests/`, `reports/` | SQL, configuración de contenido, escenarios de regresión y evidencia. |

Los servicios globales `AuthManager`, `QuestionService` y `CloudSave` conservan sesión, acceso a preguntas y estado de guardado al cambiar de escena. El menú puede cargar el mapa en segundo plano mientras consulta la partida. En juego, los NPC reutilizan niveles de detalle de sus modelos. Los perfiles Medio y Bajo reducen la resolución interna del mundo 3D al 85 % y 70 % respectivamente. [Configuración del proyecto](project.godot) · [Rendimiento](RENDIMIENTO.md)

## 6. Base de datos, autenticación y guardado

El cliente usa **Supabase Auth** para la identidad y **PostgreSQL en Supabase** para los datos. El código contempla login por correo y Google mediante OAuth con PKCE, sujeto a la configuración del proyecto. El identificador de usuario vincula el perfil, la partida y los intentos evaluados.

| Datos | Tablas principales | Qué representan |
| --- | --- | --- |
| Identidad y roles | `auth.users`, `profiles` | Identidad autenticada y perfil con rol. |
| Asignación docente | `subjects`, `teacher_subjects` | Asignaturas y relación de autorización entre profesores y materias. |
| Banco de preguntas | `questions`, `question_keys` | Contenido de las preguntas y claves protegidas. |
| Evaluación | `question_attempts`, `academic_progress` | Intentos registrados y progreso académico. |
| Actividades ampliadas | `learning_activities`, `learning_attempts`, `learning_access` | Actividades, resultados y accesos ganados. Las soluciones y tickets se guardan en un esquema privado. |
| Campaña | `campaign_saves` | Una fila por cuenta con la partida en JSON, revisión y respaldo según la operación. |
| Administración | `admin_audit_log` y funciones de auditoría | Registro de cambios administrativos autorizados. |

### Guardado en una sesión

1. El menú consulta la partida de la cuenta y entrega ese estado al campus al entrar.
2. La campaña mantiene posición, vida, inventario, misiones, accesos, XP, créditos, apariencia, celular, asistencia y ajustes.
3. El servicio envía el estado de la partida mediante funciones RPC. El servidor identifica al propietario por la sesión y compara la revisión para detectar cambios simultáneos desde otro equipo.
4. Si se pierde la conexión, una cola local conserva operaciones pendientes para esa misma cuenta. Al recuperar la sesión, puede reintentar la operación con el mismo identificador. Si aparece un conflicto, el juego solicita resolverlo explícitamente.

Las políticas RLS aplican permisos por fila y rol. Las operaciones sensibles se validan en el servidor. El JSON de campaña y los intentos académicos evaluados tienen persistencias distintas. La práctica local y los entornos de desarrollo pueden funcionar sin una sesión remota. La recuperación del guardado remoto requiere la misma cuenta y conexión. [Autenticación](AUTH_ARCHITECTURE.md) · [Guardado por cuenta](GUARDADO_SUPABASE.md) · [Migraciones SQL](supabase/migrations/)

## 7. Ejecución y alcance de la validación

Para ejecutar el flujo normal se abre `Juego/project.godot` con Godot 4.7.2 y se presiona **F5**. **F6** con `Main.tscn` abierto inicia la escena del campus para desarrollo. El repositorio contiene pruebas de movimiento, ascensores, progresión, inventario, educación, roles, guardado y rendimiento. Parte de las pruebas de roles y servidor usa datos y transporte simulados.

| Aspecto | Estado documentado |
| --- | --- |
| Campus y campaña | Implementados en el proyecto. Las pruebas de acceso y de recorridos verifican rutas específicas. La rampa poniente y la escalera lateral se comprobaron mediante movimiento y colisiones en Godot sin pantalla. |
| Supabase | La verificación de octubre registró la migración 007 aplicada y sus permisos estructurales revisados. El informe posterior 4.0 registra las migraciones 008 y 009 preparadas y el diagnóstico remoto fallido por DNS. El estado actual del servidor y la sincronización real entre equipos requieren una nueva verificación. |
| Rendimiento | Hay pruebas de arranque sin gráficos y perfiles de render en el repositorio. Una medición de arranque local registró 20,3 s antes y 19,5 s después de la optimización de NPC. El dato corresponde a esa prueba, sin medición de FPS. |
| Distribución | Existe un preset de exportación para Windows. El intento documentado del 2 de noviembre de 2026 quedó bloqueado por falta de plantillas de exportación. El informe se refiere al proyecto ejecutable desde Godot. |
| Validación humana | Las comprobaciones automáticas cubren sistemas y recorridos concretos. El balance, una campaña completa con jugadores y el uso de las funciones académicas con cuentas reales quedan fuera de esa evidencia. |

[Auditoría del proyecto](CAPSTONE_AUDITORIA_REAL.md) · [Informe y evidencias 4.0](DUOCGAMES_4_0_REPORT.md) · [Exportación Windows](DEMO_WINDOWS_4_0.md)
