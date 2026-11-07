# Soyga recurrence in Agda

`Soyga.agda` is a self-contained Agda module using only Agda builtins.

## What is proved if Agda accepts the module

- `verse-reeds-invariant`: the proposed f(w) = (V(w)-1) mod 23 reproduces Reeds's independently tabulated offsets for all 23 Latin letters.
- `interior-equivalence`, `top-equivalence`: the proposed rule produces the same cell as Reeds's rule for all north/west inputs.
- `reverse-involution`: reversing a six-letter seed twice is the identity.
- `top-first-step`, `interior-first-step`: row constructors follow the recurrence.
- `table`: produces a 36 × 36 matrix of `Letter` values, structurally ruling out out-of-alphabet cells and wrong dimensions.
- `nisram-prefix`, `nisram-reversal`: finite regression checks.

## How to check

```sh
agda --safe --without-K Soyga.agda
```

No Agda executable was available in the creation environment, so **this module has not been type-checked**. In particular, it is not a claim of machine verification until that command succeeds.

## Historical scope

The proof is conditional on the transcribed Section 18 letter weights and Reeds's empirical table. It verifies equality of *the encoded data and computations*, not the historical provenance of the manuscript or the interpretive claim that the verse originally intended this recurrence. It does not establish geometric mirroring of the matrices.

Sources:
- Jim Reeds, *John Dee and the Magic Tables in the Book of Soyga*.
- Jason Louv, *The Source of Reeds's Function* (June 2026 preprint): https://soyga.magick.me/derivation/
