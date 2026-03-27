---
name: lean-unit-testing
description: Eliminate useless, redundant, and low-value unit tests. Use this skill proactively whenever writing, reviewing, or refactoring unit tests in any language. Trigger when the user mentions "unit test", "test review", "redundant test", "useless test", "test quality", "test cleanup", or when you are about to generate test code. Also apply silently when generating tests as part of feature implementation — every test you write should pass the value check below before being included.
---

# Lean Unit Testing

Write tests that catch real bugs. Every test should justify its existence by covering a distinct behavior that, if broken, would cause a user-visible problem. If a test doesn't meet this bar, don't write it.

## The One-Question Filter

Before writing any test, ask: **"What real bug would this catch that no other test catches?"**

If you can't answer clearly, skip it.

## What Makes a Good Test

### One behavior, one test

A test name should describe a single behavior. If you need "and" in the name, split it — unless the assertions verify different facets of the same action (same Arrange + Act).

```ts
// Good — clear behavior
it('should reject empty email with validation error', ...)
it('should redirect to dashboard after login', ...)

// Bad — two behaviors crammed together
it('should validate email and redirect after login', ...)
```

### Name describes the "should...when" contract

The name is the test's documentation. Someone reading only test names should understand what the system does.

```ts
// Good — reads like a spec
it('should display error message when deletion fails', ...)
it('should reset form fields after successful submission', ...)

// Bad — meaningless
it('test1', ...)
it('works', ...)
it('handles the thing', ...)
```

### Prefer real code over mocks

Mocks are a last resort for things you can't control (network, timers, third-party services). If you can test with real objects, do it — mocked tests can pass while real integration is broken.

**When mocks are justified:**
- External HTTP calls
- Timers / dates
- Browser APIs (`window.confirm`, `localStorage`)
- Third-party services you don't own

**When mocks are a smell:**
- Mocking your own modules to isolate a single function
- Mocking so much that the test only proves mocks work
- Every dependency of the unit is mocked

### Test complexity signals design problems

| Symptom | Root cause |
|---------|-----------|
| Test setup is 40 lines, assertion is 2 | Code under test has too many dependencies — simplify the interface |
| Must mock everything | Tight coupling — use dependency injection |
| Can't test without private access | Logic buried in wrong layer — extract to a testable unit |
| Test is harder to read than the code | Over-engineering — step back and simplify |

### Cover edges, not just the happy path

Good tests exercise boundaries and failure modes, not just the golden path:
- Empty / null / undefined inputs
- Boundary values (0, -1, max int)
- Error responses from dependencies
- Concurrent / race conditions (when relevant)

But don't invent impossible scenarios — test edges that real users or real systems can actually hit.

## Anti-Patterns to Avoid

### 1. Redundant / Overlapping Tests

Two tests that exercise the same code path with the same assertions are waste. The second one catches zero additional bugs.

**Bad** — two separate tests that both verify "cancel doesn't delete":
```ts
it('should show confirmation when Delete is clicked', () => {
  confirmSpy.mockReturnValue(false);
  fireEvent.click(deleteButton);
  expect(confirmSpy).toHaveBeenCalledWith('Delete Sherlock Holmes?');
});

it('should not call deleteUser when cancelled', () => {
  confirmSpy.mockReturnValue(false);
  fireEvent.click(deleteButton);
  expect(mockDeleteUser).not.toHaveBeenCalled();
});
```

**Good** — one test covers both the confirmation message and the cancel behavior:
```ts
it('should confirm with user name and not delete when cancelled', () => {
  confirmSpy.mockReturnValue(false);
  fireEvent.click(deleteButton);
  expect(confirmSpy).toHaveBeenCalledWith('Delete Sherlock Holmes?');
  expect(mockDeleteUser).not.toHaveBeenCalled();
});
```

**How to spot it:** If two tests have identical Arrange and Act steps but only differ in Assert, merge them. Multiple assertions on the same action are fine — the smell is duplicated setup and execution.

