# 范例索引（路由表）

**用法**：先在这个表里按用户的问题找命中行；命中就**以该案例的 `script.R` 为蓝本**改，
不要凭记忆写包函数调用。**每个案例都在本机 mathmodels 0.0.14 上实跑通过**
（`bash tests/run_all_examples.sh` → 7 通过 / 0 失败），目录里躺着真实的
`log.md` / `tables/*.csv` / `figs/*.pdf`，可以对着核对列名与图的样子。

> 2026-10-11 起，这些案例是按**上游修复后重装的 0.0.14** 重新校验的（`fuzzy_eval` 算子 5、
> `theil_g2_nest` 的 `ratio`、`mf_dsigmoid` 文档、`markov_chain` 的 `dimnames`、
> `weight_entropy` 告警、`basic_DEA`/`super_DEA` 告警，共 6 条）。修复明细见
> `references/recipes.md` 第四节「上游修复记录」。

**为什么要有这些范例**：包在 0.0.13/0.0.14 更过一轮函数名，而常见素材（书稿、文章）
合计只演示了包的一部分函数，`weight_entropy` / `weight_critic` / `weight_cv` 三个最高频
赋权函数与 11 个 `mf_*` 隶属函数**缺少可直接运行的示例**。这 6 个案例就是把这些缺口补上。

---

## 一、按用户问法找案例

| 用户大概会这么说 | 案例 | 任务族 |
|---|---|---|
| "多级指标体系怎么算权重""熵权法和 AHP 怎么结合""用 TOPSIS 排名""CRITIC / 变异系数法赋权" | [`01-comp-eval`](cases/01-comp-eval/) | 综合评价与赋权 |
| "模糊综合评价怎么做""隶属函数怎么选 / 怎么写""评语集去模糊化""专家打分怎么汇总成隶属矩阵" | [`02-fuzzy-eval`](cases/02-fuzzy-eval/) | 模糊评价 |
| "DEA 效率怎么算""CCR / BCC / 超效率 / SBM 区别""面板 Malmquist 指数""投入产出效率排序" | [`03-dea-efficiency`](cases/03-dea-efficiency/) | 效率评价 |
| "基尼系数 / 泰尔指数怎么算、怎么分解""洛伦兹曲线""区位商 / HHI / EG 产业集聚""地区差距" | [`04-regional-economy`](cases/04-regional-economy/) | 不平等与集聚测度 |
| "耦合协调度怎么算""障碍度模型""多系统协调发展水平""瓶颈在哪里" | [`05-system-eval`](cases/05-system-eval/) | 系统评价 |
| "灰色预测 GM(1,1)""GM(1,N) / DGM / Verhulst 用哪个""马尔可夫链预测""灰色-马尔可夫修正" | [`06-grey-prediction`](cases/06-grey-prediction/) | 预测 |

**没命中怎么办**：回 `references/recipes.md` 的选型表 + 签名速查，按 §三 最小配方写。
本表只覆盖"最容易写错"的高频场景，不是全集。

---

## 二、按包函数找案例（覆盖锚点）

