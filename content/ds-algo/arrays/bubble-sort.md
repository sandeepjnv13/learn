---
title: Bubble Sort
order: 1
---

# Bubble Sort

Bubble sort repeatedly steps through the list, compares **adjacent** elements,
and swaps them if they are in the wrong order. After each full pass the largest
remaining element has "bubbled" to the end.

- **Time:** O(n²) worst / average, O(n) best (already sorted)
- **Space:** O(1)
- **Stable:** yes

> A step-by-step visualizer for bubble sort is coming once the native
> component kit grows a sort recorder — for now this page is notes + code.

## The code

```dart
List<int> bubbleSort(List<int> a) {
  for (var i = 0; i < a.length - 1; i++) {
    for (var j = 0; j < a.length - 1 - i; j++) {
      if (a[j] > a[j + 1]) {
        final t = a[j]; a[j] = a[j + 1]; a[j + 1] = t;
      }
    }
  }
  return a;
}
```

> The only thing the visualizer adds to this code is a `frames.add(...)` call
> at each compare and swap — the logic is identical.
