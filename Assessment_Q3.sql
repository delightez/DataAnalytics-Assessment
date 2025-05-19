-- CTE to get the last inflow transaction date per account
WITH last_inflow AS (
    SELECT
        plan_id,
        owner_id,
        MAX(transaction_date) AS last_transaction_date
    FROM savings_savingsaccount
    WHERE confirmed_amount > 0  -- Only count inflows
    GROUP BY plan_id, owner_id
)

-- Final query to get inactive accounts
SELECT
    p.id AS plan_id,
    p.owner_id,
    CASE
        WHEN p.is_regular_savings = 1 THEN 'Savings'
        WHEN p.is_a_fund = 1 THEN 'Investment'
        ELSE 'Unknown'
    END AS type,
    li.last_transaction_date,
    DATEDIFF(CURDATE(), li.last_transaction_date) AS inactivity_days
FROM plans_plan p
LEFT JOIN last_inflow li ON p.id = li.plan_id
WHERE
    (p.is_regular_savings = 1 OR p.is_a_fund = 1)  -- Limit to savings or investment accounts
    AND (
        li.last_transaction_date IS NULL OR  -- No inflow ever
        DATEDIFF(CURDATE(), li.last_transaction_date) > 365  -- Last inflow > 1 year ago
    )
ORDER BY inactivity_days DESC;
