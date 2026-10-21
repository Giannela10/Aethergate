# Profesor de Redes y Telecomunicaciones

Personaje completamente ficticio del Piso 3 (Informática y Telecomunicaciones).
Duelo opcional: no cambia requisitos, misiones, computadores ni bosses existentes.

## Ubicación

Nodo: `Main/Piso3/EncuentroProfesorRedes/ProfesorRedes`, ala oriental del pasillo,
antes de la escalera del extremo norte. Coordenadas globales comprobadas:

| Elemento | X | Y aproximada | Z |
| --- | ---: | ---: | ---: |
| Profesor | 65 | 24.008 | −145 |
| Router_A | 59 | 24.008 | −146 |
| Router_B | 69 | 24.008 | −146 |
| Router_C | 65 | 24.008 | −142 |

El encuentro ajusta únicamente sus propios objetos al suelo y comprueba una cápsula
libre en los cuatro puntos. Si la geometría cambia y un punto deja de ser válido,
avisa y no permite iniciar el duelo. No mueve paredes, losas ni otros personajes.
El boss permanece en una arena local del mismo piso; no persigue entre niveles.

## Funcionamiento

Neutral: inmune, sin IA ni fases y routers desconectados. E muestra el diálogo
solicitado con Iniciar desafío / Ahora no. Cancelar lo mantiene neutral.
Aceptar usa la introducción y HUD del controlador compartido y enciende los routers.

Vida: 550. Escala visual: 1.3 respecto al enemigo base. Ropa azul oscura,
credencial, mochila y tablet hechos con primitivas del personaje actual.

| Fase | Vida | Comportamiento |
| --- | --- | --- |
| 1 | Más de 65% | Cuerpo a cuerpo, paquete de datos y pulso cercano con empuje leve |
| 2 | 65% a 30% inclusive | Mayor velocidad y zona violeta de interferencia de 5 segundos; puede reconectar un router una sola vez |
| 3 | Menos de 30% | Más velocidad y paquetes más frecuentes; anuncia Pérdida de Conexión antes de una onda grande |

Escudo: tres routers activos reducen daño 70%; dos, 50%; uno, 25%; ninguno, 0%.
E a menos de 2.3 m y con línea de visión desconecta un router, apaga su indicador
y muestra la reacción del profesor. No se pueden desconectar durante la neutralidad.
La reconexión de fase 2 se intenta cada 4 s hasta encontrar un router desconectado;
una vez realizada no se repite durante ese duelo.

Paquetes: proyectiles con colisión barrida, velocidad 9 m/s y daño 12/15/18 según
fase. Golpes: 16/18/22. Pulso cercano: radio 3.2 m y daño 8/10/12.
Las paredes bloquean ataques y ondas.

Pérdida de Conexión anuncia un círculo naranja durante 1.2 s y después resuelve
una onda de 6 m: daño 20 y ralentización al 65% durante 3 s si impacta. Se puede
salir del círculo o esquivar el golpe. No bloquea teclas ni la barra rápida.
Interferencia ralentiza al 60% mientras se permanece en su zona, y termina
aproximadamente 1 s después de abandonarla. Reutiliza `item_effect_receiver.gd`.
Una capa local restaura la velocidad al morir, reiniciar o terminar el duelo.

## Victoria, recompensa y guardado

Recompensa: **RouterPortatil**, objeto especial único, más **150 XP y 75 créditos**.
La vida del jugador se recupera con el sistema compartido. El profesor cae y se
muestra la pista: «Esto no es un fallo normal... hay tráfico extraño viniendo de
otros pisos».

RouterPortatil se registra mediante `item_catalog.register_item()` desde la entrada
del encuentro en el árbol, antes de que el gestor cargue la mochila. No se modifica
ningún script de inventario. **Su efecto defensivo/de detección queda pendiente**:
por ahora se conserva, no se consume y no proporciona resistencia efectiva.

Se reutilizan `data.bosses.profesor_redes`, el snapshot de inventario y el evento
`story:nexo_redes`. Las desconexiones registran eventos `router:profesor_redes:Router_*`.
No se cambia el formato de guardado. Un boss derrotado carga caído, sin repetir
recompensa ni diálogo de inicio. Fases, proyectiles y routers parciales no se guardan:
un reintento vuelve a neutral con vida completa y sin efectos pendientes.

## Archivos locales

- `encuentro_profesor_redes.gd`: creación, registro del objeto y colocación segura.
- `profesor_redes_boss.gd`: ataques, fases, escudo y visual.
- `profesor_redes_duel.gd`: especialización del controlador existente para este diálogo.
- `network_router_interactable.gd`: routers y acción E.
- `network_data_packet.gd`: especialización del proyectil digital existente.
- `network_interference_zone.gd`: zona temporal.
- `network_slow_status.gd`: duración y limpieza del estado reutilizado.
- `router_portatil_item.gd`: definición local de recompensa.
- `test_profesor_redes.gd`: verificación aislada y modo de previsualización.

`Main.tscn` recibe solo una referencia de script y un nodo bajo Piso3.
Los controladores compartidos y los otros pisos/bosses se conservan.

## Comprobación

`ProfesorRedesCheck.tscn` verifica 38 condiciones, incluyendo interacción E,
neutralidad, escudo, paquetes, bloqueo por pared, fases, reconexión única,
interferencia, duración/limpieza del efecto, derrota, recompensa y carga de partida.
La prueba usa un JSON temporal dentro de esta carpeta y nunca el guardado del usuario.

```powershell
godot --headless --path . res://scripts/pisos/piso_3/ProfesorRedesCheck.tscn
```

Para probar manualmente sin alterar tu partida: abre `ProfesorRedesPreview.tscn`
y ejecútala con F6. Apareces junto al profesor; el guardado está desactivado.

Revisar manualmente:

1. Golpear estando neutral y elegir Ahora no: sin daño, ataques ni routers activos.
2. Aceptar: introducción, barra 550 y tres routers encendidos.
3. Desconectar los tres con E y comprobar que los golpes hacen más daño.
4. Comprobar cambios al 65% y bajo 30%; una única reconexión en fase 2.
5. Entrar y salir de la zona violeta; salir/esquivar el círculo naranja.
6. Morir durante una carga y reintentar: ninguna ralentización persistente.
7. Vencer, leer la pista, guardar y continuar: boss caído y una sola recompensa.

Pendientes: balance con una partida real y activar el efecto de RouterPortatil
cuando se autorice ampliar el sistema de uso de objetos. No se añadieron audios
externos; el feedback es visual y textual.
