class_name VisualAtlas
extends RefCounted

const ATLAS := preload("res://assets/marchbound_assetsprov.png")

# Provisional atlas regions from the approved Marchbound style-test sheet.
# Keep all lookups here so replacing the sheet later does not require touching gameplay code.
const REGIONS := {
	# resources / UI
	"res_gold": Rect2(0, 0, 88, 82),
	"res_wood": Rect2(88, 0, 72, 82),
	"res_stone": Rect2(158, 0, 70, 82),
	"res_iron": Rect2(226, 0, 72, 82),
	"res_food": Rect2(296, 0, 76, 82),
	"res_mana": Rect2(368, 0, 72, 82),
	"icon_build": Rect2(438, 0, 64, 78),
	"icon_research": Rect2(680, 0, 68, 78),
	"icon_world": Rect2(566, 0, 70, 78),
	"icon_legion": Rect2(864, 0, 72, 78),
	"icon_inventory": Rect2(1050, 0, 72, 78),
	"icon_close": Rect2(628, 82, 62, 62),
	"icon_settings": Rect2(348, 82, 62, 62),
	"icon_plus": Rect2(465, 82, 62, 62),
	"icon_minus": Rect2(522, 82, 62, 62),
	"icon_check": Rect2(575, 82, 62, 62),
	"icon_warning": Rect2(690, 82, 68, 64),
	"icon_boss": Rect2(754, 82, 62, 62),
	"icon_elite": Rect2(812, 82, 64, 62),
	"icon_elite_shiny": Rect2(870, 82, 64, 62),
	"icon_wild_bond": Rect2(930, 82, 62, 62),
	"icon_mutation": Rect2(96, 146, 66, 62),
	"trait_swift": Rect2(150, 146, 68, 62),
	"trait_ironhide": Rect2(286, 146, 68, 62),
	"trait_blessed": Rect2(350, 146, 68, 62),
	"trait_ancient": Rect2(414, 146, 68, 62),
	"trait_vicious": Rect2(480, 146, 68, 62),
	"trait_stormcaller": Rect2(548, 146, 68, 62),

	# units / portraits
	"warden_portrait": Rect2(0, 286, 126, 150),
	"unit_knight": Rect2(122, 282, 108, 128),
	"unit_shield": Rect2(225, 282, 84, 128),
	"unit_lancer": Rect2(302, 282, 96, 128),
	"unit_infantry": Rect2(392, 282, 92, 128),
	"unit_ranger": Rect2(482, 282, 96, 128),
	"unit_rogue": Rect2(570, 282, 84, 128),
	"unit_mage": Rect2(646, 282, 96, 128),
	"unit_cleric": Rect2(738, 282, 82, 128),
	"unit_paladin": Rect2(814, 282, 96, 128),
	"unit_engineer": Rect2(904, 282, 90, 128),
	"unit_scout": Rect2(990, 282, 92, 128),
	"enemy_goblin": Rect2(0, 548, 102, 132),
	"enemy_goblin_archer": Rect2(96, 548, 84, 132),
	"enemy_cultist": Rect2(174, 548, 84, 132),
	"enemy_dark_knight": Rect2(250, 548, 106, 132),
	"enemy_assassin": Rect2(350, 548, 98, 132),
	"enemy_skeleton": Rect2(446, 548, 98, 132),
	"enemy_skeleton_archer": Rect2(540, 548, 96, 132),
	"enemy_wraith": Rect2(622, 538, 122, 142),
	"enemy_demon": Rect2(742, 510, 170, 174),
	"enemy_boss": Rect2(908, 472, 214, 220),

	# wild bonds
	"wild_thornkin": Rect2(0, 688, 112, 128),
	"wild_stag": Rect2(104, 688, 108, 128),
	"wild_golem": Rect2(204, 688, 128, 128),
	"wild_marsh": Rect2(324, 688, 166, 128),
	"wild_imp": Rect2(492, 688, 112, 128),
	"wild_wisp": Rect2(592, 688, 112, 128),
	"wild_ridgeback": Rect2(688, 688, 112, 128),
	"wild_beetle": Rect2(792, 688, 120, 128),
	"wild_leech": Rect2(900, 688, 110, 128),
	"wild_wyvern": Rect2(1002, 688, 120, 128),

	# buildings / props
	"building_town_hall": Rect2(0, 804, 174, 164),
	"building_barracks": Rect2(162, 804, 142, 164),
	"building_forge": Rect2(292, 804, 136, 164),
	"building_farm": Rect2(416, 804, 142, 164),
	"building_lumber": Rect2(548, 804, 140, 164),
	"building_quarry": Rect2(676, 804, 128, 164),
	"building_research": Rect2(792, 804, 122, 164),
	"building_market": Rect2(900, 804, 112, 164),
	"building_storage": Rect2(1004, 804, 118, 164),
	"building_watchtower": Rect2(0, 950, 176, 118),
	"building_house": Rect2(188, 950, 128, 118),
	"building_chapel": Rect2(316, 950, 150, 118),
	"building_stable": Rect2(462, 950, 150, 118),
	"building_wall_gate": Rect2(620, 950, 344, 118),
	"tile_road": Rect2(986, 950, 136, 118),

	# battle fx / pickups
	"fx_slash": Rect2(0, 1058, 124, 112),
	"fx_arrow": Rect2(118, 1058, 96, 112),
	"fx_fireball": Rect2(202, 1058, 104, 112),
	"fx_arcane": Rect2(292, 1058, 110, 112),
	"fx_heal": Rect2(394, 1058, 116, 112),
	"fx_holy": Rect2(500, 1058, 110, 112),
	"fx_explosion": Rect2(602, 1058, 118, 112),
	"fx_void": Rect2(716, 1058, 144, 112),
	"pickup_gold": Rect2(862, 1058, 70, 112),
	"pickup_mana": Rect2(924, 1058, 72, 112),
	"pickup_health": Rect2(994, 1058, 78, 112),

	# world-map tiles / markers
	"world_grass": Rect2(0, 1162, 112, 118),
	"world_forest": Rect2(104, 1162, 112, 118),
	"world_ancient": Rect2(208, 1162, 112, 118),
	"world_swamp": Rect2(312, 1162, 112, 118),
	"world_frost": Rect2(416, 1162, 112, 118),
	"world_mountain": Rect2(520, 1162, 112, 118),
	"world_ash": Rect2(624, 1162, 112, 118),
	"world_corruption": Rect2(728, 1162, 112, 118),
	"world_coast": Rect2(832, 1162, 112, 118),
	"world_water": Rect2(936, 1162, 112, 118),
	"world_unknown": Rect2(0, 1270, 112, 132),
	"world_vault": Rect2(104, 1270, 112, 132),
	"world_boss": Rect2(208, 1270, 112, 132),
	"world_wild": Rect2(312, 1270, 112, 132),
	"world_pvp": Rect2(416, 1270, 112, 132),
	"world_route": Rect2(520, 1270, 112, 132),
	"world_claimed": Rect2(624, 1270, 112, 132),
	"world_city": Rect2(728, 1270, 112, 132),
	"world_corrupt_site": Rect2(832, 1270, 112, 132),
	"world_frost_city": Rect2(936, 1270, 112, 132)
}

