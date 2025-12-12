// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {console} from "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";
import {PoolKey} from "../../src/types/PoolKey.sol";
import {PoolId} from "../../src/types/PoolId.sol";
import {Currency} from "../../src/types/Currency.sol";
import {IHooks} from "../../src/interfaces/IHooks.sol";

// 注意：我们只导入了 PoolKey，没有导入 PoolIdLibrary
// 但是因为 PoolKey.sol 中有 `using PoolIdLibrary for PoolKey global;`
// 所以我们可以直接使用 poolKey.toId()

contract GlobalUsingTest is Test {
    
    function test_GlobalUsing() public {
        console.log("\n=== Demonstrating 'using ... for ... global' ===\n");
        
        // 创建一个 PoolKey
        PoolKey memory poolKey = PoolKey({
            currency0: Currency.wrap(address(0x1111)),
            currency1: Currency.wrap(address(0x2222)),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(address(0))
        });
        
        console.log("PoolKey created:");
        console.log("  currency0:", Currency.unwrap(poolKey.currency0));
        console.log("  currency1:", Currency.unwrap(poolKey.currency1));
        console.log("  fee:", poolKey.fee);
        console.log("  tickSpacing:", uint256(int256(poolKey.tickSpacing)));
        
        // 因为有 global 声明，可以直接调用 toId()
        // 就像 toId() 是 PoolKey 的成员函数一样
        PoolId poolId = poolKey.toId();
        
        console.log("\nPoolId (computed via poolKey.toId()):");
        console.logBytes32(PoolId.unwrap(poolId));
        
        console.log("\n--- How does 'global' work? ---");
        console.log("1. PoolKey.sol declares: using PoolIdLibrary for PoolKey global;");
        console.log("2. This makes toId() available on ALL PoolKey instances");
        console.log("3. In ANY file in the project, without importing PoolIdLibrary!");
        console.log("4. We can call: poolKey.toId() - it looks like a method!");
    }
    
    function test_ComparisonWithoutGlobal() public view {
        console.log("\n=== Comparison: With vs Without 'global' ===\n");
        
        console.log("WITHOUT 'global' (old way):");
        console.log("  1. Import library: import {PoolIdLibrary} from '...'");
        console.log("  2. Declare in each file: using PoolIdLibrary for PoolKey;");
        console.log("  3. Then use: poolKey.toId()");
        console.log("");
        console.log("WITH 'global' (new way, Solidity 0.8.13+):");
        console.log("  1. Declare once: using PoolIdLibrary for PoolKey global;");
        console.log("  2. Just import PoolKey anywhere in the project");
        console.log("  3. Automatically can use: poolKey.toId()");
        console.log("");
        console.log("Benefits:");
        console.log("  - Less boilerplate code");
        console.log("  - Consistent API across the entire project");
        console.log("  - Type feels like it has built-in methods");
    }
}

// ============================================
// 演示：模拟没有 global 的情况
// ============================================

// 假设我们有一个自定义类型
type MyNumber is uint256;

// 没有 global 的库
library MyNumberLib {
    function double(MyNumber n) internal pure returns (MyNumber) {
        return MyNumber.wrap(MyNumber.unwrap(n) * 2);
    }
    
    function square(MyNumber n) internal pure returns (MyNumber) {
        uint256 val = MyNumber.unwrap(n);
        return MyNumber.wrap(val * val);
    }
}

// 对比：有 global 的库
library MyNumberLibGlobal {
    function triple(MyNumber n) internal pure returns (MyNumber) {
        return MyNumber.wrap(MyNumber.unwrap(n) * 3);
    }
}

// 声明 global
using MyNumberLibGlobal for MyNumber global;

contract GlobalVsLocalTest is Test {
    // 对于没有 global 的库，必须在每个合约中声明
    using MyNumberLib for MyNumber;
    
    function test_LocalVsGlobal() public {
        console.log("\n=== Local vs Global 'using' ===\n");
        
        MyNumber num = MyNumber.wrap(5);
        
        // 本地声明的 using（仅在此合约中有效）
        MyNumber doubled = num.double();
        MyNumber squared = num.square();
        
        console.log("Original number:", MyNumber.unwrap(num));
        console.log("Doubled (local using):", MyNumber.unwrap(doubled));
        console.log("Squared (local using):", MyNumber.unwrap(squared));
        
        // 全局声明的 using（在整个项目中有效）
        MyNumber tripled = num.triple();
        console.log("Tripled (global using):", MyNumber.unwrap(tripled));
        
        console.log("\nNote:");
        console.log("  - double() and square() need 'using MyNumberLib for MyNumber;' in THIS contract");
        console.log("  - triple() works everywhere because of 'global'");
    }
}

// ============================================
// 另一个合约，演示 global 的作用域
// ============================================
contract AnotherContract is Test {
    // 注意：我们没有声明 using MyNumberLib for MyNumber
    
    function test_GlobalScope() public {
        console.log("\n=== Testing Global Scope ===\n");
        
        MyNumber num = MyNumber.wrap(10);
        
        // triple() 可以工作，因为是 global
        MyNumber tripled = num.triple();
        console.log("Number:", MyNumber.unwrap(num));
        console.log("Tripled (works because of global):", MyNumber.unwrap(tripled));
        
        // 下面这行会编译错误，因为 double() 不是 global 的
        // MyNumber doubled = num.double();  // ❌ Error: Member "double" not found
        
        console.log("\nThis demonstrates that:");
        console.log("  - triple() is available (declared as global)");
        console.log("  - double() is NOT available (not global, not declared locally)");
    }
}

