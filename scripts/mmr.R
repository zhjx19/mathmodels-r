# ============================================================================
# mmr.R —— mathmodels-r 工作台（R 侧）
#
# 在生成的分析脚本开头 source() 本文件，即可获得统一的日志、产物目录、
# 表格与图形导出、中文渲染设置、会话信息落盘。
#
# 设计原则（全部来自本机实测）：
#   * 中文渲染：PNG 走 R 默认设备（中文正常）；PDF 走 cairo_pdf 并强制
#     "Microsoft YaHei" 字体族（默认 pdf()/cairo_pdf() 输出中文是豆腐块/空白）。
#     绝不在未注册字体时使用 showtext_auto()——那会把中文全变成方框。
#   * 文本数据一律 UTF-8 落盘；CSV 带 BOM，便于 Excel 直接双击打开不乱码。
#   * 一切可见产物都写文件，不依赖控制台回显（控制台编码不可靠）。
#
# 兼容：R >= 4.1。无外部依赖（ggplot2 只在画图时按需调用）。
# ============================================================================

MMR <- new.env(parent = emptyenv())
MMR$dir       <- "."
MMR$tables    <- "./tables"
MMR$figs      <- "./figs"
MMR$log_file  <- "./log.md"
MMR$t0        <- Sys.time()
MMR$tables_written <- character()
MMR$figs_written   <- character()
MMR$pdf_family     <- Sys.getenv("MMR_PDF_FAMILY", "Microsoft YaHei")

# ---- 初始化 ----------------------------------------------------------------
# run_dir: run 目录；留空则用当前工作目录（run_r.sh 已 cd 到 run 目录）
# label:   本次运行的标题，写进日志与 summary
mmr_init <- function(run_dir = NULL, label = "") {
  if (!is.null(run_dir)) {
    MMR$dir <- normalizePath(run_dir, mustWork = FALSE)
    if (!dir.exists(MMR$dir)) dir.create(MMR$dir, recursive = TRUE)
    owd <- setwd(MMR$dir); on.exit(setwd(owd), add = TRUE)
  } else {
    MMR$dir <- normalizePath(getwd(), mustWork = TRUE)
  }
  MMR$tables   <- file.path(MMR$dir, "tables")
  MMR$figs     <- file.path(MMR$dir, "figs")
  MMR$log_file <- file.path(MMR$dir, "log.md")
  for (d in c(MMR$tables, MMR$figs)) if (!dir.exists(d)) dir.create(d, recursive = TRUE)
  MMR$t0 <- Sys.time()

  suppressWarnings({
    options(encoding = "UTF-8", scipen = 6)
    # 中文安全：PNG/屏幕设备用默认 sans；不碰 showtext
    if (requireNamespace("ggplot2", quietly = TRUE)) {
      ggplot2::theme_set(ggplot2::theme_minimal(base_family = "sans"))
    }
  })

  writeLines(c(
    sprintf("# 运行日志"),
    "",
    sprintf("- 时间：%s", format(MMR$t0, "%Y-%m-%d %H:%M:%S")),
    sprintf("- 标题：%s", if (nzchar(label)) label else "(未命名)"),
    sprintf("- R 版本：%s", R.version.string),
    sprintf("- mathmodels：%s",
            tryCatch(as.character(utils::packageVersion("mathmodels")), error = function(e) "未安装")),
    sprintf("- 工作目录：%s", MMR$dir),
    ""
  ), MMR$log_file, useBytes = TRUE)
  invisible(MMR$dir)
}

# ---- 日志 ------------------------------------------------------------------
# 注意：cat() 没有 useBytes 形参——误传会把它当成待输出内容写进文件（日志里
# 会凭空多出 "TRUE"）。所以这里只给 writeLines() 传 useBytes。
mmr_log <- function(..., level = "INFO") {
  msg <- paste0(...)
  line <- sprintf("- [%s] %s %s", format(Sys.time(), "%H:%M:%S"), level, msg)
  cat(line, "\n", sep = "", file = MMR$log_file, append = TRUE)
  cat(line, "\n", sep = "")            # 同时回显，便于 run_r.sh 的 console.txt
  invisible(msg)
}

