[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.18723722.svg)](https://doi.org/10.5281/zenodo.18723722)

# Paper Replication Agent

A structured Claude Code workflow for **empirically replicating published research**, created by 朱晨 @ China Agricultural University. Currently used with UK Biobank (UKB) and Chinese survey datasets (CHNS, CHARLS). Special thanks to Pedro H. C. Sant'Anna for the claude-code-my-workflow repository, which inspired this workflow.

You describe a paper; Claude plans the replication approach, writes R scripts, validates outputs against published targets, documents discrepancies, and saves a validation report — like a research assistant who handles the full pipeline.

---

## 中文介绍

**论文复现智能体** — 面向经济学、流行病学等实证研究的结构化论文复现工作流，基于 Claude Code 构建。

### 这是什么？

本项目将 Claude Code 配置为一个**论文复现研究助手**：你提供论文 PDF 和数据集，Claude 自动完成从阅读论文、整理目标指标、编写 R 脚本、运行验证，到生成复现报告的完整流程——无需手动管理每一步。

适用于：
- **经济学实证论文**（DID、RD、IV、固定效应、工具变量等计量方法）
- **流行病学与遗传社科研究**（UK Biobank、CHNS、CHARLS 等大型队列/调查数据）
- **中文社科文献复现**（中国国家健康与营养调查、中国健康与养老追踪调查等）
- 任何提供回归表格、样本描述统计或因果识别策略的实证论文

### 核心工作流（六阶段复现流程）

```
阅读论文  →  数据审核  →  编写脚本  →  验证结果  →  记录差异  →  生成报告
```

| 阶段 | 内容 |
|------|------|
| **0. 论文解析** | 读取 PDF，提取所有实证目标（回归系数、样本量、显著性）到 `replication_targets.md` |
| **1. 数据审核** | 核查样本构成是否与论文描述一致（N、变量定义、纳入/排除标准） |
| **2. 脚本翻译** | 将论文方法（含 Stata 原始代码）转写为可运行的 R 脚本，严格对齐原始设定 |
| **3. 结果验证** | 将输出与目标值逐一比对，按容差阈值判定 PASS / NEAR / FAIL |
| **4. 差异记录** | 对每个 NEAR/FAIL 结果进行溯源分析，记录尝试方案和最终解释 |
| **5. 复现报告** | 保存 `validation_report.md`，包含完整的方法说明与结果对比表 |

### 容差标准

| 统计量 | 通过标准 |
|--------|----------|
| 样本量 N | 精确匹配 |
| 点估计（β、OR、HR） | ±0.01 |
| 标准误 | ±0.05 |
| p 值 / 显著性 | 同一显著性区间 |
| 零效应系数（\|t\|<2） | 同一区间即通过（符号翻转记为 NOTE，不算 FAIL） |

### 为什么适合经济学论文复现？

1. **计划先行**：每次任务前进入计划模式，列出复现步骤并等待确认，避免盲目执行
2. **严格对标**：逐表、逐列记录目标值，结果差异有据可查
3. **Stata → R 转换**：内置常见陷阱提示（cluster SE、固定效应吸收、权重处理等）
4. **质量门控**：80 分提交 / 90 分发布 / 95 分卓越，每次复现都有量化评估
5. **上下文持久化**：会话压缩后自动恢复进度，长周期复现任务不丢失状态

### 作者

**朱 晨 | 遗传社科研究**  
Chen Zhu | China Agricultural University (CAU)

---

## Active Replications

| Paper | Data | Status | Key Finding |
|-------|------|--------|-------------|
| van den Berg et al. (2025) | UKB | COMPLETE | Prenatal sugar derationing → education |
| 江求川、张克中 (2013) | CHNS 2006 | PARTIAL | Female height income premium replicated |
| 工资制度变化与员工效用 | CHNS | PARTIAL | DID wage coefficient matched |
| Gracner et al. (2024) | UKB | IN PROGRESS | Sugar tax effects |

---

## Quick Start

### 1. Clone

```bash
git clone https://github.com/maxwell2732/paper-replicate-agent-demo.git
cd paper-replicate-agent-demo
```

### 2. Add data & paper

Place the paper PDF in `papers/[PaperName]/` and your dataset in `data/` (gitignored).

### 3. Start Claude Code and describe the task

```bash
claude
```

> I want to replicate [Paper Author (Year)]. The PDF is in `papers/[PaperName]/`. Data is in `data/[path]`. Please enter plan mode, read the paper, identify all empirical targets, and plan the replication.

Claude will read the paper, inventory the data, draft a step-by-step plan, wait for your approval, then implement — running scripts, checking outputs against tolerance thresholds, and saving a validation report.

---

## How It Works

### Contractor Mode

For any non-trivial task, Claude enters plan mode first. You approve the plan, then it implements → verifies → reviews → fixes → scores. Say "just do it" for autonomous execution.

### Replication Pipeline

| Phase | What Happens |
|-------|-------------|
| **0. Paper Intake** | Read paper; record all empirical targets in `quality_reports/[paper]_replication_targets.md` |
| **1. Data Audit** | Verify sample matches paper description (N, key variables, inclusion criteria) |
| **2. Translate & Execute** | Write R scripts; match original specification exactly |
| **3. Verify Match** | Compare outputs against targets within tolerance thresholds |
| **4. Document Discrepancies** | Investigate every near-miss; explain what we tried |
| **5. Report** | Save `replications/[paper]/validation_report.md` |

### Tolerance Thresholds

| Quantity | Tolerance |
|----------|-----------|
| Sample sizes (N) | Exact match |
| Point estimates (β, OR, HR) | ±0.01 |
| Standard errors | ±0.05 |
| P-values | Same significance bracket |
| Null coefficients (\|t\|<2 in both) | Same bracket (sign flip = NOTE, not FAIL) |

### Quality Gates

- **80** — commit threshold
- **90** — PR threshold
- **95** — excellence

---

## What's Included

<details>
<summary><strong>4 agents · 11 skills · 15 rules</strong> (click to expand)</summary>

### Agents (`.claude/agents/`)

| Agent | What It Does |
|-------|-------------|
| `domain-reviewer` | Senior epidemiology referee — causal assumptions, methods, code-theory alignment |
| `r-reviewer` | R code quality, reproducibility, domain correctness |
| `proofreader` | Grammar, typos, consistency in reports |
| `verifier` | End-to-end task completion verification |

### Skills (`.claude/skills/`)

| Skill | What It Does |
|-------|-------------|
| `/replicate-paper` | Full 6-phase replication pipeline |
| `/data-analysis` | End-to-end R analysis with publication-ready output |
| `/review-r` | R code review |
| `/proofread` | Proofread a file |
| `/review-paper` | Manuscript review: structure, methods, referee objections |
| `/lit-review` | Literature search and synthesis |
| `/research-ideation` | Generate research questions and empirical strategies |
| `/interview-me` | Interactive interview to formalize a research idea |
| `/devils-advocate` | Challenge design decisions |
| `/commit` | Stage, commit, PR, and merge |
| `/deploy` | Deploy workflow |

### Rules (`.claude/rules/`)

**Always-on:**

| Rule | What It Enforces |
|------|-----------------|
| `plan-first-workflow` | Plan mode for non-trivial tasks; context preservation |
| `orchestrator-protocol` | Contractor loop: implement → verify → review → fix → score |
| `session-logging` | Post-plan, incremental, and end-of-session logging |

**Path-scoped:**

| Rule | Triggers On | What It Enforces |
|------|------------|-----------------|
| `replication-protocol` | `replications/**` | 6-phase replication; Stata→R pitfalls |
| `quality-gates` | `*.R`, `*.py`, `reports/**` | 80/90/95 scoring rubric |
| `r-code-conventions` | `*.R` | Reproducibility, seed, paths, figure standards |
| `python-code-conventions` | `*.py` | Scientific Python coding standards |
| `orchestrator-research` | `*.R`, `explorations/**` | Lightweight orchestrator for exploratory analysis |
| `verification-protocol` | `replications/**`, `reports/**` | Task completion checklist |
| `proofreading-protocol` | `*.md`, `quality_reports/**` | Propose-first before editing |
| `knowledge-base-template` | `replications/**` | Field registry, estimand registry, known pitfalls |
| `exploration-folder-protocol` | `explorations/` | Structured sandbox; 60/100 threshold |
| `exploration-fast-track` | `explorations/` | Lightweight exploration workflow |
| `pdf-processing` | `papers/**` | Safe large PDF handling |
| `meta-governance` | — | Generic vs. specific content; two-tier memory |

### Templates (`templates/`)

| Template | What It Does |
|----------|-------------|
| `session-log.md` | Session logging format |
| `quality-report.md` | Merge-time quality report |
| `exploration-readme.md` | Exploration project README |
| `archive-readme.md` | Archive documentation |
| `requirements-spec.md` | MUST/SHOULD/MAY requirements framework |
| `constitutional-governance.md` | Immutable principles vs. preferences |
| `skill-template.md` | Template for creating new skills |

</details>

---

## Prerequisites

| Tool | Install |
|------|---------|
| [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview) | `npm install -g @anthropic-ai/claude-code` |
| R (≥ 4.2) | [r-project.org](https://www.r-project.org/) |
| [gh CLI](https://cli.github.com/) | `winget install GitHub.cli` |

---

## Data Setup

The `data/` folder is gitignored — never commit raw data.

**UK Biobank:**
1. Place your UKB extract in `data/`
2. Apply the latest withdrawal list before any analysis
3. Update your Application ID in `CLAUDE.md`

**Chinese survey data (CHNS, CHARLS, etc.):**
1. Place datasets in `data/China_rawdata/`
2. Update absolute paths in each `replicate.R` script (paths are machine-specific)

---

## Folder Structure

```
paper-replicate-agent-demo/
├── papers/              # PDFs and original replication packages
├── data/                # Datasets (gitignored)
├── replications/        # R replication scripts and outputs
│   └── [PaperName]/
│       ├── R/replicate.R
│       ├── figures/
│       ├── tables/
│       └── validation_report.md
├── quality_reports/     # Plans, session logs, replication targets
├── explorations/        # Sandbox for experimental analyses
├── reports/             # Polished final reports
├── scripts/             # Utility scripts (quality_score.py)
└── templates/           # Session log, quality report, skill templates
```

---

## License

MIT. Use freely for research.
