/////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2026: Food Memories //
/////////////////////////////////////////////////////////////////

#define FOOD_MEMORY_EXCEPTIONAL_BISCUIT "variant:exceptional_plumphelmetbiscuit"
#define FOOD_MEMORY_EXCEPTIONAL_PIE "variant:exceptional_plump_pie"
#define FOOD_MEMORY_SPECIAL_WISH_SOUP "variant:special_wishsoup"

/datum/character_memory
	var/list/foods = list()
	var/tmp/list/food_search_cache = list()
	var/tmp/list/pending_food_batches = list()
	var/selected_food

/datum/recipe
	var/list/assembly_steps
	var/obj/hand_tool
	var/preparation_note
	var/memory_variant_id
	var/memory_variant_name
	var/memory_variant_desc

/datum/recipe/proc/food_variant_note()
	return null

/datum/recipe/plumphelmetbiscuit
	memory_variant_id = FOOD_MEMORY_EXCEPTIONAL_BISCUIT
	memory_variant_name = EXCEPTIONAL_PLUMP_BISCUIT_NAME
	memory_variant_desc = EXCEPTIONAL_PLUMP_BISCUIT_DESC

/datum/recipe/plumphelmetbiscuit/food_variant_note()
	return "Each biscuit has a [EXCEPTIONAL_PLUMP_BISCUIT_CHANCE]% chance to turn out exceptional."

/datum/recipe/plump_pie
	memory_variant_id = FOOD_MEMORY_EXCEPTIONAL_PIE
	memory_variant_name = EXCEPTIONAL_PLUMP_PIE_NAME
	memory_variant_desc = EXCEPTIONAL_PLUMP_PIE_DESC

/datum/recipe/plump_pie/food_variant_note()
	return "Each pie has a [EXCEPTIONAL_PLUMP_PIE_CHANCE]% chance to turn out exceptional. An exceptional pie starts with 16 units of nutriment and 5 units of tricordrazine before the oven combines the ingredients."

/datum/recipe/wishsoup
	memory_variant_id = FOOD_MEMORY_SPECIAL_WISH_SOUP
	memory_variant_name = "Special Wish Soup"
	memory_variant_desc = SPECIAL_WISH_SOUP_DESC

/datum/recipe/wishsoup/food_variant_note()
	return "Each bowl has a [SPECIAL_WISH_SOUP_CHANCE]% chance to grant the wish and gain 8 units of nutriment."

/decl/chemical_reaction/instant/food
	var/memory_food_result

/decl/chemical_reaction/instant/food/tofu
	memory_food_result = /obj/item/weapon/reagent_containers/food/snacks/tofu

/decl/chemical_reaction/instant/food/chocolate_bar
	memory_food_result = /obj/item/weapon/reagent_containers/food/snacks/chocolatebar
	drink_pour_order = list("enzyme", "sugar", "coco", "soymilk")

/decl/chemical_reaction/instant/food/chocolate_bar2
	memory_food_result = /obj/item/weapon/reagent_containers/food/snacks/chocolatebar
	drink_pour_order = list("enzyme", "sugar", "coco", "milk")

/decl/chemical_reaction/instant/food/cheesewheel
	memory_food_result = /obj/item/weapon/reagent_containers/food/snacks/sliceable/cheesewheel

/decl/chemical_reaction/instant/food/meatball
	memory_food_result = /obj/item/weapon/reagent_containers/food/snacks/meatball

/decl/chemical_reaction/instant/food/dough
	memory_food_result = /obj/item/weapon/reagent_containers/food/snacks/dough

/decl/chemical_reaction/instant/food/syntiflesh
	memory_food_result = /obj/item/weapon/reagent_containers/food/snacks/meat/syntiflesh

/decl/chemical_reaction/instant/food/butter
	memory_food_result = /obj/item/weapon/reagent_containers/food/snacks/spreads/butter

/decl/chemical_reaction/instant/food/coating/batter
	drink_pour_order = list("water", "egg", "flour", "sodiumchloride")

/decl/chemical_reaction/instant/food/coating/beerbatter
	drink_pour_order = list("beer", "egg", "flour", "sodiumchloride")

/proc/character_memory_food_excluded(var/food_id)
	switch(food_id)
		if("/obj/item/weapon/reagent_containers/food/snacks/human/burger", "/obj/item/weapon/reagent_containers/food/snacks/human/kabob")
			return TRUE
	return FALSE

/proc/character_memory_food_item_supported(var/food_type)
	return ispath(food_type, /obj/item/weapon/reagent_containers/food/snacks) || ispath(food_type, /obj/item/weapon/storage/box/wings) || food_type == /obj/structure/theonepizza || food_type == /obj/structure/chaoscake

