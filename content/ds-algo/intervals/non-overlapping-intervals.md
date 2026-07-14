---
title: 435. Non-overlapping Intervals
order: 2
---

# 435. Non-overlapping Intervals

Given a list of intervals, find the **minimum number to remove** so that none
of the remaining intervals overlap.

> `intervals = [[1, 2], [2, 3], [3, 4], [1, 3]]` → `1` (remove `[1, 3]`; the
> rest - `[1,2], [2,3], [3,4]` - just touch, which is fine).

```viz
type: approach
technique: Greedy interval scheduling
pattern: interval
idea: Sort by start, keep one active interval, and on conflict always discard whichever ends later.
bullets:
  - No overlap (iv.start >= active.end) → iv becomes the new active.
  - Overlap → remove one interval, keep whichever has the smaller end.
  - Smaller end means more room for what comes next - that's the greedy proof.
gotcha: The greedy choice compares END times, not start times - start order only decides visiting order.
complexity: O(n log n) time (sort) · O(1) extra space
```

## The trick

This is **not** a merge problem - unlike [Insert Interval](insert-interval),
nothing gets unioned together. Instead, on every conflict you throw one
interval away, and the greedy question is *which one*.

Sort by start, then sweep keeping a single `active` interval. Whenever the
next interval `iv` doesn't overlap `active` (`iv.start >= active.end`), it
simply becomes the new `active` - no decision needed. When it **does**
overlap, one of the two must go, and the correct pick is whichever has the
**larger end**. Keeping the smaller end leaves the most room for whatever
comes next, so it can only ever overlap fewer future intervals - that's the
whole proof of correctness, same family as classic activity-selection.

```text
sort intervals by start
active ← intervals[0]
removed ← 0
for iv in intervals[1:]:
    if iv.start >= active.end:      # no overlap
        active ← iv
    else:                           # overlap - discard one
        removed ← removed + 1
        if iv.end < active.end:     # iv ends sooner
            active ← iv             # keep the smaller end
return removed
```

## Edge cases & gotchas

- **Sort first.** Unlike Insert Interval's input, this list is **not**
  guaranteed sorted - skip the sort and the greedy logic breaks immediately.
- **Compare ENDS, not starts.** The sort is by start (visiting order); the
  keep/discard decision on conflict is by **end** (`iv.end < active.end`).
  Mixing these up is the most common bug.
- **Touching is not overlapping.** Use `>=` for the no-overlap test - `[1,2]`
  then `[2,3]` do **not** conflict, so `[1,2],[2,3]` needs 0 removals.
- **Nested intervals.** `[1,10], [2,3], [4,5]` - the wide `[1,10]` has the
  larger end, so *it* gets discarded, not the narrow ones inside it.
- **All identical / fully overlapping.** `[1,5]` repeated 4× → keep just one,
  remove the other 3.
- **Count removals, not survivors** - the answer is `removed`, not
  `n - removed`.

```viz
type: non-overlapping-intervals
intervals: [[1, 2], [2, 3], [3, 4], [1, 3]]
```
