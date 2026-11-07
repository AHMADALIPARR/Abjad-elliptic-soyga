#!/usr/bin/env bqn
M ← •Import "Mirror.bqn"
! M.VerifyMagic 3
! M.VerifyMagic 5
! M.VerifyMagic 9
! ⟨0,0⟩≡M.TAdd ⟨3,⟨2,2⟩,⟨1,1⟩⟩
! ⟨2,1⟩≡M.TNeg ⟨3,⟨1,2⟩⟩
! ⟨9,⟨3,3⟩⟩≡M.Nested ⟨3,⟨1,1⟩,1⟩
! 1=M.OnCurve ⟨97,2,3,⟨3,6⟩⟩
! ⟨3,91⟩≡M.Mirror ⟨97,⟨3,6⟩⟩
! M.O≡M.EAdd ⟨97,2,3,⟨3,6⟩,⟨3,91⟩⟩
! M.O≡M.EMul ⟨97,2,3,5,⟨3,6⟩⟩
! "infinity"≡⊑M.Trace ⟨97,2,3,⟨3,6⟩,⟨3,6⟩,10,⟨⟩⟩
•Show "All Dee Mirror BQN assertions passed"
