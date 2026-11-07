-- SPDX-License-Identifier: AGPL-3.0-only
-- SPDX-FileCopyrightText: 2026 The algorithm-cores project contributors
{-# OPTIONS --safe --without-K #-}
-- Soyga recurrence.
-- Letter constructors a…z (no j, v, w) are in scope for the whole module.
-- Nat patterns therefore cannot be named n, s, r, … : Agda treats an
-- in-scope constructor as a constructor pattern, not as a binder.
-- Those binders are spelled j, aa, bb, … . The functions and the equalities
-- are the ones in the starter; this is not a termination or postulate bypass.
module Soyga where

open import Agda.Builtin.Nat using (Nat; zero; suc)
open import Agda.Builtin.Equality using (_≡_; refl)

-- The historical 23-letter Latin alphabet; j, v, and w do not occur.
data Letter : Set where
  a b c d e f g h i k l m n o p q r s t u x y z : Letter

-- A total cyclic successor on exactly 23 letters.
next : Letter → Letter
next a = b
next b = c
next c = d
next d = e
next e = f
next f = g
next g = h
next h = i
next i = k
next k = l
next l = m
next m = n
next n = o
next o = p
next p = q
next q = r
next r = s
next s = t
next t = u
next u = x
next x = y
next y = z
next z = a

advance : Nat → Letter → Letter
advance zero    w = w
advance (suc j) w = next (advance j w)

-- Modular arithmetic by cycling the residues 0 ... 22.
-- Avoids an unchecked integer-to-letter conversion.
-- 22 is not a literal pattern: Agda expands those into constructor
-- towers and rejects the combination with a catch-all binder.
data Bool : Set where
  true false : Bool

eqNat : Nat → Nat → Bool
eqNat zero zero = true
eqNat zero (suc _) = false
eqNat (suc _) zero = false
eqNat (suc j1) (suc j2) = eqNat j1 j2

nextResidue : Nat → Nat
nextResidue j with eqNat j 22
... | true = zero
... | false = suc j

mod23 : Nat → Nat
mod23 zero    = zero
mod23 (suc j) = nextResidue (mod23 j)

pred : Nat → Nat
pred zero    = zero
pred (suc j) = j

-- Section 18 letter values, as transcribed in the 2026 derivation.
verseValue : Letter → Nat
verseValue a = 3
verseValue b = 3
verseValue c = 27
verseValue d = 29
verseValue e = 15
verseValue f = 3
verseValue g = 7
verseValue h = 6
verseValue i = 15
verseValue k = 16
verseValue l = 21
verseValue m = 23
verseValue n = 15
verseValue o = 9
verseValue p = 14
verseValue q = 21
verseValue r = 12
verseValue s = 9
verseValue t = 9
verseValue u = 16
verseValue x = 16
verseValue y = 16
verseValue z = 3

-- f(w) = (V(w) - 1) mod 23.
verseStep : Letter → Nat
verseStep w = mod23 (pred (verseValue w))

-- Independent tabulation of Jim Reeds's empirical f.
reedsStep : Letter → Nat
reedsStep a = 2
reedsStep b = 2
reedsStep c = 3
reedsStep d = 5
reedsStep e = 14
reedsStep f = 2
reedsStep g = 6
reedsStep h = 5
reedsStep i = 14
reedsStep k = 15
reedsStep l = 20
reedsStep m = 22
reedsStep n = 14
reedsStep o = 8
reedsStep p = 13
reedsStep q = 20
reedsStep r = 11
reedsStep s = 8
reedsStep t = 8
reedsStep u = 15
reedsStep x = 15
reedsStep y = 15
reedsStep z = 2

-- Exhaustive, finite proof for all 23 possible letters.
verse-reeds-invariant : (w : Letter) → verseStep w ≡ reedsStep w
verse-reeds-invariant a = refl
verse-reeds-invariant b = refl
verse-reeds-invariant c = refl
verse-reeds-invariant d = refl
verse-reeds-invariant e = refl
verse-reeds-invariant f = refl
verse-reeds-invariant g = refl
verse-reeds-invariant h = refl
verse-reeds-invariant i = refl
verse-reeds-invariant k = refl
verse-reeds-invariant l = refl
verse-reeds-invariant m = refl
verse-reeds-invariant n = refl
verse-reeds-invariant o = refl
verse-reeds-invariant p = refl
verse-reeds-invariant q = refl
verse-reeds-invariant r = refl
verse-reeds-invariant s = refl
verse-reeds-invariant t = refl
verse-reeds-invariant u = refl
verse-reeds-invariant x = refl
verse-reeds-invariant y = refl
verse-reeds-invariant z = refl

cong : {A B : Set} {x y : A} (fn : A → B) → x ≡ y → fn x ≡ fn y
cong fn refl = refl

-- North + f(West), and top-row West + f(West).
interior : Letter → Letter → Letter
interior north west = advance (verseStep west) north

interiorReeds : Letter → Letter → Letter
interiorReeds north west = advance (reedsStep west) north

interior-equivalence : (north west : Letter) →
  interior north west ≡ interiorReeds north west
interior-equivalence north west =
  cong (λ step → advance step north) (verse-reeds-invariant west)

topCell : Letter → Letter
topCell west = interior west west

top-equivalence : (west : Letter) →
  topCell west ≡ interiorReeds west west
top-equivalence west = interior-equivalence west west

-- A length-indexed vector, defined locally: no external stdlib required.
infixr 5 _∷_
data Vec (A : Set) : Nat → Set where
  []  : Vec A zero
  _∷_ : {j : Nat} → A → Vec A j → Vec A (suc j)

drop1 : {A : Set} {j : Nat} → Vec A (suc j) → Vec A j
drop1 (_ ∷ xs) = xs

-- Generate a top row of length j + 1.
topRow : (j : Nat) → Letter → Vec Letter (suc j)
topRow zero    west = west ∷ []
topRow (suc j) west = west ∷ topRow j (topCell west)

-- Given north neighbors in columns 2..(j+1), build the next row.
fromNorth : {j : Nat} → Letter → Vec Letter j → Vec Letter (suc j)
fromNorth west [] = west ∷ []
fromNorth west (north ∷ norths) =
  west ∷ fromNorth (interior north west) norths

-- Top-row and next-row local rule checks, by definitional equality.
top-first-step : (j : Nat) (west : Letter) →
  topRow (suc j) west ≡ west ∷ topRow j (topCell west)
top-first-step j west = refl

interior-first-step : {j : Nat} (west north : Letter)
  (norths : Vec Letter j) →
  fromNorth west (north ∷ norths) ≡
  west ∷ fromNorth (interior north west) norths
interior-first-step west north norths = refl

-- Six-symbol seed and its involutive reversal.
record Seed : Set where
  constructor seed
  field
    s1 s2 s3 s4 s5 s6 : Letter
open Seed

reverseSeed : Seed → Seed
reverseSeed (seed aa bb cc dd ee ff) = seed ff ee dd cc bb aa

reverse-involution : (s : Seed) → reverseSeed (reverseSeed s) ≡ s
reverse-involution (seed aa bb cc dd ee ff) = refl

-- Historical left margin = (seed ++ reverse seed) repeated three times.
margin : Seed → Vec Letter 36
margin (seed aa bb cc dd ee ff) =
  aa ∷ bb ∷ cc ∷ dd ∷ ee ∷ ff ∷
  ff ∷ ee ∷ dd ∷ cc ∷ bb ∷ aa ∷
  aa ∷ bb ∷ cc ∷ dd ∷ ee ∷ ff ∷
  ff ∷ ee ∷ dd ∷ cc ∷ bb ∷ aa ∷
  aa ∷ bb ∷ cc ∷ dd ∷ ee ∷ ff ∷
  ff ∷ ee ∷ dd ∷ cc ∷ bb ∷ aa ∷ []

-- Rows are generated recursively; both dimensions are 36 by type.
rows : {j : Nat} → Vec Letter (suc j) →
  Vec Letter 36 → Vec (Vec Letter 36) (suc j)
rows (west ∷ []) above = above ∷ []
rows (west ∷ nextWest ∷ rest) above =
  above ∷ rows (nextWest ∷ rest) (newRow nextWest above)
  where
    newRow : Letter → Vec Letter 36 → Vec Letter 36
    newRow w aboveRow = fromNorth w (drop1 aboveRow)

table : Seed → Vec (Vec Letter 36) 36
table sd = rows (margin sd) (topRow 35 (s1 sd))

-- Ground truth from the NISRAM first row: n,d,i,z,b and the dizb cycle.
nisram : Seed
nisram = seed n i s r a m

nisram-prefix : topRow 4 n ≡ n ∷ d ∷ i ∷ z ∷ b ∷ []
nisram-prefix = refl

-- Hand-checked continuation: n, then dizb, then dizb again.
nisram-dizb : topRow 8 n ≡ n ∷ d ∷ i ∷ z ∷ b ∷ d ∷ i ∷ z ∷ b ∷ []
nisram-dizb = refl

-- Hand-checked interior prefix (north tail d,i,z,b and west i):
-- i, s, r, l, y. This is the start of Reeds's second-row lytr motif.
nisram-interior-prefix :
  fromNorth i (d ∷ i ∷ z ∷ b ∷ []) ≡ i ∷ s ∷ r ∷ l ∷ y ∷ []
nisram-interior-prefix = refl

nisram-reversal : reverseSeed nisram ≡ seed m a r s i n
nisram-reversal = refl
