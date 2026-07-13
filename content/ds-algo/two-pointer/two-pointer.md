---
title: Two Pointer
order: 1
---

# Two Pointer Technique

Use two indices that move toward each other (or in the same direction) to solve a
problem in a single pass. Classic case: does a **sorted** array hold a pair summing
to a target?

```viz
type: approach
technique: Converging pointers on a sorted array
pattern: two-pointer
idea: Start lo at the left and hi at the right; the sum's direction tells you which pointer to move, so each step eliminates one candidate.
bullets:
  - sum == target → found the pair.
  - sum < target → only a larger value can help, so move lo right.
  - sum > target → only a smaller value can help, so move hi left. Stop when lo meets hi.
gotcha: This only works because the array is sorted — sort first (or use a hash set instead) if it isn't. Watch the stop condition lo < hi so the pointers don't cross.
complexity: O(n) time · O(1) space
```

## Why it works

Searching `[1, 3, 4, 5, 7, 11]` for a pair summing to **9**:

1. `1 + 11 = 12 > 9` → too big, move `hi` left
2. `1 + 7 = 8 < 9` → too small, move `lo` right
3. `3 + 7 = 10 > 9` → move `hi` left
4. `3 + 5 = 8 < 9` → move `lo` right
5. `4 + 5 = 9` ✓ found the pair

Each comparison discards exactly one candidate (the current `lo` or `hi` can never
help again), so the whole scan is **O(n)** with no extra space — versus O(n²) for
checking every pair.

## Edge cases & gotchas

- **Unsorted input** breaks the direction logic — sort first, or reach for a hash
  set instead.
- **No pair exists** → the pointers meet (`lo == hi`) and you stop having found
  nothing.
- **Duplicates / multiple answers** — decide up front whether you want any one pair,
  all pairs, or a count, and skip over equal values accordingly.
