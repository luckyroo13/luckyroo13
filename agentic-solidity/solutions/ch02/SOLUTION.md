# Chapter 2 — Solution notes

## 2A — Storage layout

The full slot/offset table is in `exercises.md`'s answer key, and every entry is
asserted in `test/ch02/StorageLayout.t.sol`. The three rules people miss:

- **Packing is greedy and low-order-first.** `a` (16 bytes) + `b` (8) + `c` (8) =
  32, so slot 0 is full and perfectly packed. Swap the order to `b, a, c` and you
  get the *same* packing; swap to `a, big, b` and `big` forces a new slot,
  wasting the rest of slot 0.
- **A value only shares a slot if it fully fits the remainder.** `big` (32 bytes)
  cannot fit slot 1's leftover 11 bytes, so it takes slot 2 whole — even though
  `paused` left 11 bytes unused.
- **Mappings/arrays reserve a slot but store elsewhere.** Slot 3 stays zero;
  `balances[k]` is at `keccak256(abi.encode(k, 3))`. This is why you can't
  "read a mapping" by dumping a slot, and why layout-preserving upgrades must keep
  the mapping's *slot index* stable even though the slot looks empty.

Why it matters for agents: an upgrade that reorders or inserts a variable shifts
every later slot. The compiler won't warn you; the old storage is silently
reinterpreted. Pinning the layout with `vm.load` (or `forge inspect ... storage-
layout` in CI) is how you make this class of bug loud.

## 2B / 2C — The proxy collision

**The mechanism.** `delegatecall` executes `LogicV1`'s code against the *proxy's*
storage. `LogicV1.initialize` runs `owner = _owner`, and `owner` is `LogicV1`'s
slot 0. But slot 0 in the storage being written is the *proxy's* slot 0, which the
proxy uses for `implementation`. So `initialize` overwrites the implementation
pointer. No admin check stands in the way because `initialize` is a *logic*
function — the proxy's `upgradeTo` guard never runs.

**Why the fix is only in the proxy.** EIP-1967 moves the proxy's `implementation`
and `admin` to slots derived from `keccak256(...) - 1`. Those slots are, for all
practical purposes, unreachable by sequential allocation: a logic contract would
have to declare ~2^255 variables to land on them. So the logic contract can use
slots 0, 1, 2, … freely and never touch proxy state. The logic contract is
unchanged because it was never wrong — the defect was the proxy squatting on
low slots that delegatecall shares.

**The `- 1` detail.** The slot is `keccak256("eip1967.proxy.implementation") - 1`
rather than the raw hash. The subtraction is deliberate: it makes the slot a value
for which no known preimage exists, so nobody can construct a mapping/array whose
hashed storage location equals it. It's belt-and-suspenders against a
*hash-directed* collision on top of the sequential one.

**The transferable lesson.** Both bugs — layout drift and proxy collision — are
invisible in any single file and invisible to "read it again." They're only
visible if you simulate the EVM's execution context: *whose storage, which slot,
whose msg.sender.* That mental model is the thing you own; the tests are how you
force the machine to confirm it.
