/**
 *	This datum should be used for handling mineral contents of machines and whatever else is supposed to hold minerals and make use of them.
 *
 * TODO - About the materials var.   It would be nice if all materials/matter vars were initially populated (in code) with type paths for compile time checking.
 * 			It also would be nice if the keys at runtime were instances, for easy access to info!  Or leave the runtime keys to be types.
 *			However! for compatibilty with the rest of the codebase, we are doing to use **material/var/name** as the keys, since this is used in every other place in the code.
 *			In this way we can transition everything at once to a more robust system.
 *			In order to prepare for this, where reasonable we will use get_mateiral_ref proc, which returns an instance, but can take instance, name, or type path.
 *			In this way we transition will be even smoother as this code will already work regardless!  In time we can optimize away the conversion as reliability improves.
 */
/datum/material_container
	var/atom/parent						// Actual atom we are providing materials to (lathe etc)
	var/tmp/total_amount = 0			// Total raw amount of material this container currently hold (auto-calculated field)

	var/max_amount						// Max raw amount of material this container can hold.
	var/list/materials					// Map of allowed materials and current quantities,  Initialized by constructor. Key = material id | Value = amount
	var/list/hidden_materials			// IDs of material this machine will not display unless it contains them.  Must be in the materials list as well.

	// Item insertion settings
	var/list/preserve_composites		// If material sheets of composite material should insert the composite or break it down into its atomic types or add its main type.
	var/list/allowed_typecache			// Types accepted by the insert_item procs. Initialized by constructor
	var/precise_insertion = FALSE		// Flag to prompt users for amount of stacks to insert when inserting 
	var/datum/callback/after_insert

/**
 * Create new material container!
 * @param parent Physical atom that containts the materials "in universe"
 * @param allowed_mats Allowed material types.  List of material type paths (also will accept list of material ids)
 * @param hidden_mats
 * @param max_amt Maximum total volume of materials (shared across all material types)
 * @param allowed_item_types List of obj/item type paths accepted by the insert_item procs.  A single path or list of paths. Null disables.
 */
/datum/material_container/New(atom/parent, list/allowed_mats, max_amt = 0, list/allowed_types, list/hidden_mats, preserve_composites = TRUE, datum/callback/after_insert)
	src.parent = parent
	max_amount = max(0, max_amt)
	src.preserve_composites = preserve_composites
	src.after_insert = after_insert

	if(allowed_types)
		if(ispath(allowed_types) && allowed_types == /obj/item/stack/material)
			allowed_typecache = GLOB.typecache_material_stack
		else
			allowed_typecache = typecacheof(allowed_types)

	// See comment at top of file for why we are using material IDs as list keys.
	materials = list()
	for(var/mat in allowed_mats) //Make the assoc list ref | amount
		var/material/M = get_material_ref(mat)
		if(!M)
			log_debug("Material container datum for [parent] initialized with bad material [mat]")
			continue
		materials[M.name] = 0
	for(var/mat in hidden_mats)
		var/material/M = get_material_ref(mat)
		if(!M)
			log_debug("Material container datum for [parent] initialized with bad hidden material [mat]")
			continue
		materials[M.name] = 0
		LAZYSET(hidden_materials, M.name, TRUE)

// Helper to add contents to examine.
/datum/material_container/proc/OnExamine(datum/source, mob/user, list/examine_list)
	for(var/I in materials)
		var/amt = materials[I]
		if(amt)
			examine_list += "<span class='notice'>It has [amt] unit\s of [material_display_name(I)] stored.</span>"

/** Returns info about materials contained in a list format suitable for JSON/NanoUI */
/datum/material_container/proc/materials_ui_data()
	var/list/materials_ui = list()
	for(var/mat in materials)
		var/amount = materials[mat]
		if(hidden_materials && !amount && (mat in hidden_materials))
			continue // skip showing hidden materials when we have none
		materials_ui[++materials_ui.len] = list(
				"mat" = mat,
				"display" = material_display_name(mat),
				"amt" = amount,
				"max" = max_amount == INFINITY ? -1 : max_amount,
				"percent" = (amount / max_amount * 100))
	return materials_ui

