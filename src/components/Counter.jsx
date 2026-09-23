import { useState } from 'react'

export default function Counter() {
  const [count, setCount] = useState(0)

  return (
    <section className="counter">
      <h2>Counter</h2>
      <p>You clicked {count} times.</p>
      <div className="counter__actions">
        <button onClick={() => setCount((count) => count + 1)}>Increment</button>
        <button onClick={() => setCount(0)}>Reset</button>
      </div>
    </section>
  )
}
