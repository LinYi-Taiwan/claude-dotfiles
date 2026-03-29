---
name: clean-ts
description: >
  Write and review maintainable, readable, type-safe TypeScript/JavaScript for frontend projects.
  Use this skill whenever the user is writing new TS/JS/TSX/JSX code, asking for a code review,
  refactoring messy or hard-to-read code, spotting unsafe patterns, or asking "is this code OK?".
  Also trigger when the user pastes code and asks why it's hard to test, maintain, or understand.
  Apply proactively when you notice anti-patterns like `any`, `@ts-ignore`, deeply nested logic,
  mutation of shared state, untestable side effects, or magic values — even if the user didn't ask.
---

# Clean TypeScript / Frontend JS

You are helping write or review frontend TypeScript/JavaScript code (React, Vue, or framework-agnostic).
The goal is code that:

- A teammate can read and understand without a walkthrough
- Can be tested without elaborate setup or mocking tricks
- Doesn't rely on hacks or workarounds that will bite someone later
- Uses TypeScript's type system to catch bugs at compile time, not runtime

---

## When writing new code

### Type safety first

Avoid escaping the type system. When you're tempted to write `as any` or `// @ts-ignore`, that's usually a signal the design needs rethinking — not that you need to silence the compiler.

```ts
// ❌ Hiding the problem
const value = (response as any).data.items[0]

// ✅ Model the shape explicitly
interface ApiResponse {
  data: { items: Item[] }
}
const value = (response as ApiResponse).data.items[0]
```

Prefer `unknown` over `any` for values whose shape is genuinely unknown — it forces you to narrow before use.

```ts
// ❌ Trusts everything, catches nothing
function parse(raw: any) { return raw.name }

// ✅ Forces explicit narrowing
function parse(raw: unknown): string {
  if (typeof raw === 'object' && raw !== null && 'name' in raw) {
    return String((raw as { name: unknown }).name)
  }
  throw new Error('Invalid shape')
}
```

### Keep functions small and pure

Pure functions (same input → same output, no side effects) are the easiest things to test and reason about. Aim for this default; introduce state/effects only when necessary.

```ts
// ❌ Mixed concerns: logic + side effect
function handleSubmit(form: FormData) {
  const name = form.get('name') as string
  if (!name) return
  localStorage.setItem('lastUser', name)  // side effect baked in
  fetch('/api/users', { method: 'POST', body: form })
}

// ✅ Logic separated from effects — each part is testable independently
function extractName(form: FormData): string | null {
  return (form.get('name') as string) || null
}

function handleSubmit(form: FormData) {
  const name = extractName(form)
  if (!name) return
  persistLastUser(name)       // named, swappable
  submitUserForm(form)        // named, swappable
}
```

### No magic values

Unnamed numbers and strings scattered through code become puzzles for the next reader (often yourself).

```ts
// ❌ What is 86400000?
if (Date.now() - lastSeen > 86400000) showBanner()

// ✅ Self-documenting
const ONE_DAY_MS = 24 * 60 * 60 * 1000
if (Date.now() - lastSeen > ONE_DAY_MS) showBanner()
```

### Avoid deep nesting

More than 2–3 levels of nesting is a maintainability warning. Use early returns, named helpers, or composition to flatten.

```ts
// ❌ Pyramid of doom
function process(user?: User) {
  if (user) {
    if (user.isActive) {
      if (user.profile) {
        return user.profile.displayName
      }
    }
  }
  return 'Anonymous'
}

// ✅ Flat with early returns
function process(user?: User): string {
  if (!user?.isActive) return 'Anonymous'
  return user.profile?.displayName ?? 'Anonymous'
}
```

### Avoid mutating shared state

Mutation is fine inside a function's own scope. Mutating something passed in from outside is a hidden side effect that causes bugs at a distance.

```ts
// ❌ Caller's array is silently changed
function addDefaults(items: Item[]) {
  items.push({ id: 'default', label: 'None' })
  return items
}

// ✅ Return a new array; caller controls their own data
function addDefaults(items: Item[]): Item[] {
  return [...items, { id: 'default', label: 'None' }]
}
```

