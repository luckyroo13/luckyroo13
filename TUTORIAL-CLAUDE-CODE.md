# Guía: cómo usar el apartado de Código (Claude Code)

Esta guía te enseña a usar **Claude Code**, la herramienta con la que estás interactuando ahora mismo desde la pestaña de "Código" en Claude. Es un agente de programación que puede leer, escribir y ejecutar código directamente en tus repositorios de GitHub, y está pensada para flujos como los tuyos: contratos en Solidity con Foundry, infraestructura con Docker, Prometheus y Nginx.

---

## 1. ¿Qué es Claude Code?

Claude Code es un agente de IA que trabaja **dentro de tu repositorio**. A diferencia de un chat normal:

- Clona tu repo en un contenedor aislado y puede leer cualquier archivo.
- Ejecuta comandos reales: `forge test`, `docker compose up`, `git commit`, etc.
- Hace cambios, los prueba y los sube a una rama para que tú los revises en un Pull Request.

Está disponible en varias formas:

| Forma | Dónde | Ideal para |
|---|---|---|
| **Web** (claude.ai/code) | Navegador — lo que usas ahora | Tareas delegadas: "arregla este bug y abre un PR" |
| **CLI** | Tu terminal | Trabajo diario en tu máquina, sesiones interactivas |
| **App de escritorio** | Mac / Windows | Similar al CLI pero con interfaz gráfica |
| **Extensión de IDE** | VS Code / JetBrains | Ver diffs y cambios dentro del editor |
| **GitHub Actions** | Tu repo | Responder a issues/PRs con `@claude` |

---

## 2. Empezar en la web (lo que estás usando)

1. Entra a **claude.ai/code** (o la pestaña "Código" en Claude).
2. Conecta tu cuenta de GitHub y autoriza los repositorios que quieras usar.
3. Selecciona un repositorio y escribe una tarea en lenguaje natural.
4. Claude clona el repo en un entorno en la nube, trabaja, y **empuja los cambios a una rama** (nunca directo a `main`).
5. Tú revisas el diff y decides si crear/mergear el Pull Request.

**Puntos clave del entorno web:**

- Cada sesión corre en un contenedor **aislado y efímero**: lo que no se haga commit y push, se pierde al terminar.
- Puedes configurar la **política de red** del entorno (sin red, solo paquetes, o red completa) al crearlo.
- Puedes pedirle que **vigile un PR**: responderá a comentarios de revisión y arreglará fallos de CI automáticamente.

### Ejemplos de tareas útiles para tus proyectos

```text
"Revisa CustodyChain.sol y busca vulnerabilidades de reentrancy y problemas con el patrón CEI"

"Escribe tests de Foundry (fuzz + invariantes) para la función de arbitraje multisig"

"Agrega un healthcheck al docker-compose del RPC Gateway y documenta las métricas de Prometheus"

"Explica cómo funciona la verificación de firmas EIP-191 en este contrato"
```

---

## 3. Instalar el CLI (para trabajar en tu terminal)

En tu máquina Linux:

```bash
# Instalación con npm (requiere Node.js 18+)
npm install -g @anthropic-ai/claude-code

# O con el instalador nativo
curl -fsSL https://claude.ai/install.sh | bash
```

Luego, dentro de cualquier proyecto:

```bash
cd ~/proyectos/custody-chain
claude
```

La primera vez te pedirá iniciar sesión (con tu cuenta de Claude o una API key). A partir de ahí escribes en lenguaje natural y Claude trabaja sobre los archivos del directorio.

### Flujo típico en el CLI

```text
> ¿Qué hace este repo?                      ← explora y te explica
> Corre forge test y arregla lo que falle   ← ejecuta, diagnostica, edita
> Haz commit de los cambios                 ← solo hace git si tú lo pides
```

Claude **pide permiso** antes de ejecutar comandos o editar archivos (según el modo de permisos que elijas), así que siempre tienes control.

---

## 4. Comandos slash esenciales

Dentro de una sesión (CLI o web) puedes usar comandos que empiezan con `/`:

| Comando | Qué hace |
|---|---|
| `/init` | Analiza tu repo y crea un archivo `CLAUDE.md` con documentación del proyecto |
| `/help` | Muestra la ayuda y comandos disponibles |
| `/clear` | Limpia el historial de la conversación (empieza de cero) |
| `/compact` | Resume la conversación para liberar contexto sin perder el hilo |
| `/model` | Cambia el modelo (Opus, Sonnet, Haiku…) |
| `/config` | Abre la configuración (tema, permisos, etc.) |
| `/review` | Revisa un Pull Request de GitHub |
| `/security-review` | Revisión de seguridad de los cambios pendientes — muy útil para tus contratos |

También puedes crear **comandos propios**: archivos Markdown en `.claude/commands/` de tu repo se convierten en comandos slash. Por ejemplo, `.claude/commands/audit.md` con instrucciones de auditoría se invoca como `/audit`.

---

## 5. CLAUDE.md — la memoria de tu proyecto

`CLAUDE.md` es un archivo en la raíz del repo que Claude **lee automáticamente al iniciar cada sesión**. Es donde pones el contexto que no quieres repetir cada vez:

```markdown
# CustodyChain

## Stack
- Solidity 0.8.24, Foundry
- Tests: forge test -vvv
- Formato: forge fmt

## Convenciones
- Patrón CEI (Checks-Effects-Interactions) obligatorio en toda función que mueva fondos
- Custom errors en vez de require con strings
- Los proofs de entrega usan EIP-191, nunca EIP-712 en este proyecto

## Comandos útiles
- Compilar: forge build
- Tests con gas report: forge test --gas-report
- Levantar entorno local: docker compose up -d
```

Consejos:

- Genera el primero con `/init` y luego edítalo a mano.
- Sé concreto: comandos exactos, convenciones, cosas que Claude no debe hacer.
- Puedes tener un `CLAUDE.md` global en `~/.claude/CLAUDE.md` (preferencias personales para todos tus proyectos) y uno por repo.

---

## 6. Buenas prácticas

1. **Tareas específicas > tareas vagas.** "Arregla el overflow en `_calculateCollateral` y agrega un test que lo reproduzca" funciona mejor que "mejora el contrato".
2. **Pide un plan primero** en cambios grandes: "Antes de tocar nada, dame un plan para migrar el escrow a un patrón pull-payment". En el CLI existe el *plan mode* (Shift+Tab) que investiga sin editar nada.
3. **Deja que verifique su trabajo.** Pídele que corra los tests después de cada cambio; Claude itera hasta que pasen.
4. **Revisa siempre el diff.** Claude trabaja en ramas precisamente para que tú tengas la última palabra antes de mergear.
5. **Usa `/compact` en sesiones largas** para no perder contexto, y `/clear` cuando cambies a una tarea sin relación.
6. **Aprovecha `/security-review`** antes de cada PR en tus contratos — encaja perfecto con tu enfoque de "entender por qué las cosas fallan".

---

## 7. Recursos

- Documentación oficial: https://code.claude.com/docs
- Claude Code en la web: https://code.claude.com/docs/en/claude-code-on-the-web
- Buenas prácticas de agentes de código: https://www.anthropic.com/engineering/claude-code-best-practices

---

*Guía generada con Claude Code como ejemplo práctico: este mismo archivo fue creado, commiteado y pusheado por el agente desde la web.*
