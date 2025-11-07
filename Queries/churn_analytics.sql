/*
===============================================================
Project: Streamify Subscription Churn & Retention Analytics
Tool:    MySQL Workbench
Description:
This project simulates a subscription-based streaming platform
for analyzing customer churn, retention, revenue, and behavior.
===============================================================
*/

-- ============================================================
-- STEP 0: Reset Database
-- ============================================================
DROP DATABASE IF EXISTS streamify_churn_analytics;
CREATE DATABASE streamify_churn_analytics;
USE streamify_churn_analytics;

-- ============================================================
-- STEP 1: Dimension Tables
-- ============================================================

-- Customers
CREATE TABLE dim_customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(120) UNIQUE,
    signup_date DATE,
    country VARCHAR(50),
    plan ENUM('basic','standard','pro'),
    channel VARCHAR(50),
    gender ENUM('F','M','O','U'),
    age INT,
    is_active TINYINT(1) DEFAULT 1
);

-- Countries
CREATE TABLE dim_countries (
    country_id INT AUTO_INCREMENT PRIMARY KEY,
    country_name VARCHAR(50)
);
INSERT INTO dim_countries (country_name) VALUES
('India'),('USA'),('UK'),('Canada'),('Australia'),('Germany'),('France'),('Singapore');

-- Marketing Channels
CREATE TABLE dim_channels (
    channel_id INT AUTO_INCREMENT PRIMARY KEY,
    channel_name VARCHAR(50)
);
INSERT INTO dim_channels (channel_name) VALUES
('Social Media'),('Referral'),('Google Ads'),('Organic Search'),('YouTube'),('Affiliate');

-- Churn Reasons
CREATE TABLE dim_churn_reasons (
    reason_id INT AUTO_INCREMENT PRIMARY KEY,
    reason_text VARCHAR(100)
);
INSERT INTO dim_churn_reasons (reason_text) VALUES
('Too expensive'),('Not using enough'),('Switched to competitor'),
('Poor customer support'),('Technical issues'),('Payment failed'),
('Temporary break'),('Other');

-- ============================================================
-- STEP 2: Fact Tables
-- ============================================================

-- Subscriptions
CREATE TABLE fact_subscriptions (
    subscription_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT,
    start_date DATE,
    end_date DATE NULL,
    plan ENUM('basic','standard','pro'),
    status ENUM('active','cancelled','paused','trial','expired'),
    churn_reason VARCHAR(255),
    monthly_price DECIMAL(8,2),
    auto_renew TINYINT(1) DEFAULT 1,
    FOREIGN KEY (customer_id) REFERENCES dim_customers(customer_id)
);

-- Payments
CREATE TABLE fact_payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    subscription_id INT,
    payment_date DATE,
    amount DECIMAL(8,2),
    payment_method ENUM('credit_card','debit_card','paypal','upi'),
    status ENUM('success','pending','failed'),
    FOREIGN KEY (subscription_id) REFERENCES fact_subscriptions(subscription_id)
);

-- Events
CREATE TABLE fact_events (
    event_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT,
    event_type ENUM('login','watch','browse','cancel','renew','upgrade'),
    event_date DATETIME,
    event_value INT,
    FOREIGN KEY (customer_id) REFERENCES dim_customers(customer_id)
);

-- ============================================================
-- STEP 3: Indexing for Performance
-- ============================================================
CREATE INDEX idx_customer_signup ON dim_customers(signup_date);
CREATE INDEX idx_subscription_customer ON fact_subscriptions(customer_id);
CREATE INDEX idx_subscription_status ON fact_subscriptions(status);
CREATE INDEX idx_payment_subscription ON fact_payments(subscription_id);
CREATE INDEX idx_payment_status ON fact_payments(status);
CREATE INDEX idx_event_customer_date ON fact_events(customer_id, event_date);

-- ============================================================
-- STEP 4: Populate Data (Realistic Randomized)
-- ============================================================

-- Customers (~5000)
INSERT INTO dim_customers (email, signup_date, country, plan, channel, gender, age, is_active)
SELECT
    CONCAT('user', n, '@streamify.com'),
    DATE_SUB(CURDATE(), INTERVAL FLOOR(RAND()*730) DAY),
    (SELECT country_name FROM dim_countries ORDER BY RAND() LIMIT 1),
    ELT(FLOOR(RAND()*3)+1,'basic','standard','pro'),
    (SELECT channel_name FROM dim_channels ORDER BY RAND() LIMIT 1),
    ELT(FLOOR(RAND()*4)+1,'F','M','O','U'),
    FLOOR(18 + RAND()*35),
    1
