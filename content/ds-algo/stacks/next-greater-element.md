---
title: 496. Next Greater Element
order: 2
---

# 496. Next Greater Element

For each element, find the **first larger value to its right** (or −1 if none).

```viz
type: approach
technique: Monotonic decreasing stack
pattern: monotonic-stack
idea: Hold the indices whose answer is still unknown - kept with values strictly decreasing from bottom to top.
bullets:
  - For each arr[i], pop every top whose value is smaller than arr[i] - each of those just found its next greater element (arr[i]); record it.
  - Then push i. Anything still on the stack at the end never found anything larger → −1.
gotcha: Use a strict `<` (top < current). Equal values must not resolve each other - that matches "strictly greater". Pop on `<=` only if you actually want next-greater-or-equal.
complexity: O(n) time · O(n) space
```

## The trick

The brute force scans right from every element - O(n²). The stack removes the
rescanning: it remembers only the elements **still waiting** for an answer, and it
keeps them **strictly decreasing** top-down. That invariant is the whole point -
when a new value arrives it is the next greater element for *every* waiting top it
exceeds, and those tops are exactly the ones sitting above it in the stack, so a
single run of pops resolves all of them at once.

Because each index is **pushed once and popped at most once**, the total work is
linear - O(n) - even though the answer for one element can resolve many others.

## Edge cases & gotchas

- **Strictly decreasing input** (`[5, 4, 3, 2, 1]`) → nothing ever resolves; every
  answer is −1. **Increasing input** (`[1, 2, 3, 4, 5]`) → each element immediately
  pops its predecessor.
- **Equal values** don't count as "greater": with strict `<`, a run of equal values
  stays on the stack and only a genuinely larger value pops them.
- **Single element** → −1 (no successor).

The stack below is drawn as horizontal **normalised bars**, so the strictly-decreasing
invariant reads as a downward staircase; its highlighted **top** (right end) is where
both the push and the pops happen.

```viz
type: next-greater-element
array: [2, 1, 2, 4, 3]
```
