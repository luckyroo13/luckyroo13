import type { GameEvent } from './update';

// Audio 100% procedural (WebAudio, sin assets). El pitch codifica gameplay:
// cachar un 6 suena más agudo que un 2, y los pares suben una escala.
let actx: AudioContext | null = null;

// Los navegadores bloquean AudioContext hasta el primer gesto del usuario.
export function initAudio(): void {
  const resume = () => {
    if (!actx) actx = new AudioContext();
    if (actx.state === 'suspended') void actx.resume();
  };
  window.addEventListener('keydown', resume, { once: false });
  window.addEventListener('pointerdown', resume, { once: false });
}

function beep(freq: number, dur = 0.08, type: OscillatorType = 'square', vol = 0.12, delay = 0): void {
  if (!actx || actx.state !== 'running') return;
  const t0 = actx.currentTime + delay;
  const o = actx.createOscillator();
  const g = actx.createGain();
  o.type = type;
  o.frequency.value = freq;
  g.gain.setValueAtTime(vol, t0);
  g.gain.exponentialRampToValueAtTime(0.001, t0 + dur);
  o.connect(g).connect(actx.destination);
  o.start(t0);
  o.stop(t0 + dur);
}

export function playEvents(events: GameEvent[]): void {
  for (const e of events) {
    switch (e.type) {
      case 'catch': // pitch según el valor del dado
        beep(320 + e.face * 70, 0.07);
        break;
      case 'pair': { // arpegio ascendente; sube con el multiplicador
        const base = 440 + e.multiplier * 40;
        beep(base, 0.09, 'square', 0.14);
        beep(base * 1.25, 0.09, 'square', 0.14, 0.07);
        beep(base * 1.5, 0.12, 'square', 0.14, 0.14);
        break;
      }
      case 'snakeEye':
        beep(140, 0.25, 'sawtooth', 0.18);
        beep(95, 0.3, 'sawtooth', 0.18, 0.1);
        break;
      case 'bank':
        beep(660, 0.06, 'triangle', 0.16);
        beep(880, 0.1, 'triangle', 0.16, 0.06);
        break;
      case 'death':
        beep(180, 0.4, 'sawtooth', 0.2, 0.15);
        beep(120, 0.6, 'sawtooth', 0.2, 0.3);
        break;
      case 'start':
        beep(523, 0.08, 'triangle', 0.14);
        break;
    }
  }
}
