.PHONY: all install

all:
	zensical build --strict --config-file zensical.toml
	zensical build --strict --config-file zensical.ko.toml

install:
	@test -n "$(out)" || { echo "error: out is not set (run inside the Nix build)"; exit 1; }
	mkdir -p $(out)
	cp -r site/. $(out)/
