import { TUNING } from './tuning';
import type { Die, GameState } from './state';

// render solo LEE el estado. Si borras este archivo, la simulación sigue
// siendo correcta (así corre sim.ts).

const PIPS: Record<number, [number, number][]> = {
  1: [[0, 0]],
  2: [[-1, -1], [1, 1]],
  3: [[-1, -1], [0, 0], [1, 1]],
  4: [[-1, -1], [1, -1], [-1, 1], [1, 1]],
  5: [[-1, -1], [1, -1], [0, 0], [-1, 1], [1, 1]],
  6: [[-1, -1], [1, -1], [-1, 0], [1, 0], [-1, 1], [1, 1]],
};

function drawDie(ctx: CanvasRenderingContext2D, die: Die): void {
  const C = TUNING.colors, size = TUNING.die.size;
  const snake = die.face === 1;
  let scale = 1, alpha = 1;
  if (die.state === 'caught') { // se aplasta y desvanece
    const t = Math.min(die.stateTime / 0.3, 1);
    scale = 1 + t * 0.6; alpha = 1 - t;
  }
  ctx.save();
  ctx.globalAlpha = alpha;
  ctx.translate(die.x, die.y);
  ctx.rotate(die.rot);
  ctx.scale(scale, scale);
  ctx.fillStyle = snake ? C.snakeFace : C.dieFace;
  const r = size / 2;
  ctx.beginPath();
  ctx.roundRect(-r, -r, size, size, 7);
  ctx.fill();
  ctx.fillStyle = snake ? C.snakePip : C.diePip;
  for (const [px, py] of PIPS[die.face]) {
    ctx.beginPath();
    ctx.arc(px * r * 0.5, py * r * 0.5, size * 0.09, 0, Math.PI * 2);
    ctx.fill();
  }
  ctx.restore();
}

function text(ctx: CanvasRenderingContext2D, s: string, x: number, y: number,
              size: number, color: string, align: CanvasTextAlign = 'center'): void {
  ctx.fillStyle = color;
  ctx.font = `bold ${size}px 'Courier New', monospace`;
  ctx.textAlign = align;
  ctx.fillText(s, x, y);
}

export function render(ctx: CanvasRenderingContext2D, state: GameState): void {
  const T = TUNING, C = T.colors, W = T.canvas.w, H = T.canvas.h;

  ctx.setTransform(1, 0, 0, 1, 0, 0);
  ctx.fillStyle = C.bg;
  ctx.fillRect(0, 0, W, H);

  // screen shake: desplaza todo el mundo
  if (state.shake > 0.3) {
    ctx.translate((Math.random() - 0.5) * state.shake, (Math.random() - 0.5) * state.shake);
  }

  // fondo: rejilla tenue de casino nocturno
  ctx.strokeStyle = C.grid;
  ctx.lineWidth = 1;
  for (let x = 0; x <= W; x += 40) {
    ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, H); ctx.stroke();
  }
  for (let y = 0; y <= H; y += 40) {
    ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(W, y); ctx.stroke();
  }

  if (state.phase === 'title') {
    text(ctx, 'SNAKE EYES', W / 2, 240, 44, C.gold);
    text(ctx, 'cacha dados · esquiva los 1', W / 2, 290, 16, C.text);
    text(ctx, 'pares consecutivos multiplican', W / 2, 315, 16, C.text);
    text(ctx, 'ESPACIO banca tu racha (y resetea el mult.)', W / 2, 340, 16, C.text);
    text(ctx, 'mueres: pierdes lo no bancado', W / 2, 365, 16, C.danger);
    text(ctx, '← → mover  ·  ESPACIO bancar / empezar', W / 2, 450, 15, C.dim);
    if (state.best > 0) text(ctx, `BEST ${state.best}`, W / 2, 500, 18, C.gold);
    return;
  }

  // mundo
  for (const die of state.dice) drawDie(ctx, die);

  for (const p of state.particles) {
    ctx.globalAlpha = p.life / p.maxLife;
    ctx.fillStyle = p.color;
    ctx.fillRect(p.x - p.size / 2, p.y - p.size / 2, p.size, p.size);
  }
  ctx.globalAlpha = 1;

  // jugador: bandeja
  const px = state.player.x, half = T.player.w / 2;
  ctx.fillStyle = C.player;
  ctx.beginPath();
  ctx.roundRect(px - half, T.player.y, T.player.w, T.player.h, 6);
  ctx.fill();

  for (const f of state.floats) {
    ctx.globalAlpha = f.life / f.maxLife;
    text(ctx, f.text, f.x, f.y, 18, f.color);
  }
  ctx.globalAlpha = 1;

  // HUD (sin shake)
  ctx.setTransform(1, 0, 0, 1, 0, 0);
  text(ctx, `BANK ${state.banked}`, 14, 30, 20, C.gold, 'left');
  text(ctx, '♥'.repeat(Math.max(0, state.lives)), W - 14, 30, 20, C.danger, 'right');
  if (state.phase === 'playing') {
    if (state.streak > 0) {
      const blink = state.streak >= 20 && Math.floor(state.time * 4) % 2 === 0;
      text(ctx, `racha ${state.streak}  x${state.multiplier}`, W / 2, 30, 18,
        blink ? C.danger : C.text);
      if (state.streak >= 20) text(ctx, 'BANK!', W / 2, 52, 14, C.danger);
    }
    if (state.bankFlash > 0) text(ctx, 'BANKED', W / 2, 30, 18, C.gold);
  }

  if (state.phase === 'gameover') {
    ctx.fillStyle = 'rgba(11,11,18,0.8)';
    ctx.fillRect(0, 0, W, H);
    text(ctx, 'GAME OVER', W / 2, 260, 40, C.danger);
    text(ctx, `bancaste ${state.banked}`, W / 2, 310, 20, C.gold);
    if (state.streak > 0) text(ctx, `(perdiste ${state.streak} sin bancar)`, W / 2, 340, 16, C.dim);
    text(ctx, `BEST ${state.best}`, W / 2, 380, 18, C.text);
    text(ctx, 'ESPACIO para jugar otra vez', W / 2, 440, 15, C.dim);
  }
}
