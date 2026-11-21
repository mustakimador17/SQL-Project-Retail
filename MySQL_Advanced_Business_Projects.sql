-- =====================================================================
-- Ador Retail Analytics :: advanced business projects (MySQL 8.0+)
-- Read-only analysis queries. Revenue is always net item revenue of Completed orders
-- (quantity x unit_price x (1 - discount_pct/100)), excluding shipping, unless a
-- project defines otherwise. As-of date for time-based logic: 2025-12-31.
-- Results are DESCRIPTIVE; none of these queries proves causation.
-- =====================================================================
USE ador_retail;

-- ====================================================================
-- PROJECT 1: Retail Sales Performance
-- Business problem: Leadership wants to know how sales have trended, which products and categories drive revenue, and how regions compare.
-- Stakeholder: Head of Sales and the Retail Operations Director.
-- Metric definitions: Net revenue = SUM(quantity x unit_price x (1 - discount_pct/100)) for Completed orders, excluding shipping. Order volume = distinct Completed orders. AOV = net revenue / order volume. Returned and Cancelled orders are excluded from revenue by definition (partial returns on Completed orders are NOT deducted; see Project 5).
-- ====================================================================
-- Query 1.1: Monthly revenue, orders and AOV
WITH order_revenue AS (
    SELECT o.order_id, DATE_FORMAT(o.order_date, '%Y-%m-01') AS month_start,
           SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)) AS revenue
    FROM orders AS o
    JOIN order_items AS oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY o.order_id, DATE_FORMAT(o.order_date, '%Y-%m-01')
)
SELECT month_start, COUNT(*) AS orders, ROUND(SUM(revenue), 2) AS net_revenue, ROUND(AVG(revenue), 2) AS aov
FROM order_revenue
GROUP BY month_start
ORDER BY month_start;

-- Query 1.2: Top 5 products overall
SELECT p.product_name, c.category_name,
       SUM(oi.quantity) AS units,
       ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)), 2) AS net_revenue
FROM orders AS o
JOIN order_items AS oi ON oi.order_id = o.order_id
JOIN products AS p ON p.product_id = oi.product_id
JOIN categories AS c ON c.category_id = p.category_id
WHERE o.order_status = 'Completed'
GROUP BY p.product_id, p.product_name, c.category_name
ORDER BY net_revenue DESC, p.product_id
LIMIT 5;

-- Query 1.3: Region comparison
SELECT c.region,
       COUNT(DISTINCT o.order_id) AS orders,
       COUNT(DISTINCT o.customer_id) AS buying_customers,
       ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)), 2) AS net_revenue,
       ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)) / COUNT(DISTINCT o.order_id), 2) AS aov
FROM orders AS o
JOIN order_items AS oi ON oi.order_id = o.order_id
JOIN customers AS c ON c.customer_id = o.customer_id
WHERE o.order_status = 'Completed'
GROUP BY c.region
ORDER BY net_revenue DESC;

-- ====================================================================
-- PROJECT 2: Customer Analytics
-- Business problem: Marketing wants to understand customer acquisition, repeat behaviour, value and segments.
-- Stakeholder: Head of Marketing and the CRM Manager.
-- Metric definitions: Active customer in a year = at least one non-cancelled order. New customer = first non-cancelled order in that year. Repeat purchase rate = buyers with >= 2 non-cancelled orders / buyers with >= 1. Customer lifetime value proxy = cumulative Completed net revenue to 2025-12-31 per customer (not a forecast; older customers have had longer to buy). Segments use fixed RFM-style rules as of 2025-12-31.
-- ====================================================================
-- Query 2.1: New versus returning customers per year
WITH yearly AS (
    SELECT DISTINCT customer_id, YEAR(order_date) AS order_year
    FROM orders WHERE order_status <> 'Cancelled'
),
cohort AS (SELECT customer_id, MIN(order_year) AS cohort_year FROM yearly GROUP BY customer_id)
SELECT y.order_year,
       SUM(c.cohort_year = y.order_year) AS new_customers,
       SUM(c.cohort_year < y.order_year) AS returning_customers
FROM yearly AS y
JOIN cohort AS c ON c.customer_id = y.customer_id
GROUP BY y.order_year
ORDER BY y.order_year;

-- Query 2.2: Repeat purchase rate and LTV proxy by signup year
WITH spend AS (
    SELECT o.customer_id, SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)) AS spend
    FROM orders AS o JOIN order_items AS oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY o.customer_id
),
buyers AS (
    SELECT customer_id, COUNT(*) AS order_count
    FROM orders WHERE order_status <> 'Cancelled' GROUP BY customer_id
)
SELECT YEAR(c.signup_date) AS signup_year,
       COUNT(*) AS customers,
       COUNT(b.customer_id) AS buyers,
       ROUND(100 * SUM(b.order_count >= 2) / COUNT(b.customer_id), 1) AS repeat_rate_pct,
       ROUND(AVG(COALESCE(s.spend, 0)), 2) AS ltv_proxy_per_customer
