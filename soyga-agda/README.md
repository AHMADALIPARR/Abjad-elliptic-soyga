<!-- SPDX-License-Identifier: AGPL-3.0-only -->
<!-- SPDX-FileCopyrightText: 2026 The algorithm-cores project contributors -->
# Soyga recurrence

`Soyga.agda` is checked with Agda's own checker:

```sh
agda --safe --without-K Soyga.agda
```

Agda 2.6.3 accepts this file. The options in the file are `--safe` and `--without-K`. There are no postulates and no termination pragmas. Letter constructors cannot be reused as pattern variables; binders that collided with them were renamed. The equalities are `refl`.

That command is the proof check. The Julia tests in `julia/test/runtests.jl` recompute tables and compare letter counts. They are not Agda proofs and they do not extend what the checker accepted.

Historical scope is unchanged: the development checks the encoded weights and the recurrence, not the manuscript's provenance and not a geometric mirror claim.
