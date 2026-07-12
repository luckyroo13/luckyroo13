# Capítulo 3 — Arquitectura que sobrevive la iteración

Verdad incómoda de la industria: **el código de gameplay se tira.** No porque
esté mal escrito, sino porque el diseño que implementaba resultó no ser
divertido. Si tu arquitectura hace que tirar y reescribir sea caro, tu
arquitectura está optimizando lo equivocado.

La meta de este capítulo no es "código limpio". Es **código barato de
cambiar**, que es distinto.

## Regla 1: el estado del juego es un objeto, y es inspeccionable

Todo lo que existe en tu juego vive en una estructura que puedes imprimir:

```typescript
interface GameState {
  phase: 'title' | 'playing' | 'gameover';
  player: Player;
  dice: Die[];
  particles: Particle[];
  score: number;
  banked: number;
  lives: number;
  time: number;
}
```

Beneficios inmediatos: puedes loguear el estado completo cuando algo falla,
puedes escribir tests que armen un estado y llamen `update()`, y Claude puede
razonar sobre tu juego leyendo un solo tipo. Cuando el estado está regado en
variables globales y closures, cada pregunta de "¿por qué pasó esto?" se
vuelve arqueología.

## Regla 2: máquinas de estado explícitas

Las dos máquinas de estado que todo juego tiene, aunque nadie las haya
declarado:

**La del juego** (`title → playing → gameover → title`). Hazla un union type
y un `switch` en update y render. Los bugs de "puedo moverme en la pantalla
de game over" o "el score no se reinició" son siempre una máquina de estados
implícita mal cosida.

**La de cada entidad.** Un dado en Snake Eyes está `falling`, `caught` o
`shattered`. Un enemigo patrulla, persigue o ataca. Cuando el comportamiento
depende de banderas booleanas sueltas (`isJumping && !isDead && canAttack`),
estás a tres features del bug imposible de reproducir. Un campo `state` con
union type y transiciones explícitas cuesta cinco minutos y paga todo el
proyecto.

```typescript
type DieState = 'falling' | 'caught' | 'shattered';
```

## Regla 3: separa datos de comportamiento (tuning como datos)

La decisión arquitectónica con más impacto en velocidad de iteración: **todos
los números de diseño viven en un solo archivo de configuración.**

```typescript
// tuning.ts — el panel de control del diseñador
export const TUNING = {
  die: { fallSpeedMin: 120, fallSpeedMax: 260, spawnInterval: 0.9 },
  player: { speed: 340, width: 72 },
  scoring: { pairMultiplier: 2, snakeEyePenalty: 1 },
  difficulty: { rampDuration: 90, speedRampFactor: 2.2 },
} as const;
```

Nada de `player.x += 340 * dt` con el 340 quemado en la lógica. Cuando el
playtest diga "se siente lento", el ajuste es un número en un archivo, no una
búsqueda por el código. Y cuando le pidas a Claude "haz la rampa de
dificultad 20% más agresiva", el diff es de una línea y lo puedes revisar en
dos segundos.

Los estudios grandes llevan esto a hojas de cálculo y editores visuales. El
principio es el mismo: **el diseñador ajusta datos, no código.**

## Regla 4: entidades como datos planos + funciones

Verás "ECS" (Entity-Component-System) mencionado en todos lados. Es el patrón
correcto para juegos con miles de entidades heterogéneas. Para un arcade de
un fin de semana es sobre-ingeniería. El punto medio pragmático:

- Cada tipo de entidad es una `interface` (datos planos, sin métodos).
- El comportamiento son funciones: `updateDice(state, dt)`, `updatePlayer(state, dt)`.
- Nada de jerarquías de herencia (`class Enemy extends Entity extends GameObject`).
  La herencia es la forma más cara de descubrir que tu diseño cambió.

Esto además es el estilo con el que Claude trabaja mejor: funciones puras
sobre datos visibles son fáciles de leer, modificar y verificar en diffs
pequeños.

## Regla 5: el render no decide nada

`render()` lee el estado y dibuja. Jamás modifica nada, jamás contiene
lógica de juego ("si está muerto, no dibujar Y TAMBIÉN resetear el timer").
La prueba de fuego: si borras `render()` completo, la simulación debe seguir
siendo correcta. Esto es lo que te permite testear gameplay sin navegador.

## Estructura de archivos del capstone

```
src/
  main.ts       // bootstrap: canvas, loop, wiring
  tuning.ts     // TODOS los números de diseño
  state.ts      // tipos + createInitialState()
  update.ts     // toda la simulación (funciones puras-ish)
  render.ts     // todo el dibujado (solo lee)
  input.ts      // teclado como estado + justPressed
  audio.ts      // sonido procedural (capítulo 4)
```

Siete archivos. Un humano lo lee en 20 minutos; Claude, en un tool call.
Resiste la tentación de "organizarlo mejor" hasta que dolor real lo pida.

## Ejercicio con Claude

Toma tu esqueleto del capítulo 2 y pídele:

> Refactoriza a esta estructura: state.ts con un GameState central y máquina
> de fases (title/playing/gameover), tuning.ts con todos los números,
> update.ts y render.ts separados donde render solo lee. Luego demuéstrame
> con un script que la simulación corre sin canvas: crea un estado, simula
> 600 pasos con input falso, e imprime el estado final.

Ese script final es la prueba de que tu arquitectura quedó bien — y es la
semilla de los tests de balance del capítulo 5.

---

**Siguiente:** [Capítulo 4 — Game feel: el 80% invisible](04-game-feel.md)
