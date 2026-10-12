# ============================================================================
# smoke_all_modules.R —— mathmodels 全模块冒烟测试（本 skill 的验证资产）
#
# 用法:
#   bash scripts/run_r.sh tests/smoke_all_modules.R
#
# 作用：对 mathmodels 的每个功能模块各跑一条最小真实调用，断言返回结构与取值范围。
#       快速回答两个问题：
#         1) 本机环境能不能把这个模块跑起来？
#         2) 我记的函数签名 / 返回字段名还是不是当前版本的样子？
#       任何一条 FAIL 会打印 [FAIL] 行并在末尾汇总，退出码非 0。
#
# 纪律：这里只做「能立刻判定对错」的断言（字段是否存在、取值是否在合理区间），
#       不追求统计学意义上的结论——冒烟测试管"通不通"，不管"准不准"。
#
# 维护约定：本文件里的每次调用都经本机实跑校对过（见 references/recipes.md 的
#          「签名速查」）。包升级后先跑本文件，失败项即为需要更新的调用点。
# ============================================================================
source(file.path(Sys.getenv("MMR_HOME"), "scripts", "mmr.R"))
mmr_init(label = "mathmodels 全模块冒烟测试")

suppressPackageStartupMessages({
  library(mathmodels); library(dplyr); library(tibble); library(tidyr); library(ggplot2)
})

PASS <- 0L; FAIL <- character()
chk <- function(name, expr) {
  ok <- tryCatch({ force(expr); TRUE },
                 error = function(e) {
                   FAIL[[length(FAIL) + 1]] <<- paste0(name, " :: ", conditionMessage(e)); FALSE
                 })
  if (ok) { PASS <<- PASS + 1L; mmr_log(sprintf("[OK]   %s", name)) }
  else mmr_log(sprintf("[FAIL] %s", name), level = "ERR")
  invisible(ok)
}
within <- function(x, lo, hi) all(is.finite(x)) && all(x >= lo - 1e-9) && all(x <= hi + 1e-9)

# ---- 数据预处理 ------------------------------------------------------------
chk("预处理：rescale / normalize / standardize / to_positive", {
  x <- c(3, 5, 2, 7)
  stopifnot(within(rescale(x), 0, 1), within(normalize(x), 0, 1),
            abs(mean(standardize(x))) < 1e-9)
  # to_positive(type="minmax") 把负向指标反转成 max(x) - x，下界是 0
  stopifnot(all(to_positive(x) >= 0))
})
chk("预处理：rescale_middle / rescale_interval / 其余 rescale_* 家族", {
  x <- c(1, 5, 9)
  stopifnot(within(rescale_middle(c(6, 8, 7), 7), 0, 1),
            within(rescale_interval(c(5, 15, 25), 10, 20), 0, 1),
            within(rescale_extreme(x), 0, 1),
            # rescale_initial 是「除以首值」，量纲是倍数，不落在 [0,1]
            all(rescale_initial(x, type = "+") > 0),
            all(rescale_mean(x) > 0))
})

# ---- 赋权 ------------------------------------------------------------------
chk("AHP（含一致性比率 CR）", {
  A <- matrix(c(1, 1/2, 4, 3, 3, 2, 1, 7, 5, 5, 1/4, 1/7, 1, 1/2, 1/3,
                1/3, 1/5, 2, 1, 1, 1/3, 1/5, 3, 1, 1), byrow = TRUE, nrow = 5)
  r <- AHP(A)
  stopifnot(abs(sum(r$w) - 1) < 1e-8, r$CR < 0.1, length(r$w) == 5)
})
chk("客观赋权：weight_entropy / weight_critic / weight_cv（index 允许 NA）", {
  X <- data.frame(x1 = c(3, 5, 2, 7, 4, 6), x2 = c(10, 20, 15, 25, 12, 18), x3 = c(1, 3, 2, 5, 4, 6))
  i <- c("+", "-", "+")
  for (f in list(weight_entropy, weight_critic)) {
    r <- f(X, i); stopifnot(abs(sum(r$w) - 1) < 1e-6, within(r$s, 0, 100))
  }
  stopifnot(abs(sum(weight_cv(X)) - 1) < 1e-6)
})
chk("降维赋权：weight_pca / weight_fa（参数名是 nfs）", {
  X <- data.frame(x1 = c(3, 5, 2, 7, 4, 6), x2 = c(10, 20, 15, 25, 12, 18), x3 = c(1, 3, 2, 5, 4, 6))
  stopifnot(abs(sum(weight_pca(X, c("+", "-", "+"), nfs = 2)$w) - 1) < 1e-6,
            abs(sum(weight_fa(X, c("+", "-", "+"), nfs = 1)$w) - 1) < 1e-6)
})
chk("组合赋权：combine_weights（linear / multiplicative / game / game_linear）", {
  ws <- c(0.4, 0.3, 0.2, 0.1); wo <- c(0.25, 0.2, 0.3, 0.25)
  for (t in c("linear", "multiplicative", "game", "game_linear"))
    stopifnot(within(combine_weights(ws, wo, type = t), 0, 1))
})

