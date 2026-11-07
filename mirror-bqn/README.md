<!-- SPDX-License-Identifier: AGPL-3.0-only -->
<!-- SPDX-FileCopyrightText: 2026 The algorithm-cores project contributors -->
# Dee Mirror

BQN implementation of the abstract torsion square and of chord-and-tangent arithmetic on `y² = x³ + a x + b`. The design text is `SPECIFICATION.md`, copied from the starter and not edited. `README.original.md` is the starter README.

```sh
bqn test.bqn
bqn test_more.bqn
bqn demo.bqn
```

Current BQN spells subjects in lowercase and functions in uppercase, and a name is one variable. Data exports are `zero` and `o`. Import with `m ← •Import "Mirror.bqn"`.

`Magic n` is `(Z/nZ)²` for odd `n`, with `G(r,c) = (c+r, c+2r)`. `EAdd` is the finite-field group law. They are different domains. `Nested` multiplies abstract coordinates by 3; it does not build Weierstrass coordinates.

The recorded run is CBQN. `test.bqn` is 11 assertions. `test_more.bqn` reports 40. Both passed.
