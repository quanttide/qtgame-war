#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
田花园战斗剧本库生成器 - dry-python (returns) 重构版
只生成初始参数组合，不预设玩家决策。
使用函数式风格：Result, Maybe, 管道
"""

import json
import random
from typing import List, Dict, Optional, Tuple

from returns.result import Result, Success, Failure
from returns.maybe import Maybe, Some, Nothing
from returns.pipeline import flow, pipe
from returns.pointfree import bind, map_
from returns.curry import curry

# ---------- 类型别名 ----------
ScriptParams = Dict[str, any]  # 原始参数字典
ScriptRecord = Dict[str, any]  # 最终输出的一条记录


# ---------- 参数空间定义（纯数据） ----------
NIGHT_TURNS = (3, 4, 5)
MORALE_VALUES = (0.6, 0.7, 0.8, 0.9)
AMMO_VALUES = (0.5, 0.7, 0.9)
TANK_APPEAR = (None, 2, 3, 4)
REINFORCE_TURNS = (None, 5, 6)


@curry
def random_choice(choices: Tuple) -> Maybe:
    """从元组中随机选一个值，返回 Maybe（空元组返回 Nothing）"""
    if not choices:
        return Nothing
    return Some(random.choice(choices))


def generate_random_params(seed: Optional[int] = None) -> ScriptParams:
    """生成一组随机参数（副作用：随机数）"""
    if seed is not None:
        random.seed(seed)
    return {
        'night_turns_remaining': random.choice(NIGHT_TURNS),
        'infantry_morale': random.choice(MORALE_VALUES),
        'infantry_ammo': random.choice(AMMO_VALUES),
        'commander_alive': True,
        'tank_appear_turn': random.choice(TANK_APPEAR),
        'enemy_reinforce_turn': random.choice(REINFORCE_TURNS),
    }


def add_metadata(script_id: int, params: ScriptParams) -> ScriptRecord:
    """添加 id 和随机种子，并转换 None 为 -1"""
    record = {
        'script_id': script_id,
        'night_turns_remaining': params['night_turns_remaining'],
        'infantry_morale': params['infantry_morale'],
        'infantry_ammo': params['infantry_ammo'],
        'commander_alive': params['commander_alive'],
        'tank_appear_turn': params['tank_appear_turn'] if params['tank_appear_turn'] is not None else -1,
        'enemy_reinforce_turn': params['enemy_reinforce_turn'] if params['enemy_reinforce_turn'] is not None else -1,
        'random_seed': random.randint(0, 2**31-1),
    }
    return record


def generate_scripts(count: int, seed: Optional[int] = None) -> List[ScriptRecord]:
    """
    生成 count 个剧本记录（纯副作用：随机数生成）
    使用函数式组合：对 id 序列 map
    """
    if seed is not None:
        random.seed(seed)
    # 生成参数列表
    params_list = [generate_random_params() for _ in range(count)]
    # 添加元数据
    records = [add_metadata(i, p) for i, p in enumerate(params_list)]
    return records


# ---------- 文件写入（Result 风格） ----------
def write_jsonl_file(filename: str, records: List[ScriptRecord]) -> Result[str, Exception]:
    """将剧本列表写入 JSON Lines 文件，返回 Result"""
    try:
        with open(filename, 'w', encoding='utf-8') as f:
            for rec in records:
                f.write(json.dumps(rec, ensure_ascii=False) + '\n')
        return Success(f"成功写入 {len(records)} 个剧本到 {filename}")
    except Exception as e:
        return Failure(e)


# ---------- 统计报告（纯函数） ----------
def count_distribution(records: List[ScriptRecord], key: str) -> Dict:
    """统计某个字段的分布（纯函数）"""
    from collections import Counter
    values = [rec[key] for rec in records]
    return dict(Counter(values))


def print_report(records: List[ScriptRecord]) -> None:
    """打印统计报告（副作用）"""
    print(f"总剧本数: {len(records)}")
    print("夜间回合分布:", count_distribution(records, 'night_turns_remaining'))
    morale_dist = {k: v for k, v in count_distribution(records, 'infantry_morale').items()}
    print("士气分布:", morale_dist)
    ammo_dist = {k: v for k, v in count_distribution(records, 'infantry_ammo').items()}
    print("弹药分布:", ammo_dist)
    tank_appear = {k: v for k, v in count_distribution(records, 'tank_appear_turn').items() if k != -1}
    print("坦克出现回合分布:", tank_appear)
    reinforce = {k: v for k, v in count_distribution(records, 'enemy_reinforce_turn').items() if k != -1}
    print("援军到达回合分布:", reinforce)


# ---------- 主流程（管道 + Result 处理） ----------
def main(count: int = 20000, output_file: str = "tianhuayuan_scripts.jsonl") -> None:
    """
    主函数：生成 -> 写入 -> 报告
    使用管道风格，但 Result 的 bind 需要适当处理
    """
    # 生成剧本（产生副作用但我们在 Result 外做，因为生成不抛异常）
    scripts = generate_scripts(count, seed=42)  # 固定种子便于复现
    # 写入文件并处理 Result
    result = write_jsonl_file(output_file, scripts)
    # 匹配 Result
    match result:
        case Success(msg):
            print(msg)
            print_report(scripts)
        case Failure(e):
            print(f"写入失败: {e}")


if __name__ == "__main__":
    main()
    