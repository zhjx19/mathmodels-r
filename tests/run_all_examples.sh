#!/usr/bin/env bash
# ============================================================================
# run_all_examples.sh —— 回归测试：跑通 examples/cases/ 下全部范例
#
# 用法:
#   bash tests/run_all_examples.sh            # 跑全部
#   bash tests/run_all_examples.sh 03 05      # 只跑名字含 03 或 05 的
#
# 做两件事：
#   1. 用 scripts/run_r.sh 逐个运行范例脚本，任一非 0 退出码即记失败；
#   2. 把产物（log.md / tables/ / figs/ / meta.txt / sessionInfo.txt）回收到
#      各案例目录，使 examples/cases/NN-xxx/ 自带一份可核对的真实产物。
#
# 为什么产物要回收进案例目录：范例的价值一半在"长什么样"。读者（和 AI）
# 需要看到真实的表格列名、图的实际观感，而不是一段声称能跑的代码。
#
# 环境变量:
#   MMR_EXAMPLE_SCRATCH  临时 run 目录根（默认 <skill>/.example-runs）
# ============================================================================
set -uo pipefail

SKILL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CASES_DIR="$SKILL_ROOT/examples/cases"
SCRATCH="${MMR_EXAMPLE_SCRATCH:-$SKILL_ROOT/.example-runs}"
STAMP="$(date +%Y%m%d-%H%M%S)"

[ -d "$CASES_DIR" ] || { echo "✘ 找不到 $CASES_DIR" >&2; exit 2; }

FILTERS=("$@")
PASS=0; FAIL=0; FAILED_NAMES=()

for d in "$CASES_DIR"/*/; do
  name="$(basename "$d")"
  [ -f "$d/script.R" ] || continue
  if [ "${#FILTERS[@]}" -gt 0 ]; then
    hit=0; for f in "${FILTERS[@]}"; do [[ "$name" == *"$f"* ]] && hit=1; done
    [ "$hit" -eq 1 ] || continue
  fi

  out="$SCRATCH/$STAMP/$name"
  mkdir -p "$out"
  echo "────────────────────────────────────────────────────────────"
  echo "▶ 案例 $name"

  if bash "$SKILL_ROOT/scripts/run_r.sh" "$d/script.R" "$out" > "$out/_run.log" 2>&1; then
    # 回收产物
    for f in log.md meta.txt sessionInfo.txt console.txt; do
      [ -f "$out/$f" ] && cp -f "$out/$f" "$d/$f"
    done
    for sub in tables figs; do
      if [ -d "$out/$sub" ]; then
        mkdir -p "$d/$sub"
        cp -f "$out/$sub"/* "$d/$sub/" 2>/dev/null
      fi
    done
    NT=$(ls -1 "$d/tables" 2>/dev/null | wc -l | tr -d ' ')
    NF=$(ls -1 "$d/figs"   2>/dev/null | wc -l | tr -d ' ')
    grep -v -E "Setting LC_|^During startup" "$out/console.txt" 2>/dev/null \
      | grep -E "^\[mmr\]" | sed 's/^/    /'
    echo "    ✓ 通过（tables/ $NT, figs/ $NF）"
    PASS=$((PASS+1))
  else
    echo "    ✘ 失败，控制台尾部："
    grep -v -E "Setting LC_|^During startup" "$out/console.txt" 2>/dev/null \
      | tail -15 | sed 's/^/      /'
    FAIL=$((FAIL+1)); FAILED_NAMES+=("$name")
  fi
done

echo "════════════════════════════════════════════════════════════"
echo "范例回归结果：$PASS 通过 / $FAIL 失败"
[ "$FAIL" -gt 0 ] && { printf '失败：%s\n' "${FAILED_NAMES[*]}"; exit 1; }
exit 0
