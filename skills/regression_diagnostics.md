# Skill: 回归诊断(线性 / 广义线性模型)

> 何时读:你打算用 `lm()`、`glm()`、`lmer()` 或类似函数拟合回归模型时。

## 核心思维

回归系数本身没有意义,**除非模型假设成立**。一个高 R² 的模型,如果残差严重违反假设,它的预测、显著性检验、置信区间全部不可靠。**如果你在比较不同复杂度的回归模型,请优先报告 Adjusted R²,而不是直接拿 R² 做跨模型比较。**

诊断不是"做完模型再看一眼"——诊断是**模型的一部分**。没诊断 = 没模型。

**对 poster**:诊断图通常**不直接进 poster**(空间不够,且观众不关心),但你必须做完诊断才知道**结果图怎么呈现 + 结论怎么写**——比如发现严重异方差,你就不能在 poster 上写"X 增加 1 单位,Y 增加 β"这种线性陈述,而要改成"在我们的样本范围内观察到正向关联"。

## R 推荐姿势

### 错误写法(常见的"能跑就行")

```r
# ❌ 这样写,你不知道模型对不对
fit <- lm(y ~ x1 + x2, data = df)
summary(fit)
plot(fit)   # 弹 4 张图,但报告里看不到、没保存
```

### 正确写法

```r
library(broom)
library(performance)
library(ggplot2)

fit <- lm(log(value_eur) ~ age + overall + potential, data = df)

# 1. 系数表(整洁的 data.frame,可直接进图或表)
tidy_coef  <- broom::tidy(fit, conf.int = TRUE)
print(tidy_coef)
glance_fit <- broom::glance(fit)   # R²、AIC、BIC、F 统计量等
print(glance_fit)

# 2. 一次性诊断(残差正态性、同方差、共线性、影响点、线性性)
diag_plot <- performance::check_model(fit)
ggsave("out/figs/fig_diag_main_model.png", diag_plot,
       width = 11, height = 8, dpi = 300)

# 3. 共线性单独看(VIF > 5 警惕,> 10 严重)
vif <- performance::check_collinearity(fit)
print(vif)

# 4. 把"系数 + CI"画成 forest plot — 这张图常常进 poster
p_coef <- tidy_coef %>%
  filter(term != "(Intercept)") %>%
  ggplot(aes(x = estimate, y = reorder(term, estimate))) +
    geom_point(size = 3, color = "firebrick") +
    geom_errorbarh(aes(xmin = conf.low, xmax = conf.high), height = 0.2) +
    geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
    labs(
      title = "Regression coefficients (log value ~ age + overall + potential)",
      subtitle = sprintf("n = %d, adj. R² = %.3f", nobs(fit), glance_fit$adj.r.squared),
      x = "Coefficient estimate (log €)",
      y = NULL
    ) +
    theme_minimal(base_size = 12)
ggsave("out/figs/fig_coef_main_model.png", p_coef,
       width = 8, height = 4, dpi = 300)
```

## 诊断必查清单

- [ ] **残差正态性** — QQ 图,或 `performance::check_normality(fit)`
- [ ] **同方差性** — 残差 vs 拟合值,或 `performance::check_heteroscedasticity(fit)`
- [ ] **线性性** — 残差 vs 每个预测变量的散点不应有系统性弯曲
- [ ] **共线性** — `performance::check_collinearity(fit)`,看 VIF
- [ ] **影响点** — Cook's 距离,`performance::check_outliers(fit)`
- [ ] **(GLM)过度离散** — `performance::check_overdispersion(fit)`
- [ ] **样本量是否足够** — 经验法则: 每个系数至少 10-20 个观测

## 进 Poster 的素材

| 素材 | 进 poster 吗 | 怎么呈现 |
|---|---|---|
| Forest plot of coefficients | ✅ 通常进 | 系数 + 95% CI,横向条形 |
| 系数表 (`broom::tidy`) | 偶尔 | 简化成 3 列:term / β / 95% CI |
| 诊断图 (`check_model`) | 通常**不**进 | poster 没空间;但你必须做完才能写结论 |
| 关系散点 + 拟合曲线 | ✅ 经常进 | 比"系数"更直观,大众更容易看懂 |
| Adjusted R²、AIC | 在 figure 副标题里,尤其是比较多个模型时 | "adj. R² = 0.62, n = 17,946" |

## 常见陷阱

- **R² 高 ≠ 模型好**。R² 高但残差结构差的模型预测很差。
- **多元回归里单变量显著但联合不显著**(或反过来)— 共线性的征兆,查 VIF。
- **离群点驱动整个结果** — 拟合两次(含/不含)对比;如果结果敏感,在 poster 局限性里说明。
- **样本量小(n < 20)谈正态性** — Shapiro-Wilk 检不出问题不代表正态,小样本本来就检不出来。
- **log 变换后忘了在 poster 上说明** — y 轴标签必须写 `log(value)` 不是 `value`,系数解读也要改成"百分比变化"。
- **交互模型的组别斜率只画交互偏移而不是总斜率** — 当模型有 `position * skill` 交互项时，非参照组的真实斜率 = 主效应 + 交互偏移。若只画交互项，不同组之间的系数不可比。正确做法：对每组计算 `total_slope = main_effect + interaction_offset`，并随置信区间一起传播。

## 交互模型：正确计算分组边际效应

