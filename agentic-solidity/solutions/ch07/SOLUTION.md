# Chapter 7 — Solution notes

## The reference implementation

`src/ch07/VestingVault.sol` is a correct, minimal implementation of `IVesting`.
The parts that matter:

- **Linear vesting** with the division *last*: `amount * elapsed / duration`. Doing
  the multiply before the divide preserves precision; `amount / duration * elapsed`
  would truncate early and under-pay (a Chapter 4 rounding trap).
- **`claimable = vestedAmount(now) - claimed`** — subtracting `claimed` is what
  makes repeated claims safe and keeps the vault solvent. Forgetting the
  subtraction is the single most common agent bug, and the solvency invariant
  catches it immediately.
- **CEI in `claim`**: update `claimed` and `_totalLiabilities`, then transfer.
- **`_totalLiabilities` tracked internally**, not derived from `balanceOf` — so a
  token donation can't distort accounting (the Chapter 4 lesson applied
  preventively).
- **Grant ids are write-once** (`require(g.beneficiary == address(0))`), so a grant
  can't be silently overwritten and its liabilities corrupted.

## What the grading suite is built to catch

The suite is the real deliverable of the chapter — it's the executable form of the
spec, and it's designed so that the failure modes map back to earlier chapters:

| If the agent's code does this… | …this test fails | Chapter |
|--------------------------------|------------------|---------|
| Wrong vesting formula / early truncation | `test_vestingCurveIsLinear` | 2, 4 |
| `claimable` ignores `claimed` (over-claim) | `invariant_solvency`, `test_noDoubleClaimAtSameTime` | 3 |
| Missing/`tx.origin` access check | `test_onlyBeneficiaryCanClaim` | 4 |
| Overwritable grant ids | `test_grantIdCannotBeOverwritten` | 2, 4 |
| `balanceOf`-based accounting drift | `invariant_solvency` | 3, 4 |

Notice that **no single test** proves the contract correct — the *suite* does, and
even then only up to the properties you thought to encode. That's the honest limit
of the method: your gate is exactly as good as your specification. Step 4 of the
workflow (adversarial review beyond the suite) exists because there's always a
property you didn't write down yet.

## The point of the whole exercise

You never wrote the vesting contract. You wrote the *spec* and the *gate*, you read
the agent's output like an attacker, and you owned the deploy decision. The agent
was faster than you at the Solidity and worse than you at everything that decides
whether the Solidity should hold money. That division of labor — agent in the top
quadrants, you in the bottom-right — is the whole tutorial, and this capstone is
you running it once, for real, end to end.
