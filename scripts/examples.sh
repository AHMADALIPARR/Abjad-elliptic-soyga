#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# SPDX-FileCopyrightText: 2026 The algorithm-cores project contributors
set -eu
root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
cd "$root"
out="$root/examples/e2e.txt"
mkdir -p "$root/examples"
{
  echo "date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "-- bqn demo --"
  bqn mirror-bqn/demo.bqn
  echo "-- abjad local rpc --"
  sock="/tmp/abjad-example-$$.sock"
  rm -f "$sock"
  ./abjad-wstp/abjad-daemon local "$sock" >/tmp/abjad-example.log 2>&1 &
  pid=$!
  i=0
  while [ ! -S "$sock" ]; do
    i=$((i+1))
    [ "$i" -lt 50 ] || exit 1
    sleep 0.05
  done
  ./abjad-wstp/abjad-client "$sock" 'الله'
  ./abjad-wstp/abjad-client "$sock" 'محمد'
  kill "$pid"
  wait "$pid" 2>/dev/null || true
  rm -f "$sock"
  echo "-- soyga first row --"
  julia --project=julia --startup-file=no -e 'using Algorithms; println(String(soyga_table("nisram")[1]))'
  echo "-- neuro dispatch --"
  julia --project=julia --startup-file=no -e 'using Algorithms; println(neuro_dispatch("magic", "{}"))'
} > "$out"
echo "wrote $out"
