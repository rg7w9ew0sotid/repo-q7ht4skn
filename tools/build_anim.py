#!/usr/bin/env python3
"""Turn per-frame AI art (white background) into aligned, transparent animation
frames + a JSON manifest so units don't jitter between frames.

Input : anim_src/<unit>/{f0_idle,f1_walk_a,f2_walk_b,f3_atk_a,f4_atk_b,f5_die}.png
Output: assets/anim/<unit>/{idle,walk_a,walk_b,atk_a,atk_b,die}.png (all same size)
        assets/anim/<unit>/meta.json  {anchor:[x,y], char_height, canvas:[w,h]}

All standing frames are aligned on a common canvas so the character's FEET sit at
a fixed anchor point; the "die" frame (lying down) is anchored bottom-centre.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from slice_assets import remove_connected_background  # noqa: E402


# logical name -> source filename stem
FRAMES = {
    "idle": "f0_idle",
    "walk_a": "f1_walk_a",
    "walk_b": "f2_walk_b",
    "atk_a": "f3_atk_a",
    "atk_b": "f4_atk_b",
    "die": "f5_die",
}
STANDING = ("idle", "walk_a", "walk_b", "atk_a", "atk_b")


def trimmed(path: Path, tolerance: float) -> Image.Image:
    rgba = remove_connected_background(Image.open(path).convert("RGB"), tolerance)
    bbox = rgba.getbbox()
    return rgba.crop(bbox) if bbox else rgba


def feet_anchor(img: Image.Image) -> tuple[int, int]:
    """Horizontal centre of the bottom band of opaque pixels; bottom row."""
    w, h = img.size
    alpha = img.split()[3].load()
    band = max(1, int(h * 0.12))
    xs: list[int] = []
    for y in range(h - band, h):
        for x in range(w):
            if alpha[x, y] > 40:
                xs.append(x)
    cx = int(sum(xs) / len(xs)) if xs else w // 2
    return cx, h - 1


def build_unit(src_dir: Path, out_dir: Path, tolerance: float) -> None:
    imgs: dict[str, Image.Image] = {}
    anchors: dict[str, tuple[int, int]] = {}
    for name, stem in FRAMES.items():
        path = src_dir / f"{stem}.png"
        if not path.exists():
            continue
        img = trimmed(path, tolerance)
        imgs[name] = img
        if name == "die":
            anchors[name] = (img.size[0] // 2, img.size[1] - 1)
        else:
            anchors[name] = feet_anchor(img)

    # Canvas large enough that every frame fits with its anchor at (L, T).
    left = max(anchors[n][0] for n in imgs)
    right = max(imgs[n].size[0] - 1 - anchors[n][0] for n in imgs)
    top = max(anchors[n][1] for n in imgs)
    bottom = max(imgs[n].size[1] - 1 - anchors[n][1] for n in imgs)
    canvas_w, canvas_h = left + right + 1, top + bottom + 1

    out_dir.mkdir(parents=True, exist_ok=True)
    for name, img in imgs.items():
        ax, ay = anchors[name]
        canvas = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))
        canvas.paste(img, (left - ax, top - ay), img)
        canvas.save(out_dir / f"{name}.png", "PNG", optimize=True)

    meta = {
        "anchor": [left, top],
        "char_height": imgs["idle"].size[1] if "idle" in imgs else canvas_h,
        "canvas": [canvas_w, canvas_h],
    }
    (out_dir / "meta.json").write_text(json.dumps(meta, indent=2))
    print(f"{src_dir.name}: canvas {canvas_w}x{canvas_h} anchor {left},{top} "
          f"char_h {meta['char_height']} frames {sorted(imgs)}")


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser()
    parser.add_argument("units", nargs="*", help="unit dir names under anim_src/")
    parser.add_argument("--src", type=Path, default=root / "anim_src")
    parser.add_argument("--out", type=Path, default=root / "assets" / "anim")
    parser.add_argument("--tolerance", type=float, default=33.0)
    args = parser.parse_args()

    names = args.units or [p.name for p in sorted(args.src.iterdir()) if p.is_dir()]
    for name in names:
        build_unit(args.src / name, args.out / name, args.tolerance)


if __name__ == "__main__":
    main()
