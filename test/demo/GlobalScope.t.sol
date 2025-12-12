// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {console} from "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";

// ============================================
// 场景设置：创建自定义类型和库
// ============================================

// 文件1：定义类型和库
type MyToken is address;

library MyTokenLib {
    function isZero(MyToken token) internal pure returns (bool) {
        return MyToken.unwrap(token) == address(0);
    }
    
    function toString(MyToken token) internal pure returns (string memory) {
        return "MyToken";
    }
}

// 文件1中声明 global
using MyTokenLib for MyToken global;

// ============================================
// 测试1：导入了类型定义的文件
// ============================================

// 这个文件导入了上面的定义（在同一个文件中，相当于导入）
contract Test1_HasAccess is Test {
    function test_CanUseGlobalBinding() public view {
        console.log("\n=== Test 1: File that imports MyToken ===");
        
        MyToken token = MyToken.wrap(address(0x1234));
        
        // ✅ 可以使用，因为我们导入了 MyToken 的定义
        bool isZero = token.isZero();
        
        console.log("Token:", MyToken.unwrap(token));
        console.log("Can call token.isZero():", isZero ? "false" : "true");
        console.log("Result: WORKS! Because we imported MyToken");
    }
}

// ============================================
// 测试2：演示导入的重要性
// ============================================

// 另一个类型，但没有 global 声明
type AnotherToken is address;

library AnotherTokenLib {
    function isZero(AnotherToken token) internal pure returns (bool) {
        return AnotherToken.unwrap(token) == address(0);
    }
}

// 注意：这里没有 global！
// using AnotherTokenLib for AnotherToken;  // 局部声明

contract Test2_NoGlobal is Test {
    // 必须在这里局部声明
    using AnotherTokenLib for AnotherToken;
    
    function test_LocalDeclarationNeeded() public view {
        console.log("\n=== Test 2: Without global declaration ===");
        
        AnotherToken token = AnotherToken.wrap(address(0x5678));
        
        // ✅ 可以使用，因为有局部声明
        bool result = token.isZero();
        
        console.log("Token:", AnotherToken.unwrap(token));
        console.log("Can call token.isZero():", result ? "true" : "false");
        console.log("Result: WORKS, but needs local 'using' declaration");
    }
}

contract Test3_NoLocalDeclaration is Test {
    // 注意：这个合约没有声明 using AnotherTokenLib for AnotherToken
    
    function test_CannotUseWithoutDeclaration() public view {
        console.log("\n=== Test 3: No local declaration for AnotherToken ===");
        
        AnotherToken token = AnotherToken.wrap(address(0x9abc));
        
        // ❌ 下面这行会编译错误，因为：
        // 1. AnotherTokenLib 没有声明为 global
        // 2. 这个合约也没有局部声明 using
        // bool result = token.isZero();  // 编译错误！
        
        // 只能这样调用：
        bool result = AnotherTokenLib.isZero(token);
        
        console.log("Token:", AnotherToken.unwrap(token));
        console.log("Must call: AnotherTokenLib.isZero(token)");
        console.log("Cannot call: token.isZero() - would be compile error");
        console.log("Result:", result ? "true" : "false");
    }
}

// ============================================
// 测试4：演示跨文件导入
// ============================================

contract Test4_ImportChain is Test {
    function test_ExplainImportChain() public view {
        console.log("\n=== Test 4: How 'global' actually works ===\n");
        
        console.log("Step-by-step explanation:");
        console.log("");
        console.log("1. File A defines:");
        console.log("   type MyType is uint256;");
        console.log("   library MyLib { ... }");
        console.log("   using MyLib for MyType global;");
        console.log("");
        console.log("2. File B imports A:");
        console.log("   import {MyType} from './A.sol';");
        console.log("   -> Now File B can use myType.libraryFunction()");
        console.log("");
        console.log("3. File C does NOT import A:");
        console.log("   // No import");
        console.log("   -> File C CANNOT use MyType at all!");
        console.log("   -> 'global' doesn't magically make it available everywhere");
        console.log("");
        console.log("KEY INSIGHT:");
        console.log("  'global' means: IF you import the type,");
        console.log("  THEN you automatically get the library bindings.");
        console.log("  It does NOT mean the type is available everywhere.");
    }
}

// ============================================
// 测试5：实际的 PoolKey 例子
// ============================================

// 导入实际的 PoolKey
import {PoolKey} from "../../src/types/PoolKey.sol";
import {PoolId} from "../../src/types/PoolId.sol";
import {Currency} from "../../src/types/Currency.sol";
import {IHooks} from "../../src/interfaces/IHooks.sol";

contract Test5_RealWorldPoolKey is Test {
    function test_PoolKeyGlobalScope() public view {
        console.log("\n=== Test 5: Real-world example with PoolKey ===\n");
        
        console.log("In PoolKey.sol:");
        console.log("  using PoolIdLibrary for PoolKey global;");
        console.log("");
        console.log("In this file:");
        console.log("  import {PoolKey} from '../../src/types/PoolKey.sol';");
        console.log("");
        console.log("Result:");
        console.log("  -> We CAN use: poolKey.toId()");
        console.log("  -> We DON'T need: import {PoolIdLibrary}");
        console.log("  -> We DON'T need: using PoolIdLibrary for PoolKey;");
        console.log("");
        console.log("But if we didn't import PoolKey at all:");
        console.log("  -> We couldn't use PoolKey type");
        console.log("  -> We couldn't use toId() method");
        console.log("  -> 'global' doesn't help if there's no import!");
    }
    
    function test_ActualUsage() public {
        console.log("\n=== Actual usage demonstration ===\n");
        
        // 创建 PoolKey
        PoolKey memory poolKey = PoolKey({
            currency0: Currency.wrap(address(0x1)),
            currency1: Currency.wrap(address(0x2)),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(address(0))
        });
        
        // ✅ 可以使用 toId()，因为：
        // 1. 我们导入了 PoolKey
        // 2. PoolKey.sol 中声明了 global
        PoolId poolId = poolKey.toId();
        
        console.log("Created PoolKey and called .toId()");
        console.log("PoolId:");
        console.logBytes32(PoolId.unwrap(poolId));
        console.log("");
        console.log("This works because:");
        console.log("  1. We imported PoolKey ✅");
        console.log("  2. PoolKey.sol has 'global' declaration ✅");
        console.log("  3. Therefore toId() is automatically available ✅");
    }
}

