import { TUNING } from './tuning';
import { mulberry32, type Rng } from './rng';

export type Phase = 'title' | 'playing' | 'gameover';
export type DieState = 'falling' | 'caught' | 'shattered';

export interface Die {
  x: number; y: number; vy: number; rot: number; vrot: number;
  face: number; // 1..6
  state: DieState;
  stateTime: number; // segundos en el estado actual (anima catch/shatter)
}

export interface Particle {
  x: number; y: number; vx: number; vy: number;
  life: number; maxLife: number; color: string; size: number;
}

export interface FloatText {
  x: number; y: number; text: string; color: string; life: number; maxLife: number;
}

export interface GameState {
  phase: Phase;
  seed: number;
  rng: Rng;
  time: number;        // segundos en 'playing'
  player: { x: number };
  dice: Die[];
  particles: Particle[];
  floats: FloatText[];
  spawnTimer: number;
  lastFace: number;    // última cara cachada (para detectar pares); 0 = ninguna
  streak: number;      // puntos sin bancar
  multiplier: number;
  banked: number;
  best: number;
  lives: number;
  shake: number;
  freeze: number;      // hit-stop restante en segundos
  bankFlash: number;   // anima el "BANK!" del HUD
}

export function createInitialState(seed: number, best = 0): GameState {
  return {
    phase: 'title',
    seed,
    rng: mulberry32(seed),
    time: 0,
    player: { x: TUNING.canvas.w / 2 },
    dice: [],
    particles: [],
    floats: [],
    spawnTimer: 0,
    lastFace: 0,
    streak: 0,
    multiplier: 1,
    banked: 0,
    best,
    lives: TUNING.lives,
    shake: 0,
    freeze: 0,
    bankFlash: 0,
  };
}

// Reinicio de partida: nueva semilla, conserva el best.
export function startRun(state: GameState): void {
  const fresh = createInitialState((state.seed * 1103515245 + 12345) >>> 0, state.best);
  Object.assign(state, fresh, { phase: 'playing' });
}
