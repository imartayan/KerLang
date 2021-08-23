.PHONY: all
all:
	@ dune build
	@ cp -f _build/default/bin/gklc.exe gklc
clean:
	@ $(RM) -r _build gklc