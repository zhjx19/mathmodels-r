# mathmodels 函数索引（机器生成，勿手改）

> 由 `scripts/gen_function_index.R` 从包源 `man/*.Rd` + `_pkgdown.yml` 生成。
> 生成时包版本：0.0.14｜导出函数总数：162
> 更新方式：`Rscript scripts/gen_function_index.R <pkg_dir> <pkg_dir>/_pkgdown.yml references/function-index.md`

## Data Preprocessing

- **`standardize`** — Preprocessing Functions for Data Normalization and Standardization
  - `standardize(x, center = TRUE, scale = TRUE)`
- **`normalize`** — Preprocessing Functions for Data Normalization and Standardization
  - `normalize(x)`
- **`rescale`** — Preprocessing Functions for Data Normalization and Standardization
  - `rescale(x, type = "+", a = 0, b = 1)`
- **`rescale_middle`** — Preprocessing Functions for Data Normalization and Standardization
  - `rescale_middle(x, m)`
- **`rescale_interval`** — Preprocessing Functions for Data Normalization and Standardization
  - `rescale_interval(x, a, b)`
- **`rescale_extreme`** — Preprocessing Functions for Data Normalization and Standardization
  - `rescale_extreme(x, type = "+")`
- **`rescale_initial`** — Preprocessing Functions for Data Normalization and Standardization
  - `rescale_initial(x, type = "+")`
- **`rescale_mean`** — Preprocessing Functions for Data Normalization and Standardization
  - `rescale_mean(x)`
- **`to_positive`** — Preprocessing Functions for Data Normalization and Standardization
  - `to_positive(x, type = "minmax")`

## Weighting Methods

- **`AHP`** — AHP: Analytic Hierarchy Process
  - `AHP(A)`
- **`combine_weights`** — Combine Subjective and Objective Weights
  - `combine_weights(w_subj, w_obj, type = "linear", alpha = 0.5)`
- **`weight_critic`** — CRITIC Weight Method
  - `weight_critic( X, index = NULL, method = "std", cor_method = "pearson", epsilon = 0.002 )`
- **`weight_cv`** — Coefficient of Variation Weighting
  - `weight_cv(X)`
- **`weight_entropy`** — Entropy Weight Method
  - `weight_entropy(X, index = NULL, epsilon = 0.002)`
- **`weight_fa`** — Factor-Analysis-Based Weighting Method
  - `weight_fa(X, index = NULL, nfs = 1, rotation = "varimax", method = "abs")`
- **`linear_sum`** — Linear weighted synthesis
  - `linear_sum(data, w)`
- **`weight_pca`** — PCA-Based Weighting Method
  - `weight_pca(X, index = NULL, nfs = NULL, varimax = TRUE, method = "abs")`

## Evaluation Models

- **`topsis`** — TOPSIS Method for Multi-Criteria Decision Making
  - `topsis(X, w = NULL, index = NULL)`
- **`rank_sum_ratio`** — Rank Sum Ratio (RSR) Evaluation
  - `rank_sum_ratio(data, w = NULL, method = "int")`
- **`grey_corr`** — Grey Relational Analysis Functions
  - `grey_corr(ref, cmp, rho = 0.5, w = NULL)`
- **`grey_corr_topsis`** — Grey Relational Analysis Functions
  - `grey_corr_topsis(X, w, index = NULL, rho = 0.5)`

## Fuzzy Evaluation

- **`mf_tri`** — Membership Functions for Fuzzy Logic
  - `mf_tri(x, params)`
- **`mf_trap`** — Membership Functions for Fuzzy Logic
  - `mf_trap(x, params)`
- **`mf_gauss`** — Membership Functions for Fuzzy Logic
  - `mf_gauss(x, params)`
- **`mf_gbell`** — Membership Functions for Fuzzy Logic
  - `mf_gbell(x, params)`
- **`mf_gauss2`** — Membership Functions for Fuzzy Logic
  - `mf_gauss2(x, params)`
- **`mf_sigmoid`** — Membership Functions for Fuzzy Logic
  - `mf_sigmoid(x, params)`
- **`mf_dsigmoid`** — Membership Functions for Fuzzy Logic
  - `mf_dsigmoid(x, params)`
- **`mf_psigmoid`** — Membership Functions for Fuzzy Logic
  - `mf_psigmoid(x, params)`
- **`mf_z`** — Membership Functions for Fuzzy Logic
  - `mf_z(x, params)`
- **`mf_pi`** — Membership Functions for Fuzzy Logic
  - `mf_pi(x, params)`
