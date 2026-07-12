# TUNING_LOG — Snake Eyes

Registro de iteraciones de balance (cap. 5 del curso). Cada entrada:
qué cambió, por qué, qué pasó en `npm run sim` (1000 partidas por bot).

## v1 — números iniciales por intuición

`fallSpeedMax: 300, spawnIntervalMin: 0.42, rampDuration: 90, snake fijo 26%`

```
greedy     p50=0     duración 4:54
cautious   p50=1148  duración 4:58
threshold  p50=1514  duración 4:52
```

Diagnóstico: la decisión central está sana (greedy muere con 0, threshold
domina), pero la partida mediana dura ~5 min contra un objetivo de 2–3.

## v2 — endurecer la física

`fallSpeedMax: 300 → 400, spawnIntervalMin: 0.42 → 0.3`

```
threshold  p50=1665  duración 4:52
```

Resultado: casi nulo. Lección: la velocidad no mata a quien esquiva bien —
en este juego **solo los snake eyes matan**. La presión de final de partida
tiene que venir de la distribución, no de la física.

## v3 — el snake eye escala con la rampa

`snakeWeightEnd: 48` (el peso del 1 crece de 26 con la rampa)

```
threshold  p50=899  duración 3:17
```

Mejor. La distribución es la palanca correcta.

## v4 — apretar hasta el objetivo (actual)

`snakeWeightEnd: 48 → 62, rampDuration: 90 → 75`

```
greedy     p50=0    duración 2:42
cautious   p50=528  duración 2:38
threshold  p50=669  duración 2:41
```

Estado: sano. Un bot de esquive perfecto muere a ~2:40; un humano, antes.
threshold > cautious > greedy, así que ni "bancar siempre" ni "nunca bancar"
dominan. Congelado para embarque.
