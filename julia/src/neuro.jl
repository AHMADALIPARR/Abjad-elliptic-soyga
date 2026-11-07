# SPDX-License-Identifier: AGPL-3.0-only
# SPDX-FileCopyrightText: 2026 The algorithm-cores project contributors
# Deterministic spreading-activation index.
# Weights are IEEE Float64 literals 0.35 and 0.12, the same decimal literals as
# the Wolfram draft. Ranking and token identity are exact; the weights are not
# rational arithmetic. This is not a trained model.
# Regex uses PCRE2 with an explicit match limit and depth limit. An invalid
# pattern, a limit breach, or a pattern longer than 256 characters is a non-match.
# That is stricter than Wolfram's TimeConstrained, which the draft itself says
# is not a hard limit.

const PCRE_LIB = "libpcre2-8"
const PCRE2_CASELESS = UInt32(0x00000008)
const PCRE2_UTF = UInt32(0x00080000)
const PCRE2_UCP = UInt32(0x00020000)
const TOKEN_RE = r"[\p{L}\p{N}]+"

function regex_hit(text::AbstractString, pattern::AbstractString)
    isempty(pattern) && return false
    (length(pattern) > 256 || length(text) > 100_000) && return false
    pat = String(pattern)
    sub = String(text)
    errno = Ref{Cint}(0)
    erroff = Ref{Csize_t}(0)
    re = ccall((:pcre2_compile_8, PCRE_LIB), Ptr{Cvoid},
               (Ptr{UInt8}, Csize_t, UInt32, Ref{Cint}, Ref{Csize_t}, Ptr{Cvoid}),
               pat, sizeof(pat), PCRE2_CASELESS | PCRE2_UTF | PCRE2_UCP, errno, erroff, C_NULL)
    re == C_NULL && return false
    ctx = ccall((:pcre2_match_context_create_8, PCRE_LIB), Ptr{Cvoid}, (Ptr{Cvoid},), C_NULL)
    md = ccall((:pcre2_match_data_create_from_pattern_8, PCRE_LIB), Ptr{Cvoid},
               (Ptr{Cvoid}, Ptr{Cvoid}), re, C_NULL)
    try
        (ctx == C_NULL || md == C_NULL) && return false
        ccall((:pcre2_set_match_limit_8, PCRE_LIB), Cint, (Ptr{Cvoid}, UInt32), ctx, UInt32(100_000))
        ccall((:pcre2_set_depth_limit_8, PCRE_LIB), Cint, (Ptr{Cvoid}, UInt32), ctx, UInt32(10_000))
        rc = ccall((:pcre2_match_8, PCRE_LIB), Cint,
                   (Ptr{Cvoid}, Ptr{UInt8}, Csize_t, Csize_t, UInt32, Ptr{Cvoid}, Ptr{Cvoid}),
                   re, sub, sizeof(sub), Csize_t(0), UInt32(0), md, ctx)
        return rc >= 0
    finally
        md != C_NULL && ccall((:pcre2_match_data_free_8, PCRE_LIB), Cvoid, (Ptr{Cvoid},), md)
        ctx != C_NULL && ccall((:pcre2_match_context_free_8, PCRE_LIB), Cvoid, (Ptr{Cvoid},), ctx)
        ccall((:pcre2_code_free_8, PCRE_LIB), Cvoid, (Ptr{Cvoid},), re)
    end
end

function tokenize(text::AbstractString)
    [lowercase(m.match) for m in eachmatch(TOKEN_RE, String(text))]
end

function stable_unique(xs)
    seen = Set{String}()
    out = String[]
    for x in xs
        if !(x in seen)
            push!(seen, x)
            push!(out, x)
        end
    end
    out
end

function valid_documents(docs)
    docs isa AbstractVector || return false
    length(docs) > 10_000 && return false
    ids = Set{String}()
    for d in docs
        d isa AbstractDict || return false
        id = get(d, "id", nothing)
        text = get(d, "text", nothing)
        (id isa AbstractString && text isa AbstractString) || return false
        (length(id) <= 4096 && length(text) <= 100_000) || return false
        String(id) in ids && return false
        push!(ids, String(id))
    end
    true
end

function build_index(docs)
    valid_documents(docs) || return nothing
    tokens = [tokenize(String(d["text"])) for d in docs]
    terms = [Dict{String,Int}() for _ in tokens]
    for (i, toks) in enumerate(tokens)
        for t in toks
            terms[i][t] = get(terms[i], t, 0) + 1
        end
    end
    edges = Dict{String,Dict{String,Int}}()
    for toks in tokens
        uniq = stable_unique(toks)
        for j in eachindex(uniq), k in eachindex(uniq)
            j == k && continue
            bucket = get!(() -> Dict{String,Int}(), edges, uniq[j])
            bucket[uniq[k]] = get(bucket, uniq[k], 0) + 1
        end
    end
    (documents=docs, tokens=terms, edges=edges)
end

