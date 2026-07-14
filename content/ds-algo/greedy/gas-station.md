---
title: 134. Gas Station
order: 2
---

# 134. Gas Station

There are `n` gas stations in a circle. `gas[i]` is the fuel available at
station `i`; `cost[i]` is the fuel needed to drive from station `i` to
station `i+1`. Starting with an empty tank at some station, return the
starting index that lets you complete the full circuit, or `-1` if none
exists (the answer is guaranteed unique if it exists).

> `gas = [1,2,3,4,5]`, `cost = [3,4,5,1,2]` → `3` (start at index 3)
> `gas = [2,3,4]`, `cost = [3,4,3]` → `-1` (total cost exceeds total gas)

At each station `i`: arrive, add `gas[i]` to the tank, then pay `cost[i]`
to reach `i+1`.

```viz
type: approach
technique: One-pass running balance, reset start on deficit
pattern: gas-station
idea: If total gas >= total cost a valid start exists, and it's always the station right after the point where the running tank balance hit its lowest.
bullets:
  - runningGas accumulates (gas[i] - cost[i]) as you sweep left to right.
  - The moment runningGas goes negative, no station from the current startIdx through i can be a valid start - reset runningGas to 0 and set startIdx = i + 1.
  - Track totalGas and totalCost separately; only return startIdx if totalGas >= totalCost, else -1.
gotcha: A single forward pass is enough - you never need to re-check earlier stations, because if station j (between startIdx and i) could reach i, then starting at startIdx and picking up its surplus first would also reach i.
complexity: O(n) time · O(1) space
```

## The trick

Track a running tank balance while sweeping once, left to right. Whenever the
balance dips below zero, no station seen so far (from the current `startIdx`
through `i`) can be the answer - any of them would hit the same wall - so reset
the balance to `0` and move the candidate start to `i + 1`. Separately sum
`totalGas` and `totalCost`: if `totalGas >= totalCost`, a solution is
guaranteed to exist, and it's exactly the `startIdx` left over after the sweep
(the station right after the deepest deficit).

```java
class Solution {
    public int canCompleteCircuit(int[] gas, int[] cost) {
        if (gas == null || gas.length < 1) return 0;

        int totalGas = 0;
        int totalCost = 0;
        int runningGas = 0;
        int startIdx = 0;

        for (int i = 0; i < gas.length; i++) {
            totalGas += gas[i];
            totalCost += cost[i];
            runningGas += (gas[i] - cost[i]);
            if (runningGas < 0) {
                runningGas = 0;
                startIdx = i + 1;
            }
        }

        if (totalGas >= totalCost) return startIdx;
        return -1;
    }
}
```

## Edge cases & gotchas

- **`totalGas < totalCost`** → always `-1`, no matter what the per-station
  pattern looks like - check this before trusting `startIdx`.
- **Forgetting to reset `runningGas` to `0`** on a deficit is the most common
  bug - carrying a negative balance forward corrupts every later station's
  check.
- **Single station** (`n == 1`) - the loop still works: if `gas[0] >= cost[0]`
  it returns `0`.
- **Multiple deficits in a row** - each negative dip pushes `startIdx` further
  right; only the *last* reset before the sweep ends matters, don't try to
  remember earlier candidates.
- **Assuming you need to re-verify the chosen `startIdx`** by simulating the
  circuit again - unnecessary. The one-pass invariant (surplus before a
  deficit only helps, never hurts) already guarantees correctness when
  `totalGas >= totalCost`.

```viz
type: gas-station
gas: [1, 2, 3, 4, 5]
cost: [3, 4, 5, 1, 2]
```
