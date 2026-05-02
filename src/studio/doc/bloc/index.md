# Bloc 层现状

## GameBloc

事件驱动已成形（SelectUnit、ClickHex、EndTurn、AiStep），回合骨架（player/ai/gameOver）已就位。仍依赖 Game engine，有直接状态修改。

### 核心问题
1. **状态被直接修改** — `unit.col = tc`、`defender.revealed = true` 等
2. **依赖 Game engine** — engine.resolveCombat() 仍直接改 defender
3. **Bloc 中有 Future.delayed** — 应移到 UI 层
4. **AI 逻辑内嵌** — _onAiStep 占 1/3 代码，应抽 AiService
5. **字符串类型仍在** — side 用 'pla'/'nationalist'

## GameEvent

| 事件 | 触发者 | 含义 |
|------|--------|------|
| SelectUnit | 玩家 | 选中单位 |
| ClickHex | 玩家 | 移动/攻击/切换 |
| EndTurn | 玩家 | 结束回合 |
| ResetGame | 玩家 | 重新开始 |
| AiStep | 内部 | 执行 AI |
| ClearSelection | 内部 | 取消选中 |

问题：AiStep/ClearSelection 是内部事件，应改为私有方法；ClickHex 职责过重。

## GameState

Equatable + copyWith 尝试不可变语义，但 Unit/Campaign 仍可变。

### 核心问题
1. **copyWith 默认深拷贝** — 全量复制单位列表，性能浪费
2. **clearSelection 逻辑逃逸** — 布尔标志混在 copyWith 中
3. **props 字符串签名脆弱** — 依赖 units 顺序
4. **Unit/Campaign 可变性仍在** — 容器不可变但内容裸奔

## 改进方向（Bloc 层）

1. Unit 不可变化，copyWith 直接复用引用
2. 移除 Future.delayed（UI 层监听 phase）
3. AI 逻辑抽到 AiService
4. 拆掉 Game engine，改用纯 Service
5. 类型强化（Side 枚举）
6. 内部事件改为私有方法
