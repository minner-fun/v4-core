// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Return type of the beforeSwap hook. 返回值类型为BeforeSwapDelta
// Upper 128 bits is the delta in specified tokens. Lower 128 bits is delta in unspecified tokens (to match the afterSwap hook)
// 上128位是指定代币的delta，下128位是未指定代币的delta（与afterSwap hook匹配）
type BeforeSwapDelta is int256;

// Creates a BeforeSwapDelta from specified and unspecified 从指定和未指定创建一个BeforeSwapDelta
function toBeforeSwapDelta(int128 deltaSpecified, int128 deltaUnspecified)
    pure
    returns (BeforeSwapDelta beforeSwapDelta)
{
    assembly ("memory-safe") {
        beforeSwapDelta := or(shl(128, deltaSpecified), and(sub(shl(128, 1), 1), deltaUnspecified))
    }
}

/// @notice Library for getting the specified and unspecified deltas from the BeforeSwapDelta type 库，用于从BeforeSwapDelta类型中获取指定和未指定的delta
library BeforeSwapDeltaLibrary {
    /// @notice A BeforeSwapDelta of 0 一个BeforeSwapDelta的0值
    BeforeSwapDelta public constant ZERO_DELTA = BeforeSwapDelta.wrap(0);

    /// extracts int128 from the upper 128 bits of the BeforeSwapDelta 从BeforeSwapDelta的上128位提取int128
    /// returned by beforeSwap 由beforeSwap返回
    function getSpecifiedDelta(BeforeSwapDelta delta) internal pure returns (int128 deltaSpecified) {
        assembly ("memory-safe") {
            deltaSpecified := sar(128, delta)
        }
    }

    /// extracts int128 from the lower 128 bits of the BeforeSwapDelta 从BeforeSwapDelta的下128位提取int128
    /// returned by beforeSwap and afterSwap 由beforeSwap和afterSwap返回
    function getUnspecifiedDelta(BeforeSwapDelta delta) internal pure returns (int128 deltaUnspecified) {
        assembly ("memory-safe") {
            deltaUnspecified := signextend(15, delta)
        }
    }
}
