// RS Add Start: Enhanced mass edit (Lira, February 2026)
#define VV_MASS_EDIT_SCOPE_SCREEN "On Screen"
#define VV_MASS_EDIT_SCOPE_Z "This Z"
#define VV_MASS_EDIT_SCOPE_GLOBAL "Global"
// RS Add End

/client/proc/cmd_mass_modify_object_variables(datum/A, var_name)   //RS Edit: Why atom when u can datum (Lira, February 2026)
	set category = "Debug"
	set name = "Mass Edit Variables"
	set desc="(target) Edit all instances of a target item's variables"

	var/method = 0	//0 means strict type detection while 1 means this type and all subtypes (IE: /obj/item with this set to 1 will set it to ALL items)

	if(!check_rights(R_VAREDIT))
		return

	if(A && A.type)
		method = vv_subtype_prompt(A.type)

	src.massmodify_variables(A, var_name, method)
	feedback_add_details("admin_verb","MVV") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/client/proc/massmodify_variables(datum/O, var_name = "", method = 0)
	if(!check_rights(R_VAREDIT))
		return
	if(!istype(O))
		return

	var/variable = ""
	if(!var_name)
		var/list/names = list()
		for (var/V in O.vars)
			names += V

		names = sortList(names)

		variable = tgui_input_list(usr, "Which var?", "Var", names)
	else
		variable = var_name

	if(!variable || !O.can_vv_get(variable))
		return
	var/default
	var/var_value = O.vars[variable]

	if(variable in GLOB.VVckey_edit)
		to_chat(src, "It's forbidden to mass-modify ckeys. It'll crash everyone's client you dummy.")
		return
	if(variable in GLOB.VVlocked)
		if(!check_rights(R_DEBUG))
			return
	if(variable in GLOB.VVicon_edit_lock)
		if(!check_rights(R_FUN|R_DEBUG))
			return
	if(variable in GLOB.VVpixelmovement)
		if(!check_rights(R_DEBUG))
			return
		var/prompt = tgui_alert(src, "Editing this var may irreparably break tile gliding for the rest of the round. THIS CAN'T BE UNDONE", "DANGER", list("ABORT","Continue","ABORT"))
		if (prompt != "Continue")
			return

	default = vv_get_class(variable, var_value)

	if(isnull(default))
		to_chat(src, "Unable to determine variable type.")
	else
		to_chat(src, "Variable appears to be <b>[uppertext(default)]</b>.")

	to_chat(src, "Variable contains: [var_value]")

	if(default == VV_NUM)
		var/dir_text = ""
		if(var_value > 0 && var_value < 16)
			if(var_value & 1)
				dir_text += "NORTH"
			if(var_value & 2)
				dir_text += "SOUTH"
			if(var_value & 4)
				dir_text += "EAST"
			if(var_value & 8)
				dir_text += "WEST"

		if(dir_text)
			to_chat(src, "If a direction, direction is: [dir_text]")

	var/value = vv_get_value(default_class = default)
	var/new_value = value["value"]
	var/class = value["class"]

	if(!class || !new_value == null && class != VV_NULL)
		return

	if (class == VV_MESSAGE)
		class = VV_TEXT

	if (value["type"])
		class = VV_NEW_TYPE

	// RS Add Start: Enhanced mass edit (Lira, February 2026)
	var/scope = tgui_alert(src, "Select mass edit scope.", "Mass Edit Scope", list(VV_MASS_EDIT_SCOPE_SCREEN, VV_MASS_EDIT_SCOPE_Z, VV_MASS_EDIT_SCOPE_GLOBAL, "Cancel"))
	if(!scope || scope == "Cancel")
		return

	var/mob/center_mob = src.mob
	var/z_level = center_mob?.z
	if(scope != VV_MASS_EDIT_SCOPE_GLOBAL)
		if(!center_mob || !z_level)
			to_chat(src, "Unable to determine mob/z context for [scope]. Using Global scope.")
			scope = VV_MASS_EDIT_SCOPE_GLOBAL
		else if(!ispath(O.type, /atom) && !ispath(O.type, /client) && !ispath(O.type, /datum/ai_holder))
			to_chat(src, "[scope] only applies to atoms, clients, and AI holders. Using Global scope for [O.type].")
			scope = VV_MASS_EDIT_SCOPE_GLOBAL
	// RS Add End

	var/original_name = "[O]"

	var/rejected = 0
	var/accepted = 0

	switch(class)
		if(VV_RESTORE_DEFAULT)
			to_chat(src, "Finding items...")
			var/list/items = get_all_of_type(O.type, method, scope, center_mob, z_level) // RS Edit: Enhanced mass edit (Lira, February 2026)
			to_chat(src, "Changing [items.len] items...")
			for(var/thing in items)
				if (!thing)
					continue
				var/datum/D = thing
				if (D.vv_edit_var(variable, initial(D.vars[variable])) != FALSE)
					accepted++
				else
					rejected++
				CHECK_TICK

		if(VV_TEXT)
			var/list/varsvars = vv_parse_text(O, new_value)
			var/pre_processing = new_value
			var/unique
			if (varsvars && varsvars.len)
				unique = tgui_alert(usr, "Process vars unique to each instance, or same for all?", "Variable Association", list("Unique", "Same"))
				if(unique == "Unique")
					unique = TRUE
				else
					unique = FALSE
					for(var/V in varsvars)
						new_value = replacetext(new_value,"\[[V]]","[O.vars[V]]")

			to_chat(src, "Finding items...")
			var/list/items = get_all_of_type(O.type, method, scope, center_mob, z_level) // RS Edit: Enhanced mass edit (Lira, February 2026)
			to_chat(src, "Changing [items.len] items...")
			for(var/thing in items)
				if (!thing)
					continue
				var/datum/D = thing
				if(unique)
					new_value = pre_processing
					for(var/V in varsvars)
						new_value = replacetext(new_value,"\[[V]]","[D.vars[V]]")

				if (D.vv_edit_var(variable, new_value) != FALSE)
					accepted++
				else
					rejected++
				CHECK_TICK

		if (VV_NEW_TYPE)
			var/many = tgui_alert(src, "Create only one [value["type"]] and assign each or a new one for each thing", "How Many", list("One", "Many", "Cancel"))
			if (many == "Cancel")
				return
			if (many == "Many")
				many = TRUE
			else
				many = FALSE

			var/type = value["type"]
			to_chat(src, "Finding items...")
			var/list/items = get_all_of_type(O.type, method, scope, center_mob, z_level) // RS Edit: Enhanced mass edit (Lira, February 2026)
			to_chat(src, "Changing [items.len] items...")
			for(var/thing in items)
				if (!thing)
					continue
				var/datum/D = thing
				if(many && !new_value)
					new_value = new type()

				if (D.vv_edit_var(variable, new_value) != FALSE)
					accepted++
				else
					rejected++
				new_value = null
				CHECK_TICK

		else
			to_chat(src, "Finding items...")
			var/list/items = get_all_of_type(O.type, method, scope, center_mob, z_level) // RS Edit: Enhanced mass edit (Lira, February 2026)
			to_chat(src, "Changing [items.len] items...")
			for(var/thing in items)
				if (!thing)
					continue
				var/datum/D = thing
				if (D.vv_edit_var(variable, new_value) != FALSE)
					accepted++
				else
					rejected++
				CHECK_TICK


	var/count = rejected+accepted
	if (!count)
		to_chat(src, "No objects found")
		return
	if (!accepted)
		to_chat(src, "Every object rejected your edit")
		return
	if (rejected)
		to_chat(src, "[rejected] out of [count] objects rejected your edit")

	// RS Edit Start: Enhanced mass edit (Lira, February 2026)
	log_world("### MassVarEdit by [src]: [O.type] (scope [scope], A/R [accepted]/[rejected]) [variable]=[html_encode("[O.vars[variable]]")]([list2params(value)])")
	log_admin("[key_name(src)] mass modified [original_name]'s [variable] to [O.vars[variable]] ([accepted] objects modified, scope: [scope])")
	message_admins("[key_name_admin(src)] mass modified [original_name]'s [variable] to [O.vars[variable]] ([accepted] objects modified, scope: [scope])")
	// RS Edit End

