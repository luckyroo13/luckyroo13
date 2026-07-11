# Chapter 5 — Solution notes

## The auction capture

`NaiveAuction` pushes a refund to the previous highest bidder inside `bid`, and
`require(ok, "refund failed")` makes the *new* bid depend on the *old* bidder
being willing to receive ETH. A griefer bids from a contract whose `receive`
reverts; from then on every outbid attempt reverts, and the griefer leads forever
with a trivial bid. `AuctionGrief.t.sol` shows a 1 ETH grief surviving a 100 ETH
honest bid.

Two things make this the perfect Chapter 5 example:

- **It's not a code bug.** No reentrancy (effects precede the call), no
  access-control gap, no arithmetic error. A correctness review — human or
  agent — passes it. The defect is in the *control-flow economics*: `bid` couples
  its success to an untrusted party's cooperation.
- **The attacker has no profit motive.** They don't steal; they *deny*. Reviewers
  scanning for "how does someone take the money?" look right past it. You only see
  it by asking the griefing question: "what can someone impose on everyone else
  for cheap?"

## Why the fix must be a redesign

There is no line edit that keeps the push refund and resists the grief. As long as
`bid` sends ETH to the previous bidder and reverts on failure, that bidder can
force the revert. A `try/catch` that swallows the failed refund *does* unstick the
auction, but it silently forfeits the griefer's funds and introduces its own
questions (what if a legitimate contract bidder temporarily can't receive?). The
clean answer changes the payment model.

`PullAuction` credits `refunds[highestBidder] += highestBid` and exposes
`withdrawRefund`. Now:

- Outbidding never touches the previous bidder's code, so nobody can block it.
- Refusing to accept ETH hurts **only** the refuser — they simply leave their
  refund unclaimed. The cost of griefing is now borne by the griefer, which
  removes the incentive.

This is the pull-over-push pattern, and this griefing vector is exactly why it's
the default recommendation for any refund/withdrawal/distribution.

## The same shape, three times

Notice that the auction fix, the unbounded-loop DoS fix (5C), and half of the
incentive fixes (5D) are the *same architectural move*: don't make one transaction
responsible for pushing value to untrusted parties; let each party pull. Push
couples your liveness to their behavior; pull decouples it. Once you see this
shape you find it everywhere — and it's a design instinct, not something a gas
optimizer or a correctness checker will ever suggest.

## The meta-lesson

Everything in this chapter is "correct code that loses." That's the category
agents are structurally weakest on, because their training target is producing and
verifying *correct* code, and here correctness is not the question. The question is
what rational and malicious actors *do* with rules that work exactly as written.
Answering it is economic modeling, it has no compiler and no unit test, and it is
the least delegable judgment in smart-contract engineering.
