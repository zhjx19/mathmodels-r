# 端到端验收：综合评价 + 传染病 ODE + 时间序列预测 + 统计推断
source(file.path(Sys.getenv("MMR_HOME"), "scripts", "mmr.R"))
mmr_init(label = "mathmodels-r 端到端验收")

suppressPackageStartupMessages({
  library(mathmodels); library(dplyr); library(tibble); library(tidyr); library(ggplot2)
})

# ---- 1. 综合评价：预处理 -> 熵权法 -> TOPSIS -> 排名 ----------------------
mmr_log("第一步：多指标综合评价")
data(water_quality)
df = water_quality |>
  mutate(PH = rescale_middle(PH, 7),
         nutrient = rescale_interval(nutrient, 10, 20))
idx_w = c("+", NA, "-", NA)     # 赋权函数：NA = 已归一化，不再重标化
idx_t = c("+", "+", "-", "+")   # topsis 只认 "+"/"-"（中心化/区间型已在上面转成正向）
w = weight_entropy(df[-1], idx_w)$w
RC = topsis(df[-1], w, idx_t)
rank_tbl = tibble(河流 = paste0("R", df$ID), 相对接近度 = RC,
                  得分 = rescale(RC, b = 100), 排名 = min_rank(-得分)) |>
  arrange(排名)
mmr_table(rank_tbl, "topsis_ranking")
mmr_table(tibble(指标 = names(df)[-1], 熵权 = as.numeric(w)), "entropy_weights")
mmr_log("TOPSIS 最优对象：", rank_tbl$河流[1],
        "，得分 ", round(rank_tbl$得分[1], 3))

p1 = rank_tbl |>
  ggplot(aes(x = reorder(河流, 得分), y = 得分, fill = 得分)) +
  geom_col(width = 0.7) + coord_flip() +
  scale_fill_gradient(low = "#9ecae1", high = "#08519c") +
  labs(title = "水质综合评价得分（熵权 + TOPSIS）", x = "河流", y = "综合得分") +
  theme(legend.position = "none")
mmr_fig(p1, "topsis_scores", width = 7, height = 5)

# ---- 2. 传染病 ODE：SIR + 指标 + 分区图 -----------------------------------
mmr_log("第二步：SIR 传染病模型")
res = ode_sir(init = c(S = 990, I = 10, R = 0),
              params = c(beta = 0.15, gamma = 0.1),
              times = seq(0, 120, by = 0.5))
m = epi_metrics(res, beta = 0.15, gamma = 0.1, N = 1000)
mmr_table(tibble(指标 = c("基本再生数 R0", "峰值感染人数", "峰值时间", "累计感染率"),
                 数值 = c(m$R0, m$peak_infection, m$peak_time, m$attack_rate)), "sir_metrics")
mmr_log("R0 = ", round(m$R0, 3), "；峰值 ", round(m$peak_infection, 1),
        " 人，出现在第 ", round(m$peak_time, 1), " 天")
mmr_fig(plot_compartments(res, compartments = c("S", "I", "R")), "sir_compartments", width = 7, height = 4.5)
mmr_fig(plot_incidence(res), "sir_incidence", width = 7, height = 4)

# ---- 3. 时间序列：SARIMA 预测 ---------------------------------------------
mmr_log("第三步：国际航空客运量预测")
ap = as_ts_df(log(AirPassengers))
st = ts_test(ap)
mmr_table(as.data.frame(st), "ts_stationarity")
fit = ts_sarima(ap)
fc = ts_forecast(fit, h = 12)
mmr_table(data.frame(期数 = fc$step,
                     预测值 = round(exp(fc$forecast)),
                     下界95 = round(exp(fc$lo_95)),
                     上界95 = round(exp(fc$hi_95))), "sarima_forecast")
mmr_fig(plot_ts_forecast(ap, fc), "sarima_forecast", width = 8, height = 4.5)

# ---- 4. 统计推断：两样本 t 检验 -------------------------------------------
mmr_log("第四步：统计推断")
tt = stat_t_test(sleep, .cols = extra, group = group)
mmr_table(as.data.frame(tt), "ttest_sleep")
mmr_log("t 检验 p 值 = ", signif(tt$p.value, 4))
try(export_table(tt, output = "latex", path = "./tables/ttest.tex",
                 caption = "两样本 t 检验结果"), silent = TRUE)

mmr_finish(notes = "四类任务全部跑通：评价、ODE、时间序列、统计推断。")
