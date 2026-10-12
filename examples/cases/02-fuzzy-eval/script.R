# ============================================================================
# 案例 02：模糊综合评价（FCE）与隶属函数族
#
#   ① 11 个 mf_* 隶属函数的参数个数与值域（最容易记错的一组接口）
#   ② compute_mf_funs() / compute_mf() / plot_mf() 的用法
#   ③ 完整 FCE 流程：阈值 -> 隶属矩阵 R -> 权重 x R 模糊合成 -> 去模糊化
#   ④ 从评委打分/评语统计出隶属矩阵（模糊统计法）
#   ⑤ 从专家给出的年龄区间拟合"青年人"隶属函数（数据驱动）
#
# 数据：耕作方案指标与阈值（教材案例，内联）
#       examples/data/youth.xlsx（129 位专家对"青年人"年龄区间的调查）
#
# 运行：bash scripts/run_r.sh examples/cases/02-fuzzy-eval/script.R
#
# 覆盖的包函数：mf_tri / mf_trap / mf_gauss / mf_gbell / mf_gauss2 /
#               mf_sigmoid / mf_dsigmoid / mf_psigmoid / mf_z / mf_pi / mf_s /
#               plot_mf / compute_mf_funs / compute_mf / fuzzy_eval / defuzzify
# ============================================================================

source(file.path(Sys.getenv("MMR_HOME"), "scripts", "mmr.R"))
mmr_init(label = "案例02 模糊综合评价：隶属函数族 + 模糊合成 + 去模糊化")

suppressPackageStartupMessages({
  library(mathmodels); library(dplyr); library(tidyr)
  library(tibble); library(purrr); library(ggplot2); library(readxl)
})

DATA <- file.path(Sys.getenv("MMR_HOME"), "examples", "data")

# ============================================================================
# ① 隶属函数族：参数个数各不相同，这是最容易写错的地方
#    全部 mf_* 的调用形式都是 mf_xxx(x, params)，但 params 的长度不一。
# ============================================================================
MF <- list(
  mf_tri      = list(f = mf_tri,      p = c(1, 5, 9),        n = 3),
  mf_trap     = list(f = mf_trap,     p = c(1, 4, 6, 9),     n = 4),
  mf_gauss    = list(f = mf_gauss,    p = c(5, 1.2),         n = 2),
  mf_gbell    = list(f = mf_gbell,    p = c(5, 1.5, 2),      n = 3),
  mf_gauss2   = list(f = mf_gauss2,   p = c(1, 1.5, 9, 1.5), n = 4),
  mf_sigmoid  = list(f = mf_sigmoid,  p = c(5, 1.5),         n = 2),
  mf_dsigmoid = list(f = mf_dsigmoid, p = c(1, 1.5, 9, 1.5), n = 4),
  mf_psigmoid = list(f = mf_psigmoid, p = c(1, 1.5, 9, 1.5), n = 4),
  mf_z        = list(f = mf_z,        p = c(2, 6),           n = 2),
  mf_pi       = list(f = mf_pi,       p = c(1, 4, 6, 9),     n = 4),
  mf_s        = list(f = mf_s,        p = c(2, 8),           n = 2)
)
xs <- seq(0, 10, by = 0.05)

# 顺手核对：每个函数的实际参数量必须等于我们主张的 n（参数传错会直接报错）
tab_mf <- imap_dfr(MF, \(m, nm) {
  bad <- tryCatch({ m$f(xs, m$p); FALSE }, error = function(e) TRUE)
  tibble(函数 = nm, 参数量 = m$n, 参数值 = paste(m$p, collapse = ", "),
         报错 = bad, 值域下 = min(m$f(xs, m$p)), 值域上 = max(m$f(xs, m$p)))
})
stopifnot(!any(tab_mf$报错))
mmr_table(tab_mf |> select(-报错), "02_隶属函数参数与值域")
mmr_log("★ mf_dsigmoid 是唯一可能取负值的隶属函数（两个 sigmoid 之差），",
        "实测值域 [", round(min(MF$mf_dsigmoid$f(xs, MF$mf_dsigmoid$p)), 3), ", ",
        round(max(MF$mf_dsigmoid$f(xs, MF$mf_dsigmoid$p)), 3),
        "]；理论上下界为 ±1，实际到达多少取决于 params，不能按 [0,1] 用",
        "（0.0.14 起 Rd 已按此订正，原先误与其余 mf_* 一并声明为 [0,1]）")

# 11 条隶属函数曲线（用 mf_xxx() 直接算，再自己画，最可控）
tab_curve <- imap_dfr(MF, \(m, nm) tibble(函数 = nm, x = xs, 隶属度 = m$f(xs, m$p)))
p_mf <- ggplot(tab_curve, aes(x, 隶属度, color = 函数)) +
  geom_line(linewidth = 0.9) +
  labs(title = "11 个隶属函数（mathmodels::mf_*，参数量 2~4 不等）", x = "x", y = "隶属度") +
  theme(legend.position = "right", legend.text = element_text(size = 7))
