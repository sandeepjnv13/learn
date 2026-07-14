---
title: 209. Minimum Size Subarray Sum
order: 3
---

# 209. Minimum Size Subarray Sum

Given an array of positive integers `nums` and an integer `target`, return the
length of the **shortest contiguous subarray** whose sum is ≥ `target`, or `0` if
no such subarray exists.

```viz
type: approach
technique: Sliding window (variable size)
pattern: two-pointer
idea: Grow the window by adding nums[i]; while it's valid, shrink it from the left as far as possible; then measure it. Same-direction pointers, unlike the converging pair in 3Sum.
bullets:
  - Add - fold nums[i] into windowSum.
  - Maintain - shrink from the left while removing nums[start] would still leave the window ≥ target.
  - Use - if the window is valid, it's a length candidate: best ← min(best, i − start + 1).
gotcha: Shrink before you measure, not after - the window must be as tight as possible each time you record its length, or you'll miss the true minimum.
complexity: O(n) time · O(1) space
```

## The trick

Every sliding-window pass over an array - fixed size or variable size - is the
same three moves repeated for each `i`:

1. **Add** the current element to the window.
2. **Maintain** the window: while it's more than it needs to be, shrink from the
   left.
3. **Use** the (now-minimal) window to update the answer.

Here the window is *valid* once its sum reaches `target`. Each `i` grows it by one
element on the right, then the `while` loop pulls `start` rightward as long as
dropping `nums[start]` keeps the sum ≥ `target` - so by the time the window is
*used*, it's already the shortest window ending at `i`. Because every element is
added once and removed at most once, the whole scan is **O(n)** despite the nested
loop.

```java
class Solution {
    public int minSubArrayLen(int target, int[] nums) {
        if (nums == null || nums.length == 0) return 0;

        int start = 0, sol = Integer.MAX_VALUE;
        int currentSum = 0;
        int l = nums.length;
        for (int i = 0; i < l; i++) {
            // add element to window
            currentSum += nums[i];

            // maintain the window
            while (currentSum >= target && start <= i) {
                if (currentSum - nums[start] >= target) {
                    currentSum -= nums[start];
                    start++;
                } else {
                    break;
                }
            }
            // use the window
            if (currentSum >= target) {
                sol = Math.min(sol, i - start + 1);
            }
        }
        if (sol == Integer.MAX_VALUE) return 0;
        return sol;
    }
}
```

## Edge cases & gotchas

- **No subarray reaches `target`** - `sol` never updates and stays `Integer.MAX_VALUE`;
  translate that back to `0` before returning.
- **A single element already ≥ `target`** - the window shrinks to length 1 the
  moment it's added; don't assume the answer needs more than one element.
- **The whole array is the answer** - the shrink condition (`currentSum − nums[start]
  ≥ target`) correctly refuses to shrink further, so `start` stays at `0`.
- **Empty input** - guard for it explicitly; the loop body assumes at least one
  element.

```viz
type: min-size-subarray
array: [2, 3, 1, 2, 4, 3]
target: 7
```
