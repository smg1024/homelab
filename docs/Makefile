.PHONY: all install clean

all:
	zensical build --strict --config-file mkdocs.yml
	zensical build --strict --config-file mkdocs.ko.yml

install:
	@test -n "$(out)" || { echo "error: out is not set (run inside the Nix build)"; exit 1; }
	mkdir -p $(out)
	cp -r site/. $(out)/

clean:
	rm -rf site
