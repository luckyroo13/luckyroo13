# Chapter 3 — Solution notes

## The bug and the one-line fix

`EscrowBuggy.refund` is missing a single statement. Here it is, fixed (this is
exactly `EscrowGood.refund`):

```solidity
function refund(uint256 dealId) external {
    Deal storage d = deals[dealId];
    require(msg.sender == d.seller, "only seller");
    uint256 amt = d.amount;
    require(amt > 0, "nothing to refund");

    d.amount = 0;
    _totalEscrowed -= amt;   // <-- the missing line

    (bool ok,) = d.buyer.call{value: amt}("");
    require(ok, "transfer failed");
}
```

`EscrowGood` is the corrected contract in full; diff it against `EscrowBuggy` and
the missing `_totalEscrowed -= amt;` is the only difference.

## Why this is the whole point of the chapter

Notice what the *deliverable* was. It was not the fix — the fix is one line, and
the agent can write it in a second once it knows what's wrong. The deliverable was
`invariant_solvency`: the property that makes the bug detectable at all.

- A happy-path test (`test_buggy_passesNaiveHappyPathTest`) passes on the broken
  contract. Adding more happy-path tests doesn't help; you'd have to guess the
  exact sequence that exposes the drift.
- The invariant needs no such guess. "Balance equals declared liabilities" is
  false in a whole *class* of states, and the fuzzer only has to reach any one of
  them — which it does on essentially the first refund.

So in the agentic loop, the leverage is upstream of the code. You write the
invariant once; then every implementation the agent produces — the first draft,
the fix, next quarter's refactor — is graded by the same gate, automatically. The
contract is disposable. The specification is the asset.

## On the handler

The handler (`EscrowHandler`) is doing quiet, essential work: it constrains the
fuzzer to *valid* histories (real deal ids, funded deposits, no double-resolve).
Without it, the fuzzer wastes its whole budget on calls that revert at the first
`require`, and reverting calls change no state, so the invariant is never
meaningfully tested. A weak handler is the most common reason an invariant suite
is green but worthless — it never reached the dangerous states. Writing the
handler well (what are the legal moves? which actors exist? what's bounded?) is
you encoding your system's real state machine, and it is not something you can
hand off without understanding the system.

## Second invariant (Exercise 3B)

The sum-of-parts invariant — `Σ amountOf(liveDeals) == totalEscrowed()` — is
violated by the same missing line and is a good habit to add alongside solvency:
it localizes *which* accounting drifted, not just that the totals disagree. Track
the live-deal ids as a ghost array in the handler (append on deposit) and sum
`amountOf` over them in the invariant.
