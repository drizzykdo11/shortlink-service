-- Module 22: Transactions - one-time lab setup.
-- WARNING: Running DROP TABLE removes all existing txn_lab.accounts data.
-- Run this file ONCE before the experiments, with no other lab transactions open.
-- Do NOT rerun this file in the middle of exercises.

CREATE DATABASE IF NOT EXISTS txn_lab;
USE txn_lab;
DROP TABLE IF EXISTS accounts;

CREATE TABLE accounts (
    id INT PRIMARY KEY,
    owner VARCHAR(50) NOT NULL,
    balance INT NOT NULL
) ENGINE = InnoDB;

INSERT INTO accounts (id, owner, balance)
VALUES (1, 'alice', 1000), (2, 'bob', 1000);

SELECT * FROM accounts;
-- Expected initial rows: (1, alice, 1000), (2, bob, 1000).