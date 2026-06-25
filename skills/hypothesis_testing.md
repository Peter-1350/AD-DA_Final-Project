# Skill: 假设检验

> 何时读:你打算用 `t.test()`、`aov()`、`chisq.test()`、`wilcox.test()` 等检验函数时。

## 核心思维

假设检验问的是一个非常具体的问题:**"如果零假设是真的,我观察到这么极端的数据的概率是多少?"** 它**不**告诉你:

- 效应有多大(那是效应量的事)
- 你应不应该相信备择假设(那是贝叶斯的事)
- 在实际中是否重要(那是研究背景的事)

p 值 < 0.05 ≠ "差异重要"。p 值 > 0.05 ≠ "没差异"。

**对 poster**:检验结果在 poster 上**不要光报 p**——必须配上"差值估计 + 95% CI + 效应量"。一张精心做的图(如带误差棒的均值条形图,或 violin + 箱线图)往往比文字结果更有说服力。

## 检验前提必查

每个参数检验都有前提。**前提不验,检验结果不可信**。

### t.test() 的前提

- 两组都近似正态(或样本量大,n > 30 单组,中心极限定理够用)
- 独立同分布
- 双样本时:方差是否相等(决定是否用 Welch 校正)

```r
# 验证正态性(每组分别看)
df %>%
  group_by(group) %>%
  summarise(
    n = n(),
    shapiro_p = if (n() < 5000) shapiro.test(value)$p.value else NA,
    mean = mean(value), sd = sd(value)
  )

# 视觉检查(QQ 图常常比检验更可靠)
ggplot(df, aes(sample = value, color = group)) +
  stat_qq() + stat_qq_line() +
  facet_wrap(~ group) +
  labs(title = "Q-Q plots by group")

# 验证方差齐性
car::leveneTest(value ~ group, data = df)
```

**违反前提怎么办**:
- 不正态 + 小样本 → 用 `wilcox.test()`(Mann-Whitney U)
- 方差不齐 → `t.test(..., var.equal = FALSE)`(Welch,默认就是这个)

### aov() 的前提

