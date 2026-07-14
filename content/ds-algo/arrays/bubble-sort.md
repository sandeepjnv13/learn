---
title: Bubble Sort
order: 1
---

# Bubble Sort

Repeatedly compare **adjacent** elements and swap them when they're out of order;
after each full pass the largest remaining element has "bubbled" to the end.

```viz
type: approach
technique: Adjacent-compare passes
pattern: adjacent-swap
idea: Walk the array comparing each pair of neighbours; swap the pair when the left one is bigger. Every pass floats the next-largest value to its final place at the end.
bullets:
  - Inner loop compares a[j] with a[j+1] and swaps if a[j] > a[j+1].
  - After pass i the last i elements are already sorted, so the inner loop can stop earlier each time.
  - If a whole pass makes no swaps, the array is already sorted - stop early.
gotcha: Without the "no swaps → stop" flag you always pay O(n²), even on already-sorted input where an early exit gives O(n).
complexity: O(n²) avg/worst · O(n) best · O(1) space · stable
```

## The trick

The only operation is a swap of two **neighbours**, so a large value can only move
one position per comparison - but across a full pass the biggest unsorted value gets
carried all the way to the end. Repeat, shrinking the unsorted prefix by one each
time, and the array sorts itself. It's the simplest correct sort, useful mainly as a
mental model, not for real workloads.

## The code

```dart
List<int> bubbleSort(List<int> a) {
  for (var i = 0; i < a.length - 1; i++) {
    var swapped = false;
    for (var j = 0; j < a.length - 1 - i; j++) {
      if (a[j] > a[j + 1]) {
        final t = a[j]; a[j] = a[j + 1]; a[j + 1] = t;
        swapped = true;
      }
    }
    if (!swapped) break;   // a clean pass → already sorted
  }
  return a;
}
```

## Edge cases & gotchas

- **Already sorted** → with the `swapped` flag it's one O(n) pass; without it, still
  O(n²).
- **`- 1 - i` bound:** the tail is already sorted after pass `i`; re-scanning it wastes
  work (and an unbounded inner loop reads past the end).
- **Stability:** swap only on strict `>` so equal keys keep their original order.
