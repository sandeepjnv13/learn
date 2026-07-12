---
title: Insert Interval
order: 1
---

# Insert Interval

**Problem.** You're given a list of intervals that are pairwise
**non-overlapping** but **not necessarily sorted**, plus one **new interval** to
insert. Return the updated list, still non-overlapping and sorted, with the new
interval merged into any intervals it touches.

> Example
> `intervals = [[1, 2], [3, 5], [6, 7], [8, 10], [12, 16]]`,
> `newInterval = [4, 8]`
> → `[[1, 2], [3, 10], [12, 16]]`
> (the new `[4, 8]` swallowed `[3, 5]`, `[6, 7]`, and `[8, 10]` into `[3, 10]`).

## Idea

Because the input can arrive unsorted, first **sort by start**. Then sweep the
list left to right carrying a single interval, `toAdd`, which starts as
`newInterval` and **keeps growing** as it absorbs anything it overlaps. For each
interval `iv` in order there are exactly three possibilities:

- **`iv` is entirely before `toAdd`** → it can never touch `toAdd`, so commit
  `iv` to the result and move on.
- **`iv` is entirely after `toAdd`** → nothing later can reach back to `toAdd`
  (the list is sorted), so `toAdd` is finished: commit it, then let `toAdd`
  *become* `iv` and keep sweeping.
- **otherwise they overlap** → merge `iv` into `toAdd`
  (`toAdd ← [min(starts), max(ends)]`).

After the loop, the interval still being carried in `toAdd` was never committed
inside the loop, so **add it once at the end**.

## Pseudocode

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

Runs in **O(n log n)** for the sort (**O(n)** if the list is already sorted).

## The tricky part — order the checks so overlap falls out by elimination

The easy bug here is trying to test **overlap first**. Two intervals overlap when
`iv.start ≤ toAdd.end` **and** `iv.end ≥ toAdd.start` — a two-part condition that
is genuinely fiddly at the **touching endpoints** (is `[2, 4]` "overlapping"
`[4, 8]`?), and it's easy to flip a `<` for a `≤` and merge intervals you
shouldn't (or fail to merge ones you should).

The clean way is the opposite: **check the two *non-overlap* cases first.** They
are each a single, unambiguous comparison:

- fully before: `iv.end < toAdd.start`
- fully after:  `iv.start > toAdd.end`

If neither is true, the intervals **must** overlap — so "overlap" is just the
`else`, with no boundary reasoning at all. Getting this ordering right is the
whole game:

1. **Non-overlap checks come before the overlap case.** Overlap is never tested
   directly; it's whatever survives the two rejections.
2. **The two non-overlap comparisons use strict `<` / `>`.** Touching endpoints
   (`iv.end == toAdd.start`) therefore fall through to the `else` and get
   merged — which is what we want, since adjacent intervals like `[1, 4]` and
   `[4, 8]` should combine into `[1, 8]`.

## Visualizer

Edit the intervals or the new interval and press the check to re-run; step
through manually or auto-play. Watch **`toAdd`** (top lane) stretch as it absorbs
overlaps, and see intervals drop into **result** as they're committed. The
highlighted pseudocode line and the event log narrate each decision.

```viz
type: insert-interval
intervals: [[1, 2], [3, 5], [6, 7], [8, 10], [12, 16]]
newInterval: [4, 8]
```