/proc/get_all_of_type(var/T, subtypes = TRUE, scope = VV_MASS_EDIT_SCOPE_GLOBAL, mob/center_mob = null, z_level = null) // RS Edit: Enhanced mass edit (Lira, February 2026)
	var/list/typecache = list()
	typecache[T] = 1
	if (subtypes)
		typecache = typecacheof(typecache)

	// RS Add Start: Enhanced mass edit (Lira, February 2026)
	var/list/on_screen_atoms
	if(scope == VV_MASS_EDIT_SCOPE_SCREEN && center_mob)
		on_screen_atoms = view(center_mob.client ? center_mob.client.view : world.view, center_mob)
	// RS Add End

	. = list()
	if (ispath(T, /mob))
		for(var/mob/thing in mob_list)
			if (typecache[thing.type] && massedit_matches_scope(thing, scope, z_level, on_screen_atoms)) // RS Edit: Enhanced mass edit (Lira, February 2026)
				. += thing
			CHECK_TICK

	else if (ispath(T, /obj/machinery/door))
		for(var/obj/machinery/door/thing in world)
			if (typecache[thing.type] && massedit_matches_scope(thing, scope, z_level, on_screen_atoms)) // RS Edit: Enhanced mass edit (Lira, February 2026)
				. += thing
			CHECK_TICK

	else if (ispath(T, /obj/machinery))
		for(var/obj/machinery/thing in machines)
			if (typecache[thing.type] && massedit_matches_scope(thing, scope, z_level, on_screen_atoms)) // RS Edit: Enhanced mass edit (Lira, February 2026)
				. += thing
			CHECK_TICK

	else if (ispath(T, /obj))
		for(var/obj/thing in world)
			if (typecache[thing.type] && massedit_matches_scope(thing, scope, z_level, on_screen_atoms)) // RS Edit: Enhanced mass edit (Lira, February 2026)
				. += thing
			CHECK_TICK

	else if (ispath(T, /atom/movable))
		for(var/atom/movable/thing in world)
			if (typecache[thing.type] && massedit_matches_scope(thing, scope, z_level, on_screen_atoms)) // RS Edit: Enhanced mass edit (Lira, February 2026)
				. += thing
			CHECK_TICK

	else if (ispath(T, /turf))
		for(var/turf/thing in world)
			if (typecache[thing.type] && massedit_matches_scope(thing, scope, z_level, on_screen_atoms)) // RS Edit: Enhanced mass edit (Lira, February 2026)
				. += thing
			CHECK_TICK

	else if (ispath(T, /atom))
		for(var/atom/thing in world)
			if (typecache[thing.type] && massedit_matches_scope(thing, scope, z_level, on_screen_atoms)) // RS Edit: Enhanced mass edit (Lira, February 2026)
				. += thing
			CHECK_TICK

	else if (ispath(T, /client))
		for(var/client/thing in GLOB.clients)
			if (typecache[thing.type] && massedit_matches_scope(thing, scope, z_level, on_screen_atoms)) // RS Edit: Enhanced mass edit (Lira, February 2026)
				. += thing
			CHECK_TICK

	else if (ispath(T, /datum))
		for(var/datum/thing)
			if (typecache[thing.type] && massedit_matches_scope(thing, scope, z_level, on_screen_atoms)) // RS Edit: Enhanced mass edit (Lira, February 2026)
				. += thing
			CHECK_TICK

	else
		for(var/datum/thing in world)
			if (typecache[thing.type] && massedit_matches_scope(thing, scope, z_level, on_screen_atoms)) // RS Edit: Enhanced mass edit (Lira, February 2026)
				. += thing
			CHECK_TICK

