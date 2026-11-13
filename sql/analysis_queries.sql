-- Retail Sales Analysis: SQL queries (SQLite)
-- Table: orders (one row per order line, built in notebooks/01_data_cleaning.ipynb)
-- Every query is introduced by a name line, so notebooks/02_sql_analysis.ipynb can find it by name.
-- A question mark inside a query (see Q9) is a parameter placeholder: the value is passed separately
-- by the database driver and is never pasted into the SQL text, which prevents SQL injection.


-- name: kpis
-- Q1. How big is the business and is it profitable?
SELECT
    ROUND(SUM(sales), 2)                           AS total_revenue,
    ROUND(SUM(profit), 2)                          AS total_profit,
    COUNT(DISTINCT order_id)                       AS total_orders,
    ROUND(SUM(sales) / COUNT(DISTINCT order_id), 2) AS avg_order_value,
    ROUND(100.0 * SUM(profit) / SUM(sales), 2)     AS profit_margin_pct
FROM orders;


-- name: yearly
-- Q2. How did revenue and profit change year over year?
-- LAG() looks at the previous year's row so growth can be calculated in one query.
SELECT
    year,
    ROUND(SUM(sales), 0)                      AS revenue,
    ROUND(SUM(profit), 0)                     AS profit,
    COUNT(DISTINCT order_id)                  AS orders,
    ROUND(100.0 * SUM(profit) / SUM(sales), 1) AS margin_pct,
    ROUND(100.0 * (SUM(sales) - LAG(SUM(sales)) OVER (ORDER BY year))
          / LAG(SUM(sales)) OVER (ORDER BY year), 1) AS revenue_growth_pct
FROM orders
GROUP BY year
ORDER BY year;


-- name: monthly
-- Q3. What does the month-by-month trend look like?
SELECT
    strftime('%Y-%m', order_date)  AS month,
    ROUND(SUM(sales), 0)           AS revenue,
    ROUND(SUM(profit), 0)          AS profit,
    COUNT(DISTINCT order_id)       AS orders
FROM orders
GROUP BY month
ORDER BY month;


-- name: seasonality
-- Q4. Is there a seasonal pattern? Average revenue per calendar month across all years.
SELECT
    month_number,
    ROUND(AVG(month_revenue), 0) AS avg_monthly_revenue
FROM (
    SELECT
        strftime('%Y', order_date) AS yr,
        strftime('%m', order_date) AS month_number,
        SUM(sales)                 AS month_revenue
    FROM orders
    GROUP BY yr, month_number
)
GROUP BY month_number
ORDER BY month_number;


-- name: category
-- Q5. Which categories bring revenue and which bring profit?
SELECT
    category,
    ROUND(SUM(sales), 0)                                          AS revenue,
    ROUND(SUM(profit), 0)                                         AS profit,
    ROUND(100.0 * SUM(profit) / SUM(sales), 1)                    AS margin_pct,
    ROUND(100.0 * SUM(sales) / (SELECT SUM(sales) FROM orders), 1) AS revenue_share_pct
FROM orders
GROUP BY category
ORDER BY revenue DESC;


-- name: sub_category
-- Q6. Which sub-categories are underperforming? Sorted from least to most profit.
SELECT
    category,
    sub_category,
    ROUND(SUM(sales), 0)                       AS revenue,
    ROUND(SUM(profit), 0)                      AS profit,
    ROUND(100.0 * SUM(profit) / SUM(sales), 1) AS margin_pct,
    ROUND(100.0 * AVG(discount), 1)            AS avg_discount_pct
FROM orders
GROUP BY category, sub_category
ORDER BY profit;


-- name: region
-- Q7. How do the four regions compare?
SELECT
    region,
    ROUND(SUM(sales), 0)                       AS revenue,
    ROUND(SUM(profit), 0)                      AS profit,
    ROUND(100.0 * SUM(profit) / SUM(sales), 1) AS margin_pct,
    COUNT(DISTINCT order_id)                   AS orders,
    ROUND(100.0 * AVG(discount), 1)            AS avg_discount_pct
FROM orders
GROUP BY region
ORDER BY revenue DESC;


-- name: state_losses
-- Q8. Which states lose money overall?
SELECT
    state,
    region,
    ROUND(SUM(sales), 0)            AS revenue,
    ROUND(SUM(profit), 0)           AS profit,
    ROUND(100.0 * AVG(discount), 1) AS avg_discount_pct
FROM orders
GROUP BY state, region
HAVING SUM(profit) < 0
ORDER BY profit;


-- name: region_worst_subcategories
-- Q9. Which 3 sub-categories hurt profit most in ONE region? (parameterized: region = ?)
SELECT
    sub_category,
    ROUND(SUM(sales), 0)  AS revenue,
    ROUND(SUM(profit), 0) AS profit
FROM orders
WHERE region = ?
GROUP BY sub_category
ORDER BY profit
LIMIT 3;


-- name: discount_bands
-- Q10. What happens to profit when we discount more?
SELECT
    CASE
        WHEN discount = 0   THEN '1) No discount'
        WHEN discount <= 0.2 THEN '2) Up to 20%'
        WHEN discount <= 0.4 THEN '3) 21-40%'
        ELSE                      '4) Over 40%'
    END AS discount_band,
    COUNT(*)                                   AS order_lines,
    ROUND(SUM(sales), 0)                       AS revenue,
    ROUND(SUM(profit), 0)                      AS profit,
    ROUND(100.0 * SUM(profit) / SUM(sales), 1) AS margin_pct
FROM orders
GROUP BY discount_band
ORDER BY discount_band;


-- name: top_products
-- Q11. Top 10 products by revenue, and are they profitable?
SELECT
    product_name,
    ROUND(SUM(sales), 0)                       AS revenue,
    ROUND(SUM(profit), 0)                      AS profit,
    ROUND(100.0 * SUM(profit) / SUM(sales), 1) AS margin_pct
