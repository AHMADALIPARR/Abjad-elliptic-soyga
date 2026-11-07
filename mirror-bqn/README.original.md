# Dee Mirror — Turing-complete BQN

The exact user-supplied design text is preserved in `SPECIFICATION.md` without edits. `Mirror.bqn` is an executable BQN implementation of its mathematical operations, not pseudocode. BQN is a general-purpose Turing-complete programming language; no claim of infinite recursion without stack/resource limits is implied.

## Execute

```sh
bqn test.bqn
bqn demo.bqn
```

`Mirror.bqn` exports `Magic`, `VerifyMagic`, `Cell`, `TAdd`, `TNeg`, `TSub`, `Lift3`, `Nested`, `O`, `IsO`, `OnCurve`, `Mirror`, `PowMod`, `InvMod`, `EAdd`, `ESub`, `EMul`, `CurvePoints`, `Trace`, and `TTrace`.

### Distinction of mathematical domains

- `Magic n` is a matrix of points of the **abstract group** `(Z/nZ)^2` after choosing a basis for geometric n-torsion. An implicit isomorphism to a specific elliptic curve over an algebraically closed field is **not** the same thing as having constructed explicit coordinates on that curve.
- `EAdd`, `Mirror`, `Trace`, etc. compute genuine chord-and-tangent arithmetic on `y^2 = x^3 + a x + b` over `F_p` for prime `p>3`, discriminant `4a³+27b² != 0 (mod p)` and valid curve points.
- `Nested` models the embedding `E[n] -> E[3n]`, mapping basis coordinates `(a,b)` to `(3a,3b)`; it does not produce coordinates on a Weierstrass curve or a literal subgrid of E[3n].
- Recursion stops at identity, on repetition, or at a maximum depth. Identity is not guaranteed to occur on arbitrary chord operations with arbitrary starting values in a fixed number of steps. The `Trace` step is fixed and therefore periodic on a finite group.
- Historical John Dee mirror associations are **metaphorical**; there is no established Dee procedure equivalent to elliptic group addition.

## Algebraic proof of the magic square

For any positive odd `n`, let `G[r,c] = (r+c,2r+c) mod n` for `0<=r,c<n`. The map `(r,c)->(r+c,2r+c)` has determinant -1, so it is bijective modulo any n. Rows sum to `(0,0)`, columns sum to `(0,0)`, and both diagonals sum to `(0,0)` because `sum(0..n-1) = n(n-1)/2`, divisible by n for odd n. Hence every line of the resulting square has identity sum.

## Verification status

The environment used for creation does not include a BQN executable. Syntax and runtime behavior have **not** been machine-tested in BQN. Mathematical invariants were checked independently using a separate small integer reference computation, but this does not constitute execution/verification of the BQN program.
