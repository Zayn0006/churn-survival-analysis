# 电信用户流失生存分析

用生存分析方法分析电信用户流失，基于 Kaggle Telco Customer Churn 数据集（7043 条记录）。主要做了 KM 生存曲线、Log-rank 检验和 Cox 比例风险回归，最后基于模型风险评分筛出预警用户名单。

## 用到的技术

- MySQL（数据存储）
- pandas / matplotlib / seaborn（数据清洗和可视化）
- lifelines（生存分析：KM曲线、Cox回归）
- scipy（Log-rank 检验）

## 怎么跑

```bash
# 1. 安装依赖
pip install -r requirements.txt

# 2. 配置 MySQL 连接（修改 scripts/db_config.py 里的密码）
# 3. 建表导入数据
mysql -u root -p < sql/01_create_table.sql
python scripts/02_import_data.py

# 4. 打开 notebook 逐个运行
jupyter notebook notebooks/
```

## 项目结构

```
├── data/                    # 数据文件（.gitignore 排除）
├── sql/                     # 建表 + EDA 查询
├── notebooks/
│   ├── 01_eda.ipynb              # 数据清洗 + EDA
│   ├── 02_survival_analysis.ipynb  # KM 生存曲线 + Log-rank 检验
│   ├── 03_cox_regression.ipynb    # Cox 回归 + 风险分层
│   └── 04_alert_report.ipynb      # 预警名单 + 挽留策略
├── output/                  # 19 张图表
├── scripts/
│   └── 02_import_data.py    # 数据导入脚本
├── requirements.txt
└── README.md
```

## 分析流程

整个分析分 5 个阶段：

1. **环境搭建**：MySQL 建表导入数据，配好 Python 虚拟环境
2. **EDA**：pandas 清洗数据，画 9 张图看流失分布规律
3. **生存分析**：KM 生存曲线看留存趋势，Log-rank 检验验证 6 组群体差异
4. **Cox 回归**：量化各因素对流失风险的影响（风险比 HR），做风险分层
5. **预警应用**：根据模型评分筛高风险用户，设计挽留策略

## 主要发现

**EDA 阶段**：
- 整体流失率 26.5%
- 按月签约用户流失率 42.7%，两年合同只有 2.8%
- 电子支票付款流失率最高（45.3%），信用卡自动扣款最低（15.2%）
- 光纤用户流失率 41.9%，明显高于 DSL（19%）

**生存分析阶段**：
- 全体用户 72 个月留存率约 60%
- 合同类型差异最大：按月签约 72 个月留存率仅 13%，两年合同保持 94%
- 6 组 Log-rank 检验均显著（p < 0.001）

**Cox 回归阶段**：
- 模型 C-index = 0.8664，区分能力较强
- 最强风险因素：电子支票付款（HR=1.80，风险增加 80%）
- 最强保护因素：两年合同（HR=0.04，风险降低 96%）
- 按风险评分四分位分层，高 vs 低风险组 Log-rank p≈0

**预警应用**：
- 筛出 1942 名高风险未流失用户（高风险 769 人 + 中高风险 1173 人）
- 高风险用户特征：99% 按月签约、45% 光纤、42% 电子支票

## 数据来源

Kaggle - Telco Customer Churn  
https://www.kaggle.com/datasets/blastchar/telco-customer-churn
