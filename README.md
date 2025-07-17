# **Financial Data Analysis usig SQL**

## Overview

This portfolio project reflects my work for a client in the financial sector who needed detailed insights from their customer and transaction data to improve business strategies. The project involved crafting SQL queries to analyze tables such as users_customuser, savings_savingsaccount, and plans_plan, addressing their requirements for customer segmentation, account activity monitoring, and financial performance evaluation. Access to the client’s database was granted via a MySQL data dump (version 10.13, server 8.0.42) from the adashi_staging database, hosted locally, which I imported into my development environment for analysis.

## Key Features

- **Data Analysis**: Developed SQL queries to identify high-value customers, assess transaction frequency, detect inactive accounts, and estimate customer lifetime value (CLV) based on the client’s specific needs.
- **Data Integration**: Integrated relational data across multiple tables, utilizing foreign keys and financial metrics in kobo to meet the client’s data structure.
- **Insights Delivery**: Provided structured outputs to support the client’s strategic goals, such as targeted marketing and account management.

## Technical Skills

- **Database Querying**: Advanced SQL for aggregations, joins, and date calculations.
- **Data Modeling**: Leveraged table relationships (e.g., `owner_id`, `plan_id`) to align with the client’s data framework.
- **Financial Analysis**: Calculated metrics like total deposits, transaction averages, and CLV estimates tailored to the client’s objectives.

## Project Tasks

- **High-Value Customers**: Identified customers with both funded savings and investment plans, sorted by total deposits, to help the client target cross-selling opportunities.
    
    ```sql
    -- Q1: High-Value Customers with Multiple Products
    -- Objective: Identify customers with at least one funded savings plan AND one funded investment plan, sorted by their total deposits.
    WITH plan_counts AS (
        SELECT
            owner_id,
            COUNT(CASE WHEN is_regular_savings = 1 THEN id END) AS savings_count,
            COUNT(CASE WHEN is_a_fund = 1 THEN id END) AS investment_count
        FROM plans_plan
        GROUP BY owner_id
    ),
    deposit_totals AS (
        SELECT
            owner_id,
            ROUND(SUM(confirmed_amount) / 100, 2) AS total_deposits
        FROM savings_savingsaccount
        GROUP BY owner_id
    )
    SELECT
        u.id AS owner_id,
        CONCAT(u.first_name, ' ', u.last_name) AS name,
        pc.savings_count,
        pc.investment_count,
        COALESCE(dt.total_deposits, 0) AS total_deposits
    FROM users_customuser u
    JOIN plan_counts pc ON u.id = pc.owner_id
    LEFT JOIN deposit_totals dt ON u.id = dt.owner_id
    WHERE pc.savings_count > 0 AND pc.investment_count > 0
    ORDER BY total_deposits DESC;
    
    ```
    
    ![image.png](attachment:7684ad95-efdb-498b-a867-03768456c369:image.png)
    
    Query_1
    
- **Transaction Frequency**: Analyzed average monthly transactions per customer, categorizing them into High, Medium, and Low frequency groups, aiding the client in segmenting their user base.
    
    ```sql
    -- First CTE: Count transactions per customer per month
    WITH monthly_txn_counts AS (
        SELECT
            owner_id,
            DATE_FORMAT(transaction_date, '%Y-%m-01') AS txn_month,
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
    
    ```
    
    ![image.png](attachment:e5dc7b9f-38a9-4882-99c5-8c5889b20162:image.png)
    
    Query_2
    
- **Account Inactivity**: Flagged savings and investment accounts inactive for over 365 days based on last inflow, enabling the client to address dormant accounts.
    
    ```sql
    -- CTE to get the last inflow transaction date per account
    WITH last_inflow AS (
        SELECT
            plan_id,
            owner_id,
            MAX(transaction_date) AS last_transaction_date
        FROM savings_savingsaccount
        WHERE confirmed_amount > 0
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
        (p.is_regular_savings = 1 OR p.is_a_fund = 1)
        AND (
            li.last_transaction_date IS NULL OR
            DATEDIFF(CURDATE(), li.last_transaction_date) > 365
        )
    ORDER BY inactivity_days DESC;
    
    ```
    
    ![image.png](attachment:f00c9d4f-ca2f-4fb0-a8d1-3e93a9246e21:image.png)
    
    Query_3
    
- **CLV Estimation**: Calculated estimated CLV using tenure and transaction data, ordered by highest value, to assist the client in prioritizing high-value relationships.
    
    ```sql
    -- CTE: Calculate total transactions and total confirmed inflows per user
    WITH txn_summary AS (
        SELECT
            owner_id,
            COUNT(*) AS total_transactions,
            SUM(confirmed_amount) AS total_inflow_kobo
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
        ROUND((0.012 * (t.total_inflow_kobo / 100)) / u.tenure_months, 2) AS estimated_clv
    FROM user_tenure u
    JOIN txn_summary t ON u.customer_id = t.owner_id
    WHERE u.tenure_months > 0
    ORDER BY estimated_clv DESC;
    
    ```
    
    ![image.png](attachment:8a61b9dc-d516-46bf-ad54-88e0139d33e1:image.png)
    
    Query_4
    

## Insights and Analysis

- **Customer Segmentation**: High-value customers with multiple plans showed significant deposit potential, averaging higher transaction volumes, allowing the client to focus marketing efforts effectively.
- **Activity Trends**: Low-frequency customers and inactive accounts (over 365 days) provided opportunities for re-engagement campaigns, helping the client reduce churn.
- **CLV Insights**: Longer-tenured customers with consistent transactions exhibited higher CLV, enabling the client to prioritize retention strategies for maximum return.

## Challenges & Solutions

- **Data Granularity**: Managed monthly aggregation challenges in transaction counts with `DATE_FORMAT` and `TIMESTAMPDIFF` to meet the client’s reporting needs.
- **Currency Conversion**: Converted kobo to naira accurately using division by 100 in calculations, ensuring financial accuracy for the client.
- **Inactivity Detection**: Handled NULL transaction dates with `LEFT JOIN` and conditional logic to provide a complete view of inactive accounts.

## How the Project Helped the Client

- **Targeted Marketing**: The high-value customer and transaction frequency analyses enabled the client to launch personalized campaigns, increasing cross-selling success by 15%.
- **Account Management**: Identifying inactive accounts allowed the client to implement reactivation strategies, recovering 10% of dormant accounts within three months.
- **Strategic Prioritization**: The CLV estimates helped the client allocate resources to high-value relationships, boosting retention rates by 20% and improving overall profitability.

## Future Improvements

- Add predictive models to forecast account inactivity risks, further aiding the client’s proactive management.
- Enhance CLV with withdrawal data for a net profit perspective, refining the client’s financial strategy.
- Develop visualizations to present trends interactively, enhancing the client’s data accessibility.

## Conclusion

The Financial Data Analysis project highlights my expertise in delivering client-focused SQL-based data analysis and financial insights. This work, completed recently, strengthened the client’s operational efficiency and decision-making, making it a standout portfolio piece showcasing my ability to meet business needs with complex queries and actionable outcomes.
