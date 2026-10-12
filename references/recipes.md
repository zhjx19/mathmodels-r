# 建模任务配方（基于 mathmodels 0.0.14，本机实跑校对）

> 本文件的三类内容：
> ① **选型表**——拿到建模任务先在这里定位方法；
> ② **签名速查**——易踩的接口事实，全部经 `tests/smoke_all_modules.R` 与
>   `examples/cases/` 的 6 个范例实跑校对；
> ③ **最小配方**——每个任务一段可直接抄用的代码。
>
> 拿到任务**先查 `examples/index.md` 路由表**；命中就照案例改，没命中再用本文件。
> 包版本升级后，先跑 `bash scripts/run_r.sh tests/smoke_all_modules.R` 与
> `bash tests/run_all_examples.sh`，失败项就是需要更新的配方锚点。
> 完整函数清单见 `references/function-index.md`。

---

## 一、选型表

| 建模任务 | 首选 | 备选 / 补充 |
|---|---|---|
| 多指标综合评价与排序 | 熵权 `weight_entropy()` + `topsis()` | CRITIC `weight_critic()`、CV `weight_cv()`、PCA `weight_pca()`、因子 `weight_fa()`；灰关联 `grey_corr_topsis()`；秩和比 `rank_sum_ratio()` |
| 主观赋权 / 层次结构 | `AHP()`（含一致性比率 CR） | 与客观权组合 `combine_weights()`（linear / multiplicative / game / game_linear） |
| 模糊综合评价 | `mf_*()` + `compute_mf_funs()` + `compute_mf()` + `fuzzy_eval()` + `defuzzify()` | `plot_mf()` 画隶属函数 |
| 效率评价（投入产出） | `basic_DEA()` / `super_DEA()` | `basic_SBM()` / `super_SBM()`；面板用 `malmquist()` |
| 系统协调与瓶颈 | `coupling_degree()`（耦合协调度） | `obstacle_degree()`（障碍度，找关键约束） |
| 差距 / 不平等测度 | `gini()`、`theil()` | 分组 `theil_g()`、嵌套 `theil_g2_nest()` / `theil_g2_cross()` |
| 区域 / 产业集聚 | `LQ()`（区位熵） | `HHI()`、`EG()` |
| 小样本趋势外推 | `GM11()` | 非单调 `DGM21()`；饱和 S 形 `verhulst()`；多因素 `GM1N()` |
| 状态转移 / 波动预测 | `markov_chain()` | 灰预测 + 马尔可夫修正 `GM11_markov()` |
| 影响因素 / 因果解释 | `reg_lm()` | 二值 `reg_logistic()`、计数 `reg_poisson()`、过离散 `reg_negbin()` |
| 时间序列预测 | `ts_sarima()` + `ts_forecast()` | `ts_ets()`、带外生变量 `ts_arimax()`；分解 `ts_stl()` |
| 插值 / 曲线拟合 | `interp_spline()`、`poly_fit()` | `interp_linear/poly/hermite()`；`curve_fit()`、`growth_fit()` |
| 微分方程 / 传染病 | `ode_solver()`（任意方程组） | 内置 `ode_malthus/logistic/si/sis/sir/seir/lv()`；指标 `epi_metrics()` |
| 降维 / 因子 | `mv_pca()` | `mv_efa()` |
| 聚类 | `mv_kmeans()` | `mv_hclust()`；有效性 `mv_cluster_metrics()` |
| 判别 / 相关结构 | `mv_discrim()` | `mv_cancor()`、`mv_pcor()`；`mv_corresp()`、`mv_mds()` |
| 数据清洗 | `na_summary()` → `na_mcar_test()` → `impute*()` → `outlier()` | 透视 `pivot_table()` |
| 假设检验 | `stat_*()` 全家族 | 重抽样 `stat_bootstrap()`、`stat_perm_test()` |
| 表格出稿 | `export_table()`（Word / LaTeX 三线表） | — |

**组合纪律**：不要把 AHP、熵权、CRITIC、PCA、TOPSIS 一股脑堆在一起。每种赋权只在承担
**不同角色**时才并存（如 AHP 表达偏好、熵权表达信息量），并且要给出冗余性检验。

---

## 二、签名速查（★易错点，全部实测校对）

