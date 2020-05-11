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




/datum/material_container
	var/atom/parent						// Actual atom we are providing materials to (lathe etc)
	//var/list/materials = list()			// Materials this machine can accept.
	var/list/hidden_materials = list()	// Materials this machine will not display, unless it contains them. Must be in the materials list as well.

	var/total_amount = 0
	var/max_amount
	var/sheet_type
	var/list/materials //Map of key = material ref | Value = amount


	var/show_on_examine
	var/disable_attackby
	var/list/allowed_typecache
	var/last_inserted_id
	var/precise_insertion = FALSE
	var/datum/callback/precondition
	var/datum/callback/after_insert

/datum/material_container/New(atom/parent, list/mat_list, max_amt = 0, _show_on_examine = FALSE, list/allowed_types, datum/callback/_precondition, datum/callback/_after_insert, _disable_attackby)
	materials = list()
	max_amount = max(0, max_amt)
	show_on_examine = _show_on_examine
	disable_attackby = _disable_attackby

	if(allowed_types)
		if(ispath(allowed_types) && allowed_types == /obj/item/stack/material)
			allowed_typecache = GLOB.typecache_material_stack
		else
			allowed_typecache = typecacheof(allowed_types)

	precondition = _precondition
	after_insert = _after_insert

	// RegisterSignal(parent, COMSIG_PARENT_ATTACKBY, .proc/OnAttackBy)
	// RegisterSignal(parent, COMSIG_PARENT_EXAMINE, .proc/OnExamine)

	for(var/mat in mat_list) //Make the assoc list ref | amount
		var/material/M = get_material_by_type(mat)
		materials[M] = 0

/datum/component/material_container/proc/has_materials(list/mats, multiplier=1)
	// TODO
	return

/datum/material_container/proc/OnAttackBy(datum/source, obj/item/I, mob/living/user)
	// TODO
	return


/// For inserting an amount of material
/datum/component/material_container/proc/insert_amount_mat(amt, var/datum/material/mat)
	// TODO
	return

/// For spawning mineral sheets at a specific location. Used by machines to output sheets.
/datum/component/material_container/proc/retrieve_sheets(sheet_amt, var/datum/material/M, target = null)
	// TODO
	return

/// Proc to get all the materials and dump them as sheets
/datum/material_container/proc/retrieve_all(target = null)
	// TODO
	return



// /datum/material_container_rnd/proc/getMaterialSheetType(var/name)
// 	var/material/M = get_material_by_name(name)
// 	if(M && M.stack_type)
// 		return M.stack_type
// 	return null

// /datum/material_container_rnd/proc/getMaterialName(var/type)
// 	if(istype(type, /obj/item/stack/material))
// 		var/obj/item/stack/material/M = type
// 		return M.material.name
// 	return null

// Eject material as *amount* number of sheets.  Omitting amount ejects all of it.
/datum/material_container/proc/eject(var/material, var/amount = -1)
	var/material/matref = get_material_ref(material)
	if(!matref || !(matref in materials))
		return
	var/obj/item/stack/material/sheetType = matref.stack_type
	var/perUnit = initial(sheetType.perunit)
	var/eject = round(materials[matref] / perUnit)
	eject = (amount == -1) ? eject : min(eject, amount)
	if(eject < 1)
		return
	var/obj/item/stack/material/S = new sheetType(parent.drop_location())
	S.amount = eject
	materials[material] -= eject * perUnit
