#!/usr/bin/env python3
"""从 scenes/*.md 的 frontmatter 生成 scenes.js（window.SCENES），供 index.html 渲染。

剧本 md 是事实源；每次修改剧本元数据后重跑本脚本：
    python3 build.py

schema v3（DAG）：
- spine: 史实事件轴 [{date, name}]
- nodes: 推演图节点 [{id, kind: fork|state|ending, label, date?, parents[], prob?, note?, historical?}]
  真实历史是图中已被现实走过的路径；分支可级联（fork → state → fork → …）。
"""
import json
import re
from datetime import date
from pathlib import Path

import yaml

HERE = Path(__file__).resolve().parent
SCENE_DIR = HERE / "scenes"


def parse(path: Path) -> dict:
    text = path.read_text(encoding="utf-8")
    m = re.match(r"^---\n(.*?)\n---\n?", text, re.S)
    meta = yaml.safe_load(m.group(1)) if m else {}
    meta = meta or {}
    meta["file"] = f"scenes/{path.name}"
    meta.setdefault("battle", path.stem)
    meta.setdefault("year", "")
    meta.setdefault("status", "scanned")
    meta.setdefault("structural_conclusions", [])
    meta["spine"] = [
        {"date": str(it.get("date", "")), "name": it.get("name", "")}
        for it in (meta.get("spine") or [])
    ]
    meta["nodes"] = [norm_node(n) for n in (meta.get("nodes") or [])]
    meta.pop("variant", None)
    meta.pop("focal_points", None)
    meta.pop("outcomes", None)
    return meta


def norm_node(n):
    if isinstance(n, str):
        n = {"id": n, "kind": "state", "label": n}
    n.setdefault("id", "")
    n.setdefault("kind", "state")
    n.setdefault("label", "")
    n.setdefault("date", "")
    n["date"] = str(n["date"] or "")
    n.setdefault("parents", [])
    n.setdefault("prob", None)
    n.setdefault("note", "")
    n.setdefault("historical", False)
    return n


def main():
    scenes = [parse(p) for p in sorted(SCENE_DIR.glob("*.md"))]
    payload = {"generatedAt": date.today().isoformat(), "scenes": scenes}
    js = "window.SCENES = " + json.dumps(payload, ensure_ascii=False, indent=1) + ";\n"
    (HERE / "scenes.js").write_text(js, encoding="utf-8")
    print(f"scenes.js written: {len(scenes)} scenes")


if __name__ == "__main__":
    main()
