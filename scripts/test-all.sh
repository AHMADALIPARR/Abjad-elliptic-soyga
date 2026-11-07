#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# SPDX-FileCopyrightText: 2026 The algorithm-cores project contributors
set -eu
root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
cd "$root"
echo "== abjad-wstp =="
make -C abjad-wstp test
echo "== elliptic-neuroregex native =="
make -C elliptic-neuroregex test-native
echo "== mirror-bqn =="
bqn mirror-bqn/test.bqn
bqn mirror-bqn/test_more.bqn
echo "== soyga-agda =="
( cd soyga-agda && agda --safe --without-K Soyga.agda )
echo "== julia =="
julia --project=julia --startup-file=no -e 'using Pkg; Pkg.test("Algorithms")'
echo "ALL_SUITES_OK"
