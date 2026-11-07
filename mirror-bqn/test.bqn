#!/usr/bin/env bqn
# SPDX-License-Identifier: AGPL-3.0-only
# SPDX-FileCopyrightText: 2026 The algorithm-cores project contributors
m ← •Import "Mirror.bqn"
! m.VerifyMagic 3
! m.VerifyMagic 5
! m.VerifyMagic 9
! ⟨0, 0⟩ ≡ m.TAdd ⟨3, ⟨2, 2⟩, ⟨1, 1⟩⟩
! ⟨2, 1⟩ ≡ m.TNeg ⟨3, ⟨1, 2⟩⟩
! ⟨9, ⟨3, 3⟩⟩ ≡ m.Nested ⟨3, ⟨1, 1⟩, 1⟩
! 1 = m.OnCurve ⟨97, 2, 3, ⟨3, 6⟩⟩
! ⟨3, 91⟩ ≡ m.Mirror ⟨97, ⟨3, 6⟩⟩
! m.o ≡ m.EAdd ⟨97, 2, 3, ⟨3, 6⟩, ⟨3, 91⟩⟩
! m.o ≡ m.EMul ⟨97, 2, 3, 5, ⟨3, 6⟩⟩
! "infinity" ≡ ⊑ m.Trace ⟨97, 2, 3, ⟨3, 6⟩, ⟨3, 6⟩, 10, ⟨⟩⟩
•Show "All Dee Mirror BQN assertions passed"
