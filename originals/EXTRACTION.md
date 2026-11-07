<!-- SPDX-License-Identifier: AGPL-3.0-only -->
<!-- SPDX-FileCopyrightText: 2026 The algorithm-cores project contributors -->

# Extraction record

The four uploaded zip archives were listed with `zipinfo` before extraction.
Every entry was a regular file or directory. There were no symlink entries,
absolute paths, or `..` components. Extraction used `unzip` into a temporary
directory, rejected any symlink created on disk, and checked that every
real path stayed inside that directory. The archive members under this directory are those zip entries and are
byte-identical to `MANIFEST.sha256`. `EXTRACTION.md`, `PROVENANCE.txt`, and
`MANIFEST.sha256.license` were added later and are not archive members.

`MANIFEST.sha256` is the SHA-256 of those members. The archives did not
include a license. This tree does not add one.
