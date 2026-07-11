# Vendored forge-std (minimal subset)

This directory contains a **small, hand-vendored subset** of
[foundry-rs/forge-std](https://github.com/foundry-rs/forge-std) so the tutorial
compiles and runs without a network fetch, and so the repo is self-contained for
readers reviewing it on GitHub.

It provides just enough of `Test`, `Vm`, `console`, and `StdInvariant` to run the
exercises. Every symbol here mirrors upstream forge-std (same names, same
cheatcode selectors), so switching to the real library requires **no code
changes** in the tutorial.

## Using real Foundry

If you have Foundry installed and want the complete library (all assertions,
`StdCheats`, `StdStorage`, fuzz/invariant tooling), delete this folder and run:

```bash
forge install foundry-rs/forge-std
```

The `remappings.txt` at the project root (`forge-std/=lib/forge-std/src/`) works
with either version.