mmr_fig(p_mf, "02_隶属函数族", width = 7.5, height = 4.5)

# plot_mf()：包自带的隶属函数绘图，传入一个函数
mmr_fig(plot_mf(\(x) mf_trap(x, c(1, 4, 6, 9)), xlim = c(0, 10), main = "梯形隶属函数（plot_mf）"),
        "02_plot_mf示例", width = 5, height = 4)

# ============================================================================
# ② compute_mf：把单个指标值转成"属于各评语的隶属向量"
#    阈值 knots 把数轴切成 n 段（n = length(knots) 个评语）
# ============================================================================
th <- c(0.05, 0.15, 0.25, 0.50)      # SO2 四个等级阈值
mfs <- compute_mf_funs(th)
mmr_log("compute_mf_funs(th) 返回 ", length(mfs), " 个函数（= length(th)，不是 +1）")
mmr_log("compute_mf(0.07, th) = ", paste(round(compute_mf(0.07, th), 4), collapse = ", "))

tab_mfviz <- imap_dfr(mfs, \(f, i) tibble(
  等级 = paste0("第", i, "级"), x = seq(0, 0.6, by = 0.005), 隶属度 = f(seq(0, 0.6, by = 0.005))))
p_mfs <- ggplot(tab_mfviz, aes(x, 隶属度, color = 等级)) +
  geom_line(linewidth = 0.9) +
  labs(title = "compute_mf_funs() 生成的 4 个等级隶属函数（SO2 阈值 0.05/0.15/0.25/0.50）",
       x = "SO2 浓度", y = "隶属度")
mmr_fig(p_mfs, "02_compute_mf_funs", width = 7, height = 4)

# ============================================================================
# ③ 完整 FCE：耕作方案选优（甲/乙/丙）
#    因素集 5 个、评语集 4 级（差/中/良/优），权重来自实际要求
# ============================================================================
df <- tibble(
  方案    = c("甲(三种三收)", "乙(两茬平作)", "丙(两年三熟)"),
  product = c(592.5, 529, 412),   # 亩产量 kg，越大越好
  quality = c(3, 2, 1),           # 产品质量 级，越小越好
  labor   = c(55, 38, 32),        # 亩用工量 工日，越小越好
  income  = c(72, 105, 85),       # 亩纯收入 元，越大越好
  ecology = c(4, 3, 2)            # 生态环境影响 级，越小越好
)

# 预处理：负向指标转正向，用"固定阈值"而不是"样本最大最小"来平移
# （阈值不随方案而变，才能保证 3 个方案用同一把尺子）
df_r <- df |>
  mutate(quality = 5 - quality, labor = 80 - labor, ecology = 5 - ecology)

th_mat <- tibble(
  product = c(0, 350, 450, 550),  # 亩产量：只给了 3 个阈值，前补 0
  quality = 1:4,                  # 产品质量
  labor   = seq(0, 60, 20),       # 亩用工量
  income  = c(0, 50, 90, 130),    # 亩纯收入
  ecology = 1:4                   # 生态环境影响
)
w      <- c(0.2, 0.1, 0.15, 0.3, 0.25)
scores <- c(30, 60, 75, 90)       # 依次是 差/中/良/优 的量化分（必须升序）
names(scores) <- c("差", "中", "良", "优")

eval_one <- function(x, type = 3, method = "weighted_average") {
  R  <- map2(as.numeric(x), th_mat, compute_mf) |> sapply(cbind)  # 4 级 x 5 指标
  mu <- fuzzy_eval(w, R, type)          # 模糊合成，已归一化
  list(s = defuzzify(mu, scores, method), mu = mu, R = R)
}

res <- df_r |> select(-方案) |> apply(1, eval_one)

tab_fce <- tibble(
  方案 = df$方案,
  差 = map_dbl(res, \(r) r$mu[1]), 中 = map_dbl(res, \(r) r$mu[2]),
  良 = map_dbl(res, \(r) r$mu[3]), 优 = map_dbl(res, \(r) r$mu[4]),
  综合评分 = map_dbl(res, "s")
) |>
  mutate(排名 = min_rank(desc(综合评分))) |>
  arrange(排名)
mmr_table(tab_fce, "02_耕作方案评价结果")
mmr_log("加权平均法结果：",
        paste(tab_fce$方案, "=", round(tab_fce$综合评分, 2), collapse = "；"),
        "→ 最优方案 ", tab_fce$方案[1])

# 合成算子灵敏度：type 1~5 是五种模糊合成算子，选哪个会改变结论，论文里应交代
type_names <- c("1 取小取大(主因素决定)", "2 乘积最大(主因素突出)", "3 乘加(加权平均)",
                "4 取小上界和", "5 均衡平均")
score_mat <- map(1:5, \(tp) df_r |> select(-方案) |>
                   apply(1, \(x) tryCatch(eval_one(x, type = tp)$s,
                                          error = function(e) NA_real_)))
