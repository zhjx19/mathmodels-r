# ============================================================================
# 案例 03：DEA 效率评价（单期截面 + 跨期面板）
#
#   ① 径向模型：CCR(CRS) / BCC(VRS) x 投入导向 / 产出导向
#   ② 超效率模型：把效率为 1 的 DMU 再排序
#   ③ SBM 模型：带非期望产出
#   ④ 规模效率 = CRS 效率 / VRS 效率
#   ⑤ Malmquist 指数：面板数据的全要素生产率变化及其分解
#
# 数据：examples/data/hospital.csv    2011 年 31 个省医院投入产出（截面）
#       examples/data/economy.csv     2005-2009 年各省工业（长格式面板）
#
# 运行：bash scripts/run_r.sh examples/cases/03-dea-efficiency/script.R
#
# 覆盖的包函数：basic_DEA / super_DEA / basic_SBM / super_SBM / malmquist
# ============================================================================

source(file.path(Sys.getenv("MMR_HOME"), "scripts", "mmr.R"))
mmr_init(label = "案例03 DEA 效率评价：CCR/BCC/超效率/SBM + Malmquist 面板")

suppressPackageStartupMessages({
  library(mathmodels); library(dplyr); library(tidyr)
  library(tibble); library(purrr); library(ggplot2)
})

DATA <- file.path(Sys.getenv("MMR_HOME"), "examples", "data")
# check.names = FALSE 保留中文列名原样（否则 read.csv 会把括号换成点）
# DEA 家族要求 data 是 data.frame 且【第 1 列是 DMU 名】，不要传 matrix。
hosp <- read.csv(file.path(DATA, "hospital.csv"), fileEncoding = "UTF-8", check.names = FALSE)
mmr_log("医院截面数据：", nrow(hosp), " 个 DMU（省份）")

# 输入 2:3 = 床位数、卫技人员数；输出 4:5 = 诊疗人次数、入院人数；6 = 医疗废弃物
IN <- 2:3; OUT <- 4:5; UD <- 6

# ---- 1. 径向 DEA 四种组合 --------------------------------------------------
ccr_in  <- basic_DEA(hosp, inputs = IN, outputs = OUT, orientation = "io", rts = "crs")
ccr_out <- basic_DEA(hosp, inputs = IN, outputs = OUT, orientation = "oo", rts = "crs")
bcc_in  <- basic_DEA(hosp, inputs = IN, outputs = OUT, orientation = "io", rts = "vrs")
bcc_out <- basic_DEA(hosp, inputs = IN, outputs = OUT, orientation = "oo", rts = "vrs")
# ★ 返回字段是 efficiencies（复数），不是 efficiency
mmr_log("basic_DEA() 返回字段：", paste(names(bcc_in), collapse = ", "))

# ---- 2. 超效率：把已经等于 1 的 DMU 再区分开 --------------------------------
# ★ 为什么会有 NA：VRS 超效率把该 DMU 移出参考集后，其余 DMU 的【凸】组合
#   可能够不到它的产出水平，这个 DMU 的线性规划就不可行。
#   0.0.14 起包会汇总 warning 并点名（"... LP infeasible for DMU(s): …; efficiency set to NA."）。
run_super <- function(orientation, rts) {
  eff <- withCallingHandlers(
    super_DEA(hosp, inputs = IN, outputs = OUT, orientation = orientation, rts = rts)$efficiencies,
    warning = function(w) invokeRestart("muffleWarning"))
  tibble(导向 = orientation, 规模报酬 = rts, NA数 = sum(is.na(eff)),
         不可行DMU = ifelse(sum(is.na(eff)) == 0, "—",
                            paste(hosp[[1]][is.na(eff)], collapse = "、")))
}
tab_sup <- map_dfr(c("io", "oo"), \(orc) map_dfr(c("crs", "vrs"), \(rt) run_super(orc, rt)))
mmr_table(tab_sup, "03_超效率不可行性对照")

sup_eff <- withCallingHandlers(
  super_DEA(hosp, inputs = IN, outputs = OUT, orientation = "io", rts = "vrs")$efficiencies,
  warning = function(w) invokeRestart("muffleWarning"))
n_na <- sum(is.na(sup_eff))
# ★ 必须显式补齐，否则排序会漏掉这些 DMU——包的告警只报数，不会替你填值
mmr_log("超效率模型（io + vrs）中有 ", n_na, " 个 DMU 无可行解（返回 NA），",
        "已用标准 BCC 效率值补齐")
# ★ 如实报数（不要写死）：不可行只出现在 vrs，crs 两种导向必须恒为 0
stopifnot(all(tab_sup$NA数[tab_sup$规模报酬 == "crs"] == 0))
vrs_txt <- paste0(tab_sup$导向[tab_sup$规模报酬 == "vrs"], " 导向 ",
                  tab_sup$NA数[tab_sup$规模报酬 == "vrs"], " 个", collapse = "、")
mmr_log("★ 对照见「03_超效率不可行性对照」：不可行只出现在 vrs（", vrs_txt, "），",
        "crs 下两种导向恒为 0。",
        "机理：CRS 的锥形包络可以无限放大、永不失效；VRS 的凸组合够不到极端 DMU。",
        "所以看到 NA 不是数据错，是 VRS 超效率的固有不可行性")
sup_eff[is.na(sup_eff)] <- bcc_in$efficiencies[is.na(sup_eff)]

# ---- 3. SBM：纳入非期望产出 -------------------------------------------------
# outputs 给 3 列，ud_outputs = 3 表示这 3 列里的第 3 列（医疗废弃物）是非期望产出
# ★ v0.0.14 起 basic_SBM() 是非导向模型，**不能传 orientation**，否则报
#   "SBM models are non-oriented; `orientation` is not applicable."
#   （mathmodels-book 的 dea.qmd 里传了 orientation = "oo"，照抄会报错）
sbm <- basic_SBM(hosp, inputs = IN, outputs = 4:6, ud_outputs = 3, rts = "vrs")

