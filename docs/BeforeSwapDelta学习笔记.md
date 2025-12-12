# BeforeSwapDelta 类型与位运算学习笔记

## 目录
- [1. BeforeSwapDelta 类型简介](#1-beforeswapdelta-类型简介)
- [2. 用户自定义值类型（User Defined Value Type）](#2-用户自定义值类型user-defined-value-type)
- [3. 位运算：将两个 int128 合并为 int256](#3-位运算将两个-int128-合并为-int256)
- [4. Yul 内联汇编基础](#4-yul-内联汇编基础)
- [5. signextend 符号扩展](#5-signextend-符号扩展)
- [6. 补码（Two's Complement）理解负数](#6-补码twos-complement理解负数)
- [7. 学习资源](#7-学习资源)

---

## 1. BeforeSwapDelta 类型简介

`BeforeSwapDelta` 是 Uniswap V4 中用于表示 beforeSwap hook 返回值的类型。

```solidity
// 定义在 src/types/BeforeSwapDelta.sol
type BeforeSwapDelta is int256;
```

### 结构设计

`BeforeSwapDelta` 使用一个 `int256` 来存储两个 `int128` 值：
- **高 128 位**：`deltaSpecified` - 指定代币的 delta
- **低 128 位**：`deltaUnspecified` - 未指定代币的 delta

```
int256 (256 bits)
┌─────────────────────────┬─────────────────────────┐
│   deltaSpecified        │   deltaUnspecified      │
│   (高 128 位)           │   (低 128 位)           │
└─────────────────────────┴─────────────────────────┘
```

---

## 2. 用户自定义值类型（User Defined Value Type）

### 什么是用户自定义值类型？

Solidity 0.8.8+ 引入的特性，用于创建基于底层类型的强类型包装。

```solidity
type BeforeSwapDelta is int256;
```

### 自动生成的方法

编译器会自动为自定义类型生成两个方法：

#### 1. `wrap()` - 包装
```solidity
BeforeSwapDelta.wrap(int256 value) returns (BeforeSwapDelta)
```

示例：
```solidity
BeforeSwapDelta public constant ZERO_DELTA = BeforeSwapDelta.wrap(0);
```

#### 2. `unwrap()` - 解包
```solidity
BeforeSwapDelta.unwrap(BeforeSwapDelta value) returns (int256)
```

示例：
```solidity
int256 rawValue = BeforeSwapDelta.unwrap(beforeSwapDelta);
console.log("Raw value:", rawValue);
```

### 为什么使用自定义类型？

**类型安全**：防止将不同含义的 `int256` 值混淆使用。

```solidity
// 错误：不能直接赋值
int256 x = 100;
BeforeSwapDelta delta = x;  // ❌ 编译错误

// 正确：必须显式包装
BeforeSwapDelta delta = BeforeSwapDelta.wrap(x);  // ✅
```

---

## 3. 位运算：将两个 int128 合并为 int256

### 3.1 toBeforeSwapDelta 函数

```solidity
function toBeforeSwapDelta(int128 deltaSpecified, int128 deltaUnspecified)
    pure
    returns (BeforeSwapDelta beforeSwapDelta)
{
    assembly ("memory-safe") {
        beforeSwapDelta := or(
            shl(128, deltaSpecified),           // 步骤1: 左移到高位
            and(
                sub(shl(128, 1), 1),            // 步骤2: 创建掩码
                deltaUnspecified                // 步骤3: 提取低128位
            )
        )
    }
}
```

### 3.2 分步解析

#### 步骤1：`shl(128, deltaSpecified)` - 左移 128 位

将 `deltaSpecified` 移动到高 128 位：

```
原始值 (int128):
00000000000000000000000000000001  (1)

左移 128 位后 (int256):
00000000000000000000000000000001 00000000000000000000000000000000
└────────── deltaSpecified ──────┘ └────────── 低128位全0 ──────────┘
```

#### 步骤2：`sub(shl(128, 1), 1)` - 创建低 128 位掩码

```
shl(128, 1):
00000000000000000000000000000001 00000000000000000000000000000000

减 1:
00000000000000000000000000000000 11111111111111111111111111111111
└──────── 高128位全0 ──────────┘ └──────── 低128位全1 ──────────┘

结果 = 0x00000000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
```

#### 步骤3：`and(mask, deltaUnspecified)` - 提取低 128 位

确保 `deltaUnspecified` 只占用低 128 位：

```
deltaUnspecified:
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy

AND mask (低128位全1):
00000000000000000000000000000000 11111111111111111111111111111111

结果:
00000000000000000000000000000000 yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
```

#### 步骤4：`or(step1, step3)` - 合并

```
step1 (高128位有值):
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 00000000000000000000000000000000

OR step3 (低128位有值):
00000000000000000000000000000000 yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy

最终结果:
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
└────── deltaSpecified ─────────┘ └───── deltaUnspecified ────────┘
```

### 3.3 实际示例

```solidity
// 输入
deltaSpecified = 1
deltaUnspecified = 2

// 二进制表示
deltaSpecified (128 bit):
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001

deltaUnspecified (128 bit):
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010

// 合并后的 BeforeSwapDelta (256 bit)
高128位 (deltaSpecified=1):
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001

低128位 (deltaUnspecified=2):
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010
```

---

## 4. Yul 内联汇编基础

### 4.1 什么是 Yul？

Yul 是 Solidity 的低级中间语言，用于编写内联汇编。

### 4.2 关键特点

- **无类型**：所有值都是 256 位（uint256/int256）
- **更底层**：直接操作 EVM 指令
- **更高效**：可以优化 gas 消耗

### 4.3 常用 Yul 指令

#### 算术运算
```solidity
add(x, y)    // x + y
sub(x, y)    // x - y
mul(x, y)    // x * y
div(x, y)    // x / y
mod(x, y)    // x % y
```

#### 位运算
```solidity
and(x, y)    // x & y (按位与)
or(x, y)     // x | y (按位或)
xor(x, y)    // x ^ y (按位异或)
not(x)       // ~x (按位取反)
shl(x, y)    // y << x (左移：y 左移 x 位)
shr(x, y)    // y >> x (逻辑右移)
sar(x, y)    // y >> x (算术右移，保留符号位)
```

#### 比较运算
```solidity
lt(x, y)     // x < y
gt(x, y)     // x > y
eq(x, y)     // x == y
iszero(x)    // x == 0
```

#### 其他重要指令
```solidity
signextend(i, x)  // 从第 (i*8+7) 位进行符号扩展
byte(n, x)        // 获取 x 的第 n 个字节
```

### 4.4 内联汇编示例

```solidity
function example(uint256 a, uint256 b) public pure returns (uint256 result) {
    assembly {
        // 所有变量都是 256 位
        let temp := add(a, b)
        result := mul(temp, 2)
    }
}
```

### 4.5 重要提示

```solidity
// ❌ 错误：Yul 中没有类型
assembly {
    int128 x := shl(128, value);  // 编译错误！
}

// ✅ 正确：所有变量都是 256 位
assembly {
    let x := shl(128, value)      // 正确
}
```

---

## 5. signextend 符号扩展

### 5.1 问题：为什么需要符号扩展？

从 `BeforeSwapDelta` (int256) 中提取 `deltaUnspecified` (int128) 时，如果是**负数**，直接提取会出错。

### 5.2 getUnspecifiedDelta 实现

```solidity
function getUnspecifiedDelta(BeforeSwapDelta delta) 
    internal 
    pure 
    returns (int128 deltaUnspecified) 
{
    assembly ("memory-safe") {
        deltaUnspecified := signextend(15, delta)
    }
}
```

### 5.3 signextend 解析

**语法**：`signextend(i, x)`
- 从第 `(i*8+7)` 位进行符号扩展
- 当 `i=15` 时：`15*8+7 = 127`（int128 的符号位）

### 5.4 工作原理

对于负数 `-42` (int128)：

```
原始 int128 (-42):
符号位↓
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111010110

存储在 int256 的低 128 位时（高位可能是其他值）:
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111010110

如果直接提取（错误）:
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111010110
↑ 变成了一个巨大的正数！

使用 signextend(15, x) 后（正确）:
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111010110
↑ 符号扩展：检查第127位是1，所以高128位全部填充为1
↑ 正确表示 -42
```

### 5.5 规则总结

`signextend(15, x)` 的作用：
1. 检查 `x` 的第 127 位（int128 符号位）
2. 如果第 127 位 = 1（负数）→ 高 128 位填充 1
3. 如果第 127 位 = 0（正数）→ 高 128 位填充 0

---

## 6. 补码（Two's Complement）理解负数

### 6.1 为什么全是 1 是负数？

在计算机中，**有符号整数使用补码表示负数**。

### 6.2 int8 示例（便于理解）

```
正数：
  0 = 00000000
  1 = 00000001
 42 = 00101010
127 = 01111111  ← 最大正数

负数：
 -1 = 11111111  ← 全是 1！
 -2 = 11111110
-42 = 11010110
-128 = 10000000  ← 最小负数
```

### 6.3 符号位规则

对于有符号整数（int8, int128, int256）：
- **最高位 = 0** → 正数
- **最高位 = 1** → 负数

```
int8 范围：
0xxxxxxx  →  0 到 127（正数）
1xxxxxxx  → -1 到 -128（负数）
```

### 6.4 为什么 11111111 = -1？

**验证：1 + (-1) = 0**

```
  00000001  (1)
+ 11111111  (-1)
----------
 100000000  
    ↑
    第9位溢出，在 8 位系统中被丢弃
    
= 00000000  (0) ✅ 正确！
```

这就是为什么 `11111111` 必须是 `-1`，这样加法才能正确工作！

### 6.5 如何读取负数？

**方法：翻转所有位，加 1，得到绝对值**

示例：`11010110` 是什么？
1. 最高位是 1 → 负数
2. 翻转所有位：`11010110` → `00101001`
3. 加 1：`00101001 + 1 = 00101010 = 42`
4. 结果：`-42`

### 6.6 int128 的负数

```
int128 的 -42:
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111010110
 ↑ 符号位 = 1，所以是负数
 
这不是一个大正数！
- 如果看作 uint128：340282366920938463463374607431768211414
- 如果看作 int128：-42 ✅
```

### 6.7 关键理解

| 二进制 | uint8 (无符号) | int8 (有符号) |
|--------|---------------|--------------|
| 01111111 | 127 | 127 (最大正数) |
| 10000000 | 128 | -128 (最小负数) |
| 11111110 | 254 | -2 |
| 11111111 | 255 | -1 |
| 00000000 | 0 | 0 |
| 00000001 | 1 | 1 |

---

## 7. 学习资源

### 7.1 官方文档

#### Yul 语言
- 英文：https://docs.soliditylang.org/en/latest/yul.html
- 中文：https://docs.soliditylang.org/zh/latest/yul.html

#### 内联汇编
- 英文：https://docs.soliditylang.org/en/latest/assembly.html
- 中文：https://docs.soliditylang.org/zh/latest/assembly.html

### 7.2 交互式资源

#### EVM Opcodes
- https://www.evm.codes/
- 查看每个操作码的详细说明、gas 消耗

#### Solidity by Example
- https://solidity-by-example.org/assembly/
- 大量实用的汇编示例

### 7.3 推荐阅读项目

- **Uniswap V4**：https://github.com/Uniswap/v4-core
- **Solmate**：https://github.com/transmissions11/solmate
  - 大量使用汇编优化的库

### 7.4 学习建议

1. ✅ **从基础开始**：先理解位运算（and, or, shl, shr）
2. ✅ **可视化学习**：像本笔记中一样，打印二进制来理解
3. ✅ **对比学习**：看同样功能的 Solidity 代码和 Yul 代码
4. ✅ **关注 gas**：学习 Yul 的主要目的是优化 gas 消耗
5. ✅ **实践为主**：通过编写测试来验证你的理解

---

## 8. 测试代码参考

### 8.1 测试文件位置

```
test/demo/
├── Before.t.sol           # BeforeSwapDelta 位运算演示
├── SignExtend.t.sol       # signextend 指令演示
└── TwoComplement.t.sol    # 补码（负数表示）演示
```

### 8.2 运行测试

```bash
# 运行所有 demo 测试
forge test --match-path "test/demo/*.sol" -vvv

# 运行特定测试
forge test --match-contract BeforeTest -vvv
forge test --match-contract SignExtendTest -vvv
forge test --match-contract TwoComplementTest -vvv
```

### 8.3 重要提示

- 使用 `-vvv` 参数可以看到 `console.log` 输出
- 二进制输出会分段显示，每段 32 位，便于阅读
- 每个测试都会展示中间步骤，帮助理解位运算过程

---

## 9. 总结

### 核心概念回顾

1. **BeforeSwapDelta 类型**
   - 用户自定义值类型，基于 int256
   - 提供类型安全的包装
   - 使用 wrap/unwrap 转换

2. **位打包技术**
   - 将两个 int128 合并到一个 int256
   - 使用位运算（shl, and, or）实现
   - 节省存储空间和 gas

3. **Yul 内联汇编**
   - 无类型，所有值都是 256 位
   - 提供更底层的 EVM 操作
   - 用于性能优化

4. **符号扩展**
   - signextend 用于正确提取有符号整数
   - 保持负数的符号位
   - 关键用于解包操作

5. **补码表示**
   - 计算机表示负数的标准方式
   - 最高位是符号位
   - 全是 1 表示 -1，不是最大数

### 实际应用

这些技术在 Uniswap V4 中用于：
- ✅ **优化存储**：一个 slot 存两个值
- ✅ **节省 gas**：减少存储读写次数
- ✅ **类型安全**：避免类型混淆错误
- ✅ **高性能**：使用汇编优化关键路径

---

**学习日期**：2025-12-10  
**项目**：Uniswap V4 Core  
**重点文件**：`src/types/BeforeSwapDelta.sol`

