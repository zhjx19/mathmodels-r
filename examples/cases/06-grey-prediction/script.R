# ============================================================================
# 案例 06：灰色预测与马尔可夫修正
#
#   完整链路：宽表转长表 -> 月度汇总年度 -> 级比检验 -> GM(1,1) 预测
#             -> 按历史月份占比把年度预测分摊到月 -> 与真实值做 t 检验
#   扩展：GM(1,N) / DGM(2,1) / Verhulst 的适用条件与调用
#   马尔可夫：markov_chain() 状态转移、GM11_markov() 灰-马尔可夫修正
#
# 数据：examples/data/北京市接待海外旅游人数.xlsx
#       1997-2003 年逐月接待海外游客数（万人）——2003 年受 SARS 冲击
#
# 运行：bash scripts/run_r.sh examples/cases/06-grey-prediction/script.R
#
# 覆盖的包函数：GM11 / GM1N / DGM21 / verhulst / markov_chain / GM11_markov
# ============================================================================

source(file.path(Sys.getenv("MMR_HOME"), "scripts", "mmr.R"))
mmr_init(label = "案例06 灰色预测与马尔可夫修正：SARS 冲击下的旅游人数")

suppressPackageStartupMessages({
  library(mathmodels); library(dplyr); library(tidyr)
  library(tibble); library(purrr); library(ggplot2); library(readxl)
})

DATA <- file.path(Sys.getenv("MMR_HOME"), "examples", "data")

# ---- 1. 数据整理：宽表 -> 长表 -> 年度序列 ---------------------------------
# 原始 xlsx 是"每年一行、12 个月各一列"的宽表
tour_raw <- suppressMessages(read_excel(file.path(DATA, "北京市接待海外旅游人数.xlsx")))
tour <- tour_raw |>
  pivot_longer(-1, names_to = "月份", values_to = "人数") |>
  mutate(月 = as.integer(sub("月", "", 月份)),
         日期 = as.Date(sprintf("%d-%02d-15", 年份, 月))) |>
  select(日期, 年份, 月, 人数)
mmr_log("月度序列：", nrow(tour), " 个月（", paste(range(tour$日期), collapse = " ~ "), "）")

# 灰色预测面向小样本，先把月度汇成年度（相当于平滑）
tour_sum <- tour |> summarise(人数 = sum(人数), .by = 年份)
mmr_table(tour_sum, "06_年度人数")
train <- tour_sum$人数[tour_sum$年份 <= 2002]
mmr_log("训练期 1997-2002 共 ", length(train), " 期；真实 2003 年 = ",
        tour_sum$人数[tour_sum$年份 == 2003], "（SARS）")

# ---- 2. GM(1,1) 建模 -------------------------------------------------------
res <- GM11(train)          # 函数会自动做级比检验并打印结论
mmr_log("GM11 返回字段：", paste(names(res), collapse = ", "))
mmr_log("级比检验（包自动完成）：lambda 落在 [", round(min(res$lambda), 4), ", ",
        round(max(res$lambda), 4), "]，可容覆盖区间 [",
        round(min(res$rng), 4), ", ", round(max(res$rng), 4), "] → ",
        if (all(res$lambda > min(res$rng) & res$lambda < max(res$rng))) "通过" else "不通过")

ape <- abs((train - res$fitted) / train)
mmr_log(sprintf("GM11 拟合平均相对误差 = %.2f%%（一级精度要求 < 1%%），后验差比值需 GM1N 才给出",
                100 * mean(ape)))

# 多期外推：f() 是包内置的预测函数
path <- tibble(年份 = 1997:2005, 预测 = as.numeric(res$f(1:9)))
mmr_table(path, "06_GM11预测路径")

# ---- 3. 年度预测分摊到月 ---------------------------------------------------
# ★ 关键：月份占比只用【训练期】数据算，否则会把 2003 年的真实信息带进分配
w_month <- tour |>
  filter(年份 <= 2002) |>
  summarise(人数 = mean(人数), .by = 月) |>
  arrange(月) |>
  mutate(占比 = 人数 / sum(人数))
mmr_table(w_month, "06_训练期月份占比")

pred_2003 <- res$pnext * w_month$占比
actual_2003 <- tour |> filter(年份 == 2003) |> arrange(月) |> pull(人数)

tab_2003 <- tibble(月份 = 1:12, 真实值 = actual_2003, 预测值 = pred_2003) |>
  mutate(相对误差 = abs(真实值 - 预测值) / 真实值)
mmr_table(tab_2003, "06_2003年月度预测对比")

