# Capítulo 2 — El esqueleto: setup y game loop

Hoy montamos el proyecto y el corazón técnico de todo juego en tiempo real:
el game loop. Es el único código de "infraestructura" del curso — de aquí en
adelante, todo es diseño.

## Setup: Vite + TypeScript, cero dependencias

```bash
npm create vite@latest mi-juego -- --template vanilla-ts
cd mi-juego && npm install && npm run dev
```

Eso es todo. Vite te da hot reload: guardas un archivo y el navegador se
actualiza en milisegundos. En game dev esto no es comodidad, es metodología —
**la velocidad de iteración es la variable que más predice la calidad final
de un juego.** Un tweak de gravedad que tarda 30 segundos en probarse se
prueba 5 veces; uno que tarda 1 segundo se prueba 50.

¿Por qué no Phaser/Godot/Unity? Para *aprender diseño*, un engine esconde
exactamente las partes que necesitas entender (el loop, el timestep, el
renderizado). Cuando las entiendas en crudo, cualquier engine te tomará una
tarde. Es la misma razón por la que un chef aprende con cuchillo antes que
con procesadora.

## El game loop: el latido del juego

Todo juego en tiempo real es esto:

```
mientras el juego corra:
    leer input
    actualizar el mundo (simular física, IA, timers)
    dibujar el mundo
```

En el navegador, el loop lo marca `requestAnimationFrame`, que dispara una
vez por refresco del monitor. Y aquí viene la primera trampa técnica seria.

### La trampa: monitores de 60Hz vs 144Hz

Si actualizas el mundo "una vez por frame", tu juego corre 2.4x más rápido
en un monitor de 144Hz que en uno de 60Hz. Bug clásico, embarcado en juegos
AAA reales. La solución estándar es el **fixed timestep con acumulador**
(el artículo canónico es "Fix Your Timestep!" de Glenn Fiedler — pídele a
Claude que te lo resuma):

```typescript
const STEP = 1 / 60; // simulamos a 60Hz fijos, sin importar el monitor
let accumulator = 0;
let last = performance.now();

function frame(now: number) {
  // clamp: si la pestaña estuvo en background, no simules 40s de golpe
  accumulator += Math.min((now - last) / 1000, 0.25);
  last = now;

  while (accumulator >= STEP) {
    update(STEP);        // la simulación SIEMPRE avanza en pasos fijos
    accumulator -= STEP;
  }
  render();              // el dibujado corre a la velocidad del monitor
  requestAnimationFrame(frame);
}
requestAnimationFrame(frame);
```

Lo importante como diseñador: **la simulación es determinista y separada del
renderizado.** Mismo input, mismo resultado, en cualquier máquina. Esto
también hace tu juego testeable — puedes correr `update()` mil veces en un
test sin dibujar nada.

### Input: estado, no eventos

Los eventos del DOM (`keydown`) llegan cuando el navegador quiere. El juego
pregunta cuando el loop quiere. La solución estándar: los eventos escriben en
un set, el update lo lee.

```typescript
const keys = new Set<string>();
window.addEventListener('keydown', e => keys.add(e.code));
window.addEventListener('keyup', e => keys.delete(e.code));

// en update():
if (keys.has('ArrowLeft')) player.x -= player.speed * dt;
```

Para acciones de "un solo disparo" (saltar, bancar) necesitas detectar el
flanco — presionado este paso pero no el anterior. Verás la implementación
en el capstone (`justPressed`).

## Tu primer prompt de implementación

Aquí empieza la colaboración real con Claude. Compara:

**Prompt débil:** "hazme un juego de una nave que dispara"

**Prompt de diseñador:**

> Lee mi documento de diseño en DESIGN.md. Crea el esqueleto del proyecto:
> Vite + TypeScript vanilla, Canvas 2D a 480x640 (vertical), game loop con
> fixed timestep a 60Hz y acumulador con clamp, input por teclado con estado
> (Set de teclas + detección de flanco), y un rectángulo controlable con las
> flechas para verificar que todo funciona. Sin dependencias de runtime, sin
> clases todavía — lo más simple que compile. Cuando termines, dime cómo
> verificar que el timestep es correcto.

Diferencias que importan: contexto (el doc de diseño), decisiones técnicas
ya tomadas (tú decides la arquitectura, Claude la ejecuta), alcance acotado
("lo más simple que compile"), y **criterio de verificación pedido de
antemano**. Esa última parte es hábito de lead: nunca aceptes trabajo sin
saber cómo se verifica.

## Verificación del capítulo

Con el esqueleto corriendo:

1. El rectángulo se mueve suave con las flechas y no se sale del canvas.
2. Abre DevTools → Rendering → "Frame rendering stats". La simulación no
   debe cambiar de velocidad aunque el FPS fluctúe (puedes forzar lag con
   CPU throttling en la pestaña Performance).
3. Cambia de pestaña 10 segundos y regresa: el juego no debe "explotar"
   simulando todo el tiempo perdido de golpe (eso verifica el clamp).

## Ejercicio con Claude

Pídele a Claude que rompa su propio código a propósito:

> Quita el acumulador y actualiza el mundo una vez por frame con dt variable.
> Explícame qué bugs de gameplay causaría esto en un monitor de 144Hz y en
> una laptop con lag, con ejemplos concretos usando mi juego.

Leer la explicación con el bug enfrente te lo graba para siempre. Luego
revierte.

---

**Siguiente:** [Capítulo 3 — Arquitectura que sobrevive la iteración](03-arquitectura-para-iterar.md)