# ---- 评价模型 --------------------------------------------------------------
chk("TOPSIS + linear_sum（index 只认 +/-，不接受 NA）", {
  A <- data.frame(X1 = c(2, 5, 3), X2 = c(8, 1, 6))
  rc <- topsis(A, c(0.6, 0.4), c("+", "-"))
  stopifnot(within(rc, 0, 1), length(rc) == 3, length(linear_sum(A, c(0.6, 0.4))) == 3)
})
chk("灰色关联：grey_corr / grey_corr_topsis（★X 必须传 data.frame，传 matrix 会按元素迭代报零极差）", {
  ref <- c(0.9, 0.8, 0.7)
  cmp <- data.frame(x1 = c(0.9, 0.7, 0.8), x2 = c(0.8, 0.9, 0.7), x3 = c(0.7, 0.8, 0.9))
  stopifnot(is.numeric(grey_corr(ref, cmp)))
  X <- data.frame(x1 = c(8, 7, 6), x2 = c(150, 180, 200), x3 = c(60, 80, 100))
  stopifnot(within(grey_corr_topsis(X, c(0.3, 0.4, 0.3), c("+", "+", "+")), 0, 1))
})
chk("秩和比 RSR：rank_sum_ratio（int / non-int；★数据必须带 ID 列）", {
  df <- data.frame(ID = LETTERS[1:5],
                   x1 = c(99.54, 96.52, 99.36, 92.83, 91.71), x2 = c(60.27, 59.67, 43.91, 58.99, 35.40),
                   x3 = c(16.15, 20.10, 15.60, 17.04, 15.01))
  stopifnot(nrow(rank_sum_ratio(df |> mutate(across(x2:x3, \(x) 1 / x)), method = "int")$resultTable) == 5,
            nrow(rank_sum_ratio(df, w = c(0.4, 0.3, 0.3), method = "non-int")$resultTable) == 5)
})
chk("模糊综合：compute_mf_funs / compute_mf / fuzzy_eval / defuzzify", {
  th <- c(0.05, 0.15, 0.25, 0.50)
  # compute_mf_funs 返回 length(knots) 个隶属函数（对应各评价等级）
  stopifnot(length(compute_mf_funs(th)) == length(th), within(compute_mf(0.07, th), 0, 1))
  R <- matrix(c(0.8, 0.7, 0.6, 0.7, 0.1, 0.2, 0.2, 0.1, 0.1, 0.1, 0.2, 0.2), nrow = 3, byrow = TRUE)
  mu <- fuzzy_eval(c(0.3, 0.3, 0.3, 0.1), R, 3)
  stopifnot(within(mu, 0, 1))
  # 0.0.14 修复的回归护栏：算子 5 遇「某评语等级行全 0」应记 0，而不是抛
  # "missing value where TRUE/FALSE needed"（历史 bug）。
  R0 <- matrix(c(0, 0, 0, 0, 0,
                 0.3, 0.4, 0.5, 0.2, 0.6,
                 0.7, 0.6, 0.5, 0.8, 0.4), nrow = 3, byrow = TRUE)
  mu5 <- fuzzy_eval(c(0.2, 0.1, 0.15, 0.3, 0.25), R0, 5)
  stopifnot(abs(sum(mu5) - 1) < 1e-12, mu5[1] == 0)
  # 只有所有等级都不可行时才报错（包自带文案此时应当可达）
  stopifnot(inherits(try(fuzzy_eval(c(0.5, 0.5), matrix(0, 2, 2), 5), silent = TRUE), "try-error"))
  s <- defuzzify(mu, c(90, 75, 50), method = "weighted_average")
  stopifnot(s > 50, s < 90, length(plot_mf(\(x) mf_tri(x, c(1, 5, 9)), xlim = c(0, 10))) >= 0)
})
chk("隶属函数族 mf_*（各函数要求的 params 个数不同，见下）", {
  stopifnot(within(mf_tri(1:10, c(1, 5, 9)), 0, 1),               # 3 个
            within(mf_trap(1:10, c(1, 5, 7, 8)), 0, 1),            # 4 个
            within(mf_gauss(1:10, c(5, 1.5)), 0, 1),               # 2 个
            within(mf_gbell(1:10, c(5, 1.5, 2)), 0, 1),            # 3 个
            within(mf_gauss2(1:10, c(1, 1.5, 7, 1.5)), 0, 1),      # 4 个
            within(mf_sigmoid(1:10, c(5, 1.5)), 0, 1),             # 2 个
            within(mf_psigmoid(1:10, c(1, 1.5, 7, 1.5)), 0, 1),    # 4 个
            within(mf_z(1:10, c(2, 6)), 0, 1),                     # 2 个
            within(mf_pi(1:10, c(2, 4, 6, 8)), 0, 1),              # 4 个
            within(mf_s(1:10, c(2, 8)), 0, 1))                     # 2 个
  # ★ mf_dsigmoid 是「两个 sigmoid 之差」，取值落在 [-1, 1] 而非 [0, 1]
  d <- mf_dsigmoid(seq(0, 10, 0.1), c(1, 1.5, 7, 1.5))
  stopifnot(within(d, -1, 1))                                      # 4 个
})
chk("DEA 家族：basic_DEA / super_DEA / basic_SBM / super_SBM", {
  # data 是数据框，inputs / outputs 是列名字符向量；返回字段是 efficiencies（复数）
  dea <- data.frame(dmu = LETTERS[1:6], x1 = c(2, 3, 4, 5, 3, 4), x2 = c(3, 4, 5, 6, 4, 5),
                    y1 = c(8, 9, 10, 12, 11, 13), y2 = c(5, 6, 7, 8, 7, 9))
  r1 <- basic_DEA(dea, inputs = c("x1", "x2"), outputs = c("y1", "y2"))
  stopifnot(length(r1$efficiencies) == 6, within(r1$efficiencies, 0, 1.5))
  # ★ 0.0.14 修复的回归护栏：VRS 超效率 + 极端 DMU ⇒ LP 不可行
  #   → 汇总 warning 点名 + 该 DMU 效率置 NA（io 失败于 F、oo 失败于 A；crs 两种导向均不失败）
  sup_warn <- function(orc, rt) {
    ws <- character(0)
    e <- withCallingHandlers(
      super_DEA(dea, inputs = c("x1", "x2"), outputs = c("y1", "y2"),
                orientation = orc, rts = rt)$efficiencies,
      warning = function(w) { ws <<- c(ws, conditionMessage(w)); invokeRestart("muffleWarning") })
    list(eff = e, warn = ws)
  }
  s_io <- sup_warn("io", "vrs")
  stopifnot(length(s_io$eff) == 6, sum(is.na(s_io$eff)) == 1, is.na(s_io$eff[["F"]]),
            length(s_io$warn) == 1, grepl("F", s_io$warn))
  s_oo <- sup_warn("oo", "vrs")
  stopifnot(sum(is.na(s_oo$eff)) == 1, is.na(s_oo$eff[["A"]]), grepl("A", s_oo$warn))
  s_crs <- sup_warn("io", "crs")
  stopifnot(sum(is.na(s_crs$eff)) == 0, length(s_crs$warn) == 0)
  stopifnot(length(basic_SBM(dea, inputs = c("x1", "x2"), outputs = c("y1", "y2"))$efficiencies) == 6)
  stopifnot(length(super_SBM(dea, inputs = c("x1", "x2"), outputs = c("y1", "y2"))$efficiencies) == 6)
})
chk("不平等测度：gini / theil（pop 必填）/ theil_g（group 传列名字符）", {
  v <- c(10, 20, 30, 40, 100); p <- rep(1, 5); g <- c("A", "A", "B", "B", "B")
  stopifnot(within(gini(v, p), 0, 1), within(gini0(v), 0, 1),
            within(theil(v, p), 0, 2), within(theil0(v), 0, 2))
  tg <- theil_g(data.frame(g = g, y = v, p = p), group = "g", y = "y", pop = "p")
  stopifnot(!is.null(tg$theil))
  # 0.0.14 修复的回归护栏：theil_g2_nest 的 ratio 与 theil 不等长（历史如此），
  # 但 ratio 的名字必须唯一（历史上末尾 ".within" 块与组间项重名）。
  dn <- data.frame(g1 = c("A","A","A","A","B","B"), g2 = c("A1","A1","A2","A2","B1","B1"),
                   y = c(50, 45, 60, 55, 70, 65), p = c(10, 8, 15, 12, 10, 8))
  tn <- theil_g2_nest(dn, group1 = "g1", group2 = "g2", y = "y", pop = "p")
  stopifnot(!anyDuplicated(names(tn$ratio)), length(tn$ratio) != length(tn$theil))
})
chk("区域经济：LQ / HHI / EG", {
  reg <- data.frame(region = rep(c("A", "B", "C"), each = 3), ind = rep(c("I1", "I2", "I3"), 3),
                    y = c(10, 20, 30, 40, 50, 60, 70, 80, 90))
  lq <- LQ(reg, region = region, total = y, .cols = y, .by = ind)
  stopifnot(nrow(lq) > 0, all(c("ind", "region", "y") %in% names(lq)),
            is.numeric(HHI(c(0.3, 0.3, 0.4))))
  reg2 <- data.frame(region = rep(c("A", "B", "C"), each = 2), industry = rep(c("I1", "I2"), 3),
                     y = c(10, 20, 30, 40, 50, 60))
  stopifnot(all(c("industry", "EG") %in% names(EG(reg2, region = region, industry = industry, y = y))))
})
chk("系统评价：coupling_degree / obstacle_degree", {
  df <- data.frame(ID = LETTERS[1:5], s1 = c(0.2, 0.5, 0.7, 0.3, 0.9),
                   s2 = c(0.3, 0.6, 0.4, 0.8, 0.5), s3 = c(0.4, 0.3, 0.6, 0.7, 0.2))
  cd <- coupling_degree(df, id_cols = "ID")
  stopifnot(all(c("coupling", "coord", "coupling_coord") %in% names(cd)),
            within(cd$coupling_coord, 0, 1),
            nrow(obstacle_degree(df, id_cols = "ID")) == 5)
})

