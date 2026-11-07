# SPDX-License-Identifier: AGPL-3.0-only
# SPDX-FileCopyrightText: 2026 The algorithm-cores project contributors
# Exact integer elliptic helpers.
# magic_z3 is the NeuroRegex / inflection-point square M(i,j)=(i+j, j) mod 3.
# magic_odd is the BQN square G(r,c)=(c+r, c+2r) mod n for odd n.
# Neither is a magic square of integer squares. Curve enumeration is exhaustive
# only inside the stated bound; it is not a determination of the Mordell–Weil group.

struct DomainError2 <: Exception
    msg::String
end

function magic_z3()
    g = Array{Tuple{Int,Int}}(undef, 3, 3)
    for i in 0:2, j in 0:2
        g[i+1, j+1] = (mod(i + j, 3), j)
    end
    g
end

function magic_certificate(g::AbstractMatrix)
    size(g) == (3, 3) || return false
    cells = Tuple{Int,Int}[]
    for i in 1:3, j in 1:3
        c = g[i, j]
        c isa Tuple{Int,Int} || return false
        push!(cells, (mod(c[1], 3), mod(c[2], 3)))
    end
    length(unique(cells)) == 9 || return false
    lines = Any[
        [g[i, j] for j in 1:3] for i in 1:3
    ]
    append!(lines, [[g[i, j] for i in 1:3] for j in 1:3])
    push!(lines, [g[i, i] for i in 1:3])
    push!(lines, [g[i, 4-i] for i in 1:3])
    for line in lines
        sx = mod(sum(c[1] for c in line), 3)
        sy = mod(sum(c[2] for c in line), 3)
        (sx == 0 && sy == 0) || return false
    end
    true
end

function magic_odd(n::Integer)
    n > 0 && isodd(n) && n <= 401 || throw(DomainError2("odd n in 1..401 required"))
    g = Array{Tuple{Int,Int}}(undef, n, n)
    for r in 0:n-1, c in 0:n-1
        g[r+1, c+1] = (mod(c + r, n), mod(c + 2r, n))
    end
    g
end

function magic_odd_ok(n::Integer)
    g = magic_odd(n)
    flat = vec(g)
    length(unique(flat)) == n * n || return false
    z(xs) = (mod(sum(p[1] for p in xs), n), mod(sum(p[2] for p in xs), n)) == (0, 0)
    for r in 1:n
        z(g[r, :]) || return false
        z(g[:, r]) || return false
    end
    z([g[i, i] for i in 1:n]) && z([g[i, n+1-i] for i in 1:n])
end

function disc_int(a::Integer, b::Integer)
    BigInt(4) * BigInt(a)^3 + BigInt(27) * BigInt(b)^2
end

function integral_points(a::Integer, b::Integer, bound::Integer)
    (0 <= bound <= 10000) || throw(DomainError2("bound out of range"))
    disc_int(a, b) == 0 && throw(DomainError2("singular curve"))
    pts = Tuple{BigInt,BigInt}[]
    A = BigInt(a); B = BigInt(b); Bnd = BigInt(bound)
    for x in -Bnd:Bnd
        v = x^3 + A * x + B
        v < 0 && continue
        r = isqrt(v)
        r^2 == v || continue
        r <= Bnd || continue
        if r == 0
            push!(pts, (x, BigInt(0)))
        else
            push!(pts, (x, r))
            push!(pts, (x, -r))
        end
    end
    pts
end

struct EPoint
    inf::Bool
    x::BigInt
    y::BigInt
end
const EINF = EPoint(true, zero(BigInt), zero(BigInt))

import Base: ==
==(u::EPoint, v::EPoint) = u.inf == v.inf && (u.inf || (u.x == v.x && u.y == v.y))

function _mod(a, p)
    mod(BigInt(a), BigInt(p))
end

function eadd(p::Integer, a::Integer, u::EPoint, v::EPoint)
    p > 3 || throw(DomainError2("prime field must be > 3"))
    u.inf && return v
    v.inf && return u
    if _mod(u.x, p) == _mod(v.x, p) && _mod(u.y + v.y, p) == 0
        return EINF
    end
    same = _mod(u.x, p) == _mod(v.x, p) && _mod(u.y, p) == _mod(v.y, p)
    if same
        num = _mod(3 * u.x * u.x + a, p)
        den = _mod(2 * u.y, p)
    else
        num = _mod(v.y - u.y, p)
        den = _mod(v.x - u.x, p)
    end
    slope = _mod(num * invmod(den, BigInt(p)), p)
    x3 = _mod(slope * slope - u.x - v.x, p)
    y3 = _mod(slope * (u.x - x3) - u.y, p)
    EPoint(false, x3, y3)
end

function emul(p::Integer, a::Integer, k::Integer, pt::EPoint)
    k == 0 && return EINF
    k < 0 && return emul(p, a, -k, EPoint(false, pt.x, _mod(-pt.y, p)))
    half = emul(p, a, k >> 1, pt)
    dbl = eadd(p, a, half, half)
    iseven(k) ? dbl : eadd(p, a, dbl, pt)
end

function square_sums(m::AbstractMatrix{<:Integer})
    size(m) == (3, 3) || return false
    rows = [sum(m[i, :]) for i in 1:3]
    cols = [sum(m[:, j]) for j in 1:3]
    diag = sum(m[i, i] for i in 1:3)
    anti = sum(m[i, 4-i] for i in 1:3)
    allequal(vcat(rows, cols, diag, anti))
end

function _is_pos_square(n::Integer)
    n > 0 || return false
    r = isqrt(BigInt(n))
    r * r == n
end

function square_of_squares(m::AbstractMatrix{<:Integer})
    square_sums(m) || return false
    vals = vec(m)
    all(_is_pos_square, vals) && allunique(vals)
end
