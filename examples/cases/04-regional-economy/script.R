# ============================================================================
# 案例 04：区域经济 —— 不平等测度与产业集聚
#
#   ① 基尼系数：批量计算（分组汇总 + 长变宽），人口加权数据要传 pop
#   ② 洛伦兹曲线：注意按 人均值 排序，而不是按总量排序
#   ③ 泰尔指数分解：单分组 theil_g / 两交叉 theil_g2_cross / 两嵌套 theil_g2_nest
#   ④ 区位商 LQ：按年份批量，需要先补"全国"行
#   ⑤ HHI 与 EG 指数：市场集中度与空间集聚
#
# 数据：examples/data/income.xlsx    2014-2023 年 31 省 8 个行业的平均工资与就业人数
#       examples/data/industry.xlsx  2015-2024 年 31 省的 GDP 与三次产业增加值
#
# 运行：bash scripts/run_r.sh examples/cases/04-regional-economy/script.R
#
# 覆盖的包函数：gini / theil / theil_g / theil_g2_cross / theil_g2_nest /
#               LQ / HHI / EG
# ============================================================================

source(file.path(Sys.getenv("MMR_HOME"), "scripts", "mmr.R"))
mmr_init(label = "案例04 区域经济：不平等测度与分解 + 区位商/HHI/EG")

suppressPackageStartupMessages({
  library(mathmodels); library(dplyr); library(tidyr)
  library(tibble); library(purrr); library(ggplot2); library(readxl)
})

DATA <- file.path(Sys.getenv("MMR_HOME"), "examples", "data")

inc <- suppressMessages(read_excel(file.path(DATA, "income.xlsx")))
ind <- suppressMessages(read_excel(file.path(DATA, "industry.xlsx")))
mmr_log("工资数据：", nrow(inc), " 行 = ", n_distinct(inc$年份), " 年 x ",
        n_distinct(inc$地区), " 地区 x ", n_distinct(inc$行业), " 行业")
mmr_log("产业数据：", nrow(ind), " 行 = ", n_distinct(ind$年份), " 年 x ",
        n_distinct(ind$地区), " 地区")

# ============================================================================
# ① 基尼系数：gini(y, pop) —— 人口加权（平均）数据必须传 pop
#    分组汇总就能批量算，结果为整洁长表，直接可画图
# ============================================================================
g_byind <- inc |>
  summarise(Gini = gini(平均工资, 就业人数), .by = c(年份, 行业))
g_byreg <- inc |>
  summarise(Gini = gini(平均工资, 就业人数), .by = c(年份, 地区))

mmr_table(g_byind |> pivot_wider(names_from = 行业, values_from = Gini), "04_基尼系数_行业间")
mmr_table(g_byreg |> pivot_wider(names_from = 地区, values_from = Gini), "04_基尼系数_省份内")
mmr_log("2023 年各行业省份间工资基尼系数：",
        paste(g_byind |> filter(年份 == max(年份)) |> arrange(desc(Gini)) |>
                mutate(x = paste0(行业, "(", round(Gini, 3), ")")) |> pull(x), collapse = "，"))

# ★ 洛伦兹曲线的关键：按【人均值】排序（平均工资 / 就业人数），不是按平均工资
edu23 <- inc |> filter(行业 == "教育", 年份 == max(年份))
p_lorenz <- edu23 |>
  arrange(平均工资 / 就业人数) |>
  mutate(人口累计占比 = cumsum(就业人数) / sum(就业人数),
         收入累计占比 = cumsum(平均工资) / sum(平均工资)) |>
  ggplot(aes(人口累计占比, 收入累计占比)) +
  geom_abline(slope = 1, intercept = 0, linetype = 2, color = "grey45") +
  geom_polygon(fill = "#2980B9", alpha = 0.25) +
  geom_line(color = "#2980B9", linewidth = 1) +
  coord_equal() +
  labs(title = sprintf("洛伦兹曲线：教育行业 %d 年（基尼系数 %.3f）",
                       max(edu23$年份), gini(edu23$平均工资, edu23$就业人数)),
       x = "累计人口占比", y = "累计收入占比")
mmr_fig(p_lorenz, "04_洛伦兹曲线", width = 5.5, height = 5)

