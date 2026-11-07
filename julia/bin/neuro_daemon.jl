# SPDX-License-Identifier: AGPL-3.0-only
# SPDX-FileCopyrightText: 2026 The algorithm-cores project contributors
using Algorithms
length(ARGS) == 1 || error("usage: neuro_daemon.jl SOCKET")
timeout_s = parse(Float64, get(ENV, "NEURO_TIMEOUT_MS", "5000")) / 1000
serve_neuro(ARGS[1]; timeout_s)
