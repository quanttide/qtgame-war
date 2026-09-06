window.SCENES = {
 "generatedAt": "2026-09-06",
 "scenes": [
  {
   "battle": "平津战役",
   "year": 1948,
   "status": "draft",
   "structural_conclusions": [],
   "spine": [
    {
     "date": "1948-11-29",
     "name": "东野入关，完成分割"
    },
    {
     "date": "1949-01-31",
     "name": "北平和平解放"
    }
   ],
   "nodes": [
    {
     "id": "tou",
     "kind": "fork",
     "date": "1948-10-23",
     "label": "傅作义偷袭西柏坡",
     "parents": [],
     "prob": null,
     "note": "",
     "historical": false
    },
    {
     "id": "tou1",
     "kind": "state",
     "label": "偷袭实施，刀尖指向中共神经中枢",
     "note": "正文已含五步推演——斩首战术在1948年的中国是否成立",
     "parents": [
      "tou"
     ],
     "date": "",
     "prob": null,
     "historical": false
    },
    {
     "id": "fu",
     "kind": "fork",
     "date": "1948-11-05",
     "label": "傅作义南撤江南（真正的历史分岔口）",
     "parents": [],
     "prob": null,
     "note": "",
     "historical": false
    },
    {
     "id": "a",
     "kind": "state",
     "label": "A 西撤绥远",
     "note": "保住嫡系但离开战略枢纽，孤悬塞外的死棋",
     "parents": [
      "fu"
     ],
     "date": "",
     "prob": null,
     "historical": false
    },
    {
     "id": "b",
     "kind": "state",
     "label": "B 海运南撤江南",
     "note": "对国民党全局最有利；蒋吞并杂牌与失地盘之顾虑使其未选",
     "parents": [
      "fu"
     ],
     "date": "",
     "prob": null,
     "historical": false
    },
    {
     "id": "c",
     "kind": "state",
     "historical": true,
     "label": "C 固守平津（史实选择）",
     "note": "观望等美援/三战/蒋桂内斗，拖至西退海运两路全锁",
     "parents": [
      "fu"
     ],
     "date": "",
     "prob": null
    },
    {
     "id": "d",
     "kind": "state",
     "historical": true,
     "label": "D 起义（最终史实结局）",
     "parents": [
      "fu"
     ],
     "date": "",
     "prob": null,
     "note": ""
    }
   ],
   "file": "scenes/平津战役.md"
  },
  {
   "battle": "淮海战役",
   "year": 1948,
   "status": "draft",
   "structural_conclusions": [
    "徐州剿总的失败在三个彼此独立且无人排查的单点故障（支点二）",
    "蒋介石遥控指挥与战区指挥官权限的冲突是跨战役的结构性死结（支点三）"
   ],
   "spine": [
    {
     "date": "1948-11-06",
     "name": "战役发起"
    },
    {
     "date": "1948-11-22",
     "name": "歼灭黄百韬兵团"
    },
    {
     "date": "1948-12-15",
     "name": "歼灭黄维兵团"
    },
    {
     "date": "1949-01-10",
     "name": "杜聿明集团覆灭"
    }
   ],
   "nodes": [
    {
     "id": "zi",
     "kind": "fork",
     "date": "1948-01-22",
     "label": "粟裕「子养电」：小淮海→大淮海的转折",
     "parents": [],
     "prob": null,
     "note": "",
     "historical": false
    },
    {
     "id": "zi1",
     "kind": "state",
     "label": "按子养电原案，止步小淮海",
     "note": "未推演",
     "parents": [
      "zi"
     ],
     "date": "",
     "prob": null,
     "historical": false
    },
    {
     "id": "zhang",
     "kind": "fork",
     "date": "1948-11-08",
     "label": "张克侠、何基沣起义与黄百韬「等待44军」",
     "parents": [],
     "prob": null,
     "note": "",
     "historical": false
    },
    {
     "id": "z1",
     "kind": "state",
     "label": "不等44军（或刘峙早两天下令）",
     "parents": [
      "zhang"
     ],
     "date": "",
     "prob": null,
     "note": "",
     "historical": false
    },
    {
     "id": "z1e",
     "kind": "ending",
     "label": "黄兵团建制完整退入徐州，徐州集中45万重兵",
     "note": "小淮海方案落空",
     "parents": [
      "z1"
     ],
     "date": "",
     "prob": null,
     "historical": false
    },
    {
     "id": "z2",
     "kind": "state",
     "label": "第三绥靖区不起义",
     "parents": [
      "zhang"
     ],
     "date": "",
     "prob": null,
     "note": "",
     "historical": false
    },
    {
     "id": "z2e",
     "kind": "ending",
     "label": "华野穿插迟2-4天，黄兵团大概率退入徐州",
     "parents": [
      "z2"
     ],
     "date": "",
     "prob": null,
     "note": "",
     "historical": false
    },
    {
     "id": "du",
     "kind": "fork",
     "date": "1948-12-03",
     "label": "杜聿明「半途刹车」：蒋介石空投手令",
     "parents": [],
     "prob": null,
     "note": "",
     "historical": false
    },
    {
     "id": "du1",
     "kind": "state",
     "label": "扔掉手令，全军沿涡河南下",
     "parents": [
      "du"
     ],
     "date": "",
     "prob": null,
     "note": "",
     "historical": false
    },
    {
     "id": "du1e",
     "kind": "ending",
     "label": "大概率逃到淮南或至少半数突围；黄维仍被歼",
     "parents": [
      "du1"
     ],
     "date": "",
     "prob": null,
     "note": "",
     "historical": false
    },
    {
     "id": "hv",
     "kind": "fork",
     "date": "1948-11-20",
     "label": "黄维兵团双堆集：增援路径的必然性检验",
     "parents": [],
     "prob": null,
     "note": "",
     "historical": false
    }
   ],
   "file": "scenes/淮海战役.md"
  },
  {
   "battle": "豫东战役",
   "year": 1948,
   "status": "scanned",
   "structural_conclusions": [],
   "spine": [
    {
     "date": "1948-06-17",
     "name": "攻打开封"
    },
    {
     "date": "1948-07-06",
     "name": "华野撤出战斗"
    }
   ],
   "nodes": [
    {
     "id": "yu",
     "kind": "fork",
     "date": "1948-06-26",
     "label": "粟裕不打邱清泉改打区寿年（临阵换靶）",
     "parents": [],
     "prob": null,
     "note": "",
     "historical": false
    },
    {
     "id": "yu1",
     "kind": "state",
     "label": "区寿年不犹豫，紧跟邱清泉",
     "parents": [
      "yu"
     ],
     "date": "",
     "prob": null,
     "note": "",
     "historical": false
    },
    {
     "id": "yu1e",
     "kind": "ending",
     "label": "无分割穿插窗口，正面消耗战，豫东战役不会发生",
     "parents": [
      "yu1"
     ],
     "date": "",
     "prob": null,
     "note": "",
     "historical": false
    }
   ],
   "file": "scenes/豫东战役.md"
  },
  {
   "battle": "辽沈战役",
   "year": 1948,
   "status": "draft",
   "structural_conclusions": [
    "国民党军总兵力劣势下不存在兵力运用的活解，只有止损快慢之别",
    "倾巢出动替东野解决了最难的时间与攻坚问题",
    "唯一有价值的剧本（半数撤退）需要的果断正是其结构上不具备的"
   ],
   "spine": [
    {
     "date": "1948-09-12",
     "name": "东野南下，战役发起"
    },
    {
     "date": "1948-10-15",
     "name": "攻克锦州"
    },
    {
     "date": "1948-11-02",
     "name": "沈阳解放"
    }
   ],
   "nodes": [
    {
     "id": "du",
     "kind": "fork",
     "date": "1948-09-15",
     "label": "杜聿明到任，统合东北全权（反事实前提）",
     "parents": [],
     "prob": null,
     "note": "",
     "historical": false
    },
    {
     "id": "xi",
     "kind": "state",
     "label": "倾巢出动西进，不求守土只求撤回关内",
     "parents": [
      "du"
     ],
     "date": "",
     "prob": null,
     "note": "",
     "historical": false
    },
    {
     "id": "liao",
     "kind": "state",
     "label": "廖耀湘兵团西进彰武—新立屯轴线",
     "parents": [
      "xi"
     ],
     "date": "",
     "prob": null,
     "note": "",
     "historical": false
    },
    {
     "id": "lin",
     "kind": "fork",
     "date": "1948-09-25",
     "label": "林彪放弃攻锦、主力东转辽西决战",
     "parents": [
      "liao"
     ],
     "prob": null,
     "note": "",
     "historical": false
    },
    {
     "id": "e1",
     "kind": "ending",
     "label": "放大版辽西围歼战",
     "prob": 60,
     "parents": [
      "lin"
     ],
     "date": "",
     "note": "",
     "historical": false
    },
    {
     "id": "e2",
     "kind": "ending",
     "label": "国民党军半数经营口突围",
     "prob": 30,
     "parents": [
      "lin"
     ],
     "date": "",
     "note": "",
     "historical": false
    },
    {
     "id": "e3",
     "kind": "ending",
     "label": "东西对进成功，东野受挫",
     "prob": 10,
     "parents": [
      "lin"
     ],
     "date": "",
     "note": "",
     "historical": false
    }
   ],
   "file": "scenes/辽沈战役.md"
  }
 ]
};
