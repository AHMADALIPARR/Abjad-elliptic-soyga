# SPDX-License-Identifier: AGPL-3.0-only
# SPDX-FileCopyrightText: 2026 The algorithm-cores project contributors
module Algorithms
using Printf
using Sockets

include("abjad.jl")
include("jsonutil.jl")
include("elliptic.jl")
include("soyga.jl")
include("neuro.jl")
include("rpc.jl")

export abjad_sum, abjad_value, AbjadError
export parse_json, json_text, JSONError
export magic_z3, magic_certificate, magic_odd, magic_odd_ok
export disc_int, integral_points, eadd, emul, EPoint, EINF, DomainError2
export square_sums, square_of_squares
export soyga_table, soyga_margin, soyga_rule_holds, letter_counts, top_row, from_north
export verse_step, reeds_step, SOYGA_LETTERS
export tokenize, build_index, search_index, neuro_dispatch, regex_hit, Corpus
export serve_abjad, serve_neuro, abjad_call, neuro_call
end
