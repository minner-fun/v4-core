# Uniswap V4 Core 学习指南

## 📚 目录
1. [项目概述](#项目概述)
2. [核心架构](#核心架构)
3. [学习路径](#学习路径)
4. [核心合约详解](#核心合约详解)
5. [关键概念](#关键概念)
6. [主要流程](#主要流程)
7. [学习建议](#学习建议)

---

## 项目概述

### Uniswap V4 的主要创新

1. **Hooks（钩子）系统** - 最重要的创新
   - 允许在池子生命周期的关键点注入自定义逻辑
   - 通过合约地址的最低位来决定启用哪些钩子

2. **Singleton 架构**
   - 所有池子都在一个合约（PoolManager）中管理
   - 大幅降低创建新池子的 Gas 成本

3. **Flash Accounting（闪电记账）**
   - 使用瞬态存储（transient storage）
   - 只在交易结束时结算净余额

4. **原生 ETH 支持**
   - 直接支持 ETH，无需 WETH 包装

---

## 核心架构

### 架构图示

```
┌─────────────────────────────────────────────────────────────┐
│                         外部用户/合约                           │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                      IUnlockCallback                         │
│                  (实现 unlockCallback)                        │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                       PoolManager                            │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  unlock() - Flash Accounting 入口                     │   │
│  ├──────────────────────────────────────────────────────┤   │
│  │  initialize() - 初始化池子                            │   │
│  │  swap() - 执行交换                                     │   │
│  │  modifyLiquidity() - 添加/移除流动性                   │   │
│  │  donate() - 捐赠                                       │   │
│  ├──────────────────────────────────────────────────────┤   │
│  │  settle/settleFor() - 支付代币                         │   │
│  │  take() - 提取代币                                     │   │
│  │  mint() - 铸造 ERC6909                                 │   │
│  │  burn() - 销毁 ERC6909                                 │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
│  继承自:                                                       │
│  ├─ ProtocolFees (协议费用管理)                               │
│  ├─ ERC6909Claims (多代币记账)                                │
│  ├─ NoDelegateCall (防止 delegatecall)                       │
│  ├─ Extsload/Exttload (存储读取优化)                          │
│  └─ Owned (权限管理)                                          │
└────────────────┬─────────────┬──────────────────────────────┘
                 │             │
                 ▼             ▼
        ┌────────────┐   ┌──────────┐
        │   Hooks    │   │  Pool    │
        │  (钩子系统) │   │ (池子库)  │
        └────────────┘   └──────────┘
```

---

## 学习路径

### 第一阶段：基础概念（1-2天）

#### 1. 了解核心数据类型
**位置：** `src/types/`

学习顺序：
1. **Currency.sol** - 代币类型封装
   - `Currency` 类型（地址零表示 ETH）
   - 相关工具函数

2. **PoolKey.sol** - 池子唯一标识
   ```solidity
   struct PoolKey {
       Currency currency0;      // 较小地址的代币
       Currency currency1;      // 较大地址的代币
       uint24 fee;             // LP 费用
       int24 tickSpacing;      // Tick 间距
       IHooks hooks;           // 钩子合约
   }
   ```

3. **PoolId.sol** - 池子 ID（PoolKey 的哈希）

4. **BalanceDelta.sol** - 余额变化
   - 使用一个 `int256` 存储两个 `int128`
   - amount0 在高 128 位，amount1 在低 128 位

5. **Slot0.sol** - 池子即时状态
   - sqrtPriceX96（价格）
   - tick（当前 tick）
   - protocolFee 等

#### 2. 理解 Lock 机制
**位置：** `src/libraries/Lock.sol`

- Uniswap V4 使用 "解锁-重新锁定" 模式
- 所有操作必须在 `unlock()` 调用中完成
- 使用瞬态存储（transient storage）进行 Flash Accounting

---

### 第二阶段：核心合约（3-5天）

#### 1. PoolManager.sol - 最核心的合约
**位置：** `src/PoolManager.sol`

**关键方法学习顺序：**

1. **unlock()** - 理解 Flash Accounting
   ```solidity
   function unlock(bytes calldata data) external returns (bytes memory)
   ```
   - 解锁合约
   - 回调 `msg.sender.unlockCallback(data)`
   - 检查所有代币是否结算（delta 为 0）
   - 重新锁定

2. **initialize()** - 初始化池子
   - 验证 PoolKey 参数
   - 调用 beforeInitialize hook
   - 初始化池子状态
   - 调用 afterInitialize hook

3. **swap()** - 交换代币
   - 调用 beforeSwap hook（可能修改输入金额）
   - 执行交换（调用 Pool 库）
   - 收取协议费用
   - 调用 afterSwap hook
   - 更新 delta

4. **modifyLiquidity()** - 添加/移除流动性
   - 调用 before/after hooks
   - 修改流动性
   - 返回 callerDelta 和 feesAccrued

5. **settle/take/mint/burn** - 资金流转
   - `settle()`: 向池子支付代币
   - `take()`: 从池子提取代币
   - `mint()`: 铸造 ERC6909 代币（内部记账）
   - `burn()`: 销毁 ERC6909 代币

#### 2. Pool 库
**位置：** `src/libraries/Pool.sol`

这是实际执行 AMM 逻辑的地方：

- **initialize()** - 设置初始价格
- **swap()** - Swap 核心算法
- **modifyLiquidity()** - 流动性管理
- **donate()** - 捐赠给 LP

**关键数据结构：**
```solidity
struct State {
    Slot0 slot0;                           // 当前状态
    uint256 feeGrowthGlobal0X128;          // 全局费用增长
    uint256 feeGrowthGlobal1X128;
    uint128 liquidity;                     // 当前活跃流动性
    mapping(int24 => TickInfo) ticks;      // Tick 数据
    mapping(int16 => uint256) tickBitmap;  // Tick 位图
    mapping(bytes32 => Position.State) positions; // 头寸
}
```

---

### 第三阶段：Hooks 系统（2-3天）

#### 1. IHooks 接口
**位置：** `src/interfaces/IHooks.sol`

**所有可用的钩子：**

```
初始化阶段:
├─ beforeInitialize
└─ afterInitialize

流动性操作:
├─ beforeAddLiquidity
├─ afterAddLiquidity
├─ beforeRemoveLiquidity
└─ afterRemoveLiquidity

交换:
├─ beforeSwap
└─ afterSwap

捐赠:
├─ beforeDonate
└─ afterDonate
```

#### 2. Hooks 库
**位置：** `src/libraries/Hooks.sol`

**核心机制：通过合约地址启用钩子**

```solidity
// 例如，地址: 0x0000000000000000000000000000000000002400
// 二进制: 10 0100 0000 0000
// 启用: beforeInitialize + afterAddLiquidity

uint160 internal constant BEFORE_INITIALIZE_FLAG = 1 << 13;
uint160 internal constant AFTER_INITIALIZE_FLAG = 1 << 12;
uint160 internal constant BEFORE_ADD_LIQUIDITY_FLAG = 1 << 11;
uint160 internal constant AFTER_ADD_LIQUIDITY_FLAG = 1 << 10;
// ... 等等
```

**为什么这样设计？**
- 部署时就确定了钩子权限（不可变）
- Gas 优化：通过位运算快速检查
- 防止恶意钩子：不能声明不执行的钩子

#### 3. 实战：查看 Hook 示例
**位置：** `src/test/` 目录

建议学习的 Hook 示例：
- `EmptyTestHooks.sol` - 最简单的 Hook
- `DynamicFeesTestHook.sol` - 动态费用
- `FeeTakingHook.sol` - 收取额外费用
- `LPFeeTakingHook.sol` - LP 费用收取

---

### 第四阶段：高级概念（3-5天）

#### 1. Flash Accounting（闪电记账）

**核心思想：**
- 不是每次操作都转账
- 记录每个地址对每种代币的"欠款"（delta）
- 交易结束时一次性结算

**涉及的库：**
- `CurrencyDelta.sol` - 管理 delta
- `NonzeroDeltaCount.sol` - 计数非零 delta
- `CurrencyReserves.sol` - 储备管理

**流程示例：**
```
1. unlock() - 开始
2. swap() - delta[user][token0] = -100, delta[user][token1] = 90
3. take() - delta[user][token1] = 80 (提取 10)
4. settle() - 用户转入 100 token0, delta[user][token0] = 0
5. settle() - 用户转入 80 token1 (或用 mint 铸造 ERC6909)
6. 检查所有 delta = 0
7. unlock() 返回 - 完成
```

#### 2. ERC6909 - 多代币标准
**位置：** `src/ERC6909.sol`

**为什么用 ERC6909？**
- 一个合约管理多种代币（比 ERC1155 更简洁）
- Gas 效率高
- 用于内部记账，避免实际转账

**Claims 系统：**
- `src/ERC6909Claims.sol` - 添加 transferFrom 锁定功能

#### 3. 协议费用系统
**位置：** `src/ProtocolFees.sol`

- `protocolFeeController` - 控制器地址
- `setProtocolFee()` - 设置费用
- `collectProtocolFees()` - 收取累积的费用

---

### 第五阶段：数学与算法（3-5天）

深入理解 AMM 数学原理：

#### 1. Tick 系统
**关键文件：**
- `src/libraries/TickMath.sol` - Tick 和价格转换
- `src/libraries/TickBitmap.sol` - Tick 位图（快速查找）

**核心公式：**
```
price = 1.0001^tick
sqrtPriceX96 = sqrt(price) * 2^96
```

#### 2. 流动性数学
- `LiquidityMath.sol` - 流动性计算
- `Position.sol` - 头寸管理
- `SqrtPriceMath.sol` - 平方根价格计算

#### 3. Swap 数学
- `SwapMath.sol` - 交换计算核心
- 实现 x*y=k 曲线在 tick 范围内的计算

#### 4. 定点数运算
- `FixedPoint96.sol` - Q64.96 格式
- `FixedPoint128.sol` - Q128.128 格式
- `FullMath.sol` - 全精度数学
- `UnsafeMath.sol` - 非安全数学（性能优化）

---

## 核心合约详解

### PoolManager.sol

#### 继承关系
```
PoolManager
├── IPoolManager (接口)
├── ProtocolFees (协议费用)
├── NoDelegateCall (安全机制)
├── ERC6909Claims (多代币)
├── Extsload (存储加载)
└── Exttload (瞬态存储加载)
```

#### 状态变量
```solidity
mapping(PoolId id => Pool.State) internal _pools;  // 所有池子的状态
```

#### 修饰器
- `onlyWhenUnlocked` - 必须在解锁状态下调用
- `noDelegateCall` - 禁止 delegatecall

---

### Hooks 系统详解

#### Hook 地址验证

```solidity
// 示例：创建一个只有 beforeSwap 和 afterSwap 的 Hook
// 需要的地址模式：
// 位 7: beforeSwap = 1
// 位 6: afterSwap = 1
// 二进制: 0b11000000 = 0xC0

// 地址必须是: 0x00000000000000000000000000000000000000C0
// 或其他形式，但最低位必须是 0xC0
```

#### Hook 返回值
每个 hook 必须返回自己的函数选择器：
```solidity
function beforeSwap(...) external returns (bytes4) {
    // ... 逻辑
    return IHooks.beforeSwap.selector;
}
```

#### Delta-Returning Hooks
某些 hook 可以返回 delta，影响最终结算：
- `BEFORE_SWAP_RETURNS_DELTA_FLAG`
- `AFTER_SWAP_RETURNS_DELTA_FLAG`
- `AFTER_ADD_LIQUIDITY_RETURNS_DELTA_FLAG`
- `AFTER_REMOVE_LIQUIDITY_RETURNS_DELTA_FLAG`

---

## 关键概念

### 1. Singleton 模式

**V3 vs V4：**
```
V3: 每个池子 = 一个合约
    创建新池: 部署新合约 (~2M gas)

V4: 所有池子 = 一个 PoolManager
    创建新池: 只需初始化 (~100K gas)
```

### 2. Flash Accounting 详解

**传统模式（V1-V3）：**
```solidity
// 每次操作都转账
token0.transferFrom(user, pool, amount0);
token1.transfer(user, amount1);
```

**V4 Flash Accounting：**
```solidity
// 只记录欠款
delta[user][token0] += amount0;
delta[user][token1] -= amount1;

// 最后一次性结算
if (delta[user][token0] > 0) {
    token0.transferFrom(user, pool, delta[user][token0]);
}
```

**优势：**
- 减少转账次数
- 支持复杂的多步骤操作
- 天然支持闪电贷

### 3. Pool Key 系统

Pool 不再是独立合约，而是通过 PoolKey 标识：

```solidity
PoolId = keccak256(abi.encode(poolKey))
```

**为什么需要 5 个参数？**
- `currency0/currency1`: 定义交易对
- `fee`: 不同费率 = 不同池子
- `tickSpacing`: 影响流动性分布
- `hooks`: 不同 hook = 不同行为

### 4. Transient Storage (EIP-1153)

V4 使用瞬态存储优化 Gas：
- 只在交易期间存在
- 比 SSTORE/SLOAD 便宜
- 非常适合 Flash Accounting

**使用位置：**
- `Lock.sol` - 锁状态
- `NonzeroDeltaCount.sol` - 非零 delta 计数
- `CurrencyDelta.sol` - Delta 记录

---

## 主要流程

### 1. 初始化池子流程

```
用户
 ├─> PoolManager.initialize(key, sqrtPriceX96)
     ├─> 验证 PoolKey 参数
     │   ├─ tickSpacing 范围检查
     │   ├─ currency0 < currency1
     │   └─ hooks 地址验证
     │
     ├─> key.hooks.beforeInitialize()  [如果启用]
     │
     ├─> Pool.initialize()
     │   ├─ 检查是否已初始化
     │   ├─ 设置 sqrtPriceX96
     │   ├─ 计算初始 tick
     │   └─ 设置 lpFee
     │
     ├─> emit Initialize(...)
     │
     └─> key.hooks.afterInitialize()  [如果启用]
```

### 2. Swap 流程详解

```
用户
 ├─> 调用 Router 合约
     ├─> Router.unlock(data)
         ├─> PoolManager.unlock(data)
             ├─> Lock.unlock()  // 设置解锁状态
             │
             ├─> Router.unlockCallback(data)  // 回调
             │   │
             │   ├─> PoolManager.swap(key, params, hookData)
             │   │   ├─> 检查 unlocked 状态 ✓
             │   │   ├─> 检查 amountSpecified != 0
             │   │   ├─> Pool.checkPoolInitialized()
             │   │   │
             │   │   ├─> key.hooks.beforeSwap()  [如果启用]
             │   │   │   └─> 可能修改 amountToSwap
             │   │   │
             │   │   ├─> Pool.swap()  // 核心交换逻辑
             │   │   │   ├─> 遍历 ticks 计算
             │   │   │   ├─> 更新价格和流动性
             │   │   │   ├─> 计算协议费用
             │   │   │   └─> 返回 delta
             │   │   │
             │   │   ├─> emit Swap(...)
             │   │   │
             │   │   ├─> key.hooks.afterSwap()  [如果启用]
             │   │   │
             │   │   └─> _accountPoolBalanceDelta()
             │   │       ├─ delta[user][currency0] += amount0
             │   │       └─ delta[user][currency1] += amount1
             │   │
             │   ├─> PoolManager.settle()  // 支付输入代币
             │   │   └─> _accountDelta()  // 减少欠款
             │   │
             │   └─> PoolManager.take()  // 提取输出代币
             │       └─> _accountDelta()  // 增加欠款（提取视为欠款）
             │
             ├─> 检查 NonzeroDeltaCount == 0  // 必须！
             │   └─> 如果不为 0，revert CurrencyNotSettled
             │
             └─> Lock.lock()  // 重新锁定
```

### 3. 添加流动性流程

```
用户
 ├─> Router.unlock(data)
     ├─> PoolManager.unlock(data)
         ├─> Router.unlockCallback(data)
             │
             ├─> PoolManager.modifyLiquidity(key, params, hookData)
             │   ├─> 检查 unlocked ✓
             │   ├─> Pool.checkPoolInitialized()
             │   │
             │   ├─> key.hooks.beforeModifyLiquidity()  [如果启用]
             │   │
             │   ├─> Pool.modifyLiquidity()
             │   │   ├─> 验证 tick 范围
             │   │   ├─> 更新 position
             │   │   ├─> 更新 tick 数据
             │   │   ├─> 计算需要的代币量
             │   │   └─> 返回 principalDelta + feesAccrued
             │   │
             │   ├─> emit ModifyLiquidity(...)
             │   │
             │   ├─> key.hooks.afterModifyLiquidity()  [如果启用]
             │   │
             │   └─> _accountPoolBalanceDelta()
             │
             ├─> PoolManager.settle()  // 支付 token0
             ├─> PoolManager.settle()  // 支付 token1
             │
             └─> [或使用 mint() 铸造 ERC6909]
```

### 4. Flash Loan 实现

V4 天然支持闪电贷（无需额外费用）：

```solidity
contract FlashBorrower is IUnlockCallback {
    function flashLoan(Currency currency, uint256 amount) external {
        poolManager.unlock(abi.encode(currency, amount));
    }
    
    function unlockCallback(bytes calldata data) external returns (bytes memory) {
        (Currency currency, uint256 amount) = abi.decode(data, (Currency, uint256));
        
        // 1. 借出代币
        poolManager.take(currency, address(this), amount);
        
        // 2. 使用代币做一些操作
        // ... 你的逻辑 ...
        
        // 3. 归还代币（+可能的费用）
        currency.transfer(address(poolManager), amount);
        poolManager.settle();
        
        return "";
    }
}
```

---

## 学习建议

### 1. 实践项目

#### 初级项目
1. **创建一个简单的 Swap Router**
   - 实现 `IUnlockCallback`
   - 调用 `swap()` 和 `settle()/take()`

2. **实现基础 Hook**
   - 例如：记录每次 swap 的日志
   - 练习地址计算和部署

#### 中级项目
3. **动态费用 Hook**
   - 根据波动性调整费用
   - 使用 `updateDynamicLPFee()`

4. **流动性挖矿 Hook**
   - 在 afterSwap 中记录交易量
   - 分发奖励代币

#### 高级项目
5. **MEV 保护 Hook**
   - 限制单笔交易滑点
   - 时间加权价格检查

6. **自定义 AMM 曲线**
   - 在 beforeSwap 中修改金额
   - 实现不同的价格曲线

### 2. 调试技巧

#### 使用 Foundry 测试
```bash
# 运行测试
forge test

# 详细输出
forge test -vvvv

# 测试特定合约
forge test --match-contract PoolManagerTest

# Gas 报告
forge test --gas-report
```

#### 使用 Chisel（Solidity REPL）
```bash
# 启动 chisel
chisel

# 测试代码片段
!> uint256 price = 1.0001 ** 100
```

#### 追踪交易
```bash
# 使用 cast 解码
cast decode "swap(((address,address,uint24,int24,address),(int256,bool,uint160),bytes))" <data>

# 模拟调用
cast call <address> "swap(...)" --rpc-url <url>
```

### 3. 参考资源

#### 官方文档
- [Uniswap V4 Docs](https://docs.uniswap.org/contracts/v4/overview)
- [V4 Core GitHub](https://github.com/Uniswap/v4-core)
- [V4 Periphery](https://github.com/Uniswap/v4-periphery)

#### 社区资源
- [Uniswap V4 Book](https://uniswapv4book.com/)
- Hook 示例库: [v4-hooks-examples](https://github.com/uniswap/v4-hooks)
- [V4 模板](https://github.com/uniswap/v4-template)

#### 学习顺序建议
```
第 1 周: 基础概念 + 数据类型
第 2 周: PoolManager + 基本流程
第 3 周: Pool 库 + AMM 数学
第 4 周: Hooks 系统
第 5 周: 高级特性 + 实战项目
```

### 4. 常见问题

#### Q1: 为什么需要 unlock/lock 模式？
**A:** 
- 实现 Flash Accounting
- 减少存储操作
- 支持复杂的多步骤操作

#### Q2: Hook 地址为什么要编码权限？
**A:**
- 部署时确定，不可更改（安全）
- Gas 优化（位运算）
- 防止误导（不能声称有但不实现的 hook）

#### Q3: ERC6909 vs ERC1155？
**A:**
- ERC6909 更简洁，专为 DeFi 设计
- 没有 metadata URI
- Gas 更优

#### Q4: 如何选择 tickSpacing？
**A:**
- 小间距 = 更精细的流动性分布，更高 Gas
- 大间距 = 粗粒度，Gas 低
- 稳定币对：小间距（如 1）
- 波动性大的对：大间距（如 60, 200）

#### Q5: 动态费用如何工作？
**A:**
```solidity
// PoolKey.fee = 0x800000 (最高位为 1)
// Hook 需要实现 beforeSwap 返回 lpFeeOverride
// 调用 updateDynamicLPFee() 更新
```

---

## 进阶主题

### 1. Gas 优化技术

V4 使用的优化：
- **Transient Storage** - EIP-1153
- **Packed Storage** - Slot0 结构体打包
- **Bitmap** - TickBitmap 快速查找
- **Unchecked Math** - UnsafeMath.sol
- **Custom Errors** - 代替 require strings
- **Singleton** - 避免合约部署

### 2. 安全考虑

#### 重入保护
- `Lock` 机制本身提供保护
- `onlyWhenUnlocked` 修饰器

#### Hook 安全
- 验证 hook 地址
- 检查返回值
- Gas 限制（防止 DoS）

#### 价格操纵
- Tick 限制
- 滑点保护
- Oracle 集成（TWAP）

### 3. 与 V3 的差异

| 特性 | V3 | V4 |
|------|----|----|
| 架构 | 每个池一个合约 | 单例模式 |
| 扩展性 | 有限 | Hooks 系统 |
| 费用层级 | 3 个固定 | 无限灵活 |
| 原生 ETH | 否（WETH） | 是 |
| 价格 Oracle | 内置 TWAP | 可选（通过 Hook） |
| 协议费用 | 固定比例 | 动态可配置 |
| Flash 贷款 | 专门函数 | 天然支持 |

---

## 总结

### 核心要点
1. **Singleton + Hooks = 无限可能性**
2. **Flash Accounting = Gas 优化 + 灵活性**
3. **理解 unlock 机制是关键**
4. **Hook 地址编码是巧妙的设计**
5. **V4 是一个平台，不只是 DEX**

### 学习检查清单
- [ ] 理解 PoolKey 和 PoolId
- [ ] 能解释 Flash Accounting 流程
- [ ] 知道如何计算 Hook 地址
- [ ] 理解 unlock/lock 机制
- [ ] 能读懂 Pool.swap() 逻辑
- [ ] 实现过至少一个 Hook
- [ ] 理解 Tick 和价格的关系
- [ ] 熟悉 settle/take/mint/burn
- [ ] 知道如何使用 ERC6909
- [ ] 能实现一个简单的 Router

### 下一步
1. 阅读 v4-periphery 代码（Router 实现）
2. 学习社区的 Hook 示例
3. 参与 V4 开发（提交 Hook 或改进）
4. 关注 V4 的最新发展和 EIP

---

**祝学习顺利！🚀**

如有问题，欢迎参考官方文档或社区讨论。

