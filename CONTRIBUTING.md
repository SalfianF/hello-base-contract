# Contributing to HelloBase

Thanks for your interest! We welcome contributions from the community.

## 📋 Prerequisites

- Node.js 20+
- npm 9+
- A wallet with Base mainnet ETH for deployments

## 🛠️ Getting Started

```bash
git clone https://github.com/SalfianF/hello-base-contract.git
cd hello-base-contract
npm install
cp .env.example .env
npx hardhat compile
npx hardhat test
```

## 🧪 Testing

Write tests in the `test/` directory using Hardhat's built-in Chai + Ethers.

```bash
# Run all tests
npx hardhat test

# Run a specific test
npx hardhat test test/test_calculator.js

# Run with gas reporter
REPORT_GAS=true npx hardhat test
```

## 📝 Code Style

- Solidity: 0.8.20, NatSpec comments required for all public functions
- Indentation: 4 spaces
- Line length: 120 max
- Follow OpenZeppelin patterns where applicable

## 🔄 Pull Request Process

1. Fork the repo and create a branch: `git checkout -b feat/your-feature`
2. Commit with conventional commits: `feat:`, `fix:`, `docs:`, `chore:`, `ci:`, `refactor:`, `test:`
3. Run `npx hardhat test` — all tests must pass
4. Run `npx hardhat compile` — no warnings
5. Open a PR against `main` with a clear description

## ✅ Review Criteria

- Tests included for new functionality
- NatSpec docs complete
- No breaking changes without prior discussion
- Gas-efficient patterns preferred

## 🐛 Bug Reports

Open an issue with:
- Solidity version
- Contract + function name
- Minimal reproduction steps
- Expected vs actual behavior
