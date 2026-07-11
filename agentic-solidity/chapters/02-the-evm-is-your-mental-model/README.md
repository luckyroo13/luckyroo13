# Chapter 2 — The EVM Is Your Mental Model

> An agent writes Solidity. The EVM runs bytecode in a *context* — a caller, a
> storage layout, a delegatecall frame — that the source code doesn't show and
> the agent didn't reason about. The bugs live in that gap.

## Why this is the first hard-to-verify skill

In Chapter 1 we said the non-delegable core is the stuff that's high-cost and
hard to verify. The most common way agent code goes wrong isn't a typo — it's a
correct-looking contract that does the wrong thing *because of where and how the
EVM executes it*. Two contracts that are each individually fine can be
catastrophic together. No amount of reading the source in isolation reveals it;
you have to be running the EVM in your head.

This chapter drills the two pieces of execution context that agents most reliably
get subtly wrong: **storage layout** and **delegatecall's shared storage**.

## Part A — Storage layout is a compiler fact, not a source fact

Solidity lays out state variables into 32-byte slots by a fixed set of rules:

- Slots fill from 0, in **declaration order**.
- Value types **pack** into the same slot if they fit in the remaining bytes,
  low-order first. A `uint128` then two `uint64`s fill one slot exactly.
- A variable that doesn't fit in the remaining space starts a **new slot**.
- `mapping` and dynamic arrays reserve their slot as a placeholder; the real data
  lives at a hashed location — `balances[k]` is at `keccak256(abi.encode(k,
  slot))`.
- Reordering your variable declarations **changes the layout**. For a normal
  contract this is invisible. For an upgradeable one, it's how you corrupt every
  user's balance.

You cannot eyeball whether an agent preserved layout across an upgrade. You have
to be able to *derive the slots*, and then pin them with a test so the machine
checks you. That's the Chapter 1 move — converting "trust me" into "the harness
fails if it's wrong."

`src/ch02/StorageLayout.sol` is a packing puzzle. `test/ch02/StorageLayout.t.sol`
reads every slot with `vm.load` and asserts the real layout.

## Part B — delegatecall makes two contracts share one storage

`delegatecall` runs another contract's *code* against *your* storage and with
*your* `msg.sender`. It is the foundation of every upgradeable proxy — and the
single richest source of agent-generated disasters.

Ask an agent for "an upgradeable contract" without specifying storage discipline
and you'll often get `src/ch02/NaiveProxy.sol`: a proxy that stores its
`implementation` and `admin` in slots 0 and 1, delegatecalling to a logic
contract whose own `owner` and `value` *also* live in slots 0 and 1. Each file is
fine. Together, calling `initialize` through the proxy overwrites the proxy's
implementation pointer, because "slot 0" means the same physical location for
both. `test/ch02/ProxyCollision.t.sol` weaponizes exactly this: a non-admin
attacker repoints the proxy through an ordinary logic function.

The fix (`solutions/ch02/EIP1967Proxy.sol`) is the EIP-1967 pattern: the proxy
parks its bookkeeping at pseudo-random slots (`keccak256("eip1967.proxy.
implementation") - 1`) that no sequentially-laid-out logic contract will ever
collide with. Note what the fix does *not* require: the logic contract doesn't
change at all. The bug was never in the logic — it was in the shared context.

## Why an agent can't own this for you

- The bug is **cross-file and cross-context**. An agent reviewing either contract
  alone sees nothing wrong, and it reasons file-by-file far more than it reasons
  about the merged storage image at runtime.
- The layout is **invisible in the source**. `owner` doesn't say "slot 0"; you
  have to know the rule. Agents will confidently describe a layout that's subtly
  wrong, and it reads just as fluently as a correct one.
- The stakes are **upgrade-shaped**: these bugs surface on the second deploy, when
  real funds are already in the contract, which is the worst possible time.

The defense is not "read more carefully." It's holding the EVM's execution model
well enough to know *which questions to ask* — where does this variable live,
whose storage does this call touch, what is `msg.sender` inside this frame — and
then pinning the answers with `vm.load`/`vm.store` tests the agent can't fake.

## Exercises

See [exercises.md](exercises.md). Short version:

1. **Predict the layout** of `StorageLayout.sol` on paper, then run
   `forge test --match-path test/ch02/StorageLayout.t.sol` and reconcile.
2. **Explain the takeover** in `ProxyCollision.t.sol` — which slot, which write,
   why the attacker didn't need admin — then run the exploit and confirm.
3. **Verify the fix**: `forge test --profile solutions --match-path solutions/ch02`.

Next: [Chapter 3 — Think in Invariants](../03-think-in-invariants/README.md).