# ---- 4. 汇总：规模效率 = CRS 效率 / VRS 效率 --------------------------------
tab_dea <- tibble(
  DMU        = hosp[[1]],
  ccr_in     = as.numeric(ccr_in$efficiencies),
  ccr_out    = as.numeric(ccr_out$efficiencies),
  bcc_in     = as.numeric(bcc_in$efficiencies),
  bcc_out    = as.numeric(bcc_out$efficiencies),
  super_bcc  = as.numeric(sup_eff),
  sbm_ud_out = as.numeric(sbm$efficiencies),
  规模效率   = ccr_in / bcc_in
) |>
  mutate(规模报酬 = case_when(规模效率 > 1.0001 ~ "规模报酬递增(irs)",
                              规模效率 < 0.9999 ~ "规模报酬递减(drs)",
                              .default = "规模报酬不变(crs)"),
         排名 = min_rank(desc(bcc_in))) |>
  arrange(排名)
mmr_table(tab_dea, "03_DEA效率汇总")

mmr_log("BCC 投入导向下有效（效率 = 1）的 DMU：",
        paste(tab_dea$DMU[tab_dea$bcc_in > 0.999], collapse = "、"))
mmr_log("超效率排名前 5：",
        paste(tab_dea$DMU[order(-tab_dea$super_bcc)][1:5], collapse = "、"),
        "（超效率把同为 1 的 DMU 分了高下）")
mmr_log("平均规模效率 = ", sprintf("%.4f", mean(tab_dea$规模效率)),
        "；", sum(tab_dea$规模报酬 != "规模报酬不变(crs)"), " 个 DMU 规模无效率")

# ---- 5. Malmquist：面板数据的全要素生产率变化 -------------------------------
eco <- read.csv(file.path(DATA, "economy.csv"), fileEncoding = "UTF-8", check.names = FALSE)
mmr_log("工业面板数据：", nrow(eco), " 行 = ", n_distinct(eco$DMUs), " 个省份 x ",
        n_distinct(eco$Period), " 个年份（", paste(range(eco$Period), collapse = "-"), "）")

# 长格式：第 1 列 DMU，period 指定时期列；投入 Capital/Labor，产出 GIOV
mal <- malmquist(eco, period = 2, inputs = 3:4, outputs = 5,
                 orientation = "oo", rts = "vrs", type1 = "glob", type2 = "rd")
mmr_log("malmquist() 返回字段：", paste(names(mal), collapse = ", "))
mmr_table(mal, "03_Malmquist指数")
mmr_log("全样本 mi 均值 = ", sprintf("%.4f", mean(mal$mi, na.rm = TRUE)),
        "（>1 表示生产率提升）；分解：ec = ", sprintf("%.4f", mean(mal$ec, na.rm = TRUE)),
        "，tc = ", sprintf("%.4f", mean(mal$tc, na.rm = TRUE)))

# 按年份看技术进步与效率变化的对比
tab_mal_yr <- mal |>
  summarise(mi = mean(mi, na.rm = TRUE), ec = mean(ec, na.rm = TRUE),
            tc = mean(tc, na.rm = TRUE), .by = Period)
mmr_table(tab_mal_yr, "03_Malmquist分年度均值")

# ---- 6. 出图 ---------------------------------------------------------------
p1 <- tab_dea |>
  select(DMU, CCR = ccr_in, BCC = bcc_in, SBM = sbm_ud_out) |>
  pivot_longer(-DMU, names_to = "模型", values_to = "效率") |>
  ggplot(aes(reorder(DMU, 效率), 效率, fill = 模型)) +
  geom_col(position = "dodge", width = 0.75) +
  coord_flip() +
  labs(title = "三种 DEA 模型下的省级医院效率（2011 年）", x = NULL, y = "效率值") +
  theme(axis.text.y = element_text(size = 6.5), legend.position = "top")
mmr_fig(p1, "03_DEA效率对比", width = 7.5, height = 7)

p2 <- ggplot(tab_dea, aes(reorder(DMU, 规模效率), 规模效率)) +
  geom_col(fill = ifelse(tab_dea$规模效率[order(tab_dea$规模效率)] > 1,
                         "#C0392B", "#2980B9"), width = 0.72) +
  geom_hline(yintercept = 1, linetype = 2, color = "grey35") +
  coord_flip() +
  labs(title = "规模效率 = CRS 效率 / VRS 效率（>1 递增，<1 递减）", x = NULL, y = "规模效率") +
  theme(axis.text.y = element_text(size = 6.5))
mmr_fig(p2, "03_规模效率", width = 6.5, height = 7)

p3 <- ggplot(mal |> filter(!is.na(mi)), aes(factor(Period), mi)) +
  geom_boxplot(fill = "#8E44AD", alpha = 0.5, outlier.size = 0.8) +
  geom_hline(yintercept = 1, linetype = 2, color = "#C0392B") +
  labs(title = "Malmquist 指数分布：各相邻年份区间", x = "时期", y = "MI") +
  theme(legend.position = "none")
mmr_fig(p3, "03_Malmquist分布", width = 7, height = 4.5)

mmr_finish(notes = paste0("截面：CCR/BCC x 投入产出导向 + 超效率(NA 用标准效率补齐) + ",
                          "带非期望产出的 SBM；规模效率 = CRS/VRS。",
                          "面板：Malmquist 指数分解为 ec(效率变化) 与 tc(技术进步)。",
                          "超效率的 NA 只在 VRS 下出现（凸组合够不到极端 DMU），CRS 永不失效。"))