# 检验预测值与真实值是否有显著差异（base R 的 t.test，不必额外装 rstatix）
tt <- t.test(actual_2003, pred_2003, paired = TRUE)
mmr_log(sprintf("配对 t 检验：t = %.3f，p = %.4f → %s", tt$statistic, tt$p.value,
                if (tt$p.value < 0.05) "差异显著，2003 年 SARS 冲击真实存在"
                else "无显著差异"))
mmr_log(sprintf("年度口径：GM11 预测 2003 年 = %.1f 万人，实际 = %.1f 万人，偏低 %.1f%%",
                res$pnext, tour_sum$人数[tour_sum$年份 == 2003],
                100 * (1 - tour_sum$人数[tour_sum$年份 == 2003] / res$pnext)))

# ---- 4. 其它灰色模型的适用条件 --------------------------------------------
# 按数据形态选模型：单调近似指数增长 -> GM(1,1)；非单调摆动 -> DGM(2,1)；
# 饱和 S 形 -> Verhulst；被预测量受多个因素驱动 -> GM(1,N)
tab_models <- tribble(
  ~模型,        ~函数,        ~适用数据形态,                       ~本包返回字段,
  "GM(1,1)",   "GM11()",     "单调、近似指数增长的少数据序列",     "fitted / pnext / f / lambda / rng",
  "GM(1,N)",   "GM1N()",     "被预测量受若干相关因素驱动",         "fitted / pred / C / P / f",
  "DGM(2,1)",  "DGM21()",    "非单调、有明显摆动的序列",           "fitted / pnext / f / mat / u",
  "Verhulst",  "verhulst()", "有饱和上限的 S 形过程",              "fitted / pnext / f / mat / u"
)
mmr_table(tab_models, "06_灰色模型族适用条件")

# GM(1,N) 教材例：特征序列受单一相关因素驱动（最后一列是特征序列）
gmn <- GM1N(tibble(相关因素 = c(7.04, 7.645, 8.075, 8.53, 8.774),
                   特征序列 = c(2.874, 3.278, 3.307, 3.39, 3.679)))
mmr_log(sprintf("GM1N 拟合值 = %s；后验差比 C = %.4f，小误差概率 P = %.3f",
                paste(round(gmn$fitted, 4), collapse = ", "), gmn$C, gmn$P))

dgm <- DGM21(c(2.874, 3.278, 3.39, 3.679, 3.77, 3.8))
ver <- verhulst(c(4.93, 5.33, 5.87, 6.35, 6.63, 7.15, 7.37, 7.39,
                  7.81, 8.35, 9.39, 10.59, 10.94, 10.44))
mmr_log(sprintf("DGM21 下一期 = %.4f；Verhulst 下一期 = %.4f（交通事故死亡人数已趋饱和）",
                dgm$pnext, ver$pnext))

tr_model <- tibble(
  模型 = c("GM11", "DGM21", "Verhulst"),
  下一期预测 = c(res$pnext, dgm$pnext, ver$pnext),
  备注 = c("北京旅游人数(2003)", "教材摆动序列", "交通事故死亡人数(2004)")
)
mmr_table(tr_model, "06_三模型预测对照")

# ---- 5. 马尔可夫链与灰-马尔可夫修正 ---------------------------------------
# 状态转移：用一阶转移频数估计转移概率矩阵
S <- factor(c("晴", "晴", "阴", "雨", "晴", "阴", "晴", "晴", "雨",
              "阴", "晴", "阴", "雨", "晴", "晴"),
            levels = c("雨", "阴", "晴"))
mc <- markov_chain(S, s0 = "阴", n_steps = 3)
mmr_log("markov_chain() 返回字段：", paste(names(mc), collapse = ", "))
mmr_log("状态水平：", paste(rownames(mc$trans_mat), collapse = " / "))

# 类型要点：mc$trans_mat 是 contingency table、mc$pred_probs 是 matrix。
#   as.data.frame(table) 会把转移矩阵摊成长表 Var1/Var2/Freq、丢掉方阵形状；
#   as_tibble(matrix) 会静默丢行名。0.0.14 起 trans_mat 的 dimnames 已命名为 from/to
#   （直接 as_tibble(x, rownames=) 不再报 `Names can't be empty`，但会产生重复列名），
#   这里仍用最稳的三步走：还原矩阵 → as.data.frame → rownames_to_column。
as_tbl_mat <- function(x, first_col) {
  m <- matrix(as.numeric(x), nrow = nrow(x), dimnames = dimnames(x))
  d <- as.data.frame(m, check.names = FALSE, stringsAsFactors = FALSE)
  # ★ 注意顺序：必须先 rownames_to_column 再 as_tibble —— as_tibble() 会静默丢掉行名
  tibble::as_tibble(tibble::rownames_to_column(d, var = first_col))
}
mmr_table(as_tbl_mat(mc$trans_mat, "从 \\ 到"), "06_状态转移矩阵")
mmr_table(as_tbl_mat(mc$pred_probs, "预测步"), "06_状态概率预测")
mmr_log("转移矩阵每行和 = 1（数值校验）：",
        paste(round(rowSums(mc$trans_mat), 6), collapse = ", "))
