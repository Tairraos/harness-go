# harness-go

**Harness 工程化规则文档的母本仓库。**

这里存放两份自包含的规则文档，用于把项目改造成「智能体优先（Agent-First）」的工程化形态——人类掌舵，智能体执行。文档通过下面的一键命令分发到任意目标项目，不需要再回这个仓库手动复制。

---

## 一、这两份文档是什么

它们是同一套方法论的**两个入口**：一份从空仓库起步，一份从已有代码库起步。

| 文档 | 文件名 | 适用场景 | 起点 | 核心流程 |
|---|---|---|---|---|
| **新建项目 Harness 工程化规则** | `new-project-harness-rules.md` | 从零开始建一个新项目 | 一个**空的** Git 仓库 | 需求澄清 → 技术栈确认 → 框架确认 → Day 0 骨架 → 阶段 A–G 验收 |
| **存量项目 Harness 工程化规则** | `turn-project-to-harness-rules.md` | 把**已有代码库**改造为 harness 工程化 | 一个**已有代码**的仓库 | 五阶段串行：全量扫描 → 文档对齐 → 门禁审计 → 重构落地 → 测试补全 |

**两份都「自包含」**：方法论、检查清单、模板、术语表全部内联在文档里，执行时**不需要访问任何外部链接，也不需要原始文献**。

### 怎么选

> **空仓库用《新建项目》，已有代码用《存量项目》，不要混用。**

判别很简单——你手上有没有已经存在的业务代码：

- 有 → 存量项目那份（它把「计划先获人工确认」作为第 1 条硬契约，扫描阶段禁止改业务代码）。
- 没有、要新建 → 新建项目那份（它的第一步是向你要需求，因为空仓库里 AI 推不出你要做什么）。

### 两份的关键差异

| 维度 | 新建项目 | 存量项目 |
|---|---|---|
| 框架怎么定 | 从**需求**推出技术栈，**禁止**扫描文件判定（空仓库扫不出东西） | 扫描 `src-tauri/`、`package.json` 等**证据**机械判定 |
| 流程形态 | 阶段 A–G 检查清单，可并行推进 | 五阶段**强制串行**，前一阶段验收通过才进下一阶段 |
| 头号红线 | 需求不明不得开工 | 计划未确认不得改业务代码 |
| 额外产物 | — | 改造计划 + 问题清单（`tech-debt-tracker.md`）+ 回滚方案 |

---

## 二、快速开始

### 方式 1：一键下载（推荐）

在**你自己的项目根目录**执行：

```bash
curl -fsSL https://raw.githubusercontent.com/Tairraos/harness-go/master/scripts/install-harness-rules.sh | sh
```

它会在当前目录创建 `doc/`，把两份文档下载进去，并打印出可以直接复制给 AI 的开场提示词。

> 脚本内置多源降级：某个源不可达会自动换下一个，不用手动干预；要强制指定用 `--mirror`（`--help` 列了全部参数）。

只要其中一份：

```bash
# 新建项目用这份
curl -fsSL https://raw.githubusercontent.com/Tairraos/harness-go/master/scripts/install-harness-rules.sh | sh -s -- --only new

# 改造存量项目用这份
curl -fsSL https://raw.githubusercontent.com/Tairraos/harness-go/master/scripts/install-harness-rules.sh | sh -s -- --only existing
```

换目录名（默认 `doc`）：

```bash
curl -fsSL https://raw.githubusercontent.com/Tairraos/harness-go/master/scripts/install-harness-rules.sh | sh -s -- --dir docs
```

### 方式 2：Windows（PowerShell / CMD）

`install-harness-rules.sh` 是 sh 脚本，Windows 原生 shell 跑不了；而 PowerShell 里 `curl` 只是 `Invoke-WebRequest` 的别名（**不是真的 curl**），照搬 shell 命令必错。所以 Windows 单独给了两个脚本：

**PowerShell**（Win10/11 自带 5.1，或 PowerShell 7）——先落地再执行：

```powershell
$u='https://raw.githubusercontent.com/Tairraos/harness-go/master/scripts/install-harness-rules.ps1'
$p="$env:TEMP\install-harness-rules.ps1"; iwr -UseBasicParsing $u -OutFile $p; & $p
```