FROM orders
GROUP BY product_name
ORDER BY SUM(sales) DESC
LIMIT 10;


-- name: worst_products
-- Q12. The 10 products that lose the most money.
SELECT
    product_name,
    ROUND(SUM(sales), 0)  AS revenue,
    ROUND(SUM(profit), 0) AS profit,
    ROUND(100.0 * AVG(discount), 1) AS avg_discount_pct
FROM orders
GROUP BY product_name
ORDER BY SUM(profit)
LIMIT 10;


-- name: segments
-- Q13. Which customer segments matter most?
SELECT
    segment,
    COUNT(DISTINCT customer_id)                AS customers,
    COUNT(DISTINCT order_id)                   AS orders,
    ROUND(SUM(sales), 0)                       AS revenue,
    ROUND(SUM(profit), 0)                      AS profit,
    ROUND(100.0 * SUM(profit) / SUM(sales), 1) AS margin_pct
FROM orders
GROUP BY segment
ORDER BY revenue DESC;


-- name: customer_frequency
-- Q14. How often do customers come back? (customers grouped by number of orders placed)
SELECT
    CASE
        WHEN n_orders = 1  THEN '1 order'
        WHEN n_orders <= 4 THEN '2-4 orders'
        WHEN n_orders <= 8 THEN '5-8 orders'
        ELSE                    '9+ orders'
    END AS order_count_group,
    COUNT(*) AS customers
FROM (
    SELECT customer_id, COUNT(DISTINCT order_id) AS n_orders
    FROM orders
    GROUP BY customer_id
)
GROUP BY order_count_group
ORDER BY MIN(n_orders);


-- name: customer_concentration
-- Q15. How dependent are we on our best customers? Revenue share of the top 10% of customers.
-- A CTE (WITH ...) is a named temporary result, which keeps the query readable step by step.
WITH customer_revenue AS (
    SELECT customer_id, SUM(sales) AS revenue
    FROM orders
    GROUP BY customer_id
),
ranked AS (
    SELECT
        revenue,
        ROW_NUMBER() OVER (ORDER BY revenue DESC) AS rank_no,
        COUNT(*) OVER ()                          AS total_customers
    FROM customer_revenue
)
SELECT
    MAX(total_customers)                                                AS total_customers,
    ROUND(100.0 * SUM(revenue) / (SELECT SUM(sales) FROM orders), 1)    AS top_10pct_revenue_share
FROM ranked
WHERE rank_no <= total_customers * 0.1;


-- name: returns
-- Q16. How many orders are returned, and how much sales value sits in those orders?
-- A return is counted per order (all lines of a returned order are flagged).
SELECT
    region,
    COUNT(DISTINCT order_id)                                                    AS orders,
    COUNT(DISTINCT CASE WHEN returned = 'Yes' THEN order_id END)                AS returned_orders,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN returned = 'Yes' THEN order_id END)
          / COUNT(DISTINCT order_id), 1)                                        AS return_rate_pct,
    ROUND(SUM(CASE WHEN returned = 'Yes' THEN sales ELSE 0 END), 0)             AS sales_in_returned_orders
FROM orders
GROUP BY region
ORDER BY return_rate_pct DESC;


-- name: discount_by_category
-- Q17. Is the weak margin in some categories caused by deep discounts?
-- Compare each category's margin on lines discounted up to 20% against lines discounted over 20%.
SELECT
    category,
    ROUND(100.0 * SUM(CASE WHEN discount <= 0.2 THEN profit END)
          / SUM(CASE WHEN discount <= 0.2 THEN sales END), 1) AS margin_pct_up_to_20,
    ROUND(100.0 * SUM(CASE WHEN discount > 0.2 THEN profit END)
          / SUM(CASE WHEN discount > 0.2 THEN sales END), 1)  AS margin_pct_over_20,
    ROUND(SUM(CASE WHEN discount > 0.2 THEN profit END), 0)   AS profit_over_20
FROM orders
GROUP BY category
ORDER BY profit_over_20;


-- name: deep_discount_subcategories
-- Q18. Which sub-categories lose the most on lines discounted over 20%?
SELECT
    sub_category,
    SUM(CASE WHEN discount > 0.2 THEN 1 ELSE 0 END)                  AS lines_over_20,
    ROUND(SUM(CASE WHEN discount > 0.2 THEN profit ELSE 0 END), 0)   AS profit_over_20,
    ROUND(SUM(CASE WHEN discount <= 0.2 THEN profit ELSE 0 END), 0)  AS profit_up_to_20
FROM orders
GROUP BY sub_category
ORDER BY profit_over_20
LIMIT 6;


-- name: deep_discount_by_year
-- Q19. Is the discount problem getting better or worse over time?
SELECT
    year,
    ROUND(100.0 * SUM(CASE WHEN discount > 0.2 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_lines_over_20,
    ROUND(SUM(CASE WHEN discount > 0.2 THEN sales ELSE 0 END), 0)                AS revenue_over_20,
    ROUND(SUM(CASE WHEN discount > 0.2 THEN profit ELSE 0 END), 0)               AS profit_over_20
FROM orders
GROUP BY year
ORDER BY year;


-- name: returns_by_year
-- Q20. Is the West's high return rate a one-off or a trend?
SELECT
    region,
    year,
    COUNT(DISTINCT order_id)                                     AS orders,
    COUNT(DISTINCT CASE WHEN returned = 'Yes' THEN order_id END) AS returned_orders,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN returned = 'Yes' THEN order_id END)
          / COUNT(DISTINCT order_id), 1)                         AS return_rate_pct
FROM orders
GROUP BY region, year
ORDER BY region, year;
