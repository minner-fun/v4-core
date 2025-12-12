8.13版本引入的新特性
一次声明，全局使用。

## 概述

`using ... for ... global` 是 Solidity 0.8.13+ 引入的特性，用于在整个项目范围内将库函数绑定到类型上。

使用案例

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Currency} from "./Currency.sol";
import {IHooks} from "../interfaces/IHooks.sol";
import {PoolIdLibrary} from "./PoolId.sol";

// 8.13引入的新特性，使全局，这个项目都生效，在用到PoolKey的地方，直接使用toId()，
// 而不是像以前一样, 在每个用到PoolKey的地方凑在using 一遍 PoolIdLibrary
using PoolIdLibrary for PoolKey global;

/// @notice Returns the key for identifying a pool
struct PoolKey {
    /// @notice The lower currency of the pool, sorted numerically
    Currency currency0;
    /// @notice The higher currency of the pool, sorted numerically
    Currency currency1;
    /// @notice The pool LP fee, capped at 1_000_000. If the highest bit is 1, the pool has a dynamic fee and must be exactly equal to 0x800000
    uint24 fee;
    /// @notice Ticks that involve positions must be a multiple of tick spacing
    int24 tickSpacing;
    /// @notice The hooks of the pool
    IHooks hooks;
}

```