mmr_log("起始状态 = 阴，经 3 步后状态概率：",
        paste(paste0(names(mc$pi_final), "=", round(as.numeric(mc$pi_final), 4)), collapse = ", "),
        "；逐步最可能状态：", paste(as.character(mc$pred_states), collapse = " -> "))

# 灰-马尔可夫：先 GM(1,1) 拟合，再按残差相对误差划分状态并用转移矩阵修正
gm <- GM11_markov(c(174, 179, 183, 189, 207, 234, 220.5, 256, 270, 285), n_ahead = 3)
mmr_log("GM11_markov() 返回字段：", paste(names(gm), collapse = ", "))
mmr_table(gm, "06_灰马尔可夫修正")
mmr_log("表末 T+1/T+2/T+3 三行 Raw 为空——它们是外推期，只有模型值、没有真值")
mmr_log(sprintf("修正效果（仅拟合期）：原始 GM11 平均绝对误差 %.3f，马尔可夫修正后 %.3f",
                mean(abs(gm$Raw - gm$GM11_fitted), na.rm = TRUE),
                mean(abs(gm$Raw - gm$Markov_adj), na.rm = TRUE)))
mmr_log("→ 灰预测擅长抓趋势、不擅长抓波动；马尔可夫用残差状态转移补上波动，二者互补")

# ---- 6. 出图 ---------------------------------------------------------------
p1 <- ggplot(tour, aes(日期, 人数)) +
  geom_line(color = "#C0392B") +
  annotate("rect", xmin = as.Date("2003-01-01"), xmax = as.Date("2003-12-31"),
           ymin = -Inf, ymax = Inf, alpha = 0.12, fill = "#C0392B") +
  labs(title = "北京接待海外旅游人数（月度，1997-2003）", subtitle = "红底区间为 2003 年 SARS 冲击期",
       x = NULL, y = "人数（万人）")
mmr_fig(p1, "06_月度序列", width = 8, height = 4)

p2 <- tibble(年份 = 1997:2005, 预测 = as.numeric(res$f(1:9))) |>
  left_join(tour_sum, by = "年份") |>
  ggplot(aes(年份, 预测)) +
  geom_line(color = "#2980B9", linewidth = 1) + geom_point(color = "#2980B9") +
  geom_point(aes(y = 人数), color = "#C0392B", size = 2.4, na.rm = TRUE) +
  geom_line(aes(y = 人数), color = "#C0392B", linetype = 2, na.rm = TRUE) +
  labs(title = "GM(1,1) 拟合与外推 vs 实际（蓝 = 模型，红 = 实际）",
       subtitle = "模型给出的 2003 年预测明显偏高——SARS 是灰色模型无法预见的突变",
       x = NULL, y = "年度人数（万人）")
mmr_fig(p2, "06_GM11拟合与外推", width = 7.5, height = 4)

p3 <- tab_2003 |>
  pivot_longer(-月份, names_to = "类型", values_to = "人数") |>
  ggplot(aes(factor(月份), 人数, fill = 类型)) +
  geom_col(position = "dodge", width = 0.75) +
  labs(title = "2003 年逐月：真实值 vs GM(1,1) 预测值", x = "月份", y = "人数（万人）")
mmr_fig(p3, "06_2003预测对比", width = 8, height = 4)

p4 <- gm |>
  filter(!is.na(Raw)) |>                       # 只用有真实值的期数作图（后 3 期是外推）
  select(Period, Raw, GM11 = GM11_fitted, 修正后 = Markov_adj) |>
  pivot_longer(-Period, names_to = "类型", values_to = "值") |>
  mutate(类型 = factor(类型, levels = c("Raw", "GM11", "修正后"))) |>
  ggplot(aes(Period, 值, color = 类型, linetype = 类型, group = 类型)) +
  geom_line(linewidth = 1) + geom_point(size = 1.6) +
  labs(title = "灰-马尔可夫修正：修正后曲线更贴合原始序列的波动",
       x = "期数", y = "值")
mmr_fig(p4, "06_灰马尔可夫修正", width = 7.5, height = 4)

mmr_finish(notes = paste0("小样本灰色预测全链路：级比检验 -> GM(1,1) -> 月份占比分摊 -> ",
                          "配对 t 检验。2003 年 SARS 使实际值远低于预测，说明灰色模型",
                          "只能外推既有趋势、无法预见突变；波动修正交给马尔可夫（或直接上 ARIMA）。"))
