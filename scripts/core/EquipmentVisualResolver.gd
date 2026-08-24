class_name EquipmentVisualResolver
extends RefCounted

const RARITY_COLORS:Dictionary = {
	"common":Color("#89939f"),"uncommon":Color("#5f986e"),"rare":Color("#5c85bc"),
	"epic":Color("#8060a8"),"legendary":Color("#c0954c")
}
const BIOME_COLORS:Dictionary = {
	"Greenlands":Color("#76835c"),"Ancient Forest":Color("#4f775a"),"Iron Hills":Color("#87929e"),
	"Mistfen":Color("#557e7c"),"Ash Wastes":Color("#9c5c4b"),"Frostwild":Color("#799fba")
}

static func definition(item:Dictionary) -> Dictionary:
	var result:Dictionary = item.duplicate(true)
	var content_id:String = String(item.get("content_id",""))
	if content_id != "":
		var shipped:Dictionary = ContentDB.get_entry("items",content_id)
		for raw_key:Variant in shipped.keys():
			var key:String = String(raw_key)
			if not result.has(key) or result[key] == null or String(result[key]) == "": result[key] = shipped[raw_key]
	return result

static func profile(item:Dictionary) -> Dictionary:
	var d:Dictionary = definition(item)
	var slot:String = String(d.get("slot","weapon"))
	var weapon_class:String = String(d.get("weapon_class","sword")) if slot == "weapon" else ""
	var rarity:String = String(d.get("rarity",item.get("rarity","common")))
	var biome:String = String(d.get("origin_biome",item.get("origin_biome","")))
	if biome == "":
		var biomes:Array = Array(d.get("biomes",[]))
		if not biomes.is_empty(): biome = String(biomes[0])
	var primary:Color = Color(BIOME_COLORS.get(biome,RARITY_COLORS.get(rarity,Color("#89939f"))))
	var rarity_color:Color = Color(RARITY_COLORS.get(rarity,Color("#89939f")))
	var content_id:String = String(d.get("content_id",item.get("content_id",String(d.get("name","item")).to_snake_case())))
	return {
		"content_id":content_id,
		"slot":slot,"weapon_class":weapon_class,"rarity":rarity,"biome":biome,
		"primary":primary,"accent":primary.lightened(0.22).lerp(rarity_color,0.35),"dark":primary.darkened(0.27),
		"inventory_sprite":String(d.get("inventory_sprite","")),
		"equipped_sheet":String(d.get("equipped_sheet","")),
		"attack_sprite":String(d.get("attack_sprite","")),
		"seed":absi(hash(content_id)),
		"fallback_atlas":_fallback_atlas(slot,weapon_class)
	}

static func _fallback_atlas(slot:String,weapon_class:String) -> String:
	if slot == "weapon":
		return {
			"bow":"fx_arrow","crossbow":"fx_arrow","staff":"fx_arcane","wand":"fx_arcane",
			"hammer":"fx_explosion","spear":"fx_slash","axe":"fx_slash","dagger":"fx_slash"
		}.get(weapon_class,"fx_slash")
	return {
		"helm":"trait_ironhide","shoulders":"unit_shield","chest":"trait_blessed","gloves":"trait_vicious",
		"belt":"icon_inventory","legs":"trait_swift","boots":"trait_swift","cape":"trait_stormcaller"
	}.get(slot,"icon_inventory")

static func visual_link(item:Dictionary,context:String) -> String:
	var p:Dictionary = profile(item)
	match context:
		"inventory": return String(p.get("inventory_sprite",""))
		"equipped": return String(p.get("equipped_sheet",""))
		"attack": return String(p.get("attack_sprite",""))
	return ""

static func has_shipped_visual(item:Dictionary,context:String) -> bool:
	var link:String = visual_link(item,context)
	return link != "" and VisualAtlas.has(link)