/** Helper proc for when a player attempts to load materials from an item. Intended to be called from attackby().
 * This is truely a helper proc. You are not obligated to use this proc, its totally fine to use insert_item_materials or insert_stack_materials directly.
 * This just handles common cases!
 * @return FALSE if item wasn't an accepted type, otherwise TRUE (even if failed to load)
*/
/datum/material_container/proc/default_user_insert_item(atom/source, mob/user, obj/item/I, yield_factor = 1, datum/callback/extra_after_insert)
	set waitfor = FALSE
	// Return false in the cases the item isn't intended for us. Let other stuff handle it.
	if(user.a_intent == I_HURT)
		return FALSE // Don't intercept if they are trying to thwack
	if(allowed_typecache && !is_type_in_typecache(I, allowed_typecache))
		return FALSE
	// Okay its now an allowed type, so from hereon out we return TRUE since we have elected to handle things.
	. = TRUE
	yield_factor = CEILING(yield_factor, 0.01)
	var/inserted = 0
	if(istype(I, /obj/item/stack))
		var/obj/item/stack/S = I
		// Quick convenience check to give a helpful message to users in the most common use case of lathes.
		if(istype(I, /obj/item/stack/material) && preserve_composites)
			var/obj/item/stack/material/MS = I
			if(!(MS.material.name in materials))
				to_chat(user, "<span class='warning'>\The [source] doesn't accept [MS.material.display_name]!</span>")
				return
		else if(get_total_amount(I.matter, yield_factor) <= 0)
			to_chat(user, "<span class='warning'>[I] does not contain significant amounts of useful materials and cannot be accepted.<span>")
			return
		var/requested_amount = S.get_amount()
		if (precise_insertion && S.get_amount() > 1)
			requested_amount = min(S.get_amount(), input(user, "How much do you want to insert?", "Inserting [S.singular_name]s", requested_amount) as num|null)
			if(isnull(requested_amount) || (requested_amount <= 0))
				return // They pressed cancel
			if(QDELETED(I) || QDELETED(user) || QDELETED(src) || user.check_physical_distance(source) < STATUS_INTERACTIVE || user.get_active_hand() != I)
				return // They walked away or something
		// Attempt the insert.  If the stack is used up completely it handles its own deletion.
		inserted = insert_stack_materials(I, yield_factor, requested_amount)
		if(inserted > 0)
			to_chat(user, "<span class='notice'>You insert [inserted] [S.singular_name]\s into [source].</span>")
		if(inserted < requested_amount)
			to_chat(user, "<span class='warning'>[source] is full. Please remove materials from [source] in order to insert more.</span>")
	else
		if(!user.canUnEquip(I))
			to_chat(user, "<span class='warning'>[I] is stuck to you and cannot be placed into [source].</span>")
			return
		if(get_total_amount(I.matter, yield_factor) <= 0)
			to_chat(user, "<span class='warning'>[I] does not contain significant amounts of useful materials and cannot be accepted.<span>")
			return
		if(!can_insert_materials(I.matter, yield_factor))
			to_chat(user, "<span class='warning'>[source] is full. Please remove material in order to insert more.</span>")
			return
		inserted = insert_materials(I.matter, yield_factor)
		if(inserted > 0)
			to_chat(user, "<span class='notice'>You insert a material total of [inserted] into [source].</span>")
			user.remove_from_mob(I)
			qdel(I)
	// Invoke callback if we in fact did anything
	if(inserted > 0)
		after_insert?.Invoke(I, inserted)
		extra_after_insert?.Invoke(I, inserted)

/**
 * Helper proc for the common case of inserting material sheets. For most machines this is the only way of loading, so it help to have this helper.
 * This is to be used in the most common case of accepting only material stacks and preserving composites.
 * @returns the number of sheets actually added.
 */
/datum/material_container/proc/default_insert_sheets(atom/source, mob/user, obj/item/stack/material/S, yield_factor = 1, precise_insertion = src.precise_insertion)
	set waitfor = FALSE
	if(user.a_intent == I_HURT)
		return // Don't intercept if they are trying to thwack
	if(!istype(S) || (allowed_typecache && !is_type_in_typecache(S, allowed_typecache)))
		return // Return false in the cases the item isn't intended for us. Let other stuff handle it.
	if(!(S.material.name in materials))
		to_chat(user, "<span class='warning'>\The [source] doesn't accept [S.material.display_name]!</span>")
		return
	var/requested_amount = S.get_amount()
	if (precise_insertion && S.get_amount() > 1)
		requested_amount = min(S.get_amount(), input(user, "How much do you want to insert?", "Inserting [S.singular_name]s", requested_amount) as num|null)
		if(isnull(requested_amount) || (requested_amount <= 0))
			return // They pressed cancel
		if(QDELETED(S) || QDELETED(user) || QDELETED(src) || user.check_physical_distance(source) < STATUS_INTERACTIVE || user.get_active_hand() != S)
			return // They walked away or something
	// Attempt the insert.  If the stack is used up completely it handles its own deletion.
	. = insert_stack_materials(S, yield_factor, requested_amount)
	if(. > 0)
		to_chat(user, "<span class='notice'>You insert [.] [S.material.display_name] [S.singular_name]\s into [source].</span>")
	if(. < requested_amount)
		to_chat(user, "<span class='warning'>[source] is full. Please remove materials from [source] in order to insert more.</span>")

