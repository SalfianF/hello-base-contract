# ANBLE Token — Makefile
# Common operations for development & deployment.

# Default
.DEFAULT_GOAL := build

# --- Build ---
build:
	forge build

build-sizes:
	forge build --sizes

clean:
	forge clean

# --- Test ---
test:
	forge test -vvv

test-gas:
	forge test --gas-report

test-fuzz:
	forge test --fuzz-seed 0

# --- Deploy ---
deploy-base:
	forge script script/DeployANBLE.s.sol:DeployANBLE \
		--rpc-url base --broadcast --verify -vvv

deploy-base-sepolia:
	forge script script/DeployANBLE.s.sol:DeployANBLE \
		--rpc-url base_sepolia --broadcast --verify -vvv

# --- Format ---
fmt:
	forge fmt

fmt-check:
	forge fmt --check

# --- Snapshot ---
snapshot:
	forge snapshot

.PHONY: build build-sizes clean test test-gas test-fuzz deploy-base deploy-base-sepolia fmt fmt-check snapshot
