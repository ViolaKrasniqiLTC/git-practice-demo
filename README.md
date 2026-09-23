# Git Practice Demo

A tiny React app for practicing **cherry-picking**, **rebasing**, and **stacked pull requests**.

## Quick start

```bash
npm install
npm run dev
```

Open http://localhost:5173.

## Start here

Read [GUIDE.md](./GUIDE.md). It walks through every exercise step by step, plus a tour of the GitHub features you will use along the way.

## Branch map

| Branch | Purpose |
| --- | --- |
| `feature/dark-mode` | Theme scaffolding plus a small header fix you will cherry-pick |
| `feature/footer` | An old branch you will rebase onto `main` (has a conflict on purpose) |
| `stack/1-badge` | Stacked PR 1 (bottom of the stack) |
| `stack/2-card` | Stacked PR 2, depends on PR 1 |
| `stack/3-profile-card` | Stacked PR 3, depends on PR 2 |
| `release/1.0` | Backport target for cherry-picked fixes |

Rebuild all of them at any time with:

```bash
./scripts/setup-branches.sh
```
