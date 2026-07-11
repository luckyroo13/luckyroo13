# Chapter 2 — Exercises

## Exercise 2A — Predict the storage layout

Open `src/ch02/StorageLayout.sol`. **Before running anything**, fill in this table
from the compiler's layout rules (declaration order, packing, new-slot-on-
overflow, mapping placeholders):

| Variable | Type | Slot | Byte offset |
|----------|--------|------|-------------|
| `a` | uint128 | ? | ? |
| `b` | uint64 | ? | ? |
| `c` | uint64 | ? | ? |
| `owner` | address | ? | ? |
| `paused` | bool | ? | ? |
| `big` | uint256 | ? | ? |
| `balances` | mapping | ? | — |
| `balances[k]` | — | `keccak256(abi.encode(k, ?))` | ? |
| `x` | uint128 | ? | ? |
| `y` | uint128 | ? | ? |

Now check yourself:

```bash
forge test --match-path test/ch02/StorageLayout.t.sol -vv
```

The test reads each slot with `vm.load` and asserts the true layout. If any cell
in your table disagreed with a passing assertion, that's the gap to close —
figure out *which rule* you misapplied. (With real Foundry you can also run
`forge inspect StorageLayout storage-layout` for the canonical answer.)

**Stretch:** add a `bool` between `owner` and `paused`. Does `big` move? Does
`x`/`y` packing change? Predict, then re-run.

<details>
<summary>Answer key (open only after you've filled the table)</summary>

- `a` slot 0, offset 0 (bytes 0–15)
- `b` slot 0, offset 16 (bytes 16–23)
- `c` slot 0, offset 24 (bytes 24–31) — slot 0 is now exactly full
- `owner` slot 1, offset 0 (bytes 0–19)
- `paused` slot 1, offset 20 (byte 20)
- `big` slot 2 — a full uint256 can't fit slot 1's remaining 11 bytes, so it
  takes a fresh slot
- `balances` reserves slot 3 as a placeholder (nothing is stored there directly)
- `balances[k]` lives at `keccak256(abi.encode(k, uint256(3)))`
- `x` slot 4, offset 0; `y` slot 4, offset 16
</details>

## Exercise 2B — Diagnose the proxy takeover

Read `src/ch02/NaiveProxy.sol` and `test/ch02/ProxyCollision.t.sol`. Answer, in
your own words, before running:

1. When the attacker calls `initialize(hijackTarget)` on the proxy address, whose
   **code** runs and whose **storage** does it write?
2. Which slot does `owner = _owner` write to, and what does the proxy keep in that
   same slot?
3. Why didn't the attacker need to be the admin? Which access-control check would
   you *expect* to stop this, and why is it absent?

Run the exploit and confirm your reasoning:

```bash
forge test --match-path test/ch02/ProxyCollision.t.sol -vvv
```

The test passing means the attack *worked* — the proxy's implementation pointer
was overwritten by a non-admin.

## Exercise 2C — Prove the fix

```bash
forge test --profile solutions --match-path solutions/ch02 -vv
```

Then explain: the fix (`solutions/ch02/EIP1967Proxy.sol`) changes only the
*proxy's* storage discipline, not the logic contract. Why is that sufficient?
What property of the EIP-1967 slots guarantees no future logic contract will
collide, no matter how many variables it declares?

**Do it with an agent:** ask your agent to "make NaiveProxy upgrade-safe." Does it
reach for EIP-1967? Does it try (incorrectly) to reorder the logic contract's
variables instead? Grade its answer against `solutions/ch02` — this is the
Chapter 1 loop in miniature.