| 事实 | 说明 |
|---|---|
| `index` 有两套约定 | 赋权族（`weight_entropy` / `weight_critic` / `weight_pca` / `weight_fa`）的 `index` 允许 `NA`（表示该列已归一化、不再重标化）；**`topsis()` 与 `grey_corr_topsis()` 只认 `"+"` / `"-"`**，传 `NA` 直接报 `index must contain only "+" and "-"`。中心化/区间型指标必须先用 `rescale_middle()` / `rescale_interval()` 转成正向，再在 TOPSIS 里标 `"+"`。 |
| ★ `weight_entropy()$s` 是 **0–100 量纲** | 综合得分已做过缩放（实测 10.02 ~ 97.89），**不要再乘 100**，否则得分虚高到几千分。`weight_critic` / `weight_cv` 同族同理（用前先看 `$s` 的实测范围）。**注：这是 Rd `\value` 已写明的契约（`scaled by 100`），不是包的缺陷。** 0.0.14 起另加**尺度混用**告警：有 `+`/`-` 列被重缩放、且某 `NA` 列取值 > 1 时告警（`index = NULL` 的默认用法保持安静）。 |
| `grey_corr_topsis(X, w, index)` 的 `X` 必须是 **data.frame** | 传 `matrix` 会被 `lapply` 按元素迭代，报 `x has zero range; cannot rescale`。 |
| `rank_sum_ratio()` 的数据**必须带 `ID` 列** | 缺 ID 列会报 `object 'ID' not found`。 |
| `gini(y, pop)` / `theil(y, pop)` 的 `pop` 必填 | 不传报 `argument "pop" is missing`。`theil_g(data, group, y, pop)` 的 `group`/`y`/`pop` 传**列名字符串**，不传列向量。 |
| DEA 是「数据框 + 列名」接口 | `basic_DEA(data, inputs = c("x1","x2"), outputs = c("y1","y2"))`；返回字段是 **`efficiencies`（复数）**，不是 `efficiency`。`data` 必须是 data.frame 且**第 1 列是 DMU 名**，传 `matrix` 直接报错。 |
| ★ `basic_SBM()` 是**非导向**模型 | v0.0.14 起 **不能传 `orientation`**，否则报 `SBM models are non-oriented; orientation is not applicable.`（`mathmodels-book` 的 `dea.qmd`，截至 2026-10 的书稿快照，照抄会报错）。非期望产出用 `ud_outputs =` 指定在 outputs 里的第几列。 |
| ★ 超效率 `super_DEA()$efficiencies` 可能是 `NA` | 部分 DMU 线性规划无可行解是固有现象，**必须显式补齐**（常用标准 BCC 效率填充），否则排序会**漏掉**这些 DMU。**0.0.14 起 `basic_DEA()` / `super_DEA()` 在求解器失败时会汇总告警**（列出 DMU 名）——但告警**不会替你填值**。**触发条件已定位**：只有 `super_DEA` + `rts = "vrs"` + 存在极端 DMU（产出高到其余单元的**凸**组合够不着）才会发生；`crs` 的锥形包络可无限放大，**永不失效**；`basic_DEA` 参考集含自身（`theta = 1, lambda = e_i` 恒可行），真实数据打不到该分支，那里的告警纯属防御。可复现例见案例 03。 |
| ★ `LQ(data, region, total, .cols, .by)` 每组**第一行必须是"全国合计"行** | 源码 `quotient = function(x) x[-1] / x[1]` 拿组内第一行当分母并从输出中删除。只传真实地区会**静默错算**（实测 31 省 → 返回 30 行、上海被当参照删掉，且**没有任何一个省的 LQ 与正确值一致**、最大偏差 0.42）——务必补全国行 + `stopifnot(grepl("全国", first_rows))` 守卫 + 手工公式对拍。**注：Rd `\details` 已声明该要求（并点名 "silently wrong"），属调用者责任，不是包的缺陷。** `region`/`total`/`.cols` 走 tidyselect（传列名符号），`.cols` 要指向**数值列**。 |
| ★ `theil_g2_nest()` 的 `ratio` 与 `theil` **不等长**（`theil` = 4 + G1 + K，`ratio` = 4 + 2·G1 + K，K = 实际出现的 group1×group2 组合数；嵌套数据里 K = Σ 各 group1 内的 group2 个数，**不是** G1·G2） | 实测 income.xlsx（G1 = 4 区域、K = 31 地区）泰尔 39 项 / 贡献率 43 项，**差值恰为 G1 = 4**。**0.0.14 已修**：多出的"各一级分组的组内总贡献"块改名为 `东北.within` / `东部.within` …（不再与前面的组间项重名，且取值已按组正确折叠——此前该块每组拿到的都是全局合计）。**仍不能按名或按位置对齐**（两向量长度不同）——按名单独取（`ratio[grepl("\\.within$", names(ratio))]`），或把 `theil`/`ratio` 各自转长表。表内列名是 `T`/`Tb_g1`/`Tb_g2`/`Tw`（**不是** `Tb`），分组项用 `"_"` 拼成 `东部_上海` 这种形式，不是"组间""组内"。贡献率只有 `Tb_g1+Tb_g2+Tw`（嵌套）或 `Tb+Tw`（单/交叉）等于 1，不能整体求和（含 `T=1`）。⚠️ 单分组 `theil_g()` 与交叉 `theil_g2_cross()` 的 `theil`/`ratio` 是**等长**的——只有嵌套的 `theil_g2_nest()` 不等长。 |
| `reg_*()` 公式在前、数据在后 | `reg_lm(mpg ~ wt + hp, data = mtcars)`；系数表在 **`$coefficient`（单数）**，不是 `$coefficients`。 |
| `poly_fit()` / `curve_fit()` / `growth_fit()` 的 `$coefficient` | 是 tidy 系数表（`poly_fit` 为 degree + 1 行，含截距），不是数值向量。 |
| `interp_*()` 返回 tibble | 返回 `tibble(x = xout, y = 插值)`，行数等于 `length(xout)`，不是标量。 |
| `mv_efa(data, cols, factors)` | 参数名是 **`factors`**，不是 `nfactors`。 |
| `mv_*()` 的 `data` 必须是 **data.frame** | 传 `matrix`（如 `scale(...)` 的结果）报 `data must be a data.frame`；聚类前用 `as.data.frame(scale(...))`。 |
| `mv_cancor(mtcars, x_cols, y_cols)` | `x_cols`/`y_cols` 要给**具名字符向量**（如 `c("mpg","disp")`）；传数字区间 `2:3` 会报 `dimnames` 长度不匹配。 |
| `mv_corresp()` 吃**长表** | `mv_corresp(data, row = "r", col = "c", nf = 2)`，`data` 是含频数列的长表，不是交叉矩阵。 |
| `mf_*()` 的 `params` 个数不统一 | `mf_tri` 3 个、`mf_trap` 4 个、`mf_gauss` 2 个、`mf_gbell` 3 个、`mf_gauss2` 4 个、`mf_sigmoid` 2 个、`mf_psigmoid` 4 个、`mf_z` 2 个、`mf_pi` 4 个、`mf_s` 2 个、`mf_dsigmoid` 4 个。 |
| ★ `mf_dsigmoid()` 是**唯一可能取负值**的隶属函数（`[0,1]` 假设对它不成立） | 它是两个 sigmoid 之差，值域 `[-1,1]`，**`c1 > c2` 时为负**。实测 `params = c(1,1.5,9,1.5)` → `[-0.375, 0.375]`；文档示例 `c(5,2,5,7)`（`c1<c2`）→ `[0, 1]`，把两中心对调成 `c(5,7,5,2)` → `[-1, 0]`。**0.0.14 已订正 Rd**（`\value` 单列该条并说明可为负），`fuzzy_eval()` 的 `R must contain only values between 0 and 1` 报错文案也已指向 `mf_dsigmoid()`。要用它当隶属度请先剪到 `[0,1]`，或改用 `mf_psigmoid()`（两 sigmoid 之积，恒 `[0,1]`）。 |
| `compute_mf_funs(knots)` 返回 `length(knots)` 个函数 | 不是 `length(knots) + 1`。 |
| `fuzzy_eval(w, R, type = 5)`（均衡平均型）遇到某评语等级行全 0 | **0.0.14 已修**：该等级隶属度记 **0**，其余照常归一（实测 `w = c(.2,.1,.15,.3,.25)`、R 首行全 0 → `0, 0.4688, 0.5312`）。仅当**所有**等级都不可行才报 `Normalization failed: sum of B is zero.`（这句现在可达了）。算子 1~4 无此问题。老版本才需要 `tryCatch` 兜底。 |
| `epi_metrics()` 的字段是 `peak_infection` | 不是 `peak`。完整字段：`R0`、`peak_infection`、`peak_time`、`attack_rate`。 |
| `ode_lv()` 的分区名是 `x` / `y` | 不是 `prey` / `predator`；参数名 `alpha` / `beta` / `delta` / `mu`。传错分区名报 `'init' contains compartment(s) not used by this model`。 |
| 所有 `ode_*()` 接口统一 | `ode_xxx(init, params, times, ...)`，返回含 `time` 列的数据框；`ode_solver(init, times, equations, params, method = "lsoda")` 用**字符串方程**。 |
| `ts_*()` 要求**完整无缺失**的 `ts_df` | 先 `as_ts_df()` → `complete_ts_df()` / `impute_ts_df()` → `ts_sarima()`。 |
| `ts_transform()` → `ts_back_transform()` | `ts_back_transform(fc, tr$params)` 把对数/Box-Cox 尺度的预测还原到原尺度；若 `params` 含差分，需要历史序列才能还原。 |
| `stat_anova()` 返回 2 行 | 处理项 + Residuals；`stat_t_test()` 等返回 1 行。 |
| `stat_*()` 参数名分两类 | 连续变量族用 `.cols`（`stat_describe` / `stat_t_test` / `stat_cor` / `stat_normality` / `stat_hov_test` / `stat_bootstrap`）；分组族用 `resp` + `group`（`stat_anova` / `stat_kruskal`）；列联表用 `row` + `col`（`stat_chisq`）。 |
| `impute_multiple()` 返回裸 list | `length(mi) == m`，每个元素是一个插补后数据框；补充信息放在属性 `attr(mi, "methods" / "trace" / "n_imputed")`。配 `rubin_pool(est, err)` / `pool_fit(fits)` 汇总。 |
| `outlier()` 的 `to` 决定返回什么 | `to = "detect"` 返回**异常记录清单**（`variable`/`row`/`value`/`bound_low`/`bound_high`）；`to = "na"` / `"cap"` 返回**处理后的完整数据**。 |
| `pivot_table(data, index, columns, values, aggfunc)` | 参数名是 `index` / `columns` / `values`，不是 `rows` / `cols` / `fun`。 |
| `markov_chain()` 返回 4 个字段 | `trans_mat`（**contingency table**，`dimnames` 名 `from`/`to`）/ `pred_probs`（**matrix**，行名 `T1..Tn`）/ `pred_states`（逐步最可能状态）/ `pi_final`（终态分布）。**0.0.14 已给 `trans_mat` 的 `dimnames` 命名**，`as_tibble(trans_mat, rownames = "从\\到")` 不再报 `Names can't be empty`（但会把 dimnames 名当列名，产生**重复的 `from` 列**）。**最稳的转换仍是** `tibble::rownames_to_column(as.data.frame(x, check.names = FALSE), var = "从\\到")`；`pred_probs` 是普通 `matrix`，`as_tibble()` 会静默丢行名。 |
| ★ `GM11_markov()` 返回表末尾 `T+1..T+k` 行 `Raw` 为空 | 外推期没有真值：算误差均值要 `na.rm = TRUE`，作图先 `filter(!is.na(Raw))`，否则 ggplot 出 `Removed n rows` 警告。 |
| ★ `as_tibble()` **静默丢弃行名** | 要用行名当第一列，必须**先 `tibble::rownames_to_column(d, var = "...")` 再 `as_tibble()`**；顺序反了会得到 `1,2,3` 而非真实标签。 |
| 旧版函数名已更名 | `entropy_weight`→`weight_entropy`、`critic_weight`→`weight_critic`、`cv_weight`→`weight_cv`、`pca_weight`→`weight_pca`；`tri_mf`→`mf_tri` 等全套 `mf_*`；`model_sir`→`ode_sir` 等全套 `ode_*`。**在线书 `mathmodels-book` 的书稿快照（截至 2026-10）仍是旧名，抄代码要先换名**；书稿更新后此提示作废，复核清单见 SKILL.md §9。 |

