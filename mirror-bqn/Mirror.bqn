#!/usr/bin/env bqn
# SPDX-License-Identifier: AGPL-3.0-only
# SPDX-FileCopyrightText: 2026 The algorithm-cores project contributors
# Dee Mirror: executable BQN core.
# Abstract E[N] coordinates and actual F_p curve points are separate domains.
#
# Completion notes (algorithm unchanged on the intended domain):
# - Data exports are spelled in subject case (`zero`, `o`). Current BQN ties
#   syntactic role to capitalization, so `Zero ⇐ ⟨0,0⟩` is not a valid program.
# - Block bodies split by `;` do not share locals. Early returns are nested
#   blocks that close over one outer destructure.
# - `Nested` recurses monadically. The previous call passed the triple on the left.
# - Discriminant parentheses match 4·a³+27·b². BQN is right-to-left, so
#   `4×a⋆3+27×b⋆2` parses as `4×(a⋆(3+…))`.
# - Cycle detection compares the point with each visited point.
# - Domain checks and resource caps below reject inputs outside the stated model.
#   They do not change results for inputs the specification accepts.

zero ⇐ ⟨0, 0⟩
Mod ⇐ {𝕨|𝕩}
TAdd ⇐ {n‿a‿b ← 𝕩 ⋄ ! n>0 ⋄ n|a+b}
TNeg ⇐ {n‿a ← 𝕩 ⋄ ! n>0 ⋄ n|-a}
TSub ⇐ {n‿a‿b ← 𝕩 ⋄ ! n>0 ⋄ n|a-b}

# Magic square G[r,c] = (c+r, c+2×r) mod n, odd positive integer n.
# Returned as a rank-2 array whose elements are two-vectors.
Cell ⇐ {
  n‿r‿c ← 𝕩
  ⟨n|c+r, n|c+2×r⟩
}
Magic ⇐ {
  n ← 𝕩
  ! (n≡⌊n) ∧ (n>0) ∧ (1=2|n) ∧ (n≤401)
  cells ← {Cell ⟨n, ⌊𝕩÷n, n|𝕩⟩}¨ ↕ n×n
  n‿n ⥊ cells
}

# (a,b) ↦ (3a, 3b), iterated `levels` times: E[n] embedded in E[3^levels·n].
Lift3 ⇐ {3×𝕩}
Nested ⇐ {
  n‿p‿levels ← 𝕩
  ! (n≡⌊n) ∧ (n>0) ∧ (n≤10⋆12)
  ! (levels≡⌊levels) ∧ (0≤levels) ∧ (levels≤12)
  { 𝕊𝕩:
    levels=0 ? ⟨n, p⟩
  ; Nested (3×n)‿(3×p)‿(levels-1)
  } @
}

# Finite-field curve y² = x³ + a·x + b (mod prime p).
# Infinity is the empty vector ⟨⟩.
# Coordinates used by the group law are integer representatives in [0, p).
o ⇐ ⟨⟩
IsO ⇐ {0=≠𝕩}

ISqrt ← {
  n ← 𝕩
  ! (n≥0) ∧ (n≡⌊n)
  Search ← {
    n‿lo‿hi ← 𝕩 ⋄ (hi-lo)≤1 ? lo
  ; n‿lo‿hi ← 𝕩 ⋄ m ← lo + ⌊(hi-lo)÷2 ⋄ (m×m)≤n ? Search n‿m‿hi
  ; n‿lo‿hi ← 𝕩 ⋄ m ← lo + ⌊(hi-lo)÷2 ⋄ Search n‿lo‿m
  }
  Search n‿0‿(n+1)
}
IsPrime ← {
  p ← 𝕩
  { 𝕊𝕩:
    (p≢⌊p) ∨ (p<2) ? 0
  ; p≤3 ? 1
  ; 0=2|p ? 0
  ; lim ← ISqrt p
    ds ← 2↓↕(lim+1)
    ∧´ {0≠p|𝕩}¨ ds
  } @
}

