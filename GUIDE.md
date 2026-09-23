# Git & GitHub Practice Guide

A hands-on playground for **cherry-picking**, **rebasing**, and **stacked pull requests** — with a tour of the GitHub features you will use along the way.

Everything here is safe to break. There is a [reset script](#part-5--reset-start-over) at the end.

```
Part 1  Cherry-picking        → copy one commit to another branch, backport a hotfix
Part 2  Rebasing              → restack a stale branch, resolve conflicts, clean up commits
Part 3  Stacked PRs           → chain 3 dependent PRs, merge them one layer at a time
Part 4  GitHub feature tour   → issues, reviews, merge methods, branch protection, Actions, releases
Part 5  Reset / troubleshooting
```

---

## 0. Setup

```bash
cd ~/git-practice-demo
npm install        # already done once
npm run dev        # http://localhost:5173
```

Look at the history you will be working with:

```bash
git log --oneline --graph --all --decorate
```

You should see `main` plus 6 exercise branches. `main` has 6 commits and has moved on since most of the branches were created — that is deliberate, it is what makes the rebase exercises real.

### Put it on GitHub

You are already logged in with `gh`. Create the repo and push `main`:

```bash
gh repo create git-practice-demo --public --source=. --remote=origin --push
git branch -u origin/main main     # not needed if the line above set the upstream
```

> No `gh`? Create an empty repo on github.com, then:
> ```bash
> git remote add origin git@github.com:<your-username>/git-practice-demo.git
> git push -u origin main
> ```
>
> The guide assumes the remote is called `origin`.

---

## The branch map

| Branch | What it is for |
| --- | --- |
| `main` | Integration branch. Already has Header, Counter, Button, GUIDE, CI. |
| `feature/dark-mode` | 3 commits: theme scaffolding, a small CSS fix (**cherry-pick source**), and a WIP commit to clean up. |
| `feature/footer` | Branched from an old `main`, before Counter existed. Rebasing it will **conflict on purpose**. |
| `stack/1-badge` | Stacked PR 1 (bottom). |
| `stack/2-card` | Stacked PR 2. Its `Card` imports `Badge`, so it genuinely depends on PR 1. |
| `stack/3-profile-card` | Stacked PR 3. Built on `Card`, so it depends on PR 2. Two commits, one is a fixup. |
| `release/1.0` | A release branch at v1.0.0. Backport target for cherry-picks. |

Run `./scripts/setup-branches.sh` any time to delete and recreate all six exercise branches (it never touches `main`).

---

## Part 1 — Cherry-picking

**What it is:** take one commit from anywhere and copy it onto your current branch as a brand-new commit (new SHA). The original stays where it was.

**Use it for:** hotfixes that must land on several branches, backporting to a release branch, or stealing one good commit out of a messy branch you don't want to merge.

### Exercise 1.1 — File an issue, cherry-pick the fix, merge the PR

The story: on small screens the header logo overflows. The fix already exists on `feature/dark-mode`, but that branch is not ready to merge. You need the fix on `main` now.

**1. File an issue first** (this is the GitHub feature part):

```bash
gh issue create \
  --title "Header logo overflows on small screens" \
  --body "Below ~480px the logo pushes the nav links off screen. A fix exists on feature/dark-mode." \
  --label bug
```

Note the issue number (`#1` if this is a fresh repo).

**2. Create a hotfix branch from `main` and find the commit to copy:**

```bash
git switch main
git switch -c hotfix/mobile-header
git log --oneline feature/dark-mode
```

You will see (top to bottom):

```
xxxxxxx wip: theme toggle styles
xxxxxxx fix: shrink header logo on small screens   ← this one
xxxxxxx feat: add ThemeContext with light/dark state
```

**3. Cherry-pick it.** Use the SHA from the line above, or `feature/dark-mode~1` (one commit before that branch's tip):

```bash
git cherry-pick <sha-of-the-fix>
# or: git cherry-pick feature/dark-mode~1
```

You should see:

```
[hotfix/mobile-header xxxxxxx] fix: shrink header logo on small screens
 Date: ...
 1 file changed, 11 insertions(+)
```

Check it:

```bash
git log --oneline -3        # your branch: the fix is on top of main
git show --stat HEAD        # 1 file changed, src/index.css
npm run dev                 # shrink the browser window below 480px: logo gets smaller
```

**4. Push and open the PR:**

```bash
git push -u origin hotfix/mobile-header
gh pr create \
  --base main \
  --title "fix: shrink header logo on small screens" \
  --body "Cherry-picked from feature/dark-mode. Closes #1"
```

**GitHub features to notice:**
- The PR template (`.github/PULL_REQUEST_TEMPLATE.md`) pre-fills the description box if you use the web UI.
- `Closes #1` links the PR to the issue — it closes automatically when the PR merges.
- The **CI** workflow runs automatically (Actions tab → the check appears in the PR's merge box).

**5. Merge it.** On the PR page: **Squash and merge** → **Delete branch**. Or:

```bash
gh pr merge --squash --delete-branch
```

Then sync your local `main`:

```bash
git switch main
git pull origin main
git log --oneline -3        # the fix is now part of main
```

> Why squash? The PR had one commit anyway, but squashing is the common default. You will see in Part 3 how squash merges change SHAs — and why stacked PRs need rebasing because of it.

### Exercise 1.2 — Backport to the release branch

`release/1.0` shipped without the fix. Backport it.

**Push the release branch first:**

```bash
git push -u origin release/1.0
```

**Option A — GitHub's cherry-pick button (web UI):**
1. Open the **merged** PR from Exercise 1.1 on GitHub.
2. Click the **Cherry-pick** dropdown at the bottom of the PR and choose base branch `release/1.0`.
3. GitHub creates a new branch + PR against `release/1.0`. Merge it.

**Option B — CLI (what the button does under the hood):**

```bash
git switch -c backport/mobile-header release/1.0
git cherry-pick -x <sha-of-the-fix>
git push -u origin backport/mobile-header
gh pr create --base release/1.0 \
  --title "fix: shrink header logo on small screens (backport)" \
  --body "Backport of #<the hotfix PR number>"
```

The `-x` flag appends `(cherry picked from commit ...)` to the commit message — good practice for backports so people can trace the original.

Merge that PR too, then:

```bash
git switch release/1.0
git pull origin release/1.0
```

**Key insight:** `main` and `release/1.0` now contain the *same change* as two *different commits* with different SHAs. That is normal for cherry-picks.

### Exercise 1.3 — What a cherry-pick conflict looks like

Conflicts work exactly like rebase conflicts (Part 2.1 has a full walkthrough). If a cherry-pick conflicts:

```bash
git status                 # shows "UU <file>"
# edit the file, remove <<<<<<< ======= >>>>>>> markers
git add <file>
git cherry-pick --continue
# or give up:
git cherry-pick --abort
```

### Cherry-pick cheat sheet

| Command | Meaning |
| --- | --- |
| `git cherry-pick <sha>` | Copy that commit onto the current branch |
| `git cherry-pick -x <sha>` | Same, but record the source SHA in the message |
| `git cherry-pick <a> <b> <c>` | Copy several commits |
| `git cherry-pick -n <sha>` | Apply the changes but don't commit yet |
| `git cherry-pick --continue` / `--abort` | Finish / cancel after a conflict |

---

## Part 2 — Rebasing

**What it is:** move your commits so they start from a newer base, replaying them one by one. Unlike a merge, it produces a linear history with no merge commits — but it **rewrites SHAs**.

**Golden rule:** never rebase a branch that other people are building on, unless you have agreed on it. Rewritten history must be force-pushed, and force-pushes break other clones. Your feature branches are yours; `main` is shared.

### Exercise 2.1 — Rebase a stale branch (with a conflict)

`feature/footer` was started before Counter existed. Bring it up to date.

```bash
git switch feature/footer
git log --oneline main..feature/footer      # your 2 commits that aren't on main yet
git rebase main
```

It will stop with a conflict **on purpose**:

```
CONFLICT (content): Merge conflict in src/App.jsx
error: could not apply ... feat: render Footer in App
hint: Resolve all conflicts manually, mark them as resolved with
hint: "git add/rm <conflicted_files>", then run "git rebase --continue".
```

Open `src/App.jsx`. You will see two conflicts:

```jsx
import Header from './components/Header.jsx'
<<<<<<< HEAD
import Counter from './components/Counter.jsx'
=======
import Footer from './components/Footer.jsx'
>>>>>>> 1f4bd26 (feat: render Footer in App)
...
<<<<<<< HEAD
        <Counter />
=======
        <Footer />
>>>>>>> 1f4bd26 (feat: render Footer in App)
```

**How to read this:** during a rebase, `HEAD` is the branch you are rebasing **onto** (`main`), and the other side is **your commit** being replayed. This is the opposite of a merge — don't let it confuse you.

You want **both**, so resolve the file to:

```jsx
import Header from './components/Header.jsx'
import Counter from './components/Counter.jsx'
import Footer from './components/Footer.jsx'

export default function App() {
  return (
    <div className="app">
      <Header />
      <main className="main">
        <section className="panel">
          <h2>Practice repo</h2>
          <p>
            A tiny React app for practicing cherry-picking, rebasing, and
            stacked pull requests. Open GUIDE.md and follow the exercises.
          </p>
        </section>
        <Counter />
        <Footer />
      </main>
    </div>
  )
}
```

Then:

```bash
git add src/App.jsx
git rebase --continue
git log --oneline --graph -6      # linear: your 2 commits now sit on top of main
npm run dev                       # header, counter AND footer all render
```

If it goes wrong: `git rebase --abort` puts everything back exactly as it was.

> Tip: `git config --global rerere.enabled true` makes git remember conflict resolutions and apply them automatically next time.

### Exercise 2.2 — Interactive rebase: clean up your branch

`feature/dark-mode` has a WIP commit that must not be merged. Rewrite the branch's own history:

```bash
git switch feature/dark-mode
git log --oneline -3        # ThemeContext, fix, wip
git rebase -i HEAD~3
```

Your editor opens (vim by default) with:

```
pick xxxxxxx feat: add ThemeContext with light/dark state
pick xxxxxxx fix: shrink header logo on small screens
pick xxxxxxx wip: theme toggle styles
```

Change it to:

```
pick xxxxxxx feat: add ThemeContext with light/dark state
reword xxxxxxx fix: shrink header logo on small screens
drop xxxxxxx wip: theme toggle styles
```

- `pick` = keep
- `reword` = keep the change, edit the message
- `drop` = throw the commit away (you can also just delete the line)

Save and close (`:wq` in vim, or `dd` to delete a line first). Reword opens a second editor for the message. Result:

```bash
git log --oneline -2
```

Two clean commits. Now restack onto `main` (no conflict this time — the WIP CSS is gone):

```bash
git rebase main
```

**Other useful actions:** `squash` (combine with the previous commit and merge the messages), `fixup` (combine and throw the message away), reorder lines to reorder commits, `edit` to stop and amend.

### Exercise 2.3 — Squash a fix with `fixup`

`stack/3-profile-card` has two commits: the feature and a follow-up "make avatar round" fix. Fold the fix into the feature:

```bash
git switch stack/3-profile-card
git log --oneline -3
git rebase -i HEAD~2
```

Change the second line from `pick` to `fixup`:

```
pick xxxxxxx feat(ui): add ProfileCard built on Card
fixup xxxxxxx fix(ui): make profile card avatar round
```

Save. Result: one commit, one clean story for the reviewer.

### Exercise 2.4 — Force-push safely

Rebasing rewrote the commits, so a normal push is rejected. Push with a lease:

```bash
git push --force-with-lease origin stack/3-profile-card
```

- `--force` overwrites the remote branch no matter what. **Avoid it.**
- `--force-with-lease` only overwrites if the remote is still where you last saw it — it fails instead of destroying a teammate's work.

If you already have an open PR for the branch, it updates automatically; the PR shows "force-pushed" in its timeline.

### Exercise 2.5 — Pulling with rebase

Keep a feature branch up to date without a merge commit:

```bash
git switch hotfix/mobile-header        # or any feature branch
git fetch origin
git rebase origin/main
# or in one step:
git pull --rebase origin main
```

### Undo a rebase

| Situation | Command |
| --- | --- |
| Conflict, want out | `git rebase --abort` |
| Finished but it went wrong | `git reset --hard ORIG_HEAD` |
| No idea what happened | `git reflog` → find the SHA before the rebase → `git reset --hard <sha>` |

`reflog` is your safety net: git keeps every previous position of `HEAD` for ~90 days.

---

## Part 3 — Stacked PRs

**What it is:** a chain of PRs where each one targets the branch below it instead of `main`. Reviewers see only that layer's diff, and you can keep working on the next layer while the bottom one is in review.

```
stack/3-profile-card → PR #3 (base: stack/2-card)      ← top
stack/2-card         → PR #2 (base: stack/1-badge)
stack/1-badge        → PR #1 (base: main)              ← bottom
main
```

This repo's stack is real: `Card` imports `Badge`, and `ProfileCard` imports `Card`. The layers genuinely depend on each other.

### Exercise 3.1 — Push the stack and open the chain

```bash
git push -u origin stack/1-badge stack/2-card stack/3-profile-card
```

Create the PRs with the right bases (this is the whole trick):

```bash
gh pr create --base main --head stack/1-badge \
  --title "feat(ui): add Badge component" \
  --body "Bottom of the design-system stack."

gh pr create --base stack/1-badge --head stack/2-card \
  --title "feat(ui): add Card component" \
  --body "Stacked on #<PR1 number>. Depends on the Badge component."

gh pr create --base stack/2-card --head stack/3-profile-card \
  --title "feat(ui): add ProfileCard" \
  --body "Stacked on #<PR2 number>. Depends on Card."
```

Open PR #2 and #3 in the web UI and notice: **each diff shows only its own layer.** PR #2 shows the Card files, not the Badge files underneath. That is what makes stacked PRs reviewable.

> `gh pr create` without `--base` targets the default branch, so be explicit. In the web UI, use the base-branch dropdown next to the title when creating each PR.

### Exercise 3.2 — Review layer by layer

On PR #1:
- **Files changed** → hover a line → **+** to leave a line comment. Use the suggestion syntax:
  ````md
  ```suggestion
  padding: 0.2rem 0.6rem;
  ```
  ````
- **Start a review** (top right) → comment / approve / **request changes**. You cannot approve your own PR, so comment instead.
- Try a **draft PR**: `gh pr create --draft ...` or "Convert to draft" on the PR page. Drafts don't request reviews yet.

Meanwhile, `main` has moved on (you merged the hotfix earlier), so PR #1's branch is behind. Rebase it and force-push:

```bash
git switch stack/1-badge
git rebase main
git push --force-with-lease origin stack/1-badge
```

CI runs again; the PR's diff is unchanged.

**Merge PR #1** with **Squash and merge**, and delete the branch.

### Exercise 3.3 — Restack layer 2 after the squash merge

Here is the moment everyone needs a guide for: PR #1 is merged, but your local `stack/2-card` still sits on the *old* commit that was just squashed into `main`. Its base no longer exists as it was.

Replay the Card commit onto `main`:

```bash
git switch stack/2-card
git rebase --onto main stack/1-badge stack/2-card
git push --force-with-lease origin stack/2-card
```

Read `--onto` as: *"take the commits in `stack/1-badge..stack/2-card` and replay them onto `main`."* Since `stack/1-badge` still points at the old pre-squash commit, this selects only the Card commit.

On GitHub:
- If you deleted the `stack/1-badge` branch when merging, PR #2's base is **automatically retargeted to `main`**. Otherwise, edit the PR's base manually (the "base:" dropdown next to the title).
- PR #2's diff still shows only Card. Merge it (squash), delete the branch.

### Exercise 3.4 — Restack layer 3

Same move, one layer up:

```bash
git switch stack/3-profile-card
git rebase --onto main stack/2-card stack/3-profile-card
git push --force-with-lease origin stack/3-profile-card
```

You will see:

```
warning: skipped previously applied commit xxxxxxx
hint: use --reapply-cherry-picks to include skipped commits
```

That warning is **expected and good**: it means git noticed the Card commit is already in `main` (squash-merge rewrote its SHA, but the patch matches) and skipped it. The ProfileCard commit is replayed on top. Verify:

```bash
git log --oneline -3
npm run build
```

Retarget PR #3 to `main` if needed, then merge it. The whole stack is in.

### Exercise 3.5 — Native stacked PRs (`gh stack`)

GitHub now has first-class stacked PRs (public preview, July 2026). The official CLI extension can adopt exactly the branches you just used:

```bash
gh extension install github/gh-stack

# Adopt the existing branches as a stack (bottom → top order)
gh stack init stack/1-badge stack/2-card stack/3-profile-card

# See the stack and its PR state
gh stack view

# Create/update PRs and link them as a Stack on GitHub in one command
gh stack submit

# After a reviewer asks for a change on the bottom layer:
gh stack bottom            # jump to stack/1-badge
# ...edit, commit...
gh stack rebase            # cascading rebase of every layer above
gh stack push

# After PR #1 merges, bring the rest up to date and clean up
gh stack sync --prune
```

On github.com, a stack shows a **stack map** at the top of every PR, a **Rebase stack** button in the merge box, and **one-click merge** of the whole stack. Branch protection and CI are evaluated against `main` for every layer.

> Reset tip: `./scripts/setup-branches.sh` recreates the three `stack/*` branches if you want to replay this part.

### Why teams stack (and the pitfalls)

- Small PRs get reviewed faster; layer N+1 is not blocked by layer N's review.
- The bottom layer can merge while you keep working up the stack.
- **Pitfall:** squash/rebase merges rewrite SHAs, so children always need `rebase --onto` afterwards. `gh stack` exists precisely to automate that.
- **Pitfall:** branch protection with "Require branches to be up to date before merging" fights with stacked PRs — every merge invalidates the layers above. Native stacks handle this; manual stacking is smoother without that setting.
- **Pitfall:** never force-push a stack branch someone else has checked out without telling them.

---

## Part 4 — GitHub feature tour

A checklist of the features worth knowing, where they are in this repo, and how to try each one.

### Issues
- [ ] Create one: `gh issue create --title "..." --body "..."` (done in 1.1).
- [ ] Labels: `gh issue edit <n> --add-label enhancement`. Default labels (`bug`, `enhancement`, `documentation`...) exist in every new repo.
- [ ] Templates: add files under `.github/ISSUE_TEMPLATE/` — this repo already has `bug_report.md`.
- [ ] Milestones, assignees, and Projects (the kanban board in the Projects tab) for planning.
- [ ] Close an issue from a PR with `Closes #<n>` in the PR body (done in 1.1).

### Pull requests
- [ ] Templates: `.github/PULL_REQUEST_TEMPLATE.md` pre-fills new PRs created in the web UI.
- [ ] Draft PRs: `gh pr create --draft`, or "Convert to draft".
- [ ] Review workflow: line comments, `suggestion` blocks, approve / request changes, re-request review.
- [ ] Stacked PRs: bases chain onto each other (Part 3), or use `gh stack` / the native stack UI.
- [ ] Merge methods — try all three on throwaway PRs:
  - **Squash and merge** — one commit per PR (used throughout this guide).
  - **Merge commit** — preserves branch commits plus a merge commit.
  - **Rebase and merge** — replays commits, linear history, no merge commit.
- [ ] Auto-merge: enable "Allow auto-merge" in Settings → General → Pull Requests, then on a PR click **Enable auto-merge** so it lands as soon as CI passes.
- [ ] Delete branch on merge (checkbox in the merge box).

### Branch protection
- [ ] Settings → Branches → **Add branch ruleset** (or classic rule) for `main`:
  - Require a pull request before merging.
  - Require status checks to pass → select the `build` check from the CI workflow.
  - Try requiring "branches up to date" and then watch it block a stacked PR — a good lesson (see Part 3 pitfalls).

### Actions / CI
- [ ] This repo ships `.github/workflows/ci.yml`: on every PR it runs `npm ci` and `npm run build`.
- [ ] Watch a run: `gh run list`, `gh run watch`, or the Actions tab.
- [ ] Re-run a failed job from the UI; download logs from a run page.
- [ ] Explore next: matrices, caching (already used via `cache: npm`), secrets (`Settings → Secrets and variables → Actions`), scheduled workflows.

### Releases & tags
- [ ] Tag a release from the release branch:
  ```bash
  git switch release/1.0
  git pull origin release/1.0
  gh release create v1.0.0 --target release/1.0 \
    --title "v1.0.0" --notes "First release: header, counter, practice guide."
  ```
- [ ] Look at the Releases page: auto-generated notes, source tarballs, and the git tag (`git tag`, `git show v1.0.0`).

### Code owners (optional)
- [ ] Add `.github/CODEOWNERS`:
  ```
  * @<your-username>
  ```
  Push it on a branch and open a PR: GitHub automatically requests review from the owner. Combined with branch protection ("Require review from Code Owners"), it controls who can merge what.

### Repo settings worth a click
- [ ] **About**: description + topics (repo home page, gear icon).
- [ ] **Discussions**, **Wiki**, **Projects**: toggle them in Settings → Features.
- [ ] **Pages**: deploy a static site — this repo even has `npm run build` output that could be published from `dist/`.
- [ ] **Security**: Settings → Code security → enable Dependabot alerts/updates, secret scanning, CodeQL code scanning (public repos).

### `gh` CLI cheat sheet

| Command | What it does |
| --- | --- |
| `gh repo view --web` | Open the repo in your browser |
| `gh pr status` | Your open PRs and review requests |
| `gh pr list` / `gh pr view <n> --web` | List / open a PR |
| `gh pr checkout <n>` | Check out a PR locally (handy for reviewing) |
| `gh pr diff <n>` | Show a PR's diff in the terminal |
| `gh pr checks <n>` | CI status for a PR |
| `gh pr merge <n> --squash --delete-branch` | Merge from the CLI |
| `gh issue list --label bug` | Filter issues |
| `gh run list` / `gh run watch` | CI runs |
| `gh api repos/:owner/:repo` | Raw REST API access |

---

## Part 5 — Reset / start over

**Recreate the exercise branches** (deletes and rebuilds all `feature/*`, `stack/*`, `release/*` branches; `main` untouched):

```bash
./scripts/setup-branches.sh
```

**Reset `main` to its original state** (the repo is tagged `demo/baseline` at the starting point):

```bash
git switch main
git reset --hard demo/baseline
```

**Reset everything including GitHub** (rewrites the remote — fine for a practice repo you own):

```bash
git switch main
git reset --hard demo/baseline
./scripts/setup-branches.sh
git push --force-with-lease origin main
git push --force-with-lease origin feature/dark-mode feature/footer release/1.0 \
  stack/1-badge stack/2-card stack/3-profile-card
```

Then close/delete any leftover PRs on GitHub (`gh pr list`, `gh pr close <n>`).

---

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| `error: could not apply ...` | Conflict. `git status` → edit files → `git add` → `git rebase --continue` (or `--abort`). |
| Push rejected after rebase | `git push --force-with-lease origin <branch>` |
| `warning: skipped previously applied commit` | Expected when restacking after a squash merge. Not an error. |
| Rebase stopped with an empty commit | `git rebase --skip` |
| "detached HEAD" | You checked out a commit/SHA instead of a branch: `git switch main` |
| Which side is "ours" in a rebase conflict? | `--ours` = the branch you rebase **onto**; `--theirs` = **your** commit being replayed (inverted vs. merge). |
| Deleted a branch by accident | `git reflog` → find the SHA → `git switch -c <name> <sha>` |
| Want to see everything that happened | `git reflog`, `git log --oneline --graph --all --decorate` |

**Core commands, one table:**

| Goal | Command |
| --- | --- |
| Copy a commit | `git cherry-pick <sha>` |
| Restack on main | `git rebase main` |
| Replay a range onto a new base | `git rebase --onto <new-base> <old-base> <branch>` |
| Rewrite commits | `git rebase -i <base>` |
| Continue / abort | `git rebase --continue` / `git rebase --abort` |
| Undo a finished rebase | `git reset --hard ORIG_HEAD` |
| Push rewritten history safely | `git push --force-with-lease` |
| Move a PR's base | "Edit" next to the PR title on GitHub |
| Inspect CI | `gh pr checks` / `gh run watch` |

Now go break things — `./scripts/setup-branches.sh` and `git reset --hard demo/baseline` always bring you back.