# ---- 表格导出 --------------------------------------------------------------
# 写 CSV（UTF-8 + BOM）。BOM 让 Windows Excel 双击打开不乱码。
mmr_table <- function(x, name, digits = 6) {
  if (!is.data.frame(x)) x <- as.data.frame(x)
  num <- vapply(x, is.numeric, logical(1))
  x[num] <- lapply(x[num], function(v) if (is.double(v)) round(v, digits) else v)
  path <- file.path(MMR$tables, paste0(name, ".csv"))
  # 先取 CSV 文本（R 在 Windows 上原生即 UTF-8），再加 BOM 一次性写盘
  txt <- utils::capture.output(utils::write.csv(x, row.names = FALSE, na = ""))
  con <- file(path, open = "wb")
  writeBin(charToRaw("\xef\xbb\xbf"), con)          # UTF-8 BOM：Excel 双击不乱码
  writeBin(charToRaw(paste0(paste(txt, collapse = "\n"), "\n")), con)
  close(con)
  MMR$tables_written <- c(MMR$tables_written, basename(path))
  mmr_log("表格 -> tables/", basename(path), "  ", nrow(x), " 行 x ", ncol(x), " 列")
  invisible(path)
}

# ---- 图形导出 --------------------------------------------------------------
# plot: ggplot 对象，或一个无参函数（base 绘图）
# fmt : 同时导出哪些格式；pdf 为矢量，优先用于论文插图
mmr_fig <- function(plot, name, width = 7, height = 4.5, dpi = 300,
                    fmt = c("png", "pdf"), title = NULL) {
  fmt <- match.arg(fmt, several.ok = TRUE)
  is_gg <- inherits(plot, "ggplot")
  if (!is.null(title)) {
    if (is_gg) plot <- plot + ggplot2::labs(title = title)
  }
  for (f in fmt) {
    path <- file.path(MMR$figs, paste0(name, ".", f))
    if (f == "pdf") {
      if (is_gg) {
        # 关键：PDF 设备必须显式指定中文字体族，否则中文变方框
        p <- plot + ggplot2::theme(text = ggplot2::element_text(family = MMR$pdf_family))
        ggplot2::ggsave(path, p, width = width, height = height, device = grDevices::cairo_pdf, bg = "white")
      } else {
        grDevices::cairo_pdf(path, width = width, height = height, family = MMR$pdf_family, bg = "white")
        plot(); grDevices::dev.off()
      }
    } else {
      if (is_gg) {
        ggplot2::ggsave(path, plot, width = width, height = height, dpi = dpi, bg = "white")
      } else {
        grDevices::png(path, width = width * dpi, height = height * dpi, res = dpi, bg = "white")
        plot(); grDevices::dev.off()
      }
    }
    MMR$figs_written <- c(MMR$figs_written, basename(path))
    mmr_log("图形 -> figs/", basename(path))
  }
  invisible(path)
}

# ---- 收尾 ------------------------------------------------------------------
mmr_finish <- function(notes = NULL) {
  el <- as.numeric(difftime(Sys.time(), MMR$t0, units = "secs"))
  con <- file(MMR$log_file, open = "at", encoding = "UTF-8")
  writeLines(c(
    "",
    "## 产物清单",
    if (length(MMR$tables_written)) paste0("- 表格：", paste(MMR$tables_written, collapse = ", ")) else "- 表格：（无）",
    if (length(MMR$figs_written))   paste0("- 图形：", paste(MMR$figs_written,   collapse = ", ")) else "- 图形：（无）",
    sprintf("- 耗时：%.1f 秒", el),
    if (!is.null(notes)) c("", "## 备注", paste0("- ", notes)) else NULL
  ), con, useBytes = TRUE)
  close(con)
  writeLines(utils::capture.output(utils::sessionInfo()), file.path(MMR$dir, "sessionInfo.txt"), useBytes = TRUE)
  cat(sprintf("\n[mmr] 完成：%d 表, %d 图, 耗时 %.1fs\n", length(MMR$tables_written), length(MMR$figs_written), el))
  invisible(TRUE)
}
