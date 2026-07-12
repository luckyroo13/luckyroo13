# SNAKE EYES 🎲

Arcade de push-your-luck: cacha dados que caen, esquiva los ojos de
serpiente, y decide cuándo bancar tu racha. Capstone del curso
[Game Design con Claude Code](../README.md).

```bash
npm install
npm run dev     # jugar en http://localhost:5173
npm run sim     # simulación de balance: 1000 partidas x 3 bots
npm run build   # build de producción (tsc + vite)
```

**Controles:** ← → (o A/D) mover · ESPACIO bancar / empezar.

**Reglas en 20 segundos:** cachar un dado suma su valor × multiplicador a tu
racha. Dos caras iguales seguidas suben el multiplicador. Cachar un 1 quita
una vida y borra la racha. ESPACIO banca la racha (y el multiplicador vuelve
a x1). Al morir solo cuenta lo bancado.

- Diseño y reglas exactas: [DESIGN.md](DESIGN.md)
- Historia del balance: [TUNING_LOG.md](TUNING_LOG.md)
- Onboarding para Claude Code: [CLAUDE.md](CLAUDE.md)

Cero dependencias de runtime: TypeScript + Vite + Canvas 2D + WebAudio
procedural. Toda la simulación corre headless (así funciona `npm run sim`).
