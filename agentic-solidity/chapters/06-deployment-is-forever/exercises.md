# Chapter 6 — Exercises

## Exercise 6A — Find and fix the timelock weakness

Read `src/ch06/Timelock.sol`. It has the right functions, the right constants
(`MINIMUM_DELAY`, `GRACE_PERIOD`), plausible events. Before running anything,
answer:

1. What does a timelock *guarantee*, in one sentence?
2. Which line would have to enforce that guarantee — and is it there?
3. Construct the sequence of calls that defeats the delay entirely.

Run the demonstration:

```bash
forge test --match-path test/ch06/Timelock.t.sol -vv
```

`test_delayedExecutionWorks` shows the intended path; `test_weakness_
zeroDelayExecution` shows the admin executing with zero delay — the timelock
protecting no one.

Now fix it. Add the two missing checks (a real `eta` floor on `queue`, an expiry
window on `execute`), then verify against the reference:

```bash
forge test --profile solutions --match-path solutions/ch06 -vv
```

Compare your fix to `solutions/ch06/SecureTimelock.sol`. Did you also bound the
*configured* delay in the constructor? Why does an unbounded `delay` (e.g. 100
years, or 0) matter?

## Exercise 6B — Delay your upgrades

Combine chapters. Take the EIP-1967 proxy from `solutions/ch02/EIP1967Proxy.sol`
and make its `admin` the `SecureTimelock` (not an EOA). Then:

1. Write a test where the multisig/admin *queues* an `upgradeTo(newImpl)` call
   routed through the timelock.
2. Assert the upgrade cannot take effect before the delay (`execute` reverts
   "too early").
3. Warp past the delay and assert the upgrade lands.

This is the real-world shape: upgrades are possible, but never sudden. Users get
the delay as a warning window. (You'll need `upgradeTo` to be callable only by the
timelock — think about how the proxy checks its admin.)

## Exercise 6C — Write the runbook

Open `RUNBOOK_TEMPLATE.md` and fill it in for a contract you'd actually deploy
(one of your own, or the Chapter 3 escrow). Do it *as if before deployment*. The
sections force the questions that are painful to answer live:

- Who can pause, through which key, how fast?
- What's the exact sequence to stop a drain in progress?
- Who are the signers, and how many are reachable within an hour?
- What do you tell users, and where?

If any answer is "we'd figure it out," that's the finding — you're not ready to
deploy. This is deliberately a *writing* exercise, not a coding one: incident
response is an operational discipline, the least delegable layer of all.

## Exercise 6D — Ask an agent to build a timelock

Prompt an agent: *"Write me a governance timelock for privileged actions."* Then
audit its output against `SecureTimelock`:

- Does `queue` enforce `eta >= now + delay`, or does it just store the eta?
- Is there an expiry (`GRACE_PERIOD`) window, or can stale actions execute
  forever?
- Is the configured `delay` bounded?
- Is the admin a single address it assumes you'll "set to a multisig later," or
  does the design make that explicit?

Grade it. This is the Chapter 1 loop on the most irreversible artifact you own —
the code that gates every future change to a live contract.
