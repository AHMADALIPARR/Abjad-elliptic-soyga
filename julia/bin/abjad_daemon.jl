# SPDX-License-Identifier: AGPL-3.0-only
# SPDX-FileCopyrightText: 2026 The algorithm-cores project contributors
using Algorithms
length(ARGS) == 1 || error("usage: abjad_daemon.jl SOCKET")
timeout_s = parse(Float64, get(ENV, "ABJAD_TIMEOUT_MS", "5000")) / 1000
max_requests = parse(Int, get(ENV, "ABJAD_MAX_REQUESTS", "1024"))
serve_abjad(ARGS[1]; timeout_s, max_requests)
