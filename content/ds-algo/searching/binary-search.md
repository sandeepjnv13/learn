---
title: 704. Binary Search
order: 1
---

# 704. Binary Search

Find a target in a **sorted** array in **O(log n)**.

```viz
type: approach
technique: Halve the search range
pattern: binary-search
idea: Keep a candidate range [lo, hi]; compare the middle element to the target and throw away the half that can't contain it.
bullets:
  - If arr[mid] == target → found.
  - If target > arr[mid] → the answer can only be to the right, so lo = mid + 1.
  - If target < arr[mid] → hi = mid - 1. Repeat until lo > hi (not present).
gotcha: Compute mid as lo + (hi - lo) / 2 to avoid overflow, and always move past mid (mid ± 1) — reusing mid as the new bound loops forever.
complexity: O(log n) time · O(1) space
```

## The trick

Because the array is **sorted**, one comparison against the middle element rules out
an entire half: if the target is bigger than `arr[mid]`, nothing to the left can
match, and vice-versa. Each step discards half the remaining candidates, so the
range collapses in about `log₂ n` steps.

## Edge cases & gotchas

- **Termination:** loop while `lo <= hi`; when `lo > hi` the range is empty → not
  found. Off-by-one here is the classic bug.
- **Move past `mid`:** advance to `mid + 1` / `mid - 1`. Setting `lo = mid` or
  `hi = mid` can leave the range unchanged and spin forever.
- **Overflow:** `lo + (hi - lo) / 2` instead of `(lo + hi) / 2` for large indices.

The visualizer runs the real algorithm and records one step per line of pseudocode —
edit the array or target and re-run, or step through manually.

```viz
type: binary-search
array: [8, 3, 11, 5, 1, 7, 4]
target: 7
```