# ---- 预测 ------------------------------------------------------------------
chk("灰色预测：GM11 / DGM21 / verhulst / GM1N", {
  x <- c(2.874, 3.278, 3.307, 3.39, 3.679, 3.85)
  stopifnot(is.numeric(GM11(x)$pnext), is.numeric(DGM21(x)$pnext))
  v <- c(4.93, 5.33, 5.87, 6.35, 6.63, 7.15, 7.37, 7.39, 7.81, 8.35, 9.39, 10.59, 10.94, 10.44)
  stopifnot(is.numeric(verhulst(v)$pnext))
  dat <- data.frame(相关因素 = c(7.04, 7.645, 8.075, 8.53, 8.774),
                    特征序列 = c(2.874, 3.278, 3.307, 3.39, 3.679))
  stopifnot(length(GM1N(dat)$fitted) > 0)
})
chk("灰色-马尔可夫 / 马尔可夫链", {
  X <- c(174, 179, 183, 189, 207, 234, 220.5, 256, 270, 285)
  gm <- GM11_markov(X, n_ahead = 3)
  stopifnot(all(c("Period", "Raw", "GM11_fitted", "err_state", "adj_eff", "Markov_adj") %in% names(gm)))
  S <- factor(c("Sunny","Sunny","Cloudy","Rainy","Sunny","Cloudy","Sunny","Sunny",
                "Rainy","Cloudy","Sunny","Cloudy","Rainy","Sunny","Sunny"),
              levels = c("Rainy","Cloudy","Sunny"))
  r <- markov_chain(S, s0 = "Cloudy", n_steps = 3)
  stopifnot(nrow(r$pred_probs) == 3, abs(sum(r$trans_mat[1, ]) - 1) < 1e-8)
})
chk("回归预测：reg_*（公式在前 data 在后；系数表在 $coefficient，单数）", {
  d <- mtcars
  stopifnot(nrow(reg_lm(mpg ~ wt + hp, data = d)$coefficient) >= 3,
            nrow(reg_logistic(am ~ wt + hp, data = d)$coefficient) >= 3,
            nrow(reg_poisson(cyl ~ wt + hp, data = d)$coefficient) >= 3,
            nrow(reg_negbin(cyl ~ wt + hp, data = d)$coefficient) >= 3)
})
chk("时间序列：as_ts_df / ts_test / ts_stl / ts_sarima / ts_ets / ts_forecast", {
  ap <- as_ts_df(log(AirPassengers))
  stopifnot(is_ts_df(ap), nrow(ts_test(ap)) == 2, !is.null(ts_stl(ap)$strength))
  fc <- ts_forecast(ts_sarima(ap), h = 6)
  stopifnot(all(c("step", "forecast", "lo_95", "hi_95") %in% names(fc)), nrow(fc) == 6)
  stopifnot(nrow(ts_forecast(ts_ets(ap), h = 3)) == 3)
})
chk("时间序列：ts_transform / ts_back_transform 拟回原尺度", {
  tr <- ts_transform(as_ts_df(AirPassengers), method = "log", diff = 1)
  stopifnot(nrow(tr$transformed) > 0)
  # 用「只取对数、不做差分」的 params 做往返，结果就是 exp()；带 diff 的参数
  # 需要历史序列才能还原，不能拿两行合成数据去反变换。
  tr_log <- ts_transform(as_ts_df(AirPassengers), method = "log")
  bt <- ts_back_transform(tibble(step = 1:2, forecast = log(c(500, 600))), tr_log$params)
  stopifnot(within(bt$forecast, 300, 900))
})
chk("插值与拟合：interp_* / poly_fit / curve_fit / growth_fit", {
  x <- 1:8; y <- c(2, 4, 5, 8, 9, 12, 13, 16)
  # interp_* 返回 tibble(x = xout, y = 插值)，行数 = length(xout)
  stopifnot(nrow(interp_linear(x, y, 3.5)) == 1, nrow(interp_spline(x, y, 3.5)) == 1,
            nrow(interp_poly(x, y, 3.5, degree = 2)) == 1, nrow(interp_hermite(x, y, 3.5)) == 1)
  # $coefficient 是 tidy 系数表（degree + 1 行，含截距）
  stopifnot(nrow(poly_fit(x, y, degree = 2)$coefficient) == 3,
            !is.null(curve_fit(x, y, type = "power")$coefficient),
            !is.null(growth_fit(x, y, type = "logistic")$coefficient))
})

