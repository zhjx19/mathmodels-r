---
name: mathmodels-r
description: >-
  Use when 用户要在一台装了 R 的机器上用 mathmodels 包做数学建模计算：先做环境自检，
  再按建模任务选方法，生成可复现的 R 脚本，用本地 Rscript 跑出表格、图形与日志。
  覆盖综合评价（AHP/熵权/CRITIC/TOPSIS/模糊/RSR/DEA/灰关联）、预测（灰色/Markov/回归/时间序列）、
  微分方程与传染病模型、多元统计（PCA/EFA/聚类/判别/对应分析/MDS）、数据清洗与统计推断。
  每次运行落成一个 run 目录（脚本 + 日志 + tables/ + figs/ + sessionInfo），论文里每个数字可回溯。
  内置 6 个实测通过的范例（examples/cases/，含综合评价/模糊评价/DEA/区域经济/系统评价/灰色预测）
  与一张路由表（examples/index.md），用户提问可先命中范例，直接照抄正确函数调用。
  触发词包括但不限于：用 R 做数学建模、mathmodels、熵权法、TOPSIS、AHP 权重、模糊综合评价、
  灰色预测 GM(1,1)、马尔可夫预测、DEA 效率、耦合协调度、障碍度、基尼系数、泰尔指数、
  SARIMA 预测、SIR 传染病模型、用 R 跑一下、帮我写 R 脚本出图出表、本地 R 环境、
  这个模型的 R 代码、Rscript 跑脚本。
  不要用于：用 Python 完成建模与论文全流程（用 math-modeling-flow）、
  撰写 mathmodels 使用指南 .qmd 初稿（用 zhang-style）、
  纯 R 包开发/改源码/发版（用 R 包开发流程）、
  与本机 R 无关的通用数据分析问答。
related-skills:
  - math-modeling-flow
  - zhang-style
compatibility: claude-code, zcode, opencode, codex
metadata:
  version: "1.0"
---

# mathmodels-r · 本地 R 驱动的数学建模

## 0. 心法

**先把环境钉死，再谈方法。** 本机 Windows R 有两个稳定复现的坑——Git Bash 注入的
`LC_*` 会让 UTF-8 源码里的中文解析失败；`cairo_pdf()` / `pdf()` 默认字体族输出中文是
方框。这两条已由 `scripts/run_r.sh` 与 `scripts/mmr.R` 固化，**不要绕过它们手工调
`Rscript`**，否则会得到"脚本能跑但中文全乱码"的假成功。

**方法选择先看结构，再看工具。** 拿到任务**先查 `examples/index.md` 路由表**
（用户问法 → 命中哪个已实跑通过的案例），命中就照案例改；没命中再到
`references/recipes.md` 的选型表定位。**不要凭记忆写 mathmodels 的函数调用**——包在
0.0.13/0.0.14 有过一轮函数更名（`entropy_weight` → `weight_entropy`、`tri_mf` → `mf_tri`、
`model_sir` → `ode_sir`，完整对照见 `recipes.md` 签名速查）。**凡是在你手边的素材
（书稿、文章、旧脚本、网上示例）里出现旧名，先换成新名再跑**——报错信息不会告诉你该换成什么。
签名一律以 `references/function-index.md`（机器生成）与 `references/recipes.md` 的
「签名速查」为准：这两处锚定的是**包**，不随任何书稿/文章的更新而变。

**结论必须有产物。** 每次运行都落成一个 run 目录，论文里的每个数字都能指到
`tables/*.csv` 或 `log.md`。

---

## 1. 前置准备：环境自检（每次会话第一次任务必做）

```bash
Rscript --vanilla <skill>/scripts/check_env.R
```

预期看到 9 项 `[OK]`（R 版本、libPaths、mathmodels 版本、22 个依赖、PNG 默认设备、
cairo_pdf、系统中文字体、中文字面量解析、flextable）。任一 `[!!]` 先按提示修复，
**不要带着红色自检结果往下做**。

若 `Rscript` 不在 PATH：`run_r.sh` 会自动按 `$MMR_RSCRIPT` → 常见安装路径 → `PATH`
上的 `Rscript` 查找。**候选清单与顺序只写在脚本的 `find_rscript()` 里（唯一一处）**，
本文不复制本机绝对路径，以免两处说法不一致。换机器只需 `export MMR_RSCRIPT=...`。

