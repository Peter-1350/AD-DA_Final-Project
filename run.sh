#!/usr/bin/env bash
# run.sh — 为给定数据集生成 prompt，复制并粘贴到 codex 交互模式中运行。
#
# 用法：
#   bash run.sh data/penguins
#   bash run.sh data/fifa23
#   bash run.sh data/<your_dataset>
#
# 为何分两步执行（先生成 prompt，再手动粘贴），而不是一键调用 codex？
# 因为 `codex exec` 是只读模式，无法写入文件；可以写文件的是交互模式 `codex`，
# 但交互模式无法被 shell 脚本直接"喂入" prompt，需在 TUI 中手动粘贴。
# 这是 codex CLI 当前的设计。详见 TUTORIAL.md Step 5。

set -euo pipefail

WORK_DIR="${1:-}"
if [[ -z "$WORK_DIR" || ! -d "$WORK_DIR" ]]; then
  echo "Usage: bash run.sh <dataset_dir>"
  echo "  e.g.  bash run.sh data/penguins"
  exit 2
fi

mkdir -p "$WORK_DIR/out"/{scripts,figs}

cat <<EOF

════════════════════════════════════════════════════════════════════════════
请按以下步骤完成本次分析：
════════════════════════════════════════════════════════════════════════════

1. 启动 codex 交互模式（注意：不是 codex exec）：

       codex --sandbox workspace-write

2. 在打开的 TUI 输入框中，粘贴下面这段 prompt（整段复制）：

------------------------------ 复制这里开始 ------------------------------
读取 $WORK_DIR/README.md 了解数据和分析目标。在 $WORK_DIR/out/ 下产出 R 脚本（out/scripts/01_eda.R 等）、图（out/figs/*.png，300dpi）、analysis.md。严格按 AGENTS.md 的统计纪律，开始任何分析前先读 skills/ 里对应的 skill。
------------------------------ 复制这里结束 ------------------------------

3. codex 会询问 "Yes, proceed (y) / Yes and don't ask again (a) / No (esc)"。
   首次请按 'a'，让其后续自动批准，避免重复确认。

4. 运行结束（约 5–10 分钟）后，查看 $WORK_DIR/out/：
   - figs/        所有生成的图；
   - scripts/     codex 编写的 R 代码；
   - analysis.md  中间分析摘要。

5. 如对结果不满意，请修改 skills/ 或 AGENTS.md，然后重新运行。
   重跑前请先清除旧产出：rm -rf $WORK_DIR/out

详细教程见 TUTORIAL.md。

════════════════════════════════════════════════════════════════════════════
EOF
