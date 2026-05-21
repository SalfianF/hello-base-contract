# ANBLE Token — Anchor Network Base Liquid Ecosystem

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Solidity](https://img.shields.io/badge/Solidity-^0.8.20-363636?logo=solidity)](https://soliditylang.org/)
[![Foundry](https://img.shields.io/badge/Built%20with-Foundry-000000?logo=ethereum)](https://book.getfoundry.sh/)
[![Chain](https://img.shields.io/badge/Chain-Base_%26_Base_Sepolia-0052FF?logo=base)](https://base.org)
[![Tests](https://img.shields.io/badge/Tests-25_passing-22c55e)](https://github.com/SalfianF/base-deploy/actions)

---

**ANBLE** is a permissionless ERC-20 token on **Base** (OP Stack L2).  
Designed for the Anchor Network ecosystem — low-fee transfers, owner-controlled mint, and compliant burn mechanics.

## Table of Contents

- [Contract](#contract)
- [Quick Start](#quick-start)
- [Development](#development)
- [Deployment](#deployment)
- [Test Suite](#test-suite)
- [Security](#security)
- [License](#license)

---

## Contract

| Property       | Value                             |
|----------------|-----------------------------------|
| Name           | ANBLE                             |
| Symbol         | ANBLE                             |
| Decimals       | 18                                |
| Max Supply     | 1,000,000,000 ANBLE (1B)          |
| Standard       | ERC-20 (custom, no dependencies)  |
| Network        | Base L2 (chain ID: 8453)          |

### Functions

| Function       | Access     | Description                              |
|----------------|------------|------------------------------------------|
| `transfer`     | Public     | Transfer tokens to any address           |
| `approve`      | Public     | Approve spender allowance                |
| `transferFrom` | Public     | Transfer via allowance                   |
| `mint`         | Owner-only | Mint new tokens (up to MAX_SUPPLY)       |
| `burn`         | Public     | Burn caller's tokens                     |
| `burnFrom`     | Owner-only | Burn tokens from any address (compliance)|

## Quick Start

```bash
# Prerequisites
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Clone & build
git clone https://github.com/SalfianF/base-deploy.git
cd base-deploy
forge build

# Run tests
make test
```

## Development

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) (forge, cast, anvil)
- Git LFS (optional, for large CI artifacts)

### Common Commands

```bash
make build          # Compile contracts
make test           # Run full test suite (-vvv)
make test-gas       # Show gas report
make test-fuzz      # Run fuzz tests
make fmt            # Format Solidity source
make snapshot       # Generate gas snapshot
```

### Project Structure

```
src/
├── ANBLE.sol               # Token contract (single file, zero deps)

test/
├── ANBLE.t.sol             # 25 tests (unit + fuzz)

script/
├── DeployANBLE.s.sol       # Deployment script

lib/
└── forge-std/              # Foundry standard library (submodule)
```

## Deployment

### Environment Setup

```bash
cp .env.example .env
# Fill in: PRIVATE_KEY, BASE_RPC_URL, BASESCAN_API_KEY
source .env
```

### Deploy to Base Sepolia (testnet)

```bash
make deploy-base-sepolia
```

### Deploy to Base (mainnet)

```bash
make deploy-base
```

### Manual (custom params)

```bash
forge script script/DeployANBLE.s.sol:DeployANBLE \
  --rpc-url base \
  --broadcast \
  --verify \
  -vvv
```

Environment variables accepted by the deploy script:

| Variable         | Default                | Description               |
|------------------|------------------------|---------------------------|
| `OWNER_ADDRESS`  | Deployer address       | Token owner               |
| `INITIAL_SUPPLY` | `500_000_000 * 10**18` | Initial mint amount (wei) |

## Test Suite

**25 tests — all passing** ✅

| Category         | Tests | Type           |
|------------------|:-----:|----------------|
| Deployment       | 4     | Invariant      |
| Transfer         | 4     | Unit           |
| Approve/TransferFrom | 4  | Unit           |
| Mint             | 4     | Access control |
| Burn             | 3     | Unit           |
| BurnFrom         | 3     | Access control |
| Fuzz             | 3     | Property-based |

```bash
make test          # 25/25 PASS
make test-fuzz     # 256 runs per fuzz test
make test-gas      # Gas report per function
```

## Security

- **Custom errors** — gas-efficient error handling (no require strings)
- **Immutable MAX_SUPPLY** — cannot be changed post-deployment
- **Owner model** — simple single-owner pattern for mint/burnFrom
- **No external deps** — zero OpenZeppelin import surface

### Auditing

For security concerns, contact `salfianf@github.com`.

## License

MIT — see [LICENSE](LICENSE) for details.

---

<p align="center">
  Built on Base · Part of the Anchor Network ecosystem
</p>
