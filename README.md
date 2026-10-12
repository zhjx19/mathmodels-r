<div align="center">

# mathmodels-r

> *「别再用猜的函数名调 R 了——先让环境自检，再让配方库接管。」*

![Skill](https://img.shields.io/badge/Agent%20Skill-mathmodels--r-blueviolet)
![R](https://img.shields.io/badge/R-4.6.1-276DC3)
![mathmodels](https://img.shields.io/badge/mathmodels-0.0.14-1f9e89)

**把本机 R + mathmodels 包变成可复现的建模算力：一次运行 = 脚本 + 日志 + 表格 + 图形 + 会话信息，论文里每个数字都能指回文件。**

[看效果](#效果示例) · [六个范例](#六个可直接套用的范例) · [安装](#快速开始) · [触发方式](#触发方式) · [它和同类有什么不同](#它和同类有什么不同) · [安全边界](#安全边界)

</div>

---

## 它解决什么问题

给一个数学建模任务，你大概会这么干：翻在线书找函数，抄一段代码，粘进 RStudio，改到
能跑，然后……图的中文变成了方框，导出的 CSV 用 Excel 打开是乱码，脚本三个月后再跑
已经报错。三件事反复发生：

**第一，方法选得对不对没人替你判断。** mathmodels 有 162 个导出函数，覆盖综合评价、
预测、微分方程、多元统计、数据清洗、统计推断。同一道题里能用的方法往往有五六个，
堆一起就成了"方法大杂烩"，评委一看就知道没有取舍。

**第二，中文和编码的坑每次都踩。** 本机实测：Git Bash 会把 `LC_CTYPE` 导出成
`C.UTF-8`，Windows R 不认，于是 UTF-8 源码里的中文字面量直接解析失败，中文路径被
静默截断。而 `cairo_pdf()` 和 `pdf()` 用默认字体族输出中文是**方框或空白**——
很多人以为"能导出 PDF 就是成功"，实际上交付物是坏的。

**第三，跑出来的东西进不了论文。** 控制台里滚过去的数字，没人能追溯；图没存文件；
参数没记录；换个数据重跑结果就对不上。

这个 skill 把这三件事各钉死一层：**选型表 + 配方库**解决方法选择；**运行器 + 工作台
脚本**解决编码与字体；**run 目录**解决可复现。

---

## 效果示例

一次真实端到端运行（四类任务：综合评价 / 传染病 ODE / 时间序列 / 统计推断），
产物原样存在 `examples/e2e-run/`：

```text
▶ run 目录: runs/20261010-233025
▶ 退出码  : 0
    - INFO 表格 -> tables/topsis_ranking.csv  20 行 x 4 列
    - INFO TOPSIS 最优对象：R11，得分 100
    - INFO R0 = 1.5；峰值 69.7 人，出现在第 65 天
    - INFO 表格 -> tables/sarima_forecast.csv  12 行 x 4 列
    - INFO t 检验 p 值 = 0.07939
    [mmr] 完成：6 表, 8 图, 耗时 6.2s
```

导出的综合评价排名表（`tables/topsis_ranking.csv`，UTF-8+BOM，Excel 双击不乱码）：

| 河流 | 相对接近度 | 得分 | 排名 |
|---|---:|---:|---:|
| R11 | 0.809192 | 100 | 1 |
| R9 | 0.726053 | 87.207014 | 2 |
| R10 | 0.713845 | 85.328483 | 3 |

同一次运行导出的 `figs/topsis_scores.pdf`（矢量、中文正常）与
`figs/sir_compartments.png`——**PDF 那条路径是最容易翻车的一环，这里的文件名可以
直接打开核验。**

全模块冒烟测试结果（`examples/smoke-report.md`）：

```text
冒烟结果：35 项通过，0 项失败
```

---

## 六个可直接套用的范例

书稿与文章里**没有正确示例**的高频函数（`weight_entropy` / `weight_critic` / `weight_cv`、
11 个 `mf_*` 隶属函数……）在下面 6 个范例里都补齐了。**每个都在本机 mathmodels 0.0.14
上实跑通过**，目录里躺着真实的 `log.md` 与 `tables/*.csv`，可对着核对列名与图的样子。

| 范例 | 解决什么 | 覆盖函数 | 产物 |
|---|---|---|---|
| `01-comp-eval` | 多级指标体系综合评价、四种赋权 + AHP 组合 + TOPSIS | `weight_entropy`/`weight_critic`/`weight_cv`/`AHP`/`combine_weights`/`topsis` | 5 表 6 图 |
| `02-fuzzy-eval` | 模糊综合评价全链路、模糊统计、专家区间拟合 | 11 个 `mf_*`/`compute_mf`/`fuzzy_eval`/`defuzzify` | 5 表 8 图 |
| `03-dea-efficiency` | DEA 四种组合 + 超效率 + 非期望产出 SBM + Malmquist 面板 | `basic_DEA`/`super_DEA`/`basic_SBM`/`malmquist` | 4 表 6 图 |
| `04-regional-economy` | 基尼/洛伦兹/泰尔三种分解 + 区位商/HHI/EG | `gini`/`theil_g*`/`LQ`/`HHI`/`EG` | 8 表 8 图 |
| `05-system-eval` | 耦合协调度（标准 vs 修正）+ 障碍度 | `weight_entropy`/`coupling_degree`/`obstacle_degree` | 7 表 6 图 |
| `06-grey-prediction` | GM(1,1) 全链路 + 灰色族选型 + 马尔可夫修正 | `GM11`/`GM1N`/`DGM21`/`verhulst`/`markov_chain`/`GM11_markov` | 9 表 8 图 |

**路由表在 [`examples/index.md`](examples/index.md)**：按用户的提问方式或想用的函数，
直接定位到该看哪个范例。范例里带 ★ 的坑（如 `LQ()` 必须补"全国合计"行、`basic_SBM()`
不能传 `orientation`）都写进了各案例的 `README.md`。

一键回归全部 6 个范例：

```bash
bash tests/run_all_examples.sh     # 应输出「6 通过 / 0 失败」
```

---

## 快速开始

这是**本地技能**，装到 WorkBuddy 的用户技能目录即可：

```bash
cp -r <本目录> ~/.workbuddy/skills/mathmodels-r
```

装完先做环境自检：

```bash
Rscript --vanilla ~/.workbuddy/skills/mathmodels-r/scripts/check_env.R
```

装完对 Agent 说：

```text
用 mathmodels-r 帮我做一份多指标综合评价：先跑环境自检，再按熵权法+TOPSIS 出排名表和中文图
```

换机器或换 R 版本时，只需指定 R 位置：

```bash
export MMR_RSCRIPT="/c/Program Files/R/R-4.5.0/bin/Rscript.exe"
```

---

## 触发方式

- 用 R 做数学建模 / 帮我把这套指标算出来
- mathmodels 里有没有做 X 的函数
- 熵权法 + TOPSIS 出一份排名表
- AHP 权重算一下，顺便看 CR 过不过
- 灰色预测 GM(1,1) 预测下三期
- DEA 算效率、耦合协调度、障碍度
- SARIMA 预测未来 12 期并画图
- 用 SIR 模型模拟疫情并算 R0
- 帮我把 R 脚本跑起来，图表都要存文件

---

## 能做什么 / 它会交付什么

| 能力 | 覆盖的方法 | 交付物 |
|---|---|---|
| 多指标综合评价 | AHP、熵权、CRITIC、CV、PCA/FA 赋权、组合赋权、TOPSIS、灰关联、RSR、模糊综合 | 排名表 CSV + 得分图 + 权重表 |
| 效率与系统评价 | DEA（CCR/BCC/SBM/超效率/Malmquist）、耦合协调度、障碍度、基尼/泰尔、区位熵/HHI/EG | 效率表、障碍度表、指数表 |
| 预测 | 灰色（GM(1,1)/GM(1,N)/DGM(2,1)/Verhulst）、Markov、灰色-马尔可夫、回归四族、SARIMA/ETS/ARIMAX | 预测表（含区间）+ 预测图 |
| 微分方程与传染病 | 任意 ODE 方程组、Malthus/Logistic/SI/SIS/SIR/SEIR/LV、R0 与峰值指标 | 轨迹图、相图、R0 表 |
| 多元统计 | PCA、EFA、层次/K-means 聚类与有效性指标、判别、对应分析、MDS、典型/偏相关 | 载荷表、聚类表、判别混淆矩阵 |
| 数据清洗 | 缺失诊断（含 Little's MCAR）、三类插补、多重插补与 Rubin 合并、异常值三态处理、透视表 | 清洗前后对照表、异常清单 |
| 统计推断 | t/Wilcoxon/ANOVA/Kruskal/ANCOVA/相关/卡方/正态/方差齐性、Bootstrap、置换检验 | tidy 结果表 + Word/LaTeX 三线表 |

每次运行固定产出：`script.R`、`log.md`、`meta.txt`（耗时/退出码）、`sessionInfo.txt`、
`tables/*.csv`、`figs/*.png` + `*.pdf`。

---

## 它和同类有什么不同

| 维度 | 一般做法 | 本 skill |
|---|---|---|
| 函数调用正确性 | 靠记忆或照抄在线书（书里还是 0.0.9 的旧函数名） | 机器生成的 API 索引 + 一张 34 条「签名速查」+ 6 个实跑范例，全部经实跑校对 |
| 中文绘图 | 默认设备出 PDF，中文变方框仍被当成成功 | PNG 走默认设备、PDF 强制 `cairo_pdf` + `Microsoft YaHei`；两种格式同时导出 |
| 中文编码 | 反复改代码，或给脚本加 BOM / 传 `--encoding=UTF-8`（实测都报错） | 运行器统一清 `LC_*` 环境变量——这是唯一实测有效的解法 |
| 可复现性 | 控制台回显 + 手工另存 | 每次运行一个 run 目录，脚本/日志/表格/图/会话信息成套落盘 |
| 回归验证 | 无 | 35 项全模块冒烟测试入库，包升级后一跑就知道哪些调用点失效 |
| 方法选择 | 想到什么用什么 | 选型表按任务结构给首选+备选，并写明组合纪律（避免方法大杂烩） |

---

## 安全边界

**不会做的事**：

- 不删除或覆盖你已有的脚本、数据、run 目录（需要时先问）；所有产物写进新建的 run 目录；
- 不安装 R 包、不改 `.libPaths`、不动系统配置——依赖缺失时只报告，由你决定是否安装；
- 不联网取数（`read_nbs()` 之外），不调用外部 API；
- 不把模型结果包装成因果结论，不省略基线对比与误差指标。

**会停下来问你的事**：

- 环境自检有未通过项，且修复需要改动你的环境时；
- 建模任务实际需要"拆题 → 论文 → LaTeX"全流程时（本 skill 只管算力层，会建议切到
  `math-modeling-flow`）；
- 数据口径冲突、单位不明、或结果要写进正式论文而数据源存疑时。

---

## 文件结构

```
SKILL.md                    工作流、硬规则、强制停手点、验收单
references/
  recipes.md                选型表 + 签名速查（34 条实测易错点）+ 14 个最小配方
  function-index.md         162 个导出函数索引（从包源机器生成）
  r-environment.md          本地 R 环境与编码地雷清单
scripts/
  run_r.sh                  运行器：清 LC_*、定位 Rscript、落 run 目录、收集产物
  mmr.R                     R 侧工作台：日志、CSV(BOM)、PNG/PDF 中文安全导出
  check_env.R               环境自检（人读 / --json）
  gen_function_index.R      重新生成 function-index.md
tests/
  smoke_all_modules.R       35 项全模块冒烟测试
  run_all_examples.sh       一键回归 6 个范例并回收产物
examples/
  index.md                  ★ 路由表：用户问法 / 函数 → 该看哪个范例
  data/                     8 份真实数据（书稿案例原样打包，172 KB）
  cases/                    6 个实跑通过的范例（各含 script.R + README.md + 真实产物）
  e2e-run/                  一次真实运行的完整产物
  smoke-report.md           冒烟测试报告
```

---

## 验证与测试

```bash
# 环境自检（9 项应全 OK）
Rscript --vanilla scripts/check_env.R

# 全模块冒烟（应输出「35 项通过，0 项失败」，退出码 0）
bash scripts/run_r.sh tests/smoke_all_modules.R

# 6 个范例全量回归（应输出「6 通过 / 0 失败」，并把产物回收进各案例目录）
bash tests/run_all_examples.sh

# 端到端样例（应退出码 0，run 目录里有 6 表 8 图）
bash scripts/run_r.sh examples/e2e-run/script.R
```

验收一条 prompt：

```text
用 mathmodels-r 对 water_quality 做综合评价：熵权法定权、TOPSIS 排序，
导出排名 CSV 和中文图，并说明得分最高的对象。
```

合格表现：退出码 0；`tables/` 里有排名表且中文表头正常；`figs/*.pdf` 打开后中文不是
方框；`log.md` 里没有 `TRUE` 噪声行；能报出最高分对象与其得分。

---

## 致谢

- 方法学与接口来自张敬信的 R 包 **mathmodels**（AGPL-3）：
  [GitHub](https://github.com/zhjx19/mathmodels) ·
  [在线手册](https://zhjx19.github.io/mathmodels-book/)
- 素材来源：本机 `mathmodels` 包源（`man/`、`_pkgdown.yml`、`NEWS.md`）、
  `mathmodels-book` 与 `建模文章` 的真实代码块。
- `examples/` 的 6 个范例与 8 份数据来自《数学建模：算法与编程实现》配套书稿的
  真实案例，已按 mathmodels 0.0.14 逐行校对并实跑通过。
- 2026-10-11：向 `mathmodels` 作者提交逐行补丁建议，其中 6 条已在 0.0.14 工作树修复并重装
  （`fuzzy_eval` 算子 5、`theil_g2_nest` 的 `ratio` 取值与重名、`mf_dsigmoid` 文档、
  `markov_chain` 的 `dimnames`、`weight_entropy` 告警、`basic_DEA`/`super_DEA` 告警）；
  本 skill 的范例、签名速查与硬规则已按**修后行为**重新校验（明细见
  `references/recipes.md` 第四节「上游修复记录」）。其中 `super_DEA` 的 LP 不可行分支
  此前被作者记为"复现不出"，由本 skill 提供 **6 行最小复现**后确认为**可确定性复现**
  （`vrs` + 极端 DMU 必现，`crs` 永不失效）——范例 03 据此补了 CRS/VRS 对照表与回归护栏。
- 工程做法（环境清 `LC_*`、PDF 字体族、CSV BOM）全部为本机实测结论，
  见 `references/r-environment.md`。

## License

随宿主项目分发；`mathmodels` 包本身为 AGPL (>= 3)。