# ============================================================================
# ② 泰尔指数分解
#    ★ theil_g(data, group, y, pop) 的后三个参数是【列名字符串】，不是列向量。
#    ★ 返回 list(theil=, ratio=)，两向量【长度不等】——theil_g2_nest() 的 ratio
#      还多出各一级分组的"组内总贡献"块（0.0.14 起命名为 `东北.within` 等，
#      不再与组间项重名）。所以这里统一转成长表：
#          年份 | 成分 | 项 | 值
#      需要宽表时再自行 pivot_wider（切勿对 theil / ratio 按名或按位置对齐）。
#    ★ 表内主成分的列名是 T / Tb / Tw / Tb_g1 / Tb_g2，不是"组间""组内"。
#    ★ 贡献率向量不能整体求和（它同时含 T=1、组间、组内、各组四类），
#      只有 `Tb + Tw`（单/交叉）或 `Tb_g1 + Tb_g2 + Tw`（嵌套）才等于 1。
# ============================================================================
flatten_theil <- function(d, group, group2 = NULL, nested = FALSE) {
  r <- if (is.null(group2)) {
    theil_g(d, group = group, y = "平均工资", pop = "就业人数")
  } else if (nested) {
    theil_g2_nest(d, group1 = group, group2 = group2, y = "平均工资", pop = "就业人数")
  } else {
    theil_g2_cross(d, group1 = group, group2 = group2, y = "平均工资", pop = "就业人数")
  }
  map_dfr(r, \(v) tibble(项 = names(v), 值 = as.numeric(v)), .id = "成分") |>
    mutate(成分 = recode(成分, theil = "泰尔指数", ratio = "贡献率"))
}

th_ind <- inc |> reframe(flatten_theil(pick(everything()), "行业"), .by = 年份)
mmr_table(th_ind, "04_泰尔分解_单分组_行业")

# 自校验：贡献率里 Tb + Tw 必须等于 1
chk <- th_ind |> filter(成分 == "贡献率", 项 %in% c("Tb", "Tw")) |>
  summarise(s = sum(值), .by = 年份) |> summarise(m = max(abs(s - 1)))
stopifnot(chk$m < 1e-8)
mmr_log("自校验通过：贡献率满足 Tb + Tw = 1（最大偏差 ", sprintf("%.2e", chk$m), "）")

th_cross <- inc |> reframe(flatten_theil(pick(everything()), "行业", "区域"), .by = 年份)
mmr_table(th_cross, "04_泰尔分解_两交叉_行业x区域")

# 嵌套结构要求 group2 严格嵌套在 group1 内（这里 地区 嵌套在 区域 内）
th_nest <- inc |> reframe(flatten_theil(pick(everything()), "区域", "地区", nested = TRUE), .by = 年份)
mmr_table(th_nest, "04_泰尔分解_两嵌套_区域内地区")

n_th <- th_nest |> filter(年份 == min(年份), 成分 == "泰尔指数") |> nrow()
n_ra <- th_nest |> filter(年份 == min(年份), 成分 == "贡献率") |> nrow()
mmr_log("theil_g2_nest 的泰尔指数 ", n_th, " 项、贡献率 ", n_ra,
        " 项 —— 两者长度不等（贡献率多出区域级 `*.within` 块），不能按名字或位置对齐")

# 贡献率趋势：行业间 vs 行业内
p_theil <- th_ind |>
  filter(成分 == "贡献率", 项 %in% c("Tb", "Tw")) |>
  mutate(来源 = recode(项, Tb = "组间（行业间）", Tw = "组内")) |>
  ggplot(aes(年份, 值, color = 来源)) +
  geom_line(linewidth = 1) + geom_point() +
  scale_y_continuous(labels = scales::percent_format()) +
  labs(title = "工资不平等泰尔指数分解：组间（行业间）vs 组内（贡献率）", x = NULL, y = "贡献率")
mmr_fig(p_theil, "04_泰尔分解贡献率", width = 7, height = 4)

# ============================================================================
# ③ 区位商 LQ：衡量某地区某产业的专业化程度
#    ★★ 最关键的隐含要求：LQ() 源码里是 `quotient = function(x) x[-1] / x[1]`，
#       即【每组的第一行必须放"全国合计"行】——它拿这一行当分母，并把这一行
#       从输出中删掉。如果忘了补全国行，LQ 会静默地把某一行真实地区当成全国
#       来用：不报错、结果看着也合理，但数值全错。这是最危险的一类坑。
#    做法：按年份汇总出全国行 -> 拼上 U+0001 控制字符让它排在各组第一 ->
#    与原数据合并 -> arrange -> LQ()。返回值为"地区 x 指标"的区位商，不含全国行。
# ============================================================================
nation <- ind |>
  summarise(地区 = paste0(intToUtf8(1), "全国"), across(-地区, sum), .by = 年份)
ind_all <- bind_rows(ind, nation) |>
  group_by(年份) |>
  arrange(地区, .by_group = TRUE) |>
  ungroup()

