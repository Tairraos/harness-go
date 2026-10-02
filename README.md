# harness-go

## 这个工具是什么

一套**自包含**的规则文档，用于把项目做成「智能体优先（Agent-First）」的 harness 工程化形态——**人类掌舵，智能体执行**。它把所需的理念、流程、验收标准、模板全部写在文档里，**执行时不需要访问任何外部链接，也不需要原始资料**。

两种起点各一份，按你手上已有的东西选：

| 你在做什么 | 用哪份 |
|---|---|
| 从零建一个新项目 | `new-project-harness-rules.md` |
| 改造一个已有的代码库 | `turn-project-to-harness-rules.md` |

判别只需一句：**手上有业务代码就用后者，没有就用前者。两份不要混用。**

本仓库是这两份文档的母本，并提供一条把它们装进任意项目的命令。

---

## 装到你自己的项目里

在**你的项目根目录**执行：

```bash
curl -fsSL https://raw.githubusercontent.com/Tairraos/harness-go/master/scripts/install-harness-rules.sh | sh
```

它会问你一句「新建还是改造」，把对应的文档放进 `docs/`，并打印出可以直接复制给 AI 的开场提示词。

落地目录固定是 `docs/`，不用改——规则文档内部约定的路径就是它。

**Windows**（PowerShell）：

```powershell
$u='https://raw.githubusercontent.com/Tairraos/harness-go/master/scripts/install-harness-rules.ps1'
$p="$env:TEMP\install-harness-rules.ps1"; iwr -UseBasicParsing $u -OutFile $p; & $p
```

CMD 下执行 `scripts\install-harness-rules.cmd`；Git Bash / WSL 用 `.sh` 那份。

---

## 装完怎么用

新开一个 AI 会话，把脚本最后打印的那句话粘给它就行。

真正开工时，把 `docs/<那份文档>.md` 复制成 `docs/HARNESS-RULES.md`——一个项目只用一份，所以合并成这一个名字。

---

## 两件要记住的事

- 文档是「**施工图**」，不是永久文件。施工期放 `docs/HARNESS-RULES.md` 全文，每次新会话先读；竣工时按文档结尾的清单逐项拆解归档——一次性的流程归档，长效契约迁到 `AGENTS.md` / `ARCHITECTURE.md`。
- 这个仓库是文档的**母本**，别删。做完一个项目回来迭代一次。

---

## 出处

**英文原文**

> Harness engineering: leveraging Codex in an agent-first world (OpenAI, 2026-02-11)

**中文翻译**

> 《工程技术：在智能体优先的世界中利用 Codex》（OpenAI，2026-02-11）

**中文解读**

> 这是 OpenAI 官方发布的一篇工程实践文献，标题里的 *harness* 指的不是测试脚手架那种狭义的 harness，而是**围绕代码库的一整套支撑结构**——环境、约束、工具与反馈回路；*agent-first* 指把智能体当作主要执行者来设计工作流。文章的核心主张是：当写代码的成本趋近于零时，工程团队的工作重心必须从「写代码」转移到「设计环境、明确意图、构建反馈回路」，而瓶颈会从编码速度变成人类的注意力。本仓库两份文档把该文献的全部可操作要点内联化，并针对「空仓库新建」与「存量代码库改造」两种场景各自展开，因此**无需再访问原文**。

---

## License

见 [LICENSE](LICENSE)。
