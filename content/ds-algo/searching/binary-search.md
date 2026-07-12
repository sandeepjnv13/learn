---
title: Binary Search
order: 1
---

# Binary Search

Repeatedly halve a **sorted** range: compare the middle element with the target
and discard the half that cannot contain it. **O(log n)**.

The visualizer below runs the real algorithm and records one step per line of
pseudocode. Edit the array or target and press the check to re-run; step through
manually or auto-play.

```viz
type: binary-search
array: [8, 3, 11, 5, 1, 7, 4]
target: 7
```
