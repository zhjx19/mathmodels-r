# gen_function_index.R —— 从 mathmodels 包源机器生成 API 索引
#
# 用法：
#   Rscript --vanilla gen_function_index.R <pkg_dir> <pkgdown_yml> <out_md>
#
# 依据 _pkgdown.yml 的模块分组，逐个函数从 man/*.Rd 抽取标题与用法首行，
# 生成 references/function-index.md。手写索引会过时/编造，此脚本保证与包源同步。
#
# 依赖：仅 base R（tools 包随 R 发行）。

args = commandArgs(trailingOnly = TRUE)
pkg_dir = if (length(args) >= 1) args[1] else "."
yml     = if (length(args) >= 2) args[2] else file.path(pkg_dir, "_pkgdown.yml")
out_md  = if (length(args) >= 3) args[3] else stdout()

# ---- 1. 读入 man/*.Rd，建立 name -> {title, usage, aliases} ----
man_files = list.files(file.path(pkg_dir, "man"), pattern = "\\.Rd$", full.names = TRUE)
# 从完整 \usage 块中按括号配平抽出指定函数的签名。
# 注意：必须定义在文件顶层并以参数接收 usage_full——若定义在遍历循环内部，
# 闭包会捕获最后一次迭代的 usage_full，导致所有函数都取不到签名（真实踩过的坑）。
pick_usage = function(fn, usage_full) {
  if (is.null(usage_full) || !nzchar(usage_full)) return("")
  fn_esc = gsub(".", "\\.", fn, fixed = TRUE)   # 只转义点号，其余名字字符在正则中无歧义
  pat = paste0("(^|[^A-Za-z0-9_.])", fn_esc, "[[:space:]]*\\(")
  m = regexpr(pat, usage_full, perl = TRUE)
  if (m[[1]] < 0) return("")
  st = m[[1]] + attr(m, "match.length") - 1L    # 命中段末尾即函数名的 "("
  # 回退到函数名起点：先跳过空白，再退过函数名字符
  s0 = st
  while (s0 > 1L && grepl("[[:space:]]", substr(usage_full, s0 - 1L, s0 - 1L))) s0 = s0 - 1L
  while (s0 > 1L && grepl("[A-Za-z0-9_.]", substr(usage_full, s0 - 1L, s0 - 1L))) s0 = s0 - 1L
  depth = 0L; i = st; n = nchar(usage_full)
  while (i <= n) {
    ch = substr(usage_full, i, i)
    if (ch == "(") depth = depth + 1L
    else if (ch == ")") { depth = depth - 1L; if (depth == 0L) break }
    i = i + 1L
  }
  trimws(gsub("[[:space:]]+", " ", substr(usage_full, s0, min(i, n))))
}

rd_db = list()
for (f in man_files) {
  rd = tryCatch(tools::parse_Rd(f), error = function(e) NULL)
  if (is.null(rd)) next
  get_field = function(tag) {
    idx = which(vapply(rd, function(x) identical(attr(x, "Rd_tag"), tag), logical(1)))
    if (!length(idx)) return(NA_character_)
    raw = paste(unlist(rd[idx]), collapse = "")
    gsub("[\r\n]+", " ", trimws(raw))
  }
  nm = get_field("\\name")
  if (is.na(nm)) next
  # 一个 Rd 常通过 \alias 文档化多个函数（如 rescale.Rd 覆盖 rescale_* 全家），
  # 因此按 \name 与全部 \alias 建多键索引。
  aliases = (function() {
    idx = which(vapply(rd, function(x) identical(attr(x, "Rd_tag"), "\\alias"), logical(1)))
    if (!length(idx)) return(nm)
    a = vapply(idx, function(i) gsub("\\s+", "", paste(unlist(rd[[i]]), collapse = "")), character(1))
    unique(c(nm, a))
  })()
  usage_full = get_field("\\usage")
  if (is.na(usage_full)) usage_full = ""
  entry = list(title = get_field("\\title"), usage_full = usage_full)
  for (a in aliases) if (is.null(rd_db[[a]])) rd_db[[a]] = entry
}

