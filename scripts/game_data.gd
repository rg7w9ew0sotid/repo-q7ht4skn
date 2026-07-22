class_name GameData
extends RefCounted

const CARDS := {
	"stone_axe": {"name": "石斧", "unit": "clubber", "color": Color("#c86f3e")},
	"club": {"name": "木棒", "unit": "clubber", "color": Color("#b87845")},
	"spear": {"name": "长矛", "unit": "spearman", "color": Color("#d1964a")},
	"sling": {"name": "投石", "unit": "slinger", "color": Color("#6c9c88")},
	"bone": {"name": "兽骨", "unit": "shaman", "color": Color("#c9b98a")},
	"campfire": {"name": "篝火", "unit": "healer", "color": Color("#db8140")},
	"gold": {"name": "金块", "unit": "healer", "color": Color("#edba42")},
	"pelt": {"name": "兽皮", "unit": "shield", "color": Color("#9b664a")},
}

const STARTER_TYPES := ["stone_axe", "club", "spear", "sling", "bone"]

const ALLIES := {
	"clubber": {"name": "棒兵", "hp": 125.0, "attack": 20.0, "attack_speed": 1.05, "range": 48.0, "move_speed": 46.0, "role": "melee"},
	"shield": {"name": "盾兵", "hp": 220.0, "attack": 12.0, "attack_speed": 0.82, "range": 46.0, "move_speed": 30.0, "role": "melee"},
	"spearman": {"name": "矛兵", "hp": 105.0, "attack": 24.0, "attack_speed": 0.95, "range": 165.0, "move_speed": 39.0, "role": "ranged"},
	"slinger": {"name": "投石手", "hp": 92.0, "attack": 28.0, "attack_speed": 0.76, "range": 210.0, "move_speed": 34.0, "role": "ranged"},
	"shaman": {"name": "骨法师", "hp": 88.0, "attack": 35.0, "attack_speed": 0.68, "range": 185.0, "move_speed": 29.0, "role": "ranged"},
	"healer": {"name": "草药萨满", "hp": 105.0, "attack": 9.0, "attack_speed": 0.85, "range": 160.0, "move_speed": 31.0, "role": "healer"},
}

const ENEMIES := {
	"sabertooth": {"name": "剑齿虎", "hp": 150.0, "attack": 24.0, "attack_speed": 1.0, "range": 48.0, "move_speed": 42.0, "role": "melee"},
	"mammoth": {"name": "猛犸", "hp": 285.0, "attack": 18.0, "attack_speed": 0.72, "range": 52.0, "move_speed": 23.0, "role": "melee"},
	"bear": {"name": "洞熊", "hp": 205.0, "attack": 27.0, "attack_speed": 0.8, "range": 48.0, "move_speed": 28.0, "role": "melee"},
	"raptor": {"name": "迅猛龙", "hp": 105.0, "attack": 19.0, "attack_speed": 1.25, "range": 45.0, "move_speed": 58.0, "role": "melee"},
	"boar": {"name": "野猪", "hp": 130.0, "attack": 16.0, "attack_speed": 1.15, "range": 46.0, "move_speed": 48.0, "role": "melee"},
	"enemy_caveman": {"name": "敌方原始人", "hp": 140.0, "attack": 21.0, "attack_speed": 0.9, "range": 150.0, "move_speed": 34.0, "role": "ranged"},
}
