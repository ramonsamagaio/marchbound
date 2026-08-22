class_name LootFamilies
extends RefCounted

const SLOT_ORDER = ["weapon","helm","shoulders","chest","gloves","belt","legs","boots","cape"]

const FAMILIES = {
	"Greenlands": {
		"id":"dawnward",
		"name":"Dawnward",
		"lore":"Field gear of the first roads beyond Dawnkeep, built for commanders who refuse to let the march stall.",
		"two_piece":"2 pieces: +8% army damage.",
		"four_piece":"4 pieces: +10% army attack speed.",
		"names":{
			"weapon":"Dawnward Edge","helm":"Sunwatch Helm","shoulders":"Marchwarden Pauldrons","chest":"Dawnkeep Cuirass","gloves":"Oathgrip Gauntlets","belt":"Frontier Sash","legs":"Roadguard Greaves","boots":"Firstmarch Sabatons","cape":"Golden Horizon Mantle"
		}
	},
	"Ancient Forest": {
		"id":"briarbound",
		"name":"Briarbound",
		"lore":"Living wargear grown around old iron, favored by wardens who learn to take wealth from hostile ground without slowing down.",
		"two_piece":"2 pieces: +10% expedition harvest yield.",
		"four_piece":"4 pieces: +8% movement speed.",
		"names":{
			"weapon":"Thornwake Blade","helm":"Antlered Hood","shoulders":"Rootguard Pauldrons","chest":"Briarheart Cuirass","gloves":"Sapbound Grips","belt":"Vinekeeper Belt","legs":"Greenveil Greaves","boots":"Mossstep Boots","cape":"Canopy Mantle"
		}
	},
	"Iron Hills": {
		"id":"deepforge",
		"name":"Deepforge",
		"lore":"Dense hill-forged plate made to outlast cave-ins, sieges and anyone foolish enough to stand in front of it.",
		"two_piece":"2 pieces: +12% max Warden HP.",
		"four_piece":"4 pieces: 10% less incoming damage.",
		"names":{
			"weapon":"Deepforge Cleaver","helm":"Anvil Crown","shoulders":"Quarry Pauldrons","chest":"Blackiron Bastion","gloves":"Hammerfall Gauntlets","belt":"Furnace Girdle","legs":"Faultline Greaves","boots":"Stonewake Sabatons","cape":"Smelter's Mantle"
		}
	},
	"Mistfen": {
		"id":"mireglass",
		"name":"Mireglass",
		"lore":"Pale fen relics that drink warmth from wounded things and return a little of it to their bearer.",
		"two_piece":"2 pieces: +2% lifesteal.",
		"four_piece":"4 pieces: +3% additional lifesteal.",
		"names":{
			"weapon":"Mireglass Fang","helm":"Bogseer Mask","shoulders":"Drowned Pauldrons","chest":"Fenwraith Cuirass","gloves":"Leechsilk Gloves","belt":"Murkchain Belt","legs":"Siltwalker Greaves","boots":"Reedstep Boots","cape":"Pale Vapor Mantle"
		}
	},
	"Ash Wastes": {
		"id":"cinderborn",
		"name":"Cinderborn",
		"lore":"Heat-scarred equipment that rewards aggression, forged for marches where hesitation is just a slower death.",
		"two_piece":"2 pieces: +5% critical chance.",
		"four_piece":"4 pieces: +12% Warden damage.",
		"names":{
			"weapon":"Cinderborn Brand","helm":"Ashen Visor","shoulders":"Emberlord Pauldrons","chest":"Pyreplate Cuirass","gloves":"Coalgrip Gauntlets","belt":"Scorchchain Belt","legs":"Burnscar Greaves","boots":"Emberstep Sabatons","cape":"Smoke-Torn Mantle"
		}
	},
	"Frostwild": {
		"id":"rimebound",
		"name":"Rimebound",
		"lore":"Cold-forged frontier gear that turns movement into survival, built for hunters who never stay where the killing blow lands.",
		"two_piece":"2 pieces: -12% dash cooldown.",
		"four_piece":"4 pieces: +8% movement speed.",
		"names":{
			"weapon":"Rimebound Talon","helm":"Whiteglass Helm","shoulders":"Icefang Pauldrons","chest":"Winterhold Cuirass","gloves":"Frostbite Grips","belt":"Coldchain Belt","legs":"Snowguard Greaves","boots":"Glacierstep Boots","cape":"Howling Mantle"
		}
	}
}

static func family_for_biome(biome:String) -> Dictionary:
	return FAMILIES.get(biome,FAMILIES["Greenlands"])

static func family_by_id(id:String) -> Dictionary:
	for biome in FAMILIES:
		var family:Dictionary = FAMILIES[biome]
		if String(family.get("id","")) == id:
			return family
	return {}

static func decorate_item(item:Dictionary,biome:String) -> Dictionary:
	var family = family_for_biome(biome)
	var slot = String(item.get("slot",""))
	item["family"] = String(family.get("id",""))
	item["family_name"] = String(family.get("name",""))
	item["family_lore"] = String(family.get("lore",""))
	item["name"] = String(family.get("names",{}).get(slot,item.get("name","Frontier Relic")))
	return item

static func equipped_counts() -> Dictionary:
	var counts := {}
	for slot in GameState.equipped:
		var item = GameState.get_item(String(GameState.equipped.get(slot,"")))
		if item.is_empty():
			continue
		var family = String(item.get("family",""))
		if family != "":
			counts[family] = int(counts.get(family,0))+1
	return counts

static func equipped_count(family_id:String) -> int:
	return int(equipped_counts().get(family_id,0))

static func active_set_summary() -> Array:
	var result := []
	var counts = equipped_counts()
	for family_id in counts:
		var count = int(counts[family_id])
		if count < 2:
			continue
		var family = family_by_id(String(family_id))
		result.append("%s %dpc"%[family.get("name",family_id),count])
	return result