---

## 2. 工作流

```
① 读题与选型
   先查 examples/index.md 路由表（用户问法 → 命中案例）；命中就以该案例的
   script.R 为蓝本改。没命中再回 references/recipes.md 选型表 + 签名速查。
   ↓
② 写分析脚本（一个任务一个 .R）
   脚本骨架见 §3：source mmr.R → mmr_init() → 分步计算 → mmr_table()/mmr_fig() → mmr_finish()
   ↓
③ 运行（不要直接调 Rscript）
   bash <skill>/scripts/run_r.sh <你的脚本.R>
   ↓
④ 验收产物
   打开 run 目录：log.md 无 TRUE 噪声、tables/*.csv 中文正常、figs/*.pdf 中文不是方框
   ↓
⑤ 交付
   报出关键数值 + 产物路径；需要进论文的表格用 export_table(output="word"/"latex")
```

> **为什么第一步要查路由表**：这 6 个案例是**在 mathmodels 0.0.14 上实跑通过**的，
> 填补的是常用素材（书稿、建模文章）里**缺乏可直接运行示例**的函数——`weight_entropy` /
> `weight_critic` / `weight_cv` / 11 个 `mf_*` 等，并把踩过的坑写成可执行断言。
> **照抄案例远比凭记忆写函数调用可靠。**
> 命中案例后，先读该案例的 `README.md`（「踩过的坑」一节尤其重要）与 `script.R`，再动手改。

### 2.1 选型要点（先做结构判断，再查表）

| 题目特征 | 首选路线 | 对应案例 |
|---|---|---|
| 多对象 × 多指标，要排序 | 赋权（客观 / 主观 / 组合）+ TOPSIS 或 RSR | `01-comp-eval` |
| 有"评语 / 等级 / 隶属度"表述 | 模糊综合评价（隶属函数 + 合成 + 去模糊） | `02-fuzzy-eval` |
| 投入产出多，要算效率 | DEA 家族（+ Malmquist 面板） | `03-dea-efficiency` |
| 区域差距 / 产业集聚 | 基尼 / 泰尔分解 + LQ / HHI / EG | `04-regional-economy` |
| 有"多系统协调""瓶颈"表述 | 耦合协调度 + 障碍度 | `05-system-eval` |
| 样本极少（4-15 期）、近似指数增长 | 灰色预测（+ 马尔可夫修正） | `06-grey-prediction` |
| 有明确时间序列、样本较长 | `ts_*` 工作流 | — |
| 有自变量，要解释影响 | `reg_*` 家族 | — |
| 机制已知、可写微分方程 | `ode_solver()` 自定义方程组 | — |
| 数据脏（缺失 / 异常） | 先清洗再建模，别直接丢行 | — |

### 2.2 模型组合纪律

- 赋权方法并存的前提是**角色不同**（如 AHP 表达偏好、熵权表达信息量），并做冗余性检验；
- 不要用「多个综合评价方法排名一致」当作稳健性证据——它们常常同源；
- 灰色预测适合少数据外推，**不要**用它在样本充足时替代时间序列模型；
- 回归系数不是因果；相关系数不要写成因果结论；
- 优化问题先写清目标函数与约束，再选求解器。

---

## 3. 脚本骨架（标准写法）

```r
# ---- 骨架开始 ----
source(file.path(Sys.getenv("MMR_HOME"), "scripts", "mmr.R"))
mmr_init(label = "任务简述")          # run_r.sh 已 cd 到 run 目录，产物自动落盘

suppressPackageStartupMessages({
  library(mathmodels); library(dplyr); library(tibble); library(tidyr); library(ggplot2)
})

mmr_log("第一步：……")
# ……计算……
mmr_table(result_tbl, "result_name")        # → tables/result_name.csv（UTF-8 + BOM）
mmr_fig(ggplot_obj, "fig_name")             # → figs/fig_name.png + .pdf（中文安全）

mmr_finish(notes = "一句话结论")
# ---- 骨架结束 ----
```

`mmr_*()` 的取舍：

