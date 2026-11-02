-- MODULE 22 - CONNECTION A
-- Open this in an INDEPENDENT MySQL Workbench server connection.
-- Execute ONE statement at a time, following STEP numbers across A and B.
-- Do not run this entire file as a script.
USE txn_lab;
SELECT CONNECTION_ID() AS connection_id,
       @@autocommit AS autocommit,
       @@transaction_isolation AS isolation_level;
-- Check that CONNECTION_ID() differs from connection B, and autocommit = 1.

-- ============================================================
-- EXERCISE 1: ATOMICITY (A only)
-- ============================================================
-- E1 STEP 01 (A): Start the first transaction.
START TRANSACTION;
-- E1 STEP 02 (A): Subtract 100 from Alice.
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
-- E1 STEP 03 (A): Expect Alice = 900; Bob = 1000 (not committed).
SELECT * FROM accounts;
-- E1 STEP 04 (A): Undo the uncommitted subtraction.
ROLLBACK;
-- E1 STEP 05 (A): Expect Alice = 1000; Bob = 1000.
SELECT * FROM accounts;
-- E1 STEP 06 (A): Start a complete two-account transfer.
START TRANSACTION;
-- E1 STEP 07 (A): Debit Alice.
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
-- E1 STEP 08 (A): Credit Bob (this step was missing from the original).
UPDATE accounts SET balance = balance + 100 WHERE id = 2;
-- E1 STEP 09 (A): Commit both changes together.
COMMIT;
-- E1 STEP 10 (A): Expect Alice = 900; Bob = 1100.
SELECT * FROM accounts;

-- ============================================================
-- EXERCISE 2A: REPEATABLE READ
-- First run E2-RR STEP 01 in connection B (reset Alice).
-- ============================================================
-- E2-RR STEP 02 (A): Select the repeatable-read isolation level.
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
-- E2-RR STEP 03 (A): Begin a transaction.
START TRANSACTION;
-- E2-RR STEP 04 (A): First consistent read; expect 1000.
SELECT balance FROM accounts WHERE id = 1;
-- NOW RUN E2-RR STEP 05 in B: balance +50, autocommitted.
-- E2-RR STEP 06 (A): Same snapshot; expect 1000 again.
SELECT balance FROM accounts WHERE id = 1;
-- E2-RR STEP 07 (A): Finish this transaction.
COMMIT;
-- E2-RR STEP 08 (A): New statement, fresh transaction; expect 1050.
SELECT balance FROM accounts WHERE id = 1;

-- ============================================================
-- EXERCISE 2B: READ COMMITTED
-- First run E2-RC STEP 01 in connection B (reset Alice).
-- ============================================================
-- E2-RC STEP 02 (A): Select read-committed isolation.
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- E2-RC STEP 03 (A): Begin a transaction.
START TRANSACTION;
-- E2-RC STEP 04 (A): First consistent read; expect 1000.
SELECT balance FROM accounts WHERE id = 1;
-- NOW RUN E2-RC STEP 05 in B: balance +50, autocommitted.
-- E2-RC STEP 06 (A): New read view; expect 1050.
SELECT balance FROM accounts WHERE id = 1;
-- E2-RC STEP 07 (A): Finish transaction.
COMMIT;
-- E2-RC STEP 08 (A): Expect 1050.
SELECT balance FROM accounts WHERE id = 1;
-- E2-RC STEP 09 (A): Restore repeatable-read for later exercises.
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- ============================================================
-- EXERCISE 3A: LOST UPDATE
-- First run E3-L STEP 01 in B (reset Alice = 1000).
-- ============================================================
-- E3-L STEP 02 (A): Begin transaction A.
START TRANSACTION;
-- NOW RUN E3-L STEP 03 in B: START TRANSACTION.
-- E3-L STEP 04 (A): Read 1000; application plans to write 900.
SELECT balance FROM accounts WHERE id = 1;
-- NOW RUN E3-L STEP 05 in B: read 1000 as well.
-- E3-L STEP 06 (A): Write absolute value 900 based on old read.
UPDATE accounts SET balance = 900 WHERE id = 1;
-- E3-L STEP 07 (A): Commit.
COMMIT;
-- NOW RUN E3-L STEPS 08-09 in B: write 900 and commit.
-- E3-L STEP 10 (A): Expect final 900 (WRONG: two withdrawals should yield 800).
SELECT balance FROM accounts WHERE id = 1;

-- ============================================================
-- EXERCISE 3B: FIX 1 - ATOMIC UPDATE
-- First run E3-AT STEP 01 in B (reset Alice = 1000).
-- ============================================================
-- E3-AT STEP 02 (A): Begin A.
START TRANSACTION;
-- E3-AT STEP 03 (A): Debit using a relative, atomic update.
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
-- NOW RUN E3-AT STEPS 04-05 in B: start and UPDATE; B should WAIT.
-- E3-AT STEP 06 (A): Commit and release the lock; B's update can finish.
COMMIT;
-- NOW RUN E3-AT STEP 08 in B: COMMIT after its UPDATE completes.
-- E3-AT STEP 09 (A): Expect 800.
SELECT balance FROM accounts WHERE id = 1;

-- ============================================================
-- EXERCISE 3C: FIX 2 - SELECT ... FOR UPDATE
-- First run E3-F STEP 01 in B (reset Alice = 1000).
-- ============================================================
-- E3-F STEP 02 (A): Begin A.
START TRANSACTION;
-- E3-F STEP 03 (A): Lock and read Alice; expect 1000.
SELECT balance FROM accounts WHERE id = 1 FOR UPDATE;
-- NOW RUN E3-F STEPS 04-05 in B: B's FOR UPDATE should WAIT.
-- E3-F STEP 06 (A): Debit Alice while holding the lock.
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
-- E3-F STEP 07 (A): Release lock; B's SELECT should return 900.
COMMIT;
-- NOW RUN E3-F STEPS 09-10 in B: debit and commit.
-- E3-F STEP 11 (A): Expect 800.
SELECT balance FROM accounts WHERE id = 1;

-- ============================================================
-- EXERCISE 4: BONUS DEADLOCK
-- First run E4 STEP 01 in B (reset BOTH accounts = 1000).
-- ============================================================
-- E4 STEP 02 (A): Start A.
START TRANSACTION;
-- E4 STEP 03 (A): Lock Alice (id=1).
UPDATE accounts SET balance = balance - 10 WHERE id = 1;
-- NOW RUN E4 STEPS 04-05 in B: lock Bob (id=2).
-- E4 STEP 06 (A): Try to lock Bob; this statement should WAIT.
UPDATE accounts SET balance = balance - 10 WHERE id = 2;
-- WHILE A WAITS, RUN E4 STEP 07 in B: try to lock Alice.
-- A or B should receive Error 1213; the victim is auto-rolled back.
-- After BOTH waiting SQL statements finish, run E4 STEP 08 in A
-- and E4 STEP 09 in B. ROLLBACK both connections to clean up.
-- E4 STEP 08 (A): Safe even if A was already rolled back.
ROLLBACK;
-- NOW RUN E4 STEP 09 in B: ROLLBACK.
-- E4 STEP 10 (A): Both accounts should remain at 1000.
SELECT * FROM accounts;
