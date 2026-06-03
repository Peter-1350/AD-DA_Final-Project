# FIFA 23 Players 数据集

这是一个用于统计分析与 poster 制作的足球球员数据集。当前仓库里的分析对象是 `data/FIFA 23 Players.csv`，而不是 Palmer Penguins。

## 数据来源

数据文件来自 FIFA 23 球员资料汇总，包含球员能力值、身价、工资、位置、俱乐部、国家队与多项技术属性。文件位于：

`data/FIFA 23 Players.csv`

该文件共有 17,524 行、89 列。每一行代表一名球员。

# 分析目标

围绕**“在位置与能力值相近的情况下，国籍特征如何关联并影响球员身价？”**做一份完整分析，产出 poster-ready 素材：

1. **EDA（探索性数据分析）**：
   * 核心位置（如前锋、中场、后卫）与顶级身价的分布差异。
   * 数据缺失值情况及处理方案。
   * 国籍（传统足球强国 vs 非洲/亚洲/美洲其他国家）与高身价球员的关联性。1-2 张图够用。

2. **建模（任选一个）**：
   * **多元线性回归预测 `Value(in Euro)`**：基于 `TotalStats`（总能力值）、`Positions Played`（可胜任位置）和 `Nationality`（国籍）构建模型，重点分析国籍变量的系数和显著性。
   * **多项 Logistic 回归预测身价区间**：将身价划分为高、中、低三档，使用回归模型预测球员所属的身价区间，评估国籍在其中的权重。
   * **K-means 聚类分析**：仅基于能力值和身价进行聚类，观察在相同聚类簇（同等性价比/溢价水平）内，国籍的分布结构是否存在明显偏向。

3. **结论**：
   * 哪些国籍自带最强的“身价溢价”？
   * 有没有哪些国籍在相同的能力值和位置下，身价却高度重叠或出现明显断层？

## 主要字段

| 字段名 | 类型 | 说明 |
|---|---|---|
| Known As | character | 球员常用名 |
| Full Name | character | 球员全名 |
| Overall | integer | 综合评分 |
| Potential | integer | 潜力评分 |
| Value(in Euro) | numeric | 球员身价（欧元） |
| Positions Played | character | 可胜任位置 |
| Best Position | character | 最佳位置 |
| Nationality | character | 国籍 |
| Age | integer | 年龄 |
| Height(in cm) | numeric | 身高（厘米） |
| Weight(in kg) | numeric | 体重（千克） |
| TotalStats | numeric | 总能力值 |
| BaseStats | numeric | 基础能力值 |
| Club Name | character | 俱乐部名称 |
| Wage(in Euro) | numeric | 周薪（欧元） |
| Release Clause | numeric | 解约金 |
| Club Position | character | 俱乐部位置 |
| Contract Until | integer | 合同到期年份 |
| Joined On | integer | 加盟年份 |
| On Loan | character | 是否租借 |
| Preferred Foot | character | 惯用脚 |
| Weak Foot Rating | integer | 弱脚评分 |
| Skill Moves | integer | 技能动作评分 |
| International Reputation | integer | 国际声望 |
| National Team Name | character | 国家队名称 |
| Attacking Work Rate | character | 进攻工作率 |
| Defensive Work Rate | character | 防守工作率 |
| Pace Total | integer | 速度总评分 |
| Shooting Total | integer | 射门总评分 |
| Passing Total | integer | 传球总评分 |
| Dribbling Total | integer | 控球/盘带总评分 |
| Defending Total | integer | 防守总评分 |
| Physicality Total | integer | 身体对抗总评分 |

其余列主要是更细分的技术属性和不同位置的评分。做 EDA 时可以按主题分组，不需要每列都单独展示。


## 写给分析脚本的提示

- 数据文件名包含空格，读取时要直接引用完整路径。
- 先检查列名是否存在空格或括号，必要时在代码中统一重命名。
- `Value(in Euro)` 和 `Wage(in Euro)` 这两列可能需要先清理数值格式，再做分析。
- 如果使用对数模型，要先处理 0 值，因为 `log(0)` 不可用。