FROM (SELECT @row:=@row+1 AS n FROM 
        (SELECT 0 UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 
         UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) t1,
        (SELECT 0 UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 
         UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) t2,
        (SELECT 0 UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 
         UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) t3,
        (SELECT @row:=0) r
     ) a
LIMIT 5000;

-- Subscriptions (~1 per customer)
INSERT INTO fact_subscriptions (customer_id, start_date, end_date, plan, status, churn_reason, monthly_price, auto_renew)
SELECT 
    c.customer_id,
    c.signup_date,
    CASE WHEN RAND()<0.25 THEN DATE_ADD(c.signup_date, INTERVAL FLOOR(RAND()*600) DAY) ELSE NULL END,
    c.plan,
    CASE 
        WHEN RAND()<0.20 THEN 'cancelled'
        WHEN RAND()<0.05 THEN 'paused'
        WHEN RAND()<0.05 THEN 'expired'
        WHEN RAND()<0.05 THEN 'trial'
        ELSE 'active'
    END,
    CASE WHEN RAND()<0.20 THEN (SELECT reason_text FROM dim_churn_reasons ORDER BY RAND() LIMIT 1) ELSE NULL END,
    CASE c.plan WHEN 'basic' THEN 9.99 WHEN 'standard' THEN 19.99 WHEN 'pro' THEN 39.99 END,
    IF(RAND()<0.85,1,0)
FROM dim_customers c;

-- Payments (~3 per customer avg)
INSERT INTO fact_payments (subscription_id, payment_date, amount, payment_method, status)
SELECT 
    s.subscription_id,
    DATE_ADD(s.start_date, INTERVAL FLOOR(RAND()*365) DAY),
    s.monthly_price,
    ELT(FLOOR(RAND()*4)+1,'credit_card','debit_card','paypal','upi'),
    ELT(FLOOR(RAND()*10)+1,'success','success','success','success','success','success','pending','failed','success','success')
FROM fact_subscriptions s
WHERE s.status IN ('active','paused','trial','expired');

-- Events (~2 per customer avg)
INSERT INTO fact_events (customer_id, event_type, event_date, event_value)
SELECT
    c.customer_id,
    ELT(FLOOR(RAND()*6)+1,'login','watch','browse','cancel','renew','upgrade'),
    DATE_ADD(c.signup_date, INTERVAL FLOOR(RAND()*700) DAY),
    FLOOR(RAND()*100)
FROM dim_customers c
WHERE RAND()<0.7;

-- ============================================================
-- STEP 5: Verification
-- ============================================================
SELECT COUNT(*) AS total_customers FROM dim_customers;
SELECT COUNT(*) AS total_subscriptions FROM fact_subscriptions;
SELECT COUNT(*) AS total_payments FROM fact_payments;
SELECT COUNT(*) AS total_events FROM fact_events;


SELECT 
    COUNT(*) AS total_customers,
    SUM(CASE WHEN is_active = 1 THEN 1 ELSE 0 END) AS active_customers,
    SUM(CASE WHEN is_active = 0 THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(SUM(CASE WHEN is_active = 0 THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS churn_rate_pct
FROM dim_customers;


SELECT 
    DATE_FORMAT(signup_date, '%Y-%m') AS month,
    COUNT(*) AS new_customers
FROM dim_customers
GROUP BY DATE_FORMAT(signup_date, '%Y-%m')
ORDER BY month;

SELECT 
    plan,
    COUNT(*) AS total_users,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM dim_customers) * 100, 2) AS percentage
FROM dim_customers
GROUP BY plan
ORDER BY total_users DESC;

WITH monthly_revenue AS (
    SELECT 
        DATE_FORMAT(p.payment_date, '%Y-%m') AS month,
        SUM(p.amount) AS total_revenue
    FROM fact_payments p
    GROUP BY DATE_FORMAT(p.payment_date, '%Y-%m')
)
SELECT 
    month,
    total_revenue,
    ROUND(SUM(total_revenue) OVER (ORDER BY month), 2) AS cumulative_revenue
FROM monthly_revenue
ORDER BY month;


SELECT 
    ROUND(SUM(p.amount) / COUNT(DISTINCT s.customer_id), 2) AS ARPU
FROM fact_payments p
JOIN fact_subscriptions s ON p.subscription_id = s.subscription_id;

SELECT 
    s.plan,
    COUNT(DISTINCT s.customer_id) AS total_customers,
    ROUND(SUM(p.amount),2) AS total_revenue,
    ROUND(SUM(p.amount)/COUNT(DISTINCT s.customer_id),2) AS avg_revenue_per_customer
FROM fact_subscriptions s
JOIN fact_payments p ON s.subscription_id = p.subscription_id
GROUP BY s.plan
ORDER BY total_revenue DESC;

SELECT 
    DATE_FORMAT(end_date, '%Y-%m') AS month,
    COUNT(*) AS churned_customers,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM dim_customers) * 100, 2) AS churn_rate_pct