- **`mf_s`** — Membership Functions for Fuzzy Logic
  - `mf_s(x, params)`
- **`plot_mf`** — Membership Functions for Fuzzy Logic
  - `plot_mf(mf, xlim = c(0, 10), main = NULL)`
- **`compute_mf_funs`** — Build membership functions from knots
  - `compute_mf_funs(knots, .builder = "tri", ...)`
- **`compute_mf`** — Build membership functions from knots
  - `compute_mf(x, knots, .builder = "tri", ...)`
- **`fuzzy_eval`** — Fuzzy Comprehensive Evaluation
  - `fuzzy_eval(w, R, type)`
- **`defuzzify`** — Defuzzification Methods for Fuzzy Comprehensive Evaluation
  - `defuzzify(mu, scores, method = "weighted_average")`

## Data Envelopment Analysis

- **`basic_DEA`** — DEA efficiency analysis
  - `basic_DEA( data, inputs, outputs, ud_outputs = NULL, orientation = "io", rts = "vrs" )`
- **`super_DEA`** — DEA efficiency analysis
  - `super_DEA(data, inputs, outputs, orientation = "io", rts = "vrs")`
- **`basic_SBM`** — DEA efficiency analysis
  - `basic_SBM( data, inputs, outputs, ud_outputs = NULL, orientation = "io", rts = "vrs" )`
- **`super_SBM`** — DEA efficiency analysis
  - `super_SBM(data, inputs, outputs, orientation = "io", rts = "vrs")`
- **`malmquist`** — DEA efficiency analysis
  - `malmquist( data, period, inputs, outputs, orientation = "oo", rts = "vrs", type1 = "glob", type2 = "rd" )`

## Inequality Measures

- **`gini0`** — Inequality Indices
  - `gini0(y)`
- **`gini`** — Inequality Indices
  - `gini(y, pop)`
- **`theil0`** — Inequality Indices
  - `theil0(y)`
- **`theil`** — Inequality Indices
  - `theil(y, pop)`
- **`theil0_g`** — Inequality Indices
  - `theil0_g(data, group, y)`
- **`theil_g`** — Inequality Indices
  - `theil_g(data, group, y, pop)`
- **`theil_g2_cross`** — Inequality Indices
  - `theil_g2_cross(data, group1, group2, y, pop)`
- **`theil_g2_nest`** — Inequality Indices
  - `theil_g2_nest(data, group1, group2, y, pop)`

## Regional Economics

- **`LQ`** — Regional Economics Functions
  - `LQ(data, region, total, .cols, .by = NULL)`
- **`HHI`** — Regional Economics Functions
  - `HHI(x, scaled = FALSE)`
- **`EG`** — Regional Economics Functions
  - `EG(data, region, industry, y)`

## System Evaluation

- **`coupling_degree`** — System Evaluation Functions for Coupling and Obstacle Analysis
  - `coupling_degree(data, w = NULL, id_cols = NULL, type = "standard")`
- **`obstacle_degree`** — System Evaluation Functions for Coupling and Obstacle Analysis
  - `obstacle_degree(data, w = NULL, id_cols = NULL, scaled = FALSE)`

## Grey Prediction Models

- **`GM11`** — Grey Prediction Models
  - `GM11(X)`
- **`GM1N`** — Grey Prediction Models
  - `GM1N(dat, new_data = NULL)`
- **`DGM21`** — Grey Prediction Models
  - `DGM21(X)`
- **`verhulst`** — Grey Prediction Models
  - `verhulst(X)`
- **`combine_preds`** — Combine Multiple Prediction Results
  - `combine_preds(x)`

## Markov Prediction Models

- **`markov_chain`** — Markov Chain Prediction
  - `markov_chain(S, s0, n_steps = 5)`
- **`GM11_markov`** — Grey-Markov Prediction Model
  - `GM11_markov(X, n_ahead = 3, breaks = c(-0.1, -0.05, -0.02, 0, 0.02, 0.05, 0.1))`

## Time Series Models

- **`ts_df`** — Lightweight Time-Series Data Frame
  - `ts_df(data, time = "time", value = "value", frequency = 1, start = NULL)`
- **`as_ts_df`** — Convert Common Inputs to ts_df
  - `as_ts_df(x, time = NULL, value = NULL, frequency = NULL, start = NULL)`
- **`is_ts_df`** — Check Whether an Object Is a ts_df
  - `is_ts_df(x)`
- **`validate_ts_df`** — Validate a ts_df
  - `validate_ts_df(x, require_complete = TRUE, require_no_na = FALSE)`
