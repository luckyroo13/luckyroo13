# Incident Response Runbook — <CONTRACT NAME>

> Fill this in **before** deployment. If you're writing it during an incident,
> you're already too late. Keep it in the repo, next to the deploy scripts, and
> review it after every audit and every upgrade.

## 1. System facts (fill in at deploy time)

| Field | Value |
|-------|-------|
| Contract name / version | |
| Network(s) & address(es) | |
| Immutable or upgradeable? | |
| Proxy type (if any) | |
| Admin / owner (address) | |
| Admin is a multisig? | M-of-N = |
| Timelock address & delay | |
| Deployer key (retired?) | |
| Verified bytecode? (link) | |
| Total value at risk (est.) | |

## 2. Roles & contacts

| Role | Who | Reachable within… | Contact channel |
|------|-----|-------------------|-----------------|
| Incident commander | | | |
| Multisig signer 1 | | | |
| Multisig signer 2 | | | |
| Multisig signer N | | | |
| Comms lead | | | |
| Security advisor / auditor | | | |

- **How many signers are needed to act?** ____ of ____
- **How many can we realistically reach within 1 hour?** ____
- If we cannot reach quorum in an hour, what's the fallback? ____________

## 3. Emergency powers — what can we actually do?

For each, state whether it exists, who can trigger it, through which key, and how
long it takes (remember: a timelock delays *this* action too, unless pause is
exempt).

| Capability | Exists? | Who / which key | Time to effect | Notes |
|------------|---------|-----------------|----------------|-------|
| Pause deposits | | | | |
| Pause withdrawals | | | | |
| Full pause / circuit breaker | | | | |
| Upgrade to a patched implementation | | | | subject to timelock? |
| Move funds to safe custody | | | | |
| Rotate a compromised key | | | | |

> If "Full pause" is **No**, understand now that you have no stop button. That may
> be an acceptable choice for an immutable contract — but it must be a *chosen*
> one, documented here.

## 4. Detection

- What are we monitoring? (balance drops, TVL deltas, unexpected admin events,
  oracle deviation, failed-invariant alerts) ____________
- Where do alerts go, and who acknowledges them? ____________
- What's the threshold that declares an incident? ____________

## 5. Response playbooks

### 5a. Active drain (funds leaving now)
1. Declare incident; incident commander takes point.
2. <Exact call to pause / circuit-break — function, signer, key.>
3. Assemble signers for the multisig; reach quorum.
4. Contain: <upgrade to patched impl / move funds / disable the entry point>.
5. Verify the drain has stopped (on-chain balance stable).
6. Begin comms (section 6).

### 5b. Key compromise (admin/signer key leaked)
1. <Rotate the key / remove the signer from the multisig.>
2. Assume any pending timelock actions from that key are hostile — cancel them.
3. Audit what the key could have done and whether it did.

### 5c. Oracle / dependency failure
1. <Pause functions that consume the oracle.>
2. Switch to fallback source or halt until resolved.

## 6. Communications

- **Holding statement** (pre-written, fill the blanks): "We are aware of an issue
  affecting <CONTRACT>. Funds are <status>. Do not <action>. Updates at <channel>."
- Channels (in priority order): ____________
- Who approves public statements? ____________
- Point of contact for whitehats / disclosure: ____________

## 7. Post-incident

- [ ] Root-cause written up (what failed, and why the tests/invariants/review
      missed it).
- [ ] Invariant or test added that would have caught it (Chapter 3).
- [ ] Runbook updated with what we learned.
- [ ] Disclosure / postmortem published.

---

**Sign-off before deploy:** every section above is filled in, and the incident
commander and at least ____ signers have read it. Deploy date: ________  By: ______
