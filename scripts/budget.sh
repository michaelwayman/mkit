#!/usr/bin/env bash
# Prompt budget per plugin: each SKILL.md <= SKILL_MAX bytes, a plugin's prompt text <= TOTAL_MAX.
set -u
cd "$(dirname "$0")/.."
SKILL_MAX=${SKILL_MAX:-2800}; FRAME_MAX=${FRAME_MAX:-5500}; TOTAL_MAX=${TOTAL_MAX:-25000}
rc=0
for plugin in . mbuild; do
  total=0
  for f in "$plugin"/skills/*/SKILL.md; do
    n=$(wc -c < "$f"); total=$((total+n))
    max=$SKILL_MAX; case "$f" in */frame/*) max=$FRAME_MAX;; esac
    flag=""; [ "$n" -gt "$max" ] && { flag=" OVER"; rc=1; }
    printf '%6d  ~%4d tok  %s%s\n' "$n" $((n/4)) "$f" "$flag"
  done
  for f in "$plugin"/templates/*; do [ -f "$f" ] && total=$((total+$(wc -c < "$f"))); done
  printf '%6d  ~%4d tok  total %s, max %d\n' "$total" $((total/4)) "$plugin" "$TOTAL_MAX"
  [ "$total" -gt "$TOTAL_MAX" ] && rc=1
done
exit $rc