---

## 三、最小配方

> 全部可直接粘进脚本运行；`mmr_*()` 来自 `scripts/mmr.R`（见 SKILL.md 的脚本骨架）。

### 1. 综合评价：预处理 → 熵权 → TOPSIS → 排名

> ★ 完整可跑范例（多级指标体系 + AHP 组合赋权）：`examples/cases/01-comp-eval/`

```r
data(water_quality)
df <- water_quality |>
  dplyr::mutate(PH = rescale_middle(PH, 7),           # 中心型指标：越接近 7 越好
                nutrient = rescale_interval(nutrient, 10, 20))   # 区间型：落在 10-20 最好
idx_w <- c("+", NA, "-", NA)     # 赋权：NA = 已归一化，别再重标化
idx_t <- c("+", "+", "-", "+")   # TOPSIS：只认 +/-；中心型/区间型上面已转正向
w  <- weight_entropy(df[-1], idx_w)$w
RC <- topsis(df[-1], w, idx_t)   # 相对接近度，越大越好
tb <- tibble::tibble(对象 = df$ID, 接近度 = RC,
                     得分 = rescale(RC, b = 100), 排名 = dplyr::min_rank(-得分)) |>
  dplyr::arrange(排名)
mmr_table(tb, "topsis_ranking")
# ★ weight_entropy()$s 已含 0-100 缩放（实测 10 ~ 98），用它合成时不要再乘 100
```

