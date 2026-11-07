#!/usr/bin/env bqn
M ← •Import "Mirror.bqn"
•Show "3x3 torsion magic square"
•Show M.Magic 3
•Show "Identity sums and nine unique points"
•Show M.VerifyMagic 3
•Show "Reflection of (3,6) on y²=x³+2x+3 over F97"
•Show M.Mirror ⟨97,⟨3,6⟩⟩
•Show "Recursive chord traversal (fifth step reaches O)"
•Show M.Trace ⟨97,2,3,⟨3,6⟩,⟨3,6⟩,10,⟨⟩⟩
•Show "3-torsion embedded in abstract 27-torsion"
•Show M.Nested ⟨3,⟨1,1⟩,2⟩