当模型含分类 × 连续变量的交互项（如 `position * skill`）时，最自然的 poster 呈现方式是**每个位置各自的技能斜率图**，而不是一张列满交互项的系数表。

### 错误做法：只画交互项

```r
# ❌ Attack 显示主效应斜率，其他位置只显示 Δslope——不可比
coef_int %>% filter(str_detect(term, "position_group.*:")) %>% ...
```

### 正确做法：`emmeans::emtrends()`

用一个交互模型，通过 `emtrends()` 提取每个组 × 每个连续变量的总斜率。它在内部用 `vcov()` 的全协方差矩阵做 delta method 传播，交互项和主效应之间的协方差不会被忽略。

```r
library(emmeans)
library(purrr)

# 假设你的交互模型
fit <- lm(log_value ~ position_group * (pace_z + shooting_z + passing_z + dribbling_z + defending_z + physicality_z) + age_z + total_stats_z,
          data = df)

# 为每个技能提取"每个位置的总斜率 + 正确 CI"
skill_vars <- c("pace_z", "shooting_z", "passing_z", "dribbling_z", "defending_z", "physicality_z")

skill_slopes <- map_dfr(skill_vars, function(skill) {
  emtrends(fit, ~ position_group, var = skill) %>%
    confint() %>%                          # 输出含 lower.CL / upper.CL
    as.data.frame() %>%
    rename(estimate = contains("trend")) %>% # 趋势列名 = "<skill>.trend"
    mutate(skill = skill)
})
```

### 画成四面板森林图（poster-ready）

```r
skill_slopes %>%
  mutate(skill = recode(skill,
    pace_z = "Pace", shooting_z = "Shooting",
    passing_z = "Passing", dribbling_z = "Dribbling",
    defending_z = "Defending", physicality_z = "Physicality")) %>%
  ggplot(aes(x = estimate, y = skill)) +
    geom_vline(xintercept = 0, linetype = "dashed", color = "grey55") +
    geom_errorbar(aes(xmin = lower.CL, xmax = upper.CL), width = 0.15) +
    geom_point(size = 2.5, color = "firebrick") +
    facet_wrap(~ position_group, nrow = 1) +
    labs(
      title = "Skill premiums differ by position",
      subtitle = sprintf("Total slopes from interaction model; n = %d", nobs(fit)),
      x = "Slope on log10(value + 1)",
      y = NULL
    )
ggsave("out/figs/fig_model_slopes_by_position.png", width = 14, height = 5, dpi = 300)
```

特点：
- 每张子图都是**可直接比较的总斜率**，CI 正确
- `facet_wrap(~ position_group, nrow = 1)` 四面板紧凑排列，适合 poster 横向布局
- 标题 + 副标题携带统计量，观众一眼看懂

## 对 GLM 的额外要求

逻辑回归特别注意:

- 报告 OR(优势比)而不只是 log-odds:`broom::tidy(fit, exponentiate = TRUE, conf.int = TRUE)`
- 类别不平衡时 accuracy 没意义,看 ROC-AUC、precision-recall
- 检查分离问题(complete / quasi-complete separation)

```r
# logistic 回归的标准姿势
fit_log <- glm(y ~ x1 + x2, data = df, family = "binomial")
or_table <- broom::tidy(fit_log, exponentiate = TRUE, conf.int = TRUE)
# OR > 1: x 增加,y=1 的 odds 增加
performance::check_model(fit_log)

# Poster 上画 OR 的 forest plot,加一条 OR=1 的参考线
p_or <- or_table %>%
  filter(term != "(Intercept)") %>%
  ggplot(aes(x = estimate, y = term)) +
    geom_point(size = 3) +
    geom_errorbarh(aes(xmin = conf.low, xmax = conf.high), height = 0.2) +
    geom_vline(xintercept = 1, linetype = "dashed") +  # OR=1 是"无效应"
    scale_x_log10() +
    labs(x = "Odds ratio (log scale)", y = NULL)
```
## 处理严格正值且右偏的连续数据
当目标变量是金钱（Market Value, Wage）等**严格大于 0 且极度右偏**的数据时，常见的做法是 `lm(log(y) ~ X)`。
**但 `log` 变换 OLS 有两个致命伤：**
1. 常常无法完全消除残差两端的重尾（异方差）。
2. Duan's Smearing 偏差：在对数尺度上算出的期望，用 `exp()` 还原回原始尺度时并不是均值，而是中位数，会导致对效应的系统性低估。

**更好的解法：带有 Log 链接的 Gamma 广义线性模型。**

```r
# ❌ 传统 OLS 对数变换（如果残差 QQ 图两端依然严重翘起）
fit_ols <- lm(log(value_eur) ~ age + overall, data = df)

# ✅ Gamma GLM (Log link)
# 注意：因变量直接用原始值 value_eur，不需要 log()
# family = Gamma(link = "log") 会在内部处理对数关系并正确拟合方差结构
fit_gamma <- glm(
  value_eur ~ age + overall, 
  data = df, 
  family = Gamma(link = "log")
)

# 提取系数时，由于是 log link，系数的解释与 log(y) 的 OLS 完全一样（百分比变化）
tidy_gamma <- broom::tidy(fit_gamma, exponentiate = TRUE, conf.int = TRUE) 
# exponentiate = TRUE 会直接把系数 exp(beta) 变成乘法效应比率 (Ratio)