# ============================================================================
# 案例 01：多级指标体系的综合评价
#
#   三级指标 --熵权--> 二级指标得分 --(熵权 + AHP 博弈论组合赋权)--> 一级综合得分
#   另按年份分组给出各省的 TOPSIS 相对接近度与排名。
#
# 数据：examples/data/employment-quality.xlsx
#       2020-2022 年 30 个省份的就业质量，含 5 个二级指标 / 11 个三级指标
#       Sheet1 = 指标数据（首行是合并的二级指标名），Sheet2 = 指标体系与方向
#
# 运行：bash scripts/run_r.sh examples/cases/01-comp-eval/script.R
#
# 覆盖的包函数：weight_entropy / weight_critic / weight_cv / AHP /
#               combine_weights / linear_sum / topsis / rescale
# ============================================================================

source(file.path(Sys.getenv("MMR_HOME"), "scripts", "mmr.R"))
mmr_init(label = "案例01 多级指标体系综合评价：熵权 + AHP 组合赋权 + TOPSIS")

suppressPackageStartupMessages({
  library(mathmodels); library(dplyr); library(tidyr)
  library(tibble); library(purrr); library(ggplot2); library(readxl)
})

XLSX <- file.path(Sys.getenv("MMR_HOME"), "examples", "data", "employment-quality.xlsx")

# ---- 1. 读数据与指标体系 ---------------------------------------------------
# Sheet1 首行是跨列合并的二级指标名，真正的列名在第二行，故 skip = 1
df <- read_excel(XLSX, skip = 1)
# Sheet2 的一级/二级指标列有合并单元格（续行为 NA），fill() 向下填充还原
spec <- read_excel(XLSX, sheet = 2) |>
  fill(1:2) |>
  mutate(二级指标 = factor(二级指标, levels = unique(二级指标)))

mmr_log("数据 ", nrow(df), " 行：", paste(range(df$年份), collapse = "-"), " 年 x ",
        n_distinct(df$地区), " 个地区 x ", ncol(df) - 2, " 个三级指标")
mmr_log("指标体系：", n_distinct(spec$一级指标), " 个一级 / ",
        n_distinct(spec$二级指标), " 个二级 / ", nrow(spec), " 个三级指标")

# 按二级指标把指标体系切成 5 组：每组自带三级指标名与方向向量
splits <- split(spec, spec$二级指标)

# ---- 2. 三级指标熵权 -> 二级指标得分 ---------------------------------------
# weight_entropy(X, index)：index 取 "+"/"-" 表示按正/负向做内置归一化，
# 取 NA 表示该列已自行归一化、不要再标化。此处全部是原始指标，逐列给方向。
lv3 <- map(splits, \(s) weight_entropy(df[s$三级指标], s$方向))

tab_w3 <- imap_dfr(splits, \(s, nm) tibble(
  二级指标 = nm,
  三级指标 = s$三级指标,
  方向     = s$方向,
  熵权     = as.numeric(lv3[[nm]]$w)
))
mmr_table(tab_w3, "01_三级指标熵权")

# 各三级指标带权合成 -> 二级指标得分（熵权法已权重归一，得分落在 [0,1]）
df2 <- bind_cols(df[1:2], map_dfc(lv3, "s"))
names(df2) <- c("年份", "地区", as.character(levels(spec$二级指标)))
mmr_log("二级指标得分范围：", sprintf("%.2f ~ %.2f", min(df2[[3]]), max(df2[[3]])),
        "（注意：weight_entropy()$s 已在 0-100 量纲，不要再乘 100）")

# ---- 3. 二级指标权重：熵权（客观）+ AHP（主观）-> 组合赋权 ------------------
w2_obj <- weight_entropy(df2[-(1:2)], rep("+", ncol(df2) - 2))$w

A <- matrix(c(1,   1/2, 1/5, 1/4, 1/3,
              2,   1,   1/3, 1/2, 1,
              5,   3,   1,   3,   5,
              4,   2,   1/3, 1,   3,
              3,   1,   1/5, 1/3, 1), nrow = 5, byrow = TRUE)
ahp <- AHP(A)
stopifnot(ahp$CR < 0.1)   # 一致性不达标必须先调判断矩阵，不能硬算
mmr_log(sprintf("AHP 一致性比率 CR = %.4f（< 0.1，通过）", ahp$CR))

# 博弈论组合赋权（type 可选 linear / multiplicative / game / game_linear）
w2 <- combine_weights(ahp$w, w2_obj, type = "game")

mmr_table(tibble(二级指标 = names(w2_obj), 熵权 = as.numeric(w2_obj),
                 AHP权重 = as.numeric(ahp$w), 组合权重 = as.numeric(w2)),
          "01_二级指标权重")

