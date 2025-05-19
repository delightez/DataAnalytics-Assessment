-- CTE: Calculate total transactions and total confirmed inflows per user
WITH txn_summary AS (
    SELECT
        owner_id,
        COUNT(*) AS total_transactions,
        SUM(confirmed_amount) AS total_inflow_kobo  -- In kobo
    FROM savings_savingsaccount
    WHERE confirmed_amount > 0
    GROUP BY owner_id
),

-- CTE: Add tenure in months from signup to today
user_tenure AS (
    SELECT
        u.id AS customer_id,
        CONCAT(u.first_name, ' ', u.last_name) AS name,
        TIMESTAMPDIFF(MONTH, u.date_joined, CURDATE()) AS tenure_months
    FROM users_customuser u
)

-- Final: Combine and calculate estimated CLV
SELECT
    u.customer_id,
    u.name,
    u.tenure_months,
    t.total_transactions,
    
    -- Convert kobo to naira and apply CLV formula
    ROUND((0.012 * (t.total_inflow_kobo / 100)) / u.tenure_months, 2) AS estimated_clv
    
FROM user_tenure u
JOIN txn_summary t ON u.customer_id = t.owner_id
WHERE u.tenure_months > 0  -- Avoid division by zero
ORDER BY estimated_clv DESC;