FROM customers AS c
LEFT JOIN buyers AS b ON b.customer_id = c.customer_id
LEFT JOIN spend AS s ON s.customer_id = c.customer_id
GROUP BY YEAR(c.signup_date)
ORDER BY signup_year;

-- Query 2.3: Customer segmentation
WITH rfm AS (
    SELECT o.customer_id,
           DATEDIFF('2025-12-31', MAX(o.order_date)) AS recency_days,
           COUNT(DISTINCT o.order_id) AS frequency,
           SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)) AS monetary
    FROM orders AS o JOIN order_items AS oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY o.customer_id
)
SELECT CASE WHEN recency_days <= 90 AND frequency >= 5 THEN 'Champion'
            WHEN recency_days <= 180 AND frequency >= 3 THEN 'Loyal'
            WHEN recency_days <= 180 THEN 'Recent'
            WHEN recency_days <= 365 THEN 'At Risk'
            ELSE 'Lost' END AS segment,
       COUNT(*) AS customers,
       ROUND(AVG(monetary), 2) AS avg_monetary,
       ROUND(SUM(monetary), 2) AS total_monetary
FROM rfm
GROUP BY segment
ORDER BY total_monetary DESC;

-- ====================================================================
-- PROJECT 3: Inventory and Supply Chain
-- Business problem: Operations needs to find stock shortages, slow-moving products and compare supplier and warehouse performance.
-- Stakeholder: Director of Operations and the Procurement Manager.
-- Metric definitions: Shortage = quantity_on_hand < reorder_level for a product in a warehouse. Slow-moving = stock on hand > 0 and zero units sold in Completed orders in the 90 days to 2025-12-31 (order_date >= 2025-10-02). Supplier return rate = units returned / units sold across Completed and Returned orders.
-- ====================================================================
-- Query 3.1: Shortages by warehouse
SELECT w.warehouse_name,
       COUNT(*) AS skus_stocked,
       SUM(i.quantity_on_hand < i.reorder_level) AS skus_below_reorder,
       SUM(i.quantity_on_hand = 0) AS skus_out_of_stock,
       ROUND(100 * SUM(i.quantity_on_hand < i.reorder_level) / COUNT(*), 1) AS shortage_pct
FROM inventory AS i
JOIN warehouses AS w ON w.warehouse_id = i.warehouse_id
GROUP BY w.warehouse_id, w.warehouse_name
ORDER BY shortage_pct DESC, w.warehouse_name;

-- Query 3.2: Slow-moving products
SELECT p.product_id, p.product_name, st.units_on_hand, COALESCE(u.units, 0) AS units_sold_90d
FROM products AS p
JOIN (SELECT product_id, SUM(quantity_on_hand) AS units_on_hand FROM inventory GROUP BY product_id) AS st
  ON st.product_id = p.product_id
LEFT JOIN (SELECT oi.product_id, SUM(oi.quantity) AS units
           FROM order_items AS oi JOIN orders AS o ON o.order_id = oi.order_id
           WHERE o.order_status = 'Completed' AND o.order_date >= '2025-10-02' AND o.order_date < '2026-01-01'
           GROUP BY oi.product_id) AS u ON u.product_id = p.product_id
WHERE COALESCE(u.units, 0) = 0 AND st.units_on_hand > 0
ORDER BY st.units_on_hand DESC, p.product_id
LIMIT 10;

-- Query 3.3: Supplier comparison
SELECT s.supplier_name, s.country, s.lead_time_days,
       SUM(oi.quantity) AS units_sold,
       COALESCE(SUM(r.quantity_returned), 0) AS units_returned,
       ROUND(100 * COALESCE(SUM(r.quantity_returned), 0) / SUM(oi.quantity), 1) AS return_rate_pct
FROM suppliers AS s
JOIN products AS p ON p.supplier_id = s.supplier_id
JOIN order_items AS oi ON oi.product_id = p.product_id
JOIN orders AS o ON o.order_id = oi.order_id
LEFT JOIN returns AS r ON r.order_item_id = oi.order_item_id
WHERE o.order_status IN ('Completed', 'Returned')
GROUP BY s.supplier_id, s.supplier_name, s.country, s.lead_time_days
ORDER BY return_rate_pct DESC, s.supplier_name;

