# DEPLOYING.md

## Prerequisites

- Node.js v18+
- Base mainnet RPC URL
- Private key with Base ETH for gas

## Setup

```bash
npm install
cp .env.example .env
# Edit .env: add PRIVATE_KEY and BASE_RPC_URL
```

## Deploy a Single Contract

```bash
npx hardhat run scripts/deploy-hellobase.js --network base
npx hardhat run scripts/deploy-primitives.js --network base
npx hardhat run scripts/deploy-utilities.js --network base
npx hardhat run scripts/deploy-defi.js --network base
npx hardhat run scripts/deploy-nft.js --network base
npx hardhat run scripts/deploy-bridge.js --network base
```

## Deploy All Contracts

```bash
npx hardhat run scripts/deploy-all.js --network base
```

## Verify on BaseScan

```bash
npx hardhat verify --network base <CONTRACT_ADDRESS> <CONSTRUCTOR_ARGS>
```

## Network Configuration

| Network | RPC URL |
|---------|---------|
| Base Mainnet | `https://mainnet.base.org` |
| Base Sepolia | `https://sepolia.base.org` |
| Hardhat Local | `http://127.0.0.1:8545` |
