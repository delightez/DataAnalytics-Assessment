-- First CTE: Count transactions per customer per month
WITH monthly_txn_counts AS (
    SELECT
        owner_id,
        DATE_FORMAT(transaction_date, '%Y-%m-01') AS txn_month,  -- Get first day of transaction month
        COUNT(*) AS txn_count
    FROM savings_savingsaccount
    GROUP BY owner_id, DATE_FORMAT(transaction_date, '%Y-%m-01')
),

-- Second CTE: Compute average number of transactions per month for each customer
avg_txn_per_customer AS (
    SELECT
        owner_id,
        ROUND(AVG(txn_count), 2) AS avg_txns_per_month
    FROM monthly_txn_counts
    GROUP BY owner_id
),

-- Third CTE: Categorize each customer based on their average monthly transaction frequency
categorized_customers AS (
    SELECT
        owner_id,
        avg_txns_per_month,
        CASE
            WHEN avg_txns_per_month >= 10 THEN 'High Frequency'
            WHEN avg_txns_per_month BETWEEN 3 AND 9 THEN 'Medium Frequency'
            ELSE 'Low Frequency'
        END AS frequency_category
    FROM avg_txn_per_customer
)

-- Final Result: Count number of customers in each frequency category
-- and show the average transaction frequency for each group
SELECT
    frequency_category,
    COUNT(*) AS customer_count,
    ROUND(AVG(avg_txns_per_month), 2) AS avg_transactions_per_month
FROM categorized_customers
GROUP BY frequency_category
ORDER BY 
    CASE frequency_category
        WHEN 'High Frequency' THEN 1
        WHEN 'Medium Frequency' THEN 2
        WHEN 'Low Frequency' THEN 3
    END;
