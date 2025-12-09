// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {console} from "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";

contract BeforeTest is Test{
    type BeforeSwapDelta is int256;


    function setUp() public {
        console.log("BeforeTest setUp");
    }

    function test_BeforeSwapDelta() public {
        console.log("\n=== Test Case 1: Small values (1, 2) ===");
        testCombination(1, 2);
        
        // console.log("\n\n=== Test Case 2: Larger values (255, 256) ===");
        // testCombination(255, 256);
        
        // console.log("\n\n=== Test Case 3: Max int128 values ===");
        // testCombination(type(int128).max, type(int128).max);
    }
    
    function testCombination(int128 deltaSpecified, int128 deltaUnspecified) internal {
        console.log("Input deltaSpecified (decimal):", uint128(deltaSpecified));
        logBinary128(deltaSpecified, "deltaSpecified");
        
        console.log("");
        console.log("Input deltaUnspecified (decimal):", uint128(deltaUnspecified));
        logBinary128(deltaUnspecified, "deltaUnspecified");
        
        console.log("");
        console.log("--- After Combining (shl(128, deltaSpecified) | deltaUnspecified) ---");
        BeforeSwapDelta beforeSwapDelta = toBeforeSwapDelta(deltaSpecified, deltaUnspecified);
        
        int256 result = BeforeSwapDelta.unwrap(beforeSwapDelta);
        console.log("Result (decimal):", result > 0 ? uint256(result) : 0);
        logBinary256(result, "beforeSwapDelta");
    }
    
    // 打印 int128 的二进制表示（128位）
    function logBinary128(int128 value, string memory label) internal view {
        console.log(string(abi.encodePacked(label, " (binary 128-bit):")));
        bytes memory result = new bytes(128);
        uint128 uValue = uint128(value);
        
        for (uint i = 0; i < 128; i++) {
            result[127 - i] = (uValue & 1) == 1 ? bytes1("1") : bytes1("0");
            uValue >>= 1;
        }
        
        // 分4段打印，每段32位，便于阅读
        console.log("  ", string(slice(result, 0, 32)));
        console.log("  ", string(slice(result, 32, 32)));
        console.log("  ", string(slice(result, 64, 32)));
        console.log("  ", string(slice(result, 96, 32)));
    }
    
    // 打印 int256 的二进制表示（256位）
    function logBinary256(int256 value, string memory label) internal view {
        console.log(string(abi.encodePacked(label, " (binary 256-bit):")));
        bytes memory result = new bytes(256);
        uint256 uValue = uint256(value);
        
        for (uint i = 0; i < 256; i++) {
            result[255 - i] = (uValue & 1) == 1 ? bytes1("1") : bytes1("0");
            uValue >>= 1;
        }
        
        // 分8段打印，每段32位，便于阅读
        console.log("  [High 128 bits - deltaSpecified]");
        console.log("  ", string(slice(result, 0, 32)));
        console.log("  ", string(slice(result, 32, 32)));
        console.log("  ", string(slice(result, 64, 32)));
        console.log("  ", string(slice(result, 96, 32)));
        console.log("  [Low 128 bits - deltaUnspecified]");
        console.log("  ", string(slice(result, 128, 32)));
        console.log("  ", string(slice(result, 160, 32)));
        console.log("  ", string(slice(result, 192, 32)));
        console.log("  ", string(slice(result, 224, 32)));
    }
    
    // 辅助函数：切片字节数组
    function slice(bytes memory data, uint start, uint length) internal pure returns (bytes memory) {
        bytes memory result = new bytes(length);
        for (uint i = 0; i < length; i++) {
            result[i] = data[start + i];
        }
        return result;
    }

    function toBeforeSwapDelta(int128 deltaSpecified, int128 deltaUnspecified)
    public 
    returns (BeforeSwapDelta beforeSwapDelta)
    {
        console.log("\n--- Step by step in toBeforeSwapDelta ---");
        
        // 步骤1：将 deltaSpecified 左移 128 位，放到高 128 位
        int256 step1;
        assembly ("memory-safe") {
            step1 := shl(128, deltaSpecified)
        }
        console.log("Step 1: shl(128, deltaSpecified) =");
        logBinary256(step1, "  step1");
        
        // 步骤2：创建低 128 位的掩码 (2^128 - 1)
        int256 step2;
        assembly ("memory-safe") {
            step2 := sub(shl(128, 1), 1)
        }
        console.log("\nStep 2: mask = sub(shl(128, 1), 1) = 0x00000000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF");
        logBinary256(step2, "  mask");
        
        // 步骤3：使用掩码提取 deltaUnspecified 的低 128 位
        int256 step3;
        assembly ("memory-safe") {
            step3 := and(step2, deltaUnspecified)
        }
        console.log("\nStep 3: and(mask, deltaUnspecified) =");
        logBinary256(step3, "  step3");
        
        // 步骤4：合并两部分
        assembly ("memory-safe") {
            beforeSwapDelta := or(step1, step3)
        }
        console.log("\nStep 4: or(step1, step3) = final result");
        console.log("---\n");
    }
}