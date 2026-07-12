---
title: Two Pointer
order: 2
---

# Two Pointer Technique

Use two indices that move toward each other (or in the same direction) to solve
problems in a single pass. Classic example: check if a **sorted** array has a
pair summing to a target.

## Walking through it

Say we search a sorted `[1, 3, 4, 5, 7, 11]` for a pair summing to **9**, with
`lo` at the start and `hi` at the end:

1. `1 + 11 = 12 > 9` → too big, move `hi` left
2. `1 + 7 = 8 < 9` → too small, move `lo` right
3. `3 + 7 = 10 > 9` → move `hi` left
4. `3 + 5 = 8 < 9` → move `lo` right
5. `4 + 5 = 9` ✓ found the pair!

Each step discards one candidate, so the whole scan is **O(n)**.

> A native two-pointer visualizer will land once the component kit grows a
> recorder for it — for now this page is notes.
