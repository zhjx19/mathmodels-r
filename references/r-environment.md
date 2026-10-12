# 本地 R 环境与编码地雷（全部本机实测）

> 本文件记录 mathmodels-r 在本机（Windows + R 4.6.1 + Git Bash）实测通过的做法，
> 以及实测失败的坑。每条都注明「现象 → 根因 → 做法」。改动前请先跑
> `Rscript --vanilla scripts/check_env.R` 复核。

## 1. 定位 Rscript

优先级：`$MMR_RSCRIPT` → 常见安装路径扫描 → `PATH` 上的 `Rscript`。

本机路径：

```
D:/R-4.6.1/bin/Rscript.exe
```

`run_r.sh` 已内置该路径为首选，并在 `C:/Program Files/R/R-*/bin/Rscript.exe`
里按版本号降序兜底。换机器只用设一个环境变量，不必改脚本：

```bash
export MMR_RSCRIPT="/c/Program Files/R/R-4.5.0/bin/Rscript.exe"
```

## 2. ★ LC_* 地雷（本 skill 存在的主要理由）

**现象**：UTF-8 编码的 `.R` 脚本里有中文字面量时报

```
<ERROR: re-encoding failure from encoding 'UTF-8'>
Error: unexpected symbol in ...
```

或中文路径被静默截断——`"D:/my-project/建模数据/raw.csv"` 变成
`'D:/my-project/mathmodelsf'`，报 `cannot open file ...: Permission denied`。
（截断点落在多字节字符中间，于是路径尾巴被吃掉。）

**根因**：Git Bash 会把 `LANG` / `LC_ALL` / `LC_CTYPE` / `LC_COLLATE` 导出成
`C.UTF-8`。Windows 版 R 不认这些 POSIX locale，启动时先失败（那串
`Setting LC_COLLATE=C.UTF-8 failed` 警告），随后源码解析退回一个坏状态。

**做法**：启动 R 前把这些变量清掉。`run_r.sh` 已内建：

```bash
env -u LANG -u LC_ALL -u LC_CTYPE -u LC_COLLATE -u LANGUAGE "$RSCRIPT" --vanilla script.R
```

清掉之后：中文字面量、中文路径、中文日志、中文 CSV 全部正常。
**注意**：加 `--encoding=UTF-8` 或给脚本写 UTF-8 BOM 都**不能**解决，
反而分别带来 `re-encoding failure` 与 `unexpected invalid token in "ï"`。
唯一的解法是清环境变量。

## 3. 中文绘图：三条实测结论（反直觉，务必按此办）

| 输出 | 做法 | 实测结果 |
|---|---|---|
| **PNG** | `ggsave(path, p, width, height, dpi)` 默认设备（`base_family = "sans"`） | ✅ 中文正常 |
| **PDF 矢量** | `ggsave(..., device = cairo_pdf)` 且主题字体族设为 `"Microsoft YaHei"` | ✅ 中文正常、字体内嵌 |
| PDF 备选 | `pdf()` + `family = "GB1"`（R 自带 CJK 字体族） | ⚠️ 可用，但西文有字距问题（`TOPSIS` 印成 `TOPSI S`） |
| ❌ | `showtext::showtext_auto()` 但**未** `font_add()` 注册中文字体 | ❌ 中文全变方框（豆腐块） |
| ❌ | `cairo_pdf()` 用默认字体族 | ❌ 中文变方框 |
| ❌ | `pdf()` 用默认字体族 | ❌ 中文缺字空白，并伴随大量 font 警告 |

`mmr_fig()` 已把正确做法固化：PNG 走默认设备；PDF 走 `cairo_pdf` 并自动把
`element_text(family = MMR$pdf_family)`（默认 `Microsoft YaHei`）叠加上去。
确需 showtext 时，必须显式注册字体后再切 family：

```r
sysfonts::font_add("cn", regular = "C:/Windows/Fonts/msyh.ttc")
showtext::showtext_auto()
ggplot(...) + theme(text = element_text(family = "cn"))
```

本机可用中文字体文件：`msyh.ttc`、`msyhbd.ttc`、`simhei.ttf`、`simsun.ttc`、
`Deng.ttf`。

## 4. 文本落盘

- **CSV**：`mmr_table()` 写 **UTF-8 + BOM**。不加 BOM 时 Windows Excel 双击
  打开中文表头是乱码；加 BOM 后双击即正常。
- **日志/报告**：`file(open = "wt", encoding = "UTF-8")` 或
  `writeLines(..., useBytes = TRUE)`。
- **不要把中文交给控制台回显**：经 shell 管道回传会被二次编码。所有可见产物
  一律写文件，`run_r.sh` 再把 stdout/stderr 重定向进 `console.txt`。

## 5. `cat()` 没有 `useBytes` 形参（静默污染陷阱）

```r
cat(line, "\n", sep = "", file = logfile, append = TRUE, useBytes = TRUE)
#                                                                 ^^^^^^^^^^^^^^^
# cat() 的形参表里没有 useBytes，它落进 ...，于是被当成"要输出的内容"写进文件
# 日志里会凭空多出一串 "TRUE"，而 R 不报任何错。
```

`useBytes` 只属于 `writeLines()` / `writeChar()` 等。**改日志相关代码后，
务必打开 `log.md` 数一眼有没有 `TRUE` 噪声。**

## 6. 其他实测事实

- R 4.6.1 (ucrt)，`.libPaths()` = `D:/R-4.6.1/library`，`mathmodels` 0.0.14 已装。
- 22 个 Imports 依赖全部就绪（见 `check_env.R` 的自检输出）。
- `capabilities("cairo")` = TRUE，故 `cairo_pdf` 可用。
- 包级 startup 的 `Setting LC_* failed` 警告在清掉环境变量后**不再出现**；
  若仍出现，说明调用方没走 `run_r.sh` 的环境修复。
- `sf`/`terra` 等空间包不在依赖内；`read_nbs()` 读邻接矩阵时若缺依赖会报错，
  属可选功能。

## 7. 自查清单（换机器 / 换 R 版本后跑一遍）

1. `Rscript --vanilla scripts/check_env.R` 全绿；
2. 用 `run_r.sh` 跑 `examples/e2e-run/script.R`，退出码 0；
3. 打开 run 目录下 `figs/*.pdf`，中文标题不是方框；
4. 双击 `tables/*.csv`，中文表头不乱码；
5. `grep -c "^TRUE" log.md` 结果为 0。
