import Button from './Button.jsx'

export default function Header() {
  return (
    <header className="header">
      <h1 className="header__logo">Git Practice Demo</h1>
      <nav className="header__nav">
        <a href="#exercises">Exercises</a>
        <a href="#about">About</a>
        <Button variant="secondary">Sign in</Button>
      </nav>
    </header>
  )
}