/proc/character_memory_food_id(var/datum/recipe, var/consumed_type)
	var/food_id
	if(istype(recipe, /datum/recipe))
		var/datum/recipe/cooking = recipe
		if(cooking.result == /obj/structure/chaoscake && !cooking.assembly_steps)
			return null
		if(length(cooking.items) == 1 && !length(cooking.reagents) && !length(cooking.fruit) && ispath(cooking.result, cooking.items[1]))
			if(cooking.items[1] == cooking.result || ispath(consumed_type, cooking.result))
				return null
		if(character_memory_food_item_supported(cooking.result) && cooking.result_quantity > 0 && (length(cooking.items) || length(cooking.fruit) || length(cooking.reagents)))
			food_id = "[cooking.result]"
	else if(istype(recipe, /decl/chemical_reaction/instant/food))
		var/decl/chemical_reaction/instant/food/mixing = recipe
		if(mixing.result_amount <= 0 || !length(mixing.required_reagents) || character_memory_drink_result(mixing))
			return null
		if(ispath(mixing.memory_food_result, /obj/item/weapon/reagent_containers/food/snacks))
			food_id = "[mixing.memory_food_result]"
		else if(SSchemistry.chemical_reagents[mixing.result])
			food_id = "reagent:[mixing.result]"
	return character_memory_food_excluded(food_id) ? null : food_id

/proc/character_memory_add_hand_recipe(var/list/catalogue, var/food_type, var/list/ingredients, var/obj/hand_tool, var/list/fruit)
	var/datum/recipe/assembly = new
	assembly.appliance = 0
	assembly.result = food_type
	assembly.items = ingredients
	assembly.fruit = fruit
	assembly.coating = -1
	assembly.hand_tool = hand_tool
	LAZYADD(catalogue["[food_type]"], assembly)
	return assembly

/proc/character_memory_food_recipes(var/food_id)
	var/static/list/recipes_by_food
	if(!recipes_by_food)
		recipes_by_food = list()
		var/datum/recipe/cake = new
		cake.appliance = 0
		cake.result = /obj/structure/chaoscake
		var/obj/structure/chaoscake/cake_type = cake.result
		cake.items = new/list(initial(cake_type.maxstages))
		cake.assembly_steps = list()
		for(var/recipe_type in subtypesof(/datum/recipe))
			if(recipe_type == /datum/recipe/monkeykabob)
				continue
			var/datum/recipe/recipe = new recipe_type
			if(recipe.result == cake.result || ispath(recipe.result, /obj/item/weapon/chaoscake_layer))
				var/stage = 1
				if(recipe.result != cake.result)
					var/obj/item/weapon/chaoscake_layer/layer = recipe.result
					stage = initial(layer.layer_stage) + 1
				cake.items[stage] = recipe.result
				cake.assembly_steps["[recipe.result]"] = recipe
				continue
			var/id = character_memory_food_id(recipe)
			if(id)
				LAZYADD(recipes_by_food[id], recipe)
				if(recipe.memory_variant_id)
					LAZYADD(recipes_by_food[recipe.memory_variant_id], recipe)
			else
				qdel(recipe)
		recipes_by_food["[cake.result]"] = list(cake)
		var/list/bun_recipes = bun_filling_recipes()
		for(var/filling in bun_recipes)
			character_memory_add_hand_recipe(recipes_by_food, bun_recipes[filling], list(/obj/item/weapon/reagent_containers/food/snacks/bun, filling))
		for(var/burger_type in list(/obj/item/weapon/reagent_containers/food/snacks/monkeyburger, /obj/item/weapon/reagent_containers/food/snacks/human/burger))
			character_memory_add_hand_recipe(recipes_by_food, /obj/item/weapon/reagent_containers/food/snacks/cheeseburger,
				list(burger_type, /obj/item/weapon/reagent_containers/food/snacks/cheesewedge))
		character_memory_add_hand_recipe(recipes_by_food, /obj/item/weapon/reagent_containers/food/snacks/sliceable/flatdough,
			list(/obj/item/weapon/reagent_containers/food/snacks/dough), /obj/item/weapon/material/kitchen/rollingpin)
		character_memory_add_hand_recipe(recipes_by_food, /obj/item/weapon/reagent_containers/food/snacks/rawsticks,
			hand_tool = /obj/item/weapon/material/knife, fruit = list("potato" = 1))
		character_memory_add_hand_recipe(recipes_by_food, /obj/item/weapon/reagent_containers/food/snacks/rawsunflower,
			hand_tool = /obj/item/weapon/material/knife, fruit = list("sunflower" = 1))
		character_memory_add_hand_recipe(recipes_by_food, /obj/item/weapon/reagent_containers/food/snacks/pineapple_ring,
			hand_tool = /obj/item/weapon/material/knife, fruit = list("pineapple" = 1))
		character_memory_add_hand_recipe(recipes_by_food, /obj/item/weapon/reagent_containers/food/snacks/soydope,
			hand_tool = /obj/item/weapon/material/knife, fruit = list("soybeans" = 1))
		character_memory_add_hand_recipe(recipes_by_food, /obj/item/weapon/reagent_containers/food/snacks/carrotfries,
			hand_tool = /obj/item/weapon/material/knife, fruit = list("carrot" = 1))
		for(var/obj/item/weapon/reagent_containers/food/snacks/source as anything in list(/obj/item/weapon/reagent_containers/food/snacks/meat, /obj/item/weapon/reagent_containers/food/snacks/rawcutlet))
			var/datum/recipe/cut = character_memory_add_hand_recipe(recipes_by_food, initial(source.knife_slice_path), list(source), /obj/item/weapon/material/knife)
			cut.result_quantity = initial(source.slices_num)
		var/list/cone_ingredients = icecream_vat_cone_ingredients()
		for(var/flavour in cone_ingredients)
			var/datum/recipe/cone = character_memory_add_hand_recipe(recipes_by_food, /obj/item/weapon/reagent_containers/food/snacks/icecream, hand_tool = /obj/machinery/icecream_vat)
			cone.reagents = cone_ingredients[flavour]
			cone.preparation_note = "Choose Make under [flavour] cones on the vat, then Dispense to take a cone."
		for(var/decl/chemical_reaction/instant/food/recipe in SSchemistry.chemical_reactions)
			var/id = character_memory_food_id(recipe)
			if(id)
				LAZYADD(recipes_by_food[id], recipe)
	return isnull(food_id) ? recipes_by_food : recipes_by_food[food_id]

