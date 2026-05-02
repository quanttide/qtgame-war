# Unit 模块现状

## 当前状态

数据容器，无逻辑（除 copy 和 getter）。字段：id, name, side(字符串), col, row, hp(可变), hasActed(可变), revealed(可变), alive(可变) 等。

## 核心问题

1. **可变性泛滥** — hp, hasActed, alive 等可直接修改，副作用难追踪
2. **字符串类型不安全** — side 用 'pla'/'nationalist'，special 用字符串
3. **copy() 未被运用** — 战斗/移动仍直接修改原对象
4. **effectiveMoveRange 摆设** — 返回 baseMoveRange，战役修正未接入
5. **初始数据耦合** — createInitialUnits() 硬编码在 Game 类

## 改进方向

- 改为不可变：所有字段 final，提供 `moveTo()`、`takeDamage()` 等返回新实例
- `enum Side { pla, nationalist }`，特技改为枚举或列表
- 单位模板数据外置（JSON/配置）
- ID 自增生成，避免冲突
