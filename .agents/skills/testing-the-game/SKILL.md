---
name: testing-the-game
description: How to run and GUI-test the Deck & Merge (牌桌远征) Godot game, plus the art-asset invariants (transparent/trimmed sprites, empty runtime backgrounds) that testing must guard.
---

# 测试《牌桌远征》(Deck & Merge)

Godot 4.7.x 竖屏(720×1280)手机游戏。核心循环:凌乱牌堆点击取卡 → 7 格合成台 3 张同名自动合成 → 战场生成部落棋子 → 横版自动战斗 → 胜负结算 + 重开。

## 运行

```bash
# 桌面 GUI(需要 DISPLAY=:0)
cd /home/ubuntu/deck-and-merge
DISPLAY=:0 nohup godot --path . >/tmp/godot_run.log 2>&1 < /dev/null &
sleep 6
DISPLAY=:0 wmctrl -r :ACTIVE: -b add,maximized_vert,maximized_horz   # 录屏前最大化窗口

# 重新导入资源(改过 assets 后必须)
godot --headless --path . --import
```

- ALSA / Mesa(llvmpipe)警告是软件渲染下的正常噪音,可忽略。
- 关闭进程用 `pkill -f "godot --path"`。

## GUI 测试要点

- 用真实点击走完 T1–T4(点卡→合成→开战→胜负→重开),而不是只跑 headless。
- 全屏截图取证:`DISPLAY=:0 import -window root out.png`(或 computer 工具截图)。
- **随机牌堆 + 7 格合成台容易软锁**:手动收集特定单位时,若 7 格被 4 种以上单卡占满且无三连,就无法再取卡。要定向验证某个单位时,优先先凑齐它的三连(或用临时调试键生成)。
- 需要定向生成某单位做视觉验证时,可临时在 `main.gd` 加 `_unhandled_key_input` 按键生成(`_spawn_ally("shaman")` 等),**验证完务必删除临时代码**。
- 初始牌堆只有 `STARTER_TYPES = [stone_axe, club, spear, sling, bone]`,对应 clubber/spearman/slinger/shaman;`shield`(兽皮 pelt)、`healer`(篝火/金块)常规玩法不可达,需调试生成。

## 美术资源不变量(测试必须守住)

1. **精灵必须透明 + 紧裁**:`assets/{units,enemies,cards}/*.png` 四角 `alpha` 必须为 0,尺寸应按内容裁剪(不是整格 341×512)。否则单位身后会出现"白色卡片状方块"。快速校验:

```bash
python3 -c "
import glob
from PIL import Image
for f in sorted(glob.glob('assets/units/*.png')):
    im=Image.open(f).convert('RGBA'); w,h=im.size
    a=[im.getpixel(p)[3] for p in [(0,0),(w-1,0),(0,h-1),(w-1,h-1)]]
    print(f, im.size, a, 'BAD' if any(x>0 for x in a) else 'ok')
"
```

2. **运行时背景必须为空**:`assets/bg_board.png`、`assets/bg_battle.png` 是手绘的空场景,**不得**由 `concept_screen.png`(含烘焙卡牌/单位/敌人)重新裁剪。`tools/slice_assets.py` 只切精灵、不生成背景。改切图后务必确认这两张背景没被覆盖成拼图。

## 切图脚本

`tools/slice_assets.py`:median 四角基准色 + flood-fill 去连通近白/近背景色 + bbox 紧裁 + 1px 透明边距。跑完记得 `--import` 重新导入。
