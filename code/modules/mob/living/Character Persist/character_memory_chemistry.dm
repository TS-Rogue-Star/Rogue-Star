//////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2026: Chemistry Memories //
//////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star November 2026: Food Memories ///////
//////////////////////////////////////////////////////////////////////

/datum/character_memory
	var/list/chemicals = list()
	var/tmp/list/pending_chemical_batches = list()
	var/selected_chemical

/proc/character_memory_chemical_result(var/decl/chemical_reaction/recipe)
	if(!recipe?.result || recipe.result_amount <= 0 || !length(recipe.required_reagents))
		return null
	if(!istype(recipe, /decl/chemical_reaction/instant) && !istype(recipe, /decl/chemical_reaction/distilling))
		return null
	var/datum/reagent/chemical = SSchemistry.chemical_reagents[recipe.result]
	if(!chemical || length(character_memory_drink_recipes(chemical.id)) || (istype(chemical, /datum/reagent/nutriment) && !istype(chemical, /datum/reagent/nutriment/glucose)) || istype(recipe, /decl/chemical_reaction/instant/food))
		return null
	return chemical

/proc/character_memory_chemical_recipes(var/chemical_id)
	var/static/list/recipes_by_chemical
	if(!recipes_by_chemical)
		recipes_by_chemical = list()
		for(var/decl/chemical_reaction/recipe as anything in SSchemistry.chemical_reactions)
			var/datum/reagent/chemical = character_memory_chemical_result(recipe)
			if(chemical)
				LAZYADD(recipes_by_chemical[chemical.id], recipe)
	return recipes_by_chemical[chemical_id]

/datum/reagents/proc/record_mixed_chemicals(var/mob/mixer, var/list/reactions, var/list/recorded)
	if(!isliving(mixer) || !isobj(my_atom) || QDELETED(mixer))
		return
	var/mob/living/maker = mixer
	if(!maker.character_memory)
		return
	if(!islist(recorded))
		recorded = list()
	for(var/decl/chemical_reaction/recipe as anything in reactions)
		var/datum/reagent/chemical = character_memory_chemical_result(recipe)
		if(!chemical || (chemical.id in recorded))
			continue
		if(maker.character_memory.record_chemical(chemical.id))
			recorded += chemical.id

/datum/character_memory/proc/init_chemicals_schema()
	return execute_database_update("CREATE TABLE IF NOT EXISTS chemicals (chemical_id TEXT NOT NULL PRIMARY KEY, times_made INTEGER NOT NULL DEFAULT 0, first_made TEXT, last_made TEXT)", "create character memory chemicals table")

/datum/character_memory/proc/record_chemical(var/chemical_id)
	if(!can_track(ourmob) || shutting_down || !length(character_memory_chemical_recipes(chemical_id)))
		return FALSE
	if(!bind_pending_recipes())
		return FALSE
	return record_recipe_batches(chemical_id, chemicals, pending_chemical_batches)

/datum/character_memory/proc/known_reagent_recipes(var/reagent_id)
	if(islist(drinks[reagent_id]))
		return character_memory_drink_recipes(reagent_id)
	if(islist(chemicals[reagent_id]))
		return character_memory_chemical_recipes(reagent_id)
	if(islist(foods["reagent:[reagent_id]"]))
		return character_memory_food_recipes("reagent:[reagent_id]")
	return null

/datum/character_memory/proc/build_chemical_detail(var/chemical_id)
	var/list/entry = chemicals[chemical_id]
	if(!islist(entry))
		return null
	var/datum/reagent/chemical = SSchemistry.chemical_reagents[chemical_id]
	var/static/list/images = list()
	if(!images[chemical_id])
		var/icon/beaker = icon('icons/obj/chemical.dmi', "beaker", SOUTH, 1)
		var/icon/filling = icon('icons/obj/reagentfillings.dmi', "beaker-60", SOUTH, 1)
		filling.Blend(chemical?.color || "#808080", ICON_MULTIPLY)
		beaker.Blend(filling, ICON_OVERLAY)
		images[chemical_id] = icon2base64(beaker)
	var/list/recipes = list()
	for(var/decl/chemical_reaction/recipe as anything in character_memory_chemical_recipes(chemical_id))
		recipes += list(build_drink_recipe(recipe))
	return list(
		"id" = chemical_id,
		"name" = chemical?.name || chemical_id,
		"description" = chemical?.description || "This chemical is no longer in the recipe book.",
		"image" = images[chemical_id],
		"medical" = build_chemical_properties(chemical),
		"times_made" = entry["times_made"],
		"first_made" = entry["first_made"],
		"last_made" = entry["last_made"],
		"recipes" = recipes
	)

/datum/character_memory/proc/build_chemical_properties(var/datum/reagent/chemical)
	if(!chemical)
		return null
	var/datum/reagents/metabolism/ingested/ingested_holder = /datum/reagents/metabolism/ingested
	var/cycles_per_minute = (1 MINUTE) / SSmobs.wait
	return list(
		"effects" = chemical.memory_effects || chemical.description,
		"application" = chemical.memory_application,
		"limitations" = chemical.memory_limitations,
		"overdose" = chemical.overdose,
		"overdose_effects" = chemical.memory_overdose,
		"overdose_touch" = chemical.can_overdose_touch,
		"interactions" = chemical.memory_interactions || list(),
		"metabolism_per_minute" = chemical.metabolism * cycles_per_minute,
		"ingest_metabolism_per_minute" = (chemical.ingest_met || chemical.metabolism) * (chemical.mrate_static ? 1 : initial(ingested_holder.metabolism_speed)) * cycles_per_minute,
		"touch_metabolism_per_minute" = (chemical.touch_met || chemical.metabolism) * cycles_per_minute,
		"metabolism_static" = chemical.mrate_static,
		"scannable" = chemical.scannable
	)

/datum/character_memory/proc/build_chemical_search_text(var/datum/reagent/chemical)
	if(!chemical)
		return ""
	return lowertext(jointext(list(chemical.memory_search_terms, chemical.memory_effects || chemical.description, chemical.memory_application, chemical.memory_limitations, jointext(chemical.memory_interactions || list(), " ")), " "))

/datum/character_memory/proc/add_chemicals_ui_data(var/list/data)
	var/list/rows = list()
	var/total_made = 0
	for(var/chemical_id in chemicals)
		var/list/entry = chemicals[chemical_id]
		var/datum/reagent/chemical = SSchemistry.chemical_reagents[chemical_id]
		rows += list(list(
			"id" = chemical_id,
			"name" = chemical?.name || chemical_id,
			"times_made" = entry["times_made"],
			"ingredient_names" = build_drink_search_ingredients(chemical_id),
			"search_text" = build_chemical_search_text(chemical)
		))
		total_made += entry["times_made"]
	rows = sortTim(rows, GLOBAL_PROC_REF(cmp_character_memory_contact_row_name), FALSE)
	if(!(selected_chemical in chemicals))
		selected_chemical = length(rows) ? rows[1]["id"] : null
	data["chemicals"] = rows
	data["chemistry_xp"] = recipe_discoveries["chemistry"] || 0
	data["chemicals_made"] = total_made
	data["selected_chemical"] = selected_chemical
	data["chemical_detail"] = flatten_reagent_recipe_detail(build_chemical_detail(selected_chemical))
