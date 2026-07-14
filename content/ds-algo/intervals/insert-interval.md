---
title: 57. Insert Interval
order: 1
---

# 57. Insert Interval

Given non-overlapping intervals (not necessarily sorted) and one **new interval**,
return the updated list - still non-overlapping and sorted - with the new interval
merged into anything it touches.

> `intervals = [[1, 2], [3, 5], [6, 7], [8, 10], [12, 16]]`, `newInterval = [4, 8]`
> → `[[1, 2], [3, 10], [12, 16]]` (the new `[4, 8]` swallowed `[3, 5]`, `[6, 7]`,
> `[8, 10]`).

```viz
type: approach
technique: Sort, then sweep with a growing toAdd
pattern: interval
idea: Sort by start, then sweep once carrying one interval, toAdd, that keeps absorbing anything it overlaps.
bullets:
  - iv entirely before toAdd → commit iv and move on.
  - iv entirely after toAdd → toAdd is finished, commit it, then let toAdd become iv.
  - otherwise they overlap → toAdd = [min(starts), max(ends)]. After the loop, commit the toAdd still being carried.
gotcha: Test the two NON-overlap cases first with strict `<` / `>`; overlap is then just the else, and touching endpoints ([1,4] & [4,8]) correctly fall through and merge.
complexity: O(n log n) time (O(n) if already sorted) · O(n) space
```

## The trick

Carry a single interval `toAdd`, starting as `newInterval`, and let it **grow** as it
absorbs overlaps. The subtle part is **ordering the checks**. Testing overlap directly
means the two-part condition `iv.start ≤ toAdd.end && iv.end ≥ toAdd.start` - genuinely
fiddly at touching endpoints, and easy to get a `<` vs `≤` wrong. Instead check the two
**non-overlap** cases first, each a single unambiguous comparison:

- fully before: `iv.end < toAdd.start`
- fully after:  `iv.start > toAdd.end`

If neither holds, the intervals **must** overlap - so "overlap" is just the `else`,
with no boundary reasoning at all.

```text
sort intervals by start
result ← [ ]
toAdd ← newInterval
for iv in intervals:
    if iv.end < toAdd.start:        # iv fully BEFORE  → no overlap
        result.add(iv)
    else if iv.start > toAdd.end:   # iv fully AFTER   → no overlap
        result.add(toAdd)
        toAdd ← iv
    else:                           # what's left      → OVERLAP
        toAdd ← merge(toAdd, iv)
result.add(toAdd)
return result
```

## Edge cases & gotchas

- **Order the checks:** non-overlap cases before the overlap `else`. Overlap is never
  tested directly - it's whatever survives the two rejections.
- **Strict `<` / `>`** on the non-overlap checks, so touching endpoints (`iv.end ==
  toAdd.start`) fall through and merge - `[1, 4]` and `[4, 8]` become `[1, 8]`.
- **Commit `toAdd` once at the end:** the last carried interval is never committed
  inside the loop.

Edit the intervals or the new interval and re-run. Watch **`toAdd`** (top lane)
stretch as it absorbs overlaps, and intervals drop into **result** as they commit.

```viz
type: insert-interval
intervals: [[1, 2], [3, 5], [6, 7], [8, 10], [12, 16]]
newInterval: [4, 8]
```
