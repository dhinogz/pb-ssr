.DEFAULT_GOAL := build

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: deps
deps: # Installs templ and and npm dependencies
	go install github.com/a-h/templ/cmd/templ@latest
	npm install

.PHONY: templ
templ: # Generate templ files
	templ generate

.PHONY: assets
assets: # Generate CSS based on templ files
	npx tailwindcss -m -i ./assets/tailwind.css -o ./assets/dist/styles.min.css

.PHONY: embed
embed: templ assets # Embed generated assets
	go generate ./...

.PHONY: build
build: embed # Generate, embed and build with proper flags
	go build -ldflags="-s -w" -o ptht

.PHONY: run
run: templ assets # Run the server
	go run main.go serve

.PHONY: lint
lint:
	golangci-lint run ./...
	deadcode -generated .

# =============
# = Live Mode =
# =============

.PHONY: live/assets
live/assets:
	npx tailwindcss -m -i ./assets/tailwind.css -o ./assets/dist/styles.min.css --watch

.PHONY: live/wgo
live/wgo:
	wgo -file .go -xfile=_templ.go go run main.go serve :: \
	wgo -file .css templ generate --notify-proxy

.PHONY: live/proxy
live/proxy:
	templ generate --watch --proxy="http://127.0.0.1:8090" --open-browser=false

.PHONY: live
live:
	$(MAKE) --no-print-directory -j3 live/assets live/proxy live/wgo

# =============
# = Migrations =
# =============
migrate:
	go run main.go migrate collections

migrate/sync:
	go run main.go migrate history-sync
