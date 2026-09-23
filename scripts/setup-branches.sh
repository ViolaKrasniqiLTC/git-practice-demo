#!/usr/bin/env bash
#
# Recreates the exercise branches used by GUIDE.md.
# Usage: ./scripts/setup-branches.sh   (safe to re-run; `main` is never touched)
#
# Deletes and recreates:
#   feature/dark-mode, feature/footer, release/1.0,
#   stack/1-badge, stack/2-card, stack/3-profile-card

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

if [[ -n "$(git status --porcelain)" ]]; then
  echo "error: working tree is dirty. Commit or stash your changes first." >&2
  exit 1
fi

git switch main

find_commit() {
  local message="$1" sha
  sha="$(git log --format=%H -1 --fixed-strings --grep="$message" main)"
  if [[ -z "$sha" ]]; then
    echo "error: no commit matching '$message' found on main." >&2
    echo "If you rewrote main's history, restore it first (see GUIDE.md > Reset)." >&2
    exit 1
  fi
  printf '%s' "$sha"
}

HEADER_COMMIT="$(find_commit 'feat: add Header component')"
COUNTER_COMMIT="$(find_commit 'feat: add Counter component')"

BRANCHES=(
  feature/dark-mode
  feature/footer
  release/1.0
  stack/1-badge
  stack/2-card
  stack/3-profile-card
)
for branch in "${BRANCHES[@]}"; do
  git branch -D "$branch" >/dev/null 2>&1 || true
done

echo "Recreating exercise branches..."

# ------------------------------------------------------------ feature/dark-mode
git switch -c feature/dark-mode main

cat > src/ThemeContext.jsx <<'EOF'
import { createContext, useContext, useState } from 'react'

const ThemeContext = createContext({ theme: 'light', toggleTheme: () => {} })

export function ThemeProvider({ children }) {
  const [theme, setTheme] = useState('light')
  const toggleTheme = () => setTheme((current) => (current === 'light' ? 'dark' : 'light'))

  return (
    <ThemeContext.Provider value={{ theme, toggleTheme }}>
      {children}
    </ThemeContext.Provider>
  )
}

export function useTheme() {
  return useContext(ThemeContext)
}
EOF
git add src/ThemeContext.jsx
git commit -q -m "feat: add ThemeContext with light/dark state"

perl -pi -e 's/^(  text-decoration: none;)$/$1\n\n\@media (max-width: 480px) {\n  .header__logo {\n    font-size: 1.05rem;\n    white-space: nowrap;\n  }\n\n  .header__nav a {\n    margin-left: 0.5rem;\n  }\n}/' src/index.css
git add src/index.css
git commit -q -m "fix: shrink header logo on small screens"

cat >> src/index.css <<'EOF'

/* WIP: not ready to merge */
.theme-toggle {
  padding: 0.25rem 0.75rem;
  border: 1px solid #cbd2d9;
  border-radius: 999px;
  background: transparent;
  cursor: pointer;
}
EOF
git add src/index.css
git commit -q -m "wip: theme toggle styles"

# ---------------------------------------------------------------- feature/footer
git switch -c feature/footer "$HEADER_COMMIT"

cat > src/components/Footer.jsx <<'EOF'
export default function Footer() {
  return (
    <footer className="footer">
      <p>Built for practicing Git and GitHub workflows.</p>
    </footer>
  )
}
EOF
git add src/components/Footer.jsx
git commit -q -m "feat: add Footer component"

cat > src/App.jsx <<'EOF'
import Header from './components/Header.jsx'
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
        <Footer />
      </main>
    </div>
  )
}
EOF
git add src/App.jsx
git commit -q -m "feat: render Footer in App"

# ------------------------------------------------------------------- release/1.0
git switch -c release/1.0 "$COUNTER_COMMIT"

perl -pi -e 's/"version": "0.1.0"/"version": "1.0.0"/' package.json
cat > CHANGELOG.md <<'EOF'
# Changelog

## 1.0.0

- Initial release: header, counter, and the practice guide.
EOF
git add package.json CHANGELOG.md
git commit -q -m "chore(release): v1.0.0"

# ------------------------------------------------------------------ stack/1-badge
git switch -c stack/1-badge main

cat > src/components/Badge.jsx <<'EOF'
import './Badge.css'

export default function Badge({ children, tone = 'neutral' }) {
  return <span className={`badge badge--${tone}`}>{children}</span>
}
EOF
cat > src/components/Badge.css <<'EOF'
.badge {
  display: inline-block;
  padding: 0.15rem 0.5rem;
  border-radius: 999px;
  font-size: 0.75rem;
  font-weight: 600;
}

.badge--neutral {
  background: #e4e7eb;
  color: #3e4c59;
}

.badge--info {
  background: #dbeafe;
  color: #1d4ed8;
}
EOF
git add src/components/Badge.jsx src/components/Badge.css
git commit -q -m "feat(ui): add Badge component"

# ------------------------------------------------------------------- stack/2-card
git switch -c stack/2-card

cat > src/components/Card.jsx <<'EOF'
import Badge from './Badge.jsx'
import './Card.css'

export default function Card({ title, tag, children }) {
  return (
    <article className="ui-card">
      <header className="ui-card__header">
        <h3 className="ui-card__title">{title}</h3>
        {tag && <Badge tone="info">{tag}</Badge>}
      </header>
      <div className="ui-card__body">{children}</div>
    </article>
  )
}
EOF
cat > src/components/Card.css <<'EOF'
.ui-card {
  border: 1px solid #e4e7eb;
  border-radius: 8px;
  background: #ffffff;
  overflow: hidden;
}

.ui-card__header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 0.75rem;
  padding: 1rem 1.25rem;
  border-bottom: 1px solid #e4e7eb;
}

.ui-card__title {
  margin: 0;
  font-size: 1rem;
}

.ui-card__body {
  padding: 1.25rem;
}
EOF
git add src/components/Card.jsx src/components/Card.css
git commit -q -m "feat(ui): add Card component (uses Badge)"

# ----------------------------------------------------------- stack/3-profile-card
git switch -c stack/3-profile-card

cat > src/components/ProfileCard.jsx <<'EOF'
import Card from './Card.jsx'
import './ProfileCard.css'

export default function ProfileCard({ name, role, avatar }) {
  return (
    <Card title={name} tag={role}>
      <div className="profile-card">
        <img className="profile-card__avatar" src={avatar} alt={name} />
        <p className="profile-card__meta">Practicing stacked pull requests.</p>
      </div>
    </Card>
  )
}
EOF
cat > src/components/ProfileCard.css <<'EOF'
.profile-card {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.profile-card__avatar {
  width: 48px;
  height: 48px;
}

.profile-card__meta {
  margin: 0;
  color: #52606d;
}
EOF
git add src/components/ProfileCard.jsx src/components/ProfileCard.css
git commit -q -m "feat(ui): add ProfileCard built on Card"

cat > src/components/ProfileCard.css <<'EOF'
.profile-card {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.profile-card__avatar {
  width: 48px;
  height: 48px;
  border-radius: 50%;
}

.profile-card__meta {
  margin: 0;
  color: #52606d;
}
EOF
git add src/components/ProfileCard.css
git commit -q -m "fix(ui): make profile card avatar round"

# ------------------------------------------------------------------------- done
git switch main
echo
echo "Done. Exercise branches:"
git branch --list 'feature/*' 'stack/*' 'release/*'
