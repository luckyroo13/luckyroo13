# Chapter 7 — The Agentic Workflow (Capstone)

> Now put it together. You have a spec and a grading suite. You do **not** write
> the contract — an agent does. Your job is everything around it: define correct,
> gate the output, review it adversarially, and decide whether it's fit to deploy.
> That loop is the job in the agentic era.

## The setup

`src/ch07/IVesting.sol` is a specification for a linear token-vesting vault:
grantor locks ERC20 tokens for a beneficiary, tokens vest linearly over a
duration, beneficiary claims what has vested. The interface and the required
behavior/invariants are written out at the top of that file.

`test/ch07/VestingGrading.t.sol` is the **grading suite** — the executable
specification. It checks:

- **Vesting-curve correctness** (Chapter 2/3): the math is exactly linear, zero
  before start, capped after end.
- **Claim mechanics**: partial claims, no double-claim at the same instant, full
  claim after vesting.
- **Access control** (Chapter 4): only the beneficiary claims; grant ids can't be
  overwritten.
- **Solvency invariant** (Chapter 3): fuzzed grant/claim/time-jump sequences can
  never drive the vault below the liabilities it owes.

`src/ch07/VestingVault.sol` is a correct reference implementation, present only so
the repo is green on a fresh clone. In the capstone you throw it away and have an
agent produce its own.

## The loop

This is the entire method the tutorial has been building toward. Run it for real.

### 1. Own the specification (Chapters 1, 3)

Read `IVesting.sol` and the grading suite until you can state, without looking,
every property that must hold. This is the non-delegable core: the grading suite
*is* your intent made executable, and it's the asset that outlives any
implementation. If you can't articulate the invariants, you can't grade anything —
stop here until you can.

### 2. Delegate the implementation (Chapter 1, top-right quadrant)

Hand the agent the interface and the prose spec. Prompt, roughly:

> "Implement this `IVesting` interface as a Solidity 0.8.24 contract backed by an
> ERC20. Linear vesting, claim-what's-vested, standard safety. Here's the
> interface: …"

Do **not** give it the grading suite. You want to test whether *its* code meets
*your* spec, not whether it can pattern-match to your tests.

### 3. Run the gate (Chapter 3)

Point `_deploy()` in the grading suite at the agent's contract (change the one
line that constructs `VestingVault`) and run:

```bash
forge test --match-path test/ch07/VestingGrading.t.sol -vvv
```

Read the failures as a spec conversation. Common places agent implementations
break, and the chapter that warned you:

- Vesting math off by rounding or using the wrong denominator → curve tests fail
  (Ch 2/3).
- `claimable` computed as `vested` without subtracting `claimed`, enabling
  over-claim → solvency invariant fails (Ch 3).
- Missing `only beneficiary` check, or checking `tx.origin` → access tests fail
  (Ch 4).
- Grant id overwrite allowed → the vault can be re-pointed, liabilities corrupted
  (Ch 4/2).
- Transfer before effects, or trusting `balanceOf` for accounting → solvency /
  reentrancy surface (Ch 4).

### 4. Review adversarially, beyond the suite (Chapter 4/5)

A green suite is necessary, not sufficient. Read the agent's code as an attacker:
any external call before state update? any place a griefer or a rounding choice
helps them? any incentive the vesting rules accidentally create (e.g. can a grant
be created with `start` in the far past to make everything instantly claimable —
is that intended)? Add a test for anything you find; extend your own gate.

### 5. Decide on deployment (Chapter 6)

Only now: is this contract fit to be made real and immutable? Would you want an
admin/pause path, given vesting runs for years? Who holds any key? Fill in the
`RUNBOOK_TEMPLATE.md`. The decision to deploy is the one step in this whole loop
the agent cannot take for you — and everything in steps 1–4 exists to earn the
confidence to take it.

## What you just practiced

Look back at the loop and notice: the agent did the one thing this tutorial spent
zero time teaching — writing the Solidity. You did everything else:

- **Specified** intent precisely enough to be executable (Ch 1, 3).
- **Held the EVM model** to know which failures were real (Ch 2).
- **Verified** with invariants instead of trust (Ch 3).
- **Attacked** the output instead of reading it charitably (Ch 4).
- **Judged** incentives no test could settle (Ch 5).
- **Owned** the irreversible act (Ch 6).

That is the Delegation Line in motion. The agent lives in the top boxes; you live
in the bottom-right, and that's exactly where the value — and the money — is.

## Exercise 7 — Run it end to end

1. Have an agent implement `IVesting` from scratch. Gate it with the suite.
   Iterate until green.
2. Now have the agent implement it *badly on purpose* — ask for a version with a
   subtle over-claim bug — and confirm the solvency invariant catches it. If it
   doesn't, your suite has a gap; close it.
3. Add one adversarial test the suite doesn't currently have, from your Chapter 4
   instincts.
4. Write the deploy decision: immutable or upgradeable, keys, timelock, runbook.
   One paragraph, defended.

`solutions/ch07/SOLUTION.md` discusses the reference implementation and the bugs
the suite is designed to catch.

---

That's the tutorial. The code was never the hard part — the agent had that
covered. The hard part was everything that decides whether the code should hold
real money, and that stayed yours the whole way through.