> 这里**故意不用** `irm ... | iex`：`iex` 拿到的是一串字符串，而 `.ps1` 带 UTF-8 BOM，走字符串执行会有解码不确定性。先 `-OutFile` 落地再 `&` 执行，BOM 由文件读取环节处理，稳。

**CMD**——下载启动器再执行：

```cmd
curl.exe -fsSL -o "%TEMP%\install-harness-rules.cmd" https://raw.githubusercontent.com/Tairraos/harness-go/master/scripts/install-harness-rules.cmd && "%TEMP%\install-harness-rules.cmd"
```

**带参数**（PowerShell 用单横线 `-Only`，不是 `--only`）：

```powershell
.\install-harness-rules.ps1 -Only new -Dir docs
```

远程一行模式传不了参数，改用环境变量：

```powershell
$env:HARNESS_ONLY='new'; $env:HARNESS_DIR='docs'
$p="$env:TEMP\install-harness-rules.ps1"; iwr -UseBasicParsing $u -OutFile $p; & $p
```

**被执行策略拦住**时加 `-ExecutionPolicy Bypass`：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install-harness-rules.ps1
```

**用 Git Bash 或 WSL 的话**，直接用 `install-harness-rules.sh`，与 macOS / Linux 完全一致。

> ⚠️ **两个 Windows 脚本尚未在真机 Windows 上回归**（编写环境是 macOS，手上没有 Windows）。已按已知规范规避了主要坑：`.ps1` 用 UTF-8 with BOM + CRLF、避开「变量紧跟中文」的解析坑、不依赖 `curl` 别名；`.cmd` 保持**纯 ASCII**（CMD 按系统 ANSI 代码页解析 .bat/.cmd，文件里写 UTF-8 中文极易乱码），中文输出统一交给 `.ps1`。如遇问题请提 issue。

### 方式 3：纯 curl，不跑脚本

```bash
mkdir -p doc

# 新建项目
curl -fsSL -o doc/new-project-harness-rules.md \
  https://raw.githubusercontent.com/Tairraos/harness-go/master/rules/new-project-harness-rules.md

# 改造存量项目
curl -fsSL -o doc/turn-project-to-harness-rules.md \
  https://raw.githubusercontent.com/Tairraos/harness-go/master/rules/turn-project-to-harness-rules.md
