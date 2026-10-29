# studio TODO

> 工作记忆的近端待办。版本计划见主仓 `data/roadmap/qtgame-war/`（旧编号，待回流），设计共识见创始人档案仓 `qtgame-war/` 分区，规约见 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 已交付：v0.0.1 可玩 Demo（已固定：`studio/v0.0.1`，2026-10-29）

**背景**：用户 2026-10-29 两次修正方向——引擎优化让路，先看到能玩的 demo。Demo 建在现状上，零架构改动。

**核实结论**：闭环代码已齐——结算弹窗+重开（`headquarters_screen.dart` L48/L75）、战报尾 8 条（`plan_view.dart` L420）、回合横幅（L232）、`reset()` 全量复位。Demo 缺的是走查与交付，不是功能。

步骤：

- [x] 0. 历次 ROADMAP 重排（版本号已再演进两轮，现行编号与主线见 ROADMAP 头部）
- [x] 1. 一局闭环人工走查（已走查多轮，3 个卡点全修）
- [x] 2. 走查卡点修复（按实修，上限 3 处。候选以走查为准：战报仅尾 8 条太挤、AI 500ms 无进度反馈、结算弹窗体验）——第 1 处已修：开局弹一次玩法说明（`_showHowToPlay`，真实启动路径专属，不进测试）。第 2 处已修：主页面减法——删情报看板、方案卡、通信科、顶栏状态点，「结束回合」提为底部主按钮。第 3 处已修：战况组件整体下线（`plan_view.dart` 删除），指挥官决策卡上线（点卡→`translateOrders`→`CommandExecutor`→地图行动），玩法说明与 demo.md 改写为决策流
- [x] 3. Demo 交付物：Linux 客户端已本地安装（`~/.local/share/qtgame-war/` + `qtgame-war` 命令 + 应用菜单「QtGame War」）+ `demo.md` 十句操作说明——验收：不看代码的人按说明能打完一局（已随走查验证）

**边界**：守卫/原语/注入/清专名一律不碰；「能赢、看得懂」归 v0.0.2，引擎清理归 v0.0.3。

**下一步**：v0.0.3 组 4「剧本资产收尾」分解已备（见下），随时开工；v0.0.2 五项已全部落地（2026-10-29）。

## 已完成：v0.0.2 可赢可读（帝丘店成局）（2026-10-29，详见 ROADMAP 同名节）

**为何是它**：固定 tag 后实机玩不顺——bot 实跑第 13 回合超时判负（赢不了），战报出口删了（看不到变化），三卡两同（重复点）。引擎归 v0.0.3，本版只修剧本数据、反馈出口与决策语义。

**验收**：种子批 bot 至少一胜；事件条读得出每次决策结果；三卡行为各异。

- [x] 1. 要塞守军接通——不加新单位：现有防线（整25师40旅核心+侧翼）与四支援军补显形，工事 3→1（实测最快 T3 占领，8 胜 4 败）
- [x] 2. 事件条：地图下方一行最新事件（`logMessages` 尾条 `.msg`）
- [x] 3. 决策卡去重：「围困」→「阻击援军」（`reliefTasks` 用 `block`），`reliefPos` 从 null 接到首支存活援军位置
- [x] 4. 整局测试升种子批（12 固定种子，断言至少一胜；附带坑：同进程二次 `CampaignConfig.load` 挂起、跨 testWidgets await 缓存 Future 也挂——缓存值本身）
- [x] 5. 跨版本纪律入册「每版验收必含至少一条赢的路可达」

## 已备未开工：v0.0.3 组 4「剧本资产收尾」分解（原 v0.1.0 抽取，内容不变，随版本顺移）

**为何是它**：ROADMAP 组 4 组头前置声明「宜先于组 3 的收口大改与 v0.0.4『战力换算规则降为注入』开工，减小返工」。本组全是 schema 级改动（JSON key 改名、假字段删除、魔数归配置），现在动一次到位，组 3 与 v0.0.4 就不必二次返工；五行无前置、改动面小、可独立绿。

**现状核实**（2026-10-29 对照代码）：
- `CampaignConfig.load`（`game.dart`）rootBundle IO 与 JSON 解析 inline 混在一起，`fromJson` 无从单测
- 真实资产 `assets/campaigns/diqiudian/{campaign,map,units}.json` 零测试
- `hexSize` 双源实测：`Battlefield.hexSize`（static 27）被几何与 `battlefield_view.dart` 读取；`config.hexSize` 从 JSON 解析后无几何读点——假注入
- 魔数 12 已随任务 2 迁入 `lib/campaigns/diqiudian_victory.dart`（`turn > 12`）
- 手抄 `CampaignConfig` 的测试文件实测 7 个