# ---- 4. 合成一级综合得分 ---------------------------------------------------
# linear_sum(data, w) = 各行指标向量与权重 w 的加权和；因二级得分已是 0-100
# 量纲，这里不再乘 100（乘了就会得到几千分的荒谬结果）。
df2$就业质量 <- as.numeric(linear_sum(df2[-(1:2)], w2))
df2 <- df2 |> mutate(排名 = min_rank(desc(就业质量)), .by = 年份)
mmr_log(sprintf("就业质量得分范围：%.2f ~ %.2f", min(df2$就业质量), max(df2$就业质量)))

mmr_table(df2 |> select(年份, 地区, 就业质量, 排名) |> arrange(年份, 排名),
          "01_就业质量综合得分")
mmr_log("2022 年综合得分前 5：",
        paste(df2[df2$年份 == 2022, ] |> arrange(排名) |> head(5) |>
                mutate(x = paste0(地区, "(", round(就业质量, 1), ")")) |>
                pull(x), collapse = "，"))

# ---- 5. 三层权重汇总（可直接进论文的权重表）--------------------------------
# 一级得分 = Σ 二级组合权重 x 二级得分，二级得分 = Σ 三级熵权 x 三级指标
# 故等价于三级指标上的综合权重 = 三级熵权 x 其所属二级指标的组合权重
tab_w3 <- tab_w3 |>
  mutate(二级组合权重 = w2[as.character(二级指标)],
         综合权重     = 熵权 * 二级组合权重) |>
  arrange(desc(综合权重))
mmr_table(tab_w3, "01_三级指标综合权重")
mmr_log("权重最大的 3 个三级指标：",
        paste(head(tab_w3$三级指标, 3), collapse = "，"))

# ---- 6. TOPSIS 相对接近度（按年份分组，逐年横比）---------------------------
# TOPSIS 的 index 只认 "+"/"-"（不接受 NA）。本数据无居中/区间型指标，
# 若指标里有"越接近某值越好"的，必须先用 rescale_middle()/rescale_interval()
# 转成正向，再在这里统一标 "+"。
IND <- names(df)[-(1:2)]                       # 11 个三级指标列名
idx_all <- spec$方向[match(IND, spec$三级指标)]
stopifnot(!anyNA(idx_all))
w_all <- tab_w3$综合权重[match(IND, tab_w3$三级指标)]

# 注意：nest(.by = 年份) 之后，嵌套表里第一列是「地区」（年份已被提到外层），
# 所以这里按列名取指标，不要用 d[-(1:2)] 这种位置下标。
res_top <- df |>
  nest(.by = 年份) |>
  mutate(model = map(data, \(d) tibble(
    地区   = d$地区,
    接近度 = as.numeric(topsis(d[IND], w_all, idx_all))))) |>
  select(-data) |> unnest(model) |>
  mutate(综合得分 = rescale(接近度, b = 100), 排名 = min_rank(desc(综合得分)), .by = 年份)

mmr_table(res_top |> select(年份, 地区, 接近度, 综合得分, 排名) |> arrange(年份, 排名),
          "01_TOPSIS排名")

# ---- 7. 出图 ---------------------------------------------------------------
p1 <- tab_w3 |>
  select(三级指标, 熵权, 综合权重) |>
  pivot_longer(-三级指标, names_to = "权重类型", values_to = "权重") |>
  ggplot(aes(reorder(三级指标, 权重), 权重, fill = 权重类型)) +
  geom_col(position = "dodge") +
  coord_flip() +
  labs(title = "三级指标权重：单层熵权 vs 计入二级权重的综合权重",
       x = NULL, y = "权重") +
  theme(legend.position = "top")
mmr_fig(p1, "01_三级指标权重", width = 7.5, height = 5)

p2 <- res_top |>
  filter(年份 == max(年份)) |>
  ggplot(aes(reorder(地区, 综合得分), 综合得分)) +
  geom_col(fill = "#C0392B", width = 0.7) +
  coord_flip() +
  labs(title = sprintf("%d 年各省就业质量综合得分（TOPSIS）", max(res_top$年份)),
       x = NULL, y = "综合得分") +
  theme(axis.text.y = element_text(size = 7))
mmr_fig(p2, "01_TOPSIS排名", width = 6.5, height = 7)

p3 <- df2 |>
  pivot_longer(3:7, names_to = "二级指标", values_to = "得分") |>
  ggplot(aes(年份, 得分, group = 地区)) +
  geom_line(alpha = 0.35) +
  stat_summary(aes(group = 1), fun = mean, geom = "line", color = "#C0392B", linewidth = 1.1) +
  facet_wrap(~二级指标) +
  labs(title = "各二级指标得分走势（红粗线 = 30 省均值）", x = NULL, y = "得分")
mmr_fig(p3, "01_二级指标得分走势", width = 8, height = 5)

mmr_finish(notes = paste0("2020-2022 年 30 省就业质量：三级指标熵权 -> 二级得分 -> ",
                          "AHP+熵权博弈论组合赋权 -> 一级得分；TOPSIS 按年份分组排名。",
                          "全部数字见 tables/01_*.csv。"))
