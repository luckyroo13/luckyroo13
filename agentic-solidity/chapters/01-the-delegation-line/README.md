# Chapter 1 — The Delegation Line

> The skill of the agentic era is not writing code or reviewing code. It is
> deciding, for each piece of work, whether you need to understand it yourself —
> and being right about that decision.

## The problem this chapter solves

You sit down to build a contract. The agent can write any part of it. If you
review every line as if you wrote it, you've thrown away the speed. If you review
nothing, you've deployed code you don't understand to an immutable, adversarial
environment. Neither extreme is a strategy. You need a principled way to spend
your scarce attention on the parts that actually matter.

That principle is the **Delegation Line**: the boundary between what you can hand
off and what you must own.

## Two axes

Place any task on two axes.

**Axis 1 — Cost of being wrong.** If this is subtly incorrect and ships, what
happens? For a `name()` getter: nothing. For the withdrawal accounting in a
vault: total loss of funds. Smart contracts skew this axis hard, because the
floor for "wrong" is often "all the money leaves and never comes back."

**Axis 2 — Verifiability.** Given the finished code, how expensive is it to
convince yourself it's correct? Some things you can pin with a test in thirty
seconds (does `2 + 2` come out to `4`?). Some things no unit test will ever fully
settle (is this contract reentrancy-safe under every call ordering? are the
incentives sound when the token price moves 80%?).

```
                   cost of being wrong
                    LOW            HIGH
                +-------------+-------------+
   EASY to      |  DELEGATE   |   DELEGATE  |
   verify       |  freely     |  + verify   |
                +-------------+-------------+
   HARD to      |  DELEGATE   |    OWN IT    |
   verify       |  + spot-    |  yourself    |
                |  check      |             |
                +-------------+-------------+
```

The trap is that **agents make everything *look* like the top-left box.** The
output is fluent, commented, and confident whether it's a getter or the core
settlement math. Fluency is not correctness. Your job is to look past the fluency
and ask which box the task is *actually* in.

## Worked placements

| Task | Cost if wrong | Verifiability | Quadrant | What you do |
|------|---------------|---------------|----------|-------------|
| ERC-20 `transfer`/`approve` boilerplate | Low (standard, battle-tested) | Easy (diff against a known-good impl) | Top-left | Delegate, glance |
| `constructor` wiring, events, getters | Low | Easy | Top-left | Delegate, glance |
| Fee math, reward-per-share accounting | High | Easy-ish (write the test) | Top-right | Delegate the code, **write the test yourself**, make it pass |
| Access-control matrix (who can call what) | High | Medium (enumerable) | Top-right | Delegate the code, enumerate every role×function yourself |
| Reentrancy / external-call ordering | High | **Hard** | Bottom-right | **Own it.** Trace every external call by hand |
| Storage layout of an upgradeable proxy | High | **Hard** | Bottom-right | **Own it.** You must be able to draw the slots |
| Economic / incentive design | High | **Hard** | Bottom-right | **Own it.** No test proves incentives are sound |
| Deciding what is immutable vs upgradeable | Catastrophic | **Hard** | Bottom-right | **Own it.** This is a one-way door |
| A deploy script, a formatting pass | Low | Hard-ish | Bottom-left | Delegate, spot-check |

Notice the pattern: the bottom-right — high cost, hard to verify — is exactly the
set of topics in Chapters 2 through 6. That is not a coincidence. This tutorial
*is* a tour of the quadrant you cannot delegate.

## Why "hard to verify" is the real axis

Cost of being wrong is easy to feel. The subtle axis is verifiability, because it
determines whether delegation is even *possible*.

If something is high-cost but **easy** to verify, delegation is safe: let the
agent write it, then run a check that would catch any error. The verification is
your safety net, so you don't need to have written the code. Chapter 3 is entirely
about manufacturing this situation on purpose — turning hard-to-verify correctness
into easy-to-verify correctness by writing invariants.

If something is high-cost and **hard** to verify, there is no net. You cannot
tell whether the agent got it right by looking, and no cheap test settles it. The
only thing standing between that code and a loss is your own understanding. That's
what "own it" means: not "write every character by hand," but "understand it
deeply enough that you'd have caught the bug."

## The move that makes you fast

Beginners try to own everything and are slow. The reckless try to delegate
everything and get drained. The skilled do something more interesting: **they
move tasks from the bottom-right to the top-right on purpose.**

You can't make reward math low-cost, but you *can* make it easy to verify by
writing a fuzz test first. You can't make an upgradeable proxy low-cost, but you
*can* make its storage layout easy to verify by pinning every slot with a test.
The entire craft is converting "I have to understand this perfectly forever" into
"I have a check that fails loudly if it's wrong." That conversion is the highest-
leverage thing you do, and it is the through-line of the whole tutorial.

## Exercise 1 — Place your own contracts

No code for this one. Take a contract you've actually written (or one the agent
recently wrote for you) and do this:

1. List every distinct piece of logic — every function or cluster of related
   functions.
2. For each, score cost-of-wrong (low/med/high) and verifiability (easy/hard).
3. Drop each into a quadrant.
4. For everything you landed in the bottom-right, write one sentence: *what is the
   check, or the understanding, that currently protects this?* If your answer is
   "I read it and it looked fine," that's a finding — that's a task you're
   treating as top-left when it's actually bottom-right.
5. For two of those bottom-right items, propose how you'd move them to the
   top-right: what test, invariant, or enumeration would turn "trust me" into "the
   harness fails if it's wrong?"

There's no harness for this exercise because the deliverable is a decision, not
code. But keep your list. In Chapter 7 you'll run the full agentic workflow on a
real spec, and you'll make exactly these calls under time pressure.

## What to carry forward

- Agents make everything look delegable. It isn't. Judge by cost × verifiability,
  not by how confident the output reads.
- The bottom-right quadrant — high cost, hard to verify — is the non-delegable
  core. It's the rest of this tutorial.
- The master move is converting hard-to-verify into easy-to-verify (Chapter 3),
  so that delegation becomes safe.

Next: [Chapter 2 — The EVM Is Your Mental Model](../02-the-evm-is-your-mental-model/README.md),
where "hard to verify" gets concrete — the agent writes plausible code that the
EVM executes in a context the agent didn't reason about.
