///////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2026: Pet Register Interface //
///////////////////////////////////////////////////////////////////////////

/proc/pet_register_portrait(list/record)
	if(!islist(record))
		return null
	var/mob_type = pet_register_type(record["type"])
	if(!mob_type)
		return null
	var/static/list/cache = list()
	var/static/list/appearance_fields = list("type", "color", "crystal", "body_color", "under_color", "antennae_color", "antennae_end_color", "team_color", "eye_color", "marking_color", "horn_color", "skin_color", "item_type", "item_color", "marking_type", "horn_type")
	var/list/appearance_values = list()
	for(var/field in appearance_fields)
		appearance_values[field] = record[field]
	var/signature = md5(json_encode(appearance_values))
	if(signature in cache)
		return cache[signature]
	var/icon_file = initial(mob_type:icon)
	var/state = initial(mob_type:icon_living)
	var/base_color = initial(mob_type:color)
	var/list/layers = list()
	if(ispath(mob_type, /mob/living/simple_mob/vore/alienanimals/teppi))
		state = "body_base"
		base_color = record["body_color"]
		layers += list(list("marking_base[record["marking_type"]]", record["marking_color"]))
		if(record["item_type"])
			layers += list(list("[record["item_type"]]_base", record["item_color"]))
		layers += list(list("horn_base[record["horn_type"]]", record["horn_color"]), list("eye_base", record["eye_color"]), list("skin_base", record["skin_color"]))
	else if(ispath(mob_type, /mob/living/simple_mob/vore/isopod))
		var/small = initial(mob_type:isopod_small)
		icon_file = small ? 'icons/rogue-star/mobx32.dmi' : 'icons/rogue-star/mob_64x32.dmi'
		state = record["body_color"] ? "w-isopod" : "isopod"
		base_color = record["body_color"]
		if(!small)
			var/list/parts = list("w-isopod-under" = "under_color", "antennae" = "antennae_color", "antennae-end" = "antennae_end_color", "w-isopod-eyes" = "eye_color")
			for(var/part in parts)
				if(record[parts[part]])
					layers += list(list(part, record[parts[part]]))
			layers += list(list("w-isopod-eyeshine", "#ffffff"))
	else if(ispath(mob_type, /mob/living/simple_mob/vore/ant))
		base_color = record["team_color"]
		layers += list(list("ant_eyes", record["eye_color"]))
		var/queen = initial(mob_type:queen)
		if(queen)
			var/list/crowns = list("queen_crown", "double_queen_crown", "triple_queen_crown", "quadruple_queen_crown")
			layers += list(list(crowns[clamp(queen, 1, 4)], null))
	else if(ispath(mob_type, /mob/living/simple_mob/vore/prancer))
		base_color = record["color"]
		layers += list(list("moon_deer_crystal", record["crystal"]), list("moon_deer_shine", null))
	else if(ispath(mob_type, /mob/living/simple_mob/vore/dust_stalker))
		base_color = record["color"]
		layers += list(list("moon_ray_marking", record["marking_color"]), list("moon_ray_eyes", record["eye_color"]))
	else if(ispath(mob_type, /mob/living/simple_mob/vore/stellagan))
		base_color = record["color"]
	if(!icon_file)
		return null
	var/list/states = icon_states(icon_file)
	if(!(state in states))
		state = initial(mob_type:icon_state)
	if(!(state in states))
		return null
	var/icon/portrait = pet_register_icon_layer(icon_file, state, base_color)
	for(var/list/layer in layers)
		if(layer[1] in states)
			portrait.Blend(pet_register_icon_layer(icon_file, layer[1], layer[2]), ICON_OVERLAY)
	var/encoded = icon2base64(portrait)
	if(cache.len >= 256)
		cache.Cut(1, 2)
	cache[signature] = encoded
	return encoded

/proc/pet_register_icon_layer(icon_file, state, tint)
	var/icon/layer = icon(icon_file, state, SOUTH, 1, FALSE)
	if(istext(tint) && length(tint))
		layer.Blend(tint, ICON_MULTIPLY)
	return layer
