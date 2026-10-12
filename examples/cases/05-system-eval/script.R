# ============================================================================
# 案例 05：系统评价 —— 耦合协调度与障碍度
#
#   ① 三个子系统分别用熵权法算综合得分
#   ② 子系统得分归一化后，用熵权法确定子系统权重
#   ③ 按年份分组批量计算耦合协调度（coupling_degree）
#   ④ 障碍度（obstacle_degree）：找制约协调发展的瓶颈指标
#   ⑤ 标准式 vs 修正式耦合度的差别（王淑佳等 2021 的修正公式）
#
# 数据：examples/data/cdev-sim.csv
#       中国东部沿海 8 省市「科技-经济-生态」系统，2015-2024 年
#
# 运行：bash scripts/run_r.sh examples/cases/05-system-eval/script.R
#
# 覆盖的包函数：weight_entropy / rescale / coupling_degree / obstacle_degree
# ============================================================================

source(file.path(Sys.getenv("MMR_HOME"), "scripts", "mmr.R"))
mmr_init(label = "案例05 系统评价：耦合协调度 + 障碍度")

suppressPackageStartupMessages({
  library(mathmodels); library(dplyr); library(tidyr)
  library(tibble); library(purrr); library(ggplot2)
})

DATA <- file.path(Sys.getenv("MMR_HOME"), "examples", "data")
cdev <- read.csv(file.path(DATA, "cdev-sim.csv"), fileEncoding = "UTF-8", check.names = FALSE)
mmr_log("数据：", nrow(cdev), " 行 = ", n_distinct(cdev$地区), " 个地区 x ",
        n_distinct(cdev$年份), " 年（", paste(range(cdev$年份), collapse = "-"), "）")

# ---- 1. 三个子系统各自做熵权综合评价 --------------------------------------
# 列布局：1-2 是 地区/年份；3:5 科技创新；6:8 经济发展；9:11 生态环境
tech <- weight_entropy(cdev[3:5],  rep("+", 3))
eco  <- weight_entropy(cdev[6:8],  rep("+", 3))
env  <- weight_entropy(cdev[9:11], c("+", "-", "+"))   # 单位GDP能耗是负向指标

w_ind <- tibble(
  子系统 = rep(c("科技", "经济", "生态"), each = 3),
  指标   = names(c(cdev[3:5], cdev[6:8], cdev[9:11])),
  熵权   = as.numeric(c(tech$w, eco$w, env$w))
)
mmr_table(w_ind, "05_子系统内指标权重")

S <- bind_cols(cdev[1:2], map_dfc(list(tech, eco, env), "s") |> set_names(c("科技", "经济", "生态")))
mmr_table(S, "05_子系统综合得分")
mmr_log("子系统得分量纲：", sprintf("%.2f ~ %.2f", min(S[[3]]), max(S[[3]])),
        "（同案例01：已含 0-100 缩放）")

# ---- 2. 归一化后再定子系统权重 --------------------------------------------
# 耦合协调度要求各子系统得分落在 [0,1]，所以这里先 rescale；
# 归一化过的列在 weight_entropy 里用 index = NA 标出（不要再标化一次）
S <- S |> mutate(across(3:5, rescale))
w <- weight_entropy(S[3:5], rep(NA, 3))$w
mmr_log("子系统权重（熵权，等权时为 NULL 亦可）：科技 ", round(w[1], 4),
        "，经济 ", round(w[2], 4), "，生态 ", round(w[3], 4))

# ---- 3. 按年份分组批量算耦合协调度 ----------------------------------------
# coupling_degree(data, w, id_cols)：data 是已归一化的子系统得分，
# id_cols 指定不参与计算的列；返回 ID / coupling / coord / coupling_coord
res_std <- S |>
  nest(.by = 年份) |>
  mutate(model = map(data, \(d) coupling_degree(d, w, id_cols = "地区"))) |>
  select(-data) |> unnest(model)
mmr_table(res_std, "05_耦合协调度_标准式")

# 修正式（王淑佳等 2021）：传统 C 值在 [0,1] 上分布偏向 1，区分度差；修正式拉开分布
res_adj <- S |>
  nest(.by = 年份) |>
  mutate(model = map(data, \(d) coupling_degree(d, w, id_cols = "地区", type = "adjusted"))) |>
  select(-data) |> unnest(model)

tab_cmp <- tibble(
  年份 = res_std$年份, 地区 = res_std$地区,
  耦合度_标准 = res_std$coupling, 耦合度_修正 = res_adj$coupling,
  协调指数 = res_std$coord, 协调度_标准 = res_std$coupling_coord,
  协调度_修正 = res_adj$coupling_coord
)
mmr_table(tab_cmp, "05_耦合协调度_标准vs修正")
pile_std <- mean(tab_cmp$耦合度_标准 > 0.9)
pile_adj <- mean(tab_cmp$耦合度_修正 > 0.9)
mmr_log(sprintf("标准式耦合度：均值 %.4f，其中 %.0f%% 的样本挤在 0.9 以上",
                mean(tab_cmp$耦合度_标准), 100 * pile_std))