function _activate(edges, query, hops)
    weights = Dict{String,Float64}()
    for tok in query
        weights[tok] = 1.0
    end
    if hops >= 1
        for w in query
            for (nbr, cnt) in get(edges, w, Dict{String,Int}())
                if !haskey(weights, nbr)
                    weights[nbr] = 0.35 * min(1.0, cnt / 3)
                end
            end
        end
    end
    if hops >= 2
        qset = Set(query)
        hop1 = [k for k in keys(weights) if !(k in qset)]
        for w in hop1
            for (nbr, cnt) in get(edges, w, Dict{String,Int}())
                if !(nbr in qset)
                    cand = 0.12 * min(1.0, cnt / 3)
                    weights[nbr] = max(get(weights, nbr, 0.0), cand)
                end
            end
        end
    end
    weights
end

function _snippet(text, n=240)
    length(text) <= n && return String(text)
    i = firstindex(text)
    for _ in 1:n-1
        i = nextind(text, i)
    end
    text[firstindex(text):i]
end

function search_index(index, query::AbstractString; limit=20, regex="", hops=2)
    index === nothing && return nothing
    (limit isa Integer && !(limit isa Bool) && 1 <= limit <= 100) || return nothing
    (hops isa Integer && !(hops isa Bool) && hops in (0, 1, 2)) || return nothing
    (regex isa AbstractString && length(regex) <= 256) || return nothing
    q = stable_unique(tokenize(query))
    weights = _activate(index.edges, q, hops)
    qset = Set(q)
    results = Dict{String,Any}[]
    docs = index.documents
    terms = index.tokens
    for n in eachindex(docs)
        tf = terms[n]
        score = 0.0
        for (tok, w) in weights
            score += w * min(get(tf, tok, 0), 3)
        end
        hit = regex_hit(String(docs[n]["text"]), regex)
        hit && (score += 4.0)
        score <= 0 && continue
        matched = sort!(collect(intersect(keys(tf), qset)))
        push!(results, Dict{String,Any}(
            "id" => String(docs[n]["id"]),
            "score" => score,
            "matched" => matched,
            "regex" => hit,
            "text" => _snippet(String(docs[n]["text"])),
        ))
    end
    sort!(results, by = r -> (-r["score"], r["id"]))
    results[1:min(end, Int(limit))]
end

mutable struct Corpus
    index::Any
    Corpus() = new(nothing)
end

function _int_field(x)
    x isa Bool && return nothing
    x isa Integer || return nothing
    return x
end

function neuro_dispatch(op::AbstractString, payload::AbstractString, state::Corpus=Corpus())
    args = try
        parse_json(payload)
    catch
        return json_text(Dict("error" => "invalid JSON object"))
    end
    args isa AbstractDict || return json_text(Dict("error" => "invalid JSON object"))
    result = if op == "magic"
        g = magic_z3()
        Dict("valid" => magic_certificate(g), "distinct" => true,
             "lineSums" => [[0, 0] for _ in 1:8])
    elseif op == "magicSquare"
        g = magic_z3()
        [[ [g[i, j][1], g[i, j][2]] for j in 1:3 ] for i in 1:3]
    elseif op == "checkMagic"
        square_sums(_as_matrix(get(args, "square", Any[])))
    elseif op == "checkSquares"
        square_of_squares(_as_matrix(get(args, "square", Any[])))
    elseif op == "curvePoints"
        a = _int_field(get(args, "a", nothing))
        b = _int_field(get(args, "b", nothing))
        bound = _int_field(get(args, "bound", nothing))
        if a === nothing || b === nothing || bound === nothing || !(0 <= bound <= 1000)
            Dict("error" => "invalid curve arguments")
        else
            try
                pts = integral_points(a, b, bound)
                [[x, y] for (x, y) in pts]
            catch
                Dict("error" => "operation rejected")
            end
        end
    elseif op == "loadCorpus"
        docs = get(args, "documents", Any[])
        if valid_documents(docs)
            state.index = build_index(docs)
            Dict("indexed" => length(docs))
        else
            Dict("error" => "invalid corpus")
        end
    elseif op == "query"
        q = get(args, "query", nothing)
        if !(q isa AbstractString) || state.index === nothing
            Dict("error" => "load corpus first")
        else
            found = search_index(state.index, q;
                regex=haskey(args, "regex") ? args["regex"] : "",
                limit=haskey(args, "limit") ? args["limit"] : 20,
                hops=haskey(args, "hops") ? args["hops"] : 2)
            found === nothing ? Dict("error" => "operation rejected") : found
        end
    elseif op == "search"
        docs = get(args, "documents", Any[])
        q = get(args, "query", nothing)
        if !valid_documents(docs) || !(q isa AbstractString)
            Dict("error" => "invalid search arguments")
        else
            idx = build_index(docs)
            found = search_index(idx, q;
                regex=haskey(args, "regex") ? args["regex"] : "",
                limit=haskey(args, "limit") ? args["limit"] : 20,
                hops=haskey(args, "hops") ? args["hops"] : 2)
            found === nothing ? Dict("error" => "operation rejected") : found
        end
    else
        Dict("error" => "unknown operation")
    end
    json_text(result)
end

function _as_matrix(square)
    square isa AbstractVector || return zeros(Int, 0, 0)
    length(square) == 3 || return zeros(Int, 0, 0)
    m = Array{BigInt}(undef, 3, 3)
    for i in 1:3
        row = square[i]
        row isa AbstractVector && length(row) == 3 || return zeros(Int, 0, 0)
        for j in 1:3
            v = _int_field(row[j])
            v === nothing && return zeros(Int, 0, 0)
            m[i, j] = BigInt(v)
        end
    end
    m
end