FROM fact_subscriptions
WHERE status IN ('cancelled', 'expired')
GROUP BY DATE_FORMAT(end_date, '%Y-%m')
ORDER BY month;

SELECT 
    country,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN is_active = 0 THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(SUM(CASE WHEN is_active = 0 THEN 1 ELSE 0 END)/COUNT(*)*100,2) AS churn_rate_pct
FROM dim_customers
GROUP BY country
ORDER BY churn_rate_pct DESC;

SELECT 
    CASE 
        WHEN age < 25 THEN '18-24'
        WHEN age BETWEEN 25 AND 34 THEN '25-34'
        WHEN age BETWEEN 35 AND 44 THEN '35-44'
        ELSE '45+'
    END AS age_group,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN is_active = 0 THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(SUM(CASE WHEN is_active = 0 THEN 1 ELSE 0 END)/COUNT(*)*100,2) AS churn_rate_pct
FROM dim_customers
GROUP BY age_group
ORDER BY churn_rate_pct DESC;


SELECT 
    churn_reason,
    COUNT(*) AS total_customers,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM fact_subscriptions WHERE status IN ('cancelled','expired'))*100,2) AS percentage
FROM fact_subscriptions
WHERE status IN ('cancelled','expired') AND churn_reason IS NOT NULL
GROUP BY churn_reason
ORDER BY total_customers DESC;


SELECT 
    DATE_FORMAT(end_date, '%Y-%m') AS churn_month,
    COUNT(*) AS churned_customers,
    ROUND(SUM(monthly_price),2) AS potential_monthly_revenue_lost
FROM fact_subscriptions
WHERE status IN ('cancelled','expired')
GROUP BY DATE_FORMAT(end_date, '%Y-%m')
ORDER BY churn_month;

SELECT
    c.channel,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    SUM(CASE WHEN s.status = 'active' THEN 1 ELSE 0 END) AS retained_customers,
    ROUND(
        SUM(CASE WHEN s.status = 'active' THEN 1 ELSE 0 END) / COUNT(DISTINCT c.customer_id) * 100,
        2
    ) AS retention_rate_pct
FROM dim_customers AS c
LEFT JOIN fact_subscriptions AS s
    ON c.customer_id = s.customer_id
GROUP BY c.channel
ORDER BY retention_rate_pct DESC;


SELECT 
    ROUND(AVG(DATEDIFF(IFNULL(end_date,CURDATE()), start_date)),1) AS avg_days_before_churn
FROM fact_subscriptions
WHERE status IN ('cancelled','expired');

WITH cohort_base AS (
    SELECT 
        c.customer_id,
        DATE_FORMAT(c.signup_date, '%Y-%m') AS cohort_month,
        MIN(DATE_FORMAT(e.event_date, '%Y-%m')) AS first_active_month
    FROM dim_customers c
    JOIN fact_events e ON c.customer_id = e.customer_id
    GROUP BY c.customer_id, cohort_month
),
cohort_metrics AS (
    SELECT 
        cohort_month,
        first_active_month,
        COUNT(DISTINCT customer_id) AS active_users
    FROM cohort_base
    GROUP BY cohort_month, first_active_month
)
SELECT 
    cohort_month,
    first_active_month,
    active_users,
    ROUND(active_users/FIRST_VALUE(active_users) OVER (PARTITION BY cohort_month ORDER BY first_active_month)*100,2) AS retention_rate_pct
FROM cohort_metrics
ORDER BY cohort_month, first_active_month;

SELECT 
    c.customer_id,
    COUNT(*) AS total_subscriptions,
    SUM(CASE WHEN s.status = 'cancelled' THEN 1 ELSE 0 END) AS churn_count
FROM dim_customers c
JOIN fact_subscriptions s ON c.customer_id = s.customer_id
GROUP BY c.customer_id
HAVING total_subscriptions > 1 AND churn_count > 0
ORDER BY churn_count DESC;

WITH plan_order AS (
    SELECT 'basic' AS plan, 1 AS plan_rank UNION ALL
    SELECT 'standard', 2 UNION ALL
    SELECT 'pro', 3
)
SELECT 
    c.customer_id,
    MIN(po.plan_rank) AS first_plan_rank,
    MAX(po.plan_rank) AS latest_plan_rank,
    CASE WHEN MAX(po.plan_rank) > MIN(po.plan_rank) THEN 'Upgraded' ELSE 'No Change' END AS plan_movement
FROM fact_subscriptions s
JOIN dim_customers c ON s.customer_id = c.customer_id
JOIN plan_order po ON s.plan = po.plan
GROUP BY c.customer_id
ORDER BY plan_movement DESC;
