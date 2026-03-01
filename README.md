[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.18723722.svg)](https://doi.org/10.5281/zenodo.18723722)

# MIMIC-IV Empirical Replication Agent

A structured **GitHub Copilot** workflow for **empirically replicating published research** using MIMIC-IV data, created by 朱晨 | 遗传社科研究. You describe a paper; Copilot plans the replication approach, writes R/Python scripts, validates outputs against published targets, documents discrepancies, and reports results — like a research contractor who handles the full pipeline.

---

## Quick Start

### 1. Clone & Set Up

```bash
git clone https://github.com/YOUR_USERNAME/paper-replicate-agent-demo.git
cd paper-replicate-agent-demo
```

### 2. Open in VS Code with GitHub Copilot

Open the repository in VS Code and ensure the **GitHub Copilot** extension is installed and enabled.

### 3. Describe Your Task

Open **Copilot Chat** and paste a prompt like:

> I want to replicate [Paper Author (Year)]. The PDF is in `papers/[PaperName]/`. The relevant MIMIC-IV data is in `data/`. Please read the paper, identify all empirical targets, and plan the replication.

**What this does:** Copilot reads `.github/copilot-instructions.md` and the paper, inventories the available data, identifies every table and figure to replicate, drafts a step-by-step plan, waits for your approval, then implements — running scripts, verifying outputs against tolerance thresholds, and saving a validation report.

---

## How It Works

### Contractor Mode

You describe a task. For complex or ambiguous requests, Copilot first creates a requirements specification with MUST/SHOULD/MAY priorities. You approve the spec, then Copilot plans, implements, verifies, scores against quality gates, and presents a summary.

### Replication Pipeline (6 Phases)

| Phase | What Happens |
|-------|-------------|
| **0. Paper Intake** | Read paper; record all empirical targets in `quality_reports/[paper]_replication_targets.md` |
| **1. Inventory & Data Audit** | Verify data matches paper's described sample (N, events, key variables) |
| **2. Translate & Execute** | Write R/Python scripts; match original specification exactly |
| **3. Verify Match** | Check outputs against targets within tolerance thresholds |
| **4. Document Discrepancies** | Investigate every near-miss; document explanations |
| **5. Report** | Save `replications/[paper]/validation_report.md` and polished `reports/[paper]_replication_report.md` |

### Specialized Review Roles

When asking Copilot to review work, you can request it take on one of these roles by saying so in Copilot Chat:

| Role | What It Does |
|------|-------------|
| `domain-reviewer` | Senior epidemiology referee (NEJM/Lancet/IJE standard) — checks causal assumptions, methods, code-theory alignment |
| `r-reviewer` | R code quality, reproducibility, and domain correctness |
| `proofreader` | Grammar, typos, consistency in reports |
| `verifier` | End-to-end task completion verification |

### Quality Gates

Every script and report gets a score (0–100). Scores below threshold block the action:
- **80** — commit threshold
- **90** — PR threshold
- **95** — excellence (aspirational)

### Tolerance Thresholds

| Quantity | Tolerance |
|----------|-----------|
| Sample sizes (N, events) | Exact match |
| Point estimates (HR, OR, β) | ±0.01 |
| Standard errors | ±0.05 |
| P-values | Same significance bracket |
| Percentages | ±0.1pp |

---

## What's Included

<details>
<summary><strong>5 review roles, 10 workflow prompts, 13 reference guides, 6 templates</strong> (click to expand)</summary>

### Review Roles (`.claude/agents/` — reference docs)

| Role | What It Does |
|------|-------------|
| `data-collector` | Read-only MIMIC-IV data extraction via PostgreSQL; saves tables to `data/` |
| `domain-reviewer` | Epidemiology substance review (causal assumptions, methods, MIMIC-IV specifics) |
| `r-reviewer` | R code quality, reproducibility, and domain correctness |
| `proofreader` | Grammar, typos, overflow, consistency review |
| `verifier` | End-to-end task completion verification |

### Workflow Prompts (`.claude/skills/` — reference docs)

| Workflow | What It Does |
|----------|-------------|
| `replicate-paper` | Full 6-phase replication pipeline |
| `data-analysis` | End-to-end R analysis with publication-ready output |
| `review-r` | R code review checklist |
| `proofread` | Proofreading checklist for a file |
| `review-paper` | Manuscript review: structure, epidemiology, referee objections |
| `lit-review` | Literature search, synthesis, and gap identification |
| `research-ideation` | Generate research questions and empirical strategies |
| `interview-me` | Interactive interview to formalize a research idea |
| `devils-advocate` | Challenge design decisions before committing |
| `commit` | Stage, commit, create PR, and merge to main |

### Reference Guides (`.claude/rules/` — reference docs)

| Guide | What It Covers |
|-------|---------------|
| `plan-first-workflow` | Planning protocol for non-trivial tasks |
| `orchestrator-protocol` | Contractor mode: implement → verify → review → fix → score |
| `session-logging` | Logging triggers: post-plan, incremental, end-of-session |
| `replication-protocol` | 6-phase replication + Stata→R/Python pitfalls |
| `quality-gates` | 80/90/95 scoring rubrics + tolerance thresholds |
| `r-code-conventions` | R coding standards, reproducibility, MIMIC-IV pitfalls |
| `python-code-conventions` | Python scientific coding standards |
| `orchestrator-research` | Simplified orchestrator for exploratory research |
| `verification-protocol` | Replication task completion checklist |
| `pdf-processing` | Safe large PDF handling |
| `proofreading-protocol` | Propose-first, then apply with approval |
| `knowledge-base-template` | MIMIC-IV variable registry, estimand registry, pitfalls |
| `exploration-fast-track` | Lightweight exploration workflow (60/100 threshold) |

### Templates (`templates/`)

| Template | What It Does |
|----------|-------------|
| `session-log.md` | Structured session logging format |
| `quality-report.md` | Merge-time quality report format |
| `exploration-readme.md` | Exploration project README template |
| `archive-readme.md` | Archive documentation template |
| `requirements-spec.md` | MUST/SHOULD/MAY requirements framework |
| `constitutional-governance.md` | Non-negotiable principles vs. preferences |

</details>

---

## Prerequisites

| Tool | Required For | Install |
|------|-------------|---------|
| [GitHub Copilot](https://github.com/features/copilot) | AI assistant | VS Code extension or JetBrains plugin |
| [VS Code](https://code.visualstudio.com/) | Editor | [code.visualstudio.com](https://code.visualstudio.com/) |
| R (≥ 4.2) | Replication scripts | [r-project.org](https://www.r-project.org/) |
| Python (≥ 3.10) | Python replication scripts | [python.org](https://www.python.org/) |
| [gh CLI](https://cli.github.com/) | PR workflow | `winget install GitHub.cli` (Windows) |

---

## Data Setup

Create a `data/` directory at the project root and place approved datasets there.

The `data/` folder is intentionally excluded from version control.

1. Complete CITI training and sign the PhysioNet Data Use Agreement to obtain MIMIC-IV access
2. Place your MIMIC-IV data files in `data/` (gitignored — never commit)
3. MIMIC-IV modules used: `hosp/` (core hospital tables), `icu/` (ICU stay tables)
4. Verify table schemas against the [MIMIC-IV documentation](https://mimic.mit.edu/docs/iv/)

---

## Folder Structure

```
paper-replicate-agent-demo/
├── papers/           # PDFs + original replication packages
├── data/             # MIMIC-IV data (gitignored)
├── replications/     # Our R/Python replication scripts + outputs
├── reports/          # Polished final reports
├── quality_reports/  # Plans, specs, session logs, replication targets
├── explorations/     # Sandbox for experimental analyses
├── master_supporting_docs/  # Reference papers and methods docs
└── scripts/          # Utility scripts and shared R functions
```

---

## License

MIT License. Use freely for research.
