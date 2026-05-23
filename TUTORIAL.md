# 运行教程

---

## 准备清单

| 项目 | 必备性 | 备注 |
| --- | --- | --- |
| Node.js 22+ | 必备 | 安装 codex CLI 的前提 |
| R 4.x+ | 必备 | 运行分析脚本 |
| OpenAI API key | 必备 | 课程提供代理 key |
| 终端的 UTF-8 设置 | 必备（中文环境） | 否则 codex 读取 skill 时会出现乱码 |
| Git Bash | 推荐 | 在 Windows 中文环境下，UTF-8 处理优于原生 cmd |

---

## Step 0：配置基础环境

### Node.js

在 [nodejs.org](https://nodejs.dorg) 下载 **LTS 版本**（目前为 24.x），按提示安装。

安装完成后，**关闭所有终端并重新打开**（不重开则读不到新安装的 node）。验证：

```cmd
node --version
npm --version
```

应分别显示 `v24.x.x` 与 `10.x.x`。

### R 包

进入 R 控制台（在 cmd 中输入 `R` 回车），执行：

```r
install.packages(c("tidyverse", "broom", "performance", "effectsize", "car", "patchwork", "scales", "palmerpenguins", "skimr", "naniar"))
```

系统会询问选择哪个镜像，可选 `China`（任意一个均可）。安装完成后输入 `q()` 退出，选 `n` 不保存工作空间。

### Git Bash（推荐）

在 [git-scm.com/download/win](https://git-scm.com/download/win) 下载 Git for Windows，安装后会自带 Git Bash。在中文环境下，Git Bash 在 UTF-8 处理上明显优于 cmd，建议后续命令均在 Git Bash 中执行。

---

## Step 1：安装 Codex CLI

```cmd
npm install -g @openai/codex
```

如果报权限错（`EACCES`），Windows 上重试一次通常即可；Linux/Mac 加 `sudo`。

验证：

```cmd
codex --version
```

---

## Step 2：配置 API key 和代理

### 课程提供的 key 与代理 URL

- API key：`sk-jzBaCDbJXCEDjs2iu4oLOeCYffJ29J839fYIbA3L18BXbohx`
- 代理 URL：`https://api.openai-proxy.org/v1`

### 设置环境变量

**在 cmd 中**（仅对当前窗口有效）：

```cmd
set OPENAI_API_KEY=sk-xxxxxxxx
```

**在 Git Bash 中**（仅对当前会话有效）：

```bash
export OPENAI_API_KEY=sk-xxxxxxxx
```

**永久设置（推荐）**："环境变量" → "编辑系统环境变量" → "环境变量" → 在用户变量中新建 `OPENAI_API_KEY`。新建完成后关闭所有终端，重新打开后生效。

### 配置 codex 走代理

打开 codex 的配置文件：

```cmd
notepad %USERPROFILE%\.codex\config.toml
```

（如提示找不到，记事本会询问是否新建，选**是**。）

将内容**完全替换**为：

```toml
model_provider = "proxy"
model = "gpt-5.4-mini"

[model_providers.proxy]
name = "Proxy"
base_url = "https://api.openai-proxy.org/v1"
wire_api = "responses"
env_key = "OPENAI_API_KEY"
```

**保存时**确认：

- 文件名：`config.toml`（不能是 `config.toml.txt`）；
- 编码：UTF-8；
- 保存类型选 "所有文件"。

### 验证连通

```cmd
codex exec "say hello in one word"
```

应在数秒内返回 "Hello"。

**常见错误**：

- `Reconnecting...` — 代理 URL 或 key 配置错误。请检查 `config.toml` 与环境变量。
- `Missing environment variable: sk-xxx` — 把 key 直接写入了 `config.toml` 的 `env_key` 字段。`env_key` 应填写变量**名**（`OPENAI_API_KEY`），而不是变量**值**。
- `wire_api = "chat" is no longer supported` — 安装的是新版 codex，但 `config.toml` 仍使用旧字段。改为 `wire_api = "responses"`。

---

## Step 3：解决中文乱码

如果 Windows 系统语言为中文，**此步必做**，否则 codex 读取 skill 文档时会出现 `鏍稿績鎬濈淮` 之类的乱码。

### 修改 PowerShell 配置文件

打开记事本：

```cmd
notepad %USERPROFILE%\Documents\WindowsPowerShell\profile.ps1
```

（找不到则新建。）

如该文件已有内容（例如 conda 自动添加的若干行），请**在文件最顶部**追加以下 4 行，**不要删除原有内容**：

```powershell
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$PSDefaultParameterValues['Get-Content:Encoding'] = 'utf8'
```

保存。

### 允许 PowerShell 加载脚本

在 cmd 中执行：

```cmd
powershell -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force"
```

### 将 cmd 切换至 UTF-8

每次打开新 cmd 窗口时，先执行：

```cmd
chcp 65001
```

永久设置："区域设置" → "管理" → "更改系统区域设置" → 勾选 "Beta：使用 Unicode UTF-8 提供全球语言支持" → 重启电脑。

---

## Step 4：解压项目

将项目压缩包解压至**路径中不含中文与空格**的位置，例如 `C:\Users\<你>\Downloads\r-stats-harness`。

```cmd
cd C:\Users\<你>\Downloads\r-stats-harness
dir
```

应可见 `AGENTS.md`、`README.md`、`skills`、`data`、`run.sh` 等。

---

## Step 5：运行 demo

### 重要：`codex exec` 与 `codex` 的区别

本项目要求 codex **写文件**（R 脚本、PNG 图）并**执行命令**（运行 R）。但是：

- `codex exec` 为非交互模式，**强制 read-only**，无法写文件；
- `codex`（不带 `exec`）为交互模式，可以写文件，但需要逐次确认写入操作。

**因此 demo 必须使用交互模式运行。**

### 运行

进入项目目录，**以交互模式启动**：

```cmd
codex --sandbox workspace-write
```

将打开一个 TUI（类似聊天窗口），底部为输入框。

### 粘贴 prompt

将以下内容**完整复制**并粘贴至输入框（右键 → 粘贴，或 `Ctrl+Shift+V`），按回车：

```
读取 data/penguins/README.md 了解数据和分析目标。在 data/penguins/out/ 下产出 R 脚本（out/scripts/01_eda.R 等）、图（out/figs/*.png，300dpi）、analysis.md。严格按 AGENTS.md 的统计纪律，开始任何分析前先读 skills/ 里对应的 skill。数据用 palmerpenguins::penguins。
```

### 同意操作

codex 会询问是否同意执行某项操作（创建文件、运行 R 命令），屏幕显示：

```
Would you like to make the following edits?
> 1. Yes, proceed (y)
  2. Yes, and don't ask again for these files (a)
  3. No, and tell Codex what to do differently (esc)
```

**第一次选 `2`**（Yes and don't ask again for these files），后续将自动批准，避免重复确认。

### 等待运行

codex 将持续运行 5–10 分钟，期间执行以下工作：

1. 读取 README 与 skills；
2. 编写 `01_eda.R`、`02_model.R`、`03_diagnostics.R` 等脚本；
3. 运行这些 R 脚本（如出现包缺失会自行处理）；
4. 将生成的图保存至 `data/penguins/out/figs/`；
5. 撰写 `analysis.md`。

期间无需手动干预。

### 退出

运行完成后会停在 `>` 提示符。此时输入 `/exit` 回车，或连续按 `Ctrl+C` 两次退出。

---

## Step 6：检查产出

```cmd
dir data\penguins\out
```

应可见 `scripts\`、`figs\`、`analysis.md`。

### 必须查看的文件

**1. analysis.md**

```cmd
type data\penguins\out\analysis.md
```

**2. figs/ 目录中的所有图**

```cmd
explorer data\penguins\out\figs
```

将打开文件夹，逐张检查图的清晰度、标题、坐标轴等。

**3. scripts/ 中的 R 代码**

```cmd
type data\penguins\out\scripts\02_model.R
```

如代码使用了 `broom::tidy()`、`ggplot2`、`performance` 等推荐包，说明 skill 已发挥作用；如果代码仍依赖 `summary(fit)` 或 `plot(fit)` 这种基础形式，则说明 skill 未充分传递，应进一步细化对应 skill 文件。

---

## Step 7：开始 harness engineering 循环

运行成功后，可正式进入 README 中所述的迭代循环：

1. 运行一次，查看产出；
2. 找出不满意之处（图表质量、用语过度、诊断缺失等）；
3. 修改 `skills/` 或 `AGENTS.md`；
4. 删除 `out/` 目录后重新运行；
5. 验证问题是否消失；
6. 在反思报告中记录此次循环；如希望使用结构化模板，可参考 `HARNESS_LOG.md`。

重新运行前请清除旧产出：

```bash
# Git Bash:
rm -rf data/penguins/out

# 或 cmd:
rmdir /s /q data\penguins\out
```

随后再次执行：

```cmd
codex --sandbox workspace-write
```