/proc/character_memory_food_item_name(var/obj/food_type)
	var/static/list/names = list(
		/obj/item/weapon/holder/diona = "held diona nymph",
		/obj/item/weapon/reagent_containers/food/snacks/berryclafoutis/poison = "Berry Clafoutis (poison berry)",
		/obj/item/weapon/reagent_containers/food/snacks/berrymuffin/poison = "berry muffin (poison berry)",
		/obj/item/weapon/reagent_containers/food/snacks/bloodsoup = "Tomato soup (blood)",
		/obj/item/weapon/reagent_containers/food/snacks/donut/plain/jelly = "plain jelly donut (berry)",
		/obj/item/weapon/reagent_containers/food/snacks/donut/plain/jelly/cherryjelly = "plain jelly donut (cherry)",
		/obj/item/weapon/reagent_containers/food/snacks/donut/plain/jelly/poisonberry = "plain jelly donut (poison berry)",
		/obj/item/weapon/reagent_containers/food/snacks/donut/plain/jelly/slimejelly = "plain jelly donut (slime)",
		/obj/item/weapon/reagent_containers/food/snacks/ghostmuffin/poison = "booberry muffin (poison berry)",
		/obj/item/weapon/reagent_containers/food/snacks/gigapuddi = "Astro-Pudding (plain)",
		/obj/item/weapon/reagent_containers/food/snacks/gigapuddi/anger = "Astro-Pudding (hate)",
		/obj/item/weapon/reagent_containers/food/snacks/gigapuddi/happy = "Astro-Pudding (love)",
		/obj/item/weapon/reagent_containers/food/snacks/grub_blue = "blue candy grub",
		/obj/item/weapon/reagent_containers/food/snacks/grub_purple = "purple candy grub",
		/obj/item/weapon/reagent_containers/food/snacks/human/burger = "human-meat burger",
		/obj/item/weapon/reagent_containers/food/snacks/jelliedtoast/cherry = "Jellied Toast (cherry)",
		/obj/item/weapon/reagent_containers/food/snacks/jelliedtoast/slime = "Jellied Toast (slime)",
		/obj/item/weapon/reagent_containers/food/snacks/jellyburger/cherry = "Jelly Burger (cherry)",
		/obj/item/weapon/reagent_containers/food/snacks/jellyburger/slime = "Jelly Burger (slime)",
		/obj/item/weapon/reagent_containers/food/snacks/jellysandwich/cherry = "Jelly Sandwich (cherry)",
		/obj/item/weapon/reagent_containers/food/snacks/jellysandwich/peanutbutter = "Jelly Sandwich (peanut butter)",
		/obj/item/weapon/reagent_containers/food/snacks/jellysandwich/slime = "Jelly Sandwich (slime)",
		/obj/item/weapon/reagent_containers/food/snacks/meat/human = "human meat",
		/obj/item/weapon/reagent_containers/food/snacks/omurice = "omelette rice (plain)",
		/obj/item/weapon/reagent_containers/food/snacks/omurice/face = "omelette rice (face)",
		/obj/item/weapon/reagent_containers/food/snacks/omurice/heart = "omelette rice (heart)",
		/obj/item/weapon/reagent_containers/food/snacks/rawsunflower = "raw sunflower seeds",
		/obj/item/weapon/reagent_containers/food/snacks/roastedsunflower = "roasted sunflower seeds",
		/obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza = "sliceable pizza"
	)
	return names[food_type] || initial(food_type.name)

/proc/character_memory_food_variant_recipe(var/food_id)
	if(findtext(food_id, "variant:") == 1)
		var/list/recipes = character_memory_food_recipes(food_id)
		return recipes?[1]

/proc/character_memory_food_item_type(var/food_id)
	var/datum/recipe/variant = character_memory_food_variant_recipe(food_id)
	return variant ? variant.result : text2path(food_id)

/proc/character_memory_food_name(var/food_id)
	var/datum/recipe/variant = character_memory_food_variant_recipe(food_id)
	if(variant)
		return variant.memory_variant_name
	if(findtext(food_id, "reagent:") == 1)
		var/datum/reagent/food = SSchemistry.chemical_reagents[copytext(food_id, 9)]
		return food?.name || food_id
	var/obj/food = text2path(food_id)
	var/obj/structure/chaoscake/cake_type = /obj/structure/chaoscake
	if(food == cake_type)
		return initial(cake_type.completed_name)
	return character_memory_food_item_supported(food) ? character_memory_food_item_name(food) : food_id

