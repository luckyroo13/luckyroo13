// Input como estado: los eventos escriben, el update lee.
const down = new Set<string>();
const pressedThisStep = new Set<string>();

export function initInput(target: Window): void {
  target.addEventListener('keydown', (e) => {
    if (!down.has(e.code)) pressedThisStep.add(e.code);
    down.add(e.code);
    if (['ArrowLeft', 'ArrowRight', 'Space'].includes(e.code)) e.preventDefault();
  });
  target.addEventListener('keyup', (e) => down.delete(e.code));
}

export interface InputFrame {
  left: boolean;
  right: boolean;
  bank: boolean;  // flanco: solo el paso en que se presionó
  start: boolean;
}

export function readInput(): InputFrame {
  const frame: InputFrame = {
    left: down.has('ArrowLeft') || down.has('KeyA'),
    right: down.has('ArrowRight') || down.has('KeyD'),
    bank: pressedThisStep.has('Space'),
    start: pressedThisStep.has('Space') || pressedThisStep.has('Enter'),
  };
  pressedThisStep.clear();
  return frame;
}