### Design for testability

If a function is hard to test, it's usually hard to reason about too. Common causes and fixes:

| Hard to test because... | Fix |
|---|---|
| Calls `fetch` directly | Accept a `fetcher` param or inject via context |
| Reads `Date.now()` / `Math.random()` | Accept a `clock` / `rng` param |
| Reads `localStorage` directly | Accept a `storage` param (or mock interface) |
| Depends on global variable | Pass as argument |

```ts
// ❌ Untestable without real network
async function loadUser(id: string) {
  const res = await fetch(`/api/users/${id}`)
  return res.json()
}

// ✅ Easily testable: pass in a stub
async function loadUser(id: string, fetcher = fetch) {
  const res = await fetcher(`/api/users/${id}`)
  return res.json()
}
```

### Name things honestly

Names should describe what something *is* or *does*, not how it's implemented or where it lives.

```ts
// ❌ Tells you nothing
const d = new Date()
const arr2 = arr.filter(Boolean)
const flag = true

// ✅ Self-documenting
const createdAt = new Date()
const validItems = items.filter(Boolean)
const isEmailVerified = true
```

Booleans should read as yes/no questions: `isLoading`, `hasError`, `canSubmit`, not `loading`, `error`, `submit`.

---

## React: useEffect rules

`useEffect` is for **synchronizing with external systems** — DOM APIs, third-party widgets, WebSocket subscriptions, browser APIs. It's not a general-purpose "run code when something changes" tool.

Most `useEffect` usage in the wild is actually derived state, event handling, or data fetching that belongs somewhere else. When you see a `useEffect`, ask: **"What external system am I syncing with?"** If the answer is "nothing external, just some other state/prop", that's a sign it shouldn't be an effect.

### ❌ Don't derive state in useEffect

The most common misuse: transforming one piece of state into another. This causes an extra render cycle and is hard to trace.

```tsx
// ❌ Two renders: one for items change, one for filteredItems
const [filteredItems, setFilteredItems] = useState(items)
useEffect(() => {
  setFilteredItems(items.filter(i => i.active))
}, [items])

// ✅ Compute during render — zero extra renders, simpler, testable
const filteredItems = items.filter(i => i.active)
// Or if expensive:
const filteredItems = useMemo(() => items.filter(i => i.active), [items])
```

### ❌ Don't handle events in useEffect

If something happens *because the user did something*, put the logic in the event handler — not in an effect that watches state the handler set.

```tsx
// ❌ Indirection: handler sets state → effect reacts → fires API
function handleSubmit() {
  setSubmitted(true)
}
useEffect(() => {
  if (submitted) sendAnalytics('form_submitted')
}, [submitted])

// ✅ Just do it in the handler
function handleSubmit() {
  sendAnalytics('form_submitted')
}
```

### ❌ Don't fetch data in useEffect (in 2024+)

Plain `useEffect` + `fetch` has real problems: race conditions, no loading state, no cache, no deduplication. Use a data-fetching library instead.

```tsx
// ❌ Race condition if userId changes fast; no cleanup; no caching
useEffect(() => {
  fetch(`/api/users/${userId}`)
    .then(r => r.json())
    .then(setUser)
}, [userId])

// ✅ Use React Query / SWR — handles all of this for free
const { data: user } = useQuery({
  queryKey: ['user', userId],
  queryFn: () => fetchUser(userId),
})
```

If you can't use a library (legacy codebase, bundle constraints), write a custom hook that handles cancellation with `AbortController` and put it there — not inline in the component.

### ❌ Don't use useEffect to sync state with props

This pattern usually means the component should either be fully controlled or use `key` to reset.

```tsx
// ❌ Lags by one render; easy to get out of sync
useEffect(() => {
  setInternalValue(propValue)
}, [propValue])

// ✅ Option A: fully controlled (no local state)
<input value={propValue} onChange={onPropValueChange} />

// ✅ Option B: reset internal state when identity changes
<ExpensiveComponent key={userId} initialValue={user.name} />
```