- 各组正态
- 各组方差齐(Levene's test)
- 独立性

不要把 `Shapiro p < .05` 或 `Levene p < .05` 当成机械开关。特别是在大样本下，轻微偏离也几乎一定会显著；要同时看 QQ 图、组内样本量、分布形状，以及你真正想比较的是**均值/期望值**、**中位数**，还是更一般的**秩次结构**。

违反方差齐性时，直接降级为非参数检验（Kruskal-Wallis）并非唯一方案，因为 KW 检验在方差不齐时检验的不再单纯是位置移动。
推荐的处理准则：
- **异方差但数据对称性良好**：使用 Welch's ANOVA (`oneway.test(..., var.equal = FALSE)`) + Games-Howell 事后检验。
- **异方差且数据明显右偏**：不建议做秩和检验，推荐直接构建带有适当链接函数（如 Log 链接的 Gamma 分布）的广义线性模型 (GLM)，并通过 `car::Anova(fit, test="LR")` 执行方差分析。
- **货币/价格/工资这类严格正值且右偏的连续变量**：优先问自己是否要比较**期望值差异或乘性比值**。如果答案是"要"，优先选 Welch's ANOVA（在可接受时）或 `Gamma(link = "log")` / `lognormal` 建模，而不是默认 `kruskal.test()`。
- **只想比较整体秩次/随机优势，且不打算把结果解释成欧元差、均值差或百分比溢价**：这时才优先 `kruskal.test()`。

一个常见误区是：先把 `y` 取 `log()`，再做 `kruskal.test(log(y) ~ group)`，以为这样"修复了偏态"。这是错误直觉，因为秩检验对单调变换基本不变；`log()` 不会把 KW 变成均值检验，也不会让结果自动更贴近"价格差异"的研究问题。

### chisq.test() 的前提

- 期望频数 ≥ 5(每个格子)。否则用 `fisher.test()`。
- 独立性。

## R 推荐姿势

### 完整工作流(以两组比较为例)

```r
library(broom)
library(effectsize)

# 1. 先验前提
levene <- car::leveneTest(value ~ group, data = df)
print(levene)

# 2. 跑检验,转 tidy
test_result <- t.test(value ~ group, data = df, var.equal = FALSE)
tidy_test <- broom::tidy(test_result)
# 含 estimate(差值)、conf.low/conf.high、statistic、p.value、parameter(df)
print(tidy_test)

# 3. 算效应量(必须!p 值不告诉你影响大小)
d <- effectsize::cohens_d(value ~ group, data = df)
print(d)
# 解读:|d| < 0.2 小,0.2-0.5 中,> 0.8 大

# 4. 可视化(比检验结果本身更适合 poster)
library(ggplot2)
p_compare <- ggplot(df, aes(x = group, y = value, fill = group)) +
  geom_violin(alpha = 0.5, trim = FALSE) +
  geom_boxplot(width = 0.15, fill = "white", outlier.size = 0.5) +
  stat_summary(fun = mean, geom = "point", size = 3, color = "black") +
  scale_fill_brewer(palette = "Set2") +
  labs(
    title = "Group comparison",
    subtitle = sprintf("Welch's t = %.2f, df = %.1f, p = %.3f, Cohen's d = %.2f [%.2f, %.2f]",
                       tidy_test$statistic, tidy_test$parameter, tidy_test$p.value,
                       d$Cohens_d, d$CI_low, d$CI_high),
    x = NULL, y = "Value"
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "none")

ggsave("out/figs/fig_group_comparison.png", p_compare,
       width = 6, height = 5, dpi = 300)
```

### 多组比较

```r
# ANOVA + post-hoc
fit_aov <- aov(value ~ group, data = df)
tidy_aov <- broom::tidy(fit_aov)

# 效应量 (eta-squared)
eta <- effectsize::eta_squared(fit_aov, partial = FALSE)

# Tukey HSD,自动多重比较修正
tukey <- TukeyHSD(fit_aov)
tidy_tukey <- broom::tidy(tukey)
print(tidy_tukey)  # 含 contrast / estimate / conf.low/high / adj.p.value

# Forest plot of pairwise differences (poster-friendly)
p_pairs <- ggplot(tidy_tukey, aes(x = estimate, y = contrast)) +
  geom_point(size = 3) +
  geom_errorbarh(aes(xmin = conf.low, xmax = conf.high), height = 0.2) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
  labs(
    title = "Pairwise differences (Tukey HSD)",
    subtitle = sprintf("ANOVA F = %.2f, p < .001, η² = %.3f",
                       tidy_aov$statistic[1], eta$Eta2[1]),
    x = "Estimated difference [95% family-wise CI]",
    y = NULL
  ) +
  theme_minimal(base_size = 12)
```

### 多组比较:右偏正连续变量的更稳健方案

```r
library(emmeans)

# 研究问题是"不同组的期望值/价格水平是否不同?"
# 不要因为 Levene 或 Shapiro 显著就机械退回 Kruskal-Wallis

# 方案 A: 方差不齐,但仍希望比较组均值
welch_fit <- oneway.test(value ~ group, data = df, var.equal = FALSE)
print(broom::tidy(welch_fit))

# Games-Howell 适合异方差 + 不等样本量
gh <- rstatix::games_howell_test(df, value ~ group)
print(gh)

# 方案 B: 严格正值且明显右偏(如价格/工资/花费)
fit_gamma <- glm(value ~ group + age + potential,
                 data = df,
                 family = Gamma(link = "log"))

car::Anova(fit_gamma, test = "LR")

emm <- emmeans::emmeans(fit_gamma, ~ group, type = "response")
pairs_resp <- emmeans::pairs(emm, adjust = "tukey")

print(broom::tidy(emm))
print(broom::tidy(pairs_resp))
# 这里得到的是原始尺度上的期望值/比值,解释通常比秩检验更贴近业务问题
```

### 错误写法

```r
# ❌ 跑 t 检验前不验前提
t.test(value ~ group, data = df)

# ❌ 多次 t 检验不修正
for (g in groups) t.test(...)   # 多重比较问题

# ❌ 报告 "p < 0.05" 就完事
cat(sprintf("p < 0.05, significant"))   # 没有效应量、没有 CI、没有 n
```

## 进 Poster 的素材

- ✅ **检验结果可视化**(violin + 箱线、点图 + 误差棒、forest plot of pairwise diffs)
- ✅ **副标题或 caption 里嵌入完整统计**:`Welch's t(df) = X, p = Y, d = Z [CI]`
- ❌ **只放一个 p 值** — 信息量太低,且暗示二元思维
- ❌ **裸 R 输出截图** — 永远不要把 console 输出当图片

## 常见陷阱

- **多重比较不修正**:做 10 个 t 检验,假阳性概率约 40%。用 `p.adjust(..., method = "BH")` 或 `TukeyHSD()`。
- **从大样本里挖到 p < 0.05 就报告**(p-hacking)。预先注册假设;否则在 poster 局限性里坦白。
- **接受零假设**:p > 0.05 不等于"没差异"。可能是样本量不够。报告 power 或 CI。
- **小样本检验非正态**:Shapiro-Wilk 在 n < 20 时几乎检不出非正态——别因为它没拒绝就说"数据正态"。
- **t 检验比例数据**:比例(0/1)不是正态的。用逻辑回归或卡方。
- **把前提检验当成自动路由器**:看到 `Shapiro p < .05` / `Levene p < .05` 就立刻改用 `wilcox` / `kruskal`，会把原本关于均值或金额尺度的问题错误地改写成秩问题。
- **对 `log(y)` 做 Kruskal-Wallis 后声称"处理了偏态"**:`log()` 对秩检验几乎不改变结论；它没有把 KW 变成更适合解释价格差异的检验。

## 决策树

```
比较两组连续变量?
  ├─ 正态 + 方差齐 → t.test()
  ├─ 正态 + 方差不齐 → t.test(var.equal=FALSE)
  └─ 不正态 / 小样本 → wilcox.test()

比较 ≥3 组连续变量?
  ├─ 正态 + 方差齐 → aov() + TukeyHSD()
  ├─ 异方差,但仍关心组均值/期望值 → oneway.test() + Games-Howell post-hoc
  ├─ 极端右偏或严格正值,且关心金额/比值解释 → 构建 GLM (如 Gamma) 并提取 emmeans 分析
  └─ 仅关注整体分布和秩次结构 → kruskal.test() + Dunn's post-hoc
比较两个分类变量?
  ├─ 期望频数 ≥ 5 → chisq.test()
  └─ 否则 → fisher.test()
```