/** 
 * Helper proc that inserts the material of an item, intended for non-user-interactive usage.
 * As such it doesn't bother to print feedback about why insertion was denied.
 * @yield_factor is a multiplier to the amount added to materials, NOT to the amount consumed.
 * @force Insert even if some matter would be lost due to disallowed types or full storage
 * @return True if anything was inserted, otherwise false.
*/
/datum/material_container/proc/default_insert_item(obj/item/I, yield_factor = 1, force = FALSE, datum/callback/extra_after_insert)
	if(allowed_typecache && !is_type_in_typecache(I, allowed_typecache))
		return FALSE

	yield_factor = CEILING(yield_factor, 0.01)
	var/inserted = 0
	if(istype(I, /obj/item/stack))
		inserted = insert_stack_materials(I, yield_factor)
	else if(force || can_insert_materials(I.matter, yield_factor))
		inserted = insert_materials(I.matter, yield_factor)
		if(inserted > 0)
			qdel(I)
	if(inserted > 0)
		after_insert?.Invoke(I, inserted)
		extra_after_insert?.Invoke(I, inserted)
		return TRUE	
	return FALSE

/**
 * Helper proc that inserts stacks (or parts of a stack).  Note: Not necessarily material stacks, this works for any stack with matter!
 * @yield_factor is a multiplier to the amount added to materials, NOT to the amount consumed.
 * @stack_amt is the desired amount of stacks to use from S. May actually use less if we don't have room for it all.
 * @return amount of stacks actually used and inserted.
*/
/datum/material_container/proc/insert_stack_materials(obj/item/stack/S, yield_factor = 1, stack_amt = INFINITY)
	if(!istype(S))
		return 0

	var/list/matter_per_stack = S.matter
	// Special handling for material sheets if we want the composite material instead of its component sub-materials.
	if(istype(S, /obj/item/stack/material) && preserve_composites)
		var/obj/item/stack/material/MS = S
		matter_per_stack = list(MS.material.name = MS.perunit)

	// Calculate mass per stack
	var/units_per_stack = get_total_amount(matter_per_stack, multiplier = yield_factor)
	if(units_per_stack <= 0)
		return 0  // It contains nothing usable after all
	var/max_that_will_fit = round((max_amount - total_amount) / units_per_stack)
	var/stacks_to_use = clamp(stack_amt, 0, min(max_that_will_fit, S.get_amount()))
	if(stacks_to_use >= 1 && S.use(stacks_to_use))
		insert_materials(matter_per_stack, stacks_to_use * yield_factor)
		return stacks_to_use
	return 0

//
// Misc
//

/**
 * Get the total quantity of materials in mats, counting only materials allowed in this container.
 * @multiplier Multiply total by this amount
 * @include_disallowed_types Also count materials disallowed by this container (for some reason)
*/
/datum/material_container/proc/get_total_amount(list/mats, multiplier = 1, include_disallowed_types = FALSE)
	if(!LAZYLEN(mats))
		return 0
	var/total_amount = 0
	for(var/x in mats)
		var/material/M = get_material_ref(x)
		if(M && ((M.name in materials) || include_disallowed_types))
			total_amount += mats[x]
	return total_amount * multiplier

/// Returns the amount of a specific material in this container.
/datum/material_container/proc/get_material_amount(var/material/mat)
	if(!istype(mat))
		mat = get_material_ref(mat)
	return (mat && materials[mat.name]) || 0

///////////////////////////////////////////////////////////
// Associative materials list version of functions
///////////////////////////////////////////////////////////

/// Checks if we can affor it.
/datum/material_container/proc/can_use_materials(list/mats, multiplier = 1)
	if(!LAZYLEN(mats))
		return FALSE
	
	for(var/x in mats)
		var/material/M = get_material_ref(x)
		var/amount_required = mats[x] * multiplier
		if(!M || !(materials[M.name] >= amount_required))
			return FALSE // Doesn't exist or can't afford it!
	return TRUE

/// For consuming a dictionary of materials. mats is the map of materials to use and the corresponding amounts, example: list("glass" = 100, "steel" = 200)
/// Strict pass/fail, if *any* entry in mats isn't available, *nothing* is withdrawn.
/datum/material_container/proc/use_materials(list/mats, multiplier = 1)
	if(!LAZYLEN(mats))
		return FALSE

	var/list/mats_to_remove = list() // Assoc list MATID | AMOUNT
	for(var/x in mats) //Loop through all required materials
		var/material/M = get_material_ref(x)
		var/amount_required = mats[x] * multiplier
		if(!M || !(materials[M.name] >= amount_required)) // do we have enough of the resource?
			return FALSE //Can't afford it
		mats_to_remove[M.name] += amount_required // Add it to the assoc list of things to remove

	var/total_amount_save = total_amount
	for(var/i in mats_to_remove)
		materials[i] -= mats_to_remove[i]
		total_amount -= mats_to_remove[i]
	return total_amount_save - total_amount

