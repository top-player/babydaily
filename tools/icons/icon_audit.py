"""核对「手机里装的图标」与「仓库里的图标资源」是否一致。

背景：改完图标后如果桌面还是旧图，先分清是构建产物没带上新图，还是启动器缓存。
本脚本把已安装 APK 拉回来逐像素比对仓库资源，用来排除第一种可能。

用法：
    adb shell pm path com.yjym.baby.babydaily        # 取 base.apk 路径
    adb pull <base.apk> build/iconcheck/installed.apk
    python tools/icons/icon_audit.py

注意：release 构建开了资源路径压缩（AGP resource optimizations），APK 里的
资源名会变成 res/xx.png 这类短名，所以这里按"尺寸"而不是按路径找图标资源。
"""
from __future__ import annotations

import io
import zipfile
from pathlib import Path

from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parents[2]
APK = ROOT / "build" / "iconcheck" / "installed.apk"
RES = ROOT / "android" / "app" / "src" / "main" / "res"
OUT = ROOT / "build" / "iconcheck"

# 生成的图标尺寸（见 gen_icons.py）：传统图标 48/72/96/144/192，自适应前景 108/162/216/324/432
LEGACY = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
FOREGROUND = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}


def diff_ratio(a: Image.Image, b: Image.Image) -> tuple[float, int]:
    """比较两张图"看起来是否一样"。

    透明像素底下的颜色值差异肉眼不可见（AAPT2 重新压缩常改这些值），
    所以先各自合成到同一张奶油底上，再做 RGB 差异。
    返回（不同像素占比, 单通道最大差值 0-255）。
    """
    bg = (252, 240, 223, 255)  # icon2.png 的奶油底色

    def flatten(img: Image.Image) -> Image.Image:
        img = img.convert("RGBA")
        if img.size != a.size:  # 尺寸不同时以第一张为准
            img = img.resize(a.size, Image.LANCZOS)
        canvas = Image.new("RGBA", img.size, bg)
        canvas.alpha_composite(img)
        return canvas.convert("RGB")

    fa, fb = flatten(a), flatten(b)
    diff = ImageChops.difference(fa, fb).convert("L")
    hist = diff.histogram()
    changed = sum(hist[1:])  # 任何非零差异的像素
    total = fa.size[0] * fa.size[1]
    max_delta = max((i for i, count in enumerate(hist) if count), default=0)
    return changed / total, max_delta


def main() -> None:
    if not APK.exists():
        raise SystemExit(f"没找到 {APK}：先按文件头注释里的命令 adb pull 安装包")
    OUT.mkdir(parents=True, exist_ok=True)

    with zipfile.ZipFile(APK) as zf:
        # APK 里的 PNG 按尺寸索引（资源名被压缩成了短名）
        by_size: dict[tuple[int, int], tuple[str, bytes]] = {}
        for name in zf.namelist():
            if not (name.startswith("res/") and name.lower().endswith(".png")):
                continue
            data = zf.read(name)
            try:
                im = Image.open(io.BytesIO(data))
            except Exception:
                continue
            by_size.setdefault(im.size, (name, data))

        print(f"APK: {APK.name}（{APK.stat().st_size / 1024 / 1024:.1f} MB）")
        print(f"其中 {len(by_size)} 种尺寸的 PNG，逐个核对仓库资源：\n")

        worst = 0.0
        worst_delta = 0
        missing = 0
        for kind, table in (("传统", LEGACY), ("自适应前景", FOREGROUND)):
            for density, px in table.items():
                stem = (
                    "ic_launcher.png"
                    if kind == "传统"
                    else "ic_launcher_foreground.png"
                )
                repo = RES / f"mipmap-{density}" / stem
                hit = by_size.get((px, px))
                if hit is None or not repo.exists():
                    missing += 1
                    print(
                        f"  {kind:6} {density:8} {px:3}px  "
                        f"缺失（APK 有={hit is not None} 仓库有={repo.exists()}）"
                    )
                    continue
                name, data = hit
                apk_img = Image.open(io.BytesIO(data))
                (OUT / f"apk_{density}_{stem}").write_bytes(data)
                ratio, max_delta = diff_ratio(Image.open(repo), apk_img)
                worst = max(worst, ratio)
                worst_delta = max(worst_delta, max_delta)
                # 重新压缩会带来极小的量化误差，肉眼不可见
                verdict = (
                    "一致"
                    if ratio == 0
                    else f"量化误差（{ratio:.2%} 像素、单通道最多差 {max_delta}/255）"
                )
                print(f"  {kind:6} {density:8} {px:3}px  {verdict}   [{name}]")

        print()
        if missing:
            print(f"⚠️ 有 {missing} 项缺失：构建时没带上这些密度的图标")
        elif worst == 0 or worst_delta <= 8:
            print(
                f"✅ 安装包里的图标与仓库资源一致"
                f"（最大差异 {worst:.2%}、单通道 {worst_delta}/255，只是重新压缩）"
            )
            print("   若桌面仍显示旧图，是启动器图标缓存 / 主题图标重绘，不是构建问题")
        else:
            print(f"⚠️ 安装包与仓库资源不一致（单通道最多差 {worst_delta}/255）：重装一次新构建的 APK")


if __name__ == "__main__":
    main()
