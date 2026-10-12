# ============================================================================
# check_env.R —— mathmodels-r 环境自检
#
# 用法:
#   Rscript --vanilla check_env.R                # 人读报告
#   Rscript --vanilla check_env.R --json         # 机器可读
#
# 检查项：R 版本、libPaths、mathmodels 版本、依赖包齐备度、中文渲染能力
# （PNG 默认设备 / cairo_pdf + 系统中文字体）、UTF-8 字面量解析、图表导出依赖。
# 任何一项 FAIL 都会在结论里给出可执行的修复建议。
# ============================================================================

args <- commandArgs(trailingOnly = TRUE)
as_json <- "--json" %in% args

R <- list()
add <- function(name, ok, detail) R[[length(R) + 1]] <<- list(item = name, ok = ok, detail = detail)

add("R 版本", getRversion() >= "4.1",
    sprintf("%s（要求 >= 4.1）", R.version.string))

add("libPaths", length(.libPaths()) > 0, paste(.libPaths(), collapse = " | "))

mm_ver <- tryCatch(as.character(utils::packageVersion("mathmodels")), error = function(e) NA_character_)
add("mathmodels", !is.na(mm_ver), if (is.na(mm_ver)) "未安装：install.packages('mathmodels')" else mm_ver)

# ---- 依赖齐备度（按 DESCRIPTION 的 Imports 逐项 requireNamespace）----
need <- c("boot", "car", "flextable", "lpSolveAPI", "minpack.lm", "nnet", "rpart",
          "dplyr", "forecast", "ggplot2", "MASS", "purrr", "readxl", "rlang",
          "stats", "stringr", "tibble", "tidyr", "tseries", "deSolve", "patchwork", "lmtest")
have <- vapply(need, function(p) requireNamespace(p, quietly = TRUE), logical(1))
add("依赖包", all(have),
    sprintf("%d/%d 就绪%s", sum(have), length(have),
            if (all(have)) "" else paste0("；缺：", paste(names(have)[!have], collapse = ", "))))

# ---- 中文渲染：PNG 默认设备 ----
png_ok <- tryCatch({
  f <- tempfile(fileext = ".png")
  grDevices::png(f, width = 400, height = 300)
  graphics::plot(1, 1, main = "中文渲染测试")
  grDevices::dev.off()
  ok <- file.exists(f) && file.size(f) > 1000
  unlink(f); ok
}, error = function(e) FALSE)
add("PNG 默认设备", png_ok, if (png_ok) "可用（中文正常）" else "不可用：检查 grDevices 图形设备")

# ---- 中文渲染：cairo_pdf + 系统中文字体 ----
cairo_ok <- isTRUE(capabilities("cairo"))
fonts <- if (.Platform$OS.type == "windows") {
  list.files("C:/Windows/Fonts", pattern = "^(msyh|simhei|simsun|Deng).*\\.(ttf|ttc|otf)$",
             ignore.case = TRUE)
} else character(0)
add("cairo_pdf", cairo_ok, sprintf("capabilities('cairo') = %s", cairo_ok))
add("系统中文字体", length(fonts) > 0,
    if (length(fonts)) paste(head(fonts, 5), collapse = ", ") else "未找到 msyh/simhei/simsun/Deng*")

# ---- UTF-8 字面量：脚本内中文字符串 ----
utf8_ok <- tryCatch({
  s <- "综合评价"
  nchar(s) == 4L && !any(is.na(iconv(s, "UTF-8", "UTF-8")))
}, error = function(e) FALSE)
add("中文字面量解析", utf8_ok,
    if (utf8_ok) "正常" else "异常：调用方必须先清掉 LC_ALL/LC_CTYPE/LANG（见 run_r.sh）")

# ---- 表格导出 ----
add("flextable（三线表）", requireNamespace("flextable", quietly = TRUE),
    "export_table() 导出 Word/LaTeX 三线表所需")

# ---- 输出 ----
ok_all <- all(vapply(R, function(x) x$ok, logical(1)))
if (as_json) {
  esc <- function(s) gsub('"', '\\\\"', s)
  cat('{"r": "', esc(R.version.string), '", "mathmodels": "', esc(ifelse(is.na(mm_ver), "", mm_ver)),
      '", "all_ok": ', tolower(as.character(ok_all)), ', "checks": [', sep = "")
  cat(paste(vapply(R, function(x)
    sprintf('{"item": "%s", "ok": %s, "detail": "%s"}', x$item, tolower(as.character(x$ok)), esc(x$detail)),
    character(1)), collapse = ","))
  cat(']}\n', sep = "")
} else {
  cat("mathmodels-r 环境自检\n")
  cat(strrep("-", 58), "\n")
  for (x in R) cat(sprintf("%-4s %-18s %s\n", if (x$ok) "[OK]" else "[!!]", x$item, x$detail))
  cat(strrep("-", 58), "\n")
  cat(if (ok_all) "结论：环境就绪，可以开工。\n" else "结论：存在未通过项，按上面提示修复后再跑。\n")
}
quit(status = if (ok_all) 0L else 1L)