### 2. AHP + 客观权组合

```r
A <- matrix(c(1, 1/2, 4, 3, 3,  2, 1, 7, 5, 5,  1/4, 1/7, 1, 1/2, 1/3,
              1/3, 1/5, 2, 1, 1,  1/3, 1/5, 3, 1, 1), byrow = TRUE, nrow = 5)
ahp <- AHP(A)
stopifnot(ahp$CR < 0.1)                       # 一致性不达标必须先调判断矩阵
w_obj <- weight_entropy(X, index)$w           # X 为指标矩阵
w <- combine_weights(ahp$w, w_obj, type = "game")   # 也可 "linear"/"multiplicative"
```

### 3. 秩和比 RSR（★数据必须带 ID 列）

```r
df <- data.frame(ID = LETTERS[1:10], x1 = ..., x2 = ..., x3 = ...)
df1 <- df |> dplyr::mutate(dplyr::across(x2:x3, \(x) 1 / x))   # 负向指标取倒数
res <- rank_sum_ratio(df1, method = "int")
res$resultTable; res$rankTable
```

### 4. 模糊综合评价

> ★ 完整可跑范例（11 个 `mf_*` + 算子灵敏度 + 专家区间拟合）：`examples/cases/02-fuzzy-eval/`

```r
th  <- c(0.05, 0.15, 0.25, 0.50)          # 各等级的阈值（knots）
mfs <- compute_mf_funs(th)                # 返回 length(th) 个隶属函数
mu  <- compute_mf(0.07, th)               # 单个指标的隶属向量
w   <- c(0.3, 0.3, 0.3, 0.1)
R   <- matrix(c(0.8, 0.7, 0.6, 0.7,  0.1, 0.2, 0.2, 0.1,  0.1, 0.1, 0.2, 0.2),
              nrow = 3, byrow = TRUE)     # 每行一个等级，每列一个指标
mu_f <- fuzzy_eval(w, R, 3)               # 算子 1~5（均衡平均型 5 已容错：某等级全 0 记 0）
score <- defuzzify(mu_f, c(90, 75, 50), method = "weighted_average")  # 量化分须升序
```