/obj/item/weapon/reagent_containers/food/snacks/proc/record_hand_preparation(var/mob/user)
	if(isliving(user))
		var/mob/living/cook = user
		cook.character_memory?.record_food("[type]")

/proc/capture_cooking_operator(var/mob/cook)
	var/datum/character_memory/memory = cook?.character_memory
	if(!memory || memory.ourmob != cook || memory.shutting_down || !memory.can_track(memory.ourmob) || !memory.can_access_memory())
		return null
	if(!memory.save_path)
		memory.load()
	if(!memory.savable || !memory.save_path || !memory.can_access_memory())
		return null
	return new /datum/cooking_memory_binding(memory)

/datum/cooking_memory_binding
	var/datum/weakref/memory_ref
	var/owner_ckey
	var/generation

/datum/cooking_memory_binding/New(var/datum/character_memory/memory)
	memory_ref = WEAKREF(memory)
	owner_ckey = memory.save_owner_ckey
	generation = memory.save_generation

/datum/cooking_memory_binding/proc/resolve()
	RETURN_TYPE(/mob/living)
	var/datum/character_memory/memory = memory_ref.resolve()
	if(!memory || memory.ourmob?.character_memory != memory || memory.shutting_down || !memory.savable || !memory.save_path)
		return null
	if(memory.save_generation == generation && memory.save_owner_ckey == owner_ckey && memory.can_access_memory())
		return memory.ourmob

/datum/recipe/proc/record_food_batches(var/list/prepared_batches, var/mob/maker, var/atom/destination)
	if(!isliving(maker) || QDELETED(maker) || !destination)
		return
	var/list/batch_counts = list()
	for(var/list/batch as anything in prepared_batches)
		var/datum/recipe/preparation = prepared_batches[batch]
		if(length(batch) != preparation.result_quantity)
			continue
		var/output_type = preparation.serving_type || preparation.result
		var/complete = TRUE
		for(var/obj/food as anything in batch)
			if(QDELETED(food) || food.loc != destination || !istype(food, output_type))
				complete = FALSE
				break
		if(complete)
			preparation.count_food_batch(batch_counts, batch)
	var/mob/living/cook = maker
	for(var/food_id in batch_counts)
		cook.character_memory?.record_food(food_id, batch_counts[food_id])

/datum/recipe/proc/count_food_batch(var/list/batch_counts, var/list/batch)
	if(!memory_variant_id)
		batch_counts["[result]"]++
		return
	var/list/food_ids = list()
	for(var/obj/item/weapon/reagent_containers/food/snacks/serving as anything in batch)
		food_ids |= (serving.is_exceptional ? memory_variant_id : "[result]")
	for(var/food_id in food_ids)
		batch_counts[food_id]++

/datum/reagents/proc/record_mixed_foods(var/mob/mixer, var/list/reactions)
	if(!isliving(mixer) || !isobj(my_atom) || QDELETED(mixer))
		return
	var/mob/living/maker = mixer
	if(!maker.character_memory)
		return
	var/list/batch_counts = list()
	for(var/decl/chemical_reaction/instant/food/recipe in reactions)
		if(recipe.memory_food_result && !get_turf(my_atom))
			continue
		var/food_id = character_memory_food_id(recipe)
		if(food_id)
			batch_counts[food_id]++
	for(var/food_id in batch_counts)
		maker.character_memory.record_food(food_id, batch_counts[food_id])

/datum/character_memory/proc/init_foods_schema()
	return execute_database_update("CREATE TABLE IF NOT EXISTS foods (food_id TEXT NOT NULL PRIMARY KEY, times_made INTEGER NOT NULL DEFAULT 0, first_made TEXT, last_made TEXT)", "create character memory foods table")

/datum/character_memory/proc/load_database_foods()
	var/list/rows = execute_database_query("SELECT food_id, times_made, first_made, last_made FROM foods", "load character memory foods")
	if(!islist(rows))
		return FALSE
	var/list/loaded_foods = list()
	for(var/list/row as anything in rows)
		var/food_id = row["food_id"]
		var/times_made = text2num("[row["times_made"]]")
		if(!istext(food_id) || !length(food_id) || character_memory_food_excluded(food_id) || !isnum(times_made) || times_made < 1)
			if(!execute_database_update(list("DELETE FROM foods WHERE food_id = ? AND times_made = ?", food_id, row["times_made"]), "remove invalid character memory food"))
				return FALSE
			continue
		loaded_foods[food_id] = list("times_made" = round(times_made), "first_made" = row["first_made"], "last_made" = row["last_made"])
	foods = loaded_foods
	recipes_saved_path = save_path
	food_search_cache.Cut()
	set_recipe_discoveries("cooking", length(foods), reconcile_keys = TRUE)
	return TRUE

/datum/character_memory/proc/database_food_count()
	var/list/rows = execute_database_query("SELECT COUNT(*) AS discoveries FROM foods", "count character memory discoveries")
	return rows?[1]?["discoveries"]

