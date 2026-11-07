# SPDX-License-Identifier: AGPL-3.0-only
# SPDX-FileCopyrightText: 2026 The algorithm-cores project contributors
using Algorithms
using Sockets
using Test

const ROOT = normpath(joinpath(@__DIR__, "..", ".."))

@testset "JSON" begin
    @test parse_json("{\"a\":1,\"b\":[true,false,null]}") == Dict("a"=>1, "b"=>Any[true, false, nothing])
    @test parse_json("\"\\u0627\"") == "ا"
    pair = parse_json("\"\\uD800\\uDC00\"")
    @test pair == string(Char(0x10000))
    @test parse_json("1") isa Int
    @test parse_json("1.5") isa Float64
    @test_throws JSONError parse_json("{\"a\":1,\"a\":2}")
    @test_throws JSONError parse_json("{\"a\":1} junk")
    @test_throws JSONError parse_json("\"\\uD800\"")
    @test json_text(Dict("b"=>1, "a"=>2)) == "{\"a\":2,\"b\":1}"
end

@testset "Abjad exact" begin
    @test abjad_sum("الله") == 66
    @test abjad_sum("محمد") == 92
    @test abjad_sum("أحمد") == 53
    @test abjad_sum("علي") == 110
    letters = "ابجدهوزحطيكلمنسعفصقرشتثخذضظغ"
    @test length(letters) == 28
    @test abjad_sum(letters) == 5995
    @test abjad_sum("ة") == 5
    @test abjad_sum("ى") == 10
    @test abjad_sum("آ") == 1
    @test abjad_sum("ٱ") == 1
    @test abjad_sum("ءالله") == 66
    @test abjad_sum("اللَّه") == 66
    @test abjad_sum("A الله!") == 66
    @test_throws AbjadError abjad_sum("")
    @test_throws AbjadError abjad_sum("ABC")
    @test_throws AbjadError abjad_sum("ئ")
    @test_throws AbjadError abjad_sum(UInt8[0xc0, 0xaf])
    @test_throws AbjadError abjad_sum(UInt8[0xed, 0xa0, 0x80])
    @test_throws AbjadError abjad_sum(UInt8[0xe0, 0x80, 0x80])
    @test_throws AbjadError abjad_sum(UInt8[0xf4, 0x90, 0x80, 0x80])
    @test_throws AbjadError abjad_sum(UInt8[0x80])
    rng = UInt32(1)
    for _ in 1:200
        n = Int(rng % UInt32(40))
        rng = rng * UInt32(1664525) + UInt32(1013904223)
        buf = UInt8[]
        for _k in 1:n
            rng = rng * UInt32(1664525) + UInt32(1013904223)
            push!(buf, UInt8(rng >> 24))
        end
        try
            v = abjad_sum(buf)
            @test v > 0
        catch e
            @test e isa AbjadError
            @test e.code in (-1, -2)
        end
    end
end

@testset "Elliptic exact vs group law" begin
    @test disc_int(1, 1) % 97 == 31
    @test disc_int(-3, 2) == 0
    g = magic_z3()
    @test magic_certificate(g)
    @test g[1, 2] == (1, 1)
    @test g[3, 3] == (1, 2)
    pts = integral_points(0, 1, 4)
    @test pts == [(-1, 0), (0, 1), (0, -1), (2, 3), (2, -3)]
    @test_throws DomainError2 integral_points(-3, 2, 5)
    p = EPoint(false, 0, 1)
    two = eadd(5, 0, p, p)
    @test two == EPoint(false, 0, 4)
    @test eadd(5, 0, two, p) == EINF
    @test emul(5, 0, 3, p) == EINF
    field = EPoint[EINF, p, EPoint(false, 0, 4), EPoint(false, 2, 2), EPoint(false, 2, 3), EPoint(false, 4, 0)]
    for u in field
        @test eadd(5, 0, u, EINF) == u
        if !u.inf
            neg = EPoint(false, u.x, mod(-u.y, 5))
            @test eadd(5, 0, u, neg) == EINF
        end
    end
    for u in field, v in field
        @test eadd(5, 0, u, v) == eadd(5, 0, v, u)
        if !v.inf
            neg = EPoint(false, v.x, mod(-v.y, 5))
            @test eadd(5, 0, eadd(5, 0, u, v), neg) == u
        end
    end
    for u in field, v in field, w in field
        @test eadd(5, 0, eadd(5, 0, u, v), w) == eadd(5, 0, u, eadd(5, 0, v, w))
    end
    a = EPoint(false, 3, 6)
    @test emul(97, 2, 5, a) == EINF
    @test eadd(97, 2, a, EPoint(false, 3, 91)) == EINF
    lo = BigInt[8 1 6; 3 5 7; 4 9 2]
    @test square_sums(lo)
    @test !square_of_squares(lo)
    for n in 1:2:31
        @test magic_odd_ok(n)
    end
    @test_throws DomainError2 magic_odd(2)
