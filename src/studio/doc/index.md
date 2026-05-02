# 架构现状

## 状态管理

使用 `GameController`（ChangeNotifier）+ 全可变状态。状态管理从"伪不可变"降级为诚实的全可变。

## 核心决策

| 之前 | 现在 |
|---|---|
| GameState 不可变 + copyWith | GameState 所有字段 mutable |
| Unit 不可变 + copyWith | Unit 字段 public non-final |
| Campaign copy() 浅拷贝 | Campaign 直接变异 |
| Equatable.props 字符串签名伪比较 | notifyListeners() 直接通知 |
| 外部状态管理库依赖 | 零状态管理依赖 |

## 为什么

兵棋的核心 loop（选中→移动→攻击→伤害→下一回合）本质是**原地改状态**。与其维持一个没人遵守的不可变约束，不如诚实可变。

## 影响

- 不再支持时间旅行调试 / 状态回放（当前不需要）
- 代码量减少（-copyWith 样板、-Equatable props）
- 依赖减少（删除外部状态管理库）
- 游戏逻辑更直接，阅读负担降低

## 当前架构

```
UI → GameController (ChangeNotifier) → notifyListeners()
       ↓ 直接变异
     GameState (全部 mutable)
       ├─ List<Unit> (mutable)
       ├─ Campaign (mutable)
       └─ engine → Game (纯函数工具, 不变)
```