# ---- 微分方程 --------------------------------------------------------------
chk("ODE：ode_solver 自定义方程组", {
  res <- ode_solver(init = c(S = 1000, E = 1, I = 0, R = 0), times = seq(0, 60, by = 1),
                    equations = c(S = "mu*N - beta*S*I - mu*S", E = "beta*S*I - alpha*E - mu*E",
                                  I = "alpha*E - gamma*I - mu*I", R = "gamma*I - mu*R"),
                    params = c(beta = 0.3, alpha = 0.2, gamma = 0.1, mu = 0.01, N = 1000))
  stopifnot(nrow(res) == 61, all(c("time", "S", "E", "I", "R") %in% names(res)))
})
chk("ODE 内置族：malthus / logistic / si / sis / sir / seir / lv", {
  stopifnot(nrow(ode_malthus(init = c(N = 100), params = c(r = 0.3), times = seq(0, 10, by = 0.5))) > 0,
            nrow(ode_logistic(init = c(N = 10), params = c(r = 0.5, K = 100), times = seq(0, 20, by = 0.5))) > 0)
  for (f in list(ode_si, ode_sis, ode_sir))
    stopifnot(nrow(f(init = c(S = 990, I = 10), params = c(beta = 0.3, gamma = 0.1),
                      times = seq(0, 30, by = 1))) > 0)
  stopifnot(nrow(ode_seir(init = c(S = 990, E = 5, I = 5, R = 0),
                          params = c(beta = 0.3, alpha = 0.2, gamma = 0.1), times = seq(0, 60, by = 1))) > 0)
  # ★ ode_lv 的分区名是 x / y（不是 prey / predator），参数 alpha/beta/delta/mu
  lv <- ode_lv(init = c(x = 10, y = 5), params = c(alpha = 1.1, beta = 0.4, delta = 0.1, mu = 0.4),
               times = seq(0, 30, by = 0.5))
  stopifnot(nrow(lv) > 0, all(c("x", "y") %in% names(lv)))
})
chk("传染病指标与可视化：epi_metrics（字段 peak_infection 而非 peak）", {
  res <- ode_sir(init = c(S = 990, I = 10, R = 0), params = c(beta = 0.15, gamma = 0.1),
                 times = seq(0, 120, by = 0.5))
  m <- epi_metrics(res, beta = 0.15, gamma = 0.1, N = 1000)
  stopifnot(all(c("R0", "peak_infection", "peak_time", "attack_rate") %in% names(m)),
            within(m$R0, 1, 3), within(m$attack_rate, 0, 1))
  mmr_fig(plot_compartments(res), "smoke_compartments", width = 7, height = 4.5)
  mmr_fig(plot_incidence(res), "smoke_incidence", width = 7, height = 4)
})

