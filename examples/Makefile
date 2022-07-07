#/usr/bin/make -f

CFLAGS+=$(shell pkg-config --cflags node) $(shell pkg-config --cflags node-addon-api)

all: libnode-napi-example-cc libnode-napi-example-c

clean:
	rm -f libnode-napi-example-cc libnode-napi-example-c

% :: %.c
	$(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@

% :: %.cc
	$(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@
