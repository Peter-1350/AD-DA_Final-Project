# FIFA 23 Players 数据集

这是一个用于统计分析与 poster 制作的足球球员数据集。当前仓库里的分析对象是 `data/FIFA 23 Players.csv`。

## 数据来源

数据文件来自 FIFA 23 球员资料汇总，包含球员能力值、身价、工资、位置、俱乐部、国家队与多项技术属性。文件位于：

`data/FIFA 23 Players.csv`

该文件共有 17,524 行、89 列。每一行代表一名球员。

# 分析目标

围绕 **"在能力值相差不大的情况下，惯用脚的左和右是否会影响球员的身价；逆足脚的能力大小又如何影响球员的身价"** 做一份完整分析，产出 poster-ready 素材：

1. **EDA（探索性数据分析）**：
   * 惯用脚（左/右）的全局分布，以及不同位置上惯用脚的比例差异。
   * 逆足脚评分（Weak Foot Rating, 1–5）的分布概览。
   * 不同惯用脚 / 逆足脚水平下身价的粗略对比。1–2 张图够用。

2. **建模**：
   * **多元线性回归预测 `Value(in Euro)`**：以 `Overall` / `TotalStats` 控制能力水平，将 `Preferred Foot`、`Weak Foot Rating` 作为核心自变量，同时控制 `Best Position`、`Age` 等协变量，量化惯用脚和逆足对身价的独立贡献。

3. **结论**：
   * 左撇子球员是否存在身价溢价或折价？
   * 弱脚评分每提高 1 分，身价预期变化多少？
   * 惯用脚和逆足的影响是否因位置而异（例如门将 vs 外场球员）？

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


## 探索目标（基于初步分析结果）
1. 