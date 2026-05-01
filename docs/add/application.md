# 应用层设计

应用层（Bloc）负责接收事件、调用领域层函数、更新状态，并协调层间通信。

---

## 战役模式：一次决策的生命周期

1. 玩家看到叙事文本 + 选项（A/B/C），选择一个意图锁定 → 触发 `CHOOSE_INTENT` 事件
2. 应用层 Bloc 收到事件，调用 `filter_options(intent, all_options)`，过滤出当前意图下可用的选项
3. 玩家在过滤后的选项中做出选择 → 触发 `EXECUTE_DECISION` 事件
4. Bloc 收到事件，调用 `validate_orders(command, force_state)`：
   - 校验失败（体力不足/编制过低）→ 反馈"命令不可执行"及原因，停留在决策阶段
   - 校验通过 → 继续执行
5. 调用 `calculate_consequences(command, battlefield_state, intel)`，计算后果
6. Bloc 更新战场真实态势，同时按情报延迟规则生成 IntelligenceReport（延迟送达玩家）
7. 叙事生成器读取新状态，将领事翻译为战报文本
8. 玩家看到战报，态势图更新（可能带"据报"标记），进入下一轮决策

时间在过程中持续推进：TimeBloc 按战役速度发射脉冲，体力衰减、情报时效性降低在每次脉冲时自动更新。

---

## 兵棋模式：一次攻击的生命周期

1. 玩家点击选中单位 → `SELECT_UNIT` → 对应 Bloc 调用 `calculate_move_range` 和 `calculate_attack_targets`，高亮合法范围
2. 玩家点击合法目标格子 → `ATTACK` 事件
3. Bloc 收到事件，调用 `resolve_combat(attacker, defender, terrain, campaign_state)`
4. 战斗结算返回 `CombatResult`（是否命中、伤害、消灭信息）
5. Bloc 应用结果到 GameState（更新血量、位置，触发消灭）
6. 日志增加战斗条目，UI 刷新
7. 若攻击触发 AI 反击，Bloc 调度 `ai_act()` 步进执行 AI 动作
8. 玩家结束回合 → `END_TURN` → Bloc 推进到 AI 阶段，AI 完成行动后回到玩家阶段
