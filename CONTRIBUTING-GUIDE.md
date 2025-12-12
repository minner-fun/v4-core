# 如何向 Uniswap V4 提交 Pull Request

## 📋 提交前检查清单

### 1. 确认问题尚未被修复

在提交 PR 之前，先检查官方仓库是否已经修复：

1. 访问 https://github.com/Uniswap/v4-core
2. 查看最新的 commit 历史
3. 检查是否有类似的 PR 或 issue

### 2. 确认你的修改完整且正确

- ✅ 所有 4 个文件都已修改：
  - `src/types/PoolKey.sol`
  - `src/types/Currency.sol`
  - `src/types/Slot0.sol`
  - `src/types/BalanceDelta.sol`
- ✅ 版本都改为 `^0.8.13`
- ✅ 代码可以编译
- ✅ 测试通过

---

## 🔄 提交 PR 的步骤

### Step 1: 确保你的 fork 是最新的

```bash
# 添加上游仓库（如果还没有添加）
git remote add upstream https://github.com/Uniswap/v4-core.git

# 获取上游的最新更改
git fetch upstream

# 确保你在 main 分支
git checkout main

# 合并上游的更改
git merge upstream/main

# 推送到你的 fork
git push origin main
```

### Step 2: 创建新分支

```bash
# 创建并切换到新分支
git checkout -b fix/solidity-version-pragma

# 或者使用更描述性的名称
git checkout -b fix/update-pragma-for-global-keyword
```

### Step 3: 提交你的更改

```bash
# 查看修改的文件
git status

# 添加修改的文件
git add src/types/PoolKey.sol
git add src/types/Currency.sol
git add src/types/Slot0.sol
git add src/types/BalanceDelta.sol

# 提交（使用清晰的 commit message）
git commit -m "fix: update pragma to ^0.8.13 for files using global keyword"
```

#### 推荐的 Commit Message 格式

```
fix: update pragma to ^0.8.13 for files using global keyword

The `using ... for ... global` syntax requires Solidity 0.8.13+.
Updated version pragma in 4 files to match the language feature requirements:
- src/types/PoolKey.sol
- src/types/Currency.sol
- src/types/Slot0.sol
- src/types/BalanceDelta.sol
```

### Step 4: 推送到你的 fork

```bash
# 推送新分支到你的 GitHub fork
git push origin fix/solidity-version-pragma
```

### Step 5: 在 GitHub 上创建 Pull Request

1. 访问你的 fork：`https://github.com/YOUR_USERNAME/v4-core`
2. GitHub 会显示 "Compare & pull request" 按钮
3. 点击按钮
4. 填写 PR 信息：
   - **Title**: `fix: update pragma to ^0.8.13 for files using global keyword`
   - **Description**: 使用 `PR-TEMPLATE.md` 中的内容
5. 点击 "Create pull request"

---

## 📝 PR 描述建议

### 标题（Title）

简洁明了，遵循项目的 commit 规范：

```
fix: update pragma to ^0.8.13 for files using global keyword
```

### 描述（Description）

使用我为你准备的 `PR-TEMPLATE.md` 内容，它包含：
- 问题描述
- 修改内容
- 受影响的文件
- 测试结果
- 影响分析

---

## 🎯 提交注意事项

### 1. 保持简洁

- ✅ 只修改必要的内容（4 个文件的 pragma）
- ❌ 不要包含其他不相关的修改
- ❌ 不要修改格式、添加注释等

### 2. 遵循项目规范

查看 Uniswap V4 的贡献指南：
- https://github.com/Uniswap/v4-core/blob/main/CONTRIBUTING.md

### 3. 准备回应反馈

维护者可能会：
- 要求修改 commit message
- 要求添加测试（虽然这个改动不太需要）
- 提出其他建议

### 4. 检查 CI/CD

PR 创建后，GitHub Actions 会自动运行测试。确保：
- ✅ 编译成功
- ✅ 测试通过
- ✅ Linting 通过

---

## 💡 额外建议

### 在 PR 中可以提到的要点

1. **这是一个低风险的修复**
   - 只改变 pragma 声明
   - 不影响实际代码逻辑
   - 不影响已部署的合约

2. **提高了可移植性**
   - 其他项目可以更容易地集成这些类型
   - 版本要求更明确

3. **符合最佳实践**
   - pragma 应该匹配使用的语言特性

### 如果需要，可以创建对应的 Issue

在提交 PR 之前，可以先创建一个 Issue 说明这个问题：

**Issue Title**: 
```
Solidity version pragma mismatch in files using `global` keyword
```

**Issue Description**:
```markdown
## Problem
Several files in `src/types/` use the `global` keyword (requires Solidity 0.8.13+) 
but declare compatibility with `^0.8.0`.

## Affected Files
- src/types/PoolKey.sol
- src/types/Currency.sol
- src/types/Slot0.sol
- src/types/BalanceDelta.sol

## Impact
While compilation works with the current `solc = "0.8.26"` in foundry.toml, 
attempting to compile with Solidity 0.8.0-0.8.12 would fail.

## Proposed Solution
Update pragma from `^0.8.0` to `^0.8.13` in these files.

## Reference
- [Solidity 0.8.13 Release Notes](https://blog.soliditylang.org/2022/03/16/solidity-0.8.13-release-announcement/)
```

然后在 PR 中引用这个 Issue：`Fixes #ISSUE_NUMBER`

---

## 🔍 验证步骤

在提交前本地验证：

```bash
# 1. 清理并重新编译
forge clean
forge build

# 2. 运行所有测试
forge test

# 3. 检查 gas 报告（可选）
forge test --gas-report

# 4. 运行 linter（如果项目有）
forge fmt --check
```

---

## 📚 有用的资源

- [Uniswap V4 Core Repository](https://github.com/Uniswap/v4-core)
- [Contributing Guidelines](https://github.com/Uniswap/v4-core/blob/main/CONTRIBUTING.md)
- [Solidity Documentation](https://docs.soliditylang.org/)
- [GitHub PR Best Practices](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests)

---

## ❓ 常见问题

### Q: PR 会被接受吗？
A: 这是一个真实的、有价值的修复，有很大概率被接受。但最终决定权在维护者。

### Q: 需要等多久？
A: Uniswap 项目通常会在几天到几周内回应 PR。耐心等待。

### Q: 如果被拒绝怎么办？
A: 这是学习的好机会。听取反馈，理解原因，下次做得更好。

### Q: 可以在社交媒体上宣传吗？
A: 等 PR 被合并后再分享。过早宣传可能造成压力。

---

## 🎉 提交后

1. **监控 PR 状态**
   - 及时回应评论
   - 根据反馈修改代码

2. **保持专业**
   - 礼貌沟通
   - 理解维护者的观点
   - 愿意做出调整

3. **学习经验**
   - 无论结果如何，这都是宝贵的开源贡献经验
   - 记录学到的东西

---

**祝你的 PR 顺利！** 🚀

这是你对 Uniswap V4 生态系统的贡献，值得自豪！

