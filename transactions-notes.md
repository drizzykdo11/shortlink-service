# Module 22 — MySQL Transactions Lab

## Environment

- **Database:** `txn_lab`
- **Database server:** MySQL 8.0.46, InnoDB
- **Client:** MySQL Workbench
- **Independent sessions:** Connection A (ID 34) and Connection B (ID 36)
- **Initial account balances:** Alice = 1000; Bob = 1000
- **Isolation levels tested:** `REPEATABLE READ` and `READ COMMITTED`

The experiments used two independent MySQL connections. Statements in `connection A.sql` and `connection B.sql` were executed in their labeled interleaved order.

## 1. Atomicity: COMMIT and ROLLBACK

The test first deducted 100 from Alice inside an explicit transaction and then issued `ROLLBACK`. The debit was not retained. A separate transfer used two updates—debiting Alice and crediting Bob—followed by `COMMIT`, so both changes could be committed together.

With both accounts starting at 1000, a rolled-back debit leaves Alice at 1000. A successfully committed transfer of 100 leaves Alice at 900 and Bob at 1100. Without an explicit transaction, autocommit could preserve the debit even if the application failed before the credit.

## 2. Isolation Levels

Recorded balance readings for Alice:

| Isolation level | First SELECT | Second SELECT (after B commits +50) | SELECT after A commits |
| --- | ---: | ---: | ---: |
| `REPEATABLE READ` | 1000 | 1000 | 1050 |
| `READ COMMITTED` | 1000 | 1050 | 1050 |

**Explanation.** Under `REPEATABLE READ`, A's ordinary consistent reads reused the same snapshot, so B's committed change was not visible until A finished its transaction. Under `READ COMMITTED`, A's second `SELECT` obtained a newer snapshot and saw B's committed update. This demonstrates that `READ COMMITTED` permits a **non-repeatable read**.

## 3. Lost Update and Two Fixes

| Test | Recorded outcome |
| --- | --- |
| Two sessions read 1000 and each write the absolute value 900 | Final balance = **900**; one withdrawal was lost |
| Both sessions use `SET balance = balance - 100` | Final balance = **800** |
| B executes `SELECT ... FOR UPDATE` while A holds the lock | **B waited** |
| B's locking read continues after A commits its deduction | B reads **900** |
| B then deducts 100 and commits | Final balance = **800** |

**Explanation.** Writing a value calculated from an earlier application read can overwrite the effect of another request. A relative update such as `SET balance = balance - 100` lets InnoDB coordinate concurrent changes and calculate from the current record value. `SELECT ... FOR UPDATE` is useful when an application must first read and validate data, then make a decision and update it within the same transaction.

## 4. Deadlock

The two connections acquired locks in opposite orders:

- **A** updated Alice (`id = 1`) and then tried to update Bob (`id = 2`).
- **B** updated Bob (`id = 2`) and then tried to update Alice (`id = 1`).

This created a circular wait. **Connection B was reported as the deadlock victim**, with MySQL error 1213:

```text
Deadlock found when trying to get lock; try restarting transaction
```

**Observed:** After InnoDB rolled back connection B, B's lock on Bob's row (`id = 2`) was released. **Connection A's previously blocked `UPDATE ... WHERE id = 2` completed successfully.** This completed the SQL statement, but did not automatically end A's transaction; A still needed an explicit `COMMIT` or `ROLLBACK`. To discard the test changes, `ROLLBACK` should be issued for any surviving open transaction. Running `ROLLBACK` in both sessions after their statements finish is a safe lab cleanup procedure.

**Explanation.** A deadlock occurs when transactions hold locks needed by one another and form a cycle of waiting. Keeping transactions short and acquiring records in a consistent order reduces the probability of deadlocks. Applications must still be prepared to retry a transaction rolled back due to error 1213.

## 5. Backend Application Takeaways

### Click counters

A Django view that loads `link.click_count`, increments it in Python, and saves it can lose increments when many requests read the same old value. A database-side update avoids this read-modify-write race:

```python
from django.db.models import F

Link.objects.filter(pk=link_id).update(click_count=F('click_count') + 1)
```

### Flash-sale inventory

Stock can be decremented only when available using one conditional statement, without an explicit `SELECT ... FOR UPDATE`:

```python
updated = Product.objects.filter(pk=product_id, stock__gt=0).update(
    stock=F('stock') - 1
)
```

`updated == 1` indicates the stock decrement succeeded; `updated == 0` means no product matched the conditions (for example, the item was out of stock or did not exist). If order creation and inventory changes must succeed together, they also need an appropriate transaction.

## Conclusion

This lab demonstrated rollback and commit behavior, the snapshot differences between `REPEATABLE READ` and `READ COMMITTED`, the lost-update problem, and two safe ways to coordinate concurrent modifications. It also reproduced a deadlock: B was rolled back as the victim, and A's blocked update completed after B released its locks. The experiment illustrates why lock acquisition order and explicit transaction cleanup matter.