// Checks if we can insert all the materials in mats.
/datum/material_container/proc/can_insert_materials(list/mats, multiplier = 1, ignore_disallowed_types = FALSE)
	if(!LAZYLEN(mats))
		return FALSE

	var/material_amount = 0
	for(var/x in materials)
		var/material/M = get_material_ref(x)
		if(!M || !(M.name in materials))
			if(ignore_disallowed_types)
				continue;
			return FALSE // Not an allowed material
		material_amount += mats[x]	
	material_amount *= multiplier
	return (material_amount > 0) && (total_amount + material_amount <= max_amount)

// Adds materials.  Partial success allowed If it fills up we add what we can and stop.
/datum/material_container/proc/insert_materials(list/mats, multiplier = 1)
	if(!LAZYLEN(mats))
		return FALSE

	. = 0
	for(var/x in mats)
		var/material/M = get_material_ref(x)
		if(!M || !(M.name in materials))
			continue // Not an allowed material
		var/amount_to_add = clamp(mats[x] * multiplier, 0, max_amount - total_amount)
		materials[M.name] += amount_to_add
		total_amount += amount_to_add
		. += amount_to_add

///////////////////////////////////////////////////////////
// Material Sheet functions - For outputting as sheets
///////////////////////////////////////////////////////////

/// For spawning mineral sheets at a specific location. Used by machines to output sheets.
/datum/material_container/proc/retrieve_sheets(sheet_amt = INFINITY, mat, target = null)
	var/material/M = get_material_ref(mat)
	if(!M || !M.stack_type)
		log_debug("Attempted to retrieve sheets of [mat] from [parent] but it's not valid.")
		return 0
	
	if(!target)
		target = parent.drop_location()

	var/obj/item/stack/material/sheetType = M.stack_type
	var/perSheet = initial(sheetType.perunit)
	var/maxStackSize = initial(sheetType.max_amount)
	var/stacks_to_make = clamp(sheet_amt, 0, round(materials[M.name] / perSheet))

	// If the're asking for more than fit in a single stack, we need to spawn multiple
	var/count = 0
	while(stacks_to_make >= 1)
		var/qty = min(stacks_to_make, maxStackSize)
		if(!use_materials(list(M.name = perSheet), qty))
			log_debug("Okay somehow didn't get val from use_materials([json_encode(list(M.name = perSheet))], [qty])")
		new sheetType(target, qty)
		count += qty
		stacks_to_make -= qty
	return count

/// Helper proc to get all the materials and dump them as sheets
/datum/material_container/proc/retrieve_all(target = null)
	var/result = 0
	for(var/MAT in materials)
		if(materials[MAT] > 0)
			result += retrieve_sheets(null, MAT, target)
	return result

///////////////////////////////////////////////////////////
// Single material version of functions
///////////////////////////////////////////////////////////

// // private
// // Check if we have enough space to add an amount of a specific material
// /datum/material_container/proc/can_insert_amount_mat(amt = 0, var/material/mat)
// 	// Note: doesn't check if mat is valid for this container.  Intentional for now since it is not always passed.
// 	return (total_amount + amt) <= max_amount

// // private
// /// For inserting an amount of material.  If you try to insert more than there is room, insets what it can. Returns amount inserted.
// /datum/material_container/proc/insert_amount_mat(amt = 0, var/material/mat)
// 	if(!istype(mat))
// 		mat = get_material_ref(mat)
// 	if(!mat || !(mat.name in materials))
// 		return FALSE // Not an allowed material
// 	var/amount_to_add = clamp(amt, 0, max_amount - total_amount)
// 	materials[mat.name] += amount_to_add
// 	total_amount += amount_to_add
// 	return amount_to_add

// // private
// // Check if we have enough of a specific material to use an amount of it.
// /datum/material_container/proc/can_use_amount_mat(amt = 0, var/material/mat)
// 	if(!istype(mat))
// 		mat = get_material_ref(mat)
// 	if(mat && materials[mat.name] >= amt)
// 		return TRUE
// 	return FALSE

// // private
// /// Uses an amount of a specific material, effectively removing it.
// /datum/material_container/proc/use_amount_mat(amt = 0, var/material/mat)
// 	if(!istype(mat))
// 		mat = get_material_ref(mat)
// 	if(mat && materials[mat.name] >= amt)
// 		materials[mat.name] -= amt
// 		total_amount -= amt
// 		return amt
// 	return FALSE
