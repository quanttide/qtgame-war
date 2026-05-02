# 应用层设计

应用层（GameController）负责接收事件、调用领域层函数、更新状态，并协调层间通信。

---

## 战役模式：一次决策的生命周期

1. 玩家看到叙事文本 + 选项（A/B/C），选择一个意图锁定 → 触发 `chooseIntent` 方法
2. 应用层 GameController 收到调用，调用 `filterOptions(intent, allOptions)`，过滤出当前意图下可用的选项
3. 玩家在过滤后的选项中做出选择 → 触发 `executeDecision` 方法
4. GameController 收到调用，调用 `validateOrders(command, forceState)`：
   - 校验失败（体力不足/编制过低）→ 反馈"命令不可执行"及原因，停留在决策阶段
   - 校验通过 → 继续执行
5. 调用 `calculateConsequences(command, battlefieldState, intel)`，计算后果
6. GameController 更新战场真实态势，同时按情报延迟规则生成 IntelligenceReport（延迟送达玩家）
7. 叙事生成器读取新状态，将领事翻译为战报文本
8. 玩家看到战报，态势图更新（可能带"据报"标记），进入下一轮决策

时间在过程中持续推进：TimeController 按战役速度发射脉冲，体力衰减、情报时效性降低在每次脉冲时自动更新。

---

## 兵棋模式：一次攻击的生命周期

1. 玩家点击选中单位 → `selectUnit` → GameController 调用 `calculateMoveRange` 和 `calculateAttackTargets`，高亮合法范围
2. 玩家点击合法目标格子 → `clickHex` → 识别为攻击动作
3. GameController 调用 `resolveCombat(attacker, defender, terrain, campaignState)`
4. 战斗结算返回 `CombatResult`（是否命中、伤害、消灭信息）
5. GameController 直接变异状态（扣血、标记行动、追加日志）
6. `notifyListeners()` 触发 UI 刷新
7. 若攻击触发 AI 反击，待实现
8. 玩家结束回合 → `endTurn()` → GameController 推进到 AI 阶段，AI 完成行动后回到玩家阶段

## 架构说明

- GameController 继承 `ChangeNotifier`，不是 Bloc
- 状态直接变异，不产生新对象
- UI 通过 `ListenableBuilder` 或手动 `addListener` 订阅变更
- 无事件类定义（方法调用替代事件类 + 分发）
- `notifyListeners()` 在每次状态变异后调用