tab_type <- tibble(
  算子 = type_names,
  甲   = map_dbl(score_mat, \(v) v[1]),
  乙   = map_dbl(score_mat, \(v) v[2]),
  丙   = map_dbl(score_mat, \(v) v[3])
)
tab_type$最优方案 <- apply(tab_type[, -1], 1, function(r)
  if (anyNA(r)) "—（不可用）" else c("甲", "乙", "丙")[which.max(r)])
mmr_table(tab_type, "02_合成算子灵敏度")
mmr_log("算子 3/4 与 1/2 给出的最优方案：", paste(unique(tab_type$最优方案), collapse = " / "))

# 注：算子 5（均衡平均型）的分母 r0 = sum(R[j,]) 取 R 的【行和】。若某评语等级在
#   所有指标上的隶属度都为 0（本例方案乙不存在"差"的可能），老版本会除零得 NaN 并
#   崩在 `if (sum(B) == 0)`（包自带文案反而不触发）。0.0.14 已修：该等级记 0、其余
#   照常归一。这里保留一条守卫断言，防止将来回退。
bad <- which(is.na(map_dbl(score_mat, \(v) v[2])))
stopifnot(!length(bad))                       # 0.0.14 修后不应再出现 NA
mmr_log("算子 5（均衡平均型）对\"某等级全 0\"已容错：方案乙的\"差\"等级记 0，",
        "归一后方案乙得分 = ", round(score_mat[[5]][2], 4))

# ============================================================================
# ④ 模糊统计法：从评委打分/评语直接统计出隶属矩阵
#    （不需要隶属函数——分组计数就是隶属度）
# ============================================================================
set.seed(1)
# 注：as_tibble(matrix) 与 read_excel(col_names = FALSE) 都会在控制台刷
# "New names:" 提示，用 suppressMessages() 包住，保持 console.txt 干净。
dv <- suppressMessages(
  matrix(sample(30:100, 120, replace = TRUE), ncol = 10) |>
    as_tibble(.name_repair = "universal")
) |>
  set_names(paste0("评委", 1:10)) |>
  mutate(ID = rep(1:3, each = 4),
         指标 = rep(c("颜色", "做工", "品牌", "款式"), 3), .before = 1)

R_list <- dv |>
  pivot_longer(-(1:2), names_to = "评委", values_to = "打分") |>
  mutate(评语 = factor(case_when(打分 < 60 ~ "差", 打分 < 75 ~ "一般", .default = "好"),
                       levels = c("差", "一般", "好"))) |>
  count(ID, 指标, 评语) |>
  mutate(p = n / sum(n), .by = c(ID, 指标)) |>
  split(~ ID) |>
  map(\(d) d |> pivot_wider(id_cols = 评语, names_from = 指标, values_from = p) |>
        select(-评语) |> mutate(across(everything(), \(x) tidyr::replace_na(x, 0))))

tab_dress <- imap_dfr(R_list, \(m, id) as_tibble(m) |>
                        mutate(衣服 = paste0("第", id, "件"), .before = 1))
mmr_table(tab_dress, "02_评委打分的隶属矩阵")
mmr_log("从 10 位评委的打分直接统计出 3 件衣服 x 4 指标的隶属矩阵")

# ============================================================================
# ⑤ 数据驱动的隶属函数：129 位专家给出的"青年人"年龄区间
# ============================================================================
youth <- suppressMessages(read_excel(file.path(DATA, "youth.xlsx"), col_names = FALSE)) |>
  set_names(paste0("g", 1:13)) |>
  pivot_longer(everything(), names_to = "g", values_to = "x", values_drop_na = TRUE) |>
  separate(x, c("x1", "x2"), sep = "\u2212", convert = TRUE) |>   # 分隔符是 U+2212 减号
  select(-g)
mmr_log("青年人间卷：", nrow(youth), " 位专家，区间 "
        , min(youth$x1), "-", max(youth$x2))

# 隶属度 = 包含该年龄的专家区间占比
mf_youth <- function(x) mean(youth$x1 <= x & x <= youth$x2)
ages <- 10:40
tab_youth <- tibble(年龄 = ages, 隶属度 = map_dbl(ages, mf_youth))
mmr_table(tab_youth, "02_青年人隶属度")
p_youth <- ggplot(tab_youth, aes(年龄, 隶属度)) +
  geom_area(fill = "#2980B9", alpha = 0.2) +
  geom_line(color = "#2980B9", linewidth = 1) +
  geom_point(color = "#2980B9", size = 1) +
  labs(title = "由 129 位专家的年龄区间拟合的“青年人”隶属函数", x = "年龄", y = "隶属度")
mmr_fig(p_youth, "02_青年人隶属函数", width = 7, height = 4)

mmr_finish(notes = paste0("模糊综合评价完整链路：阈值 -> compute_mf() 生成隶属矩阵 -> ",
                          "fuzzy_eval() 模糊合成 -> defuzzify() 去模糊化。",
                          "耕作方案最优为 ", tab_fce$方案[1],
                          "（综合评分 ", round(tab_fce$综合评分[1], 2), "）。"))