### ✅ When useEffect IS the right tool

- Setting up a WebSocket / EventSource subscription
- Integrating a third-party library that needs a DOM node (`new Chart(ref.current, ...)`)
- Registering browser event listeners on `window` or `document`
- Triggering animations via a third-party library
- Logging / analytics that truly has no user event to attach to

Even then: always return a cleanup function.

```tsx
// ✅ Correct useEffect: external subscription with cleanup
useEffect(() => {
  const sub = eventBus.subscribe('update', handleUpdate)
  return () => sub.unsubscribe()
}, [])
```

### useEffect review checklist

When you see a `useEffect`, ask:
- [ ] What external system is this syncing with?
- [ ] Can this be replaced by `useMemo` or a computed variable?
- [ ] Can this be moved into an event handler?
- [ ] Does it set state that triggers another effect? (chained effects = red flag)
- [ ] Is there a missing cleanup / `AbortController`?
- [ ] Are all dependencies in the array honest (not suppressed with `// eslint-disable`)?

---

## When reviewing existing code

Go through these lenses in order:

### 1. Type safety
- Any `any`? Can it be typed or narrowed?
- Any `@ts-ignore` or `@ts-expect-error` without a comment explaining why?
- Any `as X` casts that are actually hiding a wrong assumption?
- Are function signatures typed (params + return type)?

### 2. Readability
- Can you read each function top-to-bottom without needing to jump around?
- Any unnamed magic numbers or strings?
- Nesting deeper than 3 levels?
- Variable/function names that require context to understand?
- Long ternaries or `&&` chains that could be named helpers?

### 3. Side effects and mutation
- Does the function mutate anything passed into it?
- Are there hidden dependencies (globals, singletons, `window`, `localStorage`) that aren't visible from the signature?
- Are effects (network, storage, DOM) mixed with logic?

### 4. Testability
- Can you test the core logic without mocking half the world?
- Are there I/O operations (fetch, timers, storage) that aren't injectable or interceptable?
- Does it rely on execution order or shared state between tests?

### 5. Async patterns
- Are all Promises awaited or returned? Floating promises are silent failure traps.
- Is error handling explicit (try/catch or `.catch()`) rather than assumed?
- Avoid mixing `async/await` and raw `.then()` in the same chain.

```ts
// ❌ Floating promise — errors silently swallowed
function onClick() {
  saveUser(data)  // forgot await
}

// ✅ Either handle or explicitly ignore
async function onClick() {
  try {
    await saveUser(data)
  } catch (err) {
    showToast('Save failed')
  }
}
```

---

## Quick checklist (use when reviewing a chunk of code)

- [ ] No `any` or `@ts-ignore` without justification
- [ ] All function params and return types are typed
- [ ] No mutation of inputs
- [ ] No magic numbers or strings
- [ ] Nesting ≤ 3 levels
- [ ] Side effects are isolated from logic
- [ ] All Promises are handled
- [ ] Names describe intent, not implementation
- [ ] Core logic is testable without real network/storage/timers
- [ ] No `useEffect` that is actually derived state or an event handler
- [ ] No `useEffect` fetching data without a library or AbortController
- [ ] No `// eslint-disable-next-line react-hooks/exhaustive-deps`

---

## What NOT to do

- Don't silence compiler errors with `as any` or `@ts-ignore` to "fix" build failures — fix the underlying type mismatch.
- Don't use `Object.assign()` or spread to mutate a ref/prop that came from outside.
- Don't put fetch calls inside components directly when they can live in a service/hook.
- Don't use `useEffect` to transform props/state into new state — compute it during render instead.
- Don't suppress exhaustive-deps lint warnings with `// eslint-disable` — fix the dependency array.
- Don't use `setTimeout` as a timing hack to work around render order issues.
- Don't use `!` (non-null assertion) on values that genuinely might be null — add a guard instead.
- Don't use barrel re-exports (`export * from`) as a workaround for tangled imports — fix the import structure.
