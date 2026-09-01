-- TASK 3: SQL FOR DATA ANALYSIS - SQLite
-- Dataset: Ecommerce Shipping Data.csv
-- Database table: shipments
-- Original column Reached.on.Time_Y.N is stored as reached_on_time for easier SQL use.

PRAGMA foreign_keys = ON;

-- 1) Create the main table
DROP TABLE IF EXISTS shipments;
CREATE TABLE shipments (
    shipment_id INTEGER PRIMARY KEY,
    warehouse_block TEXT NOT NULL,
    mode_of_shipment TEXT NOT NULL,
    customer_care_calls INTEGER,
    customer_rating INTEGER,
    cost_of_product REAL,
    prior_purchases INTEGER,
    product_importance TEXT,
    gender TEXT,
    discount_offered REAL,
    weight_in_gms REAL,
    reached_on_time INTEGER CHECK (reached_on_time IN (0,1))
);

-- Import the CSV using the SQLite command line after creating the table:
-- .mode csv
-- .import --skip 1 "Ecommerce Shipping Data.csv" shipments
-- NOTE: The provided CSV header has different column names. The easiest reliable method
-- is to use the supplied ecommerce_shipping.db, already loaded and validated, or import
-- into a staging table and transform the columns.

-- 2) SELECT
SELECT shipment_id, warehouse_block, mode_of_shipment, cost_of_product, reached_on_time
FROM shipments
ORDER BY shipment_id
LIMIT 10;

-- 3) WHERE + ORDER BY
SELECT shipment_id, mode_of_shipment, customer_rating, discount_offered
FROM shipments
WHERE customer_rating >= 4 AND discount_offered >= 20
ORDER BY discount_offered DESC, customer_rating DESC
LIMIT 10;

-- 4) GROUP BY
SELECT product_importance,
       COUNT(*) AS shipment_count,
       ROUND(AVG(cost_of_product),2) AS avg_product_cost
FROM shipments
GROUP BY product_importance
ORDER BY shipment_count DESC;

-- 5) Aggregate functions: SUM + AVG
SELECT ROUND(SUM(cost_of_product),2) AS total_product_value,
       ROUND(AVG(cost_of_product),2) AS avg_product_cost,
       ROUND(AVG(discount_offered),2) AS avg_discount
FROM shipments;

-- 6) Helper dimension table for JOIN examples
CREATE TABLE IF NOT EXISTS mode_info (
    mode_of_shipment TEXT PRIMARY KEY,
    transport_group TEXT,
    description TEXT
);
INSERT OR IGNORE INTO mode_info VALUES
('Flight','Air','Fastest transport mode'),
('Ship','Sea','High-volume transport mode'),
('Road','Land','Road transport mode');

-- 7) INNER JOIN
SELECT s.shipment_id, s.mode_of_shipment, m.transport_group, s.reached_on_time
FROM shipments AS s
INNER JOIN mode_info AS m
    ON s.mode_of_shipment = m.mode_of_shipment
LIMIT 10;

-- 8) LEFT JOIN
CREATE TABLE IF NOT EXISTS warehouse_info (
    warehouse_block TEXT PRIMARY KEY,
    warehouse_type TEXT,
    region TEXT
);
INSERT OR IGNORE INTO warehouse_info VALUES
('A','Standard','Zone 1'),('B','Standard','Zone 1'),('C','Standard','Zone 2'),
('D','Standard','Zone 2'),('F','Standard','Zone 3'),('E','Standard','Zone 3');

SELECT w.region, w.warehouse_block, COUNT(s.shipment_id) AS shipment_count
FROM warehouse_info AS w
LEFT JOIN shipments AS s
    ON w.warehouse_block = s.warehouse_block
GROUP BY w.region, w.warehouse_block
ORDER BY w.warehouse_block;

-- 9) RIGHT JOIN (SQLite 3.39+). If unavailable, reverse the LEFT JOIN tables.
SELECT w.warehouse_block, COUNT(s.shipment_id) AS shipment_count
FROM shipments AS s
RIGHT JOIN warehouse_info AS w
    ON s.warehouse_block = w.warehouse_block
GROUP BY w.warehouse_block
ORDER BY w.warehouse_block;

-- 10) Subquery: rows above overall average product cost
SELECT shipment_id, cost_of_product, product_importance
FROM shipments
WHERE cost_of_product > (SELECT AVG(cost_of_product) FROM shipments)
ORDER BY cost_of_product DESC
LIMIT 10;

-- 11) Subquery: mode(s) with the best on-time rate
SELECT mode_of_shipment,
       ROUND(100.0*AVG(reached_on_time),2) AS on_time_rate_pct
FROM shipments
GROUP BY mode_of_shipment
HAVING AVG(reached_on_time) = (
    SELECT MAX(rate)
    FROM (SELECT AVG(reached_on_time) AS rate
          FROM shipments
          GROUP BY mode_of_shipment)
);

-- 12) Create views for reusable analysis
DROP VIEW IF EXISTS v_shipping_performance;
CREATE VIEW v_shipping_performance AS
SELECT shipment_id, warehouse_block, mode_of_shipment, product_importance,
       cost_of_product, discount_offered, weight_in_gms, customer_rating,
       reached_on_time,
       CASE WHEN reached_on_time = 1 THEN 'On Time' ELSE 'Late' END AS delivery_status
FROM shipments;

DROP VIEW IF EXISTS v_mode_performance;
CREATE VIEW v_mode_performance AS
SELECT mode_of_shipment,
       COUNT(*) AS total_shipments,
       SUM(reached_on_time) AS on_time_shipments,
       ROUND(100.0*AVG(reached_on_time),2) AS on_time_rate_pct,
       ROUND(AVG(cost_of_product),2) AS avg_product_cost,
       ROUND(AVG(discount_offered),2) AS avg_discount,
       ROUND(AVG(weight_in_gms),2) AS avg_weight_gms
FROM shipments
GROUP BY mode_of_shipment;

-- Query the views
SELECT * FROM v_mode_performance ORDER BY on_time_rate_pct DESC;
SELECT delivery_status, COUNT(*) AS shipments
FROM v_shipping_performance
GROUP BY delivery_status;

-- 13) Indexes for common filters/grouping
CREATE INDEX IF NOT EXISTS idx_shipments_mode ON shipments(mode_of_shipment);
CREATE INDEX IF NOT EXISTS idx_shipments_importance ON shipments(product_importance);
CREATE INDEX IF NOT EXISTS idx_shipments_reached ON shipments(reached_on_time);
CREATE INDEX IF NOT EXISTS idx_shipments_warehouse ON shipments(warehouse_block);
CREATE INDEX IF NOT EXISTS idx_shipments_mode_reached ON shipments(mode_of_shipment, reached_on_time);

-- Verify an index is used for a common query
EXPLAIN QUERY PLAN
SELECT *
FROM shipments
WHERE mode_of_shipment = 'Ship' AND reached_on_time = 1;

-- 14) Additional analysis
SELECT warehouse_block,
       COUNT(*) AS total_shipments,
       SUM(reached_on_time) AS on_time_shipments,
       ROUND(100.0*AVG(reached_on_time),2) AS on_time_rate_pct
FROM shipments
GROUP BY warehouse_block
ORDER BY on_time_rate_pct DESC;

SELECT product_importance,
       COUNT(*) AS total_shipments,
       ROUND(100.0*AVG(reached_on_time),2) AS on_time_rate_pct,
       ROUND(AVG(discount_offered),2) AS avg_discount
FROM shipments
GROUP BY product_importance
ORDER BY on_time_rate_pct DESC;
