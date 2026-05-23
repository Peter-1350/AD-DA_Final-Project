# Skill: 因果语言纪律

> 何时读:写 `analysis.md` 的 Conclusions 段前,以及任何会被学生抄进 poster 的措辞之前。

## 核心思维

绝大多数数据分析作业用的是**观察性数据**(observational data)。观察性数据告诉你**关联**,不告诉你**因果**。

把"X 和 Y 相关"写成"X 导致 Y" / "X 引起 Y" / "X 推动 Y" / "X 提升 Y" / "X drives Y" / "X leads to Y"——这是**统计上的硬错误**,不是文风问题。

**对 poster 特别重要**:poster 上的措辞会被几百个路过的人快速扫过。一句"age decreases value"被当成因果声明的概率,比同样的话写在内部分析里高得多。**poster 上的因果纪律应当比 analysis.md 更严**。

## 为什么相关不等于因果

至少四种解释能产生同样的相关:

1. **X → Y**(因果,你想要的)
2. **Y → X**(反向因果)
3. **Z → X 且 Z → Y**(混淆变量)
4. **巧合**(尤其在多重比较下)

观察性数据没办法区分这四种。它们的统计输出**完全一样**。

## 安全语言 vs 危险语言

| 危险 | 安全 |
|---|---|
| age **导致** value 上升 | age 与 value **正相关** |
| 训练 **提升** 表现 | 训练时长高的球员**通常**表现更好 |
| body fat % **影响** speed | body fat % 与 speed **存在关联** |
| X 和 Y 之间有**因果关系** | X 和 Y 之间有**统计关联** |
| 提高 X 会让 Y **变好** | 在我们的样本中,X 高的观察对应 Y 高 |
| X **decreases** Y | X is **negatively associated with** Y |
| The effect of X on Y | The relationship between X and Y |

## 什么时候可以用因果语言

只有以下情况之一成立时:

1. **随机对照试验(RCT)** — 处理是随机分配的
2. **自然实验** — 有外生冲击产生准随机变异(政策切换、地理断点等)
3. **明确的因果识别策略** — 工具变量、断点回归、双重差分、合成控制等,**且严格满足相应假设**
4. **在已知 DAG 下做了正确的混淆调整** — 这要求你显式说明因果图

如果你的作业不涉及以上任何一种,**讨论部分一律用"关联 / 相关 / 共变"语言**。

## R 输出怎么避免诱导因果解读

**回归系数本身不是因果效应**——它只是"在控制了其它入模变量后,X 增加 1 单位时 Y 的条件均值变化"。

```r
tidy_coef <- broom::tidy(fit, conf.int = TRUE)

# ✅ 安全的解读模板:
# "每增加 1 单位 age,value 的条件均值平均**低** β 单位
#  (95% CI: ...),控制了 overall 和 potential 后。"

# ❌ 危险的解读模板(暗示因果):
# "age 每增加 1 单位,value 减少 β 单位。"
# "age 对 value 的影响是 β。"
# "age 对 value 有显著负向影响。"
```

**Forest plot 的标题措辞**:

```r
# ❌ "Effect of predictors on player value"
# ✅ "Associations between predictors and player value"
labs(title = "Associations between predictors and log(value)")
```

## Poster 上"研究问题"的措辞

研究问题的句式直接定调整张 poster 的因果立场:

| 危险 | 安全 |
|---|---|
| How does age affect player value? | How is age associated with player value? |
| What drives wage differences across leagues? | What predicts wage differences across leagues? |
| Effect of position on rating | Differences in rating across positions |
| Causes of overrating | Predictors of overrating |

## "讨论 / 结论"段的写法对比

### 好的讨论(进 analysis.md,可以略缩进 poster)

> 我们发现 age 与 market value 在控制 overall rating 后呈显著负相关
> (β = −0.043 log €/yr, 95% CI: [−0.046, −0.040], n = 17,946)。
> 这一关联与"年龄折扣"的市场直觉一致,但本研究为横截面观察性数据,
> **不能区分以下解释**:
> (a) 年龄确实降低了未来产出预期,使俱乐部出价更低;
> (b) 高龄球员更可能签短约,影响转会费而非真实价值;
> (c) 存在我们未观察到的混淆(如伤病史)。
> 需要纵向数据或自然实验才能识别因果。

### 坏的讨论(几乎所有学生第一稿)

> 年龄上升导致球员价值下降。这说明俱乐部应该优先签年轻球员。

后者的两个问题:
- 第一句把关联当因果(无法区分上面 abc 三种解释)
- 第二句更进一步,**给出政策建议**——政策建议要求**反事实推理**(如果俱乐部改变行为会怎样),观察性数据更没法支持

## 进 Poster 的"局限性" — 必须有

Poster 必须有 Limitations 段(哪怕只有 2 行)。常见模板:

> **Limitations**: This is a cross-sectional observational study. We report associations,
> not causal effects. Reverse causation and unmeasured confounders (e.g., injury history,
> contract terms) cannot be ruled out.

## 写作 checklist

写完讨论后逐项自查:

- [ ] 用了"导致 / cause / lead to / drive / 提升 / 降低 / 影响 / effect / impact"等词?如果用了,有没有 RCT 或因果识别支撑?
- [ ] Figure 标题用了 "Effect of X on Y" 而不是 "Association between X and Y"?
- [ ] 有没有给出政策建议或行动建议?如果有,反事实推理依据是什么?
- [ ] 讨论了反向因果的可能吗?
- [ ] 列出了潜在的混淆变量吗?
- [ ] 用了"在我们的样本中 / 在这些数据上"这类**限定**了吗?
- [ ] Poster 有 Limitations 段吗?
