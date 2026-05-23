# Palmer Penguins（Demo 数据集）

这是一个干净的小型数据集，用于跑通整套 harness 流程，以及第一次观察 codex 在统计任务上的行为。

## 数据来源

`palmerpenguins` R 包，3 个南极岛屿（Biscoe、Dream、Torgersen）上 3 个品种
（Adelie、Chinstrap、Gentoo）企鹅的形态测量数据。344 行 × 8 列。

## 数据获取

最简单的方法是让 codex 用 `palmerpenguins：：penguins`，不需要 CSV。
如果想固化成 CSV：

```r
install.packages("palmerpenguins")
library(palmerpenguins)
write.csv(penguins,"data/penguins/penguins.csv",row.names = FALSE)
```

## 列含义

| 列名 | 类型 | 说明 |
|---|---|---|
| species | factor | 品种（3 类） |
| island | factor | 岛屿（3 类） |
| bill_length_mm | numeric | 喙长（毫米） |
| bill_depth_mm | numeric | 喙深（毫米） |
| flipper_length_mm | numeric | 鳍长（毫米） |
| body_mass_g | numeric | 体重（克） |
| sex | factor | 性别（可能缺失） |
| year | integer | 观测年份 |

数据有少量缺失值，这是有意保留的（让 codex 处理）。

## 分析目标

围绕"**形态特征如何关联企鹅品种与体重？**"做一份完整分析，产出 poster-ready 素材：

1. **EDA**：三个品种的体形差异、缺失值情况、岛屿与品种的关系。1-2 张图够用。
2. **建模**（任选一个）：
   - 多元回归预测 `body_mass_g`（基于 flipper_length 和 species）
   - 多项 logistic 回归预测 species（用 `nnet：：multinom`）
   - k-means 聚类看是否能恢复品种结构
3. **结论**：哪些特征区分能力最强？有没有品种之间形态高度重叠的对？

## 应该看什么

跑完 `bash run.sh data/penguins`，看 `out/`：

- 图够不够 poster 用？字体、颜色、标题？
- `analysis.md` 里 TL;DR 够不够浓缩？
- codex 写的 R 代码够不够合适？
- 措辞有没有越界（因果语言）？

**将不足之处整合进 skill**。