| 函数 | 作用 | 关键点 |
|---|---|---|
| `mmr_init(label=)` | 建 tables/ figs/、写 log.md 头、设中文安全绘图主题 | 必调，且是第一条 |
| `mmr_log(...)` | 写日志并回显 | 中文安全；**不要**用它输出含有 `useBytes=` 的 cat |
| `mmr_table(x, name)` | 导出 CSV | UTF-8 + BOM，Excel 双击不乱码 |
| `mmr_fig(plot, name, width, height, dpi, fmt)` | 导出图形 | PNG 走默认设备；**PDF 自动套 `cairo_pdf` + `Microsoft YaHei`**（这是中文不出方框的关键） |
| `mmr_finish(notes=)` | 写产物清单、sessionInfo | 结尾必调 |

**PDF 字体可覆盖**：`Sys.setenv(MMR_PDF_FAMILY = "SimHei")` 或改 `MMR$pdf_family`。

---

## 4. 硬规则（违反会静默出错）

1. **不要绕过 `run_r.sh` 直接跑 `Rscript`**。手工调用必须自带
   `env -u LANG -u LC_ALL -u LC_CTYPE -u LC_COLLATE`，否则中文解析失败。
2. **不要给 R 脚本加 UTF-8 BOM，也不要传 `--encoding=UTF-8`**——两者都实测报错
   （`unexpected invalid token in "ï"` / `re-encoding failure`）。清环境变量是唯一解。
3. **不要用 `showtext::showtext_auto()` 而不注册字体**——中文会全变方框。
   确实要用，先 `sysfonts::font_add("cn", "C:/Windows/Fonts/msyh.ttc")` 并切 `family = "cn"`。
4. **PDF 出图必须走 `mmr_fig()`**（或自带 `cairo_pdf` + `Microsoft YaHei`）；
   `ggsave("x.pdf")` 默认设备出的是方框。
5. **`cat()` 没有 `useBytes` 形参**。误传会把 `TRUE` 当内容写进文件且不报错。
   日志相关代码改完，务必 `grep -c "^TRUE" log.md` 应为 0。
6. **`index` 两套约定要分清**：赋权族允许 `NA`（已归一化）；`topsis()` /
   `grey_corr_topsis()` 只认 `"+"` / `"-"`。中心化 / 区间型指标先用
   `rescale_middle()` / `rescale_interval()` 转正向。
7. **`mv_*()` 与 DEA 家族的 `data` 必须是 data.frame**，传 `matrix` 直接报错。
8. **`grey_corr_topsis()` 的 `X` 必须是 data.frame**，传 matrix 会报零极差。
9. **`weight_entropy()$s` 已在 0–100 量纲**（实测二级得分 10 ~ 98），
   **不要再乘 100**，否则综合评价得分虚高到几千分。
10. **`basic_SBM()` 是非导向模型，不能传 `orientation`**（v0.0.14 起），否则报
    `SBM models are non-oriented; orientation is not applicable.`。
    非期望产出用 `ud_outputs =` 指定在 outputs 里的第几列。
11. **`LQ()` 每组第一行必须是"全国合计"行**（源码 `x[-1] / x[1]` 拿它当分母并删除）。
    只传真实地区会**静默错算**且不报错——务必补全国行 + `stopifnot` 守卫 + 手工对拍。
12. **`markov_chain()` 的 `trans_mat` 是 `table`、`pred_probs` 是 `matrix`**：`table` 走
    `as.data.frame()` 会摊成长表 `Var1/Var2/Freq`，`matrix` 走 `as_tibble()` 会静默丢行名。
    两者最稳的转换都是
    `tibble::rownames_to_column(as.data.frame(x, check.names = FALSE), var = "从\\到")`。
    （0.0.14 起 `trans_mat` 的 `dimnames` 已命名为 `from`/`to`，`as_tibble(x, rownames=)` 不再报
    `Names can't be empty`，但会把维度名当列名、产生**重复的 `from` 列**。）
13. **`as_tibble()` 静默丢行名**：要用行名当列，必须**先 `rownames_to_column()` 再 `as_tibble()`**。
14. **`mf_dsigmoid()` 的值域是 `[-1, 1]`，不是 `[0, 1]`**（`c1 > c2` 时为负），不能直接当隶属度
    用——先剪到 `[0,1]`，或改用 `mf_psigmoid()`；否则喂 `fuzzy_eval()` 会被
    `R must contain only values between 0 and 1` 拦下。
