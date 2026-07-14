---
title: 987. Vertical Order Traversal
order: 2
---

# 987. Vertical Order Traversal of a Binary Tree

Assign each node a column (`x`) and row (`y`) - root is `(0, 0)`, left child is
`col − 1`, right child is `col + 1`, every step down is `row + 1` - then report the
values **column by column** (left→right), **top→bottom** within a column, and by
**value** when two nodes share the exact same `(col, row)`.

```viz
type: approach
technique: Coordinates, then sort, then group
pattern: coordinate
idea: Stop thinking about tree shape; stamp every node with a (col, row) coordinate, then the whole answer is just a sort.
bullets:
  - DFS once carrying (col, row) - left is col−1, right is col+1, both are row+1 - recording (col, row, value) per node.
  - Sort the tuples by the single key (col, row, value) - it encodes all three tie-break rules at once.
  - Sweep the sorted list, starting a new column each time col changes.
gotcha: The value tie-break only matters when two nodes land on the exact same (col, row); sorting by (col, row) alone leaves those two in arbitrary order.
complexity: O(n log n) time · O(n) space
```

## The trick

The tree shape is a distraction. Once every node is labelled with **where it sits on
a grid**, producing the answer is a pure **sorting** problem: sort by `(col, row,
value)` - that one composite key bakes in all three ordering rules - then group by
column in a single sweep. Two independent halves, neither of them clever.

```java
public List<List<Integer>> verticalTraversal(TreeNode root) {
    List<List<Integer>> sol = new ArrayList<>();
    if (root == null) return sol;

    List<int[]> nodes = new ArrayList<>();      // {col, row, val}
    dfs(root, 0, 0, nodes);                      // 1) recursive collect

    nodes.sort((a, b) -> {                        // 2) sort by (col, row, val)
        if (a[0] != b[0]) return Integer.compare(a[0], b[0]);
        if (a[1] != b[1]) return Integer.compare(a[1], b[1]);
        return Integer.compare(a[2], b[2]);
    });

    int prevCol = Integer.MIN_VALUE;              //    group column by column
    for (int[] node : nodes) {
        if (node[0] != prevCol) {
            sol.add(new ArrayList<>());
            prevCol = node[0];
        }
        sol.get(sol.size() - 1).add(node[2]);
    }
    return sol;
}

private void dfs(TreeNode root, int col, int row, List<int[]> nodes) {
    if (root == null) return;
    nodes.add(new int[]{col, row, root.val});
    dfs(root.left,  col - 1, row + 1, nodes);
    dfs(root.right, col + 1, row + 1, nodes);
}
```

## Edge cases & gotchas

- **Same `(col, row)` collisions** are the whole reason for the `value` tie-break -
  it's this problem's twist versus a plain vertical-order traversal that only sorts by
  column.
- **Sort key order matters:** `col` first, then `row`, then `value`. Swapping them
  scrambles reading order.
- **Empty tree** → empty result; handle `root == null` before the DFS.

Build a tree (**+** / **×**) and step through. Phase 1 (blue) is the DFS dropping each
node onto the **coordinate board**; phase 2 (purple) sweeps it column by column -
because every node already sits at its coordinate, the board is *already* in reading
order.

```viz
type: vertical_order
tree: [3, 9, 20, null, null, 15, 7]
```
