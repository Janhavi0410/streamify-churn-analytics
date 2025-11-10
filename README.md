# Streamify Customer Churn & Retention Analytics

## Objective
This project analyzes customer churn patterns and retention behavior for **Streamify**, a subscription-based streaming platform.  
The goal is to identify **drivers of churn**, determine **high-risk customer segments**, and propose strategies to **improve retention and revenue stability**.

---

## Project Structure
Streamify-Churn-Analytics/
│
├── Dashboard/               # Power BI dashboard 
├── Queries/                 # SQL scripts used for analysis
├── Data/                    # Dataset 
└── Visuals/                 # Dashboard screenshots

---

## Dashboard Preview
| KPI Overview                         | Churn Trend                             | Churn by Plan                               | Retention by Channel                                     | Churn by Age Group                        |
|--------------------------------------|-----------------------------------------|---------------------------------------------|----------------------------------------------------------|-------------------------------------------|
| ![KPI Overview](Visuals/kpi_row.png) | ![Churn Trend](Visuals/churn_trend.png) | ![Churn by Plan](Visuals/churn_by_plan.png) |![Retention by Channel](Visuals/retention_by_channel.png) | ![Churn by Age](Visuals/churn_by_age.png) |

--- 

## Key Insights
--The overall **churn rate is 18.6%**, meaning nearly **1 in 5 customers leave** the platform.
--**Churn is steadily decreasing**, indicating improved retention strategy or product value realization over time.
--The **Pro plan has the highest churn (≈20%)**, suggesting lower perceived value post-upgrade.
--Customers acquired via **YouTube & Google Ads show the strongest retention (≈75%+)**, making these the **highest value acquisition channels**.
--The **18–24 age segment churns the most**, likely due to pricing sensitivity or shorter product commitment cycles.
--Improving **first 30-day onboarding & engagement** can significantly reduce churn.

--- 

##  SQL Logic Summary - Joined customer, subscription, and payment tables to analyze complete subscription lifecycle.
- Joined customer, subscription, and payment tables to analyze complete subscription lifecycle.
- Classified churn using subscription status:status IN ('cancelled','expired') → churned status = 'active' → retained
- Calculated churn & retention rates by:
-  Month
-  -- Subscription plan type
-  -- Customer acquisition channel
-  --Customer age segment
-  --Measured **MRR (Monthly Recurring Revenue)** and **revenue loss due to churn**.

---

## Key DAX Measures (Power BI)

```DAX
Total Customers =
DISTINCTCOUNT(Customers[customer_id])

Active Customers =
CALCULATE(
    DISTINCTCOUNT(Subscriptions[customer_id]),
    Subscriptions[status] = "active"
)

Churned Customers =
CALCULATE(
    DISTINCTCOUNT(Subscriptions[customer_id]),
    Subscriptions[status] <> "active"
)

Churn Rate % =
DIVIDE([Churned Customers], [Total Customers], 0)

MRR =
CALCULATE(
    SUM(Payments[amount]),
    Subscriptions[status] = "active"
)

Revenue Lost Due to Churn =
CALCULATE(
    SUM(Payments[amount]),
    Subscriptions[status] <> "active"
)
```


## Tools Used 
Power BI    - Dashboard & visual analytics 
Power Query - Data cleaning, shaping, and transformation before modeling 
DAX         -  Creating calculated measures (Churn Rate %, Retention %, MRR, etc.)
SQL (MySQL) - Data extraction, segmentation & KPIs 
Excel / CSV - Data preprocessing 
GitHub      - Portfolio documentation & showcase 

--- 

##  Outcome & Business Value This analytics system provides strategic clarity to: 
-Reduce churn by improving onboarding and value communication
-Strengthen **Pro plan value positioning
-Prioritize **high-retention acquisition channels*
-Design **targeted retention programs** for vulnerable age segments
  
