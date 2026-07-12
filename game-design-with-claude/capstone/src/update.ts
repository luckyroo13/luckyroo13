import { TUNING } from './tuning';
import { weightedPick } from './rng';
import { startRun, type Die, type GameState } from './state';
import type { InputFrame } from './input';

// Eventos de gameplay: la simulación los emite, main.ts los mapea a audio.
// La simulación nunca toca WebAudio directamente (corre headless en sim.ts).
export type GameEvent =
  | { type: 'catch'; face: number }
  | { type: 'pair'; multiplier: number }
  | { type: 'snakeEye' }
  | { type: 'bank'; amount: number }
  | { type: 'death' }
  | { type: 'start' };

const lerp = (a: number, b: number, t: number) => a + (b - a) * t;

// Rampa de dificultad: 0 → 1 con saturación suave (cap. 5).
export function difficultyRamp(time: number): number {
  return 1 - Math.exp(-time / TUNING.difficulty.rampDuration);
}

function spawnDie(state: GameState): void {
  const T = TUNING.die;
  const ramp = difficultyRamp(state.time);
  const weights: number[] = [...T.faceWeights];
  weights[0] = lerp(T.faceWeights[0], T.snakeWeightEnd, ramp);
  const face = weightedPick(state.rng, weights) + 1;
  state.dice.push({
    x: T.size / 2 + state.rng() * (TUNING.canvas.w - T.size),
    y: -T.size,
    vy: lerp(T.fallSpeedMin, T.fallSpeedMax, ramp) * (0.85 + state.rng() * 0.3),
    rot: state.rng() * Math.PI * 2,
    vrot: (state.rng() - 0.5) * 4,
    face,
    state: 'falling',
    stateTime: 0,
  });
}

function burst(state: GameState, x: number, y: number, color: string, n: number): void {
  for (let i = 0; i < n; i++) {
    const a = state.rng() * Math.PI * 2;
    const s = 60 + state.rng() * 180;
    state.particles.push({
      x, y,
      vx: Math.cos(a) * s, vy: Math.sin(a) * s - 80,
      life: 0.5, maxLife: 0.5, color, size: 2 + state.rng() * 3,
    });
  }
}

function float(state: GameState, x: number, y: number, text: string, color: string): void {
  state.floats.push({ x, y, text, color, life: 0.9, maxLife: 0.9 });
}

function catchDie(state: GameState, die: Die, events: GameEvent[]): void {
  const J = TUNING.juice, C = TUNING.colors;
  die.state = 'caught';
  die.stateTime = 0;

  if (die.face === 1) { // snake eye: vida y racha fuera
    state.lives -= 1;
    state.streak = 0;
    state.multiplier = 1;
    state.lastFace = 0;
    state.shake = J.snakeEyeShake;
    state.freeze = J.deathFreeze;
    burst(state, die.x, die.y, C.danger, J.particleBurstDeath);
    float(state, die.x, die.y, 'SNAKE EYE', C.danger);
    events.push({ type: 'snakeEye' });
    if (state.lives <= 0) {
      state.phase = 'gameover';
      state.best = Math.max(state.best, state.banked);
      events.push({ type: 'death' });
    }
    return;
  }

  const isPair = die.face === state.lastFace;
  if (isPair && state.multiplier < TUNING.scoring.maxMultiplier) {
    state.multiplier += TUNING.scoring.pairMultiplierStep;
  }
  state.streak += die.face * state.multiplier;
  state.lastFace = die.face;

  if (isPair) {
    state.freeze = J.pairFreeze;
    burst(state, die.x, die.y, C.gold, J.particleBurstPair);
    float(state, die.x, die.y, `PAIR x${state.multiplier}`, C.gold);
    events.push({ type: 'pair', multiplier: state.multiplier });
  } else {
    state.shake = Math.max(state.shake, J.catchShake);
    burst(state, die.x, die.y, C.dieFace, J.particleBurstCatch);
    float(state, die.x, die.y, `+${die.face * state.multiplier}`, C.text);
    events.push({ type: 'catch', face: die.face });
  }
}

export function update(state: GameState, input: InputFrame, dt: number, events: GameEvent[] = []): GameEvent[] {
  const T = TUNING;

  if (state.phase !== 'playing') {
    if (input.start) {
      startRun(state);
      events.push({ type: 'start' });
    }
    return events;
  }

  // hit-stop: el mundo se congela pero el tiempo del freeze corre
  if (state.freeze > 0) {
    state.freeze -= dt;
    return events;
  }

  state.time += dt;
  state.bankFlash = Math.max(0, state.bankFlash - dt);

  // jugador
  const half = T.player.w / 2;
  if (input.left) state.player.x -= T.player.speed * dt;
  if (input.right) state.player.x += T.player.speed * dt;
  state.player.x = Math.min(T.canvas.w - half, Math.max(half, state.player.x));

  // bancar: la racha activa se asegura, el multiplicador se paga (cap. 7)
  if (input.bank && state.streak > 0) {
    state.banked += state.streak;
    events.push({ type: 'bank', amount: state.streak });
    float(state, state.player.x, T.player.y - 30, `BANKED ${state.streak}`, T.colors.gold);
    state.streak = 0;
    state.multiplier = 1;
    state.lastFace = 0;
    state.bankFlash = 0.5;
  }

  // spawns
  const ramp = difficultyRamp(state.time);
  state.spawnTimer -= dt;
  if (state.spawnTimer <= 0) {
    spawnDie(state);
    state.spawnTimer = lerp(T.die.spawnIntervalMax, T.die.spawnIntervalMin, ramp);
  }

  // dados
  const catchTop = T.player.y - T.die.size / 2;
  for (const die of state.dice) {
    die.stateTime += dt;
    if (die.state !== 'falling') continue;
    die.y += die.vy * dt;
    die.rot += die.vrot * dt;
    const overlapsX = Math.abs(die.x - state.player.x) < half + T.die.size / 2 - 6;
    if (die.y >= catchTop && die.y <= T.player.y + T.player.h && overlapsX) {
      catchDie(state, die, events);
      if (state.phase !== 'playing') return events; // murió en este catch
    } else if (die.y > T.canvas.h + T.die.size) {
      die.state = 'shattered'; // se fue: no castiga, pero rompe la cadena de par
      if (die.face === state.lastFace) state.lastFace = 0;
    }
  }
  state.dice = state.dice.filter(d => d.state === 'falling' || d.stateTime < 0.3);

  // partículas y textos
  for (const p of state.particles) {
    p.x += p.vx * dt; p.y += p.vy * dt; p.vy += 400 * dt; p.life -= dt;
  }
  state.particles = state.particles.filter(p => p.life > 0);
  for (const f of state.floats) { f.y -= 40 * dt; f.life -= dt; }
  state.floats = state.floats.filter(f => f.life > 0);

  // el shake decae en update para que la simulación sea autónoma
  state.shake *= Math.pow(0.001, dt); // ~0.88 por frame a 60Hz

  return events;
}
