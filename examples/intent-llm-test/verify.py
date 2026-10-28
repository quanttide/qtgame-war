#!/usr/bin/env python3
"""
意图系统数据流验证
验证"情报→判断→意图"链路是否成立：LLM 作为指挥官读取情报，输出判断和意图。
不验证界面效果，只验证数据映射是否正确。
"""

import json
import os
import sys
from openai import OpenAI

# === 战役数据（与 HTML 原型保持一致） ===

CAMPAIGNS = {
    "diqiudian": {
        "name": "帝丘店战役",
        "description": "华野围攻黄百韬兵团，邱清泉胡琏紧急驰援",
        "initial_intent": "defend",
        "initial_intent_label": "积极防御",
        "intel": {
            "text": "黄百韬整25师收缩至帝丘店核心阵地。邱清泉兵团第5军先头已逼近考城，预计3日内抵达。",
            "age": "4小时前",
            "credibility": "中高"
        }
    },
    "kaifeng": {
        "name": "开封战役",
        "description": "华野首次攻占省会城市，政治敏感度高",
        "initial_intent": "protect",
        "initial_intent_label": "保护平民",
        "intel": {
            "text": "开封守敌约3万余人，城防工事坚固。居民约40万人未疏散。",
            "age": "2小时前",
            "credibility": "高"
        }
    },
    "yudong_phase1": {
        "name": "豫东战役·第一阶段",
        "description": "原定围歼区寿年兵团，战场态势不明",
        "initial_intent": "scout",
        "initial_intent_label": "收集情报",
        "intel": {
            "text": "区寿年兵团在龙王店、铁佛寺一带构筑防御。敌军番号及兵力密度尚未完全掌握。",
            "age": "6小时前",
            "credibility": "低"
        }
    }
}

INTENTS = {
    "protect": {"label": "保护平民", "description": "优先保障平民安全，避免附带损伤"},
    "defend":  {"label": "积极防御", "description": "抢时间打击当面之敌，在有利条件下主动出击"},
    "scout":   {"label": "收集情报", "description": "敌情不明，优先摸清状况再做决策"}
}

SYSTEM_PROMPT = """你是一位身经百战的指挥官，正在指挥所里分析战场情报。
你面对的情报可能有以下特征：
- 时效性：情报可能是几小时前获取的，战场可能已经变化
- 可信度：不同来源的情报可靠程度不同
- 信息不完整：你无法看到战场全貌

你的任务是：
1. 判断当前局势（1-2句话）
2. 说明你的指挥意图（从以下三个中选择一个，并解释理由）：
   - 保护平民：优先保障平民安全，避免附带损伤
   - 积极防御：抢时间打击当面之敌，在有利条件下主动出击
   - 收集情报：敌情不明，优先摸清状况再做决策

请以 JSON 格式输出：
{
  "judgment": "你的局势判断",
  "intent": "protect|defend|scout",
  "reasoning": "你为什么选择这个意图",
  "confidence": 0-100之间的数字，表示你对这个判断的确信程度
}
"""


def test_campaign(api_key: str, campaign_id: str, base_url: str = None) -> dict:
    """测试一个战役，看 LLM 的判断是否与预设意图一致。"""
    camp = CAMPAIGNS[campaign_id]
    intel = camp["intel"]

    client = OpenAI(api_key=api_key, base_url=base_url) if base_url else OpenAI(api_key=api_key)

    user_prompt = f"""战役：{camp['name']}
态势：{camp['description']}

最新情报（{intel['age']}，可信度：{intel['credibility']}）：
{intel['text']}

作为指挥官，请做出判断。"""

    response = client.chat.completions.create(
        model="deepseek-chat",
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": user_prompt}
        ],
        response_format={"type": "json_object"},
        temperature=0.3,
    )

    result = json.loads(response.choices[0].message.content)
    expected = camp["initial_intent"]
    result["campaign_id"] = campaign_id
    result["campaign_name"] = camp["name"]
    result["expected_intent"] = expected
    result["expected_label"] = camp["initial_intent_label"]
    result["match"] = (result.get("intent") == expected)
    return result


def main():
    api_key = os.environ.get("DEEPSEEK_API_KEY") or os.environ.get("OPENAI_API_KEY")
    base_url = os.environ.get("DEEPSEEK_BASE_URL")

    if not api_key:
        print("错误：需要设置 DEEPSEEK_API_KEY 或 OPENAI_API_KEY 环境变量")
        sys.exit(1)

    campaign_ids = list(CAMPAIGNS.keys())

    print("=" * 60)
    print("意图系统数据流验证")
    print("验证核心命题：情报 → 判断 → 意图 映射是否成立")
    print("=" * 60)
    print()

    results = {}
    match_count = 0

    for cid in campaign_ids:
        print(f"▶ 测试战役：{CAMPAIGNS[cid]['name']}")
        print(f"  预设意图：{CAMPAIGNS[cid]['initial_intent_label']}")
        print(f"  情报：{CAMPAIGNS[cid]['intel']['text'][:40]}...")
        print("-" * 40)

        result = test_campaign(api_key, cid, base_url)
        results[cid] = result

        print(f"  LLM 判断：{result.get('judgment', 'N/A')}")
        print(f"  LLM 意图：{result.get('intent', 'N/A')} ({INTENTS.get(result.get('intent', ''), {}).get('label', '未知')})")
        print(f"  确信度：{result.get('confidence', 'N/A')}")
        print(f"  推理：{result.get('reasoning', 'N/A')}")
        status = "✅ 匹配" if result["match"] else "❌ 不匹配"
        print(f"  结果：{status}（预设={result['expected_label']}）")
        print()

        if result["match"]:
            match_count += 1

    # 汇总
    print("=" * 60)
    print("汇总")
    print(f"  测试战役数：{len(campaign_ids)}")
    print(f"  匹配数：{match_count}/{len(campaign_ids)}")
    if match_count == len(campaign_ids):
        print("  结论：✅ 规则映射成立——LLM 能从情报中推断出与预设一致的意图")
    else:
        mismatches = [r for r in results.values() if not r["match"]]
        print(f"  不匹配的战役：{[r['campaign_name'] for r in mismatches]}")
        print("  结论：⏳ 规则映射部分成立，需要检查不匹配案例")
    print("=" * 60)


if __name__ == "__main__":
    main()
