---
title: Vertical Order Traversal
order: 2
---

# Vertical Order Traversal of a Binary Tree

> **LeetCode 987.** Given the `root` of a binary tree, return its **vertical
> order traversal**. Assign each node a column (`x`) and row (`y`); the root is
> `(0, 0)`, a left child is `col − 1`, a right child is `col + 1`, and every
> step down increases the row by 1. Report the values **column by column**, left
> to right; within a column, top to bottom; and when two nodes land on the exact
> same `(col, row)`, order them by **value**.

## The idea — coordinates, then sort, then group

The trick is to stop thinking about the tree shape and start thinking about a
**grid of coordinates**. Two independent halves do the work:

1. **Recursive DFS (collect).** Walk the whole tree once, carrying a `(col, row)`
   as you go. At every node, record the tuple `(col, row, value)`. Left recurses
   with `col − 1`, right with `col + 1`, and both go to `row + 1`. Nothing clever
   happens here — it just stamps every node with where it sits on the board.

2. **Non-recursive sort + group.** Now the whole answer is a *sorting* problem.
   Sort the tuples by `(col, row, value)` — that single key encodes all three
   tie-break rules at once. Then sweep the sorted list, starting a **new column**
   every time `col` changes and appending the value otherwise.

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

With `n` nodes the DFS is **O(n)**; the sort dominates at **O(n log n)** time and
**O(n)** space.

## Watch it run

Build your own tree — press **+** on an empty slot to add a child, **×** to
prune — then hit **Visualize traversal** and step through.

Phase 1 (blue) is the **recursive** DFS: watch the call stack grow and each node
drop onto the **coordinate board** at its `(col, row)`. Phase 2 (purple) is the
**non-recursive** pass: because every node already sits at its coordinate, the
board is *already* in reading order — the sweep just walks it column by column,
lighting up the active column band as it fills each list.

```viz
type: vertical_order
tree: [3, 9, 20, null, null, 15, 7]
```

Notice column `0` ends up with **two** nodes (`3` at row 0 and `15` at row 2) —
different rows, same column, so they stack top-to-bottom. To see the **value**
tie-break kick in, rebuild the tree as `[1, 2, 3, 4, 6, 5, 7]`: now `5` and `6`
share the exact same `(col, row) = (0, 2)`, and the smaller value `5` comes
first.