-- ====================================================================
-- PROJECT 4: Marketing Performance
-- Business problem: Marketing needs to compare campaigns on reach, conversion and attributed revenue and decide where to spend next quarter.
-- Stakeholder: Chief Marketing Officer and the Performance Marketing Manager.
-- Metric definitions: Reach = impressions. CTR = clicks / impressions. Click-to-purchase conversion = Purchase interactions / Click interactions. Attribution: each order linked to a Purchase interaction is credited fully to the campaign with the customer's most recent click in the 14 days before the purchase (ties by lower campaign_id). Attributed revenue uses Completed orders only. ROAS = attributed revenue / budget.
-- ====================================================================
-- Query 4.1: Campaign funnel
SELECT m.campaign_name, m.channel,
       SUM(i.interaction_type = 'Impression') AS impressions,
       SUM(i.interaction_type = 'Click') AS clicks,
       ROUND(100 * SUM(i.interaction_type = 'Click') / NULLIF(SUM(i.interaction_type = 'Impression'), 0), 1) AS ctr_pct,
       SUM(i.interaction_type = 'Purchase') AS purchases,
       ROUND(100 * SUM(i.interaction_type = 'Purchase') / NULLIF(SUM(i.interaction_type = 'Click'), 0), 1) AS click_to_purchase_pct
FROM marketing_campaigns AS m
JOIN campaign_interactions AS i ON i.campaign_id = m.campaign_id
GROUP BY m.campaign_id, m.campaign_name, m.channel
ORDER BY m.campaign_id;

-- Query 4.2: Attributed revenue and ROAS by channel
WITH purchases AS (
    SELECT order_id, customer_id, interaction_datetime AS purchase_dt
    FROM campaign_interactions WHERE interaction_type = 'Purchase'
),
touches AS (
    SELECT p.order_id, c.campaign_id,
           ROW_NUMBER() OVER (PARTITION BY p.order_id ORDER BY c.interaction_datetime DESC, c.campaign_id) AS rn
    FROM purchases AS p
    JOIN campaign_interactions AS c
      ON c.customer_id = p.customer_id AND c.interaction_type = 'Click'
     AND c.interaction_datetime <= p.purchase_dt
     AND c.interaction_datetime >= DATE_SUB(p.purchase_dt, INTERVAL 14 DAY)
),
winner AS (SELECT order_id, campaign_id FROM touches WHERE rn = 1),
order_revenue AS (
    SELECT o.order_id, SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)) AS revenue
    FROM orders AS o JOIN order_items AS oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'Completed' GROUP BY o.order_id
),
camp AS (
    SELECT w.campaign_id, COUNT(*) AS orders, SUM(r.revenue) AS revenue
    FROM winner AS w JOIN order_revenue AS r ON r.order_id = w.order_id
    GROUP BY w.campaign_id
)
SELECT m.channel, COUNT(*) AS campaigns, SUM(c.orders) AS attributed_orders,
       ROUND(SUM(c.revenue), 2) AS attributed_revenue, SUM(m.budget) AS budget,
       ROUND(SUM(c.revenue) / SUM(m.budget), 2) AS roas
FROM camp AS c
JOIN marketing_campaigns AS m ON m.campaign_id = c.campaign_id
GROUP BY m.channel
ORDER BY roas DESC;

-- ====================================================================
-- PROJECT 5: Returns and Payment Reconciliation
-- Business problem: Finance suspects refund discrepancies and mismatches between order status and payment status.
-- Stakeholder: Finance Controller and the Customer Support Lead.
-- Metric definitions: Expected order total = SUM(line revenue) + shipping_fee. Paid total = SUM of payments with status 'Paid'. Rounding tolerance = 0.05. Return rate = Returned orders / (Completed + Returned orders). Refund discrepancy = refund_amount exceeding the value of the returned units by more than 0.01.
-- ====================================================================
-- Query 5.1: Order status versus latest payment status
WITH last_payment AS (
    SELECT order_id, payment_status,
           ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY payment_date DESC, payment_id DESC) AS rn
    FROM payments
)
SELECT o.order_status, COALESCE(lp.payment_status, 'No payment') AS latest_payment_status, COUNT(*) AS orders
FROM orders AS o
LEFT JOIN last_payment AS lp ON lp.order_id = o.order_id AND lp.rn = 1
GROUP BY o.order_status, COALESCE(lp.payment_status, 'No payment')
ORDER BY o.order_status, latest_payment_status;

-- Query 5.2: Payment exceptions summary
SELECT 'completed_paid_amount_mismatch' AS exception_type, COUNT(*) AS orders
FROM orders AS o
JOIN (SELECT order_id, SUM(quantity * unit_price * (1 - discount_pct / 100)) AS items_total FROM order_items GROUP BY order_id) AS i
  ON i.order_id = o.order_id
JOIN (SELECT order_id, SUM(amount) AS paid_total FROM payments WHERE payment_status = 'Paid' GROUP BY order_id) AS p
  ON p.order_id = o.order_id
