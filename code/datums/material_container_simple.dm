/*
	This datum should be used for handling mineral contents of machines and whatever else is supposed to hold minerals and make use of them.

	Variables:
		amount - raw amount of the mineral this container is holding,
			TODO - EITHER: calculated by the defined value SHEET_MATERIAL_AMOUNT=2000.
			TODO -     OR: material.perunit
		max_amount - max raw amount of mineral this container can hold.
		sheet_type - type of the mineral sheet the container handles, used for output.
		parent - object that this container is being used by, used for output.
		MAX_STACK_SIZE - size of a stack of mineral sheets. Constant.
*/

// TODO - About the materials var.   It would be nice if all materials/matter vars were initially populated (in code) with type paths for compile time checking.
// 			It also would be nice if the keys at runtime were instances, for easy access to info!  Or leave the runtime keys to be types.
//			However! for compatibilty with the rest of the codebase, we are doing to use */material/var/name* as the keys, since this is used in every other place in the code.
//			In this way we can transition everything at once to a more robust system.
//			In order to prepare for this, where reasonable we will use get_mateiral_ref proc, which returns an instance, but can take instance, name, or type path.
//			In this way we transition will be even smoother as this code will already work regardless!  In time we can optimize away the conversion as reliability improves.


/datum/material_container
	var/atom/parent					// Actual atom we are providing materials to (lathe etc)

	var/total_amount = 0			// Total raw amount of material this container currently holds.
	var/max_amount					// Max raw amount of material this container can hold.
	var/list/materials				// Map of allowed materials and current quantities.  Key = material id | Value = amount
	// TODO - Implement hidden materials
	var/list/hidden_materials		// IDs of material this machine will not display unless it contains them.  Must be in the materials list as well.

	var/show_on_examine
	var/disable_attackby
	var/list/allowed_typecache
	var/last_inserted_id
	var/precise_insertion = FALSE
	var/datum/callback/precondition
	var/datum/callback/after_insert

/datum/material_container/New(atom/parent, list/mat_list, max_amt = 0, _show_on_examine = FALSE, list/allowed_types, datum/callback/precondition, datum/callback/after_insert, _disable_attackby)
	src.parent = parent
	materials = list()
	max_amount = max(0, max_amt)
	show_on_examine = _show_on_examine
	disable_attackby = _disable_attackby

	if(allowed_types)
		if(ispath(allowed_types) && allowed_types == /obj/item/stack/material)
			allowed_typecache = GLOB.typecache_material_stack
		else
			allowed_typecache = typecacheof(allowed_types)

	src.precondition = precondition
	src.after_insert = after_insert

	// See comment at top of file for why we are using material IDs as list keys.
	for(var/mat in mat_list) //Make the assoc list ref | amount
		var/material/M = get_material_ref(mat)
		if(!M)
			log_debug("Material container datum for [parent] initialized with bad material [mat]")
			continue
		materials[M.name] = 0

/datum/material_container/proc/OnExamine(datum/source, mob/user, list/examine_list)
	if(!show_on_examine)
		return
	for(var/I in materials)
		var/amt = materials[I]
		if(amt)
			examine_list += "<span class='notice'>It has [amt] unit\s of [material_display_name(I)] stored.</span>"

/// Proc specifically for inserting items, returns the amount of materials entered.
/datum/material_container/proc/insert_item(obj/item/I, var/multiplier = 1, stack_amt)
	if(!I)
		return FALSE
	multiplier = CEILING(multiplier, 0.01)

	if(istype(I, /obj/item/stack))
		var/obj/item/stack/S = I
		if(isnull(stack_amt))
			stack_amt = S.amount
		if(stack_amt <= 0)
			return FALSE
		if(stack_amt > S.amount)
			stack_amt = S.amount
		var/material_amt = get_item_material_amount(S) * multiplier
		if(!material_amt)
			return FALSE
		stack_amt = min(stack_amt, round(((max_amount - total_amount) / material_amt)))
		if(!stack_amt)
			return FALSE
		last_inserted_id = insert_item_materials(S, stack_amt * multiplier)
		S.use(stack_amt)
		return stack_amt

	var/material_amount = get_item_material_amount(I) * multiplier
	if(!material_amount || !has_space(material_amount))
		return FALSE

	last_inserted_id = insert_item_materials(I, multiplier)
	return material_amount

// For internal use only
/datum/material_container/proc/insert_item_materials(obj/item/I, multiplier = 1)
	var/primary_mat
	var/highest_mat_value = 0
	for(var/MAT in materials)
		materials[MAT] += I.matter[MAT] * multiplier
		total_amount += I.matter[MAT] * multiplier
		if(I.matter[MAT] > highest_mat_value)
			primary_mat = MAT
	return primary_mat

