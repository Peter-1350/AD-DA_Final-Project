# Skill: Poster 图表质量

> 何时读:**保存任何图前必读**。这条 skill 决定你的图能不能直接进 poster。

## 核心思维

Poster 是**站在 1.5 米外、3 秒钟内能看懂**的视觉物，这意味着图表必须:

- **大字体**——观众站在远处,字小了根本看不清
- **少元素**——一张图传达一个核心信息,不要塞 5 个 subplot
- **自解释**——观众不读 caption,所以标题、坐标轴、图例必须自带含义
- **印刷质量**——300 dpi PNG,印出来不糊

最重要:**图表上要嵌入统计标注**(CI、p、效应量、n),不能让观众靠 caption 才知道。

## R 推荐姿势

### 一个 poster-ready 图的完整模板

```r
library(ggplot2)
library(scales)

# 假设我们要展示"年龄如何关联球员价值"
p <- ggplot(df, aes(x = age, y = value_eur)) +
  # 数据层
  geom_point(alpha = 0.15, size = 0.8, color = "grey40") +
  geom_smooth(method = "loess", se = TRUE,
              color = "firebrick", fill = "firebrick", alpha = 0.2) +
  # 坐标轴(必须有完整标签 + 单位 + 适当变换)
  scale_y_log10(
    labels = scales::label_dollar(prefix = "€",
                                  scale_cut = scales::cut_short_scale())
  ) +
  scale_x_continuous(breaks = seq(15, 45, 5)) +
  # 标签(标题 = 一句话讲明白这张图说什么)
  labs(
    title = "Player market value declines with age beyond ~28",
    subtitle = "FIFA 23 dataset, n = 17,946; loess fit with 95% CI",
    x = "Age (years)",
    y = "Market value (€, log scale)",
    caption = "Cross-sectional association; not a causal effect."
  ) +
  # 主题(poster 上 base_size 至少 14,推荐 16)
  theme_minimal(base_size = 16) +
  theme(
    plot.title = element_text(face = "bold", size = 18),
    plot.subtitle = element_text(color = "grey30", size = 13),
    plot.caption = element_text(color = "grey50", size = 11, hjust = 0),
    panel.grid.minor = element_blank()
  )

# 保存(300 dpi 是底线)
ggsave("out/figs/fig_age_value.png", p,
       width = 8, height = 6, dpi = 300)
```

### 关键技巧

#### 1. 标题写"finding",不写"内容"

```r
# ❌ 标题描述图的内容
labs(title = "Scatter plot of age vs value")

# ✅ 标题陈述发现
labs(title = "Player value peaks at age 28 and declines thereafter")
```

观众扫一眼标题就能拿到核心信息——这才是 poster 的图。

#### 2. 副标题嵌入完整统计

```r
# 用 sprintf 把 n、统计量、CI 拼进去,这样 caption 不用再重复
subtitle = sprintf(
  "n = %d, R² = %.2f, β_age = %.3f [%.3f, %.3f]",
  nobs(fit), glance$r.squared,
  coef$estimate[2], coef$conf.low[2], coef$conf.high[2]
)
```

#### 3. 颜色:色盲友好 + 印刷友好

```r
# ✅ 用 viridis(色盲友好,黑白印刷也能区分)
scale_color_viridis_d()
scale_fill_viridis_c()

# ✅ 或 ColorBrewer 的色盲安全调色板
scale_color_brewer(palette = "Set2")  # 分类
scale_fill_brewer(palette = "RdBu")   # 双向

# ❌ 默认的 ggplot2 红绿配色,色盲不友好
```

#### 4. 不要在 poster 图上用 ggplot2 默认主题

`theme_grey()`(默认)在 poster 上太花。用:

```r
theme_minimal(base_size = 14)  # 推荐
theme_classic(base_size = 14)  # 偏学术
theme_bw(base_size = 14)       # 中规中矩
```

#### 5. 数字格式化:用 scales 包

```r
library(scales)
scale_y_continuous(labels = label_number(big.mark = ","))     # 1,000,000
scale_y_continuous(labels = label_dollar(prefix = "€"))       # €1,000
scale_y_continuous(labels = label_percent())                  # 35%
scale_y_continuous(labels = label_comma(scale_cut = cut_short_scale()))  # 1.2M
```

#### 6. 对比图(before/after, group A/B)用 patchwork 拼

