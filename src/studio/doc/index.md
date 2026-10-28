# 架构现状

## 状态管理

使用 `GameController`（ChangeNotifier）+ 全可变状态。

## 架构

```
UI → GameController (ChangeNotifier) → notifyListeners()
       ↓ 直接变异
     GameState (全部 mutable)
       ├─ List<Unit> (mutable)
       ├─ Campaign (mutable)
       └─ engine → Game (纯函数工具, 不变)
```

## 依赖

```
CampaignConfig ← Game ─→ GameController → Unit/Campaign (变异)
                        ↕
                   CombatService (combat.dart, 纯函数)
```

- Game 不依赖 GameController
- 战斗逻辑已抽离到 `combat.dart`（`resolveCombat` 纯函数）
- 回合管理、AI 逻辑、UI 通知全部在 GameController
