# SPDX-License-Identifier: AGPL-3.0-only
# SPDX-FileCopyrightText: 2026 The algorithm-cores project contributors
using Algorithms

function samples(n, f)
    # one warmup
    f()
    out = Float64[]
    for _ in 1:n
        push!(out, @elapsed f())
    end
    out
end

function report(io, name, xs)
    println(io, name)
    println(io, "n=$(length(xs)) seconds")
    for x in xs
        println(io, x)
    end
    ys = sort(xs)
    mid = ys[cld(length(ys), 2)]
    println(io, "min=$(minimum(xs)) median=$(mid) mean=$(sum(xs)/length(xs))")
    println(io)
end

open(joinpath(@__DIR__, "..", "..", "benchmarks", "julia-raw.txt"), "w") do io
    println(io, "julia ", VERSION)
    println(io, readchomp(`uname -a`))
    cpu = ""
    for line in eachline("/proc/cpuinfo")
        startswith(line, "model name") && (cpu = line; break)
    end
    println(io, cpu)
    println(io, "nproc ", readchomp(`nproc`))
    println(io, "utc ", readchomp(`date -u +%Y-%m-%dT%H:%M:%SZ`))
    println(io)
    text = "الله"^2000
    report(io, "abjad_sum 8000 Arabic letters", samples(30, () -> abjad_sum(text)))
    report(io, "soyga_table nisram", samples(20, () -> soyga_table("nisram")))
    report(io, "magic_odd_ok 21", samples(30, () -> magic_odd_ok(21)))
    report(io, "integral_points a=0 b=1 bound=200", samples(20, () -> integral_points(0, 1, 200)))
    docs = [Dict("id"=>string(i), "text"=>"elliptic curve magic square soyga mirror " * string(i % 7)) for i in 1:200]
    idx = build_index(docs)
    report(io, "search_index 200 docs", samples(30, () -> search_index(idx, "elliptic magic"; hops=2)))
    p = EPoint(false, 3, 6)
    report(io, "emul order check 5*(3,6) mod 97", samples(50, () -> emul(97, 2, 5, p)))
end
println("wrote benchmarks/julia-raw.txt")
