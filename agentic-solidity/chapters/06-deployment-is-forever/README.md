# Chapter 6 — Deployment Is Forever

> Writing the contract is reversible — you can rewrite it a hundred times. The
> deploy transaction is not. It is the one moment in the whole workflow that an
> agent cannot take back for you, and it's where the stakes are highest and the
> verifiability is lowest. This is the deepest corner of the bottom-right
> quadrant.

## The one-way door

Everything before deployment is a draft. The instant your `CREATE` transaction
confirms:

- The **code is immutable**. Whatever bug it has, it has forever, unless you built
  an upgrade path *in advance*.
- The **address is live and public**. Adversaries — increasingly, adversarial
  agents — begin probing it immediately.
- The **keys that control it are now load-bearing**. A compromised deployer or
  admin key is a compromised protocol.
- **Value arrives**, and now every mistake has a dollar figure.

You can delegate writing the contract. You cannot delegate *the decision to make
it real*, because that decision is irreversible and its consequences are hard to
verify in advance. Owning deployment means owning three things: what's immutable
vs upgradeable, how privileged actions are gated in time, and what you do when
(not if) something goes wrong.

## Immutable vs upgradeable: the decision that defines your risk

This is a genuine trade, and it's yours to make:

- **Immutable** — no admin can change the code. Maximum credibility (users don't
  have to trust you), zero upgrade risk, and zero recourse if there's a bug. Right
  for small, audited, finished primitives.
- **Upgradeable** — you can fix bugs and add features, at the cost of a powerful
  admin key that is now itself the biggest attack surface (see Chapter 2's proxy
  bugs) and a trust assumption users must accept.

There's no default answer. What there *is*, is a wrong way to decide: letting an
agent scaffold an upgradeable proxy because that's the common template, without
anyone consciously choosing to accept an admin key as a permanent liability. The
choice must be deliberate, because it's a one-way door either way — immutable
can't gain an upgrade path later, and upgradeable can rarely credibly drop its
admin.

## Timelocks: make privileged actions announce themselves

If you *are* upgradeable (or have any privileged parameter), the admin key can, in
one transaction, change the rules under users' feet. A **timelock** defangs this:
privileged actions must be *queued*, then wait a fixed delay before they can
*execute*. Users who dislike a pending change have time to see it and exit. This
converts "trust the admin not to rug" into "watch the queue, and you'll have N days
of warning."

`src/ch06/Timelock.sol` is a timelock that compiles, has queue/execute/cancel,
constants named `MINIMUM_DELAY`... and doesn't actually enforce the delay. The
`queue` function never checks that `eta` is at least `delay` in the future, so the
admin can queue an action for *now* and execute it in the same block
(`test/ch06/Timelock.t.sol`, `test_weakness_zeroDelayExecution`). The "2 day
timelock" is a decorative comment.

This is precisely the kind of thing an agent produces: the *structure* of a
timelock (the right functions, the right constants, plausible events) without the
*invariant that gives it meaning* (an action cannot execute before the delay). It
looks like protection. It is theater. The fix (`solutions/ch06/SecureTimelock.sol`)
is two `require`s — `eta >= block.timestamp + delay` on queue, and an expiry window
`block.timestamp <= eta + GRACE_PERIOD` on execute — but knowing they must be there
is the non-delegable part.

## Keys and multisig

The most sophisticated contract in the world is only as safe as the key that
admins it. Operational reality you own, not the agent:

- **No single EOA** should hold upgrade/admin power. Use a multisig (e.g. an
  M-of-N Safe) so one compromised key isn't fatal.
- **The timelock's admin should be the multisig**, and the multisig's signers
  should be real, separated humans/devices — not three keys in one `.env`.
- **The deployer key is not the admin key.** Deploy with one, hand control to the
  multisig+timelock, and retire the deployer.
- **Verify the deployed bytecode** matches your audited source (Etherscan verify,
  or compare the on-chain codehash). An agent-generated deploy script can silently
  deploy a different compiler version or settings than you reviewed.

None of this is Solidity. All of it is the human's job, because it's about trust,
separation of duties, and irreversibility — things with no unit test.

## Incident response: plan it before you need it

Deployment is forever, so assume the bad day will come and write the runbook while
you're calm. `chapters/06-deployment-is-forever/RUNBOOK_TEMPLATE.md` is a template
to fill in *before* you deploy. The point is not the document; it's that "what do
we do if funds are draining right now?" is not a question to first ask at 3am with
your protocol on fire. Who can pause? How fast? Through what key? What's the comms
plan? If your answer to any of these is "we'd figure it out," you're not ready to
deploy.

## Why an agent can't own this for you

- The deploy is **irreversible and outside the code**. An agent can write the
  deploy script; it cannot bear the consequence of running it, and bearing that
  consequence is the whole responsibility.
- The core choices — **immutable vs upgradeable, who holds keys, how long the
  timelock** — are trust and risk decisions with no correct default and no test to
  satisfy. They're judgment calls about *your* threat model.
- Agents reproduce the **shape** of safety (a proxy, a timelock, a multisig)
  without guaranteeing the **substance** (layout discipline, enforced delays, real
  key separation). Chapter 6's timelock is the proof: structurally a timelock,
  functionally none.

## Exercises

See [exercises.md](exercises.md):

1. Find and fix the timelock weakness; verify with `solutions/ch06`.
2. Wire the timelock as the admin of the Chapter 2 EIP-1967 proxy so upgrades are
   delayed.
3. Fill in `RUNBOOK_TEMPLATE.md` for a real contract you'd deploy.

Next: [Chapter 7 — The Agentic Workflow](../07-the-agentic-workflow/README.md).
