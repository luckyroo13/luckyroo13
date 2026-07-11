# Chapter 5 — Economics and Gas

> Agents micro-optimize gas beautifully. What they can't do is judge whether your
> incentives are sound — whether someone profits from breaking your contract, or
> can pay a little to grief a lot. That judgment is economics, and it has no
> compiler.

## Reframing gas

Ask an agent to "optimize this contract" and you'll get tighter storage packing,
`unchecked` blocks, cached array lengths, `calldata` over `memory`. All fine, all
delegable — it's the top-left quadrant from Chapter 1: low-stakes, easy to verify
(the gas report is right there). Let the agent have it.

The part that matters is a different question entirely: **gas as a weapon and a
cost, inside an adversarial economy.** Three lenses the agent doesn't apply on its
own:

1. **Griefing** — can someone spend a little to impose a large cost or a denial of
   service on everyone else, with no profit motive beyond the harm itself?
2. **Gas as a DoS surface** — does any function's gas cost grow with something an
   attacker controls (an unbounded loop, a list they can pad), until it exceeds
   the block gas limit and the function can never complete?
3. **Incentive misalignment** — does the contract, working exactly as written,
   reward behavior you didn't want? The exploit here isn't a bug at all; it's the
   rules being wrong.

None of these show up as a failing assertion or a red gas report. They show up as
someone doing the rational thing and your protocol losing.

## The exercise: an auction that's "correct" and still captured

`src/ch05/NaiveAuction.sol` has no reentrancy (effects precede the refund), no
access-control hole, no arithmetic bug. Every unit test passes. And it can be
seized for one low bid.

The flaw is the **payment model**. When a new bid arrives, the auction *pushes* a
refund to the previous highest bidder inside `bid`. A griefer bids from a contract
whose `receive` reverts. Now the refund to the griefer can never succeed, so every
attempt to outbid them reverts on `require(ok, "refund failed")`. The griefer
leads forever with a trivial bid. `test/ch05/AuctionGrief.t.sol` shows a 100 ETH
honest bid failing to displace a 1 ETH grief.

Notice the shape: the attacker has **no profit motive** — they don't take anyone's
money, they just *deny the auction to everyone*. A correctness-focused review
(including an agent's) sees clean code and moves on. Only an economic frame — "what
can someone impose on others for cheap?" — finds it.

The fix (`solutions/ch05/PullAuction.sol`) is not a line edit. It's switching from
**push to pull**: credit the outbid party a balance they withdraw themselves. One
account's refusal to accept ETH now hurts only that account. This is *the* reason
the pull-payment pattern exists — it removes the griefing incentive by removing
the shared control-flow dependency on an untrusted party's willingness to receive.

## Gas as a denial-of-service surface

The auction's griefing cousin is the **unbounded loop**. Any function that
iterates over a collection an attacker can grow — a list of stakers, recipients,
NFT holders — has a gas cost the attacker controls. Push it past the block gas
limit and the function reverts *for everyone, forever*. Distributions,
"claim-all", per-holder payouts, and "loop until done" cleanups are the usual
victims.

The tell is architectural, and it's the same push-vs-pull choice: any time the
contract loops to *send* value to N parties, ask "who chose N, and what happens at
N = 100,000?" The fix is again pull — let each party withdraw their share — so the
cost is bounded and paid by the beneficiary, not socialized into one gas-bombable
transaction.

## Incentive misalignment: the rules are the bug

The deepest version has no code defect at all. Examples worth holding in mind:

- A staking contract that pays rewards continuously but lets you stake and unstake
  in the same block — so a flash-loaned position harvests rewards it never
  risked.
- A fee that's cheaper to avoid than to pay, so nobody pays it.
- A liquidation bonus so small that no one liquidates, and bad debt accumulates;
  or so large that liquidators race to trigger it.
- A governance quorum reachable by a flash-borrowed token balance.

For each, the contract does *exactly what it says*. The loss comes from the
incentives being wrong. No test catches this, because there's nothing to assert
against — the behavior is "correct." Catching it requires modeling the actors:
*given these rules, what's the most profitable thing a rational, well-capitalized
adversary does?* That's economics, and it's the least delegable skill in the book.

## Why an agent can't own this for you

- **There's no oracle for "the incentives are sound."** Correctness has a spec;
  economics has a game with players. The agent can compute gas and check math, but
  "is this exploitable for profit or grief?" is a modeling question about
  adversaries, not a property of the code.
- **The exploits are rational behavior, not bugs.** The griefer, the flash-loan
  harvester, the fee-avoider are all playing the game you wrote correctly. An
  agent trained to produce and verify *correct* code is looking in the wrong
  place.
- **The fixes are design-level** — push vs pull, bonded actions, TWAP-gated
  governance, bounded loops. Those are architecture decisions with tradeoffs only
  you can weigh against your protocol's goals.

## Exercises

See [exercises.md](exercises.md):

1. Find and exploit the auction capture by review, then run
   `test/ch05/AuctionGrief.t.sol`.
2. Redesign it (push → pull) and verify with `solutions/ch05`.
3. Design-review three incentive scenarios and say what a rational adversary does.

Next: [Chapter 6 — Deployment Is Forever](../06-deployment-is-forever/README.md).
