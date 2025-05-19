-- Q1: High-Value Customers with Multiple Products
-- Objective: Identify customers with at least one funded savings plan 
-- AND one funded investment plan, sorted by their total deposits.

-- First CTE: Count how many savings and investment plans each customer has
WITH plan_counts AS (
    SELECT
        owner_id,
        -- Count savings plans (flagged by is_regular_savings = 1)
        COUNT(CASE WHEN is_regular_savings = 1 THEN id END) AS savings_count,
        -- Count investment plans (flagged by is_a_fund = 1)
        COUNT(CASE WHEN is_a_fund = 1 THEN id END) AS investment_count
    FROM plans_plan
    GROUP BY owner_id
),

-- Second CTE: Calculate total confirmed deposits per customer
deposit_totals AS (
    SELECT
        owner_id,
        -- Sum confirmed deposits and convert from kobo to naira
        ROUND(SUM(confirmed_amount) / 100, 2) AS total_deposits
    FROM savings_savingsaccount
    GROUP BY owner_id
)

-- Final selection: Join customer details, plan counts, and deposit totals
SELECT
    u.id AS owner_id,
    -- Combine first and last name for readability
    CONCAT(u.first_name, ' ', u.last_name) AS name,
    pc.savings_count,
    pc.investment_count,
    -- Use COALESCE to handle users with no deposits (NULL → 0)
    COALESCE(dt.total_deposits, 0) AS total_deposits
FROM users_customuser u
-- Join to get savings & investment counts
JOIN plan_counts pc ON u.id = pc.owner_id
-- Join to get total deposits
LEFT JOIN deposit_totals dt ON u.id = dt.owner_id
-- Filter to only those with BOTH a savings and investment plan
WHERE pc.savings_count > 0 AND pc.investment_count > 0
-- Sort by highest total deposits first
ORDER BY total_deposits DESC;