/datum/character_memory/proc/food_save_committed(var/list/saved_rows, var/discovery_count)
	if(!length(pending_food_batches) && recipes_saved_path == save_path)
		return
	for(var/food_id in saved_rows)
		foods[food_id] = saved_rows[food_id]
	var/list/discoveries = list()
	for(var/food_id in pending_food_batches)
		if(foods[food_id]["times_made"] == pending_food_batches[food_id]["times_made"])
			discoveries += food_id
	pending_food_batches.Cut()
	recipes_saved_path = save_path
	if(!can_access_memory())
		set_recipe_discoveries("cooking", discovery_count)
		return
	if(discovery_count == length(foods) || !load_database_foods())
		set_recipe_discoveries("cooking", discovery_count)
	for(var/food_id in discoveries)
		to_chat(ourmob, SPAN_NOTICE("You learned to make [character_memory_food_name(food_id)]! +1 cooking XP ([recipe_discoveries["cooking"]] total). Find the recipe in Memory's Food tab."))

/datum/character_memory/proc/record_food(var/food_id, var/batches = 1)
	if(!isnum(batches) || !ISINTEGER(batches) || batches < 1 || !food_id || !can_track(ourmob) || shutting_down || !length(character_memory_food_recipes(food_id)))
		return FALSE
	if(!bind_pending_recipes())
		return FALSE
	return record_recipe_batches(food_id, foods, pending_food_batches, batches)

/proc/character_memory_produce_names(var/tag, var/hand_tool)
	var/static/list/names_by_tag
	var/static/list/names_by_cut = list()
	if(!names_by_tag)
		names_by_tag = list()
		for(var/seed_id in SSplants.seeds)
			var/datum/seed/seed = SSplants.seeds[seed_id]
			if(!seed.roundstart || !seed.seed_name || seed.get_trait(TRAIT_YIELD) <= 0)
				continue
			var/harvest_type = seed.has_mob_product || seed.has_item_product || /obj/item/weapon/reagent_containers/food/snacks/grown
			if(!ispath(harvest_type, /obj/item/weapon/reagent_containers/food/snacks/grown))
				continue
			if(seed.kitchen_tag)
				LAZYOR(names_by_tag[seed.kitchen_tag], seed.seed_name)
			var/cut_tag = seed.food_cut_tag()
			if(cut_tag)
				LAZYOR(names_by_cut[cut_tag], seed.seed_name)
	if(ispath(hand_tool, /obj/item/weapon/material/knife))
		return names_by_cut[tag] || list(tag)
	return names_by_tag[tag] || list(tag)

/proc/character_memory_food_package_servings(var/package_type, var/prepared = FALSE)
	var/static/list/servings_by_package = list()
	var/static/list/prepared_types_by_package = list()
	if(!servings_by_package[package_type])
		var/obj/item/weapon/storage/box/wings/package = new package_type(null)
		var/list/servings = list()
		var/list/prepared_types = list()
		for(var/obj/item/weapon/reagent_containers/food/snacks/food in package)
			servings[food.type]++
			var/obj/item/weapon/reagent_containers/food/snacks/cube/cube = food
			prepared_types |= istype(cube) ? cube.food_type : food.type
		servings_by_package[package_type] = servings
		prepared_types_by_package[package_type] = prepared_types
		qdel(package)
	return prepared ? prepared_types_by_package[package_type] : servings_by_package[package_type]

/proc/character_memory_food_pizza_slices()
	var/static/list/slices
	if(!slices)
		var/obj/structure/theonepizza/pizza = new(null)
		slices = pizza.slicelist
		qdel(pizza)
	return slices

/proc/character_memory_food_item_preparation(var/obj/item/weapon/reagent_containers/food/snacks/product, var/item_type)
	if(ispath(product, item_type))
		return list("pieces" = 1, "names" = list(), "notes" = list())
	var/list/servings
	if(ispath(product, /obj/item/weapon/storage/box/wings))
		servings = character_memory_food_package_servings(product)
	else if(product == /obj/structure/theonepizza)
		servings = character_memory_food_pizza_slices()
	else if(ispath(product, /obj/item/weapon/reagent_containers/food/snacks) && initial(product.slices_num) > 0)
		servings = list(product)
	else
		return null

	var/total_pieces = 0
	var/list/names = list()
	var/list/notes = list()
	for(var/serving in servings)
		var/obj/item/weapon/reagent_containers/food/snacks/piece = serving
		var/list/cuts = list()
		while(!ispath(piece, item_type) && ispath(piece, /obj/item/weapon/reagent_containers/food/snacks))
			if(initial(piece.slices_num) <= 0 || (piece in cuts))
				break
			var/next_piece = initial(piece.knife_slice_path) || initial(piece.slice_path)
			cuts[piece] = next_piece
			piece = next_piece
		if(!ispath(piece, item_type))
			continue
		var/pieces = servings[serving] || 1
		if(serving != product)
			var/serving_name = character_memory_food_item_name(serving)
			names |= serving_name
			if(product == /obj/structure/theonepizza)
				notes |= "Cut [character_memory_food_item_name(product)] with a kitchen knife to make [length(servings)] giant slices."
			else
				notes += "Each [character_memory_food_item_name(product)] contains [pieces] × [serving_name]."
		for(var/obj/item/weapon/reagent_containers/food/snacks/source as anything in cuts)
			var/count = initial(source.slices_num)
			var/slice_name = character_memory_food_item_name(cuts[source])
			var/surface = initial(source.knife_slice_path) ? "" : " on a table, operating table, or tray"
			notes |= "Cut [character_memory_food_item_name(source)] with a kitchen knife[surface] to make [count] × [slice_name]."
			names |= slice_name
			pieces *= count
		total_pieces += pieces
	if(total_pieces)
		return list("pieces" = total_pieces, "names" = names, "notes" = notes)

