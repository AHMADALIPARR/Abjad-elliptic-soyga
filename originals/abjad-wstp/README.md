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

WSTP message reception is blocking and has no request timeout in this reference. The kernel link is single-threaded; use one daemon per kernel for concurrency. Restrict socket permissions by running inside a directory with suitable permissions. The WSTP path and SDK must be provided by the operator. Operations are hard-coded; clients cannot supply arbitrary Wolfram code.
