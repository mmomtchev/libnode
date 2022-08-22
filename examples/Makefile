#/usr/bin/make -f

CFLAGS+=-g $(shell pkg-config --cflags node) $(shell pkg-config --cflags node-addon-api)
LDFLAGS+=$(shell pkg-config --libs node)

EXAMPLES=libnode-napi-example-cc libnode-napi-example-c \
	axios-example axios-example-es6 debugger-example \
	stdio-redir-example

all: $(EXAMPLES)
	@echo Do not forget npm install

clean:
	rm -f $(EXAMPLES)

% :: %.c
	$(CC) $(CFLAGS) $< -o $@ $(LDFLAGS)

% :: %.cc
	$(CXX) $(CFLAGS) $(CPPFLAGS) $< -o $@ $(LDFLAGS)