### 5. DEA 效率

> ★ 完整可跑范例（四种组合 + 超效率 + SBM + Malmquist）：`examples/cases/03-dea-efficiency/`

```r
dea <- data.frame(dmu = ..., x1 = ..., x2 = ..., y1 = ..., y2 = ...)
r <- basic_DEA(dea, inputs = c("x1", "x2"), outputs = c("y1", "y2"))
r$efficiencies              # ★复数，不是 efficiency；data 必须 data.frame、第 1 列 DMU 名
basic_SBM(dea, inputs = c("x1","x2"), outputs = 3:4, ud_outputs = 2)  # ★不能传 orientation

# 超效率：VRS 下可能有 DMU 无可行解 → NA（会 warning 点名），必须显式补齐再排序
sup <- super_DEA(dea, inputs = c("x1","x2"), outputs = c("y1","y2"),
                 orientation = "io", rts = "vrs")
eff <- sup$efficiencies
eff[is.na(eff)] <- bcc$efficiencies[is.na(eff)]   # 用标准 BCC 效率填充
# 机理：VRS 把该 DMU 移出参考集后，其余单元的凸组合够不到它的产出 ⇒ LP 不可行；
#       CRS 无此问题。所以 rts 决定 NA 会不会出现，不是数据有错。
```

### 6. 灰色预测 + 马尔可夫修正

> ★ 完整可跑范例（GM 全链路 + 分摊到月 + 马尔可夫）：`examples/cases/06-grey-prediction/`

