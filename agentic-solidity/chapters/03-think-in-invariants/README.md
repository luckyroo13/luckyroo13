# Chapter 3 — Think in Invariants

> Specification is the new programming. The agent will write the implementation.
> Your leverage is writing down what "correct" means so precisely that a machine
> can reject every implementation that isn't.

## The Chapter 1 move, made concrete

Chapter 1 said the master skill is converting *hard-to-verify* correctness into
*easy-to-verify* correctness. Invariants are how you do it. An invariant is a
property that must hold in **every** reachable state, no matter what sequence of
calls got you there. Once you've written one, you've turned "I have to trust this
contract is correct" into "the fuzzer fails loudly if it isn't." That is the
single highest-leverage artifact you produce in the agentic workflow — more
valuable than the contract, because the contract is now replaceable and the
invariant is the thing that grades every replacement.

## Why happy-path tests give false confidence

Look at `src/ch03/EscrowBuggy.sol`. It's a two-party escrow, and it's exactly
what an agent hands you: it compiles, `deposit` and `release` are flawless, and if
you write the obvious unit test — *"buyer deposits, seller refunds, did the buyer
get their ETH back?"* — it **passes**. See `test_buggy_passesNaiveHappyPathTest`.

But `refund` is missing one line: it pays the buyer and never decrements the
liability counter `_totalEscrowed`. After a single refund, the contract holds 0
ETH while its books claim it owes 1. That drift is how contracts get drained: the
accounting says there's money to pay the next person, and there isn't.

An example-based test asks "does this specific story end well?" There are
infinitely many stories. The bug lives in the ones you didn't write.

## The invariant that catches it

The property the buggy contract violates is one sentence:

> **Solvency:** the ETH the contract holds always equals the liabilities it
> declares. `address(escrow).balance == escrow.totalEscrowed()`.

That's it. It doesn't describe any particular sequence — it describes a truth that
must survive *all* sequences. Written as a Foundry invariant
(`test/ch03/EscrowInvariant.t.sol`):

```solidity
function invariant_solvency() public {
    assertEq(address(escrow).balance, escrow.totalEscrowed(),
        "ETH held must equal declared liabilities");
}
```

Foundry fires thousands of random `deposit`/`release`/`refund` sequences at the
contract through a *handler* and checks this after every step. Against
`EscrowGood` it holds. Against `EscrowBuggy` it fails on the first refund the
fuzzer stumbles into — which is almost immediately. The bug that survived a
hand-written unit test cannot survive one good invariant.

## Anatomy of an invariant test

Three pieces, all in `test/ch03/EscrowInvariant.t.sol`:

1. **The target** — the contract under test (`EscrowGood`).
2. **The handler** (`EscrowHandler`) — the fuzzer doesn't call your contract
   directly; it calls the handler, which makes *valid* calls (bounded deal ids,
   funded deposits, skips already-resolved deals). The handler is where you encode
   "reachable state," so the fuzzer spends its budget on plausible histories
   instead of reverting on garbage. Writing a good handler is itself a
   non-delegable skill: it's you telling the machine what your system's legal
   moves are.
3. **The invariant** (`invariant_solvency`) — the property, asserted after every
   sequence.

## Kinds of invariants worth writing

- **Conservation / solvency** — assets in == assets owed (this chapter).
- **Monotonicity** — a nonce, a total-supply cap, an epoch counter only ever
  moves one direction.
- **Access** — only role X can ever change state Y (enumerate it as a property,
  not a spot-check).
- **Sum-of-parts** — `totalSupply == Σ balances`; `totalStaked == Σ userStakes`.
- **No-free-money** — no sequence lets an actor end with more than they put in
  plus legitimately earned rewards.

For each, ask the Chapter 1 question: *is this high-cost and hard to verify by
reading?* If yes, it belongs in an invariant, because that's the only cheap way to
verify it.

## Why an agent can't own this for you

- The invariant **is the intent**, and intent is the one thing the agent can't
  supply — it can only optimize toward a target you define. Ask an agent to "make
  the tests pass" and a subtly wrong contract that satisfies weak tests is a
  *success* by its lights. The invariant is how you make the target correct.
- Agents write *example* tests by default — they pattern-match to "here's a test
  that exercises the function." Property thinking ("what must be true in every
  state?") is a different, harder mode, and it's exactly the mode that finds the
  bugs the agent itself introduced.
- You can absolutely have the agent *write the invariant code* once you've stated
  the property — that part is delegable. Deciding *which properties matter* and
  whether the handler actually reaches the dangerous states is not.

## Exercises

See [exercises.md](exercises.md):

1. Run the harness; watch solvency hold on `EscrowGood` and be violated by
   `EscrowBuggy`.
2. Add a second invariant (per-deal: `amountOf` is 0 once resolved; sum of live
   deals == `totalEscrowed`).
3. Have an agent "fix" `EscrowBuggy`, then grade its output *only* by whether your
   invariants pass — the Chapter 1 loop.

Next: [Chapter 4 — Adversarial Review](../04-adversarial-review/README.md).
