#!/usr/bin/env python3
"""Slice the generated art sheets into transparent, tightly-cropped sprites."""

from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path

from PIL import Image


SHEETS = {
    "cards_sheet.png": ("cards", 4, 2, (
        "stone_axe", "club", "spear", "sling",
        "bone", "campfire", "gold", "pelt",
    )),
    "units_sheet.png": ("units", 3, 2, (
        "clubber", "shield", "spearman",
        "slinger", "shaman", "healer",
    )),
    "enemies_sheet.png": ("enemies", 3, 2, (
        "sabertooth", "mammoth", "bear",
        "raptor", "boar", "enemy_caveman",
    )),
}


def color_distance(a: tuple[int, int, int], b: tuple[int, int, int]) -> float:
    return sum((x - y) ** 2 for x, y in zip(a, b)) ** 0.5


def remove_connected_background(image: Image.Image, tolerance: float = 33.0) -> Image.Image:
    """Remove the sheet's beige background, preserving enclosed artwork areas."""
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    width, height = rgba.size
    sample_points = [(0, 0), (width - 1, 0), (0, height - 1), (width - 1, height - 1)]
    key = tuple(sum(rgba.getpixel(p)[channel] for p in sample_points) // len(sample_points)
                for channel in range(3))
    seen: set[tuple[int, int]] = set()
    queue: deque[tuple[int, int]] = deque()

    for x in range(width):
        queue.append((x, 0))
        queue.append((x, height - 1))
    for y in range(1, height - 1):
        queue.append((0, y))
        queue.append((width - 1, y))

    while queue:
        x, y = queue.popleft()
        if (x, y) in seen:
            continue
        seen.add((x, y))
        pixel = pixels[x, y]
        if color_distance(pixel[:3], key) > tolerance:
            continue
        pixels[x, y] = (pixel[0], pixel[1], pixel[2], 0)
        if x:
            queue.append((x - 1, y))
        if x + 1 < width:
            queue.append((x + 1, y))
        if y:
            queue.append((x, y - 1))
        if y + 1 < height:
            queue.append((x, y + 1))
    return rgba


def slice_sheet(source: Path, output_root: Path, tolerance: float) -> list[Path]:
    image = Image.open(source).convert("RGB")
    category, columns, rows, names = SHEETS[source.name]
    cell_width, cell_height = image.width // columns, image.height // rows
    output_dir = output_root / category
    output_dir.mkdir(parents=True, exist_ok=True)
    written: list[Path] = []

    for index, name in enumerate(names):
        column, row = index % columns, index // columns
        cell = image.crop((
            column * cell_width, row * cell_height,
            (column + 1) * cell_width, (row + 1) * cell_height,
        ))
        transparent = remove_connected_background(cell, tolerance)
        alpha = transparent.getchannel("A")
        bbox = alpha.getbbox()
        if bbox is None:
            raise ValueError(f"{source.name} cell {name!r} contains no foreground")
        # A one-pixel transparent margin prevents edge antialiasing from being clipped.
        left = max(0, bbox[0] - 1)
        top = max(0, bbox[1] - 1)
        right = min(cell_width, bbox[2] + 1)
        bottom = min(cell_height, bbox[3] + 1)
        output = transparent.crop((left, top, right, bottom))
        destination = output_dir / f"{name}.png"
        output.save(destination, "PNG", optimize=True)
        written.append(destination)
    return written


def crop_background(source: Path, destination: Path, box: tuple[int, int, int, int]) -> None:
    image = Image.open(source).convert("RGB")
    image.crop(box).save(destination, "PNG", optimize=True)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--art", type=Path, default=Path(__file__).parents[2] / "game_design" / "art")
    parser.add_argument("--output", type=Path, default=Path(__file__).parents[1] / "assets")
    parser.add_argument("--tolerance", type=float, default=33.0)
    args = parser.parse_args()

    for filename in SHEETS:
        paths = slice_sheet(args.art / filename, args.output, args.tolerance)
        print(f"{filename}: {len(paths)} sprites")

    concept = args.art / "concept_screen.png"
    # Concept is 1024x1536: upper wooden table and lower side-view battle scene.
    crop_background(concept, args.output / "bg_board.png", (42, 118, 982, 785))
    crop_background(concept, args.output / "bg_battle.png", (30, 844, 994, 1488))
    print("backgrounds: bg_board.png, bg_battle.png")


if __name__ == "__main__":
    main()
