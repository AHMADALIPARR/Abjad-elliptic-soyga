<!-- SPDX-License-Identifier: AGPL-3.0-only -->
<!-- SPDX-FileCopyrightText: 2026 The algorithm-cores project contributors -->
# Security and resource limits

These programs are local calculators. They are not a network service and not a proof of cryptographic strength.

## Sockets

- Address family is `AF_UNIX` only. There is no TCP listen path.
- The socket mode is `0600`. `ABJAD_SOCKET_MODE`, if set, must be the string `0600`.
- The path must be non-empty and fit in `sun_path`. An existing path is refused rather than unlinked.
- One accepted client is served at a time. A second client waits.
- Receive and send timeouts default to 5 seconds (`ABJAD_TIMEOUT_MS`, `NEURO_TIMEOUT_MS`, range 1..120000 ms for the C daemon).
- Abjad allows at most 1024 requests per connection (`ABJAD_MAX_REQUESTS`).
- Payload caps: Abjad 65536 bytes, NeuroRegex 1 MiB, operation name at most 64 bytes.
- A bad magic, bad version, or oversize length closes the connection and does not allocate the claimed size.
- `SIGPIPE` is ignored. `EINTR` is retried. The listening descriptor is close-on-exec.

## What is not evaluated

- Abjad operations are the integer 1. The Wolfram path, when the SDK is present, calls `AbjadRPC`AbjadValue` on a byte string. It does not splice the string into Wolfram source.
- NeuroRegex `Dispatch` allowlists `magic`, `magicSquare`, `checkMagic`, `checkSquares`, `curvePoints`, `loadCorpus`, `query`, and `search`.
- JSON objects with duplicate keys are rejected by the Julia parser.
- Regex patterns are not passed to a shell.

## Regex

PCRE2 is compiled with UTF and UCP, without JIT, with match limit 100000 and depth limit 10000. Exceeding a limit, or failing to compile, yields no match. Pattern length above 256 and text length above 100000 characters are rejected before matching. This bounds backtracking. It does not sandbox the rest of the process. Run the daemon only for a local user who is allowed to read the corpus.

## Other caps

- BQN `Magic` requires an odd integer `n` in `1..401`.
- BQN `Trace` and `TTrace` require fuel in `0..1024`.
- BQN `CurvePoints` requires a prime `p` in `5..256`.
- BQN `PowMod` requires modulus and exponent at most `10^7`.
- Curve coefficients in the BQN checker are limited to absolute value `10^12`.
- Soyga seeds must be six letters from the 23-letter alphabet.
- Document corpora: at most 10000 documents, 100000 characters of text, 4096 characters of id.

## Wolfram

The WSTP sources are unchanged in intent. This environment has no Wolfram Engine and no WSTP headers, so those binaries are not built and not executed. The C `wstp` subcommand exits with a startup failure and does not bind a socket. Do not point that subcommand at an untrusted kernel command if you later compile it: the kernel command is an operator argument, not a client argument.
