#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# SPDX-FileCopyrightText: 2026 The algorithm-cores project contributors
set -eu
socket="/tmp/abjad-test-$$.sock"
./abjad-daemon local "$socket" >/dev/null 2>&1 &
pid=$!
trap 'kill "$pid" 2>/dev/null || :; wait "$pid" 2>/dev/null || :; rm -f "$socket"' EXIT HUP INT TERM
attempt=0
while [ ! -S "$socket" ]; do
  attempt=$((attempt+1)); [ "$attempt" -lt 50 ] || exit 1
  sleep 0.05
done
[ "$(./abjad-client "$socket" 'الله')" = 66 ]
[ "$(./abjad-client "$socket" 'محمد')" = 92 ]
[ "$(./abjad-client "$socket" 'أحمد')" = 53 ]
if ./abjad-client "$socket" 'ABC' >/dev/null 2>&1; then echo 'invalid input accepted' >&2; exit 1; fi
printf 'PASS: Arabic examples and invalid-input rejection\n'
