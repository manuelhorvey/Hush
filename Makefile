.PHONY: help dev up down logs rust-check rust-fmt rust-test mobile-analyze mobile-test mobile-clean mobile-get lint check ci

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ─── Docker ────────────────────────────────────────────────────────────────────

dev: ## Start all services in dev mode
	docker compose up --build -d

up: ## Start services (no rebuild)
	docker compose up -d

down: ## Stop all services
	docker compose down

logs: ## Tail logs from all services
	docker compose logs -f

# ─── Backend (Rust) ────────────────────────────────────────────────────────────

rust-check: ## Run Rust compiler checks
	cargo check --workspace --all-targets

rust-fmt: ## Check Rust formatting
	cargo fmt --all -- --check

rust-test: ## Run Rust tests
	cargo test --workspace

rust-lint: ## Run Rust linter
	cargo clippy --workspace --all-targets -- -D warnings

# ─── Mobile (Flutter) ──────────────────────────────────────────────────────────

mobile-get: ## Install Flutter dependencies
	cd apps/mobile && flutter pub get

mobile-analyze: ## Run Flutter analyzer
	cd apps/mobile && flutter analyze

mobile-test: ## Run Flutter tests
	cd apps/mobile && flutter test

mobile-clean: ## Clean Flutter build artifacts
	cd apps/mobile && flutter clean

mobile-lint: ## Run Flutter analyze with warnings as errors
	cd apps/mobile && flutter analyze --no-fatal-infos

# ─── Combined ──────────────────────────────────────────────────────────────────

lint: rust-fmt rust-check mobile-analyze ## Run all linters (Rust + Flutter)

check: rust-fmt rust-check rust-test mobile-analyze mobile-test ## Run full check suite (Rust + Flutter)

ci: check ## Alias for CI pipeline

# ─── Smoke ─────────────────────────────────────────────────────────────────────

smoke: ## Run smoke tests
	python3 test_smoke.py

# ─── Cleanup ───────────────────────────────────────────────────────────────────

clean: mobile-clean ## Clean all build artifacts
	cargo clean
