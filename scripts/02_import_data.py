"""
Telco Customer Churn 数据导入脚本
功能: 自动建库建表、清洗数据、导入MySQL
前置条件: 先修改 scripts/db_config.py 里的 MySQL 密码
"""

import sys
from pathlib import Path

# 把 scripts 目录加入路径, 确保能找到 db_config.py
sys.path.append(str(Path(__file__).parent))

import pandas as pd
from sqlalchemy import create_engine, text
from db_config import MYSQL_CONFIG, get_sqlalchemy_url


def create_table(engine):
    """创建数据库和表"""
    # 先创建数据库
    with engine.connect() as conn:
        conn.execute(text("CREATE DATABASE IF NOT EXISTS churn_analysis \
                          DEFAULT CHARACTER SET utf8mb4 \
                          DEFAULT COLLATE utf8mb4_unicode_ci;"))
        print("✅ 数据库 churn_analysis 创建/已存在")
    
    # 重新连接到指定数据库
    engine_with_db = create_engine(get_sqlalchemy_url())
    
    create_sql = """
    DROP TABLE IF EXISTS telco_churn;
    
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
        INDEX idx_churn (Churn),
        INDEX idx_contract (Contract),
        INDEX idx_tenure (tenure),
        INDEX idx_internet (InternetService)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='电信用户流失数据';
    """
    
    with engine_with_db.connect() as conn:
        for statement in create_sql.strip().split(';'):
            if statement.strip():
                conn.execute(text(statement.strip()))
        conn.commit()
    print("✅ 表 telco_churn 创建成功")
    
    return engine_with_db


def load_and_clean_data(csv_path):
    """读取CSV并清洗数据"""
    df = pd.read_csv(csv_path)
    print(f"📊 CSV读取成功: {len(df)} 行, {len(df.columns)} 列")
    
    # 处理 TotalCharges 的空格问题
    # 先把空格替换为 NaN, 再转为 float
    df['TotalCharges'] = df['TotalCharges'].replace(' ', pd.NA)
    df['TotalCharges'] = pd.to_numeric(df['TotalCharges'], errors='coerce')
    
    # 把 NaN 替换为 0.00(这些用户 tenure=0, 确实没有总费用)
    null_count = df['TotalCharges'].isna().sum()
    if null_count > 0:
        df['TotalCharges'] = df['TotalCharges'].fillna(0.0)
        print(f"⚠️ TotalCharges 有 {null_count} 个空值, 已填充为 0.0")
    
    # 确保 SeniorCitizen 是整数
    df['SeniorCitizen'] = df['SeniorCitizen'].astype(int)
    
    # 确保 MonthlyCharges 是数值
    df['MonthlyCharges'] = pd.to_numeric(df['MonthlyCharges'], errors='coerce')
    
    print("✅ 数据清洗完成")
    print(f"   - 总记录数: {len(df)}")
    print(f"   - 流失用户数: {(df['Churn'] == 'Yes').sum()}")
    print(f"   - 未流失用户数: {(df['Churn'] == 'No').sum()}")
    print(f"   - tenure=0 的用户数: {(df['tenure'] == 0).sum()}")
    
    return df


def import_to_mysql(engine, df):
    """把数据写入MySQL"""
    df.to_sql(
        name='telco_churn',
        con=engine,
        if_exists='append',
        index=False,
        method='multi',  # 批量插入,速度更快
        chunksize=1000
    )
    print(f"✅ 成功导入 {len(df)} 条数据到 MySQL")


def verify_data(engine):
    """验证导入结果"""
    with engine.connect() as conn:
        result = conn.execute(text("SELECT COUNT(*) FROM telco_churn"))
        total = result.fetchone()[0]
        print(f"\n🔍 验证: telco_churn 表共有 {total} 条记录")
        
        result = conn.execute(text("""
            SELECT Churn, COUNT(*) AS cnt,
                   ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM telco_churn), 2) AS pct
            FROM telco_churn GROUP BY Churn
        """))
        print("\n流失分布:")
        for row in result:
            print(f"   {row[0]}: {row[1]} 人 ({row[2]}%)")


if __name__ == "__main__":
    CSV_PATH = "data/WA_Fn-UseC_-Telco-Customer-Churn.csv"
    
    # 第1步: 创建数据库(先不用指定database)
    base_url = f"mysql+mysqlconnector://{MYSQL_CONFIG['user']}:{MYSQL_CONFIG['password']}@{MYSQL_CONFIG['host']}:{MYSQL_CONFIG['port']}"
    engine_base = create_engine(base_url)
    
    # 第2步: 创建表
    engine_db = create_table(engine_base)
    
    # 第3步: 加载并清洗数据
    df = load_and_clean_data(CSV_PATH)
    
    # 第4步: 导入MySQL
    import_to_mysql(engine_db, df)
    
    # 第5步: 验证
    verify_data(engine_db)
    
    print("\n导入完成，数据已写入 MySQL。")
    print("   可在 MySQL 中运行 sql/ 里的查询脚本做验证。")
