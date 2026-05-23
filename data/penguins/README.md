# FIFA 23 Players 数据集

这是一个用于统计分析与 poster 制作的足球球员数据集。当前仓库里的分析对象是 `data/FIFA 23 Players.csv`，而不是 Palmer Penguins。

## 数据来源

数据文件来自 FIFA 23 球员资料汇总，包含球员能力值、身价、工资、位置、俱乐部、国家队与多项技术属性。文件位于：

`data/FIFA 23 Players.csv`

该文件共有 17,524 行、89 列。每一行代表一名球员。

## 分析目标

建议围绕下面这个问题做 poster：

**哪些球员特征与 FIFA 23 中的球员身价、工资和综合能力最相关？**

适合 poster 的核心角度通常只有 3-6 个，不建议把所有变量都铺开。

可优先关注：

1. 身价与综合能力、年龄、潜力之间的关系
2. 工资与综合能力、国际声望、俱乐部层级之间的关系
3. 不同位置球员的能力结构差异
4. 左脚/右脚、技能动作、惯用工作率与球员表现的关联

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

## 数据特点

- `Value(in Euro)` 和 `Wage(in Euro)` 通常是明显右偏分布，适合考虑对数变换。
- `Overall`、`Potential`、`Age` 往往是解释身价的核心变量。
- `Best Position` 和各项能力评分适合做分组比较或降维分析。
- 画像类字段很多，做建模前应先明确只保留有意义的数值变量和少量分类变量。

## 建议的分析路线

1. **EDA**
   - 看身价、工资、年龄、综合评分的分布
   - 比较不同 `Best Position` 的能力差异
   - 查看 `Value(in Euro)` 与 `Overall`、`Potential` 的关系

2. **建模**
   - 线性回归：解释身价或工资的对数值
   - 多元回归：加入年龄、总评、潜力、国际声望、技能动作
   - 若目标是分类，也可以把球员位置或高价值球员作为分类目标

3. **稳健性检查**
   - 检查极端值、零值和右偏
   - 对回归模型做诊断图
   - 同时报告 p 值、置信区间和效应量

## 写给分析脚本的提示

- 数据文件名包含空格，读取时要直接引用完整路径。
- 先检查列名是否存在空格或括号，必要时在代码中统一重命名。
- `Value(in Euro)` 和 `Wage(in Euro)` 这两列可能需要先清理数值格式，再做分析。
- 如果使用对数模型，要先处理 0 值，因为 `log(0)` 不可用。

## 适合放进 poster 的一句话

> This dataset contains FIFA 23 player attributes for 17,524 players; the main analytic question is which features are most strongly associated with player market value and wage.

