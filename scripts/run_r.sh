#!/usr/bin/env bash
# ============================================================================
# run_r.sh —— 用本地 R 跑一个数学建模脚本，并把产物落成一个可复现的 run 目录
#
# 用法:
#   bash run_r.sh <script.R> [run_dir]
#
# 关键作用（每一条都是本机实测过的坑，不是理论）：
#   1. 清掉 Git Bash 注入的 LC_ALL/LC_CTYPE/LANG —— 否则 Windows R 无法解析
#      UTF-8 源码里的中文字面量，报 "re-encoding failure" 或把中文路径截断。
#   2. R 的位置可配置：$MMR_RSCRIPT > 常见安装路径 > PATH 上的 Rscript。
#   3. stdout/stderr 重定向落盘（R 在 Windows 上原生写 UTF-8，中文日志不经过
#      shell 管道就不会二次编码）。
#   4. 收尾把产物清单、sessionInfo、耗时写进 run 目录，方便论文回填数字。
#
# 环境变量:
#   MMR_RSCRIPT   Rscript 可执行文件路径（优先）
#   MMR_RUNS      产物根目录（默认 <脚本所在目录的上一级>/runs）
# ============================================================================
set -uo pipefail

SCRIPT="${1:?用法: bash run_r.sh <script.R> [run_dir]}"
RUN_DIR="${2:-}"

if [[ ! -f "$SCRIPT" ]]; then
  echo "✘ 找不到脚本: $SCRIPT" >&2
  exit 2
fi

# ---- 1. 定位 Rscript ----
find_rscript() {
  if [[ -n "${MMR_RSCRIPT:-}" ]]; then echo "$MMR_RSCRIPT"; return; fi
  local cands=(
    "D:/R-4.6.1/bin/Rscript.exe"
    "C:/Program Files/R/R-4.4.1/bin/Rscript.exe"
    "C:/Program Files/R/R-4.3.1/bin/Rscript.exe"
    "C:/Program Files/R/R-4.2.1/bin/Rscript.exe"
  )
  local c
  for c in "${cands[@]}"; do [[ -x "$c" ]] && { echo "$c"; return; }; done
  # 兜底：扫 C:/Program Files/R 下的最高版本
  local hit
  hit=$(ls -d "C:/Program Files/R"/R-*/bin/Rscript.exe 2>/dev/null | sort -V | tail -1)
  [[ -n "$hit" ]] && { echo "$hit"; return; }
  command -v Rscript 2>/dev/null || true
}
RSCRIPT="$(find_rscript)"
if [[ -z "$RSCRIPT" || ! -x "$RSCRIPT" ]]; then
  echo "✘ 未找到 Rscript。请设置 MMR_RSCRIPT 指向本机 Rscript.exe" >&2
  exit 3
fi

# ---- 2. 建 run 目录 ----
SCRIPT_ABS="$(cd "$(dirname "$SCRIPT")" && pwd)/$(basename "$SCRIPT")"
if [[ -z "$RUN_DIR" ]]; then
  ROOT="${MMR_RUNS:-$(cd "$(dirname "$SCRIPT")" && pwd)/runs}"
  RUN_DIR="$ROOT/$(date +%Y%m%d-%H%M%S)"
fi
mkdir -p "$RUN_DIR/tables" "$RUN_DIR/figs"
cp -f "$SCRIPT_ABS" "$RUN_DIR/script.R"

echo "▶ Rscript : $RSCRIPT"
echo "▶ 脚本    : $SCRIPT_ABS"
echo "▶ run 目录: $RUN_DIR"

# 让脚本无需硬编码即可定位工作台：source(file.path(Sys.getenv("MMR_HOME"), "scripts", "mmr.R"))
MMR_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export MMR_HOME

# ---- 3. 运行（清 LC_*，重定向落盘）----
START=$(date +%s)
( cd "$RUN_DIR" && env -u LANG -u LC_ALL -u LC_CTYPE -u LC_COLLATE -u LANGUAGE \
    "$RSCRIPT" --vanilla script.R ) > "$RUN_DIR/console.txt" 2>&1
CODE=$?
END=$(date +%s)

# ---- 4. 落元数据 ----
{
  echo "script: $(basename "$SCRIPT_ABS")"
  echo "rscript: $RSCRIPT"
  echo "exit_code: $CODE"
  echo "started: $(date -d @$START '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date)"
  echo "elapsed_sec: $((END - START))"
} > "$RUN_DIR/meta.txt"

# ---- 5. 报告 ----
echo "▶ 退出码  : $CODE  （耗时 $((END-START))s）"
if [[ -s "$RUN_DIR/console.txt" ]]; then
  echo "▶ 控制台尾部（完整见 $RUN_DIR/console.txt）:"
  grep -v -E "Setting LC_|^During startup|^Warning messages" "$RUN_DIR/console.txt" | tail -12 | sed 's/^/    /'
fi
NT=$(ls -1 "$RUN_DIR/tables" 2>/dev/null | wc -l | tr -d ' ')
NF=$(ls -1 "$RUN_DIR/figs"  2>/dev/null | wc -l | tr -d ' ')
echo "▶ 产物    : tables/ ${NT} 个, figs/ ${NF} 个"
ls -1 "$RUN_DIR" | sed 's/^/    /'
exit $CODE
