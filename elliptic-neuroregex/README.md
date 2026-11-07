<!-- SPDX-License-Identifier: AGPL-3.0-only -->
<!-- SPDX-FileCopyrightText: 2026 The algorithm-cores project contributors -->
# Elliptic NeuroRegex — Wolfram Language + WSTP C daemon

A **real implementation draft** (not a claim of Wolfram runtime verification): native Unix binary RPC to Wolfram Language via WSTP, a deterministic activation-network search index, and a precise elliptic-curve-inspired 3×3 group-valued magic square. The executable RPC client and C mathematical tests compile and run in the supplied environment; Mathematica/Wolfram Engine and WSTP SDK **were unavailable**, so Wolfram Language execution, WSTP linking, and end-to-end behavior remain **unverified**.

## Architecture

```
C or CLI RPC client
   | uint16_be op_length; uint32_be json_length; UTF-8 op; UTF-8 JSON
   v
local Unix socket (0600) / C daemon (one client at a time)
   | WSTP EvaluatePacket[NeuroRegex`Dispatch[op, json]]
   v
Wolfram Engine, already loaded with wl/NeuroRegex.wl
   | returns UTF-8 JSON string
   v
C daemon -> uint32_be result_length; JSON bytes
```

The source does **not** implement interception, collection or decoding of external signals. "SIGINT" from the earlier project refers only to the embedding application's name.

## Research grounding

**Two different questions must not be conflated:**

1. Ezra Brown, *Magic Squares, Finite Planes, and Points of Inflection on Elliptic Curves*, College Mathematics Journal 32 (2001), 260–267. An elliptic curve over an algebraically closed field of characteristic not 2 or 3 has nine inflection points, forming E[3] ≅ (Z/3Z)^2; these may be arranged as a 3×3 group-valued magic square. https://personal.math.vt.edu/brown/doc/magic.pdf
2. Magic squares of **nine distinct positive integer squares** are an unresolved Diophantine existence problem. Auel & Singer, *The algebraic geometry of 3-by-3 magic squares of squares*, September 2026, https://arxiv.org/abs/2609.09351. This program does **not** solve that open problem.
3. Elliptic-curve connections to square entries also arise for E_(a,b): y² = x(x+a)(x+b), an additional and different family from the short Weierstrass curves y²=x³+a x+b used by the simple `curvePoints` function. https://dms.umontreal.ca/~andrew/Courses/RationalPtsOnCurves.pdf

### Mathematical invariant

Let G=(Z/3Z)^2 and define M(i,j)=(i+j,j) mod 3 for i,j in {0,1,2}. The map (i,j)->(i+j,j) is bijective; all 9 cells are distinct. For any row, column, or diagonal, the coordinate sums are 0 mod 3. `MagicCertificate` verifies all 8 lines and distinctness. This is a **group** magic square; it is not a square of integer squares. `CurveNonsingularQ` checks 4a³+27b² != 0.

### Search design

The neural-*inspired* layer is transparent, deterministic weighted associative activation, **not a trained neural network**:

- Unicode-aware word tokenization, indexed term counts, per-document co-occurrence edges.
- Query tokens activate weights 1.0, neighboring tokens 0.35, second-hop tokens 0.12.
- Score = sum(min(term_frequency,3)×activation) + 4 for regex match.
- Deterministic sorting by descending score then document id. No embeddings or LLM dependencies.
- `RegularExpression` and `StringContainsQ` add PCRE-powered regex; evaluation uses `TimeConstrained`, but this is **not a hard security or CPU limit**. Run only with trusted local callers and datasets. The Unix socket is owner-only.

## Build

```bash
make                  # builds only rpc-client; C compiler required
make test-native       # validates 9 distinct group elements + 8 identity sums
make wl-test           # requires wolframscript, NOT available in our test environment
```

To build the daemon with YOUR Wolfram SDK library/header paths:

```bash
make wstp-daemon WSTP_INCLUDE='-I/path/to/SDK/include' \
    WSTP_LIBS='-L/path/to/SDK/lib -lWSTP64i4 -lm -lpthread -ldl'
```

**Library names and additional linker flags vary by operating system, architecture and Wolfram version**; read your installed SDK's C developer guide and adjust them. `WSOpenString` launches the kernel with link options supplied at runtime. Start locally:

```bash
./wstp-daemon /tmp/elliptic-neuroregex.sock "$PWD/wl/NeuroRegex.wl" \
  '-linkmode launch -linkname "WolframKernel -wstp"'
```

`WolframKernel -wstp` is a typical starting option, not a confirmed command for your installation. Use the kernel binary/link syntax supplied by your Wolfram installation.

In another terminal:

```bash
./rpc-client /tmp/elliptic-neuroregex.sock magic '{}'
./rpc-client /tmp/elliptic-neuroregex.sock curvePoints '{"a":0,"b":1,"bound":4}'
./rpc-client /tmp/elliptic-neuroregex.sock loadCorpus '{"documents":[{"id":"brown","text":"Elliptic curve torsion magic square"},{"id":"soyga","text":"Soyga 23-symbol mirror recurrence"}]}'
./rpc-client /tmp/elliptic-neuroregex.sock query '{"query":"magic elliptic","regex":"curve|torsion","hops":2,"limit":10}'
```

No arbitrary WL evaluation is exposed by RPC: the dispatcher accepts only allowlisted operations and parses JSON through `ImportString[...,"RawJSON"]`. The C daemon is synchronous and allows one active client at a time; it is not a scalable production multi-tenant server. Applications should apply memory/CPU limits externally and avoid untrusted regex. Indexes are kept in kernel memory and lost on restart.

### Wolfram-only usage

```wolfram
Get["wl/NeuroRegex.wl"];
m = NeuroRegex`MagicTorsionSquare[];
NeuroRegex`MagicCertificate[m]
idx = NeuroRegex`BuildIndex[{
  <|"id" -> "a", "text" -> "elliptic curve magic square"|>,
  <|"id" -> "b", "text" -> "Soyga mirror abjad numerology"|>
}];
NeuroRegex`Search[idx, "elliptic", "Regex" -> "magic", "Hops" -> 2]
```

## Verification status

Recorded on this tree, Wolfram Engine and the WSTP SDK absent:

- `rpc-client` compiles with `cc -O2 -std=c11 -Wall -Wextra -Werror`.
- `tests/math_reference` prints the original PASS line.
- `tests/native_suite` reports `elliptic native checks=26 failures=0`. It covers the 3×3 certificate, discriminant 31, the bound-4 integral points of `y²=x³+1`, order 3 on `F_5`, order 5 of `(3,6)` on `F_97`, and the Lo Shu square not being a square of squares.
- `make wstp-daemon` exits because `WSTP_INCLUDE` and `WSTP_LIBS` are unset.
- `tests/test.wls` was not run. `wolframscript` is not installed.
- The Julia dispatcher in `julia/src/neuro.jl` implements the allowlisted operations and was called through `rpc-client` on a Unix socket. That is a native substitute, not an execution of `NeuroRegex.wl`.
- Timings are in `benchmarks/`. They are measurements, not a throughput certificate.

## Caution

This is symbolic/lexical association search; the term "neurological" is a metaphor for spreading activation. `IntegralCurvePoints` enumerates bounded integer coordinates (not arbitrary rational points). All claims of computational validation beyond the listed tests require a local Wolfram Engine run.
