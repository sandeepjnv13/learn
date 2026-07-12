---
title: Joins
order: 1
---

# SQL Joins

A join combines rows from two tables based on a related column.

| Join | Keeps |
|------|-------|
| INNER | rows matching in **both** tables |
| LEFT  | all left rows + matches |
| RIGHT | all right rows + matches |
| FULL  | all rows from both |

```sql
SELECT u.name, o.total
FROM users u
INNER JOIN orders o ON o.user_id = u.id;
```

> This page is pure markdown — no visualizer. Content-only pages are totally
> fine; add a `viz` block whenever a topic benefits from one.
