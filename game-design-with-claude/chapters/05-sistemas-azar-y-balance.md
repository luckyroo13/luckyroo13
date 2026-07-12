# Capítulo 5 — Sistemas: azar, balance y dificultad

Los capítulos anteriores hicieron que tu juego *se sienta* bien momento a
momento. Este hace que *funcione* como sistema a lo largo de una partida y de
cien partidas. Aquí es donde tu instinto de ingeniero — modelar, medir,
encontrar los casos donde el sistema falla — vale oro.

## Azar: el que percibe el jugador, no el que programa la máquina

El azar bien usado genera drama y rejugabilidad. Mal usado, genera la queja
número uno de cualquier foro: "el RNG me robó". Tres lecciones de la
industria:

### 1. El azar puro se siente injusto

Los humanos son pésimos evaluando aleatoriedad: tres snake-eyes seguidos son
perfectamente probables y se sienten como sabotaje. Por eso casi ningún juego
comercial usa azar puro:

- **Bolsa barajada (bag randomness):** Tetris no elige piezas al azar — mete
  las 7 en una bolsa, la baraja y las reparte; nunca ves la misma pieza 3
  veces seguidas ni pasas 20 piezas sin la línea. Percepción: "aleatorio".
  Realidad: fuertemente acotado.
- **Pseudo-aleatorio compensado:** el crítico del 20% en Dota real sube su
  probabilidad cada vez que no ocurre. Evita tanto las sequías como las
  rachas absurdas.
- **Pity timers:** tras N fracasos, el éxito se garantiza.

La regla: **el azar decide los detalles, no el destino.** Qué dado cae y
dónde: azar. Si una partida es ganable: nunca.

### 2. En un juego de dados, la distribución ES el diseño

En Snake Eyes los dados no salen uniformes. La distribución de valores está
en tuning.ts como pesos, porque cada valor tiene un rol de diseño distinto:
el 1 es amenaza (frecuente para que haya tensión), el 6 es premio (raro para
que emocione), los medios son relleno cachable. Cambiar esos pesos cambia el
juego completo sin tocar una línea de lógica.

```typescript
// tuning.ts
faceWeights: [26, 15, 15, 15, 15, 14], // índice 0 = cara 1 (snake eye)
```

### 3. Semillas para reproducir

Usa un RNG con semilla (un `mulberry32` de cuatro líneas basta) en lugar de
`Math.random()` para la lógica de juego. Mismo seed → misma partida. Esto te
da bug reports reproducibles, replays gratis, y "daily challenges" (todos
juegan la misma semilla) casi gratis.

## Balance: simula antes de creer

Tu intuición de balance es mala. La mía también, y llevo quince años. La
diferencia entre un diseñador junior y un senior es que el senior lo sabe y
**simula**.

Aquí la arquitectura del capítulo 3 cobra su recompensa: como `update()` corre
sin canvas, puedes ejecutar miles de partidas con bots en segundos:

```typescript
// sim.ts — corre con: npx tsx sim.ts
for (const strategy of ['greedy', 'cautious', 'banker']) {
  const scores = range(1000).map(seed => simulate(strategy, seed));
  console.log(strategy, 'p50:', median(scores), 'p95:', p95(scores));
}
```

Esto es un test de invariantes económicos, exactamente como en contratos:
defines qué debe ser cierto del sistema y verificas mecánicamente que lo sea.
Preguntas que la simulación responde y tu intuición no:

- ¿La estrategia "nunca bancar" domina? → la decisión central está muerta,
  el push-your-luck no existe.
- ¿La estrategia "bancar siempre de inmediato" domina? → el riesgo no paga,
  mismo problema al revés.
- ¿Cuánto dura una partida mediana? ¿Coincide con los 2–3 minutos del pitch?

**El estado sano es que las estrategias extremas pierdan contra una mixta.**
Si un bot tonto con una regla fija le gana a todo, un humano lo descubrirá el
día del lanzamiento. Pídele a Claude que escriba los bots y el arnés — es
trabajo mecánico perfecto para delegar — pero **tú defines las estrategias y
tú interpretas los percentiles.** Eso es diseño.

## Dificultad: la rampa

Un arcade sin fin necesita que la dificultad crezca. Decisiones:

**Qué escalar.** Escala pocas variables y que se sientan: velocidad de caída
y frecuencia de spawn. Escalar seis cosas a la vez hace imposible razonar
sobre el balance (misma disciplina que cambiar una variable por experimento).

**Cómo escalar.** Lineal se siente plano; exponencial se vuelve injusto de
golpe. El estándar es una curva con saturación — rápida al inicio (los
primeros 30 segundos deben ponerse interesantes ya) y suave hacia un techo
(siempre debe ser humanamente posible):

```typescript
// 0 → 1 con saturación suave; rampDuration controla el "medio juego"
const ramp = 1 - Math.exp(-state.time / TUNING.difficulty.rampDuration);
const fallSpeed = lerp(TUNING.die.fallSpeedMin, TUNING.die.fallSpeedMax, ramp);
```

**El techo importa.** El final de la rampa define tu skill ceiling: si el
techo es sobrevivible por un experto, tu juego tiene comunidad de high
scores; si no, tiene un muro.

## La sesión de tuning con Claude

El flujo que uso en producción, adaptado a Claude Code:

1. Juega 3 partidas. Escribe qué sentiste, no qué números cambiar: *"el
   principio es aburrido, el minuto 2 es injusto, nunca me tienta seguir sin
   bancar"*.
2. Pásale eso a Claude junto con tuning.ts y pídele hipótesis: *"¿qué
   parámetros explican cada sensación y en qué dirección los moverías?"*
3. Cambia **una cosa**, corre la simulación, juega otra vez.
4. Registra cada iteración en un `TUNING_LOG.md` (qué cambió, por qué, qué
   pasó). En una semana ese log vale más que tu memoria — y le da a Claude
   contexto de por qué los números son los que son.

## Ejercicio con Claude

> Escribe sim.ts: corre 1000 partidas headless de mi juego con tres bots
> (greedy: nunca banca; cautious: banca en cuanto puede; threshold: banca
> arriba de N puntos). Reporta p50/p95 de score y duración por estrategia.
> Luego dime si mi decisión central está balanceada y qué parámetro de
> tuning.ts moverías primero.

Si una estrategia fija domina, tienes tu primera sesión de tuning real. Usa
el flujo de arriba.

---

**Siguiente:** [Capítulo 6 — Claude Code como tu equipo](06-claude-como-equipo.md)