Discriminant ⇐ {
  p‿a‿b ← 𝕩
  ! (p≡⌊p) ∧ (p>0)
  ! (a≡⌊a) ∧ (b≡⌊b)
  p | (4×a⋆3) + (27×b⋆2)
}
OnCurve ⇐ {
  p‿a‿b‿pt ← 𝕩
  { 𝕊𝕩:
    IsO pt ? 1
  ; x‿y ← pt
    (x≡⌊x) ∧ (y≡⌊y) ∧ (p|y×y) = (p | (x⋆3) + (a×x) + b)
  } @
}
Mirror ⇐ {
  p‿pt ← 𝕩
  ! (p≡⌊p) ∧ (p>0)
  { 𝕊𝕩:
    IsO pt ? o
  ; x‿y ← pt ⋄ ! (x≡⌊x) ∧ (y≡⌊y) ⋄ ⟨p|x, p|-y⟩
  } @
}

# Modular exponentiation. Exponent is a nonnegative integer.
# Resource cap: exponent ≤ 10⋆7 and modulus ≤ 10⋆7, so the recursion depth
# stays logarithmic and small. This is exact residue arithmetic, not a float.
PowMod ⇐ {
  p‿base‿exponent ← 𝕩
  ! (p≡⌊p) ∧ (p>0) ∧ (p≤10⋆7)
  ! (base≡⌊base)
  ! (exponent≡⌊exponent) ∧ (0≤exponent) ∧ (exponent≤10⋆7)
  { 𝕊𝕩:
    exponent=0 ? 1
  ; k ← ⌊exponent÷2
    t ← PowMod p‿base‿k
    r ← p|t×t
    even ← 0=2|exponent
    even ⊑ ⟨p|r×base, r⟩
  } @
}
InvMod ⇐ {
  p‿a ← 𝕩
  ! IsPrime p
  ! 0≠p|a
  PowMod p‿a‿(p-2)
}

ValidCurve ← {
  p‿a‿b ← 𝕩
  ! IsPrime p
  ! p>3
  ! p≤1000003
  ! (a≡⌊a) ∧ (b≡⌊b) ∧ (((10⋆12)≥|a) ∧ ((10⋆12)≥|b))
  ! 0≠Discriminant p‿a‿b
  1
}
PointIn ← {
  p‿pt ← 𝕩
  { 𝕊𝕩:
    IsO pt ? 1
  ; x‿y ← pt
    ! (x≡⌊x) ∧ (y≡⌊y)
    ! (0≤x) ∧ (x<p) ∧ (0≤y) ∧ (y<p)
    1
  } @
}

# Chord-and-tangent addition. Caller must pass a prime p>3, nonzero
# discriminant, and points on the curve (checked here).
EAdd ⇐ {
  p‿a‿b‿u‿v ← 𝕩
  ValidCurve p‿a‿b
  ! PointIn p‿u
  ! PointIn p‿v
  ! OnCurve p‿a‿b‿u
  ! OnCurve p‿a‿b‿v
  { 𝕊𝕩:
    IsO u ? v
  ; IsO v ? u
  ; x1‿y1 ← u ⋄ x2‿y2 ← v
    vertical ← (x1=x2) ∧ (0=p|y1+y2)
    { 𝕊𝕩:
      vertical ? o
    ; same ← (x1=x2) ∧ (y1=y2)
      numerator ← same ⊑ ⟨p|y2-y1, p|(3×x1×x1)+a⟩
      denominator ← same ⊑ ⟨p|x2-x1, p|2×y1⟩
      slope ← p | numerator × InvMod p‿denominator
      x3 ← p | ((slope×slope) - x1) - x2
      y3 ← p | (slope × (x1-x3)) - y1
      ⟨x3, y3⟩
    } @
  } @
}
ESub ⇐ {
  p‿a‿b‿u‿v ← 𝕩
  EAdd p‿a‿b‿u‿(Mirror p‿v)
}
EMul ⇐ {
  p‿a‿b‿k‿pt ← 𝕩
  ! (k≡⌊k) ∧ ((10⋆6)≥|k)
  { 𝕊𝕩:
    k=0 ?
      ValidCurve p‿a‿b
      PointIn p‿pt
      OnCurve p‿a‿b‿pt
      o
  ; k<0 ? EMul p‿a‿b‿(-k)‿(Mirror p‿pt)
  ; half ← EMul p‿a‿b‿(⌊k÷2)‿pt
    doubled ← EAdd p‿a‿b‿half‿half
    even ← 0=2|k
    even ⊑ ⟨EAdd p‿a‿b‿doubled‿pt, doubled⟩
  } @
}

