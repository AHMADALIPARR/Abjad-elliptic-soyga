# SPDX-License-Identifier: AGPL-3.0-only
# SPDX-FileCopyrightText: 2026 The algorithm-cores project contributors
# Executable Soyga table. This is not an Agda proof.
# Alphabet: a b c d e f g h i k l m n o p q r s t u x y z.
# Manuscripts sometimes write the 20th letter as v; this module follows the
# starter and Reeds's u. j and w are absent. Addition is exact mod 23.

const SOYGA_LETTERS = collect("abcdefghiklmnopqrstuxyz")
const SOYGA_POS = Dict(c => i - 1 for (i, c) in enumerate(SOYGA_LETTERS))
const VERSE_VALUE = Dict(
    'a'=>3, 'b'=>3, 'c'=>27, 'd'=>29, 'e'=>15, 'f'=>3, 'g'=>7, 'h'=>6, 'i'=>15,
    'k'=>16, 'l'=>21, 'm'=>23, 'n'=>15, 'o'=>9, 'p'=>14, 'q'=>21, 'r'=>12,
    's'=>9, 't'=>9, 'u'=>16, 'x'=>16, 'y'=>16, 'z'=>3,
)
const REEDS_STEP = Dict(
    'a'=>2, 'b'=>2, 'c'=>3, 'd'=>5, 'e'=>14, 'f'=>2, 'g'=>6, 'h'=>5, 'i'=>14,
    'k'=>15, 'l'=>20, 'm'=>22, 'n'=>14, 'o'=>8, 'p'=>13, 'q'=>20, 'r'=>11,
    's'=>8, 't'=>8, 'u'=>15, 'x'=>15, 'y'=>15, 'z'=>2,
)

verse_step(c::Char) = mod(VERSE_VALUE[c] - 1, 23)
reeds_step(c::Char) = REEDS_STEP[c]

function advance_letter(k::Integer, c::Char)
    SOYGA_LETTERS[mod(SOYGA_POS[c] + k, 23) + 1]
end

interior_cell(north::Char, west::Char) = advance_letter(verse_step(west), north)
interior_reeds(north::Char, west::Char) = advance_letter(reeds_step(west), north)

function top_row(west::Char, len::Integer=36)
    row = Vector{Char}(undef, len)
    row[1] = west
    for i in 2:len
        row[i] = interior_cell(row[i-1], row[i-1])
    end
    row
end

function from_north(west::Char, norths)
    row = Vector{Char}(undef, length(norths) + 1)
    row[1] = west
    w = west
    for (i, north) in enumerate(norths)
        w = interior_cell(north, w)
        row[i+1] = w
    end
    row
end

function soyga_margin(seed::AbstractString)
    ncodeunits(seed) == 6 && length(seed) == 6 || throw(DomainError2("seed must be 6 letters"))
    all(c -> haskey(SOYGA_POS, c), seed) || throw(DomainError2("seed outside the 23-letter alphabet"))
    block = String(seed) * reverse(String(seed))
    block ^ 3
end

function soyga_table(seed::AbstractString)
    margin = soyga_margin(seed)
    rows = Vector{Vector{Char}}(undef, 36)
    rows[1] = top_row(margin[1], 36)
    for r in 2:36
        rows[r] = from_north(margin[r], @view rows[r-1][2:end])
    end
    rows
end

function soyga_rule_holds(seed::AbstractString, rows=soyga_table(seed))
    margin = soyga_margin(seed)
    length(rows) == 36 || return false
    for r in 1:36
        length(rows[r]) == 36 || return false
        rows[r][1] == margin[r] || return false
        all(c -> haskey(SOYGA_POS, c), rows[r]) || return false
    end
    for c in 2:36
        rows[1][c] == interior_reeds(rows[1][c-1], rows[1][c-1]) || return false
    end
    for r in 2:36, c in 2:36
        rows[r][c] == interior_reeds(rows[r-1][c], rows[r][c-1]) || return false
    end
    true
end

function letter_counts(rows)
    counts = Dict(c => 0 for c in SOYGA_LETTERS)
    for row in rows, c in row
        counts[c] += 1
    end
    counts
end