# ---- 2. 解析 _pkgdown.yml 的 reference 分组 ----
lines = readLines(yml, warn = FALSE, encoding = "UTF-8")
groups = list(); cur_title = NULL; cur_cont = character(); in_ref = FALSE
flush = function() {
  if (!is.null(cur_title)) groups[[length(groups) + 1]] <<- list(title = cur_title, items = cur_cont)
}
for (ln in lines) {
  if (grepl("^reference:", ln)) { in_ref = TRUE; next }
  if (in_ref && grepl("^[a-z_]+:", ln) && !grepl("^reference:", ln)) { flush(); in_ref = FALSE; cur_title = NULL; next }
  if (!in_ref) next
  m = regmatches(ln, regexec("^- title:\\s*\"(.*)\"\\s*$", ln))[[1]]
  if (length(m) == 2) { flush(); cur_title = m[2]; cur_cont = character(); next }
  if (is.null(cur_title)) next
  m2 = regmatches(ln, regexec("^\\s+-\\s+([A-Za-z0-9_.]+)\\s*$", ln))[[1]]
  if (length(m2) == 2) { cur_cont = c(cur_cont, m2[2]); next }
  m3 = regmatches(ln, regexec("^\\s+contents:\\s*(.*)$", ln))[[1]]
  if (length(m3) == 2 && nzchar(trimws(m3[2]))) {
    cur_cont = c(cur_cont, strsplit(trimws(m3[2]), "\\s*,\\s*")[[1]])
  }
}
flush()

# ---- 3. 输出 ----
con = if (identical(out_md, stdout())) stdout() else file(out_md, open = "wt", encoding = "UTF-8")
w = function(...) cat(..., "\n", sep = "", file = con)

w("# mathmodels 函数索引（机器生成，勿手改）")
w("")
w(sprintf("> 由 `scripts/gen_function_index.R` 从包源 `man/*.Rd` + `_pkgdown.yml` 生成。"))
w(sprintf("> 生成时包版本：%s｜收录函数与别名条目：%d", as.character(utils::packageVersion("mathmodels")), length(rd_db)))
w("> 更新方式：`Rscript scripts/gen_function_index.R <pkg_dir> <pkg_dir>/_pkgdown.yml references/function-index.md`")
w("")

covered = character()
for (g in groups) {
  if (!length(g$items)) next
  w("## ", g$title)
  w("")
  for (fn in g$items) {
    if (fn %in% covered) next
    covered = c(covered, fn)
    e = rd_db[[fn]]
    if (is.null(e)) { w("- `", fn, "()` — *（包内无对应帮助页）*"); next }
    ttl = if (is.na(e$title)) "" else e$title
    ttl = gsub("\\s+", " ", ttl)
    us = pick_usage(fn, e$usage_full)
    if (!nzchar(us)) us = paste0(fn, "(...)")
    if (nchar(us) > 160) us = paste0(substr(us, 1, 157), "...")
    w("- **`", fn, "`** — ", ttl)
    w("  - `", us, "`")
  }
  w("")
}

# 未在 pkgdown 分组中出现的导出函数
ns = readLines(file.path(pkg_dir, "NAMESPACE"), warn = FALSE)
exports = sub("^export\\((.*)\\)$", "\\1", grep("^export\\(", ns, value = TRUE))
rest = setdiff(exports, covered)
if (length(rest)) {
  w("## 其他导出对象（未在 _pkgdown.yml 分组）")
  w("")
  for (fn in rest) {
    e = rd_db[[fn]]
    ttl = if (!is.null(e) && !is.na(e$title)) e$title else "*（无帮助页）*"
    w("- **`", fn, "`** — ", ttl)
  }
  w("")
}

if (!identical(out_md, stdout())) close(con)
cat("OK: generated", length(covered) + length(rest), "entries ->", out_md, "\n")
