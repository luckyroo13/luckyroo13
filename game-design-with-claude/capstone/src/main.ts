import { createInitialState } from './state';
import { update } from './update';
import { render } from './render';
import { initInput, readInput } from './input';
import { initAudio, playEvents } from './audio';

const canvas = document.getElementById('game') as HTMLCanvasElement;
const ctx = canvas.getContext('2d')!;

initInput(window);
initAudio();

const state = createInitialState(Date.now() >>> 0);

// Fixed timestep con acumulador (cap. 2): la simulación siempre avanza a
// 60Hz sin importar el refresco del monitor.
const STEP = 1 / 60;
let accumulator = 0;
let last = performance.now();

function frame(now: number): void {
  // clamp: si la pestaña estuvo en background, no simular el tiempo perdido
  accumulator += Math.min((now - last) / 1000, 0.25);
  last = now;

  while (accumulator >= STEP) {
    const events = update(state, readInput(), STEP);
    playEvents(events);
    accumulator -= STEP;
  }

  render(ctx, state);
  requestAnimationFrame(frame);
}
requestAnimationFrame(frame);
