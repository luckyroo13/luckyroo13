# Chapter 6 — Solution notes

## The timelock weakness

`Timelock` has every part of a timelock except the part that makes it one. Two
missing checks:

1. **`queue` never enforces the delay.** It stores whatever `eta` the admin
   passes. Pass `eta = block.timestamp` and `execute` — which only checks
   `block.timestamp >= eta` — succeeds in the same block. The delay is never
   applied. `SecureTimelock.queue` adds:

   ```solidity
   require(eta >= block.timestamp + delay, "eta before delay");
   ```

   That single line is the difference between a real guarantee ("nothing happens
   for `delay` seconds after it's announced") and a decorative constant.

2. **`execute` has no expiry.** A queued action stays executable forever. If a
   malicious or mistaken action is queued and everyone forgets about it, it
   remains a live privileged call indefinitely. `SecureTimelock.execute` adds:

   ```solidity
   require(block.timestamp <= eta + GRACE_PERIOD, "stale");
   ```

   so actions must be executed within a window and otherwise expire.

`SecureTimelock` also bounds the *configured* delay in the constructor
(`require(_delay >= MINIMUM_DELAY && _delay <= MAXIMUM_DELAY)`). Without it, a
delay of 0 makes the timelock a no-op, and an absurd delay (say 100 years) could
be used to permanently freeze governance — either extreme defeats the purpose, so
the safe range is enforced at construction.

## Why this is the perfect Chapter 6 artifact

The vulnerable timelock is not "buggy code." It's *structurally complete* and
*semantically empty*: correct function names, sensible events, well-named
constants that are never used to enforce anything. This is exactly the failure
mode of delegating a security-critical, hard-to-verify component: you get the
shape of the protection and, unless you know the invariant it's supposed to
enforce, no way to notice the substance is missing by reading it. The tell isn't
in any line — it's the absence of a line, and only someone who can state "a
timelock must make execution impossible before the delay" knows to look for it.

## On the runbook

There's no code to grade for 6C, and that's the point. The single most common
operational failure isn't a missing `require` — it's deploying with no answer to
"what do we do when it's draining?" The runbook forces those answers while you're
calm: who can pause, through which key, how fast; how many signers you can reach in
an hour; what you tell users. If the honest answer to "can we pause?" is "no," that
might be fine for an immutable primitive — but it has to be a decision you made,
not one you discover at 3am.

## The chapter's place in the whole

Deployment is the bottom-right corner of the Chapter 1 quadrant taken to its
limit: maximum cost of being wrong (irreversible, live, funded) and minimum
verifiability (no test can tell you your key management is sound or your
immutable/upgradeable choice fits your threat model). It is the one part of the
agentic workflow the agent cannot take back for you — which is why the decision to
deploy, and everything gating it, stays firmly in human hands.
