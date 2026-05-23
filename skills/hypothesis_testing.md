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

违反 → `kruskal.test()`(非参数替代)+ Dunn's post-hoc。

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

## 决策树

```
比较两组连续变量?
  ├─ 正态 + 方差齐 → t.test()
  ├─ 正态 + 方差不齐 → t.test(var.equal=FALSE)
  └─ 不正态 / 小样本 → wilcox.test()

比较 ≥3 组连续变量?
  ├─ 正态 + 方差齐 → aov() + TukeyHSD()
  └─ 否则 → kruskal.test() + Dunn's post-hoc

比较两个分类变量?
  ├─ 期望频数 ≥ 5 → chisq.test()
  └─ 否则 → fisher.test()
```
