---
title: Lowest Common Ancestor
order: 1
---

# Lowest Common Ancestor of a Binary Tree

> **LeetCode 236.** Given the `root` of a binary tree and two nodes `p` and `q`,
> return their **lowest common ancestor** — the deepest node that has both `p`
> and `q` somewhere in its subtree (a node can be an ancestor of itself).

## The idea — let the answer bubble up

This is a **post-order** recursion. Nothing interesting happens on the way *down*;
all the logic runs on the way back *up*, as each call combines what its two
children returned.

At every node we ask one question: *"did a target turn up on my left, my right,
both, or neither?"*

- **Base case.** If the node is `null`, or it *is* `p` or `q`, return the node
  itself — "I found a target here."
- **Recurse** into the left and right children.
- **Combine:**
  - If **both** sides came back non-`null`, then `p` and `q` were found in
    *different* subtrees, so **this node is their lowest common ancestor** — return it.
  - If only **one** side came back non-`null`, pass that result straight up
    (either a found target, or an already-decided LCA sailing up to the root).
  - If **neither** did, return `null`.

The first node that sees *both* sides succeed is the answer; above it, every
ancestor sees exactly one non-`null` side and just forwards it, so the LCA rides
untouched up to the root.

```java
TreeNode lowestCommonAncestor(TreeNode root, TreeNode p, TreeNode q) {
    if (root == null || root == p || root == q) return root;

    TreeNode leftLca  = lowestCommonAncestor(root.left,  p, q);
    TreeNode rightLca = lowestCommonAncestor(root.right, p, q);

    if (leftLca != null && rightLca != null) return root;   // targets split → LCA
    return (leftLca != null) ? leftLca : rightLca;          // forward the one that hit
}
```

Every node is visited once, so this is **O(n)** time and **O(h)** stack space for
a tree of height `h`.

## Watch it run

Build your own tree right in the visualizer — press **+** on an empty slot to add
a child, **×** to prune, then switch to **Set p** / **Set q** and tap two nodes.
Hit **Visualize LCA** and step through.

Keep an eye on the **call stack** on the right: it grows as the recursion
descends, and the answer becomes obvious the moment a frame sees *both*
`leftLca` and `rightLca` resolve to non-`null` — that frame's node is the LCA,
and it rides back up the stack unchanged.

```viz
type: lca
tree: [3, 5, 1, 6, 2, 0, 8, null, null, 7, 4]
p: 5
q: 1
```

Try picking `p = 5` and `q = 4`: the answer is `5` itself, because a node is
allowed to be its own ancestor — watch the base case fire and short-circuit the
left subtree.
