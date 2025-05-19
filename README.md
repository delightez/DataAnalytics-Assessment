# DataAnalytics-Assessment
This repository contains my SQL solutions and analysis for the Cowrywise Data Analytics Assessment. The queries address key business questions around customer transaction frequency, plan preferences, and customer lifetime value. 

"""
# Cowrywise SQL Analytics Assessment

This document provides a summary of my thought process, SQL approaches, and the challenges I encountered while working on the Cowrywise SQL assessment. Each question was approached with a focus on clarity, performance, and practical business value.

---

## Question-by-Question Breakdown

### 1. Categorize Customers by Savings Volume

**Objective:** Group users into High, Medium, and Low Savers based on their total confirmed savings.

**Approach:**  
I aggregated `confirmed_amount` by `owner_id` from the `savings_savingsaccount` table, then converted from kobo to naira (since all amount fields are in kobo). I used simple thresholds to segment users:
- **High Savers**: above ₦1,000,000
- **Medium Savers**: ₦500,000 – ₦1,000,000
- **Low Savers**: below ₦500,000

**Challenge:**  
The main thing to be mindful of was unit conversion. Since the amounts are in kobo, it was important to standardize output to naira to make the results interpretable for stakeholders.

---

### 2. Categorize Customers by Savings Frequency

**Objective:** Classify customers based on their average number of savings transactions per month.

**Approach:**  
I extracted the month from the `created_on` field in `savings_savingsaccount` to group transactions per month per customer. Then I calculated each user’s average number of transactions per month. I used the following logic:
- **High Frequency**: ≥10/month
- **Medium Frequency**: 3–9/month
- **Low Frequency**: <3/month

**Challenge:**  
One subtle issue was MySQL's lack of native `DATE_TRUNC` or month truncation like in PostgreSQL. I resolved this using `DATE_FORMAT(created_on, '%Y-%m-01')` to get consistent monthly buckets. Also had to clarify which timestamp to use since the field mentioned in the prompt (`created_at`) didn’t exist.

---

### 3. Average Savings Amount by Plan Type

**Objective:** Compute the average confirmed savings per user, grouped by plan type — either a regular savings plan or an investment.

**Approach:**  
I joined `savings_savingsaccount` with `plans_plan` using `plan_id`, then used the flags:
- `is_regular_savings = 1` for regular plans
- `is_a_fund = 1` for investment plans

I grouped by user and plan type, summed up confirmed savings, and calculated averages.

**Challenge:**  
The overlap or absence of flags (i.e., neither regular nor fund) could make classification messy. I used CASE logic to handle mixed or untagged data gracefully.

---

### 4. Customer Lifetime Value (CLV)

**Objective:** Estimate each user’s CLV based on transaction frequency and tenure.

**Approach:**
1. Calculated tenure in months using `date_joined` from the `users_customuser` table.
2. Counted total transactions from the `savings_savingsaccount` table.
3. Estimated profit per transaction as 0.1% of the transaction value.
4. Applied the formula:

CLV = (total_transactions / tenure_months) * 12 * avg_profit_per_transaction

yaml
Always show details

Copy

**Challenge:**  
Some users had zero-month tenures (i.e., signed up this month), which led to potential divide-by-zero issues. I added safeguards using `NULLIF` to avoid crashes. I also used average profit derived from total confirmed amounts where needed.

---


## Broader Challenges Faced (from an Analyst's Lens)

As someone with 4+ years in data analysis, a few recurring challenges stood out during this project:

### 1. Incomplete Schema & Ambiguities
The schema didn’t come with an ERD or definitions for each column, so I had to rely heavily on naming conventions and the provided hints. This slowed down initial query development.

### 2. Overlapping Timestamps
There were several date fields — `created_on`, `transaction_date`, `date_joined`, etc. — and choosing the correct one in context wasn’t always obvious. I double-checked each one against the business goal of the query to decide.

### 3. Inconsistent Naming vs. Expectations
Some field names in the prompt (like `created_at`) didn’t match the actual schema. I adapted queries to fit what was available (`created_on`, `date_joined`, etc.) and made notes on all assumptions.

### 4. Lack of Sample Data
Not having access to even a sample dataset made testing assumptions a bit speculative. To handle this, I wrote all queries with edge cases in mind (e.g., nulls, divide-by-zero, zero transactions).

### 5. MySQL Limitations
MySQL lacks some powerful functions available in other SQL dialects (like `FILTER`, `DATE_TRUNC`, `OVER(PARTITION ORDER BY)` in windowed aggregates). I worked around this using subqueries, `DATE_FORMAT`, and careful grouping logic.

---


## Final Thoughts

I really enjoyed working through these questions. They do a good job of simulating real-world ambiguity in analytics tasks — where you have to think both in terms of SQL logic and business context. 
"""
