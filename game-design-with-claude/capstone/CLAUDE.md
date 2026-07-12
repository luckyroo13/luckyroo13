# CLAUDE.md — Snake Eyes

## Qué es este juego
Lee DESIGN.md antes de cualquier cambio. La sección "Qué NO es este juego"
es un límite duro: si un cambio la contradice, señálalo antes de implementar.

## Reglas de arquitectura
- Todos los números de diseño van a src/tuning.ts. Nunca constantes en la lógica.
- src/render.ts solo lee estado; la simulación (src/update.ts) corre sin canvas.
- El RNG de gameplay usa la semilla del estado (src/rng.ts), jamás Math.random().
- La simulación no toca WebAudio: emite GameEvent[] y main.ts los mapea a audio.
- Entidades = interfaces planas + funciones. Sin herencia, sin clases.

## Cómo verificar
- `npm run dev` y jugar el ciclo completo: title → playing → gameover → title.
- `npm run sim` para cambios de balance: threshold debe ganarle a greedy y
  a cautious, con duración mediana ~2 minutos.
- `npm run build` debe pasar sin errores de tipos.

## Estilo de colaboración
- Un diff chico por mecánica; sin refactors oportunistas.
- Parámetros nuevos siempre a tuning.ts, y regístralos en TUNING_LOG.md si
  cambian el balance.