end

@testset "Soyga recurrence" begin
    for c in SOYGA_LETTERS
        @test verse_step(c) == reeds_step(c)
    end
    @test String(top_row('n', 9)) == "ndizbdizb"
    @test String(from_north('i', ['d', 'i', 'z', 'b'])) == "isrly"
    rows = soyga_table("nisram")
    @test length(rows) == 36
    @test all(r -> length(r) == 36, rows)
    @test soyga_margin("nisram") == ("nisram" * "marsin") ^ 3
    @test soyga_rule_holds("nisram", rows)
    @test startswith(String(rows[1]), "ndizb")
    @test occursin("dizb"^4, String(rows[1]))
    @test occursin("lytr"^2, String(rows[2]))
    @test occursin("xiba"^2, String(rows[3]))
    # Reeds's prose names the 12-letter cycles. The fourth-row cycle produced by
    # the recurrence is qsrnplfdfzly; a secondary transcription says qsrnylfdfzly.
    # The letter counts below are the external check, so the computed cycle is locked.
    @test occursin("qsrnplfdfzly"^2, String(rows[4]))
    @test occursin("ohqtauiducis", String(rows[5]))
    counts = letter_counts(rows)
    @test counts['b'] == 72
    @test counts['r'] == 70
    @test counts['y'] == 70
    @test all(c -> counts[c] > 0, SOYGA_LETTERS)
    mars = soyga_table("marsin")
    mc = letter_counts(mars)
    @test mc['i'] == 82
    @test mc['t'] == 72
    @test mc['y'] == 67
    @test soyga_rule_holds("marsin", mars)
    # A secondary writeup says NISRAM rows 11, 22 and 33 are entirely L.
    # That claim is not true of this alphabet and 1-based indexing, so it is
    # not asserted. The recurrence and the published letter counts are.
    @test_throws DomainError2 soyga_table("jv")
    @test_throws DomainError2 soyga_table("abcdefg")
end

@testset "NeuroRegex semantics" begin
    docs = [
        Dict("id"=>"a", "text"=>"elliptic curve and magic square"),
        Dict("id"=>"b", "text"=>"Arabic abjad numerology"),
    ]
    idx = build_index(docs)
    hop0 = search_index(idx, "elliptic"; hops=0)
    @test hop0[1]["id"] == "a"
    @test hop0[1]["score"] == 1.0
    @test hop0[1]["matched"] == ["elliptic"]
    rx = search_index(idx, ""; regex="magic\\s+square", hops=0)
    @test rx[1]["id"] == "a"
    @test rx[1]["score"] == 4.0
    @test rx[1]["regex"] == true
    cat = build_index([Dict("id"=>"c", "text"=>"cat cat dog")])
    s0 = search_index(cat, "cat"; hops=0)[1]["score"]
    s1 = search_index(cat, "cat"; hops=1)[1]["score"]
    @test s0 == 2.0
    @test s1 == 2 + 0.35 / 3
    reds = build_index([
        Dict("id"=>"1", "text"=>"red blue"),
        Dict("id"=>"2", "text"=>"red blue"),
        Dict("id"=>"3", "text"=>"red blue"),
        Dict("id"=>"4", "text"=>"green blue"),
        Dict("id"=>"only", "text"=>"blue"),
    ])
    low = search_index(reds, "green red"; hops=1)
    high = search_index(reds, "red green"; hops=1)
    only_low = onlyone = only_high = nothing
    for r in low
        r["id"] == "only" && (only_low = r["score"])
    end
    for r in high
        r["id"] == "only" && (only_high = r["score"])
    end
    @test only_low == 0.35 / 3
    @test only_high == 0.35
    @test search_index(idx, "elliptic"; hops=3) === nothing
    @test search_index(idx, "elliptic"; limit=0) === nothing
    bad = search_index(idx, ""; regex="(", hops=0)
    @test isempty(bad)
    @test !regex_hit("magic", "MAGIC") == false
    @test regex_hit("magic square", "MAGIC")
    longpat = "(" * "a"^300
    @test !regex_hit("a"^20, longpat)
    elapsed = @elapsed regex_hit("a"^30, "(a+)+b")
    @test elapsed < 1.0
    @test !regex_hit("a"^30, "(a+)+b")
    state = Corpus()
    @test occursin("load corpus first", neuro_dispatch("query", "{\"query\":\"a\"}", state))
    loaded = neuro_dispatch("loadCorpus", json_text(Dict("documents"=>docs)), state)
    @test parse_json(loaded)["indexed"] == 2
    q = neuro_dispatch("query", json_text(Dict("query"=>"elliptic", "hops"=>0)), state)
    @test parse_json(q)[1]["id"] == "a"
    stateless = neuro_dispatch("search", json_text(Dict(
        "documents"=>[Dict("id"=>"z", "text"=>"other topic")],
        "query"=>"other")), state)
    @test parse_json(stateless)[1]["id"] == "z"
    still = neuro_dispatch("query", json_text(Dict("query"=>"elliptic", "hops"=>0)), state)
    @test parse_json(still)[1]["id"] == "a"
    @test occursin("unknown operation", neuro_dispatch("eval", "{}", state))
    @test occursin("invalid JSON", neuro_dispatch("magic", "[", state))
    @test occursin("invalid JSON", neuro_dispatch("magic", "null", state))
    magic = parse_json(neuro_dispatch("magic", "{\"ignored\":1}", state))
    @test magic["valid"] == true
    lo = parse_json(neuro_dispatch("checkMagic", json_text(Dict("square"=>[[8,1,6],[3,5,7],[4,9,2]])), state))
    @test lo == true
    @test parse_json(neuro_dispatch("checkSquares", json_text(Dict("square"=>[[8,1,6],[3,5,7],[4,9,2]])), state)) == false
    curve = parse_json(neuro_dispatch("curvePoints", "{\"a\":0,\"b\":1,\"bound\":4}", state))
    @test [0, 1] in curve
    @test occursin("operation rejected", neuro_dispatch("curvePoints", "{\"a\":-3,\"b\":2,\"bound\":4}", state))
    @test occursin("invalid curve", neuro_dispatch("curvePoints", "{\"a\":0,\"b\":1,\"bound\":1001}", state))
    @test build_index([Dict("id"=>"a","text"=>"a"), Dict("id"=>"a","text"=>"b")]) === nothing
