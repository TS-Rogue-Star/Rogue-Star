//////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2026: Drink Memories //
//////////////////////////////////////////////////////////////////

/datum/character_memory
	var/list/drinks = list()
	var/selected_drink

/proc/character_memory_drink_result(var/decl/chemical_reaction/recipe)
	if(!recipe?.result || recipe.result_amount <= 0 || !length(recipe.required_reagents))
		return null
	var/datum/reagent/drink = SSchemistry.chemical_reagents[recipe.result]
	if(istype(recipe, /decl/chemical_reaction/instant/drinks) || istype(drink, /datum/reagent/drink) || istype(drink, /datum/reagent/ethanol))
		return drink
	return null

/proc/character_memory_drink_recipes(var/drink_id)
	var/static/list/recipes_by_drink
	if(!recipes_by_drink)
		recipes_by_drink = list()
		for(var/decl/chemical_reaction/recipe as anything in SSchemistry.chemical_reactions)
			var/datum/reagent/drink = character_memory_drink_result(recipe)
			if(!drink)
				continue
			LAZYADD(recipes_by_drink[drink.id], recipe)
	return recipes_by_drink[drink_id]

/datum/reagents/proc/record_mixed_drinks(var/mob/mixer, var/list/reactions, var/list/recorded)
	if(!isliving(mixer) || !isobj(my_atom) || QDELETED(mixer))
		return
	var/mob/living/maker = mixer
	if(!maker.character_memory)
		return
	if(!islist(recorded))
		recorded = list()
	for(var/decl/chemical_reaction/recipe as anything in reactions)
		var/datum/reagent/drink = character_memory_drink_result(recipe)
		if(!drink || (drink.id in recorded))
			continue
		if(maker.character_memory.record_drink(drink.id))
			recorded += drink.id

/datum/character_memory/proc/init_drinks_schema()
	return execute_database_update("CREATE TABLE IF NOT EXISTS drinks (drink_id TEXT NOT NULL PRIMARY KEY, times_made INTEGER NOT NULL DEFAULT 0, first_made TEXT, last_made TEXT)", "create character memory drinks table")

/datum/character_memory/proc/load_database_drinks()
	var/list/rows = execute_database_query("SELECT drink_id, times_made, first_made, last_made FROM drinks", "load character memory drinks")
	if(!islist(rows))
		return FALSE
	drinks = list()
	for(var/list/row as anything in rows)
		var/drink_id = row["drink_id"]
		var/times_made = text2num("[row["times_made"]]")
		if(!istext(drink_id) || !length(drink_id) || !isnum(times_made) || times_made < 1)
			continue
		drinks[drink_id] = list("times_made" = round(times_made), "first_made" = row["first_made"], "last_made" = row["last_made"])
	sync_bartending_xp()
	return TRUE

/datum/character_memory/proc/save_database_drink(var/drink_id)
	var/list/entry = drinks[drink_id]
	if(!islist(entry))
		return FALSE
	return execute_database_update(list("INSERT OR REPLACE INTO drinks (drink_id, times_made, first_made, last_made) VALUES (?, ?, ?, ?)", drink_id, entry["times_made"], entry["first_made"], entry["last_made"]), "save character memory drink")

/datum/character_memory/proc/save_database_drinks()
	for(var/drink_id in drinks)
		if(!save_database_drink(drink_id))
			return FALSE
	return TRUE

/datum/character_memory/proc/sync_bartending_xp()
	var/datum/etching/etching = ourmob?.etching
	if(!etching)
		return
	if(!islist(etching.xp))
		etching.xp = list()
	if(etching.xp["bartending"] != length(drinks))
		etching.xp["bartending"] = length(drinks)
		etching.needs_saving = TRUE

/datum/character_memory/proc/record_drink(var/drink_id)
	if(!can_track(ourmob) || shutting_down || !length(character_memory_drink_recipes(drink_id)))
		return FALSE
	if(!save_path)
		load()
	if(!savable || !save_path)
		return FALSE
	var/list/entry = drinks[drink_id]
	var/first_time = !islist(entry)
	var/today = get_date_key()
	if(first_time)
		entry = list("times_made" = 0, "first_made" = today)
		drinks[drink_id] = entry
	entry["times_made"]++
	entry["last_made"] = today
	if(!ensure_database() || !save_database_drink(drink_id))
		needs_saving = TRUE
	sync_bartending_xp()
	if(first_time)
		var/datum/reagent/drink = SSchemistry.chemical_reagents[drink_id]
		to_chat(ourmob, SPAN_NOTICE("You learned to make [drink.name]! +1 bartending XP ([length(drinks)] total). Find the recipe in Memory's Drinks tab."))
	SStgui.update_uis(src)
	return TRUE

