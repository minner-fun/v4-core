
# src\types\BeforeSwapDelta.sol

## BeforeSwapDelta
BeforeSwapDelta就是一个int256类型
上128位是指定代币的delta，下128位是未指定代币的delta（与afterSwap hook匹配）,上128为存放指定的代币specified tokens，低128为用来存放未指定的代币unspecified tokens
```solidity
type BeforeSwapDelta is int256;
```

## toBeforeSwapDelta
把两个int128，放入到int256类型中。
```solidity
function toBeforeSwapDelta(int128 deltaSpecified, int128 deltaUnspecified)
    pure
    returns (BeforeSwapDelta beforeSwapDelta)
{
    assembly ("memory-safe") {
        beforeSwapDelta := or(
            shl(128, deltaSpecified), 
            and(
                sub(
                    shl(128, 1), 
                    1
                ), 
                deltaUnspecified
            )
        )
    }
}
```

## 用户自定义类型
![](https://docs.soliditylang.org/zh-cn/v0.8.24/types.html#user-defined-value-types)
wrap(底层类型) - 将底层类型包装成自定义类型
```solidity
   BeforeSwapDelta.wrap(int256 value) returns (BeforeSwapDelta)
```
unwrap(自定义类型) - 将自定义类型解包回底层类型
```solidity
   BeforeSwapDelta.unwrap(BeforeSwapDelta value) returns (int256)
```