WHERE o.order_status = 'Completed' AND ABS(p.paid_total - (i.items_total + o.shipping_fee)) > 0.05
UNION ALL
SELECT 'completed_without_paid_payment', COUNT(*)
FROM orders AS o
WHERE o.order_status = 'Completed'
  AND NOT EXISTS (SELECT 1 FROM payments AS p WHERE p.order_id = o.order_id AND p.payment_status = 'Paid')
UNION ALL
SELECT 'cancelled_paid_not_refunded', COUNT(*)
FROM orders AS o
WHERE o.order_status = 'Cancelled'
  AND EXISTS (SELECT 1 FROM payments AS p WHERE p.order_id = o.order_id AND p.payment_status = 'Paid')
  AND NOT EXISTS (SELECT 1 FROM payments AS p WHERE p.order_id = o.order_id AND p.payment_status = 'Refunded')
UNION ALL
SELECT 'returned_not_refunded', COUNT(*)
FROM orders AS o
WHERE o.order_status = 'Returned'
  AND NOT EXISTS (SELECT 1 FROM payments AS p WHERE p.order_id = o.order_id AND p.payment_status = 'Refunded')
UNION ALL
SELECT 'refund_exceeds_returned_value', COUNT(*)
FROM returns AS r JOIN order_items AS oi ON oi.order_item_id = r.order_item_id
WHERE r.refund_amount > ROUND(r.quantity_returned * oi.unit_price * (1 - oi.discount_pct / 100), 2) + 0.01;

-- Query 5.3: Return rate by year and reason
SELECT YEAR(o.order_date) AS order_year,
       COUNT(*) AS shipped_orders,
       SUM(o.order_status = 'Returned') AS returned_orders,
       ROUND(100 * SUM(o.order_status = 'Returned') / COUNT(*), 1) AS return_rate_pct
FROM orders AS o
WHERE o.order_status IN ('Completed', 'Returned')
GROUP BY YEAR(o.order_date)
ORDER BY order_year;

-- ====================================================================
-- PROJECT 6: Executive KPI Report
-- Business problem: The CEO needs a single management-ready table: monthly revenue, year-over-year growth, top five products and returning-customer metrics.
-- Stakeholder: CEO and the Board reporting team.
-- Metric definitions: Net revenue = Completed order line revenue excluding shipping. YoY growth = (revenue - revenue 12 months earlier) / revenue 12 months earlier. Returning customer in a month = customer with a Completed order in that month whose first non-cancelled order was in an earlier month. Top five products = by 2025 net revenue.
-- ====================================================================
-- Query 6.1: Executive monthly KPI table (2025)
WITH order_revenue AS (
    SELECT o.order_id, o.customer_id, DATE_FORMAT(o.order_date, '%Y-%m-01') AS month_start,
           SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)) AS revenue
    FROM orders AS o JOIN order_items AS oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY o.order_id, o.customer_id, DATE_FORMAT(o.order_date, '%Y-%m-01')
),
first_order AS (
    SELECT customer_id, DATE_FORMAT(MIN(order_date), '%Y-%m-01') AS first_month
    FROM orders WHERE order_status <> 'Cancelled' GROUP BY customer_id
),
monthly AS (
    SELECT r.month_start, SUM(r.revenue) AS revenue, COUNT(*) AS orders,
           COUNT(DISTINCT r.customer_id) AS active_customers,
           COUNT(DISTINCT CASE WHEN f.first_month < r.month_start THEN r.customer_id END) AS returning_customers
    FROM order_revenue AS r JOIN first_order AS f ON f.customer_id = r.customer_id
    GROUP BY r.month_start
),
with_yoy AS (
    SELECT m.*, LAG(revenue, 12) OVER (ORDER BY month_start) AS revenue_last_year FROM monthly AS m
)
SELECT month_start, orders, ROUND(revenue, 2) AS net_revenue,
       ROUND((revenue - revenue_last_year) / revenue_last_year * 100, 1) AS yoy_growth_pct,
       active_customers, returning_customers,
       ROUND(100 * returning_customers / active_customers, 1) AS returning_pct
FROM with_yoy
WHERE month_start >= '2025-01-01'
ORDER BY month_start;

-- Query 6.2: Top five products of 2025
WITH product_revenue AS (
    SELECT p.product_name,
           SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)) AS revenue
    FROM orders AS o
    JOIN order_items AS oi ON oi.order_id = o.order_id
    JOIN products AS p ON p.product_id = oi.product_id
    WHERE o.order_status = 'Completed' AND o.order_date >= '2025-01-01' AND o.order_date < '2026-01-01'
    GROUP BY p.product_id, p.product_name
)
SELECT RANK() OVER (ORDER BY revenue DESC) AS revenue_rank, product_name, ROUND(revenue, 2) AS revenue,
       ROUND(100 * revenue / SUM(revenue) OVER (), 1) AS share_pct
FROM product_revenue
ORDER BY revenue_rank, product_name
LIMIT 5;

