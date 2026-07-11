# Chapter 4 — Exercises

## Exercise 4A — Audit by review, then score yourself

Open the three contracts in `src/ch04/` and read them **without opening the
tests**. For each, write down:

- Every finding: the function, the bug class (from the taxonomy), and one
  sentence on how you'd exploit it.
- Your confidence (sure / suspect / hunch).

Only then run the exploits:

```bash
forge test --match-path "test/ch04/*" -vv
```

Score yourself honestly:

- **Found and correctly classified** — good. Could you have written the exploit?
- **Suspected but couldn't articulate the attack** — this is the gap to close.
  A finding you can't turn into a failing test is a finding you can't defend.
- **Missed entirely** — note which taxonomy item you skipped. That's the checklist
  entry to burn into muscle memory.

Target findings (don't peek until you've written yours):

<details>
<summary>Finding list</summary>

- `VulnerableVault.withdrawAll` — reentrancy (external call before `balances = 0`).
- `VulnerableVault.setOwner` — missing access control (no modifier).
- `VulnerableVault.onlyOwner` — `tx.origin` authorization (phishable).
- `SpotOracleLoan.price` — spot-price oracle, manipulable via reserves/flash loan.
- `ShareVault.deposit` — first-depositor inflation: `balanceOf`-based price +
  rounding to zero, no minimum-shares / virtual-offset defense.
</details>

## Exercise 4B — Write an exploit from scratch

Pick the **oracle** bug (`SpotOracleLoan`). Delete `test/ch04/OracleExploit.t.sol`
from your mental model and write your own exploit test that:

1. Sets a fair pool price and deposits collateral.
2. Manipulates the reserves.
3. Borrows far more than the collateral is truly worth.
4. Asserts the protocol is now holding bad debt.

Then diff against the provided test. The point isn't to match it — it's that you
can *manufacture the adversarial transaction*, which is the skill. If you can only
recognize exploits but not author them, you can't verify an agent's "I fixed it."

## Exercise 4C — Human vs. agent audit (the real workflow)

1. Paste each `src/ch04` contract into your agent and ask: *"Audit this for
   security bugs. List each with severity and an exploit sketch."*
2. Put the agent's findings next to yours and next to the exploit suite. Fill in a
   3-way table: bug × (you found it?) × (agent found it?).
3. Reflect on the misses in both columns:
   - Bugs the agent missed are the ones you must own — usually the *emergent*
     ones (donation+rounding, spot+flashloan). Agents are strong on local
     patterns, weak on combinations.
   - Bugs *you* missed but the agent caught are your checklist gaps — fold them in.

The lesson of the chapter: the agent is a second reviewer, not the reviewer. You
run the adversary's program; the agent helps you enumerate. Neither alone is
enough, and only you can tell when the audit is done.

## Exercise 4D — Verify the fixes

```bash
forge test --profile solutions --match-path solutions/ch04 -vv
```

Read `solutions/ch04/SafeVault.sol` and `SafeShareVault.sol` and be able to
explain: why CEI *and* a guard (defense in depth)? Why does `tx.origin` → `msg.
sender` close the phishing vector? Why does a `+1/+1` virtual offset make the
inflation attack uneconomic rather than merely harder? And why is the oracle fix
*not* in the solutions as a one-liner — what does a real fix (TWAP / signed feed)
actually require? See `SOLUTION.md`.
