# 运行日志

- 时间：2026-10-12 11:14:19
- 标题：mathmodels 全模块冒烟测试
- R 版本：R version 4.6.1 (2026-06-24 ucrt)
- mathmodels：0.0.14
- 工作目录：<skill>/tests/runs/20261012-111418

- [11:14:20] INFO [OK]   预处理：rescale / normalize / standardize / to_positive
- [11:14:20] INFO [OK]   预处理：rescale_middle / rescale_interval / 其余 rescale_* 家族
- [11:14:20] INFO [OK]   AHP（含一致性比率 CR）
- [11:14:20] INFO [OK]   客观赋权：weight_entropy / weight_critic / weight_cv（index 允许 NA）
- [11:14:20] INFO [OK]   降维赋权：weight_pca / weight_fa（参数名是 nfs）
- [11:14:20] INFO [OK]   组合赋权：combine_weights（linear / multiplicative / game / game_linear）
- [11:14:20] INFO [OK]   TOPSIS + linear_sum（index 只认 +/-，不接受 NA）
- [11:14:20] INFO [OK]   灰色关联：grey_corr / grey_corr_topsis（★X 必须传 data.frame，传 matrix 会按元素迭代报零极差）
- [11:14:20] INFO [OK]   秩和比 RSR：rank_sum_ratio（int / non-int；★数据必须带 ID 列）
- [11:14:20] INFO [OK]   模糊综合：compute_mf_funs / compute_mf / fuzzy_eval / defuzzify
- [11:14:20] INFO [OK]   隶属函数族 mf_*（各函数要求的 params 个数不同，见下）
- [11:14:20] INFO [OK]   DEA 家族：basic_DEA / super_DEA / basic_SBM / super_SBM
- [11:14:20] INFO [OK]   不平等测度：gini / theil（pop 必填）/ theil_g（group 传列名字符）
- [11:14:20] INFO [OK]   区域经济：LQ / HHI / EG
- [11:14:20] INFO [OK]   系统评价：coupling_degree / obstacle_degree
- [11:14:20] INFO [OK]   灰色预测：GM11 / DGM21 / verhulst / GM1N
- [11:14:20] INFO [OK]   灰色-马尔可夫 / 马尔可夫链
- [11:14:20] INFO [OK]   回归预测：reg_*（公式在前 data 在后；系数表在 $coefficient，单数）
- [11:14:25] INFO [OK]   时间序列：as_ts_df / ts_test / ts_stl / ts_sarima / ts_ets / ts_forecast
- [11:14:25] INFO [OK]   时间序列：ts_transform / ts_back_transform 拟回原尺度
- [11:14:25] INFO [OK]   插值与拟合：interp_* / poly_fit / curve_fit / growth_fit
- [11:14:26] INFO [OK]   ODE：ode_solver 自定义方程组
- [11:14:26] INFO [OK]   ODE 内置族：malthus / logistic / si / sis / sir / seir / lv
- [11:14:27] INFO 图形 -> figs/smoke_compartments.png
- [11:14:28] INFO 图形 -> figs/smoke_compartments.pdf
- [11:14:29] INFO 图形 -> figs/smoke_incidence.png
- [11:14:30] INFO 图形 -> figs/smoke_incidence.pdf
- [11:14:30] INFO [OK]   传染病指标与可视化：epi_metrics（字段 peak_infection 而非 peak）
- [11:14:30] INFO [OK]   降维：mv_pca / mv_efa（参数名是 factors，不是 nfactors）
- [11:14:30] INFO [OK]   聚类：mv_hclust / mv_kmeans / mv_cluster_metrics（data 必须是 data.frame）
- [11:14:30] INFO [OK]   判别与相关结构：mv_discrim / mv_cancor / mv_pcor
- [11:14:30] INFO [OK]   对应分析与多维标度：mv_corresp（长表 + row/col 列）/ mv_mds
- [11:14:31] INFO 图形 -> figs/smoke_na_bar.png
- [11:14:32] INFO 图形 -> figs/smoke_na_bar.pdf
- [11:14:33] INFO 图形 -> figs/smoke_na_heatmap.png
- [11:14:34] INFO 图形 -> figs/smoke_na_heatmap.pdf
- [11:14:34] INFO [OK]   缺失诊断：na_summary / na_mcar_test / plot_na_bar / plot_na_heatmap
- [11:14:34] INFO [OK]   插补：impute（均值/中位数/模型法）与 impute_model
- [11:14:34] INFO [OK]   多重插补：impute_multiple 返回 m 个数据框的裸 list + rubin_pool
- [11:14:34] INFO [OK]   异常值：outlier 三种 to=（detect 出清单 / na / cap）
- [11:14:34] INFO [OK]   透视表 pivot_table（index / columns / values / aggfunc）
- [11:14:35] INFO [OK]   统计推断：stat_* 全家族（注意 resp / row / col 参数名）
- [11:14:35] INFO [OK]   三线表导出：export_table（LaTeX / Word）
- [11:14:35] INFO 冒烟结果：35 项通过，0 项失败

## 产物清单
- 表格：（无）
- 图形：smoke_compartments.png, smoke_compartments.pdf, smoke_incidence.png, smoke_incidence.pdf, smoke_na_bar.png, smoke_na_bar.pdf, smoke_na_heatmap.png, smoke_na_heatmap.pdf
- 耗时：16.5 秒

## 备注
- 冒烟测试：35 通过 / 0 失败