15. **数据清洗先于建模**：缺失 / 异常不处理就进模型，结论不可信。
16. **不要虚构函数名、参数名或返回字段**。不确定就先
    `Rscript -e 'args(mathmodels::函数名)'` 或查 `references/function-index.md`。

---

## 5. 强制停手点

1. 环境自检有 `[!!]` 项，且修复动作会改动用户环境（装包、改 `.libPaths`、改注册表）时；
2. 需要**覆盖或删除**用户已有数据 / 脚本 / run 目录时；
3. 准备把结论写进正式论文 / 报告，而数据源本身存疑（口径冲突、单位不明）时；
4. 数学建模任务需要多问全流程（拆题 → 论文 → LaTeX）时——本 skill 只负责
   「算力层」，流程编排交给 `math-modeling-flow`，先问用户要不要切过去；
5. 需要联网取数（如 `read_nbs` 之外的在线来源）时，先确认数据源可接受。

---

## 6. 反例黑名单

- ❌ 直接 `Rscript script.R` 而不清 `LC_*`，然后对着报错反复改代码（改成 ASCII 变量名也救不了）。
- ❌ 看见报错就改函数名猜参数——先 `args()` 或查索引。
- ❌ 把旧函数名（`entropy_weight` / `critic_weight` / `cv_weight` / `pca_weight` / `tri_mf`
  全套 / `model_sir` 全套）从**任何素材**里直接抄进脚本——先按 `references/` 换成现行名。
- ❌ 把 `basic_SBM()` 照书稿传 `orientation`，或把 DEA 的 `data` 传成 matrix。
- ❌ 把 `mf_dsigmoid()` 的返回值直接当隶属度喂 `fuzzy_eval()`（它可为负，会被守卫拦下）。
- ❌ 调 `LQ()` 时忘了补"全国合计"行——不报错，但数值全错（最危险的一类坑）。
- ❌ 用 `ggsave("fig.pdf")` 出图，交付时报"PDF 显示不了中文"。
- ❌ 只回显控制台不给文件——控制台的中文不可靠，且无法进论文。
- ❌ 把 `topsis()` 的 `index` 写成带 `NA` 的向量。
- ❌ 让 `mmr_table()` 收下未排序的 100+ 行明细当"结果表"——结果表要能直接进论文。
- ❌ 用循环跑 20 个模型却只给一张汇总图，不落中间结果表。
- ❌ 声称"模型效果好"却不给基线对比与误差指标。

---

## 7. 验收单

交付前逐项确认：

- [ ] `check_env.R` 全绿；
- [ ] 脚本经 `run_r.sh` 运行，退出码 0；
- [ ] run 目录含 `script.R` / `log.md` / `meta.txt` / `sessionInfo.txt` / `tables/` / `figs/`；
- [ ] `figs/*.pdf` 打开后中文标题、轴标签不是方框（PDF 是最容易翻车的一环，必须亲眼看）；
- [ ] `tables/*.csv` 双击后中文表头不乱码；
- [ ] `grep -c "^TRUE" log.md` = 0；
- [ ] 关键结论数字能在 `tables/` 或 `log.md` 里指出来源；
- [ ] 若改了包相关代码，重跑 `bash scripts/run_r.sh tests/smoke_all_modules.R`，35 项全过。
- [ ] 若新增 / 修改了 `examples/` 下的脚本，跑 `bash tests/run_all_examples.sh`，
      应输出「7 通过 / 0 失败」（6 个案例 + e2e-run；回收前会自动对账产物清单、
      路径可移植性与 LF，产物回收进各案例目录）。

---

## 8. 文件结构

