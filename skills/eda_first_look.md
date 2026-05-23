# Skill: EDA — 第一眼看数据

> 何时读:**任何分析的第一步必读**。在任何建模或检验之前。

## 核心思维

EDA(Exploratory Data Analysis)不是"先看看再说"——它是后续每个统计决策的基础:

- 选什么模型 → 取决于变量分布、关系形态
- 选什么检验 → 取决于正态性、方差齐性、独立性
- 怎么解读结果 → 取决于异常值、缺失模式、变量尺度

EDA 的产出在 poster 里通常占 **1-2 张关键图** + **1-2 行数据描述**。所以 EDA 必须**做得全,但呈现得克制**。

## 必查清单

每次拿到新数据,逐项检查并在 `out/analysis.md` 里写:

- [ ] **n 和列数**:多少行多少列?
- [ ] **变量类型**:连续 / 有序分类 / 名义分类 / 文本 / 时间?(用 `dplyr::glimpse()` 或 `skimr::skim()` 一次性看)
- [ ] **缺失值**:每列缺多少?是不是某些行集中缺?(MCAR / MAR / MNAR 哪种?)
- [ ] **数值变量分布**:对称?偏态?多峰?有没有明显的"特殊值"如 -1、0、99?
- [ ] **分类变量**:每个水平多少观测?有没有罕见类别(可能要合并)?
- [ ] **极端值**:用箱线图或 z-score 找;问"它是数据错误还是真实极端"?
- [ ] **变量间关系**:目标变量(如果有)和主要协变量的散点 / 箱线图;协变量之间的相关
- [ ] **重复值 / 重复观测**:`anyDuplicated()`,如果有要追究

## R 推荐姿势

### 第一眼:全数据概览

```r
library(tidyverse)
library(skimr)

df <- readr::read_csv("data/fifa23/fifa23.csv", show_col_types = FALSE)

# 一行看全貌:类型、n、缺失、分位数、直方图
skimr::skim(df)

# 缺失值热图(可视化,可进 poster)
library(naniar)
gg_miss_var(df) +
  labs(title = "Missingness by variable",
       x = NULL, y = "# missing")
ggsave("out/figs/fig_missingness.png", width = 7, height = 4, dpi = 300)
```

### 数值变量的分布

```r
# 多变量分布并排(用 patchwork 拼图)
library(patchwork)

plot_dist <- function(var) {
  ggplot(df, aes(x = .data[[var]])) +
    geom_histogram(bins = 40, fill = "steelblue", alpha = 0.8) +
    labs(title = var, x = NULL, y = NULL) +
    theme_minimal(base_size = 11)
}

p <- (plot_dist("age") | plot_dist("overall") | plot_dist("value_eur")) +
     plot_annotation(title = "Distribution of key numeric variables",
                     subtitle = paste("n =", nrow(df)))
ggsave("out/figs/fig_eda_distributions.png", p, width = 10, height = 4, dpi = 300)
```

### 关键关系:目标变量 vs 主要预测变量

```r
# 散点 + 平滑曲线,显示关系形态(线性?非线性?异方差?)
p_age_value <- ggplot(df, aes(x = age, y = value_eur)) +
  geom_point(alpha = 0.2, size = 0.6) +
  geom_smooth(method = "loess", se = TRUE, color = "firebrick") +
  scale_y_log10(labels = scales::label_dollar(prefix = "€", scale_cut = scales::cut_short_scale())) +
  labs(
    title = "Player market value vs age",
    subtitle = "log scale; loess fit with 95% CI",
    x = "Age (years)",
    y = "Market value (EUR, log)"
  ) +
  theme_minimal(base_size = 12)

ggsave("out/figs/fig_eda_age_value.png", p_age_value, width = 7, height = 5, dpi = 300)
```

### 不要这样写

```r
# ❌ 一次出 50 张直方图全保存——poster 只用 1-2 张,其它都是噪音
for (col in names(df)) {
  hist(df[[col]])
}

# ❌ 用 base R 的 plot,没有标题、没有标签、不能进 poster
plot(df$age, df$value_eur)

# ❌ 不打 dpi 就 ggsave,印出来糊
ggsave("p.png", p)
```

## 进 Poster 的 EDA 素材

通常一份 poster 在 EDA 部分**最多放 1-2 张图**,且必须服务于研究问题:

- ✅ **服务于研究问题的图**:如果研究问题是"年龄如何关联价值",放年龄-价值散点图;如果是"位置聚类",放属性间的散点矩阵
- ❌ **纯描述性的图**:每个变量的直方图、缺失值热图——这些是给你们(分析师)看的,**不进 poster**(除非缺失本身就是研究问题)

文字部分,EDA 在 poster 上通常是**一句话**:

> "Data: FIFA 23 player ratings (n=18,539). After excluding players with missing wage data (3.2%), 17,946 retained. Value is right-skewed (median €1.1M, IQR €425K-€3.2M); analyses use log-transformed value."

## 常见陷阱

- **"数据看起来正常"就跳过 EDA** → 后续建模一定有惊喜
- **EDA 时间过长** → 30 分钟看出问题,2 小时还没看出来就该开始建模再回头补
- **把 EDA 图全塞进 poster** → poster 是结论,不是工作笔记
- **忽视缺失模式** → 系统性缺失(如"低收入球员没工资数据")会偏倚后续所有分析
