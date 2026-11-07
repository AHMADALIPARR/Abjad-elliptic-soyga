# SPDX-License-Identifier: AGPL-3.0-only
# SPDX-FileCopyrightText: 2026 The algorithm-cores project contributors
# Exact Eastern abjad kabir. UTF-8 rejection matches the C decoder:
# overlong sequences, surrogates, and code points above U+10FFFF are errors.
# Diacritics, spaces, punctuation, and letters outside the table add nothing.
# A string with no recognized letter is a domain error, not the total 0.

struct AbjadError <: Exception
    code::Int
end

function abjad_value(cp::UInt32)::Int
    if cp == 0x0627 || cp == 0x0622 || cp == 0x0623 || cp == 0x0625 || cp == 0x0671
        return 1
    elseif cp == 0x0628
        return 2
    elseif cp == 0x062c
        return 3
    elseif cp == 0x062f
        return 4
    elseif cp == 0x0647 || cp == 0x0629
        return 5
    elseif cp == 0x0648
        return 6
    elseif cp == 0x0632
        return 7
    elseif cp == 0x062d
        return 8
    elseif cp == 0x0637
        return 9
    elseif cp == 0x064a || cp == 0x0649
        return 10
    elseif cp == 0x0643
        return 20
    elseif cp == 0x0644
        return 30
    elseif cp == 0x0645
        return 40
    elseif cp == 0x0646
        return 50
    elseif cp == 0x0633
        return 60
    elseif cp == 0x0639
        return 70
    elseif cp == 0x0641
        return 80
    elseif cp == 0x0635
        return 90
    elseif cp == 0x0642
        return 100
    elseif cp == 0x0631
        return 200
    elseif cp == 0x0634
        return 300
    elseif cp == 0x062a
        return 400
    elseif cp == 0x062b
        return 500
    elseif cp == 0x062e
        return 600
    elseif cp == 0x0630
        return 700
    elseif cp == 0x0636
        return 800
    elseif cp == 0x0638
        return 900
    elseif cp == 0x063a
        return 1000
    else
        return 0
    end
end

function abjad_sum(bytes::AbstractVector{UInt8})
    s = bytes
    n = length(s)
    i = 1
    sum = UInt64(0)
    matched = false
    while i <= n
        b = s[i]
        if b < 0x80
            c = UInt32(b); k = 1
        elseif 0xc2 <= b <= 0xdf
            c = UInt32(b & 0x1f); k = 2
        elseif 0xe0 <= b <= 0xef
            c = UInt32(b & 0x0f); k = 3
        elseif 0xf0 <= b <= 0xf4
            c = UInt32(b & 0x07); k = 4
        else
            throw(AbjadError(-1))
        end
        if i + k - 1 > n
            throw(AbjadError(-1))
        end
        for j in 1:k-1
            q = s[i+j]
            (q & 0xc0) == 0x80 || throw(AbjadError(-1))
            c = (c << 6) | UInt32(q & 0x3f)
        end
        if (k == 2 && c < 0x80) || (k == 3 && c < 0x800) || (k == 4 && c < 0x10000) ||
           (0xd800 <= c <= 0xdfff) || c > 0x10ffff
            throw(AbjadError(-1))
        end
        v = abjad_value(c)
        if v != 0
            sum += UInt64(v)
            matched = true
        end
        i += k
    end
    matched || throw(AbjadError(-2))
    return sum
end

abjad_sum(s::AbstractString) = abjad_sum(codeunits(s))
