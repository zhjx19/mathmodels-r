# 运行日志

- 时间：2026-10-10 23:30:29
- 标题：mathmodels-r 端到端验收
- R 版本：R version 4.6.1 (2026-06-24 ucrt)
- mathmodels：0.0.14
- 工作目录：D:\WorkBuddy\mathmodels技能\.workbuddy\scratch\runs\20261010-233025

- [23:30:31] INFO 第一步：多指标综合评价
- [23:30:31] INFO 表格 -> tables/topsis_ranking.csv  20 行 x 4 列
- [23:30:31] INFO 表格 -> tables/entropy_weights.csv  4 行 x 2 列
- [23:30:31] INFO TOPSIS 最优对象：R11，得分 100
- [23:30:32] INFO 图形 -> figs/topsis_scores.png
- [23:30:33] INFO 图形 -> figs/topsis_scores.pdf
- [23:30:33] INFO 第二步：SIR 传染病模型
- [23:30:33] INFO 表格 -> tables/sir_metrics.csv  4 行 x 2 列
- [23:30:33] INFO R0 = 1.5；峰值 69.7 人，出现在第 65 天
- [23:30:34] INFO 图形 -> figs/sir_compartments.png
- [23:30:34] INFO 图形 -> figs/sir_compartments.pdf
- [23:30:35] INFO 图形 -> figs/sir_incidence.png
- [23:30:35] INFO 图形 -> figs/sir_incidence.pdf
- [23:30:35] INFO 第三步：国际航空客运量预测
- [23:30:35] INFO 表格 -> tables/ts_stationarity.csv  2 行 x 5 列
- [23:30:38] INFO 表格 -> tables/sarima_forecast.csv  12 行 x 4 列
- [23:30:39] INFO 图形 -> figs/sarima_forecast.png
- [23:30:39] INFO 图形 -> figs/sarima_forecast.pdf
- [23:30:39] INFO 第四步：统计推断
- [23:30:39] INFO 表格 -> tables/ttest_sleep.csv  1 行 x 16 列
- [23:30:39] INFO t 检验 p 值 = 0.07939

## 产物清单
- 表格：topsis_ranking.csv, entropy_weights.csv, sir_metrics.csv, ts_stationarity.csv, sarima_forecast.csv, ttest_sleep.csv
- 图形：topsis_scores.png, topsis_scores.pdf, sir_compartments.png, sir_compartments.pdf, sir_incidence.png, sir_incidence.pdf, sarima_forecast.png, sarima_forecast.pdf
- 耗时：9.5 秒

## 备注
- 四类任务全部跑通：评价、ODE、时间序列、统计推断。
