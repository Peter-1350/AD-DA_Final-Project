# 统计分析大作业框架（Harness Engineering Track）

## 作业目的

**Harness engineering**（参考 https://www.anthropic.com/engineering/harness-design-long-running-apps）是 2025-2026 年 OpenAI 和 Anthropic 共同推动的 AI 协作范式。其核心思想是：

> **当 agent 出错时，不是去改 prompt 让它"这次别错"，而是把修复刻进它的工作环境，让同类错误不再发生。**

在本大作业中：

- **agent** = codex CLI（OpenAI 的官方 agent）
- **它的工作环境** = 本仓库中的 `AGENTS.md` 文件与 `skills/` 目录
- **修复** = 修改这些 markdown 文件
- **不再发生** = 下次再运行 codex 时，它会读到更新后的 skill，自动按新规则进行分析

通过**反复运行 codex 进行数据分析 → 观察其不足 → 修改 `skills/` 中的 markdown 使其下次更好**这一循环，逐步完善 skill 库，最终形成可用于海报的图表与分析。

---

## 项目结构

```
r-stats-harness/
├── README.md              # 项目设计
├── TUTORIAL.md            # 第一次运行的教程
├── AGENTS.md              # 项目地图与全局统计纪律
├── skills/                # 【主要工作内容】统计分析指导文档
│   ├── eda_first_look.md             ← 示例
│   ├── regression_diagnostics.md     ← 示例
│   ├── hypothesis_testing.md         ← 示例
│   ├── causal_language.md            ← 示例
│   └── poster_figure_quality.md      ← 示例
├── data/
│   └── penguins/          # demo 数据
├── HARNESS_LOG.md         # 反思报告的可选模板
└── run.sh                 # 一键运行脚本
```

---

## 工作流程

```
                    ┌──────────────────────────────────┐
                    │  bash run.sh data/<your_dataset> │
                    │  （codex 读 AGENTS.md 与 skills/，│
                    │   产出 out/figs/ 与 analysis.md） │
                    └─────────────────┬────────────────┘
                                      ▼
                    ┌──────────────────────────────────┐
                    │  查看 out/，诊断与改进             │
                    │  • 图表是否清晰                    │
                    │  • 统计是否正确                    │
                    │  • 推断是否过度                    │
                    │  • 因果语言是否越界                │
                    └─────────────────┬────────────────┘
                                      ▼
                    ┌──────────────────────────────────┐
                    │  修改 skills/<对应文件>.md         │
                    │                                  │
                    └─────────────────┬────────────────┘
                                      ▼
                                （回到最上一步）
                                      ⟲ 多轮迭代
                                      ▼
                    ┌──────────────────────────────────┐
                    │  从 out/figs/ 选图、从 analysis.md│
                    │  整理结论，完成 Poster             │
                    └──────────────────────────────────┘
```

---

## 提交内容

按照课程《Project Requirements》文档中的规定，选择本 Harness Engineering track 的小组应提交以下三项材料：

1. **Poster** — 海报形式的最终成果展示（详见 Project Requirements 中的格式要求）。
2. **完善后的 `skills/` 目录** — 在已提供的 5 条示例 skill 基础上，新增若干条 skill 或对现有 skill 进行修改，以反映你们在迭代过程中对 codex 行为的修复。
3. **反思报告（markdown 格式）** — 反思 harness 在迭代过程中的演化、所观察到的 codex 统计错误，以及 skill 文件是如何修复这些错误的。反思报告的具体格式不作硬性要求；偏好结构化记录的小组可参考 `HARNESS_LOG.md` 中的逐条 entry 模板，偏好叙事式书写的小组也可自由组织。

不需要提交以下内容：

- agent 框架代码（codex 自带，无需重写）；
- lint、evaluator 等工程化基础设施。

---

## 快速开始

> 完整的环境搭建步骤见 `TUTORIAL.md`。核心步骤为：

```bash
# 1. 安装环境（详见 TUTORIAL Step 0-1）
npm install -g @openai/codex
Rscript -e 'install.packages(c("tidyverse", "broom", "performance", "effectsize", "car", "patchwork", "scales", "palmerpenguins", "skimr", "naniar"))'

# 2. 配置 API key（使用课程提供的代理，详见 TUTORIAL Step 2）
export OPENAI_API_KEY=sk-...

# 3. 运行 demo（使用交互模式，详见 TUTORIAL Step 5）
cd r-stats-harness
codex --sandbox workspace-write
# 在 TUI 中粘贴 prompt；首次出现确认提示时选择 (a) 自动批准
```

运行结束后，查看 `data/penguins/out/`：

- `figs/` — 生成的图（高分辨率 PNG）；
- `scripts/` — codex 编写的 R 脚本（可复现）；
- `analysis.md` — codex 撰写的中间分析摘要。

请仔细分析 codex 在统计任务上的行为，查看其编写的 R 代码、生成的图表与文字表述，识别其中需要改进之处。

### 分析自选数据

将自己的 CSV 文件放入 `data/<your_dataset>/`，并撰写一份 `data/<your_dataset>/README.md`，描述数据来源与分析目标；进入 codex 后，将 prompt 中的路径替换为新目录即可。

---

## Harness Engineering 三个层次的修复

观察到 codex 出现错误时，请思考"该错误应当刻在哪一层？"：

| 层 | 适用场景 | 示例 |
| --- | --- | --- |
| **AGENTS.md** | 全局纪律，每次运行均需遵守 | "任何 `lm()` 之后必须执行诊断"；"观察性数据中禁止使用因果语言" |
| **现有的 skill** | 已有 skill 涉及该类分析，但具体性不足 | "诊断不仅要执行，还要 `ggsave` 至 `figs/`" |
| **新加的 skill** | 出现已有 skill 未覆盖的新场景 | 涉及时间序列分析时，新增 `time_series.md` |