# ---- 多元统计 --------------------------------------------------------------
chk("降维：mv_pca / mv_efa（参数名是 factors，不是 nfactors）", {
  r <- mv_pca(mtcars, cyl:carb)
  stopifnot(within(r$var_prop, 0, 1))
  stopifnot(length(mv_efa(mtcars, cyl:carb, factors = 2)$loadings) > 0)
})
chk("聚类：mv_hclust / mv_kmeans / mv_cluster_metrics（data 必须是 data.frame）", {
  stopifnot(!is.null(mv_hclust(mtcars, cyl:carb, k = 3)$cluster),
            !is.null(mv_kmeans(mtcars, cyl:carb, centers = 3)$cluster))
  cm <- mv_cluster_metrics(mtcars, cyl:carb, cluster = rep(1:3, length.out = 32))
  stopifnot(!is.null(cm$silhouette))
})
chk("判别与相关结构：mv_discrim / mv_cancor / mv_pcor", {
  d <- mv_discrim(iris, Species, 1:4)
  stopifnot(nrow(d$predictions) == nrow(iris), !is.null(d$confusion))
  # ★ mv_cancor 的 x_cols / y_cols 必须给「具名字符向量」，传数字区间会报 dimnames 错误
  cc <- mv_cancor(mtcars, x_cols = c("mpg", "disp"), y_cols = c("hp", "wt"))
  stopifnot(length(cc$correlations) > 0)
  stopifnot(!is.null(mv_pcor(mtcars, cols = c("mpg", "cyl", "disp", "hp"))$pcor_matrix))
})
chk("对应分析与多维标度：mv_corresp（长表 + row/col 列）/ mv_mds", {
  long <- data.frame(r = rep(letters[1:3], each = 3), c = rep(LETTERS[1:3], 3), n = 1:9)
  stopifnot(!is.null(mv_corresp(long, row = "r", col = "c", nf = 2)$row_coord))
  stopifnot(length(mv_mds(mtcars, cols = 3:6, k = 2)$points) > 0)
})

