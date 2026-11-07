<!-- SPDX-License-Identifier: AGPL-3.0-only -->
<!-- SPDX-FileCopyrightText: 2026 The algorithm-cores project contributors -->
# Abjad WSTP binary RPC bridge

A real C Unix-domain socket RPC daemon. It has two backends: `local` (standalone integer reference implementation) and `wstp` (evaluates the identical Abjad operation directly in a Wolfram kernel using WSTP). No notebooks, shell subprocess per request, JSON, or expression-string interpolation.

## Build and test locally (Linux / POSIX)

```sh
make
make test
./abjad-daemon local /tmp/abjad.sock &
./abjad-client /tmp/abjad.sock 'الله'
# 66
```

## Build the actual WSTP backend

Requires installed Wolfram Engine/Mathematica and matching WSTP Developer Kit. On Linux the SDK's `CompilerAdditions` folder contains `wstp.h` and `libWSTP64i4`.

```sh
make wstp WSTP_INCLUDE=/path/to/CompilerAdditions WSTP_LIBDIR=/path/to/CompilerAdditions
./abjad-daemon-wstp wstp /tmp/abjad.sock 'WolframKernel -wstp' "$PWD/wolfram/AbjadRPC.wl"
./abjad-client /tmp/abjad.sock 'محمد'
# 92
```

If your installation uses a different kernel executable or linker dependencies, adjust `WSTP_LIBS` and kernel command. WSTP backend has not been compiled or runtime-tested without the proprietary SDK/Engine. The daemon uses one shared kernel link and processes connections serially by design.

## Binary protocol v1

All integer fields big-endian. Request: `magic:u32=0x41424a44, version:u16=1, operation:u16=1, request_id:u32, payload_length:u32, payload:UTF-8`. Response: same 16-byte header, with `operation` replaced by status (0=OK, 1=bad input, 2=backend failure); payload exactly 8 bytes unsigned big-endian Abjad total. Maximum request payload 65536 bytes. Multiple requests per socket connection supported. Accepts only local Unix domain socket connections; secure the socket's parent directory for multiuser systems. No authentication or internet listener.

## Numerology convention

Traditional Eastern *abjad kabir*: `ابجد هوز حطي كلمن سعفص قرشت ثخذ ضظغ`. Diacritics, punctuation, spaces and non-Arabic characters are ignored; input containing **no recognized Arabic letters** is rejected. `أ إ آ ٱ -> ا`, `ى -> ي`, `ة -> ه`. Hamza on its own is ignored. Arabic text is required, not automatically transliterated from English. Other conventions can produce different totals. This is a symbolic/cultural numeric scheme, not a cryptographic or predictive algorithm.

## Safety and production limitations

The local daemon now sets socket mode 0600, receive and send timeouts (`ABJAD_TIMEOUT_MS`, default 5000), and a per-connection request cap (`ABJAD_MAX_REQUESTS`, default 1024). `EINTR` is retried. A bad frame closes the connection without allocating an oversize payload. `make test` runs `tests/smoke.sh` and `tests/suite`. On the recorded run the suite reported `checks=924 failures=0`.

WSTP still needs the proprietary SDK. `make wstp` without `WSTP_INCLUDE` and `WSTP_LIBDIR` exits. The binary built without `-DWITH_WSTP` rejects `wstp` mode before `bind`. The Julia program `julia/bin/abjad_daemon.jl` speaks the same framing and was exercised with `abjad-client`. It does not replace `wolfram.c`.
