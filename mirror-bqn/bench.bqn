#!/usr/bin/env bqn
# SPDX-License-Identifier: AGPL-3.0-only
# SPDX-FileCopyrightText: 2026 The algorithm-cores project contributors
m ← •Import "Mirror.bqn"
_time ← {
  t ← •MonoTime @
  𝔽 @
  (•MonoTime @) - t
}
•Show "bqn bench reps=20 unit=seconds"
•Show "verify-magic-9"
{ 𝕊𝕩: •Show {m.VerifyMagic 9} _time @ }¨ ↕20
•Show "emul-97"
{ 𝕊𝕩: •Show {m.EMul ⟨97,2,3,5,⟨3,6⟩⟩} _time @ }¨ ↕20
