#!/usr/bin/env bqn
# SPDX-License-Identifier: AGPL-3.0-only
# SPDX-FileCopyrightText: 2026 The algorithm-cores project contributors
# Boundary, known-vector, and malformed-input tests for Mirror.bqn.
# Executable checks only; they are not a machine-checked proof.
m ← •Import "Mirror.bqn"
pass ← 0
Ok ← { ! 𝕩 ⋄ pass +↩ 1 }
_bad ← { ! 1 ≡ 𝔽⎊{1⊣𝕩} 𝕩 ⋄ pass +↩ 1 }

Ok m.VerifyMagic 1
Ok m.VerifyMagic 3
Ok m.VerifyMagic 7
Ok m.VerifyMagic 11
(m.Magic _bad) 2
(m.Magic _bad) 0
(m.Magic _bad) 1.5
(m.Magic _bad) ¯1

Ok ⟨1, 2⟩ ≡ m.Cell ⟨3, 1, 0⟩
Ok ⟨0, 0⟩ ≡ m.TAdd ⟨5, ⟨4, 1⟩, ⟨1, 4⟩⟩
Ok ⟨1, 4⟩ ≡ m.TSub ⟨5, ⟨0, 0⟩, ⟨4, 1⟩⟩
Ok ⟨5, ⟨1, 1⟩⟩ ≡ m.Nested ⟨5, ⟨1, 1⟩, 0⟩
Ok ⟨27, ⟨9, 9⟩⟩ ≡ m.Nested ⟨3, ⟨1, 1⟩, 2⟩
(m.Nested _bad) ⟨3, ⟨1, 1⟩, ¯1⟩

Ok 31 ≡ m.Discriminant ⟨97, 1, 1⟩
Ok 0 ≡ m.Discriminant ⟨5, ¯3, 2⟩

Ok 1 = m.OnCurve ⟨5, 0, 1, ⟨0, 1⟩⟩
Ok ⟨0, 4⟩ ≡ m.EAdd ⟨5, 0, 1, ⟨0, 1⟩, ⟨0, 1⟩⟩
Ok m.o ≡ m.EMul ⟨5, 0, 1, 3, ⟨0, 1⟩⟩
Ok ⟨0, 1⟩ ≡ m.EAdd ⟨5, 0, 1, m.o, ⟨0, 1⟩⟩
Ok m.o ≡ m.EAdd ⟨5, 0, 1, ⟨0, 1⟩, ⟨0, 4⟩⟩
pts ← m.CurvePoints ⟨5, 0, 1⟩
Ok 6 = ≠ pts
Ok m.o ≡ ⊑ pts
want ← ⟨⟨4, 0⟩, ⟨0, 1⟩, ⟨0, 4⟩, ⟨2, 3⟩, ⟨2, 2⟩⟩
Ok ∧´ {p ← 𝕩 ⋄ ∨´ {p≡𝕩}¨ 1↓pts}¨ want
Ok 5 = ≠ 1↓ pts

(m.EAdd _bad) ⟨5, ¯3, 2, ⟨0, 0⟩, ⟨0, 0⟩⟩
(m.EAdd _bad) ⟨9, 0, 1, ⟨0, 1⟩, ⟨0, 1⟩⟩
(m.CurvePoints _bad) ⟨4, 0, 1⟩
(m.CurvePoints _bad) ⟨257, 0, 1⟩

Ok ⟨3, 6⟩ ≡ m.Mirror ⟨97, m.Mirror ⟨97, ⟨3, 6⟩⟩⟩
Ok 1 ≡ 97 | 3 × m.InvMod ⟨97, 3⟩
Ok 54 ≡ m.PowMod ⟨97, 2, 10⟩
(m.InvMod _bad) ⟨97, 0⟩
(m.PowMod _bad) ⟨97, 2, ¯1⟩

Ok "infinity" ≡ ⊑ m.Trace ⟨97, 2, 3, ⟨3, 6⟩, ⟨3, 6⟩, 10, ⟨⟩⟩
Ok "depth" ≡ ⊑ m.Trace ⟨97, 2, 3, ⟨3, 6⟩, ⟨3, 6⟩, 0, ⟨⟩⟩
Ok "cycle" ≡ ⊑ m.TTrace ⟨5, ⟨1, 0⟩, ⟨0, 0⟩, 5, ⟨⟩⟩
Ok "infinity" ≡ ⊑ m.TTrace ⟨3, ⟨1, 0⟩, ⟨1, 0⟩, 5, ⟨⟩⟩
(m.Trace _bad) ⟨97, 2, 3, ⟨3, 6⟩, ⟨3, 6⟩, 1025, ⟨⟩⟩
(m.EAdd _bad) ⟨97, 2, 3, ⟨3, 6⟩, ⟨1, 2⟩⟩

•Show "BQN extended tests passed: " ∾ •Fmt pass
