# Capítulo 7 — Capstone: embarcar un juego original

Este capítulo es distinto: no enseña una técnica nueva, documenta cómo las
seis anteriores produjeron **Snake Eyes**, el juego que vive en
[`capstone/`](../capstone). Léelo con el juego corriendo al lado
(`cd capstone && npm install && npm run dev`).

Y una advertencia de lead: la diferencia entre "sé hacer juegos" y "hice un
juego" es terminar. Terminar es una habilidad independiente y este capítulo
es sobre esa habilidad.

## El documento de una página (capítulo 1, aplicado)

```markdown
# SNAKE EYES

**Pitch:** cacha dados que caen y decide cuándo bancar tu racha antes de
que los ojos de serpiente te la quiten.
**Core loop:** muévete para cachar dados buenos y esquivar unos → tu racha
crece → banca (y pierdes la racha activa) o arriesga una más.
**Estética objetivo:** tensión de casino — "una más y banco, lo juro".
**Decisión central:** bancar congela tu multiplicador de vuelta a x1;
no bancar significa que morir te quita TODO lo no bancado.
**Ejecución central:** posicionamiento bajo presión creciente.
**Derrota:** 3 vidas; cachar un 1 (snake eye) quita una vida y la racha.
**Qué lo hace distinto:** el push-your-luck no es un menú — es posicional.
Bancar es una tecla que puedes apretar tarde porque estabas esquivando.
**Qué NO es:** no hay power-ups, no hay niveles, no hay historia, no hay
tienda. Una pantalla, un loop, tres minutos.
```

Cada decisión de los seis capítulos se puede rastrear a una línea de este
documento. Así se ve la disciplina de diseño en la práctica.

## Decisiones de diseño, con su porqué

**¿Por qué bancar resetea el multiplicador?** (cap. 1 y 5). En el primer
diseño, bancar era gratis, y la simulación de sim.ts lo confirmó en mil
partidas: el bot "banca cada 2 segundos" dominaba. Sin costo no hay decisión,
sin decisión no hay tensión. El costo (perder el multiplicador acumulado)
hace que cada banca sea una pequeña derrota voluntaria — exactamente la
estética de casino que buscábamos.

**¿Por qué los 1 empiezan en 26% y suben hasta ~46%?** (cap. 5). Con
distribución uniforme (16.6%), los playtests decían "me relajo". El 26%
inicial hace que nunca camines en línea recta. Pero la primera simulación
reveló que la velocidad no mata a un jugador que esquiva bien — solo los
snake eyes matan — así que la presión de final de partida tenía que venir
de la distribución, no de la física. El peso del 1 crece con la rampa. Todo
el proceso está en TUNING_LOG.md.

**¿Por qué el pitch del pop sube con el valor del dado?** (cap. 4). Es la
manera más barata de que el jugador *sienta* que un 6 vale más que un 2 sin
leer nada. El audio es información de diseño, no decoración.

**¿Por qué la rampa satura a los 75 segundos?** (cap. 5). El pitch dice
sesiones de 2–3 minutos. Con la rampa a 90s, el bot threshold sobrevivía
casi 5 minutos; tres iteraciones de tuning después (registradas en
TUNING_LOG.md), el bot perfecto muere a ~2:40 — un humano, antes. La
duración de la partida no es azar: es un parámetro que se diseña.

**Lo que cortamos.** Un power-up de "dado dorado", un modo de 2 jugadores y
un sistema de combos por color. Todos eran buenas ideas. Todos violaban
"Qué NO es este juego". El postmortem honesto de cualquier juego terminado
incluye un cementerio de buenas ideas — es la señal de que hubo diseño y no
solo acumulación.

## El proceso de las últimas horas: la lista de embarque

Cuando el juego "ya casi está", cambia de modo. Se acabó el diseño; empieza
el embarque. La lista estándar:

1. **El ciclo completo, diez veces.** Title → play → gameover → play otra
   vez. Los bugs de re-entrada (score que no resetea, entidades fantasma)
   son el 50% de los bugs de embarque. Es la máquina de estados del cap. 3
   cobrando su deuda si la cosiste mal.
2. **QA destructivo con Claude** (cap. 6): spam de teclas, resize, pestaña
   en background, AudioContext bloqueado hasta el primer input del usuario
   (política real de todos los navegadores — el juego debe manejarla).
3. **El playtest del extraño.** Dale el juego a alguien SIN explicarle nada
   y cállate. Donde pregunte "¿y ahora qué?", te falta comunicación en
   pantalla, no un tutorial. Snake Eyes muestra los controles en el title y
   el "BANK!" parpadea cuando hay racha en riesgo por esta razón.
4. **Build de producción** (`npm run build`) y probar el build, no el dev
   server.
5. **Congelar.** La última noche no se agregan features. Nunca. Es la regla
   más rota y más cara de la industria.

## Tu examen final

Ya jugaste Snake Eyes y leíste sus razones. Ahora:

1. **Borra la carpeta capstone de tu mente.** Tu juego no es "Snake Eyes
   pero con X".
2. Corre el ejercicio del capítulo 1 con Claude y escribe tu documento de
   una página. Original de verdad: si el pitch cabe en "es como [juego
   famoso] pero...", itera otra vez.
3. Semana 1: esqueleto + loop jugable con rectángulos (cap. 2–3). Si el
   loop no es interesante en gris, itera el loop, no el arte.
4. Semana 2: juice + balance simulado (cap. 4–5), con TUNING_LOG.md.
5. Semana 3: QA, playtest del extraño, lista de embarque, build.
6. Publícalo (GitHub Pages sirve un build de Vite gratis) y mándaselo a
   tres personas.

Cuando un extraño juegue tu juego tres veces seguidas sin que se lo pidas,
terminaste el curso. Bienvenido al oficio.

---

*Fin del curso. El código del capstone está en [`capstone/`](../capstone),
con su [postmortem de diseño](../capstone/DESIGN.md) incluido.*
