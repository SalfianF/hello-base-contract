# TASKS.md

## Available Hardhat Tasks

This project includes custom Hardhat tasks in the `tasks/` directory.

### Deploy All Contracts

```bash
npx hardhat deploy-all --network base
```

### Deploy Individual Groups

Use one of the deploy scripts in `scripts/`:

| Script | Contracts |
|--------|-----------|
| `scripts/deploy-hellobase.js` | HelloBase |
| `scripts/deploy-primitives.js` | SimpleStorage, Counter |
| `scripts/deploy-utilities.js` | Calculator, Greeter |
| `scripts/deploy-defi.js` | BaseToken, TokenSwap, Vault |
| `scripts/deploy-nft.js` | BaseNFT, MultiSig |
| `scripts/deploy-bridge.js` | BridgingToBase |

## Contract Addresses (Base Mainnet)

| Contract | Address |
|----------|---------|
| HelloBase | `0x33d378ad6bA486161777a63819aC15F66a0d3c1D` |
