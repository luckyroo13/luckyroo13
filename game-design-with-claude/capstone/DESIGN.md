# SNAKE EYES

**Pitch (1 oración):** cacha dados que caen y decide cuándo bancar tu racha
antes de que los ojos de serpiente te la quiten.

**Core loop (1 oración):** muévete para cachar dados buenos y esquivar unos
→ tu racha crece → banca (y pierdes el multiplicador) o arriesga una más.

**Estética objetivo:** tensión de casino — "una más y banco, lo juro".

**Decisión central del jugador:** bancar asegura la racha pero resetea el
multiplicador a x1; no bancar significa que un snake eye (o morir) te quita
todo lo no bancado.

**Habilidad de ejecución central:** posicionamiento bajo presión creciente.

**Condición de derrota:** 3 vidas; cachar un 1 quita una vida y la racha.

**Qué lo hace distinto:** el push-your-luck no es un menú — es posicional.
Bancar es una tecla que puedes apretar tarde porque estabas esquivando.

**Qué NO es este juego:** no hay power-ups, no hay niveles, no hay historia,
no hay tienda, no hay modo 2 jugadores. Una pantalla, un loop, tres minutos.

---

## Reglas exactas

- Dados caen con caras 1–6 pesadas (`tuning.ts: faceWeights`); el 1 empieza
  en ~26% y sube hasta ~46% conforme avanza la rampa de dificultad.
- Cachar cara N: `racha += N × multiplicador`.
- Cachar la misma cara dos veces seguidas ("par"): multiplicador +1 (máx x6).
- Dejar caer un dado no castiga, pero rompe la cadena de par.
- Cachar un 1: −1 vida, racha y multiplicador a cero.
- ESPACIO banca: `banco += racha`, racha y multiplicador a cero.
- Al morir, el score final es solo lo bancado.
- Dificultad: velocidad de caída y frecuencia de spawn suben con una curva
  saturante (~90s hasta el techo). Partida mediana objetivo: ~2 minutos.