```r
library(patchwork)
p_combined <- (p_age | p_overall) +
  plot_annotation(
    title = "Two predictors of value",
    theme = theme(plot.title = element_text(size = 18, face = "bold"))
  )
ggsave("out/figs/fig_two_predictors.png", p_combined,
       width = 14, height = 5, dpi = 300)
```

#### 7. 标题长度必须匹配图宽

**陷阱**:标题陈述发现是好事,但 finding 经常写得长——一旦超过图宽,ggsave 会**默默把标题截断**(没有警告),最后 poster 上看到的是 "Flipper length is the dominant predictor in the b..."。

经验法则:
- **主标题 ≤ 60 字符**(英文,中文 ≤ 30 字符)
- **副标题 ≤ 80 字符**(英文,中文 ≤ 40 字符)
- 标准图宽 8 英寸下,这两个数能保证不被裁。

如果你的 finding 真的写不到 60 字符以内,有两个选择:

```r
# ❌ 标题太长(72 字符)
labs(title = "Flipper length is the dominant predictor in the body-mass model")

# ✅ 选项 A:浓缩到核心断言
labs(title = "Flipper length dominates body-mass prediction")  # 47 字符

# ✅ 选项 B:把详情移到副标题
labs(
  title = "Flipper length dominates",                                       # 24 字符
  subtitle = "It outweighs species in the body-mass model (n=342, R²=.78)"  # 60 字符
)

# ✅ 选项 C:加大图宽(只在两个选项都不合适时用)
ggsave("out/figs/fig_xxx.png", p, width = 12, height = 6, dpi = 300)
```

**保存前自检**(强烈建议加进每个分析脚本):

```r
# 把这个工具函数放在 00_setup.R 里,后续脚本 source 后就能用
save_poster_fig <- function(plot, path, width = 8, height = 6) {
  title <- plot$labels$title %||% ""
  subtitle <- plot$labels$subtitle %||% ""
  if (nchar(title) > 60)    warning("Title too long (", nchar(title), " chars): ", title)
  if (nchar(subtitle) > 80) warning("Subtitle too long (", nchar(subtitle), " chars): ", subtitle)
  ggsave(path, plot, width = width, height = height, dpi = 300)
}
```

这样如果不小心写超长,会立刻看到 warning,而不是等 poster 印出来才发现被裁。

## 错误示范

```r
# ❌ ggsave 不带尺寸和 dpi
ggsave("p.png", p)  # 默认尺寸不一定合适、72dpi 印出来糊

# ❌ 标题描述方法不描述发现
labs(title = "Linear regression of value on age")

# ❌ 字体太小
theme_minimal()  # base_size 默认 11,poster 上看不清

# ❌ 一张图塞太多信息
ggplot(df) +
  geom_point(aes(x, y, color = group, shape = league, size = age)) +
  facet_wrap(~ position * club, ncol = 5)  # 50 个 subplot,谁都看不懂

# ❌ 用 base R 的 plot
plot(df$age, df$value)  # 没有标题、坐标轴丑、不可印刷
```

## 不同图类型的 poster 适用性

| 图类型 | poster 适用性 | 何时用 |
|---|---|---|
| 散点 + 平滑曲线 | ★★★ | 展示连续变量关系 |
| 带误差棒的均值图 | ★★★ | 展示组间差异 |
| Forest plot(系数 + CI) | ★★★ | 展示回归结果 |
| Violin + 箱线 | ★★ | 分布比较,信息密度高 |
| 直方图 | ★ | 单变量分布,通常不进 poster(EDA 自用) |
| 热图 | ★★ | 相关矩阵、聚类结果 |
| 雷达图 | ★ | 多维比较,但容易误导 |
| 饼图 | ☆ | 几乎从不(条形图永远更好) |
| 3D 图 | ☆ | 几乎从不(3D 失真严重) |

## 最后自查清单

保存图前过一遍:

- [ ] 标题陈述发现而不是描述方法?
- [ ] **标题 ≤ 60 字符,副标题 ≤ 80 字符**(否则会被裁)?
- [ ] 副标题或 caption 含 n、统计量、CI?
- [ ] 字体在远处能看清?(`base_size ≥ 14`)
- [ ] 颜色色盲友好?
- [ ] 坐标轴有完整标签和单位?
- [ ] 数字格式化(千位分隔、单位前缀)?
- [ ] `dpi = 300`,长宽适合 poster?
- [ ] 文件名描述内容(`fig_age_value.png` 而非 `plot1.png`)?
- [ ] 因子变量没有 NA 水平？显示的回归项都是可解释的（没有泄漏的控制变量如 age_z、total_stats_z）？
