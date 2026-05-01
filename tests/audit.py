"""
视觉审计工具：对 src/index.html 截图进行量化分析

用法:
  1. 先用 Chrome headless 截图:
     google-chrome --headless --disable-gpu --screenshot --window-size=1440,900 ../src/index.html
  2. 运行本脚本分析 screenshot.png

依赖: pip3 install pillow
"""

import sys
from PIL import Image, ImageFilter

SCREENSHOT = "screenshot.png"


def gaußian_blur(img: Image.Image):
    for r, name in [(8, "blur8.png"), (15, "blur15.png")]:
        img.filter(ImageFilter.GaussianBlur(radius=r)).save(name)
        print(f"  [✓] 模糊半径 {r} → {name}")


def info_density(gray: Image.Image, bg_val: int = 17, threshold: int = 10):
    px = list(gray.getdata())
    non_bg = sum(1 for p in px if abs(p - bg_val) > threshold)
    return non_bg / len(px) * 100


def density_by_region(img: Image.Image, bg_val: int = 17):
    W, H = img.size
    regions = {
        "header": (0, 0, W, 80),
        "left panel": (0, 80, 320, H),
        "map area": (320, 80, W, H),
    }
    for name, box in regions.items():
        g = img.crop(box).convert("L")
        px = list(g.getdata())
        non_bg = sum(1 for p in px if abs(p - bg_val) > 10)
        print(f"    {name}: {non_bg / len(px) * 100:.1f}%")


def brightness_grid(img: Image.Image, rows=6, cols=10):
    W, H = img.size
    cell_w, cell_h = W // cols, H // rows
    print("    亮度网格（每格平均亮度，背景≈17）:")
    print("     " + "".join(f"{c+1:>5d}0" for c in range(cols)))
    for r in range(rows):
        line = f"R{r+1:>2d}  "
        for c in range(cols):
            cell = img.crop((c * cell_w, r * cell_h, (c + 1) * cell_w, (r + 1) * cell_h)).convert("L")
            px = list(cell.getdata())
            avg = sum(px) / len(px)
            line += f"{avg:>4.0f} "
        print(line)


def gcw_count():
    blocks = [
        "标题栏", "副标题", "Tab:情报(active)", "Tab:命令", "Tab:兵棋",
        "情报:侦察报告[可信]", "情报:模糊情报[存疑]",
        "情报:干扰信息[已证伪]", "情报:后勤报告[可信]",
        "回合卡片x4", "六角格地图9x11", "单位标记x5",
    ]
    print(f"    独立信息块: {len(blocks)} 个（>9 = 超出 GCW 7±2 上限）")
    for b in blocks:
        print(f"      • {b}")


def semantic_distance():
    print("    操作「选命令→看结果」视线路径:")
    path = "地图(看局势) → 切到命令Tab → 左面板(选路线) → 执行栏(点下达) → 弹窗(读结果)"
    print(f"      {path}")
    print("    跨越区域切换: 5 次（健康值 ≤ 3）")


def main():
    try:
        img = Image.open(SCREENSHOT)
    except FileNotFoundError:
        print(f"[!] 未找到 {SCREENSHOT}，请先截图")
        sys.exit(1)

    W, H = img.size
    print(f"尺寸: {W}x{H}\n")

    print("[1] 视觉熵 — 高斯模糊")
    gaußian_blur(img)

    print("\n[2] 信息密度")
    gray = img.convert("L")
    dens = info_density(gray)
    print(f"    全局: {dens:.1f}%")
    density_by_region(img)

    print("\n[3] 视觉动线 — 亮度网格")
    brightness_grid(img)

    print("\n[4] GCW (信息块计数)")
    gcw_count()

    print("\n[5] 语义距离")
    semantic_distance()

    print("\n--- 完成 ---")


if __name__ == "__main__":
    main()
