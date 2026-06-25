# FIFA 23 Players 数据集

这是一个用于统计分析与 poster 制作的足球球员数据集。当前仓库里的分析对象是 `data/FIFA 23 Players.csv`，而不是 Palmer Penguins。

## 数据来源

数据文件来自 FIFA 23 球员资料汇总，包含球员能力值、身价、工资、位置、俱乐部、国家队与多项技术属性。文件位于：

`data/FIFA 23 Players.csv`

该文件共有 17,524 行、89 列。每一行代表一名球员。

## 分析目标

本次分析的核心命题是：**“在控制位置与能力值变量的前提下，探讨国籍特征对球员身价的独立影响。”** 为避免多变量全局混合回归造成的混淆，我们将采取**“先分层组别，后对比身价”**的局部控制策略，产出 poster-ready 的精练可视化素材与结论：

1. **球员分层与构建同质群组（控制变量）**：
   * **位置大类划分**：基于 `Best Position` 或 `Positions Played`，将球员清洗并归类为前锋、中场、后卫、门将等核心位置。
   * **能力值分箱层级**：依据综合评分（`Overall`）为主、总能力值（`TotalStats`）为辅，将同位置的球员划分为不同的能力梯队（例如：世界级 85+、首发主力 78-84、常规轮换 70-77、替补/小将 <70）。
   * **锁定对照组**：交叉以上两步，生成若干个“位置与能力高度相近”的同质群组（如：“能力值 78-84 的中场球员组”），作为后续对比的沙盘。

2. **组内 EDA（探索性数据分析）**：
   * 在选定的几个典型同质群组内部，绘制不同主流国籍大类（传统足球强国 vs 亚洲/非洲/美洲其他国家）的身价（`Value(in Euro)`）分布可视化（如分组箱线图或小提琴图）。
   * 观察在同能力、同位置下，不同国籍的身价中位数差异以及极端高价（Outliers）的国籍归属。

3. **组内建模与统计检验（评估国籍效应）**：
   * **方差分析（ANOVA）与事后检验**：在各个同质群组内，统计检验不同国籍的球员平均身价是否存在显著性差异。
   * **局部线性回归提取溢价系数**：在特定群组内以身价对数 `log(Value)` 为因变量，`Nationality` 为核心自变量（可适度引入 `Age` 和 `Potential` 吸收年龄溢价带来的残差），计算不同国籍对比基准国籍的“身价溢价比例”。

4. **结论提炼与 Poster 呈现**：
   * **最强溢价**：哪些国籍自带最强的“身价加成”？（例如，相同能力的前锋，特定国籍比平均水平贵多少比例？）
   * **层级与位置的异质性**：这种“国籍溢价”在哪个能力层级（如顶级球星 vs 普通球员）或哪个位置领域表现得最夸张？
   * **价值洼地**：寻找绝对的“性价比高地”——在同等能力和位置下，哪些非主流足球国家的球员身价被严重低估？

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


