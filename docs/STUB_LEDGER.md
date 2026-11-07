<!-- SPDX-License-Identifier: AGPL-3.0-only -->
<!-- SPDX-FileCopyrightText: 2026 The algorithm-cores project contributors -->
# Stub completion ledger

The starters had no `TODO` markers. The gaps were untested code, constructors that shadowed Agda binders, BQN that does not type-check under current role and block rules, and Wolfram entry points that cannot run without a proprietary kernel.

| Gap | What was wrong | Where it is now | Evidence |
| --- | --- | --- | --- |
| Abjad never executed beyond a four-line smoke sketch | Decoder existed; timeouts, socket mode, `EINTR`, and malformed frames were absent | `abjad-wstp/src/abjad.c` kept; `daemon.c`, `client.c`, `protocol.h` hardened; `tests/suite.c` | `abjad suite checks=924 failures=0` plus smoke |
| WSTP Abjad backend | Compiles only with the SDK; `wolfram_open` returns -1 otherwise | `src/wolfram.c` and `wolfram/AbjadRPC.wl` kept | `make wstp` exits; `abjad-daemon wstp` prints `WSTP kernel startup failed` and leaves no socket |
| Abjad second implementation | None | `julia/src/abjad.jl`, used by the Julia daemon and by `abjad_call` | Julia Abjad testset 421; C client against Julia daemon returns 66 and 92 |
| Elliptic math only described | `math_reference.c` checked one 3×3 identity; curve law and integral points were not implemented in C | `src/native_math.c` | `elliptic native checks=26 failures=0` and the original PASS line |
| NeuroRegex runnable only in Wolfram | `NeuroRegex.wl` and `wstp_daemon.c` kept; engine absent | `julia/src/neuro.jl` speaks the same framing to `rpc-client` | Julia NeuroRegex testset 33; RPC testset includes `rpc-client` magic, curve points, load, and query |
| WSTP NeuroRegex daemon | SDK required | `src/wstp_daemon.c` unchanged in its link requirement | `make wstp-daemon` exits 1 asking for `WSTP_INCLUDE` |
| `test.wls` | Needs `wolframscript` | File kept | Not run. `command -v wolframscript` is empty |
| Soyga module rejected by Agda | Letter constructors `n`, `s`, `f`, … were used as binders, so patterns were not variables. Literal `22` was also rejected | `soyga-agda/Soyga.agda` | `agda --safe --without-K Soyga.agda` exits 0. No `postulate`, no `TERMINATING` |
| Soyga executable checks | None in the starter | `julia/src/soyga.jl` | Julia Soyga testset 45, including NISRAM/MARSIN letter counts. These are not Agda proofs |
| BQN data names | `Zero` and `O` are function spellings; `M ← •Import` is a function spelling | `mirror-bqn/Mirror.bqn` exports `zero` and `o`; tests use `m` | `bqn mirror-bqn/test.bqn` |
| BQN `;` scopes | Locals do not cross bodies, so the original early-return form does not see its bindings | Nested blocks with one outer destructure | Same run, plus 40 extended checks |
| BQN `Nested` | The triple was passed on the left of a monadic block | Monadic `Nested (3×n)‿(3×p)‿(levels-1)` | `⟨27,⟨9,9⟩⟩` for two levels |
| BQN discriminant and anti-diagonal | Right-to-left parse of `4×a⋆3+27×b⋆2` and `n-1-𝕩` | Parentheses in `Mirror.bqn` | `Discriminant ⟨97,1,1⟩ ≡ 31`; `VerifyMagic` for 1, 3, 7, 11 |
| BQN cycle test | `(<current)∊seen` does not compare a point with a list of points, and `Seen` clashes with `seen` | `∨´ {current≡𝕩}¨ seen` | `"cycle"` for a zero step |
| Group-law cross check | Not run | Julia associativity on all `F_5` points; C and BQN known vectors | Elliptic testset 324 |
| Benchmarks | None | `benchmarks/` | C 200 reps, BQN 20 reps, Julia samples with min/median/mean |

Python does not appear in the archives and was not added.
