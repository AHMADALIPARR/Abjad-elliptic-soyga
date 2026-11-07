# SPDX-License-Identifier: AGPL-3.0-only
# SPDX-FileCopyrightText: 2026 The algorithm-cores project contributors
CC ?= cc
CFLAGS ?= -O2 -std=c11 -Wall -Wextra -Werror
WSTP_INCLUDE ?=
WSTP_LIBDIR ?=
WSTP_LIBS ?= -lWSTP64i4 -lm -lpthread -lrt -ldl -luuid -lstdc++
all: abjad-daemon abjad-client tests/suite tests/bench
abjad-daemon: src/daemon.c src/abjad.c src/wolfram.c src/protocol.h src/abjad.h
	$(CC) $(CFLAGS) -o $@ src/daemon.c src/abjad.c src/wolfram.c
abjad-client: src/client.c src/protocol.h
	$(CC) $(CFLAGS) -o $@ src/client.c
wstp: src/daemon.c src/abjad.c src/wolfram.c src/protocol.h src/abjad.h
	@test -n "$(WSTP_INCLUDE)" -a -n "$(WSTP_LIBDIR)" || (echo 'Set WSTP_INCLUDE and WSTP_LIBDIR' >&2; exit 1)
	$(CC) $(CFLAGS) -DWITH_WSTP -I"$(WSTP_INCLUDE)" -o abjad-daemon-wstp src/daemon.c src/abjad.c src/wolfram.c -L"$(WSTP_LIBDIR)" $(WSTP_LIBS)
tests/suite: tests/suite.c src/abjad.c src/protocol.h src/abjad.h
	$(CC) $(CFLAGS) -o $@ tests/suite.c src/abjad.c
tests/bench: tests/bench.c src/abjad.c src/abjad.h
	$(CC) $(CFLAGS) -o $@ tests/bench.c src/abjad.c
test: all
	sh tests/smoke.sh
	./tests/suite
clean:
	rm -f abjad-daemon abjad-client abjad-daemon-wstp tests/suite tests/bench
.PHONY: all wstp test clean
