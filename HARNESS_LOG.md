# Harness 调试日志（反思报告的可选模板）

> 本文件是反思报告的一种**可选模板**：每次发现 codex 错误、决定刻在哪一层、修复并验证，对应一条 entry。
>
> 如本小组偏好以连续叙事的形式撰写反思报告，无需使用本模板。
>
> 课程对反思报告的具体格式不作硬性要求；但所提交的反思报告应当反映：harness 在迭代过程中的演化、所观察到的 codex 统计错误、以及 skill 文件是如何修复这些错误的。

---

## 推荐格式

每一次"观察 → 定位 → 修复 → 验证"循环写一条 entry：

```markdown
## Entry NN — YYYY-MM-DD — 作者（组员姓名）

**Observed**：
（看到的 codex 错误，可贴 1–3 行原文摘录，可以是图、代码、措辞。）

**Diagnosis**：
（该错误的统计或工程本质是什么？为什么 codex 会犯？）

**Fix decided at layer**：
[ ] AGENTS.md（全局纪律）
[ ] 现有的 skills/<file>（已有 skill 不够，改它）
[ ] 新加 skills/<file>（新场景需要新 skill）

**Why this layer**：
（为什么是这一层？是否考虑过其他层？权衡是什么？）

**Change**：
（具体修改了什么。）

**Verified**：
（再次运行后问题是否消失？是否引入了新问题？）
```

---

### Entry 01 — 2026-06-03 — 牟正阳

**Observed**：
Codex运行分析同位置相近能力值不同国籍对身价的影响时，Residuals versus fitted values图中出现一条不合理的明显向下倾斜的线，

**Diagnosis**：
可能存在退役球员等特殊情况，codex没有正确处理异常值

**Fix decided at layer**：
- AGENTS.md 中加入一条 invariant，强调对极端值进行处理

**Why this layer**：
让codex能正确识别特殊情况，进行改进

**Change**：

在 AGENTS.md invariant 8 中加上“警惕并处理极端值”。

**Verified**：
重跑同一个 prompt 后，QQ图不再出现异常偏离的线


---

### Entry 01 — 2026-06-03 — 牟正阳

**Observed**：
Codex将国籍简单分为Top 10 foootball nations和Other nations，得出的相关性不合理

**Diagnosis**：
对国籍分类太粗

**Fix decided at layer**：
- AGENTS.md 中加入一条 invariant，避免对某一标签过于简单的分类

**Why this layer**：
让codex能正确处理不同分类，得出正确结论

**Change**：

在 AGENTS.md invariant 9 中加上“避免变量分类过粗”。

**Verified**：
重新运行后，分类得出的结论更加准确

---

## 示例 1 — 图表问题

### Entry 01 — 2026-04-25 — demo

**Observed**：
codex 第一次跑 penguins demo 时，在 `out/figs/` 中产出 `plot1.png`、`plot2.png`、`plot3.png`，
图均使用了 ggplot2 默认主题，字体偏小、灰底网格、无标题、坐标轴显示为 `bill_length_mm` 这种代码风格命名。

**Diagnosis**：
codex 的默认行为是"能画就行"，视觉质量远未达到海报要求。

**Fix decided at layer**：

- 现有的 `skills/poster_figure_quality.md`（已存在，但具体性不足）；
- AGENTS.md 中加入一条 invariant，强调"poster-ready"的硬性要求。

**Why this layer**：
仅靠 AGENTS.md 中的全局纪律过于抽象，codex 无法知道具体如何执行；
具体要求（base_size、dpi、标题需陈述 finding 等）放入对应 skill 更合适。

**Change**：

1. 在 `poster_figure_quality.md` 中新增"完整模板"段，给出一段可执行的 ggplot 代码；
2. 在 AGENTS.md invariant 7 中加上 "300dpi PNG"。

**Verified**：
重跑同一个 prompt 后，新图明显改善：标题、副标题、坐标轴、调色板（viridis）均符合预期。
但发现一个新问题：codex 将所有图均输出为 8×6，对分布图而言宽度不足（应为更宽的横版）。
→ 该问题在 Entry 02 中处理。

---

## 示例 2 — 图表问题

### Entry 02 — 2026-04-25 — demo

**Observed**：
跑完 penguins demo 后，查看 `data/penguins/out/figs/` 中的图，发现所有图的标题均被裁剪：

- `fig_model_coefficients.png`：标题显示为 "Flipper length is the dominant predictor in the b..."；
- `fig_eda_species_traits.png`：子图标题显示为 "Body mass differs most for Gentoo, with Adelie and Chinstrap o..."；
- 副标题同样被裁剪。

但内容本身质量较高，codex 严格按 `poster_figure_quality.md` 的要求，将标题写为陈述 finding 的句子，而非 "Coefficient plot" 这种描述性标题。

**Diagnosis**：
codex 已掌握"标题陈述 finding"这条规则，但 finding 句子写得过长（72 字符），超出 ggsave 默认宽度（8 英寸）能容纳的字符数。
ggsave 默认会静默截断，不会报错。

skill 在此处的"具体性"出现缺口：它教了 codex"该写什么样的标题"，但未规定标题长度，codex 不知道字符数会影响渲染。

**Fix decided at layer**：
现有的 `skills/poster_figure_quality.md`，加入"标题长度需匹配图宽"一节。

**Why this layer**：

- 不放在 AGENTS.md（全局纪律）中：这是图表层面的纪律，而非分析层面的纪律；
- 加在现有 skill 中："标题陈述 finding" 与 "标题不可过长" 是同一条 skill 的两面。

**Change**：

在 `poster_figure_quality.md` 中加入：

- 第 7 小节"标题长度需匹配图宽"，包含字符数限制、三种处理选项与一个 `save_poster_fig()` 自检函数；
- 自查清单中新增 "标题 ≤ 60 字符，副标题 ≤ 80 字符"。

**Verified**：
重跑 `bash run.sh data/penguins`，检查新图的标题。

**Reflection**：
本次循环依赖肉眼检查 PNG。统计 skill 的多数检查可在代码层完成（grep / lint），但仍有部分必须人工检查。因此运行结束后不应只看 `analysis.md`，还应检查全部生成产出。
