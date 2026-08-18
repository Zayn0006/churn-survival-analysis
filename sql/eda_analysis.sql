-- ============================================================
-- EDA 探索性分析常用 SQL 查询
-- 可以在 SQLyog / MySQL Workbench 中逐条执行
-- ============================================================

USE churn_analysis;

-- 1. 查看总记录数和流失率
SELECT 
    COUNT(*) AS total_users,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned_users,
    ROUND(SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS churn_rate_pct
FROM telco_churn;


-- 2. 不同合同类型的流失率
SELECT 
    Contract,
    COUNT(*) AS total,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned,
    ROUND(SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS churn_rate_pct
FROM telco_churn
GROUP BY Contract
ORDER BY churn_rate_pct DESC;


-- 3. 不同网络服务类型的流失率
SELECT 
    InternetService,
    COUNT(*) AS total,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned,
    ROUND(SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS churn_rate_pct
FROM telco_churn
GROUP BY InternetService
ORDER BY churn_rate_pct DESC;


-- 4. 不同付款方式的流失率
SELECT 
    PaymentMethod,
    COUNT(*) AS total,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned,
    ROUND(SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS churn_rate_pct
FROM telco_churn
GROUP BY PaymentMethod
ORDER BY churn_rate_pct DESC;


-- 5. 在网时长分组的流失率（用CASE WHEN手动分箱）
SELECT 
    CASE 
        WHEN tenure <= 12 THEN '0-12月'
        WHEN tenure <= 24 THEN '13-24月'
        WHEN tenure <= 48 THEN '25-48月'
        ELSE '49-72月'
    END AS tenure_group,
    COUNT(*) AS total,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned,
    ROUND(SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS churn_rate_pct
FROM telco_churn
GROUP BY tenure_group
ORDER BY churn_rate_pct DESC;


-- 6. 月费分组的流失率
SELECT 
    CASE 
        WHEN MonthlyCharges <= 35 THEN '低月费(<=35)'
        WHEN MonthlyCharges <= 65 THEN '中月费(35-65)'
        WHEN MonthlyCharges <= 95 THEN '较高月费(65-95)'
        ELSE '高月费(>95)'
    END AS charge_group,
    COUNT(*) AS total,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned,
    ROUND(SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS churn_rate_pct
FROM telco_churn
GROUP BY charge_group
ORDER BY churn_rate_pct DESC;


-- 7. 用户属性（老年、伴侣、家属）的流失率
SELECT 
    'SeniorCitizen' AS dimension,
    CASE WHEN SeniorCitizen = 1 THEN '老年' ELSE '非老年' END AS category,
    COUNT(*) AS total,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned,
    ROUND(SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS churn_rate_pct
FROM telco_churn
GROUP BY SeniorCitizen

UNION ALL

SELECT 
    'Partner' AS dimension,
    Partner AS category,
    COUNT(*) AS total,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned,
    ROUND(SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS churn_rate_pct
FROM telco_churn
GROUP BY Partner

UNION ALL

SELECT 
    'Dependents' AS dimension,
    Dependents AS category,
    COUNT(*) AS total,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned,
    ROUND(SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS churn_rate_pct
FROM telco_churn
GROUP BY Dependents;


-- 8. 流失/未流失用户的月费统计对比
SELECT 
    Churn,
    ROUND(AVG(MonthlyCharges), 2) AS avg_monthly,
    ROUND(AVG(TotalCharges), 2) AS avg_total,
    ROUND(AVG(tenure), 2) AS avg_tenure,
    COUNT(*) AS count
FROM telco_churn
GROUP BY Churn;
