"""Manifest-driven prompt builder for hero frame animation.

Reads data/heroes.json and produces, per hero, the list of
(frame_name, prompt, reference_image) needed to generate a 6-frame
sprite set: idle / walk_a / walk_b / atk_a / atk_b / die.

Frames are written to anim_src/<id>/f{n}_<frame>.png so tools/build_anim.py
can crop/align them into assets/anim/<id>/.

Generation itself is driven by tools/run_gen.py (calls the image tool);
this module only assembles prompts so the pipeline is reproducible.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "data" / "heroes.json"

STYLE = (
    "Q-style cartoon, chibi proportions with a big head, thick black outline, "
    "soft cel shading, warm readable game-art colors. 2D game character sprite, "
    "a single full-body character centered on a pure flat white background (#ffffff), "
    "no shadow, no ground, no text, no frame. Side view facing RIGHT. "
    "Feet at the very bottom on one baseline, the whole body visible."
)

FRAME_FILES = {
    "idle": "f0_idle",
    "walk_a": "f1_walk_a",
    "walk_b": "f2_walk_b",
    "atk_a": "f3_atk_a",
    "atk_b": "f4_atk_b",
    "die": "f5_die",
}

POSE = {
    "idle": "POSE: relaxed standing idle, both feet flat on the baseline, weapon held ready, calm alert stance.",
    "walk_a": "POSE: a WALKING stride, front (right) leg lifted and stepping forward with the knee bent, back leg extended behind, body leaning slightly forward.",
    "walk_b": "POSE: the OPPOSITE walking stride, back leg lifted and swinging forward, front leg planted, body bobbed slightly up and upright.",
    "die": "POSE: DEFEATED and knocked out, lying on the BACK on the ground, body horizontal, limbs sprawled limp, dizzy spiral eyes, weapon dropped beside; the whole body oriented horizontally in the lower half of the frame.",
}

# role -> (attack windup, attack strike)
POSE_ATK = {
    "melee": (
        "POSE: an ATTACK WINDUP, the weapon pulled back, body coiled with weight on the back foot, leaning back ready to strike.",
        "POSE: an ATTACK STRIKE, the weapon swung/thrust fully FORWARD to the right, body lunging forward with weight on the front foot, dynamic follow-through.",
    ),
    "ranged": (
        "POSE: an AIM/CHARGE windup, leveling and bracing the weapon forward to the right, drawing or charging it, focused.",
        "POSE: a FIRE/RELEASE, the weapon fired forward to the right with a bright muzzle flash / launched projectile, slight recoil, body braced.",
    ),
    "tank": (
        "POSE: a GUARD windup, the shield pulled back close, body coiled with weight on the back foot, ready to ram.",
        "POSE: a SHIELD BASH strike, the shield rammed/thrust fully FORWARD to the right, arm extended, body lunging forward.",
    ),
}


def _atk_kind(role: str) -> str:
    if role == "ranged":
        return "ranged"
    if role == "tank":
        return "tank"
    return "melee"


def load_manifest() -> dict:
    return json.loads(MANIFEST.read_text())


def hero_prompt(hero: dict, frame: str) -> str:
    look = hero["look"]
    if frame in ("atk_a", "atk_b"):
        wind, strike = POSE_ATK[_atk_kind(hero["role"])]
        pose = wind if frame == "atk_a" else strike
    else:
        pose = POSE[frame]
    subject = f"Match EXACTLY this same character across all frames: {look}."
    return f"{subject} {STYLE} {pose}"


def hero_frames(hero: dict):
    """Yield (frame_name, src_filename) in generation order (idle first)."""
    for frame in ["idle", "walk_a", "walk_b", "atk_a", "atk_b", "die"]:
        yield frame, FRAME_FILES[frame]


if __name__ == "__main__":
    import sys

    m = load_manifest()
    wanted = set(sys.argv[1:])
    for h in m["heroes"]:
        if wanted and h["era"] not in wanted and h["id"] not in wanted:
            continue
        print(f"=== {h['id']} ({h['era']}/{h['role']}) {h['name']} anim={h['anim']}")
        for frame, _ in hero_frames(h):
            print(f"  [{frame}] {hero_prompt(h, frame)[:120]}...")
