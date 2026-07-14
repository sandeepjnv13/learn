---
title: 236. Lowest Common Ancestor
order: 1
---

# 236. Lowest Common Ancestor of a Binary Tree

Given the `root` of a binary tree and two nodes `p` and `q`, return their **lowest
common ancestor** - the deepest node with both `p` and `q` in its subtree (a node can
be an ancestor of itself).

```viz
type: approach
technique: Post-order "answers bubble up"
pattern: post-order
idea: Recurse to the leaves and let each node combine what its two children returned - the first node that sees a target on both sides is the answer.
bullets:
  - Base case - node is null, or it is p or q → return the node itself.
  - Recurse left and right, then combine: both sides non-null → this node is the LCA.
  - Only one side non-null → forward it up (a found target, or an already-decided LCA sailing to the root).
gotcha: Because a node can be its own ancestor, the base case returns on `node == p || node == q` before recursing - so if q sits under p, the answer is p and the search short-circuits.
complexity: O(n) time · O(h) stack space
```

## The trick

This is a **post-order** recursion: nothing happens on the way *down*, all the logic
runs on the way *up*. Every node asks one question - *"did a target turn up on my
left, my right, both, or neither?"* The **first** node that sees *both* sides succeed
is the split point, so it is the LCA. Above it, every ancestor sees exactly one
non-`null` side and just forwards it, so the answer rides untouched up to the root.

```java
TreeNode lowestCommonAncestor(TreeNode root, TreeNode p, TreeNode q) {
    if (root == null || root == p || root == q) return root;

    TreeNode leftLca  = lowestCommonAncestor(root.left,  p, q);
    TreeNode rightLca = lowestCommonAncestor(root.right, p, q);

    if (leftLca != null && rightLca != null) return root;   // targets split → LCA
    return (leftLca != null) ? leftLca : rightLca;          // forward the one that hit
}
```

## Edge cases & gotchas

- **A node is its own ancestor.** If `q` lives under `p`, the answer is `p` - the base
  case fires at `p` and short-circuits the rest of that subtree.
- **Return the node, not a boolean.** Passing the actual node up is what lets an
  already-decided LCA sail to the root unchanged.
- **Assumes both `p` and `q` exist** in the tree; if that's not guaranteed you need a
  second pass (or found-count) to confirm.

Build a tree in the visualizer (**+** adds a child, **×** prunes), switch to **Set p**
/ **Set q** and tap two nodes, then step through. Watch the **call stack**: the answer
becomes obvious the moment one frame sees both `leftLca` and `rightLca` resolve.

```viz
type: lca
tree: [3, 5, 1, 6, 2, 0, 8, null, null, 7, 4]
p: 5
q: 1
```
