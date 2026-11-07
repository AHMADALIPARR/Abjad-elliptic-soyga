<!-- SPDX-License-Identifier: AGPL-3.0-only -->
<!-- SPDX-FileCopyrightText: 2026 The algorithm-cores project contributors -->

# File audit

Every path below was inspected for this license pass. Project-owned source carries `SPDX-License-Identifier: AGPL-3.0-only` and `SPDX-FileCopyrightText: 2026 The algorithm-cores project contributors` in the comment syntax of that language. AGPL-3.0-only means version 3 only. The "How to Apply" section inside `LICENSE` is the Free Software Foundation's boilerplate and is not a grant of "or any later version" for this project.

Starter bytes under `originals/` and `uploads/` are unchanged archive material. They had no license. Adding a header would change those bytes, so they are not relicensed by editing. Working-tree derivatives are the AGPL files.

Inline headers are omitted when they would change a checksum list, a preserved starter text, a generated log, a lockfile of third-party standard libraries, or a binary. Those cases have sidecars or the row below.

## Transfer exclusions

The public repository already contained `LICENSE`, the Free Software Foundation's verbatim GNU AGPL version 3 (initial commit `9c26152e1ddaa8d2feb38b7fa4b13babfe7f41b6`). The imported archive also contained a file named `LICENSE`. That copy is a whitespace-reflowed restatement, 235 lines, and is not the verbatim license document. The license text itself says changing it is not allowed. The committed `LICENSE` is the repository file, byte-for-byte. No other archive member was dropped.

`elliptic-neuroregex/docs/` and `originals/elliptic-neuroregex/docs/` are empty directories in the elliptic starter zip and in the source archive. Git does not store empty directories. No file lived under either path.

The archive contained no nested `.git`, no object files, no caches, and no secret material. Those categories were checked and were already absent, so nothing of that kind was stripped. Build products named in `.gitignore` stay untracked.

