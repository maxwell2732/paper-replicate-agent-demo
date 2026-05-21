[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.18723722.svg)](https://doi.org/10.5281/zenodo.18723722)

# Paper Replication Agent

A structured Claude Code workflow for **empirically replicating published research**, created by 朱晨 @ China Agricultural University. Currently used with UK Biobank (UKB) and Chinese survey datasets (CHNS, CHARLS). Special thanks to Pedro H. C. Sant'Anna for the claude-code-my-workflow repository, which inspired this workflow.

You describe a paper; Claude plans the replication approach, writes R scripts, validates outputs against published targets, documents discrepancies, and saves a validation report — like a research assistant who handles the full pipeline.

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