mmr_log(sprintf("修正式耦合度：均值 %.4f，其中 %.0f%% 的样本落在 0.9 以上",
                mean(tab_cmp$耦合度_修正), 100 * pile_adj))
mmr_log("→ 这就是文献指出的问题：传统 C 值概率偏向 1 一端、区分度差；",
        "修正式把分布拉回中段，评价结果更能反映真实差异（两者并非谁更\"准\"，而是取值分布不同）")

# 按协调等级给结论
grade <- function(D) cut(D, c(0, .1, .2, .3, .4, .5, .6, .7, .8, .9, 1),
                      labels = c("极度失调", "严重失调", "中度失调", "轻度失调", "濒临失调",
                                 "勉强协调", "初级协调", "中级协调", "良好协调", "优质协调"),
                      include.lowest = TRUE)
tab_cmp <- tab_cmp |> mutate(等级 = grade(协调度_修正))
tab_grade <- tab_cmp |>
  count(年份, 等级) |>
  pivot_wider(names_from = 等级, values_from = n, values_fill = 0)
mmr_table(tab_grade, "05_协调等级分布")
mmr_log("末年的协调等级：",
        paste(tab_cmp |> filter(年份 == max(年份)) |>
                mutate(x = paste0(地区, "(", 等级, ")")) |> pull(x), collapse = "、"))

# ---- 4. 障碍度：找瓶颈 -----------------------------------------------------
# obstacle_degree() 只算"二级指标障碍度"；要一级的（这里是各子系统汇总），
# 在外面用 summarise(across(...), .by =) 加总即可
res_ob <- S |>
  nest(.by = 年份) |>
  mutate(model = map(data, \(d) obstacle_degree(d, w, id_cols = "地区"))) |>
  select(-data) |> unnest(model)
mmr_table(res_ob, "05_障碍度_子系统")

res_ob_lv1 <- res_ob |> summarise(across(科技:生态, sum), .by = 年份)
mmr_table(res_ob_lv1, "05_障碍度_一级汇总")

tab_top <- res_ob |>
  pivot_longer(科技:生态, names_to = "子系统", values_to = "障碍度") |>
  slice_max(障碍度, n = 1, by = c(年份, 地区)) |>
  count(子系统)
mmr_log("各年各地区最主要的障碍子系统：",
        paste(tab_top$子系统, tab_top$n, sep = " x ", collapse = "，"))
mmr_log("提示：障碍度本身是相对值，直接比大小即可，不需要再做行归一化",
        "（scale = TRUE 才做行归一化）")

# ---- 5. 出图 ---------------------------------------------------------------
p1 <- S |>
  pivot_longer(3:5, names_to = "子系统", values_to = "得分") |>
  summarise(得分 = mean(得分), .by = c(年份, 子系统)) |>
  ggplot(aes(年份, 得分, color = 子系统)) +
  geom_line(linewidth = 1) + geom_point() +
  labs(title = "三子系统平均得分走势（8 省市均值）", x = NULL, y = "得分")
mmr_fig(p1, "05_子系统得分走势", width = 7, height = 4)

p2 <- ggplot(tab_cmp, aes(factor(年份), 协调度_修正, fill = 地区)) +
  geom_col(position = position_dodge(0.8), width = 0.78) +
  geom_hline(yintercept = 0.5, linetype = 2, color = "grey35") +
  labs(title = "耦合协调度（修正式）逐年分布：越过 0.5 才算进入协调区间",
       x = "年份", y = "耦合协调度 D") +
  theme(legend.position = "right", legend.text = element_text(size = 7))
mmr_fig(p2, "05_耦合协调度", width = 7.5, height = 4.5)

p3 <- res_ob_lv1 |>
  pivot_longer(科技:生态, names_to = "子系统", values_to = "障碍度") |>
  ggplot(aes(factor(年份), 障碍度, fill = 子系统)) +
  geom_col(position = position_dodge(0.8), width = 0.78) +
  labs(title = "一级指标（子系统）障碍度逐年汇总：柱子越高，越是制约瓶颈",
       x = "年份", y = "障碍度（8 省市合计）")
mmr_fig(p3, "05_障碍度", width = 7.5, height = 4.5)

mmr_finish(notes = paste0("耦合协调度：子系统熵权得分 -> 归一化 -> 子系统权重 -> ",
                          "coupling_degree()；障碍度：obstacle_degree() + summarise 汇总一级。",
                          "标准式 vs 修正式耦合度已对拍（修正式区分度更高）。"))