# 守卫：逐组断言第一行确实是全国合计行，避免静默错算
first_rows <- ind_all |> summarise(.first = dplyr::first(地区), .by = 年份) |> pull(.first)
stopifnot(all(grepl("全国", first_rows, fixed = TRUE)))

lq <- LQ(ind_all, 地区, GDP, contains("产业"), .by = 年份)
mmr_table(lq, "04_区位商")

# 抽验：把最后一年的某一格与手工公式对拍，证明全国行确实被当成了分母
yy <- max(ind_all$年份)
snap <- ind_all |> filter(年份 == yy)
nat  <- snap |> filter(grepl("全国", 地区))
one  <- snap |> filter(地区 == "上海")
manual <- (one$第三产业 / one$GDP) / (nat$第三产业 / nat$GDP)
got    <- lq$第三产业[lq$年份 == yy & lq$地区 == "上海"]
stopifnot(abs(manual - got) < 1e-8)
mmr_log(sprintf("抽验通过：%d 年上海第三产业区位商 手工 = %.6f，LQ() = %.6f", yy, manual, got))
mmr_log("区位商 > 1（具专业化优势）的例子：",
        paste(head(lq |> filter(第三产业 > 1.5) |> pull(地区), 3), collapse = "、"), " 等")

p_lq <- lq |>
  filter(年份 == max(年份)) |>
  pivot_longer(contains("产业"), names_to = "产业", values_to = "LQ") |>
  ggplot(aes(reorder(地区, LQ), 地区)) +
  geom_tile(aes(fill = LQ), color = "white") +
  geom_text(aes(label = sprintf("%.1f", LQ)), size = 2.1) +
  facet_wrap(~产业, ncol = 3) +
  scale_fill_gradient2(low = "#2980B9", mid = "white", high = "#C0392B", midpoint = 1) +
  labs(title = sprintf("区位商（%d 年，>1 表示该产业具有专业化优势）", max(lq$年份)),
       x = NULL, y = NULL) +
  theme(axis.text.x = element_blank(), axis.ticks.x = element_blank(),
        axis.text.y = element_text(size = 6.5))
mmr_fig(p_lq, "04_区位商热图", width = 7.5, height = 6)

# ============================================================================
# ④ HHI 与 EG 指数：市场集中度 vs 空间集聚
# ============================================================================
hhi <- inc |>
  summarise(hhi = HHI(就业人数, scaled = TRUE), .by = c(年份, 行业, 区域)) |>
  pivot_wider(names_from = 区域, values_from = hhi)
mmr_table(hhi, "04_HHI")
mmr_log("HHI（scaled=TRUE 归一化到 [0,1]，可跨区域比较）：",
        "越大表示就业越集中在少数省份")

eg <- inc |>
  nest(.by = 年份) |>
  mutate(model = map(data, \(d) EG(d, 地区, 行业, 就业人数))) |>
  select(-data) |>
  unnest(model)
mmr_table(eg, "04_EG指数")
mmr_log(sprintf("EG 指数范围 %.4f ~ %.4f（>0.05 高度集聚，<0.02 低集聚，<0 表示比总体分布更分散）",
                min(eg$EG), max(eg$EG)), if (max(eg$EG) < 0) "：本例全部为负" else "")
# EG 与基尼的分工：基尼会被"少数大企业主导"误导成假集聚，EG 剔除了企业规模效应，
# 只测"共同选址"的空间集聚。

p_eg <- eg |>
  ggplot(aes(factor(年份), EG)) +
  geom_boxplot(fill = "#27AE60", alpha = 0.45, outlier.size = 0.9) +
  geom_hline(yintercept = 0.05, linetype = 2, color = "#C0392B") +
  geom_hline(yintercept = 0.02, linetype = 3, color = "#2980B9") +
  geom_hline(yintercept = 0, linetype = 1, color = "grey30") +
  labs(title = "各行业 EG 空间集聚指数（红虚线 0.05 高度集聚，蓝点线 0.02 低集聚）",
       subtitle = "EG 剔除了企业规模差异，只测「共同选址」的空间集聚",
       x = "年份", y = "EG 指数")
mmr_fig(p_eg, "04_EG指数", width = 7.5, height = 4.5)

mmr_finish(notes = paste0("不平等：基尼系数（行业间/省份内）+ 泰尔指数三种分解；",
                          "集聚：区位商 LQ（按年批量）、HHI（scaled）、EG 指数。",
                          "注意 theil_g 系列的分组参数传列名字符串、pop 必填。"))