/datum/character_memory/proc/known_food_item_sources(var/item_type)
	if(!ispath(item_type, /obj/item))
		return null
	var/static/list/catalogue_matches = list()
	var/list/matches = catalogue_matches[item_type]
	if(!islist(matches))
		matches = list()
		for(var/id in character_memory_food_recipes())
			var/list/preparation = character_memory_food_item_preparation(character_memory_food_item_type(id), item_type)
			if(preparation)
				matches[id] = preparation
		catalogue_matches[item_type] = matches
	return matches & foods

/datum/character_memory/proc/build_food_items(var/datum/recipe/recipe, var/multiplier = 1)
	var/list/amounts = list()
	for(var/item_type in recipe.items)
		amounts["[item_type]"]++
	var/list/items = list()
	for(var/item_id in amounts)
		var/obj/ingredient = text2path(item_id)
		var/name = character_memory_food_item_name(ingredient)
		if(recipe.assembly_steps)
			name = "Layer [length(items) + 1] ([name])"
		items += list(list("id" = item_id, "name" = name, "amount" = amounts[item_id] * multiplier))
	for(var/fruit in recipe.fruit)
		var/produce = english_list(character_memory_produce_names(fruit, recipe.hand_tool), and_text = " or ")
		items += list(list("id" = "produce:[fruit]", "name" = "[produce] (produce)", "amount" = recipe.fruit[fruit] * multiplier))
	return items

/datum/recipe/proc/food_coating_target()
	if(appliance && !(appliance & MICROWAVE))
		for(var/item in items)
			if(ispath(item, /obj/item/weapon/reagent_containers/food/snacks))
				return "ingredients"
	if(length(fruit))
		return "produce"
	return null

/datum/character_memory/proc/build_food_recipe(var/datum/recipe, var/multiplier = 1, var/list/path, var/product_name)
	multiplier = max(1, multiplier)
	var/food_id = character_memory_food_id(recipe)
	if(istype(recipe, /decl/chemical_reaction/instant/food))
		var/decl/chemical_reaction/instant/food/mixing = recipe
		var/list/data = build_drink_recipe(mixing, multiplier, path)
		data["product"] = character_memory_food_name(food_id)
		if(mixing.memory_food_result)
			data["yield_unit"] = "item"
			data["mixture_volume"] -= data["yield"]
		return data
	var/datum/recipe/cooking = recipe
	if(cooking.serving_type)
		product_name = character_memory_food_item_name(cooking.serving_type)
	var/list/equipment = list()
	if(!cooking.appliance)
		equipment += cooking.hand_tool ? capitalize(character_memory_food_item_name(cooking.hand_tool)) : "Hand assembly"
	if(cooking.appliance & MICROWAVE)
		equipment += istype(cooking, /datum/recipe/theonepizza) ? "Deluxe microwave" : "Microwave"
	if(cooking.appliance & OVEN)
		equipment += "Oven"
	if(cooking.appliance & GRILL)
		equipment += "Grill"
	if(cooking.appliance & FRYER)
		equipment += "Deep fryer"
	if(cooking.appliance & CANDYMAKER)
		equipment += "Candy machine"
	if(cooking.appliance & CEREALMAKER)
		equipment += "Cereal maker"
	var/list/items = build_food_items(cooking, multiplier)
	var/list/ingredients = build_drink_ingredients(cooking.reagents, multiplier)
	var/list/next_path = islist(path) ? path.Copy() : list()
	next_path += food_id || "[cooking.result]"
	var/list/coating_ingredient
	var/coating
	var/coating_target = cooking.food_coating_target()
	if(coating_target)
		if(ispath(cooking.coating, /datum/reagent))
			var/datum/reagent/coating_type = cooking.coating
			coating = "For dipping, put the coating in an open non-food container such as a beaker."
			coating_ingredient = list(
				"id" = initial(coating_type.id),
				"name" = initial(coating_type.name),
				"instruction" = coating_target == "produce" ? "Coat each piece of produce" : "Coat each food ingredient"
			)
		else if(isnull(cooking.coating))
			coating = "Use uncoated [coating_target]."
	var/list/ingredient_recipes = build_drink_ingredient_recipes(ingredients, list(), next_path, coating_ingredient?["id"])
	if(length(next_path) < 32)
		for(var/list/item as anything in items)
			var/item_id = item["id"]
			var/datum/recipe/assembly_step = cooking.assembly_steps?[item_id]
			if(assembly_step)
				ingredient_recipes[item_id] = list(build_food_recipe(assembly_step, multiplier, next_path, item["name"]))
				continue
			var/list/sources = known_food_item_sources(text2path(item_id))
			var/list/added_recipes
			for(var/known_id in sources)
				if(known_id in next_path)
					continue
				var/list/preparation = sources[known_id]
				for(var/datum/ingredient_recipe as anything in character_memory_food_recipes(known_id))
					if(ingredient_recipe in added_recipes)
						continue
					LAZYADD(added_recipes, ingredient_recipe)
					var/yield
					if(istype(ingredient_recipe, /datum/recipe))
						var/datum/recipe/food_recipe = ingredient_recipe
						yield = food_recipe.result_quantity
					else
						var/decl/chemical_reaction/food_recipe = ingredient_recipe
						yield = food_recipe.result_amount
					var/batches = CEILING(item["amount"] / (yield * preparation["pieces"]), 1)
					var/list/step = build_food_recipe(ingredient_recipe, batches, next_path)
					step["usable_pieces"] = step["yield"] * preparation["pieces"]
					if(length(preparation["notes"]))
						step["notes"] = step["notes"] + preparation["notes"]
					LAZYADD(ingredient_recipes[item_id], list(step))
	var/list/notes = list()
	if(cooking.preparation_note)
		notes += cooking.preparation_note
	if(cooking.assembly_steps)
		notes += "Cook each layer separately, then stack them in order. Finish with the coin of balance."
	if(cooking.memory_variant_id && (cooking.memory_variant_id in foods))
		notes += cooking.food_variant_note()
	return list(
		"product" = product_name || character_memory_food_name(food_id),
		"items" = items,
		"ingredients" = ingredients,
		"ingredient_recipes" = ingredient_recipes,
		"catalysts" = list(),
		"inhibitors" = list(),
		"leftovers" = list(),
		"pour_order" = list(),
		"notes" = notes,
		"yield" = cooking.result_quantity * multiplier,
		"yield_unit" = "item",
		"method" = jointext(equipment, " / "),
		"equipment" = jointext(equipment, " or "),
		"coating" = coating,
		"coating_ingredient" = coating_ingredient
	)

