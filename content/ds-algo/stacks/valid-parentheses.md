---
title: 20. Valid Parentheses
order: 1
---

# 20. Valid Parentheses

Given a string of brackets `()[]{}`, decide whether every bracket is correctly
**opened and closed in the right order**.

```viz
type: approach
technique: Stack of still-open brackets
pattern: stack
idea: A closer must match the most recently opened bracket still waiting — last-in, first-out, which is exactly a stack.
bullets:
  - Opening bracket → push it (we now owe it a match).
  - Closing bracket → the stack must be non-empty and its top must be the matching opener; pop it. Otherwise the string is invalid.
  - Valid iff the stack is empty at the end (no opener left unmatched).
gotcha: A closer on an empty stack is immediately invalid, and leftover openers at the end are invalid too — both are easy to forget when you only check "does the top match?".
complexity: O(n) time · O(n) space
```

## The trick

Correct nesting means the **most recently opened** bracket must be the **first to
close** — precisely last-in-first-out. Push every opener; when a closer arrives, the
only bracket it could legally match is the one on top, so pop and compare. If they
don't match (or there's nothing to pop), the nesting is already broken.

## Edge cases & gotchas

- **Closer with an empty stack** (`]`) → nothing to match → invalid. Guard the pop.
- **Leftover openers** (`(((`) → the scan finishes but the stack isn't empty →
  invalid. The final emptiness check is not optional.
- **Wrong type** (`([)]`) → the top is `(` when we see `]`, so the type check, not
  just the count, is what catches crossed nesting.

The stack below is drawn horizontally; its **top** (right end, highlighted) is the
single place a push and a pop happen — exactly the opener a closer must match.

```viz
type: valid-parentheses
input: "([{}])"
```
