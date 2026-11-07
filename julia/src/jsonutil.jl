# SPDX-License-Identifier: AGPL-3.0-only
# SPDX-FileCopyrightText: 2026 The algorithm-cores project contributors
struct JSONError <: Exception
    msg::String
end

function _skip!(s, i)
    n = ncodeunits(s)
    while i[] <= n
        b = codeunit(s, i[])
        (b == UInt8(' ') || b == UInt8('\t') || b == UInt8('\n') || b == UInt8('\r')) || break
        i[] += 1
    end
end

function _parse_string!(s, i)
    codeunit(s, i[]) == UInt8('"') || throw(JSONError("string"))
    i[] += 1
    out = UInt8[]
    n = ncodeunits(s)
    while i[] <= n
        b = codeunit(s, i[])
        if b == UInt8('"')
            i[] += 1
            return String(out)
        elseif b == UInt8('\\')
            i[] += 1
            i[] > n && throw(JSONError("truncated escape"))
            e = codeunit(s, i[])
            if e == UInt8('u')
                i[] + 4 > n && throw(JSONError("bad unicode escape"))
                hex = s[i[]+1:i[]+4]
                cp = tryparse(UInt32, hex, base=16)
                cp === nothing && throw(JSONError("bad unicode escape"))
                i[] += 5
                if 0xd800 <= cp <= 0xdbff
                    i[] + 5 <= n || throw(JSONError("lone surrogate"))
                    codeunit(s, i[]) == UInt8('\\') && codeunit(s, i[]+1) == UInt8('u') || throw(JSONError("lone surrogate"))
                    hex2 = s[i[]+2:i[]+5]
                    lo = tryparse(UInt32, hex2, base=16)
                    (lo !== nothing && 0xdc00 <= lo <= 0xdfff) || throw(JSONError("lone surrogate"))
                    i[] += 6
                    u = 0x10000 + ((cp - 0xd800) << 10) + (lo - 0xdc00)
                    append!(out, transcode(UInt8, string(Char(u))))
                elseif 0xdc00 <= cp <= 0xdfff
                    throw(JSONError("lone surrogate"))
                else
                    append!(out, transcode(UInt8, string(Char(cp))))
                end
            else
                ch = e == UInt8('"') ? UInt8('"') :
                     e == UInt8('\\') ? UInt8('\\') :
                     e == UInt8('/') ? UInt8('/') :
                     e == UInt8('b') ? UInt8('\b') :
                     e == UInt8('f') ? UInt8('\f') :
                     e == UInt8('n') ? UInt8('\n') :
                     e == UInt8('r') ? UInt8('\r') :
                     e == UInt8('t') ? UInt8('\t') : 0xff
                ch == 0xff && throw(JSONError("bad escape"))
                push!(out, ch)
                i[] += 1
            end
        elseif b < 0x20
            throw(JSONError("raw control"))
        else
            ch = s[i[]]
            append!(out, transcode(UInt8, string(ch)))
            i[] = nextind(s, i[])
        end
    end
    throw(JSONError("unterminated string"))
end

function _parse_number!(s, i)
    start = i[]
    n = ncodeunits(s)
    if i[] <= n && codeunit(s, i[]) == UInt8('-')
        i[] += 1
    end
    i[] > n && throw(JSONError("bad number"))
    codeunit(s, i[]) in UInt8('0'):UInt8('9') || throw(JSONError("bad number"))
    if codeunit(s, i[]) == UInt8('0')
        i[] += 1
    else
        while i[] <= n && codeunit(s, i[]) in UInt8('0'):UInt8('9')
            i[] += 1
        end
    end
    float = false
    if i[] <= n && codeunit(s, i[]) == UInt8('.')
        float = true
        i[] += 1
        i[] <= n && codeunit(s, i[]) in UInt8('0'):UInt8('9') || throw(JSONError("bad number"))
        while i[] <= n && codeunit(s, i[]) in UInt8('0'):UInt8('9')
            i[] += 1
        end
    end
    if i[] <= n && codeunit(s, i[]) in (UInt8('e'), UInt8('E'))
        float = true
        i[] += 1
        if i[] <= n && codeunit(s, i[]) in (UInt8('+'), UInt8('-'))
            i[] += 1
        end
        i[] <= n && codeunit(s, i[]) in UInt8('0'):UInt8('9') || throw(JSONError("bad number"))
        while i[] <= n && codeunit(s, i[]) in UInt8('0'):UInt8('9')
            i[] += 1
        end
    end
    tok = s[start:prevind(s, i[])]
    if !float
        v = tryparse(Int64, tok)
        return v === nothing ? parse(BigInt, tok) : v
    end
    v = tryparse(Float64, tok)
    v === nothing && throw(JSONError("bad number"))
    return v