/datum/character_memory/proc/build_drink_ingredients(var/list/reagents, var/multiplier = 1)
	var/list/rows = list()
	for(var/reagent_id in reagents)
		var/datum/reagent/ingredient = SSchemistry.chemical_reagents[reagent_id]
		rows += list(list("id" = reagent_id, "name" = ingredient?.name || reagent_id, "amount" = reagents[reagent_id] * multiplier))
	return rows

/datum/character_memory/proc/build_drink_recipe(var/decl/chemical_reaction/recipe, var/multiplier = 1, var/list/path)
	multiplier = max(1, multiplier)
	var/batch_multiplier = multiplier
	var/batches = 1
	if(recipe.drink_max_batch_multiplier > 0)
		batch_multiplier = min(multiplier, recipe.drink_max_batch_multiplier)
		batches = CEILING(multiplier / batch_multiplier, 1)
		multiplier = batch_multiplier * batches
	var/list/batch_reagents = list()
	var/input_volume = 0
	for(var/reagent_id in recipe.required_reagents)
		input_volume += recipe.required_reagents[reagent_id] * multiplier
		batch_reagents[reagent_id] = recipe.required_reagents[reagent_id] * batch_multiplier
	var/list/leftovers = list()
	var/leftover_volume = 0
	var/list/catalysts = build_drink_ingredients(recipe.catalysts)
	for(var/list/catalyst as anything in catalysts)
		var/reagent_id = catalyst["id"]
		var/consumed = recipe.required_reagents[reagent_id] * multiplier
		catalyst["consumed"] = consumed
		catalyst["total"] = max(consumed, catalyst["amount"])
		batch_reagents[reagent_id] = max(batch_reagents[reagent_id], catalyst["amount"])
		var/remaining = max(0, catalyst["amount"] - consumed)
		if(remaining)
			leftovers[reagent_id] = remaining
			leftover_volume += remaining
	var/list/pour_reagents = list()
	for(var/reagent_id in recipe.drink_pour_order)
		if(reagent_id in batch_reagents)
			pour_reagents[reagent_id] = batch_reagents[reagent_id]
	var/list/ingredients = list()
	for(var/reagent_id in recipe.drink_pour_order)
		if(reagent_id in recipe.required_reagents)
			ingredients[reagent_id] = recipe.required_reagents[reagent_id]
	for(var/reagent_id in recipe.required_reagents)
		ingredients[reagent_id] = recipe.required_reagents[reagent_id]
	var/list/data = list(
		"ingredients" = build_drink_ingredients(ingredients, multiplier),
		"catalysts" = catalysts,
		"inhibitors" = build_drink_ingredients(recipe.inhibitors),
		"yield" = recipe.result_amount * multiplier,
		"minimum_yield" = recipe.result_amount,
		"input_volume" = input_volume + leftover_volume,
		"mixture_volume" = recipe.result_amount * multiplier + leftover_volume,
		"leftovers" = build_drink_ingredients(leftovers),
		"pour_order" = build_drink_ingredients(pour_reagents),
		"notes" = recipe.drink_preparation_notes || list(),
		"batches" = batches,
		"batch_yield" = recipe.result_amount * batch_multiplier,
		"batch_limit" = recipe.result_amount * recipe.drink_max_batch_multiplier,
		"method" = "Mixing",
		"equipment" = "Clean reagent container"
	)
	if(istype(recipe, /decl/chemical_reaction/distilling))
		var/decl/chemical_reaction/distilling/distillation = recipe
		data["method"] = "Distilling"
		data["equipment"] = "Chemical distillery"
		data["temperature"] = "[round(distillation.temp_range[1] - T0C, 0.01)] - [round(distillation.temp_range[2] - T0C, 0.01)] °C ([distillation.temp_range[1]] - [distillation.temp_range[2]] K)"
	else if(istype(recipe, /decl/chemical_reaction/instant/slime))
		var/decl/chemical_reaction/instant/slime/extraction = recipe
		var/obj/item/slime_extract/extract_type = extraction.required
		data["method"] = "Slime extraction"
		data["slime_extract"] = initial(extract_type.name)
		data["equipment"] = "[initial(extract_type.name)] with at least one use remaining"
		data["notes"] = list("Add the ingredients to the slime extract. Each reaction uses one charge of the extract.")
	var/list/next_path = islist(path) ? path.Copy() : list()
	next_path += recipe.result
	data["ingredient_recipes"] = build_drink_ingredient_recipes(data["ingredients"], catalysts, next_path)
	return data

