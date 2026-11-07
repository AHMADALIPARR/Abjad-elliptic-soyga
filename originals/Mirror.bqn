#!/usr/bin/env bqn
# Dee Mirror: executable BQN core.
# Abstract E[N] coordinates and actual F_p curve points are separate domains.
# Requires a BQN implementation supporting the documented core primitives.

# A torsion point is a pair ⟨a,b⟩ with coordinates modulo N.
# These describe E[N] after choosing a basis over an algebraically closed field,
# when the characteristic does not divide N.
Zero ⇐ ⟨0,0⟩
Mod ⇐ {𝕨|𝕩}
TAdd ⇐ {n‿a‿b←𝕩 ⋄ n|a+b}
TNeg ⇐ {n‿a←𝕩 ⋄ n|-a}
TSub ⇐ {n‿a‿b←𝕩 ⋄ n|a-b}

# Magic square G[r,c] = (c+r, c+2*r) mod n, odd n.
# Returned as a rank-2 array whose elements are two-vectors.
Cell ⇐ {
  n‿r‿c←𝕩
  ⟨n|c+r, n|c+2×r⟩
}
# The rank-2 grid is assembled from a nested list of row cells.
Magic ⇐ {
  n←𝕩
  ! (n>0)∧(1=2|n)
  cells←{Cell ⟨n,⌊𝕩÷n,n|𝕩⟩}¨ ↕(n×n)
  n‿n⥊cells
}

# Lift a point in E[n] to the chosen compatible basis in E[3n].
# The map (a,b) ↦ (3a,3b) embeds the abstract group E[n].
Lift3 ⇐ {3×𝕩}
Nested ⇐ {
  n‿p‿levels←𝕩
  levels=0 ? ⟨n,p⟩
  ; (3×n)‿(Lift3 p)‿(levels-1) 𝕊 @
}

# Finite-field curve y²=x³+ax+b (mod prime p).
# Infinity is represented by the empty vector ⟨⟩.
# Coordinates are integer representatives in [0,p).
O ⇐ ⟨⟩
IsO ⇐ {0=≠𝕩}
Discriminant ⇐ {p‿a‿b←𝕩 ⋄ p|4×a⋆3+27×b⋆2}
OnCurve ⇐ {
  p‿a‿b‿pt←𝕩
  IsO pt ? 1
  ; x‿y←pt
    (p|y×y) = (p|(x⋆3)+(a×x)+b)
}
Mirror ⇐ {
  p‿pt←𝕩
  IsO pt ? O
  ; x‿y←pt ⋄ ⟨x,p|-y⟩
}

# Modular exponentiation. Exponents are nonnegative integers.
PowMod ⇐ {
  p‿base‿exponent←𝕩
  exponent=0 ? 1
  ; k←⌊exponent÷2
    t←PowMod p‿base‿k
    r←p|t×t
    (2|exponent)=0 ? r
    ; p|r×base
}
InvMod ⇐ {
  p‿a←𝕩
  ! 0≠p|a
  PowMod p‿a‿(p-2)
}

# Actual chord-and-tangent group law in a finite field.
# Parameter p must be prime > 3 and discriminant must be nonzero.
EAdd ⇐ {
  p‿a‿b‿u‿v←𝕩
  IsO u ? v
  ; IsO v ? u
  ; x1‿y1←u
    x2‿y2←v
    ((x1=x2)∧(0=p|y1+y2)) ? O
    ; same←(x1=x2)∧(y1=y2)
      numerator←same ? p|(3×x1×x1)+a ; p|y2-y1
      denominator←same ? p|2×y1 ; p|x2-x1
      slope←p|numerator×InvMod p‿denominator
      x3←p|(slope×slope)-x1-x2
      y3←p|(slope×(x1-x3))-y1
      ⟨x3,y3⟩
}
ESub ⇐ {
  p‿a‿b‿u‿v←𝕩
  EAdd p‿a‿b‿u‿(Mirror p‿v)
}
EMul ⇐ {
  p‿a‿b‿k‿pt←𝕩
  k=0 ? O
  ; k<0 ? EMul p‿a‿b‿(-k)‿(Mirror p‿pt)
  ; half←EMul p‿a‿b‿(⌊k÷2)‿pt
    doubled←EAdd p‿a‿b‿half‿half
    (2|k)=0 ? doubled
    ; EAdd p‿a‿b‿doubled‿pt
}

# Enumerates the actual points of a finite-field elliptic curve.
# This set is not assumed to have n² points or be isomorphic to E[n].
CurvePoints ⇐ {
  p‿a‿b←𝕩
  candidates←{⟨⌊𝕩÷p,p|𝕩⟩}¨ ↕p×p
  hits←(OnCurve¨ {p‿a‿b‿𝕩}¨ candidates) / candidates
  ⟨O⟩∾hits
}

# Recursive traversal on the curve; terminated by O, repeated point,
# or exhaustion of an explicit depth budget. Tracks every visited state.
# The next chord operation is Add(current, step).
Trace ⇐ {
  p‿a‿b‿current‿step‿fuel‿seen←𝕩
  IsO current ? ⟨"infinity",seen∾⟨current⟩⟩
  ; fuel=0 ? ⟨"depth",seen∾⟨current⟩⟩
  ; ((<current)∊seen) ? ⟨"cycle",seen∾⟨current⟩⟩
  ; next←EAdd p‿a‿b‿current‿step
    Trace p‿a‿b‿next‿step‿(fuel-1)‿(seen∾⟨current⟩)
}

# Searching the abstract torsion square by repeated group translation.
# This is a distinct search from chord-tangent traversal in E(F_p).
TTrace ⇐ {
  n‿current‿step‿fuel‿seen←𝕩
  current≡Zero ? ⟨"infinity",seen∾⟨current⟩⟩
  ; fuel=0 ? ⟨"depth",seen∾⟨current⟩⟩
  ; ((<current)∊seen) ? ⟨"cycle",seen∾⟨current⟩⟩
  ; next←n|current+step
    TTrace n‿next‿step‿(fuel-1)‿(seen∾⟨current⟩)
}

# Verify group sums and uniqueness of square.
SumT ⇐ {n‿pts←𝕩 ⋄ n|+´pts}
VerifyMagic ⇐ {
  n←𝕩
  g←Magic n
  flat←⥊g
  unique←∧´{pt←𝕩 ⋄ 1=+´{pt≡𝕩}¨flat}¨flat
  rowOK←∧´{r←𝕩 ⋄ Zero≡SumT n‿({(r‿𝕩)⊑g}¨↕n)}¨↕n
  colOK←∧´{c←𝕩 ⋄ Zero≡SumT n‿({(𝕩‿c)⊑g}¨↕n)}¨↕n
  main←{(𝕩‿𝕩)⊑g}¨↕n
  anti←{(𝕩‿(n-1-𝕩))⊑g}¨↕n
  unique∧rowOK∧colOK∧(Zero≡SumT n‿main)∧(Zero≡SumT n‿anti)
}
