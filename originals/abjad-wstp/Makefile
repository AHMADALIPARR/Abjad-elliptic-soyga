CC ?= cc
CFLAGS ?= -O2 -std=c11 -Wall -Wextra -Werror
WSTP_INCLUDE ?=
WSTP_LIBDIR ?=
WSTP_LIBS ?= -lWSTP64i4 -lm -lpthread -lrt -ldl -luuid -lstdc++
all: abjad-daemon abjad-client
abjad-daemon: src/daemon.c src/abjad.c src/wolfram.c src/protocol.h src/abjad.h
	$(CC) $(CFLAGS) -o $@ src/daemon.c src/abjad.c src/wolfram.c
abjad-client: src/client.c src/protocol.h
	$(CC) $(CFLAGS) -o $@ src/client.c
wstp: src/daemon.c src/abjad.c src/wolfram.c src/protocol.h src/abjad.h
	@test -n "$(WSTP_INCLUDE)" -a -n "$(WSTP_LIBDIR)" || (echo 'Set WSTP_INCLUDE and WSTP_LIBDIR' >&2; exit 1)
	$(CC) $(CFLAGS) -DWITH_WSTP -I"$(WSTP_INCLUDE)" -o abjad-daemon-wstp src/daemon.c src/abjad.c src/wolfram.c -L"$(WSTP_LIBDIR)" $(WSTP_LIBS)
test: all
	sh tests/smoke.sh
clean:
	rm -f abjad-daemon abjad-client abjad-daemon-wstp
.PHONY: all wstp test clean
