// El panel de control del diseñador. Cada número de gameplay vive aquí.
export const TUNING = {
  canvas: { w: 480, h: 640 },
  player: { speed: 340, w: 72, h: 18, y: 590 },
  die: {
    size: 34,
    fallSpeedMin: 120,
    fallSpeedMax: 400,
    spawnIntervalMax: 0.95, // al inicio
    spawnIntervalMin: 0.3,  // con la rampa saturada
    // índice 0 = cara 1 (snake eye). El 1 es amenaza, el 6 es premio.
    faceWeights: [26, 15, 15, 15, 15, 14],
    // el peso del snake eye crece con la rampa: 26 → snakeWeightEnd
    snakeWeightEnd: 62,
  },
  scoring: {
    pairMultiplierStep: 1, // cada par consecutivo sube el mult en +1
    maxMultiplier: 6,
  },
  lives: 3,
  difficulty: { rampDuration: 75 }, // segundos hasta ~saturar la rampa
  juice: {
    catchShake: 2,
    snakeEyeShake: 12,
    pairFreeze: 0.09,
    deathFreeze: 0.14,
    particleBurstCatch: 10,
    particleBurstPair: 24,
    particleBurstDeath: 32,
  },
  colors: {
    bg: '#0b0b12',
    grid: '#16162a',
    player: '#e8c15a',
    dieFace: '#f2ede4',
    diePip: '#1c1c26',
    snakeFace: '#c23b4b',
    snakePip: '#f2ede4',
    gold: '#ffd75e',
    danger: '#ff5d6c',
    text: '#f2ede4',
    dim: '#7a7a96',
  },
} as const;