# ---- 数据清洗与统计推断 ----------------------------------------------------
chk("缺失诊断：na_summary / na_mcar_test / plot_na_bar / plot_na_heatmap", {
  set.seed(1)
  d <- as.data.frame(matrix(rnorm(120), ncol = 4)); names(d) <- paste0("x", 1:4)
  d$x1[c(1, 5, 9)] <- NA; d$x2[c(2, 7)] <- NA
  stopifnot(is.data.frame(na_summary(d)), !is.null(na_mcar_test(d, .cols = where(is.numeric))))
  mmr_fig(plot_na_bar(d), "smoke_na_bar", width = 6, height = 4)
  mmr_fig(plot_na_heatmap(d, where(is.numeric)), "smoke_na_heatmap", width = 6, height = 4)
})
chk("插补：impute（均值/中位数/模型法）与 impute_model", {
  set.seed(1)
  d <- as.data.frame(matrix(rnorm(120), ncol = 4)); names(d) <- paste0("x", 1:4)
  d$x1[c(1, 5, 9)] <- NA; d$x2[c(2, 7)] <- NA
  i1 <- impute(d, .cols = where(is.numeric), method = "mean")
  stopifnot(!anyNA(i1), !is.null(attr(i1, "changes")))
  stopifnot(!is.null(attr(impute_model(d, .cols = x1, model = "knn"), "changes")))
})
chk("多重插补：impute_multiple 返回 m 个数据框的裸 list + rubin_pool", {
  set.seed(2)
  d <- data.frame(a = c(1, 2, NA, 4, 5, 6), b = c(NA, 3, 4, 5, 6, 7))
  mi <- impute_multiple(d, m = 3)
  stopifnot(inherits(mi, "mi_impute"), length(mi) == 3, is.data.frame(mi[[1]]))
  stopifnot(!is.null(rubin_pool(est = c(1.1, 1.2, 1.15), err = c(0.1, 0.12, 0.11))))
})
chk("异常值：outlier 三种 to=（detect 出清单 / na / cap）", {
  dd <- data.frame(g = rep(c("A", "B"), each = 5), v = c(1, 2, 3, 4, 5, 10, 11, 12, 13, 250))
  det <- outlier(dd, .cols = v, .by = g)
  stopifnot(nrow(det) == 1, all(c("variable", "bound_low", "bound_high") %in% names(det)))
  stopifnot(nrow(outlier(dd, .cols = v, .by = g, to = "na")) == nrow(dd),
            max(outlier(dd, .cols = v, .by = g, to = "cap")$v) < 250)
})
chk("透视表 pivot_table（index / columns / values / aggfunc）", {
  d <- data.frame(k = rep(c("a", "b"), each = 3), g = rep(c("x", "y", "z"), 2), v = 1:6)
  stopifnot(nrow(pivot_table(d, index = k, columns = g, values = v, aggfunc = sum)) == 2)
})
chk("统计推断：stat_* 全家族（注意 resp / row / col 参数名）", {
  stopifnot(is.data.frame(stat_describe(sleep, .cols = extra)),
            nrow(stat_t_test(sleep, .cols = extra, group = group)) == 1,
            nrow(stat_wilcox_test(sleep, .cols = extra, group = group)) == 1,
            # ANOVA 返回 2 行：处理项 + Residuals
            nrow(stat_anova(iris, resp = Sepal.Length, group = Species)) == 2,
            nrow(stat_kruskal(iris, resp = Sepal.Length, group = Species)) >= 1,
            nrow(stat_cor(mtcars, .cols = c(mpg, wt, hp))) >= 1,
            is.data.frame(stat_normality(mtcars, .cols = mpg)),
            is.data.frame(stat_hov_test(iris, .cols = Sepal.Length, group = Species)),
            is.data.frame(stat_chisq(mtcars, row = cyl, col = am)),
            is.data.frame(stat_bootstrap(mtcars, statistic = mean, .cols = mpg,
                                         B = 200, seed = 1)),
            is.data.frame(stat_perm_test(mtcars, .cols = mpg, group = am, n_perm = 200, seed = 1)))
})
chk("三线表导出：export_table（LaTeX / Word）", {
  tt <- stat_t_test(sleep, .cols = extra, group = group)
  export_table(tt, output = "latex", path = "./tables/smoke_table.tex", caption = "冒烟测试三线表")
  stopifnot(file.exists("./tables/smoke_table.tex"))
})

# ---- 汇总 ------------------------------------------------------------------
ok <- length(FAIL) == 0L
mmr_log(sprintf("冒烟结果：%d 项通过，%d 项失败", PASS, length(FAIL)),
        level = if (ok) "INFO" else "ERR")
if (!ok) for (f in FAIL) mmr_log(paste0("  ✘ ", f), level = "ERR")
mmr_finish(notes = sprintf("冒烟测试：%d 通过 / %d 失败", PASS, length(FAIL)))
quit(status = if (ok) 0L else 1L)