```r
GM11(x)$pnext                       # 下一期预测值（自动做级比检验）
DGM21(x)$pnext                      # 非单调摆动序列
verhulst(x)$pnext                   # 饱和 S 形序列
markov_chain(S, s0 = "A", n_steps = 3)   # trans_mat/pred_probs/pred_states/pi_final
GM11_markov(x, n_ahead = 3)         # 返回 Period/Raw/GM11_fitted/err_state/adj_eff/Markov_adj
```

### 7. 回归预测

```r
fit <- reg_lm(mpg ~ wt + hp, data = mtcars, step = TRUE)   # ★公式在前
fit$coefficient                     # ★单数：tidy 系数表
reg_logistic(am ~ wt + hp, data = mtcars)
reg_poisson(cyl ~ wt + hp, data = mtcars)
reg_negbin(cyl ~ wt + hp, data = mtcars)
```

### 8. 时间序列全链路

```r
x  <- as_ts_df(log(AirPassengers))          # 转成 ts_df
ts_test(x)                                  # ADF + KPSS 平稳性
tr <- ts_transform(x, method = "log", diff = 1, seasonal_diff = 1)
fit <- ts_sarima(tr$transformed)            # 或 ts_sarima(x) 自动定阶
fc  <- ts_forecast(fit, h = 12)
bt  <- ts_back_transform(fc, tr$params)     # 还原到原尺度
mmr_fig(plot_ts_forecast(x, bt), "forecast")
```

### 9. 微分方程 / 传染病

```r
# 内置模型：接口统一为 init / params / times
res <- ode_sir(init = c(S = 990, I = 10, R = 0),
               params = c(beta = 0.15, gamma = 0.1), times = seq(0, 120, by = 0.5))
m <- epi_metrics(res, beta = 0.15, gamma = 0.1, N = 1000)
m$R0; m$peak_infection; m$peak_time; m$attack_rate
mmr_fig(plot_compartments(res), "compartments")
mmr_fig(plot_incidence(res), "incidence")

# 自定义方程组：方程写成字符串
ode_solver(init = c(S = 1000, E = 1, I = 0, R = 0), times = seq(0, 200, by = 1),
           equations = c(S = "mu*N - beta*S*I - mu*S", E = "beta*S*I - alpha*E - mu*E",
                         I = "alpha*E - gamma*I - mu*I", R = "gamma*I - mu*R"),
           params = c(beta = 0.3, alpha = 0.2, gamma = 0.1, mu = 0.01, N = 1000))

# ★ Lotka-Volterra 的分区名是 x / y
ode_lv(init = c(x = 10, y = 5), params = c(alpha = 1.1, beta = 0.4, delta = 0.1, mu = 0.4),
       times = seq(0, 30, by = 0.5))
```

### 10. 多元统计

```r
mv_pca(mtcars, cyl:carb)                              # 降维
mv_efa(mtcars, cyl:carb, factors = 2)                 # 参数是 factors
mv_kmeans(mtcars, cyl:carb, centers = 3)              # data 必须是 data.frame
mv_hclust(mtcars, cyl:carb, k = 3)
mv_cluster_metrics(mtcars, cyl:carb, cluster = km$cluster)   # 轮廓系数等
mv_discrim(iris, Species, 1:4)                        # 结果在 $predictions / $confusion
mv_cancor(mtcars, x_cols = c("mpg", "disp"), y_cols = c("hp", "wt"))   # 具名字符向量
mv_pcor(mtcars, cols = c("mpg", "cyl", "disp", "hp"))
mv_corresp(data.frame(r = ..., c = ..., n = ...), row = "r", col = "c", nf = 2)  # 长表
mv_mds(mtcars, cols = 3:6, k = 2)
```

### 11. 数据清洗

```r
na_summary(pen)                                   # 缺失概览
na_mcar_test(pen, .cols = where(is.numeric))      # Little's MCAR 检验
impute(pen, .cols = where(is.numeric), method = "mean", .by = species)
impute_model(pen, .cols = bill_length_mm, model = "knn")   # knn / lm / tree
mi <- impute_multiple(pen, m = 5)                 # 返回 m 个数据框的裸 list
rubin_pool(est, err)                              # Rubin 合并
outlier(d, .cols = v, .by = g, to = "cap")        # detect 出清单；na / cap 出数据
pivot_table(d, index = k, columns = g, values = v, aggfunc = sum)
```

### 12. 统计推断 + 三线表