end

function _parse_value!(s, i)
    _skip!(s, i)
    i[] > ncodeunits(s) && throw(JSONError("truncated"))
    b = codeunit(s, i[])
    if b == UInt8('"')
        return _parse_string!(s, i)
    elseif b == UInt8('{')
        i[] += 1
        obj = Dict{String,Any}()
        _skip!(s, i)
        if i[] <= ncodeunits(s) && codeunit(s, i[]) == UInt8('}')
            i[] += 1
            return obj
        end
        while true
            _skip!(s, i)
            key = _parse_string!(s, i)
            haskey(obj, key) && throw(JSONError("duplicate key"))
            _skip!(s, i)
            i[] <= ncodeunits(s) && codeunit(s, i[]) == UInt8(':') || throw(JSONError("expected colon"))
            i[] += 1
            obj[key] = _parse_value!(s, i)
            _skip!(s, i)
            i[] <= ncodeunits(s) || throw(JSONError("truncated object"))
            c = codeunit(s, i[])
            if c == UInt8(',')
                i[] += 1
                continue
            elseif c == UInt8('}')
                i[] += 1
                return obj
            else
                throw(JSONError("bad object"))
            end
        end
    elseif b == UInt8('[')
        i[] += 1
        arr = Any[]
        _skip!(s, i)
        if i[] <= ncodeunits(s) && codeunit(s, i[]) == UInt8(']')
            i[] += 1
            return arr
        end
        while true
            push!(arr, _parse_value!(s, i))
            _skip!(s, i)
            i[] <= ncodeunits(s) || throw(JSONError("truncated array"))
            c = codeunit(s, i[])
            if c == UInt8(',')
                i[] += 1
                continue
            elseif c == UInt8(']')
                i[] += 1
                return arr
            else
                throw(JSONError("bad array"))
            end
        end
    elseif b == UInt8('t')
        i[] + 3 <= ncodeunits(s) && s[i[]:i[]+3] == "true" || throw(JSONError("bad literal"))
        i[] += 4
        return true
    elseif b == UInt8('f')
        i[] + 4 <= ncodeunits(s) && s[i[]:i[]+4] == "false" || throw(JSONError("bad literal"))
        i[] += 5
        return false
    elseif b == UInt8('n')
        i[] + 3 <= ncodeunits(s) && s[i[]:i[]+3] == "null" || throw(JSONError("bad literal"))
        i[] += 4
        return nothing
    else
        return _parse_number!(s, i)
    end
end

function parse_json(text::AbstractString)
    i = Ref(1)
    v = _parse_value!(String(text), i)
    _skip!(String(text), i)
    i[] == ncodeunits(String(text)) + 1 || throw(JSONError("trailing junk"))
    return v
end

function write_json(io::IO, x)
    if x === nothing
        print(io, "null")
    elseif x isa Bool
        print(io, x ? "true" : "false")
    elseif x isa Integer && !(x isa Bool)
        print(io, x)
    elseif x isa AbstractFloat
        isfinite(x) || throw(JSONError("non-finite"))
        s = @sprintf("%.17g", Float64(x))
        occursin(r"[.eE]", s) || (s *= ".0")
        print(io, s)
    elseif x isa AbstractString
        print(io, '"')
        for c in x
            if c == '"'
                print(io, "\\\"")
            elseif c == '\\'
                print(io, "\\\\")
            elseif c == '\b'
                print(io, "\\b")
            elseif c == '\f'
                print(io, "\\f")
            elseif c == '\n'
                print(io, "\\n")
            elseif c == '\r'
                print(io, "\\r")
            elseif c == '\t'
                print(io, "\\t")
            elseif UInt32(c) < 0x20
                @printf(io, "\\u%04x", UInt32(c))
            else
                print(io, c)
            end
        end
        print(io, '"')
    elseif x isa AbstractDict
        print(io, '{')
        first = true
        for k in sort!(collect(String.(keys(x))))
            first || print(io, ',')
            first = false
            write_json(io, k)
            print(io, ':')
            write_json(io, x[k])
        end
        print(io, '}')
    elseif x isa AbstractVector
        print(io, '[')
        for (i, v) in enumerate(x)
            i == 1 || print(io, ',')
            write_json(io, v)
        end
        print(io, ']')
    else
        throw(JSONError("unsupported value $(typeof(x))"))
    end
end

json_text(x) = sprint(io -> write_json(io, x))