### 2. Tautological Tests (Testing Your Mocks)

A test that only verifies a mock returns what you configured it to return proves nothing about your code.

**Bad:**
```ts
mockAxios.get.mockResolvedValue({ data: users });
await fetchUsers();
expect(mockAxios.get).toHaveBeenCalledWith('/users'); // just echoing setup
```

**Good** — verify the *effect* of the call, not the call itself:
```ts
mockAxios.get.mockResolvedValue({ data: users });
await fetchUsers();
expect(store.getState().users).toEqual(users); // actual state changed
```

### 3. Retry / "Can I Do It Again" Tests

Testing that a user can retry an action after failure rarely catches bugs. If the first click works and error display works, the second click goes through the same code path.

**Bad:**
```ts
it('should allow retry after error', async () => {
  mockDelete.mockRejectedValueOnce(new Error('fail'));
  fireEvent.click(button);
  await waitFor(() => expect(screen.getByText('fail')).toBeInTheDocument());

  mockDelete.mockResolvedValueOnce(undefined);
  fireEvent.click(button);
  await waitFor(() => expect(mockDelete).toHaveBeenCalledTimes(2));
});
```

This test only proves that `onClick` fires twice — the same handler, the same path. The error-clearing behavior (`setError(null)`) is trivially covered by the success test which starts with no error.

**When retry IS worth testing:** Only if there's explicit retry logic (retry count, backoff, disabled state that re-enables). If the "retry" is just "click the button again", skip it.

### 4. Existence-Only Tests

Testing that a component renders without verifying any behavior is almost never useful — it catches only catastrophic import/render failures, which any other behavioral test would also catch.

**Bad:**
```ts
it('should render the panel', () => {
  render(<Panel />);
  expect(screen.getByTestId('panel')).toBeInTheDocument();
});
```

**Good** — test what the panel actually does:
```ts
it('should display title and children', () => {
  render(<Panel title="Users"><span>content</span></Panel>);
  expect(screen.getByText('Users')).toBeInTheDocument();
  expect(screen.getByText('content')).toBeInTheDocument();
});
```

### 5. Testing Framework / Language Behavior

Don't test that React renders children, that `useState` holds state, or that `Array.filter` filters. Trust the platform.

**Bad:**
```ts
it('should update state when setState is called', () => {
  const [value, setValue] = useState('');
  setValue('hello');
  expect(value).toBe('hello'); // testing React, not your code
});
```

### 6. Implementation-Coupled Tests

Tests that break when you refactor without changing behavior are a maintenance tax, not a safety net.

**Signals of over-coupling:**
- Asserting exact mock call counts (`toHaveBeenCalledTimes(3)`) when the count isn't meaningful
- Testing internal state instead of rendered output
- Checking the order of function calls when order doesn't matter to the user

**Prefer:** Assert on user-visible outcomes (rendered text, navigation, API response) rather than internal mechanics.

### 7. Trivial Getter/Setter Tests

Don't test code with zero logic. If a function does `return this.name`, testing it adds noise without value.

**Exception:** Test computed properties or getters with conditional logic.

## Decision Checklist

When writing a test, run through this quickly:

1. **Distinct bug coverage** — Does this catch a bug no other test catches?
2. **Behavioral, not structural** — Am I testing what the user sees, not how the code is organized?
3. **Not a mock echo** — Am I verifying a real effect, not just that my mock was called?
4. **Survives refactoring** — If I restructure the internals without changing behavior, does this test still pass?
5. **Not already covered** — Is there another test with the same Arrange + Act that already checks this?

If any answer is "no", reconsider.

## Merging Strategy

When you find overlapping tests during review:

1. Identify tests with **identical Arrange + Act** (same setup, same trigger)
2. Keep the one with the most meaningful assertions
3. Move any unique assertions from the other test(s) into the keeper
4. Delete the duplicates

Multiple assertions per test are fine when they verify different facets of the same action. The goal is one test per *behavior*, not one test per *assertion*.