# Exact enumeration of affine points with coordinates in 0..p-1, plus O.
# Not assumed to have n² points. Resource cap: p≤256 (at most 65536 candidates).
CurvePoints ⇐ {
  p‿a‿b ← 𝕩
  ValidCurve p‿a‿b
  ! p≤256
  candidates ← {⟨⌊𝕩÷p, p|𝕩⟩}¨ ↕p×p
  hits ← (OnCurve¨ {p‿a‿b‿𝕩}¨ candidates) / candidates
  ⟨o⟩ ∾ hits
}

# Recursive traversal. Stops at O, a repeated point, or the fuel budget.
# Fuel is an explicit depth cap in 0..1024, not a claim that O is reached.
Trace ⇐ {
  p‿a‿b‿current‿step‿fuel‿seen ← 𝕩
  ! (fuel≡⌊fuel) ∧ (0≤fuel) ∧ (fuel≤1024)
  ValidCurve p‿a‿b
  ! PointIn p‿current
  ! PointIn p‿step
  ! OnCurve p‿a‿b‿current
  ! OnCurve p‿a‿b‿step
  { 𝕊𝕩:
    IsO current ? ⟨"infinity", seen∾⟨current⟩⟩
  ; fuel=0 ? ⟨"depth", seen∾⟨current⟩⟩
  ; (∨´ {current≡𝕩}¨ seen) ? ⟨"cycle", seen∾⟨current⟩⟩
  ; next ← EAdd p‿a‿b‿current‿step
    Trace p‿a‿b‿next‿step‿(fuel-1)‿(seen∾⟨current⟩)
  } @
}

# Abstract torsion walk. Distinct from chord-and-tangent traversal.
TTrace ⇐ {
  n‿current‿step‿fuel‿seen ← 𝕩
  ! (n≡⌊n) ∧ (n>0) ∧ (n≤10007)
  ! (fuel≡⌊fuel) ∧ (0≤fuel) ∧ (fuel≤1024)
  { 𝕊𝕩:
    current≡zero ? ⟨"infinity", seen∾⟨current⟩⟩
  ; fuel=0 ? ⟨"depth", seen∾⟨current⟩⟩
  ; (∨´ {current≡𝕩}¨ seen) ? ⟨"cycle", seen∾⟨current⟩⟩
  ; next ← n|current+step
    TTrace n‿next‿step‿(fuel-1)‿(seen∾⟨current⟩)
  } @
}

SumT ⇐ {n‿pts ← 𝕩 ⋄ n|+´pts}
VerifyMagic ⇐ {
  n ← 𝕩
  g ← Magic n
  flat ← ⥊g
  unique ← ∧´ {pt ← 𝕩 ⋄ 1=+´{pt≡𝕩}¨flat}¨ flat
  rowOK ← ∧´ {r ← 𝕩 ⋄ zero≡SumT n‿({(r‿𝕩)⊑g}¨↕n)}¨ ↕n
  colOK ← ∧´ {c ← 𝕩 ⋄ zero≡SumT n‿({(𝕩‿c)⊑g}¨↕n)}¨ ↕n
  main ← {(𝕩‿𝕩)⊑g}¨ ↕n
  anti ← {(𝕩‿((n-1)-𝕩))⊑g}¨ ↕n
  unique ∧ rowOK ∧ colOK ∧ (zero≡SumT n‿main) ∧ (zero≡SumT n‿anti)
}
