# Capítulo 4 — Game feel: el 80% invisible

Toma dos builds del mismo juego: mismas reglas, mismos números. En uno,
cachar un dado suma puntos. En el otro, cachar un dado **truena**: el dado se
aplasta, salen chispas, el número flota hacia arriba, suena un pop con pitch
según el valor, y la pantalla apenas tiembla. El segundo juego es "mejor"
para el 100% de los jugadores, aunque sea mecánicamente idéntico.

Eso es **game feel** (o "juice"). Es la disciplina menos visible en un plan
de proyecto y la más visible en el producto. Los estudios buenos le dedican
más tiempo que a las mecánicas. Referencias canónicas que le puedes pedir
resumidas a Claude: la charla "Juice it or lose it" (Jonasson & Purho) y el
libro *Game Feel* de Steve Swink.

## El principio: cada acción del jugador merece una reacción

El contrato psicológico del juego es: *hiciste algo → el mundo respondió*.
Cuanto más inmediata, proporcional y multicanal (visual + audio + movimiento)
la respuesta, más "se siente bien". El checklist mínimo por cada evento de
gameplay:

1. ¿Hay respuesta **visual** en el objeto? (escala, flash, deformación)
2. ¿Hay respuesta en el **mundo**? (partículas, shake, pausa)
3. ¿Hay respuesta de **audio**?
4. ¿Hay respuesta en la **UI**? (el score que "late" al subir)

## Las cinco herramientas, con implementación

### 1. Tweening y easing — nada se mueve linealmente

En el mundo real nada arranca ni frena instantáneamente. Las funciones de
easing lo simulan barato:

```typescript
// easing clásico: t va de 0 a 1
const easeOutCubic = (t: number) => 1 - Math.pow(1 - t, 3);
const easeOutBack = (t: number) => { // se pasa tantito y regresa: "pop"
  const c = 1.70158;
  return 1 + (c + 1) * Math.pow(t - 1, 3) + c * Math.pow(t - 1, 2);
};
```

Úsalo para todo: el dado que aparece crece de 0 a 1 con `easeOutBack`, el
panel de game over cae con `easeOutCubic`. Regla de oro: **entradas rápidas
con rebote, salidas rápidas y secas.**

### 2. Partículas — el sistema más barato del mundo

```typescript
interface Particle { x: number; y: number; vx: number; vy: number;
                     life: number; maxLife: number; color: string; size: number; }

function burst(state: GameState, x: number, y: number, color: string, n = 12) {
  for (let i = 0; i < n; i++) {
    const a = Math.random() * Math.PI * 2, s = 60 + Math.random() * 180;
    state.particles.push({ x, y, vx: Math.cos(a) * s, vy: Math.sin(a) * s - 80,
      life: 0.5, maxLife: 0.5, color, size: 2 + Math.random() * 3 });
  }
}
// update: gravedad + vida; render: alpha = life/maxLife
```

Treinta líneas y de pronto todo evento tiene peso físico. En render, dibuja
con `alpha = p.life / p.maxLife` para que se desvanezcan.

### 3. Screen shake — con moderación quirúrgica

```typescript
// state.shake decae; render desplaza TODO el canvas
if (state.shake > 0) {
  ctx.translate((Math.random() - 0.5) * state.shake,
                (Math.random() - 0.5) * state.shake);
  state.shake *= 0.88; // decae exponencialmente
}
```

El shake comunica **daño y peso**, no éxito. Perder una vida: shake 12px.
Cachar un par: shake 3px o nada. El error de novato es hacer temblar todo —
si todo tiembla, nada importa.

### 4. Hit-stop / freeze frames

En los eventos grandes, congela la simulación 60–120ms (`state.freeze = 0.08`
y el update lo descuenta antes de simular). Suena contraintuitivo — ¿pausar
el juego lo hace sentir más rápido? — pero es el truco central de los juegos
de pelea y de Nintendo: el cerebro usa esa pausa para registrar el impacto.

### 5. Audio procedural con WebAudio — sin assets

No necesitas archivos de sonido para prototipar (¡ni para embarcar un
arcade!). WebAudio genera tonos en runtime:

```typescript
const actx = new AudioContext();
function beep(freq: number, dur = 0.08, type: OscillatorType = 'square', vol = 0.15) {
  const o = actx.createOscillator(), g = actx.createGain();
  o.type = type; o.frequency.value = freq;
  g.gain.setValueAtTime(vol, actx.currentTime);
  g.gain.exponentialRampToValueAtTime(0.001, actx.currentTime + dur);
  o.connect(g).connect(actx.destination);
  o.start(); o.stop(actx.currentTime + dur);
}
```

El truco de diseño: **mapea parámetros de audio a datos de gameplay.** En
Snake Eyes, el pitch del "pop" sube con el valor del dado (cachar un 6 suena
más agudo que un 2), y la racha de pares sube una escala musical. El jugador
no lo nota conscientemente; su cerebro sí.

## El proceso: pasada de juice dirigida

El juice no se agrega "al final" ni de golpe. El flujo con Claude:

1. Lista los eventos de gameplay (spawn, catch, pair, snake-eye, bank, death).
2. Para cada evento, decide su **peso emocional** (menor / medio / mayor).
3. Prompt por evento, con presupuesto:

> Evento: cachar un par (peso: mayor, es el momento de gloria del loop).
> Agrega: hit-stop de 90ms, burst de 24 partículas doradas, texto flotante
> "PAIR x2" con easeOutBack, y un arpegio de 3 notas ascendentes. Todos los
> valores nuevos van a tuning.ts.

4. Prueba **con las manos, no con los ojos**. El juice se evalúa jugando.
5. Luego quita el 20%. Siempre hay un 20% de más.

## Ejercicio con Claude

Toma tu prototipo y hazle una pasada de juice completa a UN solo evento (el
más frecuente de tu loop) usando las cinco herramientas. Después pídele a
Claude:

> Dame una versión con el juice al 300% — exagera todo: shake, partículas,
> hit-stop, escalas. Quiero sentir dónde está el límite.

Juega la versión exagerada 2 minutos. Sentir el "demasiado" te calibra el
"suficiente" mejor que cualquier regla. Luego ajusta a tu gusto en tuning.ts.

---

**Siguiente:** [Capítulo 5 — Sistemas: azar, balance y dificultad](05-sistemas-azar-y-balance.md)
