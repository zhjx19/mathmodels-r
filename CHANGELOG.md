# Changelog

格式参考 [keepachangelog](https://keepachangelog.com/) 精神：每条讲清"为什么改"，不只"改了什么"。

## [1.0] — 2026-10-12

首次公开发布。mathmodels-r = 本地 R + `mathmodels` 包（0.0.14）的数学建模算力层：
环境自检 → 方法选型 → 可复现 run 目录（脚本 / 日志 / 表格 / 图 / sessionInfo）。

### 为什么是这几条设计

- **把 Windows 中文环境的坑固化成运行器，而不是写成注意事项。**
  本机实测：Git Bash 注入的 `LC_*` 会让 UTF-8 源码里的中文字面量解析失败；
  `cairo_pdf()` / `pdf()` 用默认字体族输出中文是方框；CSV 不带 BOM 时 Excel 双击是乱码。
  这三条都不是"注意一下"能解决的，所以做进 `run_r.sh`（清 `LC_*`）与 `mmr.R`
  （PDF 强制 `cairo_pdf` + 字体族、CSV 带 BOM）。**绕过运行器手调 `Rscript` 会得到
  "脚本能跑但中文全乱码"的假成功**，这是本 skill 存在的主要理由。
- **交付物必须与自己的日志对得上账。**
  早期版本 `examples/e2e-run/` 只留了 3 表 3 图，而它自己的 `log.md` 声称 6 表 8 图——
  读者据它核对会得出错误结论。根因是回收产物时只 `cp` 不删、且 e2e-run 不在回收循环里。
  `run_all_examples.sh` 因此立了三道纪律：先剪除再回收、对照「产物清单」逐条验在、
  断言产物里无本机家目录路径与盘符绝对 run 目录。
- **产物可移植，不写本机路径。**
  `log.md` 的「工作目录」记成 `<skill>/…` 而非 `C:\Users\…`；
  文本产物一律 LF 落盘（R 在 Windows 上用文本连接写文件会产出 CRLF，
  导致同一份产物在两个平台字节不同、git 里反复显示「已修改」）。
  已知限制：Cairo 导出的 PDF 内嵌创建时间与文档 ID，每次重跑字节都不同
  （实测 `SOURCE_DATE_EPOCH=0` 无效），PNG 则字节稳定。
- **只陈述包的契约，不对任何书稿/文章的当前状态作断言。**
  同类表述（「在线书里还是旧名，照抄会报错」）一旦素材更新就集体变成假话。
  现在改为：更名事实只作为**包侧对照表**存在，表述统一为
  「凡在手边素材里遇到旧名，先按对照换名再跑」——这句话在素材更新前后都成立。

### 内容

- `scripts/`：`run_r.sh` 运行器、`mmr.R` 工作台（日志 / 表格 / 图形 / 中文安全）、
  `check_env.R` 环境自检（人读 + `--json`）、`gen_function_index.R` 索引生成。
- `references/`：`function-index.md`（162 个导出函数，机器生成）、
  `recipes.md`（选型表 + 34 条签名速查 + 14 个最小配方 + 上游修复记录）、
  `r-environment.md`（编码与字体地雷，每条附现象/根因/做法）。
- `examples/`：6 个在本机 0.0.14 上实跑通过的范例（综合评价 / 模糊评价 / DEA /
  区域经济 / 系统评价 / 灰色预测）+ 路由表 `index.md` + 8 份真实数据 + 一次端到端运行产物。
- `tests/`：35 项全模块冒烟测试；`run_all_examples.sh` 一键回归（含回收前对账）。
- 元数据：`version.json`、`test-prompts.json`、`.claude-plugin/marketplace.json`。
