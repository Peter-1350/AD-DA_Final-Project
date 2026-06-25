# 不同位置下的技能定价

这是一个基于 `data/FIFA 23 Players.csv` 的统计分析主题，目标不是先找“便宜球员”，而是回答：**不同位置的球员，哪一项具体技能与其身价提升最相关？**

## 数据来源

数据文件来自 FIFA 23 球员资料汇总，包含球员能力值、身价、工资、位置、俱乐部、国家队与多项技术属性。文件位于：

`data/FIFA 23 Players.csv`

该文件共有 17,524 行、89 列。每一行代表一名球员。

## 分析目标

本主题围绕 **“技能对身价的定价是否因位置而异”** 展开，产出 poster-ready 素材。

核心问题不是“哪项技能总体最重要”，而是：

- 前锋更看重射门还是速度？
- 中场更看重传球、盘带还是视野？
- 后卫更看重防守还是身体对抗？
- 门将是否需要单独处理，还是作为特殊位置单独建模？

这意味着，**技能变量和位置变量之间的交互项** 是本主题的重点。

### 1. EDA

先做基础探索：

- 不同位置组的身价分布
- 各位置的技能结构差异
- 不同位置中，技能与身价的粗略关系

分析必须覆盖全部 6 项核心技能——不要为了降低共线性而排除其中任何一项。所有 6 项技能必须同时出现在主效应模型和交互模型中（可以先将连续变量标准化后再进入交互项）。共线性应通过 VIF 诊断和谨慎解读来处理，而不是通过删除研究变量。

位置变量必须使用 `position_group`（4 组：Attack / Midfield / Defense / GK），不能使用 `best_position`（15 个单独位置）。

必须包含的技能：

- `Pace Total`
- `Shooting Total`
- `Passing Total`
- `Dribbling Total`
- `Defending Total`
- `Physicality Total`

### 2. 主模型：技能与位置的交互

基础模型先回答“总体上哪些技能和身价相关”：

`log10(value + 1) ~ position_group + age_z + total_stats_z + pace_z + shooting_z + passing_z + dribbling_z + defending_z + physicality_z`

然后再加入交互项，回答"不同位置的定价权重是否不同"：

`log10(value + 1) ~ position_group * (pace_z + shooting_z + passing_z + dribbling_z + defending_z + physicality_z) + age_z + total_stats_z`

这里的 `Skills` 固定为全部 6 项核心技能（见上方列表），不可删减。`position_group` 是 4 组分类变量（Attack / Midfield / Defense / GK），不可使用细粒度位置的 `best_position`。

### 3. 分位置建模

如果交互项结果过于复杂，或者你想让 poster 更清楚，可以进一步做分位置模型：

- 前锋单独建模
- 中场单独建模
- 后卫单独建模
- 门将单独建模

这样可以回答：

- 在前锋内部，哪项技能最能解释身价差异？
- 在后卫内部，哪项技能的定价最高？
- 中场球员的价值是否更依赖传球和盘带？

### 4. 结论落点

这条主题的最终落点建议写成三层：

1. **不同位置的“关键技能”并不相同**
2. **同一项技能在不同位置上的市场权重不同**
3. **如果只看总能力，会掩盖位置特异的定价机制**

## 建议的统计流程

### Step 1: EDA

先检查：

- 价格是否右偏
- 各位置人数是否均衡
- 技能之间是否高度相关
- 技能与身价的粗略关系是否随位置而变

### Step 2: 主效应模型

先建立一个没有交互项的模型：

`log10(value + 1) ~ position_group + age_z + total_stats_z + pace_z + shooting_z + passing_z + dribbling_z + defending_z + physicality_z`

用途：

- 判断哪些技能总体上和身价相关
- 为交互模型提供基线

### Step 3: 交互模型

加入位置交互项：

`log10(value + 1) ~ position_group * (pace_z + shooting_z + passing_z + dribbling_z + defending_z + physicality_z) + age_z + total_stats_z`

用途：

- 检验不同位置对技能是否有不同的"市场定价"
- 找出位置特异的关键技能

### Step 4: 分位置解释

对每个位置单独看：

- 技能回归系数
- 标准化系数
- 排名靠前的技能

这样更适合写成 poster 的结论。

## 推荐的图表

### EDA 图

- `fig_eda_position_value.png`：不同位置的身价分布
- `fig_eda_skill_profile.png`：不同位置的技能结构
- `fig_eda_skill_vs_value_by_position.png`：分位置的技能-身价关系

### 模型图

- `fig_model_coefficients_main.png`：主效应模型系数图
- `fig_model_interaction_terms.png`：交互模型系数图
- `fig_model_slopes_by_position.png`：每个位置的技能斜率图（使用 `emmeans::emtrends()` 计算总斜率）

### 诊断图

- `fig_model_diagnostics_main.png`
- `fig_model_residuals_main.png`

## 建模建议

### 模型 1: 主效应模型

`log10(value + 1) ~ position_group + age_z + total_stats_z + pace_z + shooting_z + passing_z + dribbling_z + defending_z + physicality_z`

用途：

- 得到一个总体上"哪些技能和身价相关"的答案

### 模型 2: 交互模型

`log10(value + 1) ~ position_group * (pace_z + shooting_z + passing_z + dribbling_z + defending_z + physicality_z) + age_z + total_stats_z`

用途：

- 检验技能的市场价值是否因位置而变
- 用于解释"同一项技能在不同位置的不同定价"

### 模型 3: 分位置模型

对四个 `position_group` 分别拟合：

`log10(value + 1) ~ age_z + total_stats_z + pace_z + shooting_z + passing_z + dribbling_z + defending_z + physicality_z`

用途：

- 生成位置内技能排序
- 为 poster 提供更直观的解释

## 需要注意的统计问题

- `position_group` 必须作为分类变量处理。已知它在 `00_setup.R` 中被设为 factor（Attack / Midfield / Defense / GK / Other），直接使用即可。**不要使用 `best_position`（15 个水平）代替 `position_group`。**
- 技能变量和位置高度相关，交互项会带来更强的共线性，必须检查 VIF 或其他 collinearity 指标。
- **不要为了降低共线性而删除技能变量。** 全部 6 项技能是研究问题的定义的一部分。共线性应在诊断中报告、在论文局限性中讨论，而不是通过删除变量来绕过。
- 结果解读要以“关联”而不是“因果”来写。

## 写给分析脚本的提示

- 数据文件名包含空格，读取时要直接引用完整路径。
- 先检查列名是否存在空格或括号，必要时在代码中统一重命名。
- `Value(in Euro)` 和 `Wage(in Euro)` 这两列可能需要先清理数值格式，再做分析。
- 建模前必须排除零身价球员：`filter(value_eur > 0)`。仅靠 `log10(value + 1)` 不能消除地板效应——零值压缩到 `log10(1) = 0` 会系统性地扭曲残差结构。
- 先把位置变量设为 `factor`，再放进回归模型，避免它被误当作数值变量。
- 如果要比较位置间的技能差异，优先考虑交互项或分位置模型，不要只看整体主效应。

