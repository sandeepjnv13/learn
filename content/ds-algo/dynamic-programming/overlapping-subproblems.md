---
title: Overlapping Subproblems
order: 1
---

# Overlapping Subproblems

```viz
type: approach
technique: Memoize the plain recursion
pattern: overlapping-subproblems
idea: If the DP is hard to derive, write the obvious recursion and cache each answer.
bullets:
  - Recursion re-solves the same cell down every branch that reaches it
  - A memo turns every repeat call into an instant lookup, no subtree
  - Same complexity as the table, and far easier to reason about
gotcha: Cache on the arguments that identify the subproblem - here (i, j), not the path taken to reach it.
complexity: O(m·n) time · O(m·n) space
```

Walk from the top-left of a grid to the bottom-right moving only **right or down**,
and pay every cell you land on. Cheapest total wins. (This is LeetCode 64,
Minimum Path Sum, on `[[1,3,1],[1,5,1],[4,2,1]]`.)

The recurrence writes itself - to stand on `(i, j)` you must have come from
directly above or directly left, so take whichever was cheaper:

```
minCost(i, j) = grid[i][j] + min(minCost(i-1, j), minCost(i, j-1))
minCost(0, 0) = grid[0][0]
```

That is a correct solution already. It is also exponential, and the reason is
worth looking at rather than taking on faith: **the recursion keeps re-solving
cells it has already solved.** `(1,1)` is reachable through two different
branches, and each branch rebuilds its entire subtree from scratch.

Click **Add a memo** to cache each cell's answer the first time it is computed.
Nothing about the recurrence changes - the repeat calls just stop expanding:

```viz
type: overlapping-subproblems
grid: [[1, 3, 1], [1, 5, 1], [4, 2, 1]]
```

That is the whole idea. You never derived a table, never worked out a fill order:
you wrote the obvious recursion, added two lines, and the exponential blowup
disappeared because there are only 9 distinct subproblems to solve.

## Dropping the recursion

The memo table above gets filled in whatever order the recursion happens to reach
things. But look at the recurrence again: `(i, j)` only ever needs the cell
**above** and the cell **left**. Walk the grid top-to-bottom, left-to-right and
both are guaranteed to be done already - so you can fill the table directly and
skip the recursion entirely.

Same recurrence, same `O(m·n)`, no call stack:

```viz
type: min-path-dp
grid: [[1, 3, 1], [1, 5, 1], [4, 2, 1]]
```

Neither version is "more dynamic programming" than the other. Memoized recursion
is top-down, tabulation is bottom-up, and they compute the same 9 numbers. Reach
for the recursion first when the fill order is not obvious.

## Edge cases & gotchas

- **The first row and column have no choice.** There is no cell above row 0 and
  none left of column 0, so `min()` would read off the grid. Handle them as their
  own cases (the table does this in two separate loops).
- **Memo on the subproblem, not the journey.** The key is `(i, j)` because the
  cost of the rest of the walk depends only on where you are, not how you got
  there. If your recursion also carried, say, a budget, the key would have to
  include it.
- **A cache hit must return immediately.** If you look the value up but still
  recurse, you have written a slower naive recursion.
- **Greedy fails here.** Taking the cheaper *next* cell is not the same as the
  cheaper *total* - try the "Detour pays off" preset, where the cheap first step
  walks into a wall.
