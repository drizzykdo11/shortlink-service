# Short-link service

A URL shortener backed by MySQL, built step by step to learn
backend fundamentals (SQL, indexes, transactions, caching).

## Database
- `users` and `links` tables (links reference users via a foreign key)
- `schema.sql` rebuilds the database from scratch (development only: it drops tables)
- `seed.sql` inserts sample data
- `practice.sql` holds exercise queries

## Run
Open MySQL Workbench, run `schema.sql`, then `seed.sql`.
Requires MySQL 8.