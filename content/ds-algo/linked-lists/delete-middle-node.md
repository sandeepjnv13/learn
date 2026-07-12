---
title: Delete the Middle Node
order: 1
---

# Delete the Middle Node of a Linked List

> **LeetCode 2095.** Given the `head` of a singly-linked list, delete the
> **middle** node and return the head of the modified list. The middle node of a
> list of size `n` is the `⌊n / 2⌋`-th node (0-indexed).

## The idea — slow, fast, and a trailing `prev`

We find the middle in a **single pass** with two pointers:

- **`fast`** moves **two** nodes each iteration; **`slow`** moves **one**. By the
  time `fast` walks off the end, `slow` is sitting exactly on the middle node.
- But to *delete* a node in a singly-linked list you need the node **before** it.
  So we keep a **`prev`** pointer, initialised to `null`, that trails one step
  behind `slow`. When the walk stops, `prev.next = slow.next` splices the middle
  node out of the chain.

### Short lists

If the list has **fewer than two nodes**, the middle *is* the last (or only)
node — deleting it leaves an empty list, so we return `null` (and if the list was
already empty, there is nothing to do). Both cases are handled up front before the
pointer walk begins.

```
slow ← head,  fast ← head,  prev ← null
while fast ≠ null and fast.next ≠ null:
    prev ← slow
    slow ← slow.next
    fast ← fast.next.next
prev.next ← slow.next        # unlink the middle
return head
```

Everything is one pass over the list, so this is **O(n)** time and **O(1)** extra
space.

## Watch it run

Step through the two pointers below. `fast` sprints ahead, `slow` lands on the
middle, and `prev` performs the unlink — watch the middle node pop out of the
chain while a healed arrow reconnects its neighbours.

```viz
type: delete-middle-node
list: [1, 2, 3, 4, 5, 6]
```

Try an **odd** length like `[10, 20, 30, 40, 50]` (middle is `30`), an **even**
length, or a **single node** to see the list empty out.