/datum/character_memory/proc/build_drink_ingredient_recipes(var/list/ingredients, var/list/catalysts, var/list/path)
	var/list/recipes = list()
	if(length(path) >= 32)
		return recipes
	var/list/amounts = list()
	for(var/list/ingredient as anything in ingredients)
		amounts[ingredient["id"]] = ingredient["amount"]
	for(var/list/catalyst as anything in catalysts)
		var/reagent_id = catalyst["id"]
		amounts[reagent_id] = max(amounts[reagent_id], catalyst["total"])
	for(var/reagent_id in amounts)
		if(!islist(drinks[reagent_id]) || (reagent_id in path))
			continue
		for(var/decl/chemical_reaction/recipe as anything in character_memory_drink_recipes(reagent_id))
			var/multiplier = max(1, CEILING(amounts[reagent_id] / recipe.result_amount, 1))
			var/list/recipe_data = build_drink_recipe(recipe, multiplier, path)
			LAZYADD(recipes[reagent_id], list(recipe_data))
	return recipes

/datum/character_memory/proc/build_drink_detail(var/drink_id)
	var/list/entry = drinks[drink_id]
	if(!islist(entry))
		return null
	var/datum/reagent/drink = SSchemistry.chemical_reagents[drink_id]
	var/static/list/images = list()
	if(!images[drink_id])
		var/glass_file = drink?.glass_icon_file || 'icons/obj/drinks.dmi'
		var/glass_state = drink?.glass_icon_state || "glass_brown"
		if(!(glass_state in cached_icon_states(glass_file)))
			glass_file = 'icons/obj/drinks.dmi'
			glass_state = "glass_brown"
		images[drink_id] = icon2base64(icon(glass_file, glass_state, SOUTH, 1))
	var/list/recipes = list()
	for(var/decl/chemical_reaction/recipe as anything in character_memory_drink_recipes(drink_id))
		var/list/recipe_data = build_drink_recipe(recipe)
		recipes += list(recipe_data)
	return list(
		"id" = drink_id,
		"name" = drink?.name || drink_id,
		"description" = drink?.glass_desc || drink?.description || "This drink is no longer in the recipe book.",
		"image" = images[drink_id],
		"traits" = build_drink_traits(drink),
		"times_made" = entry["times_made"],
		"first_made" = entry["first_made"],
		"last_made" = entry["last_made"],
		"recipes" = recipes
	)

/datum/character_memory/proc/build_drink_search_ingredients(var/drink_id)
	var/list/names = list()
	if(!islist(drinks[drink_id]))
		return names
	var/list/pending = list(drink_id)
	for(var/index = 1, index <= length(pending), index++)
		for(var/decl/chemical_reaction/recipe as anything in character_memory_drink_recipes(pending[index]))
			var/list/ingredients = recipe.required_reagents.Copy()
			ingredients |= recipe.catalysts
			for(var/reagent_id in ingredients)
				var/datum/reagent/ingredient = SSchemistry.chemical_reagents[reagent_id]
				names |= ingredient?.name || reagent_id
				if(islist(drinks[reagent_id]))
					pending |= reagent_id
	return names

/datum/character_memory/proc/add_drinks_ui_data(var/list/data)
	var/list/rows = list()
	var/total_made = 0
	for(var/drink_id in drinks)
		var/list/entry = drinks[drink_id]
		var/datum/reagent/drink = SSchemistry.chemical_reagents[drink_id]
		rows += list(list(
			"id" = drink_id,
			"name" = drink?.name || drink_id,
			"times_made" = entry["times_made"],
			"ingredient_names" = build_drink_search_ingredients(drink_id)
		))
		total_made += entry["times_made"]
	rows = sortTim(rows, GLOBAL_PROC_REF(cmp_character_memory_contact_row_name), FALSE)
	if(!(selected_drink in drinks))
		selected_drink = length(rows) ? rows[1]["id"] : null
	data["drinks"] = rows
	data["bartending_xp"] = length(drinks)
	data["drinks_made"] = total_made
	data["selected_drink"] = selected_drink
	data["drink_detail"] = build_drink_detail(selected_drink)
