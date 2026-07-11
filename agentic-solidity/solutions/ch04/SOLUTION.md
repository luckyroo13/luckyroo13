# Chapter 4 — Solution notes

## The findings, and why each fix is what it is

### 1. Reentrancy (`VulnerableVault.withdrawAll`)

The external call runs before `balances[msg.sender] = 0`, so the recipient
re-enters with its balance still intact and drains everyone.

**Fix (`SafeVault`):** Checks-Effects-Interactions — zero the balance *before* the
call — **and** a `nonReentrant` guard. Why both? CEI alone is correct here, but as
contracts grow you add call sites and the ordering discipline slips; the guard is
cheap insurance that turns a future CEI mistake into a revert instead of a drain.
Defense in depth is the norm for value-holding code.

**The subtlety worth keeping:** the vulnerable version uses `balances = 0` *after*
the call, not `balances -= amount`. Under Solidity ≥0.8 a `-= amount` reentrancy
often reverts on underflow during unwinding and *accidentally* survives — which
teaches people the wrong lesson ("0.8 fixed reentrancy"). It didn't. Recognizing
which vulnerable shape actually drains is the depth this exercise trains.

### 2. Missing access control (`VulnerableVault.setOwner`)

No modifier. Anyone calls it and becomes owner. **Fix:** `onlyOwner`, and reject
the zero address. The lesson: a function's *name* ("setOwner", "adminOnly",
"rescue") is not a guard. Enumerate every state-changing function and prove the
guard exists — don't infer it from intent.

### 3. tx.origin authorization (`VulnerableVault.onlyOwner`)

`require(tx.origin == owner)` passes whenever the owner is the transaction's
originator — including when the owner has been phished into calling an attacker's
contract, which then calls `rescue`. **Fix:** `msg.sender == owner`. `tx.origin`
authorization is essentially never correct; it breaks the moment a legitimate user
interacts through any intermediate contract, and it's directly phishable.

### 4. Oracle manipulation (`SpotOracleLoan.price`)

`price()` reads the pool's instantaneous reserve ratio. It's *honest* code — and
that's the trap. A flash loan lets an attacker move the reserves, borrow against
the manipulated price, and repay the loan, all atomically. There is **no one-line
fix**, which is why it's not in the solutions as a patched contract. A real fix is
architectural:

- Use a **manipulation-resistant oracle**: a Chainlink-style signed feed, or a
  **TWAP** (time-weighted average) so a single-block move can't set the price.
- Add **sanity bounds / circuit breakers**: reject prices that deviate too far,
  too fast.
- Cap **LTV** well below 100% and separate the price source from the venue you
  can trade against.

The reason this matters for the agentic era: an agent will happily write
`price()` and it will pass every unit test, because unit tests don't include an
adversary with a flash loan. Only a human asking "where does this number come from
and who can move it?" catches it. The fix lives in *architecture*, the least
delegable layer.

### 5. First-depositor inflation (`ShareVault.deposit`)

Two benign facts combine: `totalAssets()` reads `balanceOf` (so a *donation* moves
the price), and shares floor to zero with no floor protection. The attacker seeds
1 wei, donates to inflate the single share, and the victim's 10k deposit mints 0
shares — the attacker redeems everything.

**Fix (`SafeShareVault`):** the virtual-shares / virtual-assets offset that
OpenZeppelin's ERC4626 adopted — compute as if the vault always holds one extra
virtual share and one extra virtual asset (`(assets * (supply + 1)) / (totalAssets
+ 1)`). Now the first share's price is bounded and a donation can't round a later
depositor to zero; an attacker would have to donate more than they could steal.
The extra `require(mintedShares > 0)` is a cheap backstop. `Ch04Fixes.t.sol` shows
the victim minting real shares instead of 0.

## The meta-lesson

Three of these five bugs (reentrancy shape, oracle source, inflation combination)
are invisible to line-by-line review and to a cooperative reader. They surface
only when you run the attacker's program: call in a hostile order, from a
contract, at a price you manufactured, with values chosen to round your way. The
agent will help you *check* each hypothesis and even write the patch — but forming
the hypothesis is the human's move, and a passing exploit is the only proof that
counts.
