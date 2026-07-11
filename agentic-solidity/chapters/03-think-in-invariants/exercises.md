# Chapter 3 — Exercises

## Exercise 3A — Watch the invariant work

```bash
# Solvency holds on the correct implementation, plus the deterministic demos:
forge test --match-path test/ch03/EscrowInvariant.t.sol -vv
```

Read the four tests and be able to say, out loud:

- Why `test_buggy_passesNaiveHappyPathTest` gives false confidence.
- Why `test_buggy_violatesSolvency` catches what the happy-path test missed.
- What the *handler* (`EscrowHandler`) contributes — what would go wrong if the
  fuzzer called the escrow directly with fully random arguments instead?

**With real Foundry**, point the invariant runner at the buggy contract and watch
it fail. Copy `EscrowInvariantTest`, swap `EscrowGood` for `EscrowBuggy` in
`setUp`, and run `forge test --match-test invariant_solvency`. Foundry will hand
you a minimal reproducing sequence — read it; that shrunk counterexample is the
bug, stated as a call trace.

## Exercise 3B — Write a second invariant

Solvency is necessary but not sufficient. Add these properties to the harness and
make them pass on `EscrowGood`:

1. **Resolution is terminal.** Once a deal is released or refunded, `amountOf(id)`
   is 0 forever — no path resurrects it.
2. **Sum-of-parts.** The sum of `amountOf` over all live deals equals
   `totalEscrowed()`. (Track the set of ids in the handler with ghost variables —
   an array the handler appends to on each deposit — and sum them in the
   invariant.)

Then reason: does `EscrowBuggy` violate #2 as well as solvency? Which single line
would you add to `EscrowBuggy` to fix *both* at once? (This is the whole bug —
find it, then confirm against `solutions/ch03`.)

## Exercise 3C — Grade an agent's fix (the core loop)

This is the exercise the whole tutorial is built around.

1. Give an agent `src/ch03/EscrowBuggy.sol` and the prompt: *"This escrow has a
   bug. Fix it."* Do **not** tell it the invariant.
2. Take whatever it returns and run **your** invariant suite against it. Not its
   tests — yours.
3. Three outcomes, and each teaches something:
   - Invariants pass → the fix is real. You verified it without reading every
     line, because you owned the specification.
   - Invariants fail → the agent's fix is wrong or incomplete, and you caught it
     automatically. Feed the counterexample back and iterate.
   - The agent "fixes" it by weakening a test → notice that it optimized for
     *plausible*, exactly as warned. Your invariant is immune because it describes
     truth, not examples.

The lesson: in the agentic workflow you are not the person who writes the fix. You
are the person who defines correct and owns the gate. `solutions/ch03/SOLUTION.md`
walks through the one-line fix and why the invariant is the real deliverable.
