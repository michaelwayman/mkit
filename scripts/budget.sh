#!/usr/bin/env bash
# Prompt budget: each SKILL.md <= SKILL_MAX bytes, the plugin's prompt text <= TOTAL_MAX.
set -u
cd "$(dirname "$0")/.."
SKILL_MAX=${SKILL_MAX:-2800}; TOTAL_MAX=${TOTAL_MAX:-25000}
rc=0; total=0
for f in skills/*/SKILL.md; do
  n=$(wc -c < "$f"); total=$((total+n))
  flag=""; [ "$n" -gt "$SKILL_MAX" ] && { flag=" OVER"; rc=1; }
  printf '%6d  ~%4d tok  %s%s\n' "$n" $((n/4)) "$f" "$flag"
done
for f in templates/*; do total=$((total+$(wc -c < "$f"))); done
printf '%6d  ~%4d tok  total (skills+templates), max %d\n' "$total" $((total/4)) "$TOTAL_MAX"
[ "$total" -gt "$TOTAL_MAX" ] && rc=1
exit $rc
