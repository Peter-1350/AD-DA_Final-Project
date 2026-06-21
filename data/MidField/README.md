# FIFA 23 Players 数据集

这是一个用于统计分析与 poster 制作的足球球员数据集。当前仓库里的分析对象是 `data/FIFA 23 Players.csv`。

## 数据来源

数据文件来自 FIFA 23 球员资料汇总，包含球员能力值、身价、工资、位置、俱乐部、国家队与多项技术属性。文件位于：

`data/FIFA 23 Players.csv`

该文件共有 17,524 行、89 列。每一行代表一名球员。

# 分析目标

## 研究背景

在之前的回归模型（`Value ~ TotalStats + Age + Preferred Foot + Weak Foot + Position`）中，发现 **中场（Midfielder）这一位置因素的系数为负**。这引出了两个核心问题：

1. 中场球员的身价是否真的显著低于前锋或后卫等位置？
2. 如果是，这是否由中场球员群体自身的特点导致——例如他们的射门能力、年龄结构、或是其他未控制的协变量差异？

本分析围绕 **"中场球员的身价差异到底是位置标签本身所致，还是由中场球员的某项特征驱动"** 展开，产出 poster-ready 素材：

1. **EDA（探索性数据分析）**：
   * 不同位置组（GK / Defender / Midfielder / Forward）的身价分布对比。1 张图。
   * 中场球员在各能力维度（Shooting / Passing / Dribbling / Defending / Pace / Physicality）上与其他位置的差异。1 张图。
   * 中场球员的年龄、国际声望、综合评分是否系统性地不同于其他位置。可整合进上述图或单独 1 张。

2. **建模**：
   * **渐进调整回归（Progressive adjustment）**：从简单到复杂逐步加入控制变量，观察中场系数如何变化——
     * Model 1: `Value ~ Position`（原始差异）
     * Model 2: `+ TotalStats`（控制综合能力）
     * Model 3: `+ Shooting + Passing + Dribbling + Defending`（控制技能结构）
     * Model 4: `+ Age + International Reputation`（控制年龄和声望）
   * 中场系数从 Model 1 到 Model 4 的变化路径能揭示：是哪个（些）协变量"解释"了中场的身价差异。
   * 可选：**ANOVA + Tukey HSD** 做各位置组之间的两两比较，报告效应量 η²。

3. **结论**：
   * 中场球员的身价在原始对比中是否处于低位？
   * 控制综合能力后，中场系数是负的吗？控制技能结构后是否消失？
   * 中场的身价偏低，是因为市场低估这个位置，还是因为中场球员的某项能力特征导致？

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
| Crossing | integer | 传中 |
| Finishing | integer | 终结能力 |
| Heading Accuracy | integer | 头球精度 |
| Short Passing | integer | 短传 |
| Volleys | integer | 凌空 |
| Dribbling | integer | 盘带 |
| Curve | integer | 弧线 |
| Freekick Accuracy | integer | 任意球精度 |
| LongPassing | integer | 长传 |
| BallControl | integer | 控球 |
| Acceleration | integer | 加速 |
| Sprint Speed | integer | 冲刺速度 |
| Agility | integer | 灵活 |
| Reactions | integer | 反应 |
| Balance | integer | 平衡 |
| Shot Power | integer | 射门力量 |
| Jumping | integer | 弹跳 |
| Stamina | integer | 耐力 |
| Strength | integer | 力量 |
| Long Shots | integer | 远射 |
| Aggression | integer | 侵略性 |
| Interceptions | integer | 拦截 |
| Positioning | integer | 跑位 |
| Vision | integer | 视野 |
| Penalties | integer | 点球 |
| Composure | integer | 沉着 |
| Marking | integer | 盯人 |
| Standing Tackle | integer | 抢断 |
| Sliding Tackle | integer | 铲球 |

其余列主要是各位置评分。做 EDA 时可以按主题分组，不需要每列都单独展示。


## 写给分析脚本的提示

- 数据文件名包含空格，读取时要直接引用完整路径。
- 先检查列名是否存在空格或括号，必要时在代码中统一重命名。
- `Value(in Euro)` 和 `Wage(in Euro)` 这两列可能需要先清理数值格式，再做分析。
- 如果使用对数模型，要先处理 0 值，因为 `log(0)` 不可用。
- **渐进回归的核心**是保持样本一致（不要在逐步加变量时丢掉行），确保所有模型用同一批观测。
- 中场系数的变化趋势比单个模型的 p 值更重要——建议把 4 个模型的系数整合到一张 forest plot 中。