| Path | Class |
| --- | --- |
| `.github/workflows/ci.yml` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. GitHub Actions workflow for the C, BQN, Agda, and Julia suites. It does not run Wolfram. |
| `.gitignore` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `LICENSE` | FSF verbatim AGPL-3.0 text kept from the repository's initial commit. Not project copyright. No extra SPDX banner. The archive's reflowed copy was not committed over it. |
| `NOTICE` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `README.md` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `abjad-wstp/Makefile` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `abjad-wstp/README.md` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `abjad-wstp/abjad-client` | Local build or Agda interface output. Gitignored. Not part of the source license grant. |
| `abjad-wstp/abjad-daemon` | Local build or Agda interface output. Gitignored. Not part of the source license grant. |
| `abjad-wstp/src/abjad.c` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `abjad-wstp/src/abjad.h` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `abjad-wstp/src/client.c` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `abjad-wstp/src/daemon.c` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `abjad-wstp/src/protocol.h` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `abjad-wstp/src/wolfram.c` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `abjad-wstp/tests/bench` | Local build or Agda interface output. Gitignored. Not part of the source license grant. |
| `abjad-wstp/tests/bench.c` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `abjad-wstp/tests/smoke.sh` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `abjad-wstp/tests/suite` | Local build or Agda interface output. Gitignored. Not part of the source license grant. |
| `abjad-wstp/tests/suite.c` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `abjad-wstp/wolfram/AbjadRPC.wl` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `benchmarks/SPDX-EXCEPTION.txt` | Project-owned sidecar. SPDX-License-Identifier: AGPL-3.0-only. Does not alter the logs it describes. |
| `benchmarks/abjad-c-raw.txt` | Recorded command output. Inline header omitted so the record stays the record. |
| `benchmarks/bqn-raw.txt` | Recorded command output. Inline header omitted so the record stays the record. |
| `benchmarks/environment.txt` | Recorded command output. Inline header omitted so the record stays the record. |
| `benchmarks/julia-raw.txt` | Recorded command output. Inline header omitted so the record stays the record. |
| `benchmarks/verification.txt` | Recorded command output. Inline header omitted so the record stays the record. |
| `dist/algorithms-source.zip` | Built source archive. Regenerated after license headers. Not a source file. |
| `docs/ALGORITHMS.md` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `docs/SECURITY.md` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `docs/STUB_LEDGER.md` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `elliptic-neuroregex/Makefile` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `elliptic-neuroregex/README.md` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `elliptic-neuroregex/rpc-client` | Local build or Agda interface output. Gitignored. Not part of the source license grant. |
| `elliptic-neuroregex/src/native_math.c` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `elliptic-neuroregex/src/native_math.h` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `elliptic-neuroregex/src/rpc_client.c` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `elliptic-neuroregex/src/wstp_daemon.c` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `elliptic-neuroregex/tests/math_reference.c` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `elliptic-neuroregex/tests/native_suite` | Local build or Agda interface output. Gitignored. Not part of the source license grant. |
| `elliptic-neuroregex/tests/native_suite.c` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `elliptic-neuroregex/tests/test.wls` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `elliptic-neuroregex/wl/NeuroRegex.wl` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `examples/e2e.txt` | Recorded command output. Inline header omitted so the record stays the record. |
| `examples/e2e.txt.license` | Project-owned sidecar. SPDX-License-Identifier: AGPL-3.0-only. Does not alter `examples/e2e.txt`. |
| `julia/Manifest.toml` | Generated Julia lockfile. Does not relicense the MIT standard libraries it names. Sidecar: julia/Manifest.toml.license. |
| `julia/Manifest.toml.license` | Project-owned sidecar. SPDX-License-Identifier: AGPL-3.0-only. Does not alter `julia/Manifest.toml` and does not relicense the Julia standard libraries. |
| `julia/Project.toml` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `julia/bench/run.jl` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `julia/bin/abjad_daemon.jl` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `julia/bin/neuro_daemon.jl` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `julia/src/Algorithms.jl` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `julia/src/abjad.jl` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `julia/src/elliptic.jl` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `julia/src/jsonutil.jl` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `julia/src/neuro.jl` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `julia/src/rpc.jl` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `julia/src/soyga.jl` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `julia/test/runtests.jl` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `mirror-bqn/Mirror.bqn` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `mirror-bqn/README.md` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `mirror-bqn/README.original.md` | Byte-identical to the matching file in originals/. SPDX sidecar instead of an inline header. |
| `mirror-bqn/README.original.md.license` | SPDX sidecar or documented exception. Does not alter the file it describes. |
| `mirror-bqn/SPECIFICATION.md` | Byte-identical to the matching file in originals/. SPDX sidecar instead of an inline header. |
| `mirror-bqn/SPECIFICATION.md.license` | SPDX sidecar or documented exception. Does not alter the file it describes. |
| `mirror-bqn/bench.bqn` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `mirror-bqn/demo.bqn` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `mirror-bqn/test.bqn` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `mirror-bqn/test_more.bqn` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `originals/EXTRACTION.md` | Project note inside the provenance directory. Not an archive member. |
| `originals/MANIFEST.sha256` | sha256sum list of archive members. No inline comment, so sha256sum -c stays valid. Sidecar: originals/MANIFEST.sha256.license. |
| `originals/MANIFEST.sha256.license` | Project note inside the provenance directory. Not an archive member. SPDX-License-Identifier: AGPL-3.0-only. |
| `originals/Mirror.bqn` | Unmodified starter member. Checksum in originals/MANIFEST.sha256. No AGPL header added. |
| `originals/PROVENANCE.txt` | Project note inside the provenance directory. Not an archive member. SPDX-License-Identifier: AGPL-3.0-only. |
| `originals/README.md` | Unmodified starter member. Checksum in originals/MANIFEST.sha256. No AGPL header added. |
| `originals/SPECIFICATION.md` | Unmodified starter member. Checksum in originals/MANIFEST.sha256. No AGPL header added. |
| `originals/abjad-wstp/Makefile` | Unmodified starter member. Checksum in originals/MANIFEST.sha256. No AGPL header added. |
| `originals/abjad-wstp/README.md` | Unmodified starter member. Checksum in originals/MANIFEST.sha256. No AGPL header added. |
| `originals/abjad-wstp/src/abjad.c` | Unmodified starter member. Checksum in originals/MANIFEST.sha256. No AGPL header added. |
| `originals/abjad-wstp/src/abjad.h` | Unmodified starter member. Checksum in originals/MANIFEST.sha256. No AGPL header added. |
| `originals/abjad-wstp/src/client.c` | Unmodified starter member. Checksum in originals/MANIFEST.sha256. No AGPL header added. |
| `originals/abjad-wstp/src/daemon.c` | Unmodified starter member. Checksum in originals/MANIFEST.sha256. No AGPL header added. |
| `originals/abjad-wstp/src/protocol.h` | Unmodified starter member. Checksum in originals/MANIFEST.sha256. No AGPL header added. |
| `originals/abjad-wstp/src/wolfram.c` | Unmodified starter member. Checksum in originals/MANIFEST.sha256. No AGPL header added. |
| `originals/abjad-wstp/tests/smoke.sh` | Unmodified starter member. Checksum in originals/MANIFEST.sha256. No AGPL header added. |
| `originals/abjad-wstp/wolfram/AbjadRPC.wl` | Unmodified starter member. Checksum in originals/MANIFEST.sha256. No AGPL header added. |
| `originals/demo.bqn` | Unmodified starter member. Checksum in originals/MANIFEST.sha256. No AGPL header added. |
| `originals/elliptic-neuroregex/Makefile` | Unmodified starter member. Checksum in originals/MANIFEST.sha256. No AGPL header added. |
| `originals/elliptic-neuroregex/README.md` | Unmodified starter member. Checksum in originals/MANIFEST.sha256. No AGPL header added. |
| `originals/elliptic-neuroregex/src/rpc_client.c` | Unmodified starter member. Checksum in originals/MANIFEST.sha256. No AGPL header added. |
| `originals/elliptic-neuroregex/src/wstp_daemon.c` | Unmodified starter member. Checksum in originals/MANIFEST.sha256. No AGPL header added. |
| `originals/elliptic-neuroregex/tests/math_reference.c` | Unmodified starter member. Checksum in originals/MANIFEST.sha256. No AGPL header added. |
| `originals/elliptic-neuroregex/tests/test.wls` | Unmodified starter member. Checksum in originals/MANIFEST.sha256. No AGPL header added. |
| `originals/elliptic-neuroregex/wl/NeuroRegex.wl` | Unmodified starter member. Checksum in originals/MANIFEST.sha256. No AGPL header added. |
| `originals/soyga-agda/README.md` | Unmodified starter member. Checksum in originals/MANIFEST.sha256. No AGPL header added. |
| `originals/soyga-agda/Soyga.agda` | Unmodified starter member. Checksum in originals/MANIFEST.sha256. No AGPL header added. |
| `originals/test.bqn` | Unmodified starter member. Checksum in originals/MANIFEST.sha256. No AGPL header added. |
| `scripts/examples.sh` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `scripts/test-all.sh` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `soyga-agda/README.md` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `soyga-agda/Soyga.agda` | Project-owned. Inline SPDX-License-Identifier: AGPL-3.0-only. |
| `soyga-agda/Soyga.agdai` | Local build or Agda interface output. Gitignored. Not part of the source license grant. |
| `uploads/0576927637a405a56a86bfef7a95cc1279cedcd8019c21b40ab0baefb7f5342c_291a.zip` | Unmodified upload. No license inside. Not edited. Not relicensed. |
| `uploads/10e4ebc6065640ebd966aecffb6d9d1c11f720f04da572cec8dbf2c828b45939_c524.zip` | Unmodified upload. No license inside. Not edited. Not relicensed. |
| `uploads/18047e3e7a3b2288ee57543dc8b24df8006039cb96a11874ec4062fd8833e7fc_f1ea.zip` | Unmodified upload. No license inside. Not edited. Not relicensed. |
| `uploads/2193bff8c7f23389e696044302b63e7533e9e51526d5bae74423dd276ca4a098_ba58.zip` | Unmodified upload. No license inside. Not edited. Not relicensed. |
| `uploads/PROVENANCE.txt` | Project note beside the archives. Does not change zip bytes. SPDX-License-Identifier: AGPL-3.0-only. |

`docs/FILE_AUDIT.md` is this file and is project-owned under the header above. It is written after the path list is collected, so it is not a row in the table.
