# Security Audit — hello-base-contract

**Audit Date:** May 2026  
**Contracts Audited:** Greeter, BridgingToBase, TokenSwap, MultiSig, Vault, HelloBase  
**Scope:** Solidity 0.8.20, Hardhat test suite, Ownable2Step, ReentrancyGuard

---

## 1. Summary of Findings

| Severity | Count | Status |
|----------|-------|--------|
| Critical | 0 | - |
| High | 0 | - |
| Medium | 0 | - |
| Low | 0 | - |
| Informational | 3 | Addressed |

All identified issues have been remediated. No open findings.

---

## 2. Security Improvements

### 2.1 Ownable2Step — Two-Step Ownership Transfer

**Contracts:** `Greeter.sol`, `BridgingToBase.sol`, `TokenSwap.sol`

**Risk:** Single-step `transferOwnership` can accidentally transfer ownership to a mistyped address (irreversible loss of control).

**Fix:** Migrated from OpenZeppelin `Ownable` to `Ownable2Step`. Ownership transfer now requires:

1. Current owner calls `transferOwnership(newOwner)`
2. New owner calls `acceptOwnership()` (two transactions)

If the new address is wrong or inaccessible, ownership remains with the current owner.

**Verification:** `test/test_security.js` — Greeter & BridgingToBase Ownable2Step tests.

### 2.2 ReentrancyGuard — Reentrancy Protection

**Contract:** `TokenSwap.sol`, `Vault.sol`

**Risk:** `fillOrder()` and `withdraw()` transfer tokens/ETH externally, which can trigger malicious fallbacks that re-enter the function before state updates complete.

**Fix:** `TokenSwap.fillOrder()` uses OpenZeppelin `nonReentrant` modifier. `Vault` uses a custom `nonReentrant` modifier (CEI pattern).

**Verification:** `test/test_security.js` — Vault reentrancy protection tests using `ReentrancyAttacker.sol`.

### 2.3 Order Deadlines — Expiration Mechanism

**Contract:** `TokenSwap.sol`

**Risk:** Orders remain fillable indefinitely, exposing makers to price slippage over time.

**Fix:** Added `deadline` field to `SwapOrder`. `createOrder` rejects past deadlines. `fillOrder` rejects expired orders (`block.timestamp > deadline`).

**Verification:** `test/test_security.js` — expired order test, past deadline rejection test.

### 2.4 Order Cancellation — Maker Reclaims Tokens

**Contract:** `TokenSwap.sol`

**Risk:** Makers cannot cancel unfilled orders — tokens are locked in the contract until someone fills the order or the maker loses access.

**Fix:** Added `cancelOrder(orderId)` — only the maker can cancel their own unfilled, uncancelled order. Tokens are returned to the maker. `emergencyWithdraw` handles non-order tokens only.

**Verification:** `test/test_security.js` — cancel order test, non-maker rejection test.

### 2.5 Dynamic Signer Management — MultiSig

**Contract:** `MultiSig.sol`

**Risk:** MultiSig signers are fixed at deployment. There is no way to add/remove signers or revoke confirmations without redeploying.

**Fix:**
- `addSigner(signer)` — existing signers can add new signers
- `removeSigner(signer)` — removes a signer, guarded against falling below `required` threshold
- `revokeConfirmation(txIndex)` — signers can revoke a mistaken confirmation before execution

**Verification:** `test/test_security.js` — signer management & revoke tests.

### 2.6 Input Validation

**Contracts:** All

**Risk:** Empty strings, zero addresses, zero amounts, duplicate signers, same-token swaps.

**Fix:**
- `Greeter/BridgingToBase` — reject empty string in constructor
- `TokenSwap` — reject zero addresses, zero amounts, same-token swaps, past deadlines
- `MultiSig` — reject zero-address and duplicate signers in constructor, guard minimum signer count for removal
- `HelloBase` — custom error `HelloBase__EmptyMessage`, custom error `HelloBase__Unauthorized`

---

## 3. Test Coverage

| Suite | Tests | File |
|-------|-------|------|
| HelloBase — Deployment | 4 | `test_hello_base.js` |
| HelloBase — getInfo | 1 | `test_hello_base.js` |
| HelloBase — setMessage | 7 | `test_hello_base.js` |
| HelloBase — Access Control | 2 | `test_hello_base.js` |
| HelloBase — Edge Cases | 3 | `test_hello_base.js` |
| Vault — Reentrancy | 2 | `test_security.js` |
| TokenSwap — Cancel/Deadline/Access | 6 | `test_security.js` |
| Greeter — Ownable2Step | 3 | `test_security.js` |
| BridgingToBase — Ownable2Step | 2 | `test_security.js` |
| MultiSig — Signer Management & Revoke | 6 | `test_security.js` |
| SimpleStorage — Edge Cases | 3 | `test_primitives_edge.js` |
| Counter — Edge Cases | 3 | `test_primitives_edge.js` |
| Calculator — Edge Cases | 5 | `test_primitives_edge.js` |
| **Total** | **47** | |

### Run Tests

```bash
npx hardhat test              # All tests
npx hardhat coverage          # With coverage report
npx solhint "contracts/**/*.sol"  # Solidity lint
```

---

## 4. Static Analysis

Configure Slither:

```bash
slither . --config-file slither.config.json
```

### Detector Exclusions

- **Informational** — excluded (noise). Low/Medium/High are included.

### Known False Positives

- `MultiSig.sol` — swap-and-pop removal pattern triggers "centralization" warnings. This is by design: signers are trusted participants.
- `Vault.sol` — plain ETH receive warnings. Vault is designed for ETH deposits.

---

## 5. Chain-Specific Notes

**Base (OP Stack):** All contracts target Solidity 0.8.20 with `viaIR: true` for Yul IR pipeline. The OP Stack is EVM-equivalent — no special security considerations beyond standard EVM.

**Deployed addresses** (if applicable): See `TASKS.md` for latest deployment info.

---

## 6. Recommendations

1. **Run Slither** before each mainnet deployment to catch new vulnerabilities
2. **Use a hardware wallet** for MultiSig signers in production
3. **Set reasonable deadlines** in TokenSwap (e.g., 1–7 days)
4. **Monitor failed transactions** — repeated failed TokenSwap fills may indicate sandwhich attempts on Base
