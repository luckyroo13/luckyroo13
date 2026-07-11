# Smart Contracts for the Agentic Era

*A tutorial about the parts you can't delegate.*

An AI agent can now write a Solidity contract faster than you can type the import
statements. It knows the syntax, the ERC standards, the OpenZeppelin APIs, and a
thousand gas tricks better than most humans ever will. So the interesting
question is no longer "how do I write this contract?" — the agent will write it.
The question is:

> **When the agent hands you a contract that holds real money, what do you need
> to understand to know whether to sign the deploy transaction?**

That is the entire subject of this tutorial. It deliberately does **not** teach
Solidity syntax, "what is a blockchain," or how to set up your editor. Agents
have made that content cheap. Instead it teaches the six things that stay
expensive — the concepts where being wrong costs money, and where you cannot
verify the answer just by reading plausible-looking code.

This is written for someone who already writes basic Solidity and can run
Foundry. If that's you, skip the parts you know and go straight to the exercises.

---

## The thesis: agents raise the floor, they don't remove it

There is a comforting story that says "AI writes the code now, so developers move
up to architecture." That's half right. The half it gets wrong is that it treats
understanding the machine as a lower-level skill you get to drop. In smart
contracts, the opposite is true. The reason is **irreversibility plus
adversariality**:

- A deployed contract is immutable and public. There is no hotfix, no rollback,
  no "we'll patch it Monday." A mainnet bug is a press release.
- Every contract sits in a permanently hostile environment. The moment value
  flows through it, thousands of adversaries — many of them also using
  agents — probe it for the one path you didn't consider.

An agent optimizes for *plausible*. Adversaries attack the *actual*. The gap
between those two is exactly where money is lost, and closing that gap is the
human's job. The agent can write ten variants of a vault in a minute; only you
can decide which invariant must never break and whether the code actually holds
it.

## The Delegation Line

The organizing idea of this tutorial is a single rubric. For any piece of work,
place it on two axes:

```
                   cost of being wrong
                    LOW            HIGH
                +-------------+-------------+
   EASY to      |  DELEGATE   |   DELEGATE  |
   verify       |  freely     |  + verify   |
                +-------------+-------------+
   HARD to      |  DELEGATE   |    OWN IT    |
   verify       |  + spot-    |  yourself    |
                |  check      |             |
                +-------------+-------------+
```

- **Easy to verify, low cost** — boilerplate, getters, event definitions, a
  standard ERC-20. Let the agent write it, glance at it, move on.
- **Easy to verify, high cost** — arithmetic you can pin down with a test, an
  access-control table you can enumerate. Delegate the writing, but write the
  verification yourself and make it pass.
- **Hard to verify, low cost** — a helper script, a formatting choice. Delegate;
  a bug here is cheap.
- **Hard to verify, high cost** — the reentrancy surface, the economic incentive
  design, the storage layout of an upgradeable contract, the decision to make
  something immutable. **This quadrant is the tutorial.** You cannot outsource
  understanding it, because you cannot tell whether the agent got it right just
  by looking.

The skill of the agentic era is putting each task in the right quadrant — and
having the depth to actually own the bottom-right one. Every chapter below is a
region of that bottom-right quadrant.

## Chapters

| # | Chapter | The non-delegable skill |
|---|---------|-------------------------|
| 1 | [The Delegation Line](chapters/01-the-delegation-line/README.md) | Deciding what to delegate vs. own |
| 2 | [The EVM Is Your Mental Model](chapters/02-the-evm-is-your-mental-model/README.md) | Predicting execution context & storage |
| 3 | [Think in Invariants](chapters/03-think-in-invariants/README.md) | Specifying correctness the agent must meet |
| 4 | [Adversarial Review](chapters/04-adversarial-review/README.md) | Reviewing agent output like an attacker |
| 5 | [Economics and Gas](chapters/05-economics-and-gas/README.md) | Judging incentives, not micro-optimizing |
| 6 | [Deployment Is Forever](chapters/06-deployment-is-forever/README.md) | Owning the irreversible act |
| 7 | [The Agentic Workflow](chapters/07-the-agentic-workflow/README.md) | Putting it together (capstone) |

## How to use this repo

Each chapter has a `README.md` (the concept and *why an agent can't own it for
you*) and, from Chapter 2 on, an `exercises.md`. The exercises are backed by real
Foundry code:

```
src/chNN/         exercise contracts — some intentionally buggy, to be audited
test/chNN/        the harness: tests that encode what "solved" means
solutions/chNN/   corrected contracts + a SOLUTION.md walkthrough
```

The default `forge test` run is **green on a fresh clone** — the shipped tests
demonstrate the concepts (an exploit test *passes* by successfully exploiting a
planted bug, proving the bug is real). Your job in each exercise is described in
`exercises.md`; you check your work against the harness and compare with
`solutions/`.

### Running the code

This repo vendors a **minimal** forge-std in `lib/forge-std` so it is
self-contained. With [Foundry](https://book.getfoundry.sh/) installed:

```bash
cd agentic-solidity
forge build                      # compile everything
forge test                       # run the exercise harnesses (green baseline)
forge test --profile solutions   # run the solution suite (proves solutions correct)
forge test --match-path test/ch04 -vvv   # focus one chapter
```

For the full upstream library (all cheatcodes, StdStorage, richer fuzzing),
replace the vendored copy: `rm -rf lib/forge-std && forge install foundry-rs/forge-std`.
No tutorial code changes are needed — the remapping is the same.

> **A note on this being an agentic tutorial:** you are encouraged to solve the
> exercises *with* an agent. That's the point. The skill being trained is not
> "write the fix by hand" — it's "direct the agent, then verify it's right." Use
> the agent freely; just make sure that when you finish, you can explain why the
> harness passes.

---

## License

MIT. Use it, fork it, teach from it.
