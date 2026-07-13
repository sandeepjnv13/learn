---
title: Next Greater Element
order: 2
---

# Next Greater Element

For each element, find the **first larger value to its right** (or −1 if none).
The brute force is O(n²); a **monotonic stack** does it in **O(n)**.

## Idea — a strictly decreasing stack of "waiting" elements

Keep a stack of indices whose answer we don't know yet. We maintain the
invariant that their **values are strictly decreasing** from bottom to top.

- For each new value `arr[i]`:
  - while the stack's top value is **smaller** than `arr[i]`, that element has
    just found its next greater element (`arr[i]`) → **pop** it and record it;
  - then **push** `i`.
- Whatever is still on the stack at the end never found anything larger → −1.

Each index is pushed and popped at most once → **O(n)**. The stack is drawn
horizontally as **normalised bars**, so the strictly-decreasing invariant is
visible as a downward staircase left→right; its highlighted **top** (right end)
is where both push and pop happen.

### Is the described approach correct?

Yes. Popping every top smaller than the current value and assigning the current
value as their answer is exactly right, and the leftover elements correctly get
−1. One subtlety: use a **strict** comparison (`top < current`) so that equal
values don't resolve each other — that matches the usual "*strictly* greater"
definition. (If you instead want "next greater **or equal**", pop on `top <=
current`.)

```viz
type: next-greater-element
array: [2, 1, 2, 4, 3]
```

Try `[5, 4, 3, 2, 1]` (all −1) or `[1, 2, 3, 4, 5]` (each resolves the previous).
