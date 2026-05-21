# TESTING.md

## Running Tests

```bash
# Run all tests
npx hardhat test

# Run specific test file
npx hardhat test test/test_storage.js

# Run with gas report
npx hardhat test --gas

# Run with coverage
npx hardhat coverage
```

## Test Structure

| Test File | Contracts Covered |
|-----------|------------------|
| `test_hello_base.js` | HelloBase |
| `test_storage.js` | SimpleStorage |
| `test_counter.js` | Counter |
| `test_calculator.js` | Calculator |
| `test_greeter.js` | Greeter |
| `test_vault.js` | Vault |
| `test_basetoken.js` | BaseToken |
| `test_tokenswap.js` | TokenSwap |
| `test_basenft.js` | BaseNFT |
| `test_multisig.js` | MultiSig |

## Writing Tests

Tests use Hardhat's built-in network and Chai assertions:

```javascript
const { expect } = require("chai");

describe("SimpleStorage", function () {
  it("should store and retrieve values", async function () {
    const SimpleStorage = await ethers.getContractFactory("SimpleStorage");
    const storage = await SimpleStorage.deploy();
    await storage.store(42);
    expect(await storage.retrieve()).to.equal(42);
  });
});
```
