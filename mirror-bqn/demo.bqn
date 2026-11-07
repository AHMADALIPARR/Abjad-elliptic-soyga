#!/usr/bin/env bqn
# SPDX-License-Identifier: AGPL-3.0-only
# SPDX-FileCopyrightText: 2026 The algorithm-cores project contributors
m ← •Import "Mirror.bqn"
•Show "3x3 torsion magic square"
•Show m.Magic 3
•Show "Identity sums and nine unique points"
•Show m.VerifyMagic 3
•Show "Reflection of (3,6) on y²=x³+2x+3 over F97"
•Show m.Mirror ⟨97, ⟨3, 6⟩⟩
•Show "Recursive chord traversal (fifth step reaches O)"
•Show m.Trace ⟨97, 2, 3, ⟨3, 6⟩, ⟨3, 6⟩, 10, ⟨⟩⟩
•Show "3-torsion embedded in abstract 27-torsion"
•Show m.Nested ⟨3, ⟨1, 1⟩, 2⟩
