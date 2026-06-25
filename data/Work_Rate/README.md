# FIFA 23 Players 数据集 - 攻防投入度（Work Rate）专项研究

这是一个用于统计分析与 poster 制作的足球球员数据集。当前仓库里的分析对象是 `data/FIFA 23 Players.csv`。

## 数据来源

数据文件来自 FIFA 23 球员资料汇总，包含球员能力值、身价、工资、位置、俱乐部、国家队与多项技术属性。文件位于：

`data/FIFA 23 Players.csv`

该文件共有 17,524 行、89 列。每一行代表一名球员。

# 分析目标

围绕 **"球员的进攻与防守投入度（Attacking/Defensive Work Rate）分位置与年龄、身高、体重的关系"** 做一份完整分析，产出 poster-ready 素材：

1. **EDA（探索性数据分析）**：
   * 进攻工作率（Attacking Work Rate）与防守工作率（Defensive Work Rate）在全数据集中的分布（High/Medium/Low 的频数与比例）。
   * 分位置（Best Position）观察攻防工作率的二维交叉分布（例如：前锋的高进攻率比例是否明显高于后卫？）。
   * 年龄（Age）、身高（Height）、体重（Weight）在不同工作率级别下的箱线图或小提琴图展示，初步探索生理特征与工作率的粗略相关性。

2. **建模与统计推断**：
   * **多分类 Logistic 回归（Multinomial Logistic Regression）或有序 Logistic 回归（Ordinal Logistic Regression）**：
     由于 `Work Rate` 为分分类变量（Low < Medium < High），以 `Attacking Work Rate` 和 `Defensive Work Rate` 分别作为因变量。
   * **控制变量与协变量**：将 `Age`、`Height(in cm)`、`Weight(in kg)` 作为核心自变量，同时引入 `Best Position` 作为控制变量，量化身体特征对攻防投入度类型的独立影响。
   * **多重共线性（Multicollinearity）诊断**：身高和体重通常具有生物学上的高度相关性，必须计算并报告方差膨胀因子（VIF），以防共线性导致模型系数失真。

3. **结论**：
   * 年龄较大的球员是否倾向于拥有更低的攻防投入度（是否存在随年龄增长“踢养生足球”的趋势）？
   * 身高和体重（强壮程度）对防守投入度和进攻投入度的影响是否有显著不同？（例如：高大强壮的球员是否防守投入度更高？）
   * 身体特征和年龄对工作率的影响是否因位置而异（例如门将 vs 中场球员）？

## 主要字段

| 字段名 | 类型 | 说明 |
|---|---|---|
| Full Name | character | 球员全名 |
| Best Position | character | 最佳位置（用于位置分层/控制变量） |
| Age | integer | 年龄（核心自变量） |
| Height(in cm) | numeric | 身高（厘米，核心自变量） |
| Weight(in kg) | numeric | 体重（千克，核心自变量） |
| Attacking Work Rate | character | 进攻工作率（Low / Medium / High，因变量1） |
| Defensive Work Rate | character | 防守工作率（Low / Medium / High，因变量2） |
| TotalStats | numeric | 总能力值（可用作控制变量） |
| Stamina | integer | 体能/耐力（新增核心控制变量，解决模型全员预测 Medium 问题） |
| Aggression | integer | 侵略性/积极性（新增核心控制变量） |

## 写给分析脚本的提示（Prompt Instructions for Codex）

- **数据路径提示**：数据文件名包含空格，读取时要直接引用完整路径。
- **变量清洗提示**：`Attacking Work Rate` 和 `Defensive Work Rate` 是文本分类，请先检查是否存在缺失值（NA），并将其显式转换为因子类型（Factor），推荐按 `Low`, `Medium`, `High` 的顺序设置水平（Levels）。
- **位置聚合提示（重要）**：`Best Position` 包含 10 多个细分位置（ST, CAM, CB, GK...）。直接放入模型会导致自由度爆炸。请在建模前将位置聚类为大类（如：Forward, Midfielder, Defender, Goalkeeper），并对门将（GK）的特殊性进行单独考虑或在模型中单独诊断。
- **共线性与诊断提示**：在拟合任何逻辑回归模型（`nnet::multinom` 或 `MASS::polr`）后，**必须运行模型诊断**。特别是由于 `Height(in cm)` 和 `Weight(in kg)` 的高度相关性，必须调用 `car::vif()` 计算 VIF。如果 VIF > 5，请考虑使用身体质量指数（BMI）代替身高体重，或在分析报告中说明共线性影响。
- **可视化图表规范**：生成的 EDA 图表和回归优势图（如 Odds Ratios 森林图）必须以高分辨率（300dpi）保存至 `figs/` 目录，并确保坐标轴标签清晰、排版美观以用于 Poster 制作。
- **位置聚合与完美分离处理（核心）**：`Best Position` 包含 10 多个细分位置。请在建模前将位置聚类为大类（Forward, Midfielder, Defender, Goalkeeper）。**注意：由于 100% 的 Goalkeeper 的攻防投入度均为 Medium，这会导致多分类 Logistic 回归发生完美分离（Perfect Separation）进而系数崩溃。请在建立回归模型前，显式过滤掉门将数据（`filter(position_group != "Goalkeeper")`），将门将作为独立章节进行描述，不纳入回归方程。**
- **提高模型区分度**：为了防止模型陷入“将所有球员都预测为 Medium”的惰性状态，必须将 `Stamina` 和 `Aggression` 作为核心自变量联合拟合，并在分析报告中讨论引入这两个变量后混淆矩阵的改善情况。
- **联合分类诊断图 fig_model_diagnostics.png 的排版重构约束（核心微调）**：
  为了彻底根除 VIF 图与混淆矩阵图拼接时，各子图顶部标题（Predictor collinearity... 与 Attack model...）发生的严重文字重叠、叠影灾难，请直接对绘图脚本进行以下逻辑重构：
  1. **移除子图原有标题**：请在生成 `plot_vif`、`plot_cm_attack` 和 `plot_cm_defense` 的代码中，将各自的 `labs(title = ...)` 彻底设为 `NULL`，从根源上清空图表顶部的文字冲突。
  2. **改用字母标签定位**：使用 `patchwork` 拼图时，利用自动打标签功能标识子图（如 A, B, C），为 `plot_annotation()` 追加 `tag_levels = 'A'`。
  3. **全局大标题降维安置**：将原本冲突的标题文字，统一收纳到整个拼图的最上方或最下方作为全局副标题或说明。示例代码逻辑：
     ```R
     (plot_vif | plot_cm_attack | plot_cm_defense) + 
       plot_layout(widths = c(1.2, 2, 2)) +
       plot_annotation(
         title = "Model Checks and In-Sample Classification Fit",
         subtitle = "A: Predictor collinearity check (VIF) | B: Attack model confusion matrix | C: Defense model confusion matrix",
         theme = theme(
           plot.title = element_text(size = 12, face = "bold"),
           plot.subtitle = element_text(size = 9, color = "grey30")
         )
       )
     ```