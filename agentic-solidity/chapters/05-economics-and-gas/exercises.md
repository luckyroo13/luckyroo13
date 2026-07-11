# Chapter 5 — Exercises

## Exercise 5A — Capture the auction

Read `src/ch05/NaiveAuction.sol`. It has no reentrancy, no access-control bug, no
bad arithmetic. Before running anything, answer:

1. What does `bid` do to the *previous* highest bidder, and what does it require to
   succeed?
2. If the previous highest bidder is a contract that reverts on receiving ETH,
   what happens to the next person's bid?
3. What does the attacker gain? (Hint: not money.) Why does that make it invisible
   to a profit-focused reviewer?

Run the exploit:

```bash
forge test --match-path test/ch05/AuctionGrief.t.sol -vv
```

`test_baseline_honestOutbidWorks` shows normal behavior; `test_exploit_
griefingFreezesAuction` shows a 1 ETH griefer surviving a 100 ETH bid.

## Exercise 5B — Redesign, don't patch

You cannot fix this with a smaller change than the payment model. Convince
yourself: is there *any* line edit to `NaiveAuction.bid` that keeps the push
refund and also can't be blocked by a hostile `receive`? (There isn't — as long as
`bid` depends on an untrusted party accepting ETH, that party can block it.)

Now study the real fix, `solutions/ch05/PullAuction.sol`, and run:

```bash
forge test --profile solutions --match-path solutions/ch05 -vv
```

Explain why crediting `refunds[highestBidder]` and letting them `withdrawRefund`
removes the griefing incentive entirely — who bears the cost of refusing ETH now?

**With an agent:** ask it to "make this auction safe from griefing." Does it reach
for pull payments, or does it try a `try/catch` around the refund (which forfeits
the griefer's refund but is subtler and has its own edge cases)? Compare its answer
to the pull design and reason about the tradeoffs.

## Exercise 5C — Gas as a DoS

No harness for this one — it's a design review. In `NaiveAuction`, imagine you add
a `distributeToAllBidders()` that loops over every address that ever bid and sends
each a small consolation refund.

1. Who controls the length of that loop?
2. How would an attacker make `distributeToAllBidders()` impossible to execute?
3. What's the fix, and why is it the *same shape* as the auction fix?

## Exercise 5D — The rules are the bug

For each scenario, the contract has **no code defect**. Describe, in one or two
sentences, the most profitable thing a rational adversary does — and the design
change that removes the incentive:

1. A pool pays rewards proportional to your staked balance, sampled at claim time,
   and lets you stake and unstake in the same transaction.
2. Governance passes a proposal if addresses holding >50% of the token vote in
   favor, counting balances at the moment of the vote.
3. A lending market offers a 0.1% bonus to whoever liquidates an underwater
   position, but liquidations cost ~0.3% in gas and slippage.

<details>
<summary>Discussion</summary>

1. Flash-loan a huge balance, stake, claim rewards, unstake, repay — earning
   rewards on capital you held for zero time and zero risk. Fix: accrue rewards
   over time held (checkpoint on stake), or forbid same-block stake+claim.
2. Flash-borrow >50% of the token, vote, repay — governance capture for the cost
   of a flash-loan fee. Fix: snapshot voting power at a past block (checkpointing)
   so a momentary balance can't vote.
3. Nobody liquidates because it's unprofitable; bad debt accrues and the protocol
   becomes insolvent. Fix: size the liquidation bonus above realistic
   gas+slippage so liquidation is reliably profitable — an incentive-design
   decision, not a code fix.

The through-line: in all three, the code is "correct." The loss is in the
incentives, and only actor-modeling — not testing — surfaces it.
</details>
