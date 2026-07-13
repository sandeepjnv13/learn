---
title: 2095. Delete the Middle Node
order: 1
---

# 2095. Delete the Middle Node of a Linked List

Delete the **middle** node of a singly-linked list and return the head. The middle of
a list of size `n` is the `⌊n / 2⌋`-th node (0-indexed).

```viz
type: approach
technique: Slow / fast pointers with a trailing prev
pattern: fast-slow
idea: Advance fast two nodes for every one that slow takes; when fast runs off the end, slow sits exactly on the middle.
bullets:
  - slow += 1, fast += 2 each iteration → slow lands on the middle in one pass.
  - Keep prev trailing one step behind slow (deleting in a singly-linked list needs the node before the target).
  - Unlink with prev.next = slow.next.
gotcha: Lists shorter than two nodes have no "previous" — handle head == null and a single node up front (deleting the only node returns null) before the walk.
complexity: O(n) time · O(1) space
```

## The trick

Two pointers find the middle in a **single pass**: `fast` moves twice as fast as
`slow`, so when `fast` falls off the end, `slow` has covered exactly half the list and
is parked on the middle node. But a singly-linked list can only be spliced from the
node **before** the target, so a `prev` pointer trails one step behind `slow`; when the
walk stops, `prev.next = slow.next` drops the middle out of the chain.

```text
slow ← head,  fast ← head,  prev ← null
while fast ≠ null and fast.next ≠ null:
    prev ← slow
    slow ← slow.next
    fast ← fast.next.next
prev.next ← slow.next        # unlink the middle
return head
```

## Edge cases & gotchas

- **0 or 1 nodes:** there's no `prev` to splice from — return `null` (deleting the
  only node empties the list) before starting the walk.
- **Loop guard:** `fast != null && fast.next != null` — checking only one lets
  `fast.next.next` dereference null on even-length lists.
- **Odd vs even length** land the middle on different nodes; the `⌊n/2⌋` definition
  makes both fall out of the same walk.

Step through below: `fast` sprints ahead, `slow` lands on the middle, and `prev`
performs the unlink while a healed arrow reconnects the neighbours.

```viz
type: delete-middle-node
list: [1, 2, 3, 4, 5, 6]
```