- **`complete_ts_df`** — Complete Missing Time Points
  - `complete_ts_df(x, by)`
- **`impute_ts_df`** — Complete and Interpolate a ts_df
  - `impute_ts_df(x, by, method = c("linear", "spline"))`
- **`drop_na_ts_df`** — Drop Missing Values from a ts_df
  - `drop_na_ts_df(x)`
- **`ts_transform`** — Transform a ts_df
  - `ts_transform( x, method = c("none", "log", "boxcox"), lambda = NULL, diff = 0L, seasonal_diff = 0L )`
- **`ts_back_transform`** — Back-Transform Forecasts
  - `ts_back_transform(forecast_tbl, params, bias_adj = TRUE)`
- **`ts_test`** — Stationarity Tests for a Time Series
  - `ts_test(x, adf_lags = NULL)`
- **`ts_stl`** — STL Decomposition for a ts_df
  - `ts_stl(x, s_window = "periodic", robust = TRUE, ...)`
- **`ts_ets`** — ETS Model Fitting
  - `ts_ets(x, model = "ZZZ", ...)`
- **`ts_sarima`** — SARIMA Model Fitting
  - `ts_sarima( x, order = NULL, seasonal = NULL, stepwise = TRUE, approximation = TRUE, ... )`
- **`ts_arimax`** — ARIMAX Model Fitting
  - `ts_arimax( x, xreg, order = NULL, seasonal = NULL, stepwise = TRUE, approximation = TRUE, ... )`
- **`ts_forecast`** — Generate Forecasts
  - `ts_forecast(model_result, h = 12, level = c(80, 95), newxreg = NULL)`
- **`plot_ts`** — Plot a Time Series
  - `plot_ts(x, title = "Time Series", x_lab = "Time", y_lab = "Value")`
- **`plot_ts_forecast`** — Plot Forecasts
  - `plot_ts_forecast( x, forecast_tbl, level = c(80, 95), by = NULL, title = "Forecast" )`
- **`plot_ts_residuals`** — Residual Diagnostic Plot
  - `plot_ts_residuals(model_result, max_lag = 30L, title = "Residual Diagnostics")`
- **`plot_ts_stl`** — STL Decomposition Plot
  - `plot_ts_stl(stl_result, title = "STL Decomposition")`
- **`plot_ts_acf`** — Autocorrelation Plot
  - `plot_ts_acf(x, max_lag = 40L, title = "ACF")`
- **`plot_ts_pacf`** — Partial Autocorrelation Plot
  - `plot_ts_pacf(x, max_lag = 40L, title = "PACF")`

## Regression Prediction Models

- **`reg_lm`** — Multivariable Linear Regression
  - `reg_lm( formula, data, step = FALSE, direction = c("both", "forward", "backward"), ... )`
- **`reg_logistic`** — Logistic Regression
  - `reg_logistic( formula, data, step = FALSE, direction = c("both", "forward", "backward"), ... )`
- **`reg_poisson`** — Poisson Regression
  - `reg_poisson( formula, data, step = FALSE, direction = c("both", "forward", "backward"), ... )`
- **`reg_negbin`** — Negative Binomial Regression
  - `reg_negbin(formula, data, step = FALSE, ...)`
- **`reg_diagnostics`** — Model Diagnostics
  - `reg_diagnostics(model_result)`
- **`reg_predict`** — Predictions
  - `reg_predict(model_result, n_new = 10, level = 0.95, newdata = NULL)`
- **`plot_reg_residuals`** — Residual Diagnostics
  - `plot_reg_residuals(model_result)`
- **`plot_reg_predict`** — Prediction Plot
  - `plot_reg_predict(model_result, type = c("fitted", "predicted"), show_ci = TRUE)`

## Dimension Reduction

- **`mv_pca`** — Principal Component Analysis
  - `mv_pca(data, cols, scale = TRUE, center = TRUE)`
- **`mv_efa`** — Exploratory Factor Analysis
  - `mv_efa( data, cols, factors, rotation = "varimax", scores = c("regression", "none") )`
- **`plot_mv_scree`** — Scree Plot
  - `plot_mv_scree(x, type = c("prop", "cum"))`
- **`plot_mv_scores`** — Scores Plot
  - `plot_mv_scores(x, group = NULL)`

## Clustering Analysis

- **`mv_hclust`** — Hierarchical Clustering
  - `mv_hclust( data, cols, k = 3, dist_method = "euclidean", method = "ward.D2", scale = TRUE )`
