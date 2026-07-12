# Capítulo 1 — Cómo piensa un diseñador

Antes de escribir una línea de código, o de pedirle a Claude que la escriba,
necesitas poder responder tres preguntas sobre tu juego. La mayoría de los
proyectos que he visto morir, murieron porque nadie las respondió.

## 1. El core loop: ¿qué hace el jugador cada 10 segundos?

Un juego es un ciclo de **acción → feedback → decisión**, repetido. En Tetris:
mueves la pieza (acción), ves cómo encaja (feedback), decides dónde va la
siguiente (decisión). Ese ciclo dura segundos y se repite miles de veces.

Escribe el core loop de tu juego en una oración. Si necesitas dos, tu juego
todavía no existe. Ejemplos reales:

- *Tetris:* acomoda piezas que caen para completar líneas antes de que se
  llene la pantalla.
- *Vampire Survivors:* muévete para esquivar la horda mientras tus armas
  disparan solas y eliges mejoras.
- *Snake Eyes (nuestro capstone):* cacha dados buenos, esquiva los malos, y
  decide cuándo bancar tu puntaje antes de morir.

Fíjate que ninguna oración menciona gráficos, historia ni menús. El core loop
es lo que queda cuando quitas todo lo demás. Si el loop no es interesante con
rectángulos grises, no lo va a salvar el arte.

## 2. MDA: mecánica, dinámica, estética

El framework MDA (Hunicke, LeBlanc, Zubek, 2004 — viejo pero sigue siendo el
vocabulario estándar de la industria) separa tres capas:

- **Mecánica** — las reglas que programas. "Los dados caen a 200px/s. Un par
  del mismo valor multiplica x2."
- **Dinámica** — el comportamiento que emerge cuando el jugador juega con las
  reglas. "Los jugadores ignoran dados de valor bajo para pescar pares altos."
- **Estética** — la emoción que produce la dinámica. "Tensión: ¿banco ahora o
  arriesgo una racha más?"

La trampa: tú programas mecánicas, pero el jugador solo siente estéticas.
**No controlas la experiencia directamente — la controlas a través de dos
capas de emergencia.** Por eso el diseño es iterativo por naturaleza: ajustas
una regla, observas qué comportamiento emerge, y verificas si produce la
emoción que buscabas. Casi nunca a la primera.

Cuando le pidas algo a Claude, especifica la mecánica pero **declara la
estética que buscas**. "Haz que los dados caigan más rápido con el tiempo"
es una orden. "Quiero que a los 90 segundos el jugador sienta que apenas
sobrevive — sube la velocidad de caída gradualmente hasta lograrlo" es
dirección de diseño, y Claude puede proponerte tres mecánicas distintas para
lograrla.

## 3. ¿Divertido para quién? Decisiones vs. ejecución

"Divertido" no es accionable. Estas dos preguntas sí:

- **¿Qué decisiones interesantes toma el jugador?** Una decisión es
  interesante cuando tiene trade-offs reales y consecuencias visibles.
  Sid Meier: "un juego es una serie de decisiones interesantes".
- **¿Qué habilidad de ejecución exige?** Timing, precisión, velocidad de
  reacción. Los juegos de ejecución pura (Flappy Bird) y de decisión pura
  (ajedrez) existen, pero la mayoría de los arcades buenos mezclan ambas.

Snake Eyes, por diseño: la ejecución es cachar dados en movimiento; la
decisión es cuándo bancar. Quita cualquiera de las dos y el juego se
desinfla. Haz este análisis con tu idea antes de prototipar.

## El documento de una página

Olvida el "game design document" de 40 páginas — nadie lo lee y miente desde
el día dos. El estándar moderno en estudios pequeños es una página:

```markdown
# [Nombre del juego]

**Pitch (1 oración):** ...
**Core loop (1 oración):** ...
**Estética objetivo:** (tensión / flow / poder / descubrimiento / ...)
**Decisión central del jugador:** ...
**Habilidad de ejecución central:** ...
**Condición de derrota:** ...
**Qué lo hace distinto:** ...
**Qué NO es este juego:** (el scope-killer más importante de la lista)
```

Este documento vive en el repo, junto al código, y **es lo primero que Claude
lee en cada sesión** (capítulo 6). Es tu contrato de diseño: cuando a media
iteración se te ocurra agregar crafting, la línea "Qué NO es este juego" te
va a salvar el proyecto.

## Ejercicio con Claude

Todavía sin código. Abre Claude Code y pídele:

> Quiero diseñar un juego arcade de sesiones de 2–3 minutos, controlable con
> teclado, hecho en Canvas 2D. Propónme 3 conceptos distintos. Para cada uno
> dame: pitch de una oración, core loop, la decisión interesante central, la
> habilidad de ejecución central, y el riesgo de diseño principal (qué podría
> hacer que no funcione).

Evalúa las propuestas con el criterio de este capítulo: ¿el loop cabe en una
oración? ¿hay decisión Y ejecución? ¿el riesgo que señala es real? Elige una
(o mezcla) y escribe tu documento de una página. Lo vas a usar todo el curso.

---

**Siguiente:** [Capítulo 2 — El esqueleto: setup y game loop](02-esqueleto-y-game-loop.md)
