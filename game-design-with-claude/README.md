# Game Design con Claude Code

> Un curso de 7 capítulos donde un lead game designer te enseña a diseñar,
> prototipar y terminar juegos usando Claude Code como tu equipo de desarrollo.

---

## Quién te habla

Imagina que soy tu lead. Llevo quince años embarcando juegos: mobile, consola,
jams de 48 horas y un free-to-play que murió en soft launch (de ese aprendí más
que de todos los demás juntos). Mi trabajo aquí no es enseñarte a programar —
Claude programa más rápido que los dos juntos. Mi trabajo es enseñarte a
**pensar como diseñador**: qué pedir, cómo evaluarlo, cuándo cortar, y cómo
convertir "una idea de juego" en algo que un extraño juega tres veces seguidas
sin que se lo pidas.

La tesis del curso: **con un agente de código, el cuello de botella ya no es
implementar — es saber qué vale la pena implementar.** El diseñador que sabe
articular un core loop, leer un playtest y dirigir la iteración vale diez veces
más que antes. Ese es el músculo que vamos a entrenar.

## El stack (2026, estándar de la industria web)

- **TypeScript** — todo tipado; los bugs de diseño ya son suficientes.
- **Vite** — dev server con hot reload instantáneo; iterar es el juego.
- **Canvas 2D** — sin engine. Para aprender diseño, el engine estorba; para
  embarcar después, lo que aprendas aquí mapea directo a Phaser, Godot o Unity.
- **Claude Code** — plan mode, skills, subagentes y verificación como flujo
  de trabajo, no como truco.

Cero dependencias de runtime. Todo lo que corre lo entiendes.

## Los capítulos

| # | Capítulo | Lo que sales sabiendo |
|---|----------|----------------------|
| 1 | [Cómo piensa un diseñador](chapters/01-como-piensa-un-disenador.md) | Core loop, MDA, y por qué "divertido" no es un requisito accionable |
| 2 | [El esqueleto: setup y game loop](chapters/02-esqueleto-y-game-loop.md) | Vite + TS, fixed timestep, y el primer prompt bien hecho a Claude |
| 3 | [Arquitectura que sobrevive la iteración](chapters/03-arquitectura-para-iterar.md) | Entidades, máquinas de estado, y por qué el código de juego se tira |
| 4 | [Game feel: el 80% invisible](chapters/04-game-feel.md) | Juice, tweening, partículas, screen shake, audio reactivo |
| 5 | [Sistemas: azar, balance y dificultad](chapters/05-sistemas-azar-y-balance.md) | Curvas de dificultad, aleatoriedad justa, push-your-luck |
| 6 | [Claude Code como tu equipo](chapters/06-claude-como-equipo.md) | Plan mode, CLAUDE.md, skills, subagentes, verificación |
| 7 | [Capstone: embarcar un juego original](chapters/07-capstone.md) | El proceso completo, del pitch al build final |

## El capstone: SNAKE EYES

El curso termina con un juego original y jugable: **[Snake Eyes](capstone/)**,
un arcade de push-your-luck donde cachas dados que caen del cielo. Los pares
multiplican, los ojos de serpiente matan, y tu puntaje no vale nada hasta que
lo bancas — y bancar te congela en el peor momento posible. Fue diseñado con
el proceso exacto de los capítulos 1–6, y el capítulo 7 documenta cada
decisión de diseño con su razón.

```bash
cd capstone
npm install
npm run dev
```

## Cómo tomar el curso

1. Lee cada capítulo **antes** de abrir Claude Code. Los capítulos te dan el
   criterio; Claude te da la velocidad. En ese orden.
2. Cada capítulo termina con un **ejercicio con Claude** — un prompt concreto
   y qué evaluar en el resultado. Hazlos. Leer sobre game feel sin sentirlo
   es como leer sobre nadar.
3. Al terminar el capítulo 7, tira Snake Eyes a la basura y haz tu propio
   juego con el mismo proceso. Ese es el examen final y nadie te lo califica
   más que tus playtesters.

---

*Escrito para desarrolladores que ya programan y quieren aprender a diseñar.
Si vienes de contratos inteligentes o infraestructura: bienvenido, aquí
también todo puede fallar en producción, solo que aquí le llamamos "el
jugador encontró la manera".*
