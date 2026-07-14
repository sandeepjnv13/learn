---
title: Other Problems
order: 1
---

# Other Problems

A grab-bag of greedy problems that don't (yet) warrant their own page.

## At a Glance

| # | Problem | Complexity | Key Point |
|---|---------|------------|-----------|
| 1013 | [Partition Array Into Three Parts With Equal Sum](#1013-partition-array-into-three-parts-with-equal-sum) | O(n) time · O(1) space | Can't early-break on `runningSum > target` - negatives make it non-monotonic |

---

## 1013. Partition Array Into Three Parts With Equal Sum

Given an array, decide whether it can be split into **three non-empty
contiguous parts** whose sums are all equal.

> `arr = [3, 3, -6, 3, 3]` → `true` (each part sums to `3`: `[3]`, `[3, -6, 3]`, `[3]`)
> `arr = [1, -1, 1, -1]` → `false` (total sum is `0`, but there's no way to find
> three separate cut points that each land on a running sum of `0`)

```viz
type: approach
technique: Running sum against a fixed target, count completed parts
pattern: running-sum
idea: The total sum must split evenly into three equal parts, so compute target = sum / 3, then sweep once counting how many times the running sum hits that target.
bullets:
  - Compute the total sum. If sum % 3 != 0, no valid split exists - bail out immediately.
  - target = sum / 3. Sweep with runningSum = 0 and found = 0.
  - Whenever runningSum == target, that's a valid cut point - reset runningSum to 0 and increment found.
  - The array can be partitioned iff found >= 3 by the end (>= so a longer array with more matching cut points still counts, but the last part must still be non-empty - the loop naturally leaves it out since we stop resetting once we've already found 3).
gotcha: Can't early-break on `runningSum > target` - negatives make it non-monotonic, so only an exact `==` check is safe.
complexity: O(n) time · O(1) space
```

### The trick

If the array splits into three equal parts, each part sums to `target = sum / 3`.
Walk the array once, accumulating a running sum. Every time that running sum
exactly equals `target`, that's a legal place to end a part - reset the
accumulator to `0` and count it. Three such resets (with array left over for
the third part) means a valid partition exists.

### Edge cases & gotchas

- **Sum not divisible by 3** → return `false` immediately; don't bother scanning.
- **Negative numbers mean you cannot break early on `runningSum > target`.**
  With an all-positive array, overshooting the target means this path is dead
  and you could stop. With negatives in play, a running sum that's currently
  above (or below) `target` can still come back down (or up) to exactly
  `target` a few elements later - e.g. `[3, 3, -6, 3, 3]`: after `[3, 3]` the
  running sum is `6`, which overshoots `target = 3`, but the very next element
  `-6` brings it back to `0`... the point is the sum is **not monotonic**, so
  only an exact `==` check against `target` is safe, never a `>` short-circuit.
- **Target of `0`** (e.g. `[0, 0, 0, 0]`) - every prefix sum can equal `0`
  repeatedly; make sure the reset-and-count logic still requires the array to
  have at least 3 non-empty parts, not just 3 zero-crossings, if you extend this
  to also return the split points.
