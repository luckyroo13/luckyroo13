// Simulación de balance (cap. 5): mil partidas headless por estrategia.
// Correr con: npm run sim
import { createInitialState } from './src/state';
import { update } from './src/update';
import type { InputFrame } from './src/input';
import { TUNING } from './src/tuning';

type Strategy = 'greedy' | 'cautious' | 'threshold';
const STEP = 1 / 60;

function botInput(state: ReturnType<typeof createInitialState>, strategy: Strategy): InputFrame {
  // objetivo: el dado no-snake más cercano a la bandeja; huir de los 1
  let targetX = state.player.x;
  let bestY = -Infinity;
  let threatX: number | null = null;
  for (const d of state.dice) {
    if (d.state !== 'falling') continue;
    if (d.face === 1) {
      if (Math.abs(d.x - state.player.x) < 70 && d.y > 380) threatX = d.x;
    } else if (d.y > bestY) {
      bestY = d.y; targetX = d.x;
    }
  }
  if (threatX !== null) targetX = threatX < state.player.x ? threatX + 130 : threatX - 130;

  const bank =
    strategy === 'greedy' ? false :
    strategy === 'cautious' ? state.streak > 0 :
    state.streak >= 25;

  return {
    left: targetX < state.player.x - 6,
    right: targetX > state.player.x + 6,
    bank,
    start: state.phase !== 'playing',
  };
}

function simulate(strategy: Strategy, seed: number): { score: number; duration: number } {
  const state = createInitialState(seed);
  update(state, botInput(state, strategy), STEP); // arranca la partida
  let steps = 0;
  const maxSteps = 60 * 60 * 10; // tope de 10 min por si un bot es inmortal
  while (state.phase === 'playing' && steps < maxSteps) {
    update(state, botInput(state, strategy), STEP);
    steps++;
  }
  return { score: state.banked, duration: state.time };
}

const pct = (xs: number[], p: number) => {
  const s = [...xs].sort((a, b) => a - b);
  return s[Math.min(s.length - 1, Math.floor(p * s.length))];
};
const fmt = (s: number) => `${Math.floor(s / 60)}:${String(Math.floor(s % 60)).padStart(2, '0')}`;

console.log(`Snake Eyes — simulación de balance (${JSON.stringify(TUNING.die.faceWeights)} pesos)\n`);
for (const strategy of ['greedy', 'cautious', 'threshold'] as Strategy[]) {
  const runs = Array.from({ length: 1000 }, (_, i) => simulate(strategy, i * 7919 + 13));
  const scores = runs.map(r => r.score);
  const durs = runs.map(r => r.duration);
  console.log(
    `${strategy.padEnd(10)} score p50=${String(pct(scores, 0.5)).padStart(4)} ` +
    `p95=${String(pct(scores, 0.95)).padStart(4)}  duración p50=${fmt(pct(durs, 0.5))}`
  );
}
console.log('\nSano: threshold > greedy y > cautious, con duración p50 ~2min.');