static func region(id:String) -> Rect2:
	return REGIONS.get(id, Rect2())

static func texture(id:String) -> AtlasTexture:
	var out := AtlasTexture.new()
	out.atlas = ATLAS
	out.region = region(id)
	return out

static func has(id:String) -> bool:
	return REGIONS.has(id)

static func unit_sprite_id(unit:String) -> String:
	return {
		"militia":"unit_shield",
		"archer":"unit_ranger",
		"wolf":"wild_ridgeback",
		"mage":"unit_mage",
		"ridgeback":"wild_ridgeback",
		"thornkin":"wild_thornkin",
		"stone_golem":"wild_golem",
		"mire_leech":"wild_leech",
		"ember_imp":"wild_imp",
		"frost_wisp":"wild_wisp"
	}.get(unit,"unit_knight")

static func enemy_sprite_id(type:String) -> String:
	return {
		"raider":"enemy_goblin",
		"slime":"wild_marsh",
		"wolf":"wild_ridgeback",
		"wisp":"wild_wisp",
		"bramble":"wild_thornkin",
		"golem":"wild_golem",
		"leech":"wild_leech",
		"imp":"wild_imp",
		"frostling":"wild_ridgeback",
		"boss":"enemy_boss"
	}.get(type,"enemy_goblin")

static func biome_tile_id(biome:String) -> String:
	return {
		"Greenlands":"world_grass",
		"Ancient Forest":"world_forest",
		"Iron Hills":"world_mountain",
		"Mistfen":"world_swamp",
		"Ash Wastes":"world_ash",
		"Frostwild":"world_frost"
	}.get(biome,"world_grass")
