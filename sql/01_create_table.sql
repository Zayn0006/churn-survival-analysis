-- ============================================================
-- 用户流失预警项目 - MySQL建表脚本
-- 数据集: Kaggle Telco Customer Churn (约7000条)
-- 运行方式: 在MySQL客户端中执行本文件
-- ============================================================

-- 如果已存在则删除（方便反复练习）
DROP TABLE IF EXISTS telco_churn;

-- 创建数据库（如果还没有）
CREATE DATABASE IF NOT EXISTS churn_analysis
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

USE churn_analysis;

-- ============================================================
-- 建表
-- ============================================================
CREATE TABLE telco_churn (
    customerID          VARCHAR(20)    NOT NULL COMMENT '用户ID',
    gender              VARCHAR(10)    DEFAULT NULL COMMENT '性别 (Male/Female)',
    SeniorCitizen       TINYINT        DEFAULT NULL COMMENT '是否老年用户 (0=否, 1=是)',
    Partner             VARCHAR(5)     DEFAULT NULL COMMENT '是否有伴侣 (Yes/No)',
    Dependents          VARCHAR(5)     DEFAULT NULL COMMENT '是否有家属 (Yes/No)',
    tenure              INT            DEFAULT NULL COMMENT '在网时长（月）',
    PhoneService        VARCHAR(5)     DEFAULT NULL COMMENT '是否开通电话服务 (Yes/No)',
    MultipleLines       VARCHAR(20)    DEFAULT NULL COMMENT '是否多线 (Yes/No/No phone service)',
    InternetService     VARCHAR(20)    DEFAULT NULL COMMENT '网络服务类型 (DSL/Fiber optic/No)',
    OnlineSecurity      VARCHAR(20)    DEFAULT NULL COMMENT '在线安全 (Yes/No/No internet service)',
    OnlineBackup        VARCHAR(20)    DEFAULT NULL COMMENT '在线备份 (Yes/No/No internet service)',
    DeviceProtection    VARCHAR(20)    DEFAULT NULL COMMENT '设备保护 (Yes/No/No internet service)',
    TechSupport         VARCHAR(20)    DEFAULT NULL COMMENT '技术支持 (Yes/No/No internet service)',
    StreamingTV         VARCHAR(20)    DEFAULT NULL COMMENT '网络电视 (Yes/No/No internet service)',
    StreamingMovies     VARCHAR(20)    DEFAULT NULL COMMENT '网络电影 (Yes/No/No internet service)',
    Contract            VARCHAR(20)    DEFAULT NULL COMMENT '合同类型 (Month-to-month/One year/Two year)',
    PaperlessBilling    VARCHAR(5)     DEFAULT NULL COMMENT '电子账单 (Yes/No)',
    PaymentMethod       VARCHAR(30)    DEFAULT NULL COMMENT '付款方式',
    MonthlyCharges      DECIMAL(10,2)  DEFAULT NULL COMMENT '月费',
    TotalCharges        DECIMAL(12,2)  DEFAULT NULL COMMENT '总费用',
    Churn               VARCHAR(5)     DEFAULT NULL COMMENT '是否流失 (Yes/No)',

    PRIMARY KEY (customerID),

    -- 建索引：后面查询经常按这些字段筛选/分组
    INDEX idx_churn (Churn),
    INDEX idx_contract (Contract),
    INDEX idx_tenure (tenure),
    INDEX idx_internet (InternetService),

    -- 字段注释
    -- tenure: 这个字段就是生存分析里的"生存时间"
    -- Churn: 这个字段就是生存分析里的"事件是否发生"（Yes=流失=事件发生）
    --         注意：Churn=No的用户，在生存分析里叫"删失数据(censored)"
    --         意思是：观测期内没流失，但未来可能会流失，我们只是没观察到
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='电信用户流失数据';

-- ============================================================
-- 导入数据（两种方式选一种）
-- ============================================================

-- 方式1: 用MySQL Workbench的导入功能（推荐新手）
-- 1. 打开MySQL Workbench
-- 2. 右键表名 -> Table Data Import Wizard
-- 3. 选择下载的CSV文件
-- 4. 按提示完成导入

-- 方式2: 用LOAD DATA INFILE（更快，但需要配置文件路径）
-- 注意：把下面路径改成你电脑上CSV文件的实际路径
-- 注意：Windows路径用 / 不用 \
/*
LOAD DATA INFILE 'C:/Users/你的用户名/Downloads/telco_churn.csv'
INTO TABLE telco_churn
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(customerID, gender, SeniorCitizen, Partner, Dependents, tenure,
 PhoneService, MultipleLines, InternetService, OnlineSecurity, OnlineBackup,
 DeviceProtection, TechSupport, StreamingTV, StreamingMovies,
 Contract, PaperlessBilling, PaymentMethod, MonthlyCharges, TotalCharges, Churn);
*/

-- ============================================================
-- 导入后验证查询
-- ============================================================

-- 查看总记录数
SELECT COUNT(*) AS total_rows FROM telco_churn;

-- 查看流失率
SELECT
    Churn,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM telco_churn), 2) AS percentage
FROM telco_churn
GROUP BY Churn;

-- 查看前5条数据确认导入正确
SELECT * FROM telco_churn LIMIT 5;

-- 检查TotalCharges是否有空值（这个字段有坑）
SELECT COUNT(*) AS null_total_charges
FROM telco_churn
WHERE TotalCharges IS NULL OR TotalCharges = 0;
