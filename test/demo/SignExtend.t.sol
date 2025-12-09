// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {console} from "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";

contract SignExtendTest is Test {
    
    function test_SignExtend_Positive() public {
        console.log("\n=== Test 1: Positive number (42) ===");
        int128 positive = 42;
        testSignExtend(positive);
    }
    
    function test_SignExtend_Negative() public {
        console.log("\n=== Test 2: Negative number (-42) ===");
        int128 negative = -42;
        testSignExtend(negative);
    }
    
    function test_SignExtend_MaxNegative() public {
        console.log("\n=== Test 3: Min int128 (most negative) ===");
        int128 minValue = type(int128).min;
        testSignExtend(minValue);
    }
    
    function testSignExtend(int128 value) internal {
        console.log("Original int128 value:", int256(value));
        
        // 模拟：将 int128 存储到 int256 的低 128 位
        int256 packed;
        assembly {
            // 假设这是从 BeforeSwapDelta 中提取的原始值
            // 高128位可能是其他值，我们只关心低128位
            packed := value
        }
        
        console.log("\n--- Method 1: Direct cast (Wrong for negative!) ---");
        int256 directCast;
        assembly {
            // 只是把低128位的值当作 uint128，然后转换
            directCast := and(packed, 0xffffffffffffffffffffffffffffffff)
        }
        console.log("Direct cast result:", uint256(directCast));
        logBinary256(directCast, "Direct");
        
        console.log("\n--- Method 2: signextend (Correct!) ---");
        int256 signExtended;
        assembly {
            // signextend(15, x) 从第127位进行符号扩展
            signExtended := signextend(15, packed)
        }
        console.log("signextend(15, x) result:", signExtended);
        logBinary256(signExtended, "SignExtend");
        
        console.log("\n--- Verification ---");
        console.log("Original int128:", int256(value));
        console.log("After signextend:", signExtended);
        console.log("Are they equal?", int256(value) == signExtended);
        
        if (value < 0) {
            console.log("\nNote: For negative numbers:");
            console.log("  - Direct cast treats it as large positive number");
            console.log("  - signextend correctly preserves the negative value");
        }
    }
    
    function test_Comparison_With_BeforeSwapDelta() public {
        console.log("\n=== Simulating BeforeSwapDelta.getUnspecifiedDelta ===");
        
        int128 deltaSpecified = 100;
        int128 deltaUnspecified = -50;  // 负数！
        
        console.log("deltaSpecified:", int256(deltaSpecified));
        console.log("deltaUnspecified:", int256(deltaUnspecified));
        
        // 组合成 BeforeSwapDelta
        int256 beforeSwapDelta;
        assembly {
            beforeSwapDelta := or(
                shl(128, deltaSpecified),
                and(sub(shl(128, 1), 1), deltaUnspecified)
            )
        }
        
        console.log("\nCombined BeforeSwapDelta:");
        logBinary256(beforeSwapDelta, "BeforeSwapDelta");
        
        // 提取 deltaUnspecified - 错误方法
        console.log("\n--- Wrong way (without signextend) ---");
        int256 wrongExtract;
        assembly {
            wrongExtract := and(beforeSwapDelta, 0xffffffffffffffffffffffffffffffff)
        }
        console.log("Extracted (wrong):", uint256(wrongExtract));
        console.log("Expected:", int256(deltaUnspecified));
        console.log("Match?", wrongExtract == int256(deltaUnspecified));
        
        // 提取 deltaUnspecified - 正确方法
        console.log("\n--- Correct way (with signextend) ---");
        int256 correctExtract;
        assembly {
            correctExtract := signextend(15, beforeSwapDelta)
        }
        console.log("Extracted (correct):", correctExtract);
        console.log("Expected:", int256(deltaUnspecified));
        console.log("Match?", correctExtract == int256(deltaUnspecified));
    }
    
    function logBinary256(int256 value, string memory label) internal view {
        console.log(string(abi.encodePacked(label, " (binary 256-bit):")));
        bytes memory result = new bytes(256);
        uint256 uValue = uint256(value);
        
        for (uint i = 0; i < 256; i++) {
            result[255 - i] = (uValue & 1) == 1 ? bytes1("1") : bytes1("0");
            uValue >>= 1;
        }
        
        // 分8段打印，每段32位
        console.log("  [Bits 255-224]", string(slice(result, 0, 32)));
        console.log("  [Bits 223-192]", string(slice(result, 32, 32)));
        console.log("  [Bits 191-160]", string(slice(result, 64, 32)));
        console.log("  [Bits 159-128]", string(slice(result, 96, 32)));
        console.log("  [Bits 127-96] ", string(slice(result, 128, 32)), "<-- int128 sign bit at 127");
        console.log("  [Bits 95-64]  ", string(slice(result, 160, 32)));
        console.log("  [Bits 63-32]  ", string(slice(result, 192, 32)));
        console.log("  [Bits 31-0]   ", string(slice(result, 224, 32)));
    }
    
    function slice(bytes memory data, uint start, uint length) internal pure returns (bytes memory) {
        bytes memory result = new bytes(length);
        for (uint i = 0; i < length; i++) {
            result[i] = data[start + i];
        }
        return result;
    }
}

