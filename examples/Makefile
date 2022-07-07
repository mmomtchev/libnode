#/usr/bin/make -f

CFLAGS+=-g $(shell pkg-config --cflags node) $(shell pkg-config --cflags node-addon-api)
LDFLAGS+=$(shell pkg-config --libs node)

all: libnode-napi-example-cc libnode-napi-example-c axios-example

clean:
	rm -f libnode-napi-example-cc libnode-napi-example-c axios-example

% :: %.c
	$(CC) $(CFLAGS) $< -o $@ $(LDFLAGS)

% :: %.cc
	$(CXX) $(CFLAGS) $(CPPFLAGS) $< -o $@ $(LDFLAGS)