```r
stat_t_test(sleep, .cols = extra, group = group)        # 连续变量族用 .cols
stat_anova(iris, resp = Sepal.Length, group = Species)  # 分组族用 resp + group
stat_chisq(mtcars, row = cyl, col = am)                 # 列联表用 row + col
stat_bootstrap(mtcars, statistic = mean, .cols = mpg, B = 2000, seed = 1)
stat_perm_test(mtcars, .cols = mpg, group = am, n_perm = 2000, seed = 1)

export_table(stat_t_test(sleep, .cols = extra, group = group),
             output = "latex", path = "tables/ttest.tex", caption = "两样本 t 检验")
# output = "word" 时写 .docx，可直接贴进论文
```

### 13. 区域经济：不平等测度与集聚

> ★ 完整可跑范例：`examples/cases/04-regional-economy/`

```r
# 基尼系数：平均量数据必须人口加权，分组批量算就是整洁长表
inc |> summarise(Gini = gini(平均工资, 就业人数), .by = c(年份, 行业))

# 泰尔分解：参数是【列名字符串】；返回 list(theil=, ratio=)，统一转长表最稳
theil_g(inc, group = "行业", y = "平均工资", pop = "就业人数")
theil_g2_cross(inc, group1 = "行业", group2 = "区域", y = "平均工资", pop = "就业人数")
theil_g2_nest(inc, group1 = "区域", group2 = "地区", y = "平均工资", pop = "就业人数")
#   ★ theil_g2_nest 的 ratio 与 theil 不等长（ratio 多 G1 项），不能按名/按位置对齐；贡献率不能整体求和

# 区位商：★ 每组第一行必须是"全国合计"行（源码拿它当分母并删除）
nation <- ind |> summarise(地区 = paste0(intToUtf8(1), "全国"), across(-地区, sum), .by = 年份)
ind_all <- bind_rows(ind, nation) |> group_by(年份) |> arrange(地区, .by_group = TRUE) |> ungroup()
stopifnot(all(grepl("全国", ind_all |> summarise(.f = dplyr::first(地区), .by = 年份) |> pull(.f), fixed = TRUE)))
lq <- LQ(ind_all, 地区, GDP, contains("产业"), .by = 年份)

# 集聚：HHI 集中度 + EG 空间集聚
inc |> summarise(hhi = HHI(就业人数, scaled = TRUE), .by = c(年份, 行业, 区域))
```

### 14. 系统评价：耦合协调度 + 障碍度

> ★ 完整可跑范例：`examples/cases/05-system-eval/`

```r
# 每子系统先熵权综合评价（得分已 0-100），再归一化到 [0,1]
tech <- weight_entropy(cdev[3:5], rep("+", 3))
S <- bind_cols(cdev[1:2], map_dfc(list(tech, eco, env), "s") |> set_names(c("科技","经济","生态")))
S <- S |> mutate(across(3:5, rescale))          # 耦合协调度要求落在 [0,1]
w <- weight_entropy(S[3:5], rep(NA, 3))$w        # ★ 已归一化的列标 NA

S |> nest(.by = 年份) |>
  mutate(model = map(data, \(d) coupling_degree(d, w, id_cols = "地区"))) |>    # 或 type = "adjusted"
  unnest(model)                                   # 返回 ID/coupling/coord/coupling_coord

S |> nest(.by = 年份) |>
  mutate(model = map(data, \(d) obstacle_degree(d, w, id_cols = "地区"))) |>
  unnest(model)                                   # 二级指标障碍度；一级自行 summarise 汇总
```

---

## 四、上游修复记录（随包版本跟踪）

> 2026-10-11：对本机 `mathmodels 0.0.14` 做过一次"陷阱是不是包的缺陷"的系统评估
> （读 `asNamespace` 源码 + Rd 原文 + 实测三对照），并向作者提交了逐行补丁建议。
> **下列问题已在 0.0.14 的工作树中修复并重新安装**——本机安装路径
> `D:/R-4.6.1/library/mathmodels`，`packageVersion()` 仍是 `0.0.14`；作者侧
> `devtools::test()` 519 块 / 1436 条断言 **0 失败**、`devtools::check()` **0 error / 0 warning / 0 note**。
> 本技能已按修后行为校正，下表留作历史与版本辨识用。