**方案决断**（`hexSize` 二选一，已决）：删 `config.hexSize` 字段与 campaign.json 的 `hex_size` key，`Battlefield.hexSize` 明记为跨剧本表现常量。理由：像素尺寸是 UI 渲染参数，不是剧本事实；「几何收注入值」要动 TerrainBook/几何/视图全链，扩大改动面且无剧本差异化需求。

**红阶段纪律**：新测试引用尚不存在的 `fromJson`/`makeTestConfig`，红就该红在符号缺失；禁止先写空实现占位。

步骤（doc → test → lib）：

- [ ] 1. doc：`doc/models/game.md` CampaignConfig 节写明「`fromJson(campaignJson, mapJson, unitsJson)` 纯函数 + `load` 薄 IO 壳」；字段表删 `hexSize` 行；变更记录加 key 改名、`hexSize` 字段删除两条——验收：doc 无 `hex_size` 残留表述
- [ ] 2. test：`fromJson` 单元测试（`dart:io` File 读三份真实 JSON 传入，断言 name/`max_turns`/`initial_player_power`/templates/units 非空/mapGrid 尺寸与 grid_cols、rows 一致/catalog 含 is_core）；`max_turns: N` 驱动第 N+1 回合判败的控制器测试；`test/fixtures.dart` 抽 `makeTestConfig({...覆盖项})` builder 并重构 7 个测试文件改用——验收：`flutter test` 红在符号缺失；故意改坏 map.json 一个地形 id 时真实资产测试变红
- [ ] 3. lib：`game.dart` 拆 `fromJson(c, m, u)` 纯函数，`load` 只留 IO + decode + 调用；JSON key `initial_huaye_power` → `initial_player_power` 并同步 campaign.json；删 `CampaignConfig.hexSize` 字段与解析（`battlefield_view.dart` 已读 static，不动）；`diqiudian_victory.dart` `turn > 12` 改 `turn > config.maxTurns`——验收：`flutter test` 全绿；`grep -rn "hex_size\|huaye" lib/ assets/` 零命中
- [ ] 4. 收尾：ROADMAP 组 4 五条勾选（第 2 条「五个」→「七个」、第 5 条魔数新家同步、`hexSize` 条记录已决方向）；已知缺陷索引 `maxTurns` 条同步；本文件更新——验收：索引与勾选行一致

## 已交付

### 任务 2 — 可注入胜负策略（2026-10-29 完成）

- 核心：`lib/models/victory_policy.dart` 定形状（`VictoryPolicy` 签名含 `TerrainBook`——核心据点判断要查地形属性，较原分解的三参签名多传一个）；`Game.checkVictory` 降为调用+落盘+返回战报，`gameOver` 已置位不再评估
- 剧本：`lib/campaigns/diqiudian_victory.dart` 四条件（红全灭胜/占核心且工事 0 胜/蓝全灭败/`turn > 12` 败）+ 文案 + 超时战报（turn 透传，修正原写死 0）
- `game_controller.dart` 两处手写失败块删除，胜负出口收敛到 `checkVictory`；`headquarters_screen.dart` 注入 `diqiudianVictory(config)`
- 测试 77 → 93：策略四条件分支、`checkVictory` 转发/落盘/已结束不评估、控制器判败转 gameOver、超时战报入 logMessages
- 收尾已同步：ROADMAP 任务 2 勾选、已知缺陷索引改「控制器余 3 处专名，胜负详情/超时战报已迁策略实现」；复盘四缺陷已登记 ROADMAP（评估时序耦合、gameOver 双标志、战报无结构、注入双通道）

## 路线备忘

- **落地主线（2026-10-29 三次修正）**：v0.0.1 可玩 Demo（已固定）→ v0.0.2 可赢可读 → v0.0.3 引擎收口 → v0.0.4 龙王店可玩竖切 → v0.0.5 完整战役；v0.1.0 帝丘店与组 5 不在主线。
- v0.0.3 组 3（原语拆分 + 状态所有权收口，两线：守卫归一、状态单源；胜负评估收敛随守卫唯一化同批；原三条注入化幽灵行已删）待 v0.0.2 后按组内任务行分解。
- v0.0.3 组 5 确定性双跑非主线，宜在 v0.0.4「endTurn 改可等待」后做，v0.2.0 前补齐即可。
- **实战教训（2026-10-29）**：整局测试绿 ≠ 能玩——bot 那局实为超时判负；「至少一胜」已升为跨版本纪律，验收写「打完」不算数。
- 主仓 `data/roadmap/qtgame-war/` 基线仍为旧编号，待回流（映射见 ROADMAP 头部编号说明）。
