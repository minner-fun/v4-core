# 快速 PR 提交指南

## 🚀 快速开始（5 分钟）

### 1️⃣ 准备工作

在 Git Bash 中运行：

```bash
# 确保更改已保存
git status

# 创建新分支
git checkout -b fix/solidity-version-pragma
```

### 2️⃣ 提交更改

```bash
# 添加修改的文件
git add src/types/PoolKey.sol src/types/Currency.sol src/types/Slot0.sol src/types/BalanceDelta.sol

# 提交
git commit -m "fix: update pragma to ^0.8.13 for files using global keyword

The using ... for ... global syntax requires Solidity 0.8.13+.
Updated version pragma in 4 files to match language feature requirements."

# 推送到你的 fork
git push origin fix/solidity-version-pragma
```

### 3️⃣ 创建 PR

1. 打开你的 fork：https://github.com/YOUR_USERNAME/v4-core
2. 点击 "Compare & pull request" 按钮
3. 复制 `PR-TEMPLATE.md` 的内容到 PR 描述
4. 提交！

---

## 📋 检查清单

提交前确认：

- [ ] 已更新 4 个文件的 pragma 为 `^0.8.13`
- [ ] 运行 `forge build` 成功
- [ ] 运行 `forge test` 通过
- [ ] 创建了新分支（不要直接在 main 上提交）
- [ ] commit message 清晰明了
- [ ] PR 描述完整（使用 PR-TEMPLATE.md）

---

## 📝 修改总结

| 文件 | 修改内容 |
|------|---------|
| `src/types/PoolKey.sol` | `^0.8.0` → `^0.8.13` |
| `src/types/Currency.sol` | `^0.8.0` → `^0.8.13` |
| `src/types/Slot0.sol` | `^0.8.0` → `^0.8.13` |
| `src/types/BalanceDelta.sol` | `^0.8.0` → `^0.8.13` |

**原因**：这些文件使用了 `global` 关键字，需要 Solidity 0.8.13+

---

## 🎯 PR 信息

### 标题
```
fix: update pragma to ^0.8.13 for files using global keyword
```

### 标签建议
- `bug` 或 `fix`
- `good first issue`（如果适用）

### 描述
使用 `PR-TEMPLATE.md` 中的完整描述

---

## ⚡ 故障排除

### 问题：push 被拒绝
```bash
# 确保你在自己的分支上
git branch

# 如果在 main 上，创建新分支
git checkout -b fix/solidity-version-pragma
```

### 问题：没有 upstream remote
```bash
# 添加上游仓库
git remote add upstream https://github.com/Uniswap/v4-core.git
```

### 问题：本地有其他修改
```bash
# 暂存其他修改
git stash

# 提交你的 PR
# ... 完成后 ...

# 恢复其他修改
git stash pop
```

---

## 💡 小贴士

1. **保持简洁**：只修改 pragma，不要包含其他改动
2. **礼貌沟通**：在 PR 中保持专业和友好
3. **及时回应**：如果维护者有问题，尽快回复
4. **耐心等待**：可能需要几天到几周才有回应

---

## 📱 后续跟进

提交后：
- 检查 GitHub Actions 是否通过
- 关注 PR 评论
- 如有需要，及时修改

---

## 🌟 这次贡献的意义

✅ 修复了真实的兼容性问题  
✅ 提高了代码质量  
✅ 你的名字将出现在 Uniswap V4 的贡献者列表中！  
✅ 为开源社区做出了贡献  

**加油！你做得很好！** 🎉