| 你想用的函数 | 去哪个案例看正确调用 | 备注 |
|---|---|---|
| `weight_entropy` | 01、05 | ★ 零示例函数；`$s` 已在 **0–100** 量纲，别再乘 100 |
| `weight_critic` / `weight_cv` | 01 | ★ 零示例函数 |
| `AHP` | 01 | 返回 `CR`（一致性比率），需 < 0.1 |
| `combine_weights` / `linear_sum` / `topsis` / `rescale` | 01 | `topsis` 的 `index` 只认 `"+"` / `"-"`，不能带 `NA` |
| `mf_tri` / `mf_trap` / `mf_gauss` / `mf_gbell` / `mf_gauss2` / `mf_sigmoid` / `mf_dsigmoid` / `mf_psigmoid` / `mf_z` / `mf_pi` / `mf_s`（共 11 个） | 02 | ★ 零示例函数；参数含义与值域见案例 02 表 1 |
| `compute_mf` / `compute_mf_funs` / `plot_mf` | 02 | |
| `fuzzy_eval` / `defuzzify` | 02 | 算子 1–5；均衡平均型 `type = 5` 遇"某等级全 0"已容错（0.0.14 修：该等级记 0） |
| `basic_DEA` / `super_DEA` / `basic_SBM` / `super_SBM` | 03 | ★ 效率字段是 `efficiencies`（复数）；SBM **不能传 `orientation`**；`super_DEA` 的 NA **只在 `vrs` 下出现**（VRS 凸组合够不到极端 DMU），必须显式补齐 |
| `malmquist` | 03 | 面板需要 `period` + 分组键，返回 `mi / ec / tc / pech / sech` |
| `gini` / `theil` / `theil_g` / `theil_g2_cross` / `theil_g2_nest` | 04 | ★ `theil_g2_nest` 的 `ratio` 与 `theil` **不等长**（多出 `*.within` 块），不能按名/按位置对齐 |
| `LQ` | 04 | ★ 每组**第一行必须是"全国合计"**，否则静默错算 |
| `HHI` / `EG` | 04 | |
| `coupling_degree` | 05 | 标准式与修正式都给，别只给一个 |
| `obstacle_degree` | 05 | 障碍度 + 一级指标汇总 |
| `GM11` | 06 | 返回 `fitted / pnext / f / mat / u / lambda / rng`；`f(1:n)` 做外推 |
| `GM1N` / `DGM21` / `verhulst` | 06 | 表 06_灰色模型族适用条件.csv 说明各自适用形态 |
| `markov_chain` | 06 | 返回 `trans_mat`（**table**）/ `pred_probs`（matrix）/ `pred_states` / `pi_final`；转 tibble 走 `rownames_to_column(as.data.frame(x))` |
| `GM11_markov` | 06 | 返回 `Period / Raw / GM11_fitted / err_state / adj_eff / Markov_adj` |

---

## 三、每个案例里有什么

每个案例目录统一是：`script.R`（可跑脚本）+ `README.md`（说明卡）+ 一次真实运行的
产物（`log.md` / `meta.txt` / `sessionInfo.txt` / `console.txt` / `tables/` / `figs/`）。

| 案例 | 数据 | 覆盖函数 | 产物 |
|---|---|---|---|
| 01-comp-eval | 就业质量 30 地区 × 11 指标 × 3 年 | 4 种赋权 + AHP + 组合赋权 + TOPSIS | 5 表 6 图 |
| 02-fuzzy-eval | 耕作方案 / 评委打分 / 129 位专家区间 | 11 个 `mf_*` + 合成 + 去模糊 | 5 表 8 图 |
| 03-dea-efficiency | 31 省医院投入产出 + 面板 | DEA 四组合 + 超效率 + SBM + Malmquist | 4 表 6 图 |
| 04-regional-economy | 31 省 × 8 行业 × 10 年 | 不平等分解 + 集聚测度 | 8 表 8 图 |
| 05-system-eval | 8 地区 × 10 年 × 3 子系统 | 熵权 + 耦合协调 + 障碍度 | 7 表 6 图 |
| 06-grey-prediction | 北京月度旅游人数 1997–2003 | 灰色族 4 模型 + 马尔可夫 | 9 表 8 图 |

数据文件在 [`data/`](data/)，全部来自《数学建模：算法与编程实现》配套书稿的真实案例，
已随 skill 打包（172 KB）。

---

## 四、怎么用（对 AI 的硬要求）

1. 命中案例后，**先读该案例的 `script.R` 与 `README.md`**，再动手改；
2. **不要**直接照搬任何素材里的函数名——凡出现旧名（`entropy_weight` /
   `critic_weight` / `cv_weight` / `pca_weight` / `tri_mf` 全套 / `model_sir` 全套），
   按 `references/recipes.md` 签名速查换成现行名再跑；
3. 改完跑 `bash scripts/run_r.sh <你的脚本.R>`，退出码必须为 0；
4. 案例里带 ★ 的坑都写在 `README.md` 的「踩过的坑」一节，动手前先看一遍；
5. 新增/修改案例后，跑 `bash tests/run_all_examples.sh` 做全量回归（产物会自动回收）。