/datum/character_memory/proc/build_food_search_ingredients(var/food_id)
	if(!islist(foods[food_id]))
		return list()
	if(islist(food_search_cache[food_id]))
		return food_search_cache[food_id]
	var/list/names = list()
	var/list/recipes = character_memory_food_recipes(food_id)
	var/list/pending = recipes?.Copy() || list()
	for(var/index = 1, index <= length(pending), index++)
		var/datum/recipe = pending[index]
		var/list/reagents
		if(istype(recipe, /datum/recipe))
			var/datum/recipe/cooking = recipe
			reagents = cooking.reagents?.Copy() || list()
			for(var/component in cooking.assembly_steps)
				pending |= cooking.assembly_steps[component]
			for(var/list/item as anything in build_food_items(cooking))
				names |= item["name"]
				var/list/sources = known_food_item_sources(text2path(item["id"]))
				for(var/known_id in sources)
					var/list/preparation = sources[known_id]
					names |= character_memory_food_name(known_id)
					names |= preparation["names"]
					pending |= character_memory_food_recipes(known_id)
			for(var/tag in cooking.fruit)
				names |= "[tag] (produce)"
				names |= character_memory_produce_names(tag, cooking.hand_tool)
			if(ispath(cooking.coating, /datum/reagent) && cooking.food_coating_target())
				var/datum/reagent/coating = cooking.coating
				reagents |= initial(coating.id)
		else
			var/decl/chemical_reaction/mixing = recipe
			reagents = mixing.required_reagents.Copy()
			reagents |= mixing.catalysts
		for(var/reagent_id in reagents)
			var/datum/reagent/ingredient = SSchemistry.chemical_reagents[reagent_id]
			names |= ingredient?.name || reagent_id
			names |= build_drink_search_ingredients(reagent_id)
	food_search_cache[food_id] = names
	return names

/obj/item/weapon/reagent_containers/food/snacks
	var/is_exceptional = FALSE
	var/memory_taste_variation
	var/memory_variable_allergens = FALSE

/obj/item/weapon/reagent_containers/food/snacks/chaoscakeslice
	memory_taste_variation = "Varies by slice"
	memory_variable_allergens = TRUE

/obj/item/weapon/reagent_containers/food/snacks/donut/chaos
	memory_taste_variation = "Varies between batches"
	memory_variable_allergens = TRUE

/obj/item/weapon/reagent_containers/food/snacks/mysterysoup
	memory_taste_variation = "Varies between batches"
	memory_variable_allergens = TRUE

/datum/character_memory/proc/build_food_serving_traits(var/list/serving_types)
	var/list/tastes = list()
	var/list/allergens = list()
	for(var/serving_type in serving_types)
		var/list/serving_traits = build_food_traits("[serving_type]")
		if(islist(serving_traits))
			tastes |= serving_traits["taste"]
			allergens |= serving_traits["allergens"]
	return list("taste" = english_list(tastes), "allergens" = allergens, "base_food" = TRUE)

