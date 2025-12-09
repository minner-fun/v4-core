// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {console} from "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";

contract TwoComplementTest is Test {
    
    function test_UnderstandNegativeNumbers() public {
        console.log("\n=== Understanding Two's Complement (Negative Numbers) ===\n");
        
        // 使用 int8 来演示（8位更容易理解）
        console.log("--- Using int8 (8 bits) for easy understanding ---");
        
        int8 zero = 0;
        int8 one = 1;
        int8 minusOne = -1;
        int8 minusTwo = -2;
        int8 minusFive = -5;
        int8 minusFortyTwo = -42;
        
        logInt8(zero, "0");
        logInt8(one, "1");
        logInt8(minusOne, "-1");
        logInt8(minusTwo, "-2");
        logInt8(minusFive, "-5");
        logInt8(minusFortyTwo, "-42");
        
        console.log("\n--- Pattern Analysis ---");
        console.log("Notice:");
        console.log("  0  = 00000000");
        console.log("  1  = 00000001");
        console.log(" -1  = 11111111  <- All 1s!");
        console.log(" -2  = 11111110");
        console.log(" -42 = 11010110");
        console.log("");
        console.log("Rule: If the highest bit (sign bit) is 1, it's negative!");
        
        console.log("\n--- Key Facts ---");
        console.log("1. All bits = 1 means -1, NOT the largest number");
        console.log("2. The largest positive int8 = 127 = 01111111");
        console.log("3. The smallest negative int8 = -128 = 10000000");
        
        int8 maxPositive = type(int8).max;
        int8 minNegative = type(int8).min;
        logInt8(maxPositive, "max int8 (127)");
        logInt8(minNegative, "min int8 (-128)");
    }
    
    function test_HowToReadNegativeNumber() public {
        console.log("\n=== How to convert binary to decimal (for negative) ===\n");
        
        int8 value = -42;
        uint8 bits = uint8(value);
        
        console.log("Binary: 11010110");
        console.log("Decimal:", int256(value));
        console.log("");
        console.log("Method 1 - Understanding the pattern:");
        console.log("  Step 1: See the highest bit is 1, so it's negative");
        console.log("  Step 2: To find absolute value:");
        console.log("    a) Flip all bits: 11010110 -> 00101001");
        console.log("    b) Add 1:          00101001 + 1 = 00101010 = 42");
        console.log("  Step 3: Add negative sign: -42");
        
        // 验证
        uint8 flipped = ~bits;
        uint8 absolute = flipped + 1;
        console.log("");
        console.log("Verification:");
        console.log("  Original bits:", bits, "=", toBinary8(bits));
        console.log("  Flipped:     ", flipped, "=", toBinary8(flipped));
        console.log("  Add 1:       ", absolute, "=", toBinary8(absolute), "= 42");
        console.log("  So original is: -42");
    }
    
    function test_WhyAllOnesIsMinusOne() public {
        console.log("\n=== Why 111...111 = -1 ? ===\n");
        
        console.log("Think about it this way:");
        console.log("");
        console.log("If we have:  00000001 (1)");
        console.log("What is 1 + (-1)? Should be 0, right?");
        console.log("");
        console.log("Let's add: 00000001 (1)");
        console.log("         + 11111111 (-1)");
        console.log("         ----------");
        console.log("         100000000");
        console.log("            ^^^^^^^^ <- overflow, discarded in 8-bit");
        console.log("         = 00000000 (0) ✓");
        console.log("");
        console.log("This is why 11111111 = -1!");
        console.log("It's designed so that addition works correctly.");
        
        // 实际验证
        int8 one = 1;
        int8 minusOne = -1;
        int8 result = one + minusOne;
        
        console.log("");
        console.log("Solidity verification:");
        console.log("  1 + (-1) =", int256(result));
    }
    
    function test_Int128_Example() public {
        console.log("\n=== Back to your int128 example ===\n");
        
        int128 value = -42;
        
        console.log("For int128, the bit pattern of -42:");
        logBinary128(value);
        
        console.log("");
        console.log("Notice:");
        console.log("  - Bit 127 (highest) = 1, so it's negative");
        console.log("  - All those 1s in high bits are part of the negative representation");
        console.log("  - This is NOT a large positive number!");
        console.log("");
        console.log("If interpreted as unsigned (uint128), it would be:", uint128(value));
        console.log("But as signed (int128), it is:", int256(value));
    }
    
    function logInt8(int8 value, string memory label) internal view {
        uint8 bits = uint8(value);
        console.log(string(abi.encodePacked(
            label, " = ", toBinary8(bits), " = "
        )), int256(value));
    }
    
    function toBinary8(uint8 value) internal pure returns (string memory) {
        bytes memory result = new bytes(8);
        for (uint i = 0; i < 8; i++) {
            result[7 - i] = (value & 1) == 1 ? bytes1("1") : bytes1("0");
            value >>= 1;
        }
        return string(result);
    }
    
    function logBinary128(int128 value) internal view {
        bytes memory result = new bytes(128);
        uint128 uValue = uint128(value);
        
        for (uint i = 0; i < 128; i++) {
            result[127 - i] = (uValue & 1) == 1 ? bytes1("1") : bytes1("0");
            uValue >>= 1;
        }
        
        // 分4段打印
        console.log("  ", string(slice(result, 0, 32)), " <- sign bit + high bits");
        console.log("  ", string(slice(result, 32, 32)));
        console.log("  ", string(slice(result, 64, 32)));
        console.log("  ", string(slice(result, 96, 32)));
    }
    
    function slice(bytes memory data, uint start, uint length) internal pure returns (bytes memory) {
        bytes memory result = new bytes(length);
        for (uint i = 0; i < length; i++) {
            result[i] = data[start + i];
        }
        return result;
    }
}

