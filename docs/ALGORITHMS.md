<!-- SPDX-License-Identifier: AGPL-3.0-only -->
<!-- SPDX-FileCopyrightText: 2026 The algorithm-cores project contributors -->
# Algorithms

## Abjad

Eastern abjad kabir. The 28 letters `ابجد هوز حطي كلمن سعفص قرشت ثخذ ضظغ` have values 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000. Their total is 5995.

`أ إ آ ٱ` count as alif (1). `ى` counts as ya (10). `ة` counts as ha (5). Hamza, tatweel, harakat, spaces, punctuation, and any other code point add 0. A string with no valued letter is rejected. UTF-8 must be well-formed: overlong encodings, surrogates, and code points above U+10FFFF are rejected. Yeh-with-hamza `ئ` and waw-with-hamza `ؤ` are not in the table, so a string of only those letters is rejected. Presentation forms are not remapped.

Known totals: `الله` = 66, `محمد` = 92, `أحمد` = 53, `علي` = 110.

The C function `abjad_sum` is the original decoder. The Julia function of the same name is a second implementation checked against the same vectors. The Wolfram package `AbjadRPC.wl` is the original kernel package. It was not executed.

## Soyga

23-letter alphabet `a b c d e f g h i k l m n o p q r s t u x y z` (no j, v, w). Reeds's step is `f(w) = (V(w) - 1) mod 23` with the Section 18 weights in `Soyga.agda`. The top row is repeated `west + f(west)`. Every later cell is `north + f(west)`. The left margin is the 6-letter seed followed by its reverse, three times.

Agda checks, under `--safe --without-K` and with no postulates:

- `verse-reeds-invariant` for all 23 letters
- `interior-equivalence` and `top-equivalence`
- `reverse-involution`
- `top-first-step` and `interior-first-step`
- `nisram-prefix`, `nisram-dizb`, `nisram-interior-prefix`, `nisram-reversal`

Pattern variables that collided with letter constructors were renamed. That was required for Agda to accept the module. The equalities are definitional (`refl`).

Julia `soyga_table` is a separate executable. It is not a proof. It reproduces the NISRAM first row `ndizb` and then `dizb`, the second-row cycle `lytr`, the third-row cycle `xiba`, and the fifth-row cycle `ohqtauiducis`. The fourth-row cycle produced by the recurrence is `qsrnplfdfzly`. A secondary transcription of Reeds's prose says `qsrnylfdfzly`. Letter counts for the generated NISRAM table are B 72, R 70, Y 70, and every letter occurs. MARSIN counts are I 82, T 72, Y 67. A secondary claim that NISRAM rows 11, 22, and 33 are entirely L is not true of this indexing and is not asserted.

## Two different magic squares

They are both group-valued. Neither is a 3×3 square of distinct positive integer squares, and this project does not claim one.

- NeuroRegex / inflection square: `M(i,j) = (i+j, j) mod 3` on `(Z/3Z)^2`. All nine cells are distinct and all eight lines sum to `(0,0)`.
- BQN square: `G(r,c) = (c+r, c+2r) mod n` for odd positive `n`. The map has determinant `-1`, so it is bijective. For odd `n`, `sum(0..n-1) = n(n-1)/2` is divisible by `n`, so every row, column, and both diagonals sum to `(0,0)`.

`SquareOfSquaresQ` only checks a candidate. The Lo Shu square sums to 15 and is not a square of squares.

## Finite-field group law

`y^2 = x^3 + a x + b` over a prime `p > 3` with `4a^3 + 27b^2 ≠ 0 (mod p)`. Infinity is the empty vector in BQN and `EPoint(true, …)` in Julia. Addition is the chord-and-tangent law. Negation is `(x, -y)`. Scalar multiplication is double-and-add.

Checked vectors:

- Over `F_5`, `y^2 = x^3 + 1`, `2·(0,1) = (0,4)` and `3·(0,1) = O`.
- Affine integral points of `y^2 = x^3 + 1` with bound 4 are `(-1,0), (0,±1), (2,±3)`.
- Over `F_97`, `y^2 = x^3 + 2x + 3`, the point `(3,6)` has order 5. Its trace under repeated addition is `(3,6), (80,10), (80,87), (3,91), O`.
- Julia checks commutativity, inverses, and associativity on all six `F_5` points, including infinity. That is a finite check, not a general proof.

`CurvePoints` in BQN lists every affine point with coordinates in `0..p-1` and prepends `O`. It is capped at `p ≤ 256`. `IntegralCurvePoints` lists integer points with `|x|,|y| ≤ bound`. The RPC bound is `≤ 1000`. The library bound is `≤ 10000`. The C helper uses int64 and rejects overflow. Julia uses `BigInt`.

BQN is right-to-left. `4×a⋆3+27×b⋆2` is not the discriminant. The implementation uses `(4×a⋆3)+(27×b⋆2)`. `Discriminant ⟨97,1,1⟩` is 31.

## NeuroRegex search

Tokenization is one or more Unicode letters or numbers, then lowercase. Inside each document, unique tokens form directed co-occurrence edges. Edge weight is the number of documents in which the ordered pair occurs.

Query tokens, in first-seen order, receive weight `1.0`. A neighbor not yet weighted receives `0.35 * min(1, count/3)` from the first query token that reaches it. A second hop, from those neighbors only, uses `max` with `0.12 * min(1, count/3)` and does not overwrite query tokens. A document score is `sum(weight * min(tf, 3))`, plus `4.0` when the PCRE2 pattern matches. Non-positive scores are dropped. Sort is descending score, then ascending id.

An invalid pattern, a pattern longer than 256 characters, or a PCRE2 match-limit or depth-limit failure is a non-match. The limits used are 100000 match steps and depth 10000. This is not Wolfram `TimeConstrained`. The Wolfram draft says that timer is not a hard limit.

`loadCorpus` replaces the in-process index only when the corpus is valid. `search` does not replace it. `query` before a successful load returns an error. Operations outside the allowlist return an error. The dispatcher parses JSON and does not evaluate caller source.