/// Uses an amount of a specific material, effectively removing it.
/datum/material_container/proc/use_amount_mat(amt, var/material/mat)
	if(!istype(mat))
		mat = get_material_ref(mat)
	if(mat && materials[mat.name] >= amt)
		materials[mat] -= amt
		total_amount -= amt
		return amt
	return FALSE

/// Proc that returns TRUE if the container has space
/datum/material_container/proc/has_space(amt = 0)
	return (total_amount + amt) <= max_amount

/datum/material_container/proc/has_materials(list/mats, multiplier = 1)
	if(!mats || !mats.len)
		return FALSE
	
	for(var/x in mats)
		var/material/M = get_material_ref(x)
		if(!(materials[M?.name] >= (mats[x] * multiplier)))
			return FALSE // Doesn't exist or can't afford it!
	return TRUE

/// For consuming a dictionary of materials. mats is the map of materials to use and the corresponding amounts, example: list("glass" = 100, "steel" = 200)
/datum/material_container/proc/use_materials(list/mats, multiplier = 1)
	if(!mats || !length(mats))
		return FALSE

	var/list/mats_to_remove = list() // Assoc list MATID | AMOUNT

	for(var/x in mats) //Loop through all required materials
		var/material/M = get_material_ref(x)
		var/id = M.name
		var/amount_required = mats[x] * multiplier
		if(!(materials[id] >= amount_required)) // do we have enough of the resource?
			return FALSE //Can't afford it
		mats_to_remove[id] += amount_required // Add it to the assoc list of things to remove
		continue

	var/total_amount_save = total_amount
	for(var/i in mats_to_remove)
		materials[i] -= mats_to_remove[i]
		total_amount -= mats_to_remove[i]
	return total_amount_save - total_amount

/// For spawning mineral sheets at a specific location. Used by machines to output sheets.
/datum/material_container/proc/retrieve_sheets(sheet_amt, mat, target = null)
	var/material/M = get_material_ref(mat)
	if(!M || !M.stack_type)
		log_debug("Attempted to retrieve sheets of [mat] from [parent] but it's not valid.")
		return 0

	var/obj/item/stack/material/sheetType = M.stack_type
	var/perSheet = initial(sheetType.perunit)
	var/maxStackSize = initial(sheetType.max_amount)

	if(!target)
		target = get_turf(parent)
	if(isnull(sheet_amt) || materials[M.name] < (sheet_amt * perSheet))
		sheet_amt = round(materials[M] / perSheet)
	var/count = 0
	while(sheet_amt > maxStackSize)
		new sheetType(target, maxStackSize)
		count += maxStackSize
		use_amount_mat(sheet_amt * perSheet, M)
		sheet_amt -= maxStackSize
	if(sheet_amt >= 1)
		new sheetType(target, sheet_amt)
		count += sheet_amt
		use_amount_mat(sheet_amt * perSheet, M)
	return count

/// Proc to get all the materials and dump them as sheets
/datum/material_container/proc/retrieve_all(target = null)
	var/result = 0
	for(var/MAT in materials)
		if(materials[MAT] > 0)
			result += retrieve_sheets(null, MAT, target)
	return result

/// Returns the total amount of material in I relevant to this container; if this container does not support X, any X in 'I' will not be taken into account
/datum/material_container/proc/get_item_material_amount(obj/item/I)
	if(!istype(I) || !LAZYLEN(I.matter))
		return FALSE
	var/material_amount = 0
	for(var/MAT in materials)
		material_amount += I.matter[MAT]
	return material_amount

/// Returns the amount of a specific material in this container.
/datum/material_container/proc/get_material_amount(var/mat)
	var/material/M = get_material_ref(mat)
	return (M && materials[M.name]) || 0

// Eject material as *amount* number of sheets.  Omitting amount ejects all of it.
/datum/material_container/proc/eject(var/material, var/amount = -1)
	var/material/matref = get_material_ref(material)
	if(!matref || !(matref in materials))
		return
	var/obj/item/stack/material/sheetType = matref.stack_type
	var/perSheet = initial(sheetType.perunit)
	var/eject = round(materials[matref] / perSheet)
	eject = (amount == -1) ? eject : min(eject, amount)
	if(eject < 1)
		return
	var/obj/item/stack/material/S = new sheetType(parent.drop_location())
	S.amount = eject
	materials[material] -= (eject * perSheet)
	total_amount -= (eject * perSheet)
