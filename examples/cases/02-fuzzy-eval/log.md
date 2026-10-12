# 运行日志

- 时间：2026-10-12 10:46:57
- 标题：案例02 模糊综合评价：隶属函数族 + 模糊合成 + 去模糊化
- R 版本：R version 4.6.1 (2026-06-24 ucrt)
- mathmodels：0.0.14
- 工作目录：C:\Users\zhang\.config\opencode\skills\mathmodels-r\.example-runs\20261012-104652\02-fuzzy-eval

- [10:46:58] INFO 表格 -> tables/02_隶属函数参数与值域.csv  11 行 x 5 列
- [10:46:58] INFO ★ mf_dsigmoid 是唯一可能取负值的隶属函数（两个 sigmoid 之差），实测值域 [-0.375, 0.375]；理论上下界为 ±1，实际到达多少取决于 params，不能按 [0,1] 用（0.0.14 起 Rd 已按此订正，原先误与其余 mf_* 一并声明为 [0,1]）
- [10:46:58] INFO 图形 -> figs/02_隶属函数族.png
- [10:46:59] INFO 图形 -> figs/02_隶属函数族.pdf
- [10:46:59] INFO 图形 -> figs/02_plot_mf示例.png
- [10:46:59] INFO 图形 -> figs/02_plot_mf示例.pdf
- [10:46:59] INFO compute_mf_funs(th) 返回 4 个函数（= length(th)，不是 +1）
- [10:46:59] INFO compute_mf(0.07, th) = 0.8, 0.2, 0, 0
- [10:46:59] INFO 图形 -> figs/02_compute_mf_funs.png
- [10:46:59] INFO 图形 -> figs/02_compute_mf_funs.pdf
- [10:46:59] INFO 表格 -> tables/02_耕作方案评价结果.csv  3 行 x 7 列
- [10:46:59] INFO 加权平均法结果：丙(两年三熟) = 75.7；乙(两茬平作) = 75.53；甲(三种三收) = 61.54→ 最优方案 丙(两年三熟)
- [10:46:59] INFO 表格 -> tables/02_合成算子灵敏度.csv  5 行 x 5 列
- [10:46:59] INFO 算子 3/4 与 1/2 给出的最优方案：乙 / 丙
- [10:46:59] INFO 算子 5（均衡平均型）对"某等级全 0"已容错：方案乙的"差"等级记 0，归一后方案乙得分 = 78.5359
- [10:47:00] INFO 表格 -> tables/02_评委打分的隶属矩阵.csv  9 行 x 5 列
- [10:47:00] INFO 从 10 位评委的打分直接统计出 3 件衣服 x 4 指标的隶属矩阵
- [10:47:00] INFO 青年人间卷：129 位专家，区间 14-36
- [10:47:00] INFO 表格 -> tables/02_青年人隶属度.csv  31 行 x 2 列
- [10:47:00] INFO 图形 -> figs/02_青年人隶属函数.png
- [10:47:00] INFO 图形 -> figs/02_青年人隶属函数.pdf

## 产物清单
- 表格：02_隶属函数参数与值域.csv, 02_耕作方案评价结果.csv, 02_合成算子灵敏度.csv, 02_评委打分的隶属矩阵.csv, 02_青年人隶属度.csv
- 图形：02_隶属函数族.png, 02_隶属函数族.pdf, 02_plot_mf示例.png, 02_plot_mf示例.pdf, 02_compute_mf_funs.png, 02_compute_mf_funs.pdf, 02_青年人隶属函数.png, 02_青年人隶属函数.pdf
- 耗时：2.9 秒

## 备注
- 模糊综合评价完整链路：阈值 -> compute_mf() 生成隶属矩阵 -> fuzzy_eval() 模糊合成 -> defuzzify() 去模糊化。耕作方案最优为 丙(两年三熟)（综合评分 75.7）。
