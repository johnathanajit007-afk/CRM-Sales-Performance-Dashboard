USE crm_db;

CREATE OR REPLACE VIEW crm_sales_master AS
SELECT 
    sp.opportunity_id,
    sp.sales_agent,
    st.manager,
    st.regional_office,
    sp.product,
    p.series,
    p.sales_price,
    sp.account,
    a.sector,
    a.revenue AS account_revenue,
    sp.engage_date AS created_on,
    sp.close_date,
    sp.deal_stage,
    sp.close_value,
    CASE WHEN LOWER(TRIM(sp.deal_stage)) = 'won' THEN 1 ELSE 0 END AS is_won,
    CASE WHEN LOWER(TRIM(sp.deal_stage)) IN ('won', 'lost') THEN 1 ELSE 0 END AS is_closed,
    DATEDIFF(sp.close_date, sp.engage_date) AS sales_cycle_days
FROM sales_pipeline sp
LEFT JOIN sales_teams st ON sp.sales_agent = st.sales_agent
LEFT JOIN products p ON sp.product = p.product
LEFT JOIN accounts a ON sp.account = a.account;

SELECT 
    manager,
    regional_office,
    COUNT(opportunity_id) AS total_opportunities,
    SUM(is_won) AS won_deals,
    ROUND((SUM(is_won) / COUNT(CASE WHEN is_closed = 1 THEN 1 END)) * 100, 2) AS win_rate_pct,
    SUM(close_value) AS total_revenue
FROM crm_sales_master
WHERE is_closed = 1
GROUP BY manager, regional_office
ORDER BY total_revenue DESC;

WITH QuarterlyRevenue AS (
    SELECT 
        CONCAT(YEAR(close_date), '-Q', QUARTER(close_date)) AS close_quarter,
        SUM(close_value) AS quarterly_revenue,
        COUNT(opportunity_id) AS deals_won
    FROM crm_sales_master
    WHERE LOWER(deal_stage) = 'won'
    GROUP BY close_quarter
)
SELECT 
    close_quarter,
    quarterly_revenue,
    deals_won,
    LAG(quarterly_revenue, 1) OVER (ORDER BY close_quarter) AS prev_quarter_revenue,
    ROUND(
        ((quarterly_revenue - LAG(quarterly_revenue, 1) OVER (ORDER BY close_quarter)) 
        / LAG(quarterly_revenue, 1) OVER (ORDER BY close_quarter)) * 100, 2
    ) AS qoq_growth_pct
FROM QuarterlyRevenue
ORDER BY close_quarter;

SELECT 
    product,
    COUNT(opportunity_id) AS total_opportunities,
    SUM(is_won) AS won_deals,
    ROUND((SUM(is_won) * 100.0 / COUNT(opportunity_id)), 2) AS win_rate_pct,
    SUM(close_value) AS total_revenue
FROM crm_sales_master
WHERE is_closed = 1
GROUP BY product
ORDER BY win_rate_pct DESC;