```
SKILL.md                         本文件：工作流、硬规则、停手点、验收单
README.md / README.en.md         安装前说明（中文 / English）
CHANGELOG.md                     版本记录（讲"为什么改"，不只"改了什么"）
LICENSE / version.json           MIT 许可；动态版本徽章的取值来源
test-prompts.json                验收样例：触发是否准确、流程是否被遵守
.claude-plugin/marketplace.json  Claude Code plugin marketplace 清单
references/
  r-environment.md               本地 R 环境与编码地雷清单（每条附现象/根因/做法）
  function-index.md              全 API 索引（机器生成，勿手改）
  recipes.md                     选型表 + 签名速查（实测校对）+ 14 个最小配方
scripts/
  run_r.sh                       运行器：清 LC_*、定位 Rscript、落 run 目录、收产物
  mmr.R                          R 侧工作台：日志、表格/图形导出、中文安全
  check_env.R                    环境自检（人读 + --json）
  gen_function_index.R           从包源重新生成 function-index.md
tests/
  smoke_all_modules.R            35 项全模块冒烟测试（本 skill 的验证资产）
  run_all_examples.sh            一键回归：跑通 examples/ 全部范例（含 e2e-run），
                                 回收前对账（产物清单 / 路径可移植 / LF）
examples/
  index.md                       ★ 路由表：用户问法 / 包函数 → 该看哪个案例（工作流第一步查）
  data/                          8 份真实数据（书稿案例原样打包，约 145 KB）
  cases/                         6 个实跑通过的范例，每个含 script.R + README.md + 真实产物
    01-comp-eval/                综合评价：多种赋权 + AHP + 组合赋权 + TOPSIS
    02-fuzzy-eval/               模糊评价：11 个 mf_* + 模糊合成 + 去模糊 + 模糊统计
    03-dea-efficiency/           DEA：CCR/BCC/超效率/SBM + Malmquist 面板
    04-regional-economy/         区域经济：基尼/泰尔分解 + LQ/HHI/EG
    05-system-eval/              系统评价：耦合协调度 + 障碍度
    06-grey-prediction/          灰色预测：GM(1,1)/GM(1,N)/DGM/Verhulst + 马尔可夫
  e2e-run/                       一次真实端到端运行的完整产物（脚本+日志+表+图）
  smoke-report.md                冒烟测试报告
```

---

## 9. 维护约定

- 包版本变化后：`Rscript --vanilla scripts/gen_function_index.R <pkg_dir> <pkg_dir>/_pkgdown.yml references/function-index.md`，
  再 `bash scripts/run_r.sh tests/smoke_all_modules.R`，用失败项更新 `recipes.md`；
  并**逐条复核 `recipes.md` 第四节「上游修复记录」**——该表记录了 2026-10-11 向作者提交、
  已在 0.0.14 工作树修复并重装的 6 条（`fuzzy_eval` 算子 5 / `theil_g2_nest` / `mf_dsigmoid` 文档 /
  `markov_chain` dimnames / `weight_entropy` 告警 / `basic_DEA`·`super_DEA` 告警）。
  **若某条在升级后回退**，要在「签名速查」对应行恢复警告措辞。
- 新增易错点时，同时写进 `references/r-environment.md`（环境类）或
  `recipes.md` 的「签名速查」（接口类），并补一条冒烟断言。
  写之前先分清**是包的缺陷、还是 Rd 已声明的调用者责任**——两者在速查表里标注方式不同。
- **本 skill 不对任何书稿/文章的当前命名状态作断言。** 命名事实只作为「包侧更名对照」
  存在于 `recipes.md` 的签名速查与本节；凡素材里出现旧名，按对照换名即可。
  这样书稿更新前后，本 skill 的表述都成立，无需回改。
- **提交任何 `examples/**` 产物前对账**（`tests/run_all_examples.sh` 已自动执行这三条）：
  ① `log.md` 的「产物清单」逐条在 `tables/`·`figs/` 里存在；② 产物里无本机家目录路径、
  无盘符绝对 run 目录；③ 文本产物为 LF。
  **稳定性分级（实测）**：表格 CSV 与 PNG 字节稳定；`log.md`/`meta.txt`/`console.txt`
  含时间戳、`*.pdf` 内嵌 Cairo 创建时间与文档 ID，每次重跑都会变。
  只想复核、不改产物时，用
  `git checkout -- 'examples/**/figs/*.pdf' 'examples/**/log.md' 'examples/**/meta.txt' 'examples/**/console.txt'`
  丢弃这批字节差异。