- **`mv_kmeans`** — K-means Clustering
  - `mv_kmeans(data, cols, centers, nstart = 25, scale = TRUE, iter.max = 100)`
- **`mv_cluster_metrics`** — Clustering Validity Metrics
  - `mv_cluster_metrics( data, cols, cluster, dist_method = "euclidean", scale = TRUE )`
- **`plot_mv_elbow`** — Elbow Plot
  - `plot_mv_elbow( data, cols, max_k = 10, method = c("kmeans", "hclust"), nstart = 25, dist_method = "euclidean", hclust_method = "ward.D2", scale = TRUE )`
- **`plot_mv_silhouette`** — Silhouette Plot
  - `plot_mv_silhouette(x)`
- **`plot_mv_dendrogram`** — Dendrogram Plot
  - `plot_mv_dendrogram(x)`

## Discriminant Analysis

- **`mv_discrim`** — Linear and Quadratic Discriminant Analysis
  - `mv_discrim( data, group, cols, method = c("lda", "qda"), prior = NULL, newdata = NULL )`

## Correspondence Analysis and Scaling

- **`mv_corresp`** — Simple Correspondence Analysis
  - `mv_corresp(data, row, col, nf = 2)`
- **`mv_mds`** — Multidimensional Scaling
  - `mv_mds( data, cols, k = 2, metric = TRUE, dist_method = "euclidean", scale = TRUE, maxit = 50 )`
- **`plot_mv_corresp`** — Correspondence Analysis Map
  - `plot_mv_corresp(x)`
- **`plot_mv_mds`** — MDS Configuration Plot
  - `plot_mv_mds(x)`

## Correlation Structure

- **`mv_cancor`** — Canonical Correlation Analysis
  - `mv_cancor(data, x_cols, y_cols, scale = TRUE)`
- **`mv_pcor`** — Partial Correlation Matrix
  - `mv_pcor(data, cols)`

## Curve Fitting & Interpolation

- **`poly_fit`** — Polynomial Fit
  - `poly_fit(x, y, degree = 1)`
- **`curve_fit`** — Linearizable Curve Fit
  - `curve_fit(x, y, type = c("exp", "power", "log", "hyperbolic"))`
- **`growth_fit`** — Nonlinear Growth Curve Fit
  - `growth_fit(x, y, type = c("logistic", "gompertz", "saturation", "mm"))`
- **`interp_linear`** — Linear Interpolation
  - `interp_linear(x, y, xout)`
- **`interp_poly`** — Polynomial Interpolation
  - `interp_poly(x, y, xout, degree = 3)`
- **`interp_hermite`** — Piecewise Cubic Hermite Interpolation
  - `interp_hermite(x, y, xout)`
- **`interp_spline`** — Cubic Spline Interpolation
  - `interp_spline(x, y, xout, spar = NULL)`

## Differential Equation Models

- **`ode_solver`** — General ODE Solver
  - `ode_solver(init, times, equations, params = NULL, method = "lsoda", ...)`
- **`ode_malthus`** — Malthusian (Exponential) Growth Model
  - `ode_malthus(init, params, times, ...)`
- **`ode_logistic`** — Logistic Population Growth Model
  - `ode_logistic(init, params, times, ...)`
- **`ode_si`** — SI Epidemic Model
  - `ode_si(init, params, times, ...)`
- **`ode_sis`** — SIS Epidemic Model
  - `ode_sis(init, params, times, ...)`
- **`ode_sir`** — SIR Epidemic Model
  - `ode_sir(init, params, times, ...)`
- **`ode_seir`** — SEIR Epidemic Model
  - `ode_seir(init, params, times, ...)`
- **`ode_lv`** — Lotka-Volterra Predator-Prey Model
  - `ode_lv(init, params, times, ...)`
- **`epi_metrics`** — Extract key epidemic metrics from ODE simulation output
  - `epi_metrics(data, beta, gamma, N = NULL)`
- **`plot_compartments`** — Plot compartment trajectories
  - `plot_compartments(df, compartments = NULL)`
- **`plot_incidence`** — Plot daily new infections (dI)
  - `plot_incidence(df)`
- **`plot_phase_si`** — Phase plot S vs I
  - `plot_phase_si(df)`
- **`plot_Rt_estimate`** — Plot effective reproduction number R_t
  - `plot_Rt_estimate(df, params, N = NULL)`

## Data Cleaning

- **`na_summary`** — Missing Value Summary
  - `na_summary(data, .cols = dplyr::everything())`
