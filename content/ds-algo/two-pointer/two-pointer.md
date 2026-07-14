---
title: Two Pointer
order: 1
---

# Two Pointer Technique

Use two indices to solve a problem in a single pass. There are two families,
depending on which way the pointers move:

- **Converging** - `lo` and `hi` start at opposite ends and move toward each
  other, each step ruling out one candidate. This page and
  [3Sum](three-sum.md) are converging.
- **Sliding window** - both pointers move in the *same* direction; `start`
  trails `i` and only catches up when the window needs shrinking. Every pass
  is three moves per `i`: **add** the new element, **maintain** the window
  (shrink from the left while required), **use** the window as a candidate
  answer - true whether the window is fixed or variable size. See
  [209. Minimum Size Subarray Sum](minimum-size-subarray-sum.md) for the
  worked example.

Classic converging case: does a **sorted** array hold a pair summing to a target?

```viz
type: approach
technique: Converging pointers on a sorted array
pattern: two-pointer
idea: Start lo at the left and hi at the right; the sum's direction tells you which pointer to move, so each step eliminates one candidate.
bullets:
  - sum == target → found the pair.
  - sum < target → only a larger value can help, so move lo right.
  - sum > target → only a smaller value can help, so move hi left. Stop when lo meets hi.
gotcha: This only works because the array is sorted - sort first (or use a hash set instead) if it isn't. Watch the stop condition lo < hi so the pointers don't cross.
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
help again), so the whole scan is **O(n)** with no extra space - versus O(n²) for
checking every pair.

## Edge cases & gotchas

- **Unsorted input** breaks the direction logic - sort first, or reach for a hash
  set instead.
- **No pair exists** → the pointers meet (`lo == hi`) and you stop having found
  nothing.
- **Duplicates / multiple answers** - decide up front whether you want any one pair,
  all pairs, or a count, and skip over equal values accordingly.
