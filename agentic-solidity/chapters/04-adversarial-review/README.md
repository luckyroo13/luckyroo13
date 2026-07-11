# Chapter 4 — Adversarial Review

> Reading code asks "does this do what it says?" Adversarial review asks "what
> can I make this do that it never intended?" Agents are fluent at the first
> question and blind to the second. That blindness is your job.

## Why this is the skill agents can't cover

An agent generates code by predicting plausible continuations. Plausible is a
cooperative frame — it writes the function the way the function is "supposed" to
go. An attacker is *uncooperative*: they call functions in orders you didn't
intend, from contracts instead of wallets, at prices they manufactured, with
values chosen to make your arithmetic round their way. The agent isn't modeling
that adversary. Worse, agent code often *looks* more trustworthy than
hand-written code — clean names, confident comments — which lowers your guard
exactly when you should raise it.

So adversarial review is not "read the agent's code more carefully." It's running
a *different program* in your head: the attacker's. This chapter gives you a
checklist for that program and a contract to practice on.

## The taxonomy — a review checklist for agent output

For every contract an agent hands you, walk this list. Each item is a question an
attacker is already asking.

1. **Reentrancy / CEI.** Does any function make an external call (`.call`,
   `.transfer`, a token hook, a callback) *before* it finishes updating state?
   If so, assume the callee re-enters. Checks-Effects-Interactions, plus a guard
   for anything holding value.
2. **Access control.** For every state-changing function: who is allowed to call
   it, and is that *enforced*? Watch for missing modifiers, `tx.origin` instead of
   `msg.sender`, and "admin" functions that only *look* protected by their name.
3. **Oracle / price.** Where does the contract learn a price or an amount? If it's
   a spot value it can be read at (an AMM reserve, `balanceOf`), it can be
   manipulated in the same transaction with a flash loan. Prefer TWAPs, signed
   feeds, and sanity bounds.
4. **Rounding & precision.** Every division truncates. Who benefits from the
   truncation — the protocol or the caller? Can a caller force a mint/rate/share
   to round to zero, or to round repeatedly in their favor? First-depositor share
   inflation is the canonical case.
5. **Front-running / MEV.** Is there a transaction whose profitability depends on
   ordering — a claim, a liquidation, a price update, an unprotected `approve`
   race? Assume the mempool is public and a bot reorders around you. (We push the
   economic side of this into Chapter 5.)

## The exercise contracts

`src/ch04/` ships three agent-style contracts, each of which compiles and whose
happy path works. Between them they contain the bugs above. Every bug has a
matching exploit in `test/ch04/` that *passes by successfully attacking* — that's
your proof the finding is real, not theoretical.

| File | Planted bugs | Exploit test |
|------|-------------|--------------|
| `VulnerableVault.sol` | reentrancy (CEI), missing access control, `tx.origin` auth | `VaultExploits.t.sol` |
| `SpotOracleLoan.sol` | spot-price oracle manipulation | `OracleExploit.t.sol` |
| `ShareVault.sol` | first-depositor share inflation (rounding) | `ShareInflation.t.sol` |

A few things worth internalizing from these:

- **The reentrancy uses `= 0` after the call, not `-= amount`.** Under Solidity
  0.8, a `-= amount` reentrancy often *reverts* on underflow and accidentally
  survives — so agents (and reviewers) get a false sense that "0.8 checked math
  fixed reentrancy." It didn't. The assignment pattern drains cleanly. Knowing
  *which* vulnerable shape is actually exploitable is exactly the depth this
  chapter trains.
- **The `tx.origin` bug is a phishing exploit.** The attack isn't calling the
  function directly — it's luring the *owner* into calling a malicious contract,
  where `tx.origin` is still the owner. `VaultExploits.t.sol` models that with
  `vm.prank(owner, owner)`.
- **The oracle bug is a design choice, not a typo.** `price()` is "correct" — it
  reads the pool honestly. The vulnerability is trusting a manipulable source at
  all. No line-level review finds this; only asking "where does this number come
  from and who controls it?" does.
- **The inflation bug is invisible without adversarial framing.** `ShareVault`'s
  math is textbook. It's only broken because an attacker can *donate* to move the
  price and *round the victim to zero*. That's two benign-looking facts combined
  by someone hostile.

## Why an agent can't own this for you

- It requires **modeling an adversary**, which is the opposite of the cooperative
  next-token frame the agent generates in. You can ask an agent "is this
  reentrant?" and often get a useful answer — but you have to *know to ask*, about
  the right function, which presupposes the very checklist this chapter is.
- Many of these bugs are **emergent, not local**: donation + rounding, spot price
  + flash loan, missing guard + tx.origin. Each ingredient is fine; the dish is
  poison. Reviewing line by line — the agent's strong suit — misses combinations.
- The **exploit is the proof**. In this domain "I think it's safe" is worth
  nothing; a passing attack test is worth everything. Writing that attack is a
  human act of imagination the agent will help with but won't initiate.

## Exercises

See [exercises.md](exercises.md):

1. Audit each `src/ch04` contract **by review only**, writing down findings before
   running anything. Then run the exploits and score yourself.
2. For one bug, write the exploit test yourself from scratch.
3. Have an agent audit the same contracts; compare its findings to yours and to
   the exploit suite. Where did it miss? Where did you?
4. Verify the fixes: `forge test --profile solutions --match-path solutions/ch04`.

Next: [Chapter 5 — Economics and Gas](../05-economics-and-gas/README.md).
