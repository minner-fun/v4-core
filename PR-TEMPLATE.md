# Fix: Update Solidity version pragma for files using `global` keyword

## Description

This PR fixes a Solidity version compatibility issue in type definition files that use the `global` keyword.

## Problem

The `using ... for ... global` syntax was introduced in Solidity 0.8.13, but several files in `src/types/` declared compatibility with `^0.8.0`. While this compiles successfully with the current `solc = "0.8.26"` in `foundry.toml`, it creates a version mismatch that could cause compilation failures if someone tries to compile with Solidity versions 0.8.0 - 0.8.12.

### Error when compiling with 0.8.0 - 0.8.12:
```
Error: "global" is only supported from Solidity 0.8.13 onwards.
```

## Changes

Updated the Solidity version pragma from `^0.8.0` to `^0.8.13` in the following files:

- `src/types/PoolKey.sol`
- `src/types/Currency.sol`  
- `src/types/Slot0.sol`
- `src/types/BalanceDelta.sol`

### Before:
```solidity
pragma solidity ^0.8.0;  // Allows 0.8.0+

using SomeLibrary for SomeType global;  // Requires 0.8.13+
```

### After:
```solidity
pragma solidity ^0.8.13;  // Correctly requires 0.8.13+

using SomeLibrary for SomeType global;
```

## Files Changed

| File | Old Version | New Version | Reason |
|------|------------|-------------|---------|
| `src/types/PoolKey.sol` | `^0.8.0` | `^0.8.13` | Uses `global` |
| `src/types/Currency.sol` | `^0.8.0` | `^0.8.13` | Uses `global` |
| `src/types/Slot0.sol` | `^0.8.0` | `^0.8.13` | Uses `global` |
| `src/types/BalanceDelta.sol` | `^0.8.0` | `^0.8.13` | Uses `global` |

## Testing

- ✅ All existing tests pass with `forge test`
- ✅ Compilation succeeds with `forge build`
- ✅ Version pragma now matches the required Solidity features

## Impact

- **Positive**: Prevents compilation errors when using Solidity versions 0.8.0 - 0.8.12
- **Positive**: Makes version requirements more explicit and accurate
- **Neutral**: No impact on existing deployments or runtime behavior
- **Neutral**: Foundry config uses 0.8.26, so no change in current build process

## Solidity Feature Reference

The `using ... for ... global` syntax requires Solidity ≥ 0.8.13:
- [Solidity 0.8.13 Release Notes](https://blog.soliditylang.org/2022/03/16/solidity-0.8.13-release-announcement/)
- [Solidity Documentation - Using For](https://docs.soliditylang.org/en/latest/contracts.html#using-for)

## Checklist

- [x] Code compiles without errors
- [x] All tests pass
- [x] Version pragma matches used language features
- [x] Changes are minimal and focused on the issue
- [x] Documentation updated if necessary (N/A for this change)

