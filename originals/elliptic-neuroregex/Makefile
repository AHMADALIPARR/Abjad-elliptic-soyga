CC ?= cc
CFLAGS ?= -O2 -std=c11 -Wall -Wextra -Werror
# Supply WSTP_INCLUDE and WSTP_LIBS from YOUR installed Wolfram SDK.
WSTP_INCLUDE ?=
WSTP_LIBS ?=
all: rpc-client
rpc-client: src/rpc_client.c
	$(CC) $(CFLAGS) $< -o $@
wstp-daemon: src/wstp_daemon.c
	@test -n "$(WSTP_INCLUDE)" -a -n "$(WSTP_LIBS)" || (echo "Supply WSTP_INCLUDE='-I...' WSTP_LIBS='-L... -lWSTP64i4 ...'"; exit 1)
	$(CC) $(CFLAGS) $(WSTP_INCLUDE) $< -o $@ $(WSTP_LIBS)
wl-test:
	wolframscript -file tests/test.wls
clean:
	rm -f rpc-client wstp-daemon
.PHONY: all wl-test clean
test-native: rpc-client tests/math_reference.c
	$(CC) $(CFLAGS) tests/math_reference.c -o /tmp/elliptic-neuroregex-test
	/tmp/elliptic-neuroregex-test
