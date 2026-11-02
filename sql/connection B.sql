-- MODULE 22 - CONNECTION B
-- Open this in a SEPARATE MySQL Workbench server connection from A.
-- Execute ONE statement at a time, following STEP numbers across A and B.
-- Do not run this entire file as a script.
USE txn_lab;
SELECT CONNECTION_ID() AS connection_id,
       @@autocommit AS autocommit,
       @@transaction_isolation AS isolation_level;
-- Must have a different CONNECTION_ID() from A and autocommit = 1.

-- ============================================================
-- EXERCISE 2A: REPEATABLE READ
-- ============================================================
-- E2-RR STEP 01 (B): Reset after exercise 1; expect Alice=1000.
UPDATE accounts SET balance = 1000 WHERE id = 1;
-- NOW RUN E2-RR STEPS 02-04 in A (begin + read 1000).
-- E2-RR STEP 05 (B): Commit +50 in B (autocommit = 1).
UPDATE accounts SET balance = balance + 50 WHERE id = 1;
-- NOW RUN E2-RR STEPS 06-08 in A (1000, COMMIT, then 1050).

-- ============================================================
-- EXERCISE 2B: READ COMMITTED
-- ============================================================
-- E2-RC STEP 01 (B): Reset before second isolation experiment.
UPDATE accounts SET balance = 1000 WHERE id = 1;
-- NOW RUN E2-RC STEPS 02-04 in A (begin + read 1000).
-- E2-RC STEP 05 (B): A second +50 update (missing in original B.sql).
UPDATE accounts SET balance = balance + 50 WHERE id = 1;
-- NOW RUN E2-RC STEPS 06-09 in A (1050, COMMIT, 1050, restore RR).

-- ============================================================
-- EXERCISE 3A: LOST UPDATE
-- ============================================================
-- E3-L STEP 01 (B): Reset balance = 1000, outside any transaction.
UPDATE accounts SET balance = 1000 WHERE id = 1;
-- NOW RUN E3-L STEP 02 in A (START TRANSACTION).
-- E3-L STEP 03 (B): Begin B.
START TRANSACTION;
-- NOW RUN E3-L STEP 04 in A (read 1000).
-- E3-L STEP 05 (B): Read the same original value 1000.
SELECT balance FROM accounts WHERE id = 1;
-- NOW RUN E3-L STEPS 06-07 in A (write 900 and COMMIT).
-- E3-L STEP 08 (B): Write stale absolute value 900.
UPDATE accounts SET balance = 900 WHERE id = 1;
-- E3-L STEP 09 (B): Commit (may show 0 changed rows, no SQL error).
COMMIT;
-- NOW RUN E3-L STEP 10 in A: final 900, not 800.

-- ============================================================
-- EXERCISE 3B: FIX 1 - ATOMIC UPDATE
-- ============================================================
-- E3-AT STEP 01 (B): Reset Alice = 1000.
UPDATE accounts SET balance = 1000 WHERE id = 1;
-- NOW RUN E3-AT STEPS 02-03 in A (START + debit 100).
-- E3-AT STEP 04 (B): Begin B.
START TRANSACTION;
-- E3-AT STEP 05 (B): Try to debit; this waits for A's lock.
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
-- WHILE THIS WAITS, RUN E3-AT STEP 06 in A: COMMIT.
-- E3-AT STEP 07 (B): The waiting UPDATE completes (no extra SQL here).
-- E3-AT STEP 08 (B): Commit B's debit.
COMMIT;
-- NOW RUN E3-AT STEP 09 in A: final 800.

-- ============================================================
-- EXERCISE 3C: FIX 2 - SELECT ... FOR UPDATE
-- ============================================================
-- E3-F STEP 01 (B): Reset balance = 1000.
UPDATE accounts SET balance = 1000 WHERE id = 1;
-- NOW RUN E3-F STEPS 02-03 in A (lock/read Alice = 1000).
-- E3-F STEP 04 (B): Begin B.
START TRANSACTION;
-- E3-F STEP 05 (B): Try to lock and read Alice; this waits.
SELECT balance FROM accounts WHERE id = 1 FOR UPDATE;
-- WHILE THIS WAITS, RUN E3-F STEPS 06-07 in A (debit + COMMIT).
-- E3-F STEP 08 (B): Waiting SELECT returns 900 (no extra SQL here).
-- E3-F STEP 09 (B): Debit based on the current locked value.
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
-- E3-F STEP 10 (B): Commit.
COMMIT;
-- NOW RUN E3-F STEP 11 in A: final 800.

-- ============================================================
-- EXERCISE 4: BONUS DEADLOCK
-- ============================================================
-- E4 STEP 01 (B): Reset both accounts; ensure A and B have no open txns.
UPDATE accounts SET balance = 1000 WHERE id IN (1, 2);
-- NOW RUN E4 STEPS 02-03 in A (lock Alice).
-- E4 STEP 04 (B): Begin B.
START TRANSACTION;
-- E4 STEP 05 (B): Lock Bob (id=2).
UPDATE accounts SET balance = balance - 10 WHERE id = 2;
-- NOW RUN E4 STEP 06 in A (try id=2; A waits).
-- E4 STEP 07 (B): Try id=1; makes circular lock wait.
UPDATE accounts SET balance = balance - 10 WHERE id = 1;
-- Error 1213 may occur in A OR B; deadlock victim auto-rolls back.
-- Once both updates return or fail, ROLLBACK both sessions:
-- E4 STEP 08 in A, then E4 STEP 09 below.
-- E4 STEP 09 (B): Safe even if B was auto-rolled back.
ROLLBACK;
-- NOW RUN E4 STEP 10 in A: both accounts should be 1000.
