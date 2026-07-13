---
title: 15. 3Sum
order: 2
---

# 15. 3Sum

Given an integer array, return every **unique triplet** `[a, b, c]` that sums to
**0** — no index reused, no duplicate triplets.

```viz
type: approach
technique: Sort + converging two pointers
pattern: two-pointer
idea: Sort first; fix one number as the anchor, then the problem shrinks to "find a pair in the rest that sums to −anchor" — exactly the sorted two-pointer scan.
bullets:
  - Fix anchor nums[i]; set lo = i+1, hi = n−1 and read s = nums[i] + nums[lo] + nums[hi].
  - s == 0 → record it, then move both inward. s < 0 → move lo right; s > 0 → move hi left.
  - Skip equal values at the anchor and after a hit, so each triplet is emitted once.
gotcha: The dedup skips are the whole difference between right and wrong — without them you get repeated triplets. Skip a repeated anchor, and after a match advance lo/hi past equal neighbours.
complexity: O(n²) time · O(1) extra space
```

## The trick

Brute force checks every triple — O(n³). Sorting unlocks something better: once the
array is sorted, **fixing the first number `nums[i]`** turns the rest into a
*sorted two-sum* — find a pair after `i` summing to `−nums[i]`. That inner search is
the converging two-pointer scan: because the array is sorted, the sum's sign tells
you exactly which pointer to move, so every step discards one candidate. One O(n)
scan per anchor over `n` anchors gives **O(n²)**.

## Edge cases & gotchas

- **Duplicate anchors** (`[-1, -1, ...]`) — skip `nums[i]` when it equals
  `nums[i-1]`, or you re-emit the same triplets.
- **Duplicate pointer values** — after recording a hit, advance `lo`/`hi` past any
  equal neighbours before continuing, for the same reason.
- **Fewer than 3 numbers** → no triplet is possible; return `[]`.
- **All zeros / all one sign** — `[0,0,0]` yields exactly one `[0,0,0]`; an
  all-positive (or all-negative) array yields nothing.

```viz
type: three-sum
array: [-1, 0, 1, 2, -1, -4]
```