- **`na_mcar_test`** — Little's MCAR Test
  - `na_mcar_test(data, .cols = dplyr::everything(), maxit = 200, tol = 1e-08)`
- **`plot_na_heatmap`** — Missingness Heatmap
  - `plot_na_heatmap(data, .cols)`
- **`plot_na_bar`** — Missingness Bar Plot
  - `plot_na_bar(data, .cols)`
- **`impute`** — Simple Missing Value Imputation
  - `impute( data, .cols, method = c("mean", "median", "mode", "linear", "spline", "constant"), .by = NULL, value = NULL )`
- **`impute_model`** — Model-Based Missing Value Imputation
  - `impute_model( data, .cols, model = c("knn", "lm", "tree"), .by = NULL, k = 5, ... )`
- **`impute_multiple`** — Multiple Imputation via FCS
  - `impute_multiple( data, .cols = dplyr::everything(), m = 5, maxit = 5, seed = NULL, methods = NULL )`
- **`rubin_pool`** — Pool Estimates via Rubin's Rules
  - `rubin_pool(est, err, alpha = 0.05, edf = Inf)`
- **`pool_fit`** — Pool lm/glm Fits Across Imputations
  - `pool_fit(fits, alpha = 0.05)`
- **`outlier`** — Outlier Detection and Handling
  - `outlier( data, .cols, .by = NULL, method = c("iqr", "zscore", "mad"), k = NULL, to = c("detect", "na", "cap") )`
- **`pivot_table`** — Pivot Table
  - `pivot_table( data, index, columns, values, aggfunc = mean, fill_value = NA, names_sep = "_" )`

## Statistical Inference

- **`stat_describe`** — Descriptive Statistics
  - `stat_describe(data, .cols, .by = NULL, conf_level = 0.95)`
- **`stat_t_test`** — t-test (one-sample, two-sample, Welch, paired)
  - `stat_t_test( data, .cols, group, .by = NULL, mu = 0, paired = FALSE, var.equal = FALSE, alternative = "two.sided", conf_level = 0.95, p_adjust = "none" )`
- **`stat_wilcox_test`** — Wilcoxon / Mann-Whitney Tests
  - `stat_wilcox_test( data, .cols, group, .by = NULL, mu = 0, paired = FALSE, alternative = "two.sided", conf_level = 0.95, p_adjust = "none" )`
- **`stat_anova`** — Analysis of Variance (ANOVA)
  - `stat_anova(data, resp, group, .by = NULL)`
- **`stat_kruskal`** — Kruskal-Wallis Rank Sum Test
  - `stat_kruskal(data, resp, group, .by = NULL)`
- **`stat_ancova`** — Analysis of Covariance (ANCOVA)
  - `stat_ancova(data, resp, group, covariates, .by = NULL, test_parallel = FALSE)`
- **`stat_cor`** — Correlation Analysis
  - `stat_cor( data, .cols, method = c("pearson", "spearman", "kendall"), .by = NULL, alternative = "two.sided", conf_level = 0.95, p_adjust = "none" )`
- **`stat_chisq`** — Chi-square Test of Independence
  - `stat_chisq(data, row, col, .by = NULL, correct = TRUE, exact = FALSE)`
- **`stat_normality`** — Normality Tests
  - `stat_normality(data, .cols, .by = NULL, p_adjust = "none")`
- **`stat_hov_test`** — Variance Homogeneity Tests
  - `stat_hov_test( data, .cols, group, .by = NULL, method = c("levene", "bartlett", "f"), center = c("median", "mean") )`
- **`stat_bootstrap`** — Bootstrap Estimation and Confidence Intervals
  - `stat_bootstrap( data, statistic, ..., B = 2000, type = c("bca", "percentile", "basic"), conf_level = 0.95, seed = NULL, .by = NULL, parallel = "no", ncpus = 1 )`
- **`stat_perm_test`** — Permutation Test
  - `stat_perm_test( data, .cols = NULL, group = NULL, statistic = NULL, ..., type = c("two.sample", "paired", "one.sample", "independence"), alternative = "two.s...`
- **`export_table`** — Three-line Table Export (Word / LaTeX)
  - `export_table( x, output = c("docx", "latex"), path = NULL, font = "Times New Roman", caption = NULL, note = NULL, digits = 3, font_size = 10 )`

## Datasets

- **`water_quality`** — Water Quality Dataset
  - `water_quality(...)`

## Data I/O Utilities

- **`read_nbs`** — Read and Combine National Bureau of Statistics XLS Files
  - `read_nbs(paths)`

