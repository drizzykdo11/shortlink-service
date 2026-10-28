# Module 22 — Transaction Lab Notes

> Status: **Expected results only; actual Workbench outputs have not yet been supplied or independently verified.** Replace `_____` with observations from both connections before submitting.

## Environment

- Database: `txn_lab`
- Engine: `InnoDB`
- Connection A ID: `__34___`
- Connection B ID: `__36___` (**must be different**)
- A / B `@@autocommit`: `___1__` / `__1___` (expected `1` / `1`)
- A initial isolation: `_REPEATABLE-READ____` (often `REPEATABLE-READ`)
- Run the setup once. Execute individual A/B statements in the numbered order, not entire files.

## 1. Atomicity

| Checkpoint | Expected | Observed |
| --- | --- | --- |
| Before ROLLBACK, Alice | 900 | __900___ |
| After ROLLBACK, Alice | 1000 | __1000___ |
| After full transfer COMMIT, Alice | 900 | __900___ |
| After full transfer COMMIT, Bob | 1100 | __1100___ |

Explanation: A transaction lets the debit and credit succeed or be rolled back together. Without a transaction, autocommit could preserve Alice's debit even if the program crashes before Bob's credit.

## 2. Isolation levels

| Isolation | First SELECT | Second SELECT | After COMMIT | Actual observations |
| --- | ---: | ---: | ---: | --- |
| REPEATABLE READ | 1000 | 1000 | 1050 | _1000____ / _1000____ / _1050_ _ |
| READ COMMITTED | 1000 | 1050 | 1050 | _1000____ / __1050___ / __1050___ |

**Answer 1 — In my own words (reference draft):**

Under REPEATABLE READ, both SELECT statements in the same transaction returned 1000, even after another transaction committed a balance of 1050. Under READ COMMITTED, the second SELECT returned 1050 because it used a newer snapshot, allowing a non-repeatable read.

## 3. Lost update and solutions

| Checkpoint | Expected | Observed |
| --- | --- | --- |
| Both sessions' initial SELECT | 1000 / 1000 | _1000____ / __1000___ |
| Lost-update final balance | 900 (incorrect) | __900___ |
| Correct balance after two withdrawals | 800 | __800___ |
| Atomic `balance = balance - 100` final | 800 | __800___ |
| Session B `FOR UPDATE` waited? | Yes | ___Yes__ |
| Session B `FOR UPDATE` returned | 900 | __900___ |
| `FOR UPDATE` final balance | 800 | __800___ |

**Answer 2 — In my own words (reference draft):**

`SET balance = balance - 100` avoids lost updates because InnoDB coordinates concurrent modifications using row locks and applies each subtraction to the current value. I would use `SELECT ... FOR UPDATE` when the application must read data, validate complex business conditions, and then update the records safely within a transaction.

## 4. Deadlock (bonus)

- Session reporting Error 1213: `__B___` (A or B; not predetermined)
- Full error message: `_Deadlock found when trying to get to lock____`
- Did the other session complete after the victim rolled back? `_No____`
- After `ROLLBACK` in A and B, Alice / Bob balances: `___1000__` / `__1000___` (expected `1000` / `1000`)

**Answer 3 — In my own words (reference draft):**

A deadlock occurs when two transactions hold locks that the other transaction needs, causing a circular wait. Keeping transactions short and acquiring locks in a consistent order can reduce the risk of deadlocks.

## Troubleshooting / lessons

- `Error 1213`: a deadlock was detected; InnoDB rolls back the **entire victim transaction**. The application should retry that complete transaction.
- `Error 1205`: lock wait timeout; by default InnoDB rolls back the **failed statement only**. Explicitly end the remaining transaction in this lab.
- Avoid using two SQL editor tabs that share one Workbench server connection; verify with `SELECT CONNECTION_ID()`.
- Run `ROLLBACK` in both sessions after the deadlock exercise, once blocked statements have returned.

## Git commit

From your local `shortlink-service` directory, after checking and filling the actual results:

```bash
git status
git add transactions.sql "connection A.sql" "connection B.sql" transactions-notes.md
git commit -m "Complete Module 22 transaction exercises"
git push
```

`git push` requires a configured remote and appropriate authentication. If the branch has no upstream, use `git push -u origin <your-branch-name>` after verifying the remote with `git remote -v`.