```

### 方式 4：整仓 clone

```bash
git clone https://github.com/Tairraos/harness-go.git
```

---

## 三、下载下来之后怎么用

以 `doc/` 为例：

**新建项目**——新开一个 AI 会话，把这段发给它：

> 阅读 `doc/new-project-harness-rules.md`，严格按规则体系从 Day 0 搭建这个项目。
> **第一步先处理我的需求**（§3.2）：先把需求复述给我确认，再提取技术栈；如果语言或框架不明确，必须通过交互向我确认，不要自己假设。
> 技术栈定下来后，再做 §3.3 框架确认；若确认为 Tauri，必须按 §3.4 逐条向我提问，问完再动手。

**存量改造**——新开一个 AI 会话：

> 阅读 `doc/turn-project-to-harness-rules.md`，严格按其第 5 节五阶段流程对本项目执行 harness 工程化改造。
> 先只做**阶段 1**：全量扫描并输出《Harness 工程化改造计划》到 `docs/exec-plans/active/`，把问题清单写入 `docs/exec-plans/tech-debt-tracker.md`。
> **不要修改任何业务代码**，等我确认计划后再落地。

> **关于目录名**：文档正文里约定的落地路径是 `docs/HARNESS-RULES.md`（单份项目只用一份，所以能合并成这一个名字）。本仓库分发到 `doc/` 是为了让两份**并存**、便于对照；真正开工时按文档「使用方法」第 1 步把它复制/改名为 `docs/HARNESS-RULES.md` 即可。

---

## 四、文档里有什么

两份文档的骨架一致，各有侧重：

| 模块 | 内容 |
|---|---|
| **使用方法** | 五步/四步操作流程 + 可直接复制的开场提示词 |
| **核心心法 / 理念基线** | 「人类掌舵，智能体执行」的 6 条心法或 7 条核心信条 |
| **仓库结构规范** | `AGENTS.md`（≤100 行，只做地图）+ `ARCHITECTURE.md` + `docs/` 目标布局 |
| **条件式 GitHub CI** | 先判定框架；Tauri 必须走「是否配 CI / 目标平台多选 / 正式发布还是 draft」三步交互询问 |
| **架构与品味不变量** | 分层依赖 `Types → Config → Repo → Service → Runtime → UI`；T1–T10 可机械检查的规则 |
| **会话纪律** | 版本三处一致、提交单一职责、用户提示词记录 |
| **反模式清单** | 20+ 条已经踩过的坑，含后果与对策 |
| **检查清单 / 阶段验收** | 新建项目：阶段 A–G；存量项目：阶段 1–5 + 验收总矩阵 |
| **附录模板** | `AGENTS.md`、`core-beliefs.md`、`docs/CI.md`、执行计划、问题清单字段定义、术语表 |
| **生命周期与收官处置** | 文档自己是「施工图」——竣工后必须拆解归档（见下） |

**Tauri 项目的实战坑清单**是两份文档里密度最高的部分，每条都来自真实发布链路翻车：`bundle.targets` 必须 `"all"`、Windows CI 必需 `icon.ico`、固定 `ubuntu-22.04`、删 tag 重打会把已发布 Release 打回草稿、`--manifest-path` 不会加载 crate 内 cargo 配置等。

---

## 五、重要：这两份文档是「施工图」，不是永久文件

两份文档都在结尾专门写了这一点，容易被忽略：

| 阶段 | 文档在哪 | 动作 |
|---|---|---|
| **施工期** | 目标仓库 `docs/HARNESS-RULES.md`，全文 | 不删、不精简、不就地改写。**每次新会话都要先读** |
| **竣工时** | 同上 | 逐项拆解：一次性流程归档、长效契约迁移。**单独一次提交** |
| **竣工后** | 降级为 `docs/exec-plans/completed/harness-<日期>.md` | 常驻入口改为 `AGENTS.md` + `core-beliefs.md` + `ARCHITECTURE.md` |

**拆解判据**只有一句话：*它是「用来做决定的」，还是「用来约束日常的」？*

- 做决定的（要不要配 CI、build 哪些平台、发正式还是 draft）→ 决定已物化进配置文件，文档里那份归档。
- 约束日常的（不许跨层依赖、单文件不超 N 行）→ 常驻，而且要以 **linter / 结构测试**的形式常驻。

**不要做的事**：阶段没走完就删掉文档；以及——**把这个母本仓库当成垃圾删掉**。本仓库就是文档里所说的「独立模板仓库」，母本与仓库副本分开管理，每做完一个项目回来迭代一次。

---

## 六、出处

方法论的原始文献，以及三层对照：

**英文原文**

> **Harness engineering: leveraging Codex in an agent-first world** (OpenAI, 2026-02-11)

**中文翻译**

> 《工程技术：在智能体优先的世界中利用 Codex》（OpenAI，2026-02-11）

**中文解读**

> 这是 OpenAI 官方发布的一篇工程实践文献，标题里的 *harness* 指的不是测试脚手架那种狭义的 harness，而是**围绕代码库的一整套支撑结构**——环境、约束、工具与反馈回路；*agent-first* 指把智能体当作主要执行者来设计工作流。文章的核心主张是：当写代码的成本趋近于零时，工程团队的工作重心必须从"写代码"转移到"设计环境、明确意图、构建反馈回路"，而瓶颈会从编码速度变成人类的注意力。本仓库两份文档把该文献的全部可操作要点内联化，并针对「空仓库新建」与「存量代码库改造」两种场景各自展开，因此**无需再访问原文**。

---

## 七、仓库结构

```text
harness-go/
├── README.md                            # 本文件
├── LICENSE
├── rules/                               # 母本（分发源，不要手改已分发的副本）
│   ├── new-project-harness-rules.md     #   新建项目
│   └── turn-project-to-harness-rules.md #   存量项目改造
└── scripts/                             # 三个平台各一份，功能一致
    ├── install-harness-rules.sh         #   macOS / Linux / Git Bash / WSL
    ├── install-harness-rules.ps1        #   Windows PowerShell（UTF-8 with BOM）
    └── install-harness-rules.cmd        #   Windows CMD 启动器（纯 ASCII，转调 .ps1）
```

---

## License

见 [LICENSE](LICENSE)。