// RS Add Start: Enhanced mass edit (Lira, February 2026)
/proc/massedit_matches_scope(datum/thing, scope, z_level, list/on_screen_atoms)
	if(scope == VV_MASS_EDIT_SCOPE_GLOBAL)
		return TRUE

	if(istype(thing, /atom))
		var/atom/A = thing
		switch(scope)
			if(VV_MASS_EDIT_SCOPE_Z)
				var/turf/T = get_turf(A)
				return T && T.z == z_level
			if(VV_MASS_EDIT_SCOPE_SCREEN)
				return on_screen_atoms && (A in on_screen_atoms)
		return TRUE

	if(istype(thing, /client))
		var/client/C = thing
		var/mob/M = C.mob
		if(!M)
			return FALSE
		switch(scope)
			if(VV_MASS_EDIT_SCOPE_Z)
				var/turf/T = get_turf(M)
				return T && T.z == z_level
			if(VV_MASS_EDIT_SCOPE_SCREEN)
				return on_screen_atoms && (M in on_screen_atoms)
		return TRUE

	if(istype(thing, /datum/ai_holder))
		var/datum/ai_holder/AI = thing
		var/mob/M = AI.holder
		if(!M)
			return FALSE
		switch(scope)
			if(VV_MASS_EDIT_SCOPE_Z)
				var/turf/T = get_turf(M)
				return T && T.z == z_level
			if(VV_MASS_EDIT_SCOPE_SCREEN)
				return on_screen_atoms && (M in on_screen_atoms)
		return TRUE

	return TRUE

#undef VV_MASS_EDIT_SCOPE_SCREEN
#undef VV_MASS_EDIT_SCOPE_Z
#undef VV_MASS_EDIT_SCOPE_GLOBAL
// RS Add End
