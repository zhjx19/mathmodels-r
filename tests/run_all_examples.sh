#!/usr/bin/env bash
# ============================================================================
# run_all_examples.sh —— 回归测试：跑通 examples/ 下的全部范例并回收真实产物
#
# 用法:
#   bash tests/run_all_examples.sh            # 跑全部（含 e2e-run）
#   bash tests/run_all_examples.sh 03 05      # 只跑名字含 03 或 05 的（跳过 e2e-run）
#
# 做三件事：
#   1. 用 scripts/run_r.sh 逐个运行范例脚本，任一非 0 退出码即记失败；
#   2. 把产物（log.md / tables/ / figs/ / meta.txt / sessionInfo.txt）回收到
#      各案例目录，使 examples/ 自带一份可核对的真实产物；
#   3. 回收前做三道纪律检查（防「交付物对不上账」——这一课是一次真实事故）：
#      a. 先剪除历史 tables/ figs/，避免陈旧文件残留；曾因只 cp 不删，导致
#         examples/e2e-run/ 只留 3 表 3 图、而它自己的 log.md 声称 6 表 8 图；
#      b. 对照 log.md 的「产物清单」逐条验在：清单里写的文件必须真的存在；
#      c. 断产物里不含本机家目录路径（隐私）与盘符绝对运行目录（不可移植）。
#
# 为什么产物要回收进案例目录：范例的价值一半在"长什么样"。读者（和 AI）
# 需要看到真实的表格列名、图的实际观感，而不是一段声称能跑的代码。
#
# 已知限制（实测，非本脚本能解决）：Cairo 导出的 PDF 内嵌创建时间/文档 ID，
# 每次重跑字节都不同（已实测 SOURCE_DATE_EPOCH=0 无效）；PNG 反而字节稳定。
# 所以重跑后 `git status` 会显示一批 PDF「已修改」，内容其实一样。只想复核、
# 不打算改图时，用 `git checkout -- 'examples/**/figs/*.pdf'` 丢弃这批字节差异。
#
# 环境变量:
#   MMR_EXAMPLE_SCRATCH  临时 run 目录根（默认 <skill>/.example-runs，已 gitignore）
# ============================================================================
set -uo pipefail

SKILL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CASES_DIR="$SKILL_ROOT/examples/cases"
E2E_DIR="$SKILL_ROOT/examples/e2e-run"
SCRATCH="${MMR_EXAMPLE_SCRATCH:-$SKILL_ROOT/.example-runs}"
STAMP="$(date +%Y%m%d-%H%M%S)"

[ -d "$CASES_DIR" ] || { echo "✘ 找不到 $CASES_DIR" >&2; exit 2; }

FILTERS=("$@")
PASS=0; FAIL=0; FAILED_NAMES=()

# 跑一个目录下的 script.R 并把产物回收进该目录
recover_one() {
  local d="$1" label="$2"
  local out="$SCRATCH/$STAMP/$label"
  mkdir -p "$out"
  echo "────────────────────────────────────────────────────────────"
  echo "▶ $label"

  if ! bash "$SKILL_ROOT/scripts/run_r.sh" "$d/script.R" "$out" > "$out/_run.log" 2>&1; then
    echo "    ✘ 失败，控制台尾部："
    grep -v -E "Setting LC_|^During startup" "$out/console.txt" 2>/dev/null \
      | tail -15 | sed 's/^/      /'
    FAIL=$((FAIL+1)); FAILED_NAMES+=("$label"); return
  fi

  # (a) 先剪除历史产物，再回收——只 cp 不删会让陈旧文件永远留在案例目录里
  rm -rf "$d/tables" "$d/figs"
  mkdir -p "$d/tables" "$d/figs"
  for f in log.md meta.txt sessionInfo.txt console.txt; do
    [ -f "$out/$f" ] && cp -f "$out/$f" "$d/$f"
  done
  for sub in tables figs; do
    [ -d "$out/$sub" ] && cp -f "$out/$sub"/* "$d/$sub/" 2>/dev/null
  done

  # (b) 产物清单对账：log.md 列出的表格/图形必须真的落在 tables/ figs/ 里
  local miss="" kind entry
  for kind in "表格:tables" "图形:figs"; do
    local key="${kind%%:*}" dir="${kind##*:}"
    local listed
    listed="$(sed -n "s/^- ${key}：//p" "$d/log.md" 2>/dev/null)"
    [ "$listed" = "（无）" ] && continue
    for entry in $(printf '%s' "$listed" | tr ',' ' '); do
      [ -z "$entry" ] && continue
      [ -f "$d/$dir/$entry" ] || miss="$miss ${dir}/${entry}"
    done
  done
  if [ -n "$miss" ]; then
    echo "    ✘ 产物与 log.md 的「产物清单」对不上，缺：$miss"
    FAIL=$((FAIL+1)); FAILED_NAMES+=("$label(manifest-mismatch)"); return
  fi

  # (c) 可移植性/隐私断言：交付物里不许出现本机家目录路径或盘符绝对运行目录
  if grep -qE 'C:[\\/]Users[\\/]|/c/Users/|/home/[A-Za-z]|/Users/[A-Za-z]' \
        "$d/log.md" "$d/meta.txt" 2>/dev/null; then
    echo "    ✘ 产物含本机家目录路径（隐私泄露），拒绝回收："
    grep -nE 'C:[\\/]Users[\\/]|/c/Users/|/home/[A-Za-z]|/Users/[A-Za-z]' \
      "$d/log.md" "$d/meta.txt" 2>/dev/null | head -3 | sed 's/^/      /'
    FAIL=$((FAIL+1)); FAILED_NAMES+=("$label(path-leak)"); return
  fi
  if sed -n 's/^- 工作目录：//p' "$d/log.md" 2>/dev/null | grep -qE '^[A-Za-z]:'; then
    echo "    ✘ log.md 的「工作目录」是盘符绝对路径（不可移植）——"
    echo "      应走 scripts/mmr.R 的 mmr_portable_path()"
    FAIL=$((FAIL+1)); FAILED_NAMES+=("$label(abs-run-dir)"); return
  fi

  local NT NF
  NT=$(ls -1 "$d/tables" 2>/dev/null | wc -l | tr -d ' ')
  NF=$(ls -1 "$d/figs"   2>/dev/null | wc -l | tr -d ' ')
  grep -v -E "Setting LC_|^During startup" "$out/console.txt" 2>/dev/null \
    | grep -E "^\[mmr\]" | sed 's/^/    /'
  echo "    ✓ 通过（tables/ $NT, figs/ $NF）"
  PASS=$((PASS+1))
}

for d in "$CASES_DIR"/*/; do
  name="$(basename "$d")"
  [ -f "$d/script.R" ] || continue
  if [ "${#FILTERS[@]}" -gt 0 ]; then
    hit=0; for f in "${FILTERS[@]}"; do [[ "$name" == *"$f"* ]] && hit=1; done
    [ "$hit" -eq 1 ] || continue
  fi
  recover_one "$d" "$name"
done

# 端到端样例也纳入回归：README 把它当「完整产物」展示，脱管就会漂移成半份
if [ "${#FILTERS[@]}" -eq 0 ] && [ -f "$E2E_DIR/script.R" ]; then
  recover_one "$E2E_DIR/" "e2e-run"
fi

echo "════════════════════════════════════════════════════════════"
echo "范例回归结果：$PASS 通过 / $FAIL 失败"
[ "$FAIL" -gt 0 ] && { printf '失败：%s\n' "${FAILED_NAMES[*]}"; exit 1; }
exit 0
