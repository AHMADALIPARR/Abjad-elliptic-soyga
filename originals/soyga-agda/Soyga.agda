{-# OPTIONS --safe --without-K #-}
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
advance zero     w = w
advance (suc n)  w = next (advance n w)

-- Modular arithmetic by cycling the residues 0 ... 22.
-- Avoids an unchecked integer-to-letter conversion.
nextResidue : Nat → Nat
nextResidue 22 = 0
nextResidue n  = suc n

mod23 : Nat → Nat
mod23 zero    = zero
mod23 (suc n) = nextResidue (mod23 n)

pred : Nat → Nat
pred zero = zero
pred (suc n) = n

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

cong : {A B : Set} {x y : A} (f : A → B) → x ≡ y → f x ≡ f y
cong f refl = refl

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
  _∷_ : {n : Nat} → A → Vec A n → Vec A (suc n)

-- Generate a top row of length n + 1.
topRow : (n : Nat) → Letter → Vec Letter (suc n)
topRow zero west = west ∷ []
topRow (suc n) west = west ∷ topRow n (topCell west)

-- Given north neighbors in columns 2..(n+1), build the next row.
fromNorth : {n : Nat} → Letter → Vec Letter n → Vec Letter (suc n)
fromNorth west [] = west ∷ []
fromNorth west (north ∷ norths) =
  west ∷ fromNorth (interior north west) norths

-- Top-row and next-row local rule checks, by definitional equality.
top-first-step : (n : Nat) (west : Letter) →
  topRow (suc n) west ≡ west ∷ topRow n (topCell west)
top-first-step n west = refl

interior-first-step : {n : Nat} (west north : Letter)
  (norths : Vec Letter n) →
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
reverseSeed (seed p q r s t u) = seed u t s r q p

reverse-involution : (s : Seed) → reverseSeed (reverseSeed s) ≡ s
reverse-involution (seed p q r s t u) = refl

-- Historical left margin = (seed ++ reverse seed) repeated three times.
margin : Seed → Vec Letter 36
margin (seed p q r s t u) =
  p ∷ q ∷ r ∷ s ∷ t ∷ u ∷
  u ∷ t ∷ s ∷ r ∷ q ∷ p ∷
  p ∷ q ∷ r ∷ s ∷ t ∷ u ∷
  u ∷ t ∷ s ∷ r ∷ q ∷ p ∷
  p ∷ q ∷ r ∷ s ∷ t ∷ u ∷
  u ∷ t ∷ s ∷ r ∷ q ∷ p ∷ []

-- Rows are generated recursively; both dimensions are 36 by type.
rows : {n : Nat} → Vec Letter (suc n) →
  Vec Letter 36 → Vec (Vec Letter 36) (suc n)
rows (west ∷ []) above = above ∷ []
rows (west ∷ nextWest ∷ rest) above =
  above ∷ rows (nextWest ∷ rest) (newRow nextWest above)
  where
    newRow : Letter → Vec Letter 36 → Vec Letter 36
    newRow w (_ ∷ northTail) = fromNorth w northTail

table : Seed → Vec (Vec Letter 36) 36
table s = rows (margin s) (topRow 35 (s1 s))

-- Ground truth from the NISRAM first row: n,d,i,z,b.
nisram : Seed
nisram = seed n i s r a m

nisram-prefix : topRow 4 n ≡ n ∷ d ∷ i ∷ z ∷ b ∷ []
nisram-prefix = refl

nisram-reversal : reverseSeed nisram ≡ seed m a r s i n
nisram-reversal = refl
