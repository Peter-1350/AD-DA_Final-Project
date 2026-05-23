# AGENTS.md

> 这个文件是提供给 codex agent 的，定义了项目结构和必须遵守的统计纪律。

---

## 项目地图

你在一个 R 数据分析项目里工作。**你的最终用户是统计专业的本科生**——他们会从你的产出里挑选图表和结论,组装成一份学术 poster。

```
data/<dataset>/         数据 CSV + README(说明列含义和分析目标)
data/<dataset>/out/     你的工作目录
  ├── scripts/          你写的 R 脚本(每一步分析一个 .R 文件)
  ├── figs/             生成的图(高分辨率 PNG,poster-ready)
  └── analysis.md       中间分析摘要(给学生选素材用)
skills/                 统计与 R 的最佳实践
                        — 开始任何一类分析前先 cat 对应的 skill 文件
```

## 你的任务定位

**你不是在写最终报告**,而是在做"高质量的统计分析素材"——学生会从你的产出里挑东西放进 poster。这意味着:

- **图表必须 poster-ready**:大字号、清晰图注、完整坐标轴标签、统计标注(CI、p、效应量在图上可见)
- **分析必须聚焦**:学生 poster 上放不下 10 个发现,你需要识别并清晰呈现 **3-6 个核心 finding**
- **结论必须诚实**:**你的措辞决定学生 poster 上的措辞**

## 工作流程

1. 读 `data/<dataset>/README.md`,理解数据和分析目标
2. 读相关的 `skills/*.md`(见下方索引)
3. 在 `out/scripts/` 里写 R 脚本完成分析,分步骤(`01_eda.R`、`02_model.R`、`03_diagnostics.R` …)
4. 用 `Rscript` 跑,把图存到 `out/figs/`
5. 写 `out/analysis.md`,**结构化呈现**(见下方"输出要求")

## 核心统计纪律(invariants)

这些是任何分析都必须遵守的:

1. **任何 `lm()` / `glm()` / `aov()` 调用之后,必须输出诊断图**(用 `performance::check_model()` 一次性出全套是最方便的)
2. **任何假设检验前,必须验证检验前提**——t 检验/方差分析需要正态性 + 方差齐性,否则用非参替代或解释为什么仍然适用
3. **观察性数据上禁止使用因果语言**("导致 / 引起 / cause / lead to / drive / 推动"),除非有随机化或可信的因果识别策略
4. **同时报告 p 值和效应量**——p 值不告诉你重要性,效应量(Cohen's d、η²、OR、回归系数本身)才告诉你实际影响
5. **R 代码使用 tidyverse + broom 风格**——`broom::tidy()` / `broom::glance()` 而不是裸 `summary()`,输出更结构化、更易后续处理
6. **结论必须显式表达不确定性**——置信区间 > 单个点估计;"在这个样本上观察到 X" > "X 是真的"
7. **图表保存为 300dpi PNG**——poster 印出来要清晰。`ggsave(file, plot, width=W, height=H, dpi=300)`

## Skill 索引(按需读取)

不要一开始就读所有 skill。**只在你决定做对应分析时才读对应 skill**:

- `skills/eda_first_look.md` — **任何分析的第一步必读**
- `skills/regression_diagnostics.md` — 做线性/广义线性回归前读
- `skills/hypothesis_testing.md` — 做 t 检验、方差分析、卡方等检验前读
- `skills/causal_language.md` — 写讨论/结论部分前读
- `skills/poster_figure_quality.md` — **保存任何图前必读**
- `skills/<其他>` — 见 skills/ 目录

## 输出要求

### `out/figs/` 里的每张图

- 文件名清晰描述内容(`fig_eda_value_distribution.png`,不是 `plot1.png`)
- 300 dpi PNG
- 长宽适合 poster(常见:8×6 英寸 横版,6×8 英寸 竖版)
- 标题 + 完整坐标轴标签 + 单位
- 统计标注嵌在图里(回归图标 CI 带、检验图标 p 和效应量、聚类图标 silhouette)
- 颜色友好(用 `viridis` 或 `RColorBrewer` 的 colorblind-safe 调色板)

### `out/analysis.md` 的结构

```markdown
# Analysis: <dataset name>

## TL;DR
- (3-6 条 bullet,每条一句话,这是给学生 poster 用的核心 finding)

## Data
- n、变量类型、缺失情况、明显的数据质量问题
- 引用相关图:`![](figs/fig_data_overview.png)`

## EDA
- 主要发现 + 引用图

## Main analysis
- 方法选择理由
- 结果 + 配套统计图(系数表、CI、效应量)
- 引用图

## Diagnostics & robustness
- 模型假设检验、共线性、影响点
- 引用诊断图

## Conclusions
- 简洁、克制(看 skills/causal_language.md)
- 局限性单独一段

## Notes for the team
- (你的观察、对 skill 不准确处的反馈、你想说但 poster 装不下的话)
```

## 你不是被动执行

如果发现 skill 写错了、AGENTS.md 的纪律和具体任务不匹配——**不要默默忽略**。
在 `analysis.md` 末尾的 "## Notes for the team" 里写下来,学生会看到。
