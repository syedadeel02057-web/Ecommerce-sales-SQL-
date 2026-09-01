# Ecommerce-sales-SQL-
Querying the sales data by SQL
# Task 3 – SQL for Data Analysis (SQLite)
Dataset rows: 10,999
Database: `ecommerce_shipping.db`
SQL script: `task3_sqlite.sql`

## How to use
1. Open `ecommerce_shipping.db` in DB Browser for SQLite.
2. Open the Execute SQL tab.
3. Open/paste `task3_sqlite.sql` if you want to reproduce the queries.
4. Run each section separately and capture the result grid as screenshots.
5. The database is already populated, so you can immediately inspect the results.

## What the task covers
SELECT, WHERE, ORDER BY, GROUP BY, INNER JOIN, LEFT JOIN, RIGHT JOIN (SQLite 3.39+), subqueries, SUM, AVG, views, indexes, and EXPLAIN QUERY PLAN.

## Important note
The original CSV has a column named `Reached.on.Time_Y.N`. In the SQLite table it is renamed to `reached_on_time` so queries are easier to write and read.
