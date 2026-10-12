# 运行日志

- 时间：2026-10-12 11:09:19
- 标题：案例03 DEA 效率评价：CCR/BCC/超效率/SBM + Malmquist 面板
- R 版本：R version 4.6.1 (2026-06-24 ucrt)
- mathmodels：0.0.14
- 工作目录：<skill>/.example-runs/20261012-110844/03-dea-efficiency

- [11:09:21] INFO 医院截面数据：31 个 DMU（省份）
- [11:09:21] INFO basic_DEA() 返回字段：efficiencies, lambdas, slacks, targets, returns, model, orientation, dmu
- [11:09:21] INFO 表格 -> tables/03_超效率不可行性对照.csv  4 行 x 4 列
- [11:09:21] INFO 超效率模型（io + vrs）中有 2 个 DMU 无可行解（返回 NA），已用标准 BCC 效率值补齐
- [11:09:21] INFO ★ 对照见「03_超效率不可行性对照」：不可行只出现在 vrs（io 导向 2 个、oo 导向 1 个），crs 下两种导向恒为 0。机理：CRS 的锥形包络可以无限放大、永不失效；VRS 的凸组合够不到极端 DMU。所以看到 NA 不是数据错，是 VRS 超效率的固有不可行性
- [11:09:21] INFO 表格 -> tables/03_DEA效率汇总.csv  31 行 x 10 列
- [11:09:21] INFO BCC 投入导向下有效（效率 = 1）的 DMU：上海、天津、广东、福建、西藏、湖南、江西、云南、山东、新疆、四川
- [11:09:21] INFO 超效率排名前 5：西藏、云南、上海、福建、四川（超效率把同为 1 的 DMU 分了高下）
- [11:09:21] INFO 平均规模效率 = 0.9611；25 个 DMU 规模无效率
- [11:09:21] INFO 工业面板数据：155 行 = 31 个省份 x 5 个年份（2005-2009）
- [11:09:22] INFO malmquist() 返回字段：Period, DMU, mi, ec, tc, pech, sech
- [11:09:22] INFO 表格 -> tables/03_Malmquist指数.csv  124 行 x 7 列
- [11:09:22] INFO 全样本 mi 均值 = 1.0665（>1 表示生产率提升）；分解：ec = 1.0046，tc = 1.0615
- [11:09:22] INFO 表格 -> tables/03_Malmquist分年度均值.csv  4 行 x 4 列
- [11:09:25] INFO 图形 -> figs/03_DEA效率对比.png
- [11:09:26] INFO 图形 -> figs/03_DEA效率对比.pdf
- [11:09:27] INFO 图形 -> figs/03_规模效率.png
- [11:09:28] INFO 图形 -> figs/03_规模效率.pdf
- [11:09:29] INFO 图形 -> figs/03_Malmquist分布.png
- [11:09:30] INFO 图形 -> figs/03_Malmquist分布.pdf

## 产物清单
- 表格：03_超效率不可行性对照.csv, 03_DEA效率汇总.csv, 03_Malmquist指数.csv, 03_Malmquist分年度均值.csv
- 图形：03_DEA效率对比.png, 03_DEA效率对比.pdf, 03_规模效率.png, 03_规模效率.pdf, 03_Malmquist分布.png, 03_Malmquist分布.pdf
- 耗时：11.5 秒

## 备注
- 截面：CCR/BCC x 投入产出导向 + 超效率(NA 用标准效率补齐) + 带非期望产出的 SBM；规模效率 = CRS/VRS。面板：Malmquist 指数分解为 ec(效率变化) 与 tc(技术进步)。超效率的 NA 只在 VRS 下出现（凸组合够不到极端 DMU），CRS 永不失效。