/datum/character_memory/proc/build_food_traits(var/food_id)
	var/static/list/cache = list()
	if(islist(cache[food_id]))
		return cache[food_id]
	var/list/traits
	if(findtext(food_id, "reagent:") == 1)
		var/datum/reagent/food = SSchemistry.chemical_reagents[copytext(food_id, 9)]
		if(!food)
			return null
		var/datum/reagents/sample = new(1)
		sample.add_reagent(food.id, 1, safety = TRUE)
		traits = list("taste" = sample.generate_taste_message(include_intensity = FALSE), "allergens" = character_memory_allergen_names(food.allergen_type))
		qdel(sample)
	else if(ispath(text2path(food_id), /obj/item/weapon/storage/box/wings))
		traits = build_food_serving_traits(character_memory_food_package_servings(text2path(food_id), prepared = TRUE))
	else if(text2path(food_id) == /obj/structure/chaoscake)
		traits = build_food_traits("[/obj/item/weapon/reagent_containers/food/snacks/chaoscakeslice]")
	else if(text2path(food_id) == /obj/structure/theonepizza)
		traits = build_food_serving_traits(character_memory_food_pizza_slices())
	else
		var/obj/item/weapon/reagent_containers/food/snacks/food_type = character_memory_food_item_type(food_id)
		if(!ispath(food_type, /obj/item/weapon/reagent_containers/food/snacks))
			return null
		if(ispath(food_type, /obj/item/weapon/reagent_containers/food/snacks/bageltwo))
			food_type = /obj/item/weapon/reagent_containers/food/snacks/bagelplain
		var/variation = initial(food_type.memory_taste_variation)
		if(variation)
			traits = list("taste" = variation, "allergens" = list(), "variable_allergens" = initial(food_type.memory_variable_allergens) ? variation : null, "base_food" = TRUE)
		else
			var/list/recipes = character_memory_food_recipes(food_id)
			var/datum/recipe/cooking = recipes?[1]
			var/obj/item/weapon/reagent_containers/food/snacks/food
			if(istype(cooking) && cooking.memory_variant_id)
				food = new food_type(null, food_id == cooking.memory_variant_id)
			else
				food = new food_type(null)
			if(!food.reagents)
				qdel(food)
				return null
			var/allergen_types = 0
			for(var/datum/reagent/ingredient as anything in food.reagents.reagent_list)
				allergen_types |= ingredient.allergen_type
			traits = list("taste" = food.reagents.generate_taste_message(), "allergens" = character_memory_allergen_names(allergen_types), "base_food" = TRUE)
			qdel(food)
	cache[food_id] = traits
	return traits

/datum/character_memory/proc/build_food_detail(var/food_id)
	var/list/entry = foods[food_id]
	if(!islist(entry))
		return null
	var/description = "This food is no longer in the recipe book."
	var/static/list/images = list()
	if(findtext(food_id, "reagent:") == 1)
		var/datum/reagent/food = SSchemistry.chemical_reagents[copytext(food_id, 9)]
		description = food?.description || description
		if(!images[food_id])
			var/icon/beaker = icon('icons/obj/chemical.dmi', "beaker", SOUTH, 1)
			var/icon/filling = icon('icons/obj/reagentfillings.dmi', "beaker-60", SOUTH, 1)
			filling.Blend(food?.color || "#808080", ICON_MULTIPLY)
			beaker.Blend(filling, ICON_OVERLAY)
			images[food_id] = icon2base64(beaker)
	else
		var/obj/food = character_memory_food_item_type(food_id)
		if(character_memory_food_item_supported(food))
			description = initial(food.desc)
			var/state = initial(food.icon_state)
			var/datum/recipe/variant = character_memory_food_variant_recipe(food_id)
			if(variant)
				description = variant.memory_variant_desc
			if(food == /obj/structure/chaoscake)
				var/obj/structure/chaoscake/cake_type = food
				description = initial(cake_type.completed_desc)
				state = "chaoscake-[initial(cake_type.maxslices)]"
			if(!images[food_id] && (state in cached_icon_states(initial(food.icon))))
				images[food_id] = icon2base64(icon(initial(food.icon), state, SOUTH, 1))
	var/list/recipes = list()
	for(var/datum/recipe as anything in character_memory_food_recipes(food_id))
		recipes += list(build_food_recipe(recipe))
	return list(
		"id" = food_id,
		"name" = character_memory_food_name(food_id),
		"description" = description,
		"image" = images[food_id],
		"traits" = build_food_traits(food_id),
		"times_made" = entry["times_made"],
		"first_made" = entry["first_made"],
		"last_made" = entry["last_made"],
		"recipes" = recipes
	)

/datum/character_memory/proc/add_foods_ui_data(var/list/data)
	var/list/rows = list()
	var/total_made = 0
	for(var/food_id in foods)
		var/list/entry = foods[food_id]
		var/list/row = list(
			"id" = food_id,
			"name" = character_memory_food_name(food_id),
			"times_made" = entry["times_made"],
			"ingredient_names" = build_food_search_ingredients(food_id)
		)
		if(food_id == "[/obj/item/weapon/reagent_containers/food/snacks/beetsoup]")
			row["search_text"] = lowertext(jointext(GLOB.beet_soup_names, " "))
		else if(food_id == FOOD_MEMORY_SPECIAL_WISH_SOUP)
			row["search_text"] = lowertext(SPECIAL_WISH_SOUP_DESC)
		rows += list(row)
		total_made += entry["times_made"]
	rows = sortTim(rows, GLOBAL_PROC_REF(cmp_character_memory_contact_row_name), FALSE)
	if(!(selected_food in foods))
		selected_food = length(rows) ? rows[1]["id"] : null
	data["foods"] = rows
	data["cooking_xp"] = recipe_discoveries["cooking"] || 0
	data["foods_made"] = total_made
	data["selected_food"] = selected_food
	data["food_detail"] = flatten_reagent_recipe_detail(build_food_detail(selected_food))
