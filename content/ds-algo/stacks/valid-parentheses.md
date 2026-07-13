---
title: Valid Parentheses
order: 1
---

# Valid Parentheses

Given a string of brackets `()[]{}`, decide whether every bracket is correctly
**opened and closed in the right order**.

## Idea — a stack of "still-open" brackets

A closing bracket must always match the **most recently opened** bracket that is
still waiting — that's *last-in, first-out*, exactly what a **stack** models.

- **Opening bracket** `(` `[` `{` → **push** it (remember we owe it a match).
- **Closing bracket** `)` `]` `}` →
  - if the stack is **empty**, there's nothing to close → **invalid**;
  - otherwise **pop** the top and check it's the matching opener. If it isn't →
    **invalid**.
- At the end, the string is valid **iff the stack is empty** (no opener left
  unmatched).

**O(n)** time, **O(n)** space. The stack is drawn horizontally; its **top** (the
right end, highlighted) is the single place where both a push and a pop happen —
exactly the opener a closer must match.

```viz
type: valid-parentheses
input: "([{}])"
```

Try `([)]` to see a mismatch, `(((` to see leftover openers, or `]` to see a
closer with an empty stack.
