# Capítulo 6 — Claude Code como tu equipo

Llevas cinco capítulos usando Claude como programador. Este capítulo lo
convierte en equipo: programador, QA, artista técnico y sparring de diseño —
con los roles que un lead usa en un estudio real. Todo lo de aquí es
funcionalidad estándar de Claude Code, no trucos.

## CLAUDE.md: el onboarding de tu estudio

Claude Code lee `CLAUDE.md` en la raíz del repo al inicio de cada sesión. Es
el documento de onboarding que le darías a un dev nuevo. Para un juego, el
mío siempre tiene cuatro secciones:

```markdown
# CLAUDE.md

## Qué es este juego
Lee DESIGN.md antes de cualquier cambio. La línea "Qué NO es este juego"
es un límite duro.

## Reglas de arquitectura
- Todos los números de diseño van a tuning.ts. Nunca constantes en la lógica.
- render.ts solo lee estado. La simulación corre sin canvas.
- El RNG de gameplay usa la semilla del estado, jamás Math.random().
- Entidades = interfaces planas + funciones. Sin herencia.

## Cómo verificar
- npm run dev y jugar una partida completa (title → playing → gameover → title).
- npx tsx sim.ts para cambios de balance: ninguna estrategia fija debe dominar.
- npm run build debe pasar sin errores de tipos.

## Estilo de colaboración
- Cambios de gameplay: un diff chico por mecánica, no refactors oportunistas.
- Si un cambio de diseño contradice DESIGN.md, señálalo antes de implementar.
```

Esa última línea es la más valiosa del archivo: convierte a Claude de
ejecutor en colaborador que defiende la visión del juego — incluso de ti
mismo a las 2am cuando quieres agregar crafting.

## Plan mode: diseña antes de implementar

Para cualquier cambio que toque más de un sistema, activa plan mode
(Shift+Tab). Claude explora el código y propone un plan **sin tocar nada**,
tú lo corriges y luego autorizas.

En game dev esto brilla porque las features tienen más soluciones que en el
software normal. "Agregar un power-up de imán" puede tocar el spawn, la
física, el render y el balance — y hay tres maneras razonables de hacerlo.
Quieres elegir la manera **antes** de que exista el código, porque revisar
un plan de 10 líneas cuesta un minuto y revisar 200 líneas equivocadas
cuesta una tarde.

Hábito de lead: al plan siempre pregúntale dos cosas — *¿qué parámetros
nuevos van a tuning.ts?* y *¿cómo verificamos que quedó?*

## Subagentes: paraleliza como un estudio

Claude Code puede lanzar agentes para tareas independientes (menciona
"usa un subagente" o configura agentes en `.claude/agents/`). Úsalo como
usarías a un equipo:

- **QA:** "Lanza un subagente que revise update.ts buscando bugs de estado:
  transiciones de fase incompletas, timers que no se resetean al reiniciar,
  entidades que sobreviven al game over."
- **Investigación:** "Mientras implemento, que un subagente investigue cómo
  resuelven otros arcades el problema de spawns injustos y me traiga 3
  patrones."

Regla del lead: los subagentes son para trabajo **paralelizable y
verificable**. El diseño central no se delega — se conversa.

## Los roles del equipo, como prompts

**Sparring de diseño** (el rol más subestimado):

> Aboga contra mi mecánica de bancar: dame los 3 argumentos más fuertes de
> por qué podría no funcionar, y qué juego ya intentó algo parecido y cómo
> le fue.

Claude conoce miles de juegos y postmortems. Úsalo como memoria institucional
de la industria: no para que decida, sino para que tu decisión esté informada.

**QA destructivo** (tu instinto de seguridad aplica directo):

> Actúa como tester adversarial. Lista 10 maneras en que un jugador podría
> romper este juego: exploits de puntaje, estados imposibles, spam de teclas,
> resize de ventana, pestaña en background. Luego verifica cada una en el
> código y repórtame cuáles son reales.

**Artista técnico:**

> La paleta actual es placeholder. Propón 3 paletas de 5 colores para un
> arcade nocturno de dados con neón, con los hex en tuning.ts, y aplica la
> que te parezca mejor. Los dados deben leerse en 100ms de un vistazo.

## El ciclo completo (y quién hace qué)

| Paso | Tú (diseñador) | Claude |
|------|----------------|--------|
| 1. Hipótesis | "El juego necesita más tensión al final" | Sparring: mecánicas candidatas |
| 2. Plan | Eliges mecánica y estética objetivo | Plan mode: propuesta técnica |
| 3. Build | Revisas el diff | Implementa, números a tuning.ts |
| 4. Verificar | **Juegas** (esto no se delega) | Corre sim.ts, typecheck, QA |
| 5. Tuning | Describes sensaciones | Propone ajustes de parámetros |
| 6. Registro | Decides qué se queda | Actualiza TUNING_LOG.md |

La fila 4 es el corazón del capítulo: **Claude puede verificar que el código
es correcto; solo tú puedes verificar que el juego es bueno.** Todo el resto
del flujo existe para maximizar tu tiempo jugando y decidiendo, que es el
trabajo que no se puede delegar.

## Ejercicio con Claude

Monta el estudio completo en tu prototipo:

1. Escribe tu `CLAUDE.md` con las cuatro secciones.
2. En plan mode, diseña e implementa una mecánica nueva de principio a fin
   con el ciclo de la tabla.
3. Corre la sesión de QA destructivo y arregla lo que salga real.
4. Cierra con el sparring: "¿cuál es la mayor debilidad de diseño del juego
   en su estado actual?" — y no lo arregles todavía. Anótalo. El capítulo 7
   trata de decidir qué se arregla y qué se embarca.

---

**Siguiente:** [Capítulo 7 — Capstone: embarcar un juego original](07-capstone.md)