| 位置 | 原现象 | 修后行为（本机实测） |
|---|---|---|
| `fuzzy_eval()` 算子 5 | 某评语等级行全 0 时除零得 `NaN`，`if (sum(B)==0)` 拿到 `NA`，抛 R 的 `missing value where TRUE/FALSE needed`；包自带文案**够不着** | 该等级记 **0**、其余照常归一（`0, 0.4688, 0.5312`）；全 0 才报 `Normalization failed: sum of B is zero.`（现可达）。`R must contain values between 0 and 1` 文案已指向 `mf_dsigmoid()` |
| `theil_g2_nest()` | `ratio`(43) 比 `theil`(39) 多 4 项，多出项与前面**同名不同值**；**且该块取值也错**（`summarise()` 里 `Rwi` 命中环境中的全长向量，分组失效，每组都拿到全局合计） | 改名 `东北.within` / `东部.within` …（名唯一），并用 `tapply(Rwi, df_within$group1, sum, na.rm = TRUE)` **按组正确折叠**（实测 `sum(.within) == ratio["Tw"]`）。两向量**仍不等长**，勿按名 / 按位置对齐 |
| `mf_dsigmoid()` | Rd `\value` 与其余 `mf_*` 一起声明 `[0,1]` | `\value` 单列该条：`[-1,1]`、`c1 > c2` 时为负、给出 `mf_psigmoid()` / 剪裁出路 |
| `markov_chain()` | `trans_mat` 的 `dimnames` 无维度名 → `as_tibble(x, rownames=)` 报 `Names can't be empty` | `dimnames` 命名为 `from`/`to`，`as_tibble()` 可用（会产生重复的 `from` 列，仍推荐 `as.data.frame()` + `rownames_to_column()`）。`@return` 已补注 |
| `weight_entropy()` | 缺上界校验：`index = c("+", NA)` 且 `NA` 列未归一化时零告警，`range(s)` 达 `[37.87, 440.29]` | 加**收窄版**告警：**有 `+`/`-` 列被重缩放 且 某 `NA` 列 > 1** 才告警（`index = NULL` 的默认用法保持安静，避免打在文档默认用法上） |
| `basic_DEA()` / `super_DEA()` | LP 失败时静默置 `NA`（`else` 分支为空） | 两个模型都加了失败汇总告警 `... LP infeasible for DMU(s): <名>; efficiency set to NA.`。**两者的可触发性不同**：`super_DEA` 是**真会触发**的诊断——`rts = "vrs"` + 极端 DMU 必现（6 DMU 最小复现：`io` → F、`oo` → A；`crs` 两种导向均不出现）；`basic_DEA` 参考集含自身、`theta = 1` 恒可行，真实数据打不到该分支，那里的告警是**纯防御性**（防求解器数值异常）。回归测试：`super_DEA` 用真实数据、`basic_DEA` 保留一条窄 mock |

**仍按其契约使用、不是包的错**（Rd 已声明，勿当缺陷报）：

- `LQ()` 每组第一行须为"全国合计"行（`\details` 写明并点名 "silently wrong"）——护栏（`check=`）未加，按契约用；
- `weight_entropy()$s` 是 0–100（`\value` 写明 `scaled by 100`）；
- `basic_SBM()` 不接受 `orientation`（设计如此；`mathmodels-book` 的 `dea.qmd` 需改书稿，截至 2026-10 快照尚未改）。

**`super_DEA` 不可行分支的复现结论（2026-10-11 已闭环）**：作者初版记为"复现不出"，
拿到上面的 6 行最小复现后**一次命中**，并更正为"可确定性复现"，同时说明了原搜索设计
的盲区（2 投入 1 产出 + 均匀分布，结构上产生不了极值点）。本机重装版逐条复跑一致：
`io + vrs → NA@F`、`oo + vrs → NA@A`、`crs` 两种导向**零告警零 NA**。

> **对使用者的含义**：`super_DEA` 下看到 `NA` **不是 bug、也不代表数据有错**，
> 而是 VRS 超效率的固有不可行性。要么按上面配方用标准 BCC 效率补齐后再排序，
> 要么在理论上允许时改用 `rts = "crs"`。

**`theil_g2_nest` 的尾巴：作者已决定不再变动（2026-10-11 确认）**——两项都**不要再按"待修"处理**：
① within 项继续用 `"_"` 拼分组名（组名含下划线理论上可能撞名，但改分隔符是破坏性变更）；
② `theil` / `ratio` 维持**不等长向量**，不改成等长 tibble（0.0.x 不做破坏性变更）。
按签名速查里"不等长、勿按名或按位置对齐"的写法用即可。

**包升级后的复核动作**：跑 `bash scripts/run_r.sh tests/smoke_all_modules.R` 与
`bash tests/run_all_examples.sh`；若某条修复回退，签名速查表对应行需恢复警告措辞。