end

function with_julia_server(script, sock, env, body)
    cmd = addenv(`$(Base.julia_cmd()) --project=$(joinpath(ROOT,"julia")) --startup-file=no $(joinpath(ROOT,"julia","bin",script)) $sock`, env)
    proc = run(cmd, wait=false)
    try
        ready = false
        for _ in 1:200
            if ispath(sock)
                ready = true
                break
            end
            process_running(proc) || break
            sleep(0.05)
        end
        @assert ready "server failed to listen on $sock"
        body()
    finally
        kill(proc)
        wait(proc)
        rm(sock, force=true)
    end
end

@testset "RPC integration" begin
    sock = "/tmp/abjad-julia-$(getpid()).sock"
    with_julia_server("abjad_daemon.jl", sock, Dict("ABJAD_TIMEOUT_MS"=>"5000"), () -> begin
        got = abjad_call(sock, "الله")
        @test got.status == 0 && got.value == 66
        bad = abjad_call(sock, "ABC")
        @test bad.status == 1
        client = joinpath(ROOT, "abjad-wstp", "abjad-client")
        @test readchomp(`$client $sock محمد`) == "92"
        p = run(ignorestatus(`$client $sock ABC`))
        @test p.exitcode != 0
    end)
    csock = "/tmp/abjad-c-$(getpid()).sock"
    daemon = joinpath(ROOT, "abjad-wstp", "abjad-daemon")
    proc = run(`$daemon local $csock`, wait=false)
    try
        for _ in 1:100
            ispath(csock) && break
            sleep(0.02)
        end
        @test abjad_call(csock, "أحمد").value == 53
    finally
        kill(proc)
        wait(proc)
        rm(csock, force=true)
    end
    nsock = "/tmp/neuro-julia-$(getpid()).sock"
    with_julia_server("neuro_daemon.jl", nsock, Dict("NEURO_TIMEOUT_MS"=>"5000"), () -> begin
        rpc = joinpath(ROOT, "elliptic-neuroregex", "rpc-client")
        callrpc(op, js) = readchomp(Cmd([rpc, nsock, op, js]))
        magic = parse_json(callrpc("magic", "{}"))
        @test magic["valid"] == true
        points = parse_json(callrpc("curvePoints", "{\"a\":0,\"b\":1,\"bound\":4}"))
        @test any(==([0, 1]), points)
        docs = json_text(Dict("documents"=>[
            Dict("id"=>"brown", "text"=>"Elliptic curve torsion magic square"),
            Dict("id"=>"soyga", "text"=>"Soyga 23-symbol mirror recurrence"),
        ]))
        loaded = parse_json(callrpc("loadCorpus", docs))
        @test loaded["indexed"] == 2
        q = json_text(Dict("query"=>"magic elliptic", "regex"=>"curve|torsion", "hops"=>2, "limit"=>10))
        hits = parse_json(callrpc("query", q))
        @test hits[1]["id"] == "brown"
        junk = connect(nsock)
        write(junk, zeros(UInt8, 6))
        close(junk)
        @test parse_json(callrpc("magic", "{}"))["valid"] == true
    end)
end

println("JULIA_TEST_FILE_DONE")
