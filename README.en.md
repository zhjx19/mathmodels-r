<sub>🌐 <a href="README.md">中文</a> · <b>English</b></sub>

<div align="center">

# mathmodels-r

> *「Stop poking at R with function names you half-remember — let the environment self-check run first, then let the recipe library take over.」*

[![Agent Skills](https://img.shields.io/badge/Agent_Skills-mathmodels--r-blueviolet)](SKILL.md)
[![version](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2Fzhjx19%2Fmathmodels-r%2Fmain%2Fversion.json&query=%24.version&label=version&color=blue)](version.json)
[![R](https://img.shields.io/badge/R-4.6.1-276DC3)](https://www.r-project.org/)
[![mathmodels](https://img.shields.io/badge/mathmodels-0.0.14-1f9e89)](https://github.com/zhjx19/mathmodels)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![smoke](https://img.shields.io/badge/smoke-35%20passed-brightgreen)](tests/smoke_all_modules.R)
[![examples](https://img.shields.io/badge/examples-6%2F6%20passed-brightgreen)](tests/run_all_examples.sh)
[![skills.sh](https://skills.sh/b/zhjx19/mathmodels-r)](https://skills.sh/zhjx19/mathmodels-r)

**Turn your local R plus the `mathmodels` package into a reproducible modelling workbench: one run = script + log + tables + figures + session info, and every number in your paper points back to a file.**

[See it work](#see-it-work) · [Six examples](#six-ready-to-use-examples) · [Install](#quick-start) · [Triggers](#triggers) · [How it differs](#how-it-differs) · [Safety](#safety-boundaries)

</div>

---

## What it solves

Handed a mathematical-modelling task, the usual path is: hunt the online book for a function,
copy a snippet, paste it into RStudio, fix it until it runs — and then the Chinese labels in your
figure come out as tofu boxes, the CSV opens as mojibake in Excel, and three months later the
script no longer runs. Three things keep happening:

**First, nobody judges whether the method was the right one.** `mathmodels` exports 162 functions
across comprehensive evaluation, forecasting, differential equations, multivariate statistics, data
cleaning, and inference. Any single problem admits five or six plausible methods; pile them up and
you get a "method soup" that reads as having made no choices at all.

**Second, the Chinese/encoding traps get stepped on every time.** Measured on this machine:
Git Bash exports `LC_CTYPE` as `C.UTF-8`, Windows R does not accept it, so Chinese literals in a
UTF-8 source file fail to parse and Chinese paths get silently truncated. And `cairo_pdf()` /
`pdf()` with the default font family render Chinese as **boxes or blanks** — many people assume
"it exported a PDF, so it worked", when the deliverable is in fact broken.

**Third, what comes out cannot go into a paper.** Numbers scroll past in the console and nobody can
trace them; figures were never written to disk; parameters were never recorded; rerun on different
data and the results no longer line up.

This skill pins each of the three down one layer: **a selection table + recipe library** for method
choice, **a runner + workbench script** for encoding and fonts, and **the run directory** for
reproducibility.

---

## See it work

One real end-to-end run (four task types: comprehensive evaluation / epidemic ODE / time series /
inference). The artifacts live verbatim in [`examples/e2e-run/`](examples/e2e-run/):

```text
▶ 退出码  : 0
    - INFO 表格 -> tables/topsis_ranking.csv  20 行 x 4 列
    - INFO TOPSIS 最优对象：R11，得分 100
    - INFO R0 = 1.5；峰值 69.7 人，出现在第 65 天
    - INFO 表格 -> tables/sarima_forecast.csv  12 行 x 4 列
    - INFO t 检验 p 值 = 0.07939
    [mmr] 完成：6 表, 8 图, 耗时 15.7s
```
(The lines above are taken verbatim from [`examples/e2e-run/console.txt`](examples/e2e-run/console.txt).)

The ranking table exported by the same run (`tables/topsis_ranking.csv`, UTF-8 + BOM, so Excel
opens it without mojibake):

| River | Relative closeness | Score | Rank |
|---|---:|---:|---:|
| R11 | 0.809192 | 100 | 1 |
| R9 | 0.726053 | 87.207014 | 2 |
| R10 | 0.713845 | 85.328483 | 3 |

The same run also exports `figs/topsis_scores.pdf` (vector, Chinese renders correctly) and
`figs/sir_compartments.png` — **the PDF path is the one that most often goes wrong, and these files
are sitting right there for you to open and check.**

Full-module smoke test result ([`examples/smoke-report.md`](examples/smoke-report.md)):

```text
冒烟结果：35 项通过，0 项失败
```

---

## Six ready-to-use examples

The high-frequency functions that **lack a runnable example** in the usual material
(`weight_entropy` / `weight_critic` / `weight_cv`, the 11 `mf_*` membership functions, …) are all
covered by the six examples below. **Each one has actually been run on `mathmodels` 0.0.14 on this
machine**, and each directory carries the real `log.md` and `tables/*.csv`, so you can check column
names and figures against them.

| Example | What it covers | Functions | Artifacts |
|---|---|---|---|
| `01-comp-eval` | Multi-level indicator evaluation; four weightings + AHP combination + TOPSIS | `weight_entropy`/`weight_critic`/`weight_cv`/`AHP`/`combine_weights`/`topsis` | 5 tables, 6 figures |
| `02-fuzzy-eval` | Full fuzzy comprehensive evaluation; fuzzy statistics; expert interval fitting | 11 `mf_*`/`compute_mf`/`fuzzy_eval`/`defuzzify` | 5 tables, 8 figures |
| `03-dea-efficiency` | DEA four combinations + super-efficiency + undesirable-output SBM + Malmquist panel | `basic_DEA`/`super_DEA`/`basic_SBM`/`malmquist` | 4 tables, 6 figures |
| `04-regional-economy` | Gini/Lorenz/Theil decompositions + location quotient/HHI/EG | `gini`/`theil_g*`/`LQ`/`HHI`/`EG` | 8 tables, 8 figures |
| `05-system-eval` | Coupling coordination (standard vs corrected) + obstacle degree | `weight_entropy`/`coupling_degree`/`obstacle_degree` | 7 tables, 6 figures |
| `06-grey-prediction` | Full GM(1,1) chain + grey-family selection + Markov correction | `GM11`/`GM1N`/`DGM21`/`verhulst`/`markov_chain`/`GM11_markov` | 9 tables, 8 figures |

**The router is [`examples/index.md`](examples/index.md)**: it maps how a user phrases the question,
or which function they want, onto the example to read. The ★-marked traps in the examples (such as
`LQ()` requiring a "national total" row, or `basic_SBM()` refusing `orientation`) are all written up
in each case's `README.md`.

Regress all examples (6 cases + e2e-run) in one shot:

```bash
bash tests/run_all_examples.sh     # expect "7 passed / 0 failed"
```

---

## Quick start

One-line install (skills.sh / Agent Skills registry):

```bash
npx skills add zhjx19/mathmodels-r            # one-line install via skills.sh
```

Or place it in your skills directory by hand (the location depends on your runtime):

| runtime | user skills directory |
|---|---|
| OpenCode | `~/.config/opencode/skills/` |
| Claude Code | `~/.claude/skills/` |

```bash
cp -r <this directory> ~/.config/opencode/skills/mathmodels-r
```

Then run the environment self-check first:

```bash
Rscript --vanilla ~/.config/opencode/skills/mathmodels-r/scripts/check_env.R
```

Then say this to your agent:

```text
Use mathmodels-r to run a multi-indicator comprehensive evaluation: check the environment first,
then produce a ranking table and a Chinese-labelled figure via entropy weighting + TOPSIS.
```

On another machine or with another R version, just point at the R binary:

```bash
export MMR_RSCRIPT="/c/Program Files/R/R-4.5.0/bin/Rscript.exe"
```

---

## Triggers

- Do this mathematical modelling in R / compute this indicator system for me
- Does `mathmodels` have a function for X?
- Entropy weighting + TOPSIS, give me a ranking table
- Compute AHP weights and check whether CR passes
- Forecast the next three periods with grey prediction GM(1,1)
- DEA efficiency, coupling coordination, obstacle degree
- Forecast 12 periods ahead with SARIMA and plot it
- Simulate an epidemic with an SIR model and compute R0
- Just run my R script and make sure every table and figure is written to disk

---

## What it does / what it delivers

| Capability | Methods covered | Deliverable |
|---|---|---|
| Multi-indicator evaluation | AHP, entropy, CRITIC, CV, PCA/FA weighting, combined weighting, TOPSIS, grey relational, RSR, fuzzy | Ranking CSV + score figure + weight table |
| Efficiency & system evaluation | DEA (CCR/BCC/SBM/super-efficiency/Malmquist), coupling coordination, obstacle degree, Gini/Theil, location quotient/HHI/EG | Efficiency, obstacle, and index tables |
| Forecasting | Grey (GM(1,1)/GM(1,N)/DGM(2,1)/Verhulst), Markov, grey–Markov, four regression families, SARIMA/ETS/ARIMAX | Forecast table (with intervals) + forecast figure |
| ODEs & epidemics | Arbitrary ODE systems, Malthus/Logistic/SI/SIS/SIR/SEIR/LV, R0 and peak metrics | Trajectory figures, phase plot, R0 table |
| Multivariate statistics | PCA, EFA, hierarchical/k-means clustering with validity indices, discriminant analysis, correspondence analysis, MDS, canonical/partial correlation | Loading, clustering, and confusion-matrix tables |
| Data cleaning | Missingness diagnostics (incl. Little's MCAR), three imputation families, multiple imputation with Rubin pooling, three-mode outlier handling, pivot tables | Before/after table + outlier list |
| Inference | t/Wilcoxon/ANOVA/Kruskal/ANCOVA/correlation/chi-square/normality/variance tests, bootstrap, permutation | Tidy result table + Word/LaTeX three-line table |

Every run produces a fixed set: `script.R`, `log.md`, `meta.txt` (elapsed time / exit code),
`sessionInfo.txt`, `tables/*.csv`, `figs/*.png` + `*.pdf`.

---

## How it differs

| Dimension | The usual approach | This skill |
|---|---|---|
| Correct function calls | Recall, or copy from whatever material is at hand (which often carries pre-0.0.13 names) | A machine-generated API index + a 34-row "signature cheat-sheet" + six run-verified examples; plus an old→new rename table |
| Chinese figures | Export a PDF with the default device and call it a success while Chinese renders as boxes | PNG via the default device; PDF forced through `cairo_pdf` + `Microsoft YaHei`; both formats exported together |
| Chinese encoding | Keep editing the code, or add a BOM / pass `--encoding=UTF-8` (both measured to fail) | The runner clears the `LC_*` environment variables — the only approach that actually worked in testing |
| Reproducibility | Console echo + manual save-as | One run directory per run: script, log, tables, figures, and session info travel together |
| Regression safety | None | 35 full-module smoke assertions in-repo, so a package upgrade immediately reveals which call sites broke |
| Method choice | Whatever comes to mind | A selection table keyed to problem structure, with primary and fallback routes, plus explicit combination discipline (no method soup) |

---

## Safety boundaries

**It does not:**

- delete or overwrite your existing scripts, data, or run directories (it asks first when needed);
  every artifact is written into a newly created run directory;
- install R packages, modify `.libPaths`, or touch system configuration — missing dependencies are
  only reported, and you decide whether to install them;
- fetch data online (beyond `read_nbs()`), or call external APIs;
- package model output as causal claims, or drop baseline comparisons and error metrics.

**It stops and asks when:**

- the environment self-check has failing items and fixing them would change your environment;
- the task actually needs the full "problem framing → paper → LaTeX" pipeline (this skill covers
  only the compute layer, and will suggest switching to `math-modeling-flow`);
- data definitions conflict, units are unclear, or results are headed for a formal paper while the
  data source is in doubt.

---

## File structure

```
SKILL.md                    workflow, hard rules, mandatory stop points, acceptance checklist
README.md / README.en.md    pre-install documentation (Chinese / English)
CHANGELOG.md                version history (why things changed, not just what)
LICENSE / version.json      MIT licence; the source value for the dynamic version badge
test-prompts.json           acceptance samples: does it trigger, is the workflow followed
.claude-plugin/
  marketplace.json          Claude Code plugin marketplace manifest
references/
  recipes.md                selection table + signature cheat-sheet (34 verified traps) + 14 recipes
  function-index.md         index of 162 exported functions (machine-generated from the package source)
  r-environment.md          local R environment and encoding landmine list
scripts/
  run_r.sh                  runner: clears LC_*, locates Rscript, creates the run dir, collects artifacts
  mmr.R                     R-side workbench: logging, CSV (BOM), Chinese-safe PNG/PDF export
  check_env.R               environment self-check (human-readable / --json)
  gen_function_index.R      regenerates function-index.md
tests/
  smoke_all_modules.R       35 full-module smoke assertions
  run_all_examples.sh       one-shot regression over 6 examples + e2e-run, with pre-recovery reconciliation
examples/
  index.md                  ★ router: how a question / function maps to which example
  data/                     8 real datasets (from the book's cases, ~145 KB)
  cases/                    6 run-verified examples (each with script.R + README.md + real artifacts)
  e2e-run/                  complete artifacts of one real run
  smoke-report.md           smoke test report
```

---

## Verification & testing

```bash
# Environment self-check (all 9 items should be OK)
Rscript --vanilla scripts/check_env.R

# Full-module smoke (expect "35 passed, 0 failed", exit code 0)
bash scripts/run_r.sh tests/smoke_all_modules.R

# Full example regression (6 cases + e2e-run, expect "7 passed / 0 failed",
#   artifacts recovered back into each case directory)
bash tests/run_all_examples.sh

# End-to-end sample (expect exit code 0, 6 tables and 8 figures in the run directory)
bash scripts/run_r.sh examples/e2e-run/script.R
```

One acceptance prompt:

```text
Use mathmodels-r to run a comprehensive evaluation on water_quality: weight by entropy,
rank by TOPSIS, export the ranking CSV and a Chinese-labelled figure, and state the top object.
```

Passing behaviour: exit code 0; a ranking table in `tables/` with correct Chinese headers; Chinese
in `figs/*.pdf` renders as real glyphs rather than boxes; no `TRUE` noise lines in `log.md`; and the
top-scoring object and its score are reported.

---

## Acknowledgements

- The methodology and interfaces come from Jingxin Zhang's R package **mathmodels** (AGPL-3):
  [GitHub](https://github.com/zhjx19/mathmodels) ·
  [online manual](https://zhjx19.github.io/mathmodels-book/)
- Source material: this machine's `mathmodels` package source (`man/`, `_pkgdown.yml`, `NEWS.md`),
  plus real code blocks from `mathmodels-book` and the modelling articles.
- The 6 examples and 8 datasets under `examples/` are real cases from the companion manuscript of
  *数学建模：算法与编程实现*, checked line by line against `mathmodels` 0.0.14 and run to completion.
- 2026-10-11: a line-by-line patch proposal was submitted to the `mathmodels` author; six items were
  fixed and reinstalled in the 0.0.14 working tree (`fuzzy_eval` operator 5, `theil_g2_nest`'s
  `ratio` values and duplicate names, the `mf_dsigmoid` docs, `markov_chain` dimnames, the
  `weight_entropy` warning, and the `basic_DEA`/`super_DEA` warnings). This skill's examples,
  cheat-sheet, and hard rules were re-verified against the **post-fix** behaviour (details in
  `references/recipes.md`, section 4). One of them — `super_DEA`'s LP-infeasible branch, previously
  recorded by the author as "cannot reproduce" — was confirmed **deterministically reproducible**
  once this skill supplied a **6-line minimal reproduction** (`vrs` + an extreme DMU always triggers
  it; `crs` never does), and example 03 now carries a CRS/VRS comparison table and a regression
  guard accordingly.
- The engineering choices (clearing `LC_*`, the PDF font family, CSV BOM) are all measured
  conclusions from this machine; see `references/r-environment.md`.

## License

Distributed with the host project; the `mathmodels` package itself is AGPL (>= 3).
