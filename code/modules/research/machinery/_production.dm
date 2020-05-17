/obj/machinery/rnd/production
	name = "technology fabricator"
	desc = "Makes researched and prototype items with materials and energy."
	layer = UNDER_JUNK_LAYER
	flags = OPENCONTAINER
	ui_template = "techfab.tmpl"
	var/consoleless_interface = FALSE		// Whether it can be used without a console.
	var/efficiency_coeff = 1				// Materials needed / coeff = actual.
	var/build_speed = 1						// Multiplier for build speed.
	var/list/categories = list()			// TODO - Leshana - Seems to affect UI somehow?
	var/datum/remote_materials/materials	// Material storage.`
	var/allowed_department_flags = ALL		// Filter for which designs this will build
	var/production_start_animation			// What's flick()'d on production start
	var/production_animation				// Icon state set during production
	var/production_done_animation			// What's flick()'d on production finished
	var/sheet_insertion_state				// Base name for sheet insertion icon states.
	var/allowed_buildtypes = NONE			// Filter for which designs this will build.
	var/list/datum/design/cached_designs	// Local cache of designs this knows how to build.
	var/list/datum/design/matching_designs	// Designs matching last search. Someday move search to be pure UI.
	var/department_tag = "Unidentified"		// Used for material distribution among other things. TODO Leshana - How?
	var/datum/techweb/stored_research		// Local repository of research.
	var/datum/techweb/host_research			// Remote repositoy of research to update from.

	var/list/datum/design/queue = list()	// The build queue!
	var/progress = 0						// Progress towards current build

	// UI STATE
	var/screen = RESEARCH_FABRICATOR_SCREEN_MAIN
	var/selected_category

/obj/machinery/rnd/production/Initialize(mapload)
	. = ..()
	create_reagents(0)
	matching_designs = list()
	cached_designs = list()
	stored_research = new
	host_research = SSresearch.science_tech
	update_research()
	materials = new /datum/remote_materials(src, "lathe", mapload)
	RefreshParts()

/obj/machinery/rnd/production/Destroy()
	QDEL_NULL(materials)
	cached_designs = null
	matching_designs = null
	QDEL_NULL(stored_research)
	host_research = null
	return ..()

/obj/machinery/rnd/production/proc/update_research()
	host_research.copy_research_to(stored_research, TRUE)
	update_designs()

/obj/machinery/rnd/production/proc/update_designs()
	cached_designs.Cut()
	categories.Cut()
	for(var/i in stored_research.researched_designs)
		var/datum/design/d = SSresearch.techweb_design_by_id(i)
		if((isnull(allowed_department_flags) || (d.departmental_flags & allowed_department_flags)) && (d.build_type & allowed_buildtypes))
			cached_designs |= d
			categories |= d.category
	listclearnulls(categories)
	if(!selected_category || !(selected_category in categories))
		selected_category = LAZYACCESS(categories, 1)

/obj/machinery/rnd/production/RefreshParts()
	calculate_efficiency()

/obj/machinery/rnd/production/set_busy()
	if((. = ..()))
		update_icon()

/obj/machinery/rnd/production/reset_busy()
	if((. = ..()))
		update_icon()

/obj/machinery/rnd/production/update_icon()
	if(panel_open)
		icon_state = "[initial(icon_state)]_t"
	else if(busy && production_animation && LAZYLEN(queue))
		icon_state = production_animation
	else
		icon_state = initial(icon_state)

//
// Interaction
//

/obj/machinery/rnd/production/examine(var/mob/user)
	. = ..()
	materials?.OnExamine(src, user, .)

/obj/machinery/rnd/production/Insert_Item(obj/item/I, mob/user)
	if(istype(I, /obj/item/stack/material) && user.a_intent != I_HURT)
		if(!materials.mat_container)
			to_chat(user, "<span class='warning'>No material storage connected!</span>")
		else if(is_insertion_ready(user))
			// forward it on to our actual material container, be it local or the ore silo's
			materials.mat_container.default_user_insert_item(src, user, I, extra_after_insert = CALLBACK(src, .proc/AfterMaterialInsert))
		return TRUE
	return ..()

// Evidently we use power and show animations when stuff is inserted.
/obj/machinery/rnd/production/proc/AfterMaterialInsert(obj/item/stack/material/S, amount_inserted)
	log_debug("AfterMaterialInsert([S], [amount_inserted]) on [src]")
	// Log the deposit with the material storage
	var/matter_per_stack = list(S.material.name = S.perunit)
	materials.silo_log(src, "deposited", amount_inserted, "[S.singular_name]", matter_per_stack)

	// Use power for importing materials
	use_power_oneoff(min(1000, (amount_inserted * 100)))

	// Play the loading animation if any
	if(!sheet_insertion_state)
		return
	var/specific_state = "[sheet_insertion_state]_[S.material.name]"
	if(specific_state in cached_icon_states(icon))
		flick_overlay_view(image(icon, src, specific_state), src, 8)
	else
		var/image/load_overlay = image(icon, src, "[sheet_insertion_state]_loadlights")
		var/image/sheet_anim = image(icon, "[sheet_insertion_state]_loadsheet")
		sheet_anim.color = S.material?.icon_colour
		load_overlay.overlays += sheet_anim
		image(icon, src, specific_state)
		flick_overlay_view(load_overlay, src, 8)

/obj/machinery/rnd/production/OnAttackBy(datum/source, obj/item/O, mob/user)
	if(materials?.OnAttackBy(src, O, user))
		return TRUE
	return ..()

// If configured for ui interaction, call ui_interact
/obj/machinery/rnd/production/attack_hand(mob/user as mob)
	. = ..()
	if(. || !consoleless_interface || !ui_template)
		return
	if(!allowed(user))
		to_chat(user, "<span class='warning'>Access denied.</span>")
		return
	ui_interact(user)

//
// Local NanoUI
//

/obj/machinery/rnd/production/get_ui_data()
	var/list/data = ..()

	var/datum/design/current = queue.len ? queue[1] : null
	if(current)
		data["current"] = current.name
	data["queue"] = get_queue_names()
	data["buildable"] = get_build_options()
	data["category"] =  selected_category // category
	data["categories"] = categories
	data["materials_status"] = materials.get_status_message()
	data["materials_amount"] = materials.format_amount()
	data["materials"] = get_materials()
	data["maxres"] =  materials.mat_container?.max_amount == INFINITY ? -1 : materials.mat_container?.max_amount
	data["chemicals"] = get_chemicals()
	data["totalchems"] = reagents?.total_volume
	data["maxchems"] = reagents?.maximum_volume
	if(current)
		data["builtperc"] = round((progress / current.time) * 100)

	return data;

/obj/machinery/rnd/production/proc/get_queue_names()
	. = list()
	for(var/i = 2 to queue.len)
		var/datum/design/D = queue[i]
		. += D.name

/obj/machinery/rnd/production/proc/get_build_options()
	. = list()
	for(var/id in stored_research.researched_designs)
		var/datum/design/D = SSresearch.techweb_design_by_id(id)
		if(!D.build_path)
			continue
		if(!(D.build_type & allowed_buildtypes) || !(isnull(allowed_department_flags) ||(D.departmental_flags & allowed_department_flags)))
			continue
		. += list(list("name" = D.name, "id" = D.id, "category" = D.category, "max" = max_build_qty(D), "resourses" = get_design_resourses(D), "time" = get_design_time(D)))

/// How many of this design can we print given current resources?
/obj/machinery/rnd/production/proc/max_build_qty(var/datum/design/D)
	if (!materials.mat_container)  // no connected silo
		return 0
	var/list/all_materials = D.chemicals + D.materials
	var/ef = efficient_with(D.build_path) ? efficiency_coeff : 1

	. = 50
	for(var/mat in all_materials)
		var/have = materials.mat_container.get_material_amount(mat) || reagents.get_reagent_amount(mat)
		. = min(., round(have / max(1, all_materials[mat] / ef)))

/obj/machinery/rnd/production/proc/get_design_resourses(var/datum/design/D)
	var/list/F = list()
	// TODO - The rdconsole has a fancy version that colors the missing ones red etc
	var/mat_efficiency = efficient_with(D.build_path) ? 1/efficiency_coeff : 1  // TODO switch to using normal instead of inverse
	for(var/T in D.materials)
		F += "[material_display_name(T)]: [D.materials[T] * mat_efficiency]"
	return english_list(F, and_text = ", ")

/obj/machinery/rnd/production/proc/get_design_time(var/datum/design/D)
	return time2text(round(10 * D.time / build_speed), "mm:ss")

/obj/machinery/rnd/production/proc/get_materials()
	return materials.mat_container?.materials_ui_data()

/obj/machinery/rnd/production/proc/get_chemicals()
	. = list()
	for(var/datum/reagent/R in reagents?.reagent_list)
		. += list(list("id" = R.id, "name" = capitalize(R.name), "amt" = R.volume))

//
// Stuff
//

/obj/machinery/rnd/production/proc/calculate_efficiency()
	efficiency_coeff = 1
	if(reagents) //If reagents/materials aren't initialized, don't bother, we'll be doing this again after reagents init anyways.
		reagents.maximum_volume = 0
		for(var/obj/item/weapon/reagent_containers/glass/G in component_parts)
			reagents.maximum_volume += G.volume
			G.reagents.trans_to(src, G.reagents.total_volume)
	if(materials)
		var/total_storage = 0
		for(var/obj/item/weapon/stock_parts/matter_bin/M in component_parts)
			total_storage += M.rating * 75000
		materials.set_local_size(total_storage)
	var/total_rating = 0
	for(var/obj/item/weapon/stock_parts/manipulator/M in component_parts)
		total_rating += M.rating
	efficiency_coeff = 1/max(1 - (total_rating - 2) / 8, 0.2)
	build_speed = total_rating / 2

//we eject the materials upon deconstruction.
/obj/machinery/rnd/production/dismantle()
	for(var/obj/item/weapon/reagent_containers/glass/G in component_parts)
		reagents.trans_to(G, G.reagents.maximum_volume)
	return ..()

//
// Production
//

/obj/machinery/rnd/production/proc/addToQueue(datum/design/D)
	queue += D
	START_MACHINE_PROCESSING(src)
	return

/obj/machinery/rnd/production/proc/removeFromQueue(var/index)
	queue.Cut(index, index + 1)
	return

/// Check that we still have enough materials when popping something off the queue
/obj/machinery/rnd/production/proc/canBuild(datum/design/D, amount = 1, say_errors = TRUE)
	if(inoperable())
		return FALSE // Broken or no power, oops!
	if(!materials.mat_container)
		if(say_errors)
			buzz("No connection to material storage, please contact the quartermaster.")
		return FALSE
	if(materials.on_hold())
		if(say_errors)
			buzz("Mineral access is on hold, please contact the quartermaster.")
		return FALSE
	var/coeff = efficient_with(D.build_path) ? efficiency_coeff : 1
	if(!materials.mat_container.can_use_materials(D.materials, amount / coeff))
		if(say_errors)
			buzz("Not enough materials to complete prototype[amount > 1? "s" : ""].")
		return FALSE
	for(var/R in D.chemicals)
		if(!reagents.has_reagent(R, D.chemicals[R] * amount / coeff))
			if(say_errors)
				buzz("Not enough reagents to complete prototype[amount > 1? "s" : ""].")
			return FALSE
	return TRUE

/obj/machinery/rnd/production/process(wait)
	if(LAZYLEN(queue) == 0)
		update_use_power(USE_POWER_IDLE)
		reset_busy()
		return PROCESS_KILL

	var/datum/design/D = queue[1]
	if(canBuild(D, say_errors = busy))
		set_busy()
		update_use_power(USE_POWER_ACTIVE)
		progress += build_speed * wait * (1/10) // Normalized to seconds even if fastprocess
		if(progress >= D.time)
			finish_queued_build(D)
			progress = 0
			removeFromQueue(1)
			if(linked_console)
				linked_console.updateUsrDialog()
			if(!LAZYLEN(queue) && success_sound)
				playsound(src, success_sound, 50, 0)
		update_icon()
	else
		reset_busy()

// Actually finish a queued build - Use power, materials, and spawn the items - Call ONLY from process()
/obj/machinery/rnd/production/proc/finish_queued_build(datum/design/D, amount = 1)
	var/coeff = efficient_with(D.build_path) ? efficiency_coeff : 1

	var/power = active_power_usage
	for(var/M in D.materials)
		power += round(D.materials[M] * amount / (5 * coeff))
	use_power(power)

	// Use the materials
	var/list/efficient_mats = list()
	for(var/M in D.materials)
		efficient_mats[M] = D.materials[M] / coeff
	materials.mat_container.use_materials(efficient_mats, amount)
	materials.silo_log(src, "built", -amount, "[D.name]", efficient_mats)
	for(var/R in D.chemicals)
		reagents.remove_reagent(R, D.chemicals[R]*amount/coeff)

	if(D.dangerous_construction)
		investigate_log("[key_name(usr)] built [amount] of [D] at [src]([type]).", INVESTIGATE_RESEARCH)
		message_admins("[ADMIN_LOOKUPFLW(usr)] has built [amount] of [D] at \a [src]([type]).")

	if(production_done_animation)
		flick(production_done_animation, src)

	for(var/i in 1 to amount)
		var/obj/item/I = D.Fabricate(drop_location(), src)
		if(I && LAZYLEN(I.matter) > 0) // No matter out of nowhere
			I.matter = efficient_mats.Copy()
		if(istype(I) && isturf(I.loc))
			I.randpixel_xy() // Shift them around a bit so their visible.
	
	return TRUE

/obj/machinery/rnd/production/drop_location()
	// Try to drop items one step in front of us, if its open.
	. = get_step(get_turf(src), src.dir)
	if(!isfloor(.))
		. = ..() // Oh well, we tried.

/obj/machinery/rnd/production/proc/check_mat(datum/design/being_built, var/mat)	// now returns how many times the item can be built with the material
	if (!materials.mat_container)  // no connected silo
		return 0
	var/list/all_materials = being_built.chemicals + being_built.materials

	var/A = materials.mat_container.get_material_amount(mat)
	if(!A)
		A = reagents.get_reagent_amount(mat)

	// these types don't have their .matter set in do_print, so don't allow
	// them to be constructed efficiently
	var/ef = efficient_with(being_built.build_path) ? efficiency_coeff : 1
	return round(A / max(1, all_materials[mat] / ef))

/obj/machinery/rnd/production/proc/efficient_with(path)
	return !ispath(path, /obj/item/stack/material) && !ispath(path, /obj/item/weapon/ore/bluespace_crystal)

/obj/machinery/rnd/production/proc/user_try_print_id(id, amount = 1)
	if((!istype(linked_console) && requires_console) || !id)
		return FALSE
	if(istext(amount))
		amount = text2num(amount)
	amount = clamp(amount, 1, 50)
	var/datum/design/D = (linked_console) ? (linked_console.stored_research.researched_designs[id]? SSresearch.techweb_design_by_id(id) : null) : SSresearch.techweb_design_by_id(id)
	if(!istype(D))
		return FALSE
	if(!(isnull(allowed_department_flags) || (D.departmental_flags & allowed_department_flags)))
		state("Warning: Printing failed: This fabricator does not have the necessary keys to decrypt design schematics. Please update the research data with the on-screen button and contact Nanotrasen Support!")
		return FALSE
	if(D.build_type && !(D.build_type & allowed_buildtypes))
		state("This machine does not have the necessary manipulation systems for this design. Please contact Nanotrasen Support!")
		return FALSE
	if(!canBuild(D, amount))
		return FALSE
	for(var/i = 1 to amount)
		addToQueue(D)
	return TRUE

// /obj/machinery/rnd/production/proc/search(string)
// 	matching_designs.Cut()
// 	for(var/v in stored_research.researched_designs)
// 		var/datum/design/D = SSresearch.techweb_design_by_id(v)
// 		if(!(D.build_type & allowed_buildtypes) || !(isnull(allowed_department_flags) ||(D.departmental_flags & allowed_department_flags)))
// 			continue
// 		if(findtext(D.name,string))
// 			matching_designs.Add(D)

// /obj/machinery/rnd/production/proc/generate_ui()
// 	var/list/ui = list()
// 	ui += ui_header()
// 	switch(screen)
// 		if(RESEARCH_FABRICATOR_SCREEN_MATERIALS)
// 			ui += ui_screen_materials()
// 		if(RESEARCH_FABRICATOR_SCREEN_CHEMICALS)
// 			ui += ui_screen_chemicals()
// 		if(RESEARCH_FABRICATOR_SCREEN_SEARCH)
// 			ui += ui_screen_search()
// 		if(RESEARCH_FABRICATOR_SCREEN_CATEGORYVIEW)
// 			ui += ui_screen_category_view()
// 		if(RESEARCH_FABRICATOR_SCREEN_QUEUE)
// 			ui += ui_screen_queue()
// 		else
// 			ui += ui_screen_main()
// 	for(var/i in 1 to length(ui))
// 		if(!findtextEx(ui[i], RDSCREEN_NOBREAK))
// 			ui[i] += "<br>"
// 		ui[i] = replacetextEx(ui[i], RDSCREEN_NOBREAK, "")
// 	return ui.Join("")

// /obj/machinery/rnd/production/proc/ui_header()
// 	var/list/l = list()
// 	l += "<div class='statusDisplay'><b>[host_research.organization] [department_tag] Department Lathe</b>"
// 	l += "Security protocols: [emagged ? "<font color='red'>Disabled</font>" : "<font color='green'>Enabled</font>"]"
// 	if (materials.mat_container)
// 		l += "<A href='?src=[REF(src)];switch_screen=[RESEARCH_FABRICATOR_SCREEN_MATERIALS]'><B>Material Amount:</B> [materials.format_amount()]</A>"
// 	else
// 		l += "<font color='red'>No material storage connected, please contact the quartermaster.</font>"
// 	l += "<A href='?src=[REF(src)];switch_screen=[RESEARCH_FABRICATOR_SCREEN_CHEMICALS]'><B>Chemical volume:</B> [reagents.total_volume] / [reagents.maximum_volume]</A>"
// 	l += "<a href='?src=[REF(src)];switch_screen=[RESEARCH_FABRICATOR_SCREEN_QUEUE]'>View Queue ([LAZYLEN(queue)])</a>"
// 	l += "<a href='?src=[REF(src)];sync_research=1'>Synchronize Research</a>"
// 	l += "<a href='?src=[REF(src)];switch_screen=[RESEARCH_FABRICATOR_SCREEN_MAIN]'>Main Screen</a></div>[RDSCREEN_NOBREAK]"
// 	return l

// /obj/machinery/rnd/production/proc/ui_screen_materials()
// 	if (!materials.mat_container)
// 		screen = RESEARCH_FABRICATOR_SCREEN_MAIN
// 		return ui_screen_main()
// 	var/list/l = list()
// 	l += "<div class='statusDisplay'><h3>Material Storage:</h3>"
// 	for(var/mat_id in materials.mat_container.materials)
// 		var/material/M = get_material_ref(mat_id)
// 		var/amount = materials.mat_container.materials[mat_id]
// 		var/ref = REF(M)
// 		l += "* [amount] of [M.name]: "
// 		if(amount >= SHEET_MATERIAL_AMOUNT) l += "<A href='?src=[REF(src)];ejectsheet=[ref];eject_amt=1'>Eject</A> [RDSCREEN_NOBREAK]"
// 		if(amount >= SHEET_MATERIAL_AMOUNT*5) l += "<A href='?src=[REF(src)];ejectsheet=[ref];eject_amt=5'>5x</A> [RDSCREEN_NOBREAK]"
// 		if(amount >= SHEET_MATERIAL_AMOUNT) l += "<A href='?src=[REF(src)];ejectsheet=[ref];eject_amt=50'>All</A>[RDSCREEN_NOBREAK]"
// 		l += ""
// 	l += "</div>[RDSCREEN_NOBREAK]"
// 	return l

// /obj/machinery/rnd/production/proc/ui_screen_chemicals()
// 	var/list/l = list()
// 	l += "<div class='statusDisplay'><A href='?src=[REF(src)];disposeall=1'>Disposal All Chemicals in Storage</A>"
// 	l += "<h3>Chemical Storage:</h3>"
// 	for(var/datum/reagent/R in reagents.reagent_list)
// 		l += "[R.name]: [R.volume]"
// 		l += "<A href='?src=[REF(src)];dispose=[R.type]'>Purge</A>"
// 	l += "</div>"
// 	return l


// /obj/machinery/rnd/production/proc/ui_screen_queue()
// 	var/list/l = list()
// 	l += "<div class='statusDisplay'><h3>Construction Queue:</h3>"
// 	if(!LAZYLEN(queue))
// 		l += "Empty"
// 	else
// 		var/index = 1
// 		for(var/datum/design/D in queue)
// 			if(index == 1)
// 				if(busy)
// 					l += "<B>1: [D.name]</B>"
// 				else
// 					l += "<B>1: [D.name]</B> (Awaiting materials) <A href='?src=[REF(src)];remove=[index]'>(Remove)</A>"
// 			else
// 				l += "[index]: [D.name] <A href='?src=[REF(src)];remove=[index]'>(Remove)</A>"
// 			++index
// 	l += "</div>[RDSCREEN_NOBREAK]"
// 	return l

// /obj/machinery/rnd/production/proc/ui_screen_search()
// 	var/list/l = list()
// 	var/coeff = efficiency_coeff
// 	l += "<h2>Search Results:</h2>"
// 	l += "<form name='search' action='?src=[REF(src)]'>\
// 	<input type='hidden' name='src' value='[REF(src)]'>\
// 	<input type='hidden' name='search' value='to_search'>\
// 	<input type='text' name='to_search'>\
// 	<input type='submit' value='Search'>\
// 	</form><HR>"
// 	for(var/datum/design/D in matching_designs)
// 		l += design_menu_entry(D, coeff)
// 	l += "</div>"
// 	return l

// /obj/machinery/rnd/production/proc/design_menu_entry(datum/design/D, coeff)
// 	if(!istype(D))
// 		return
// 	if(!coeff)
// 		coeff = efficiency_coeff
// 	if(!efficient_with(D.build_path))
// 		coeff = 1
// 	var/list/l = list()
// 	var/temp_material
// 	var/c = 50
// 	var/t
// 	var/all_materials = D.materials + D.chemicals
// 	for(var/M in all_materials)
// 		t = check_mat(D, M)
// 		temp_material += " | "
// 		if (t < 1)
// 			temp_material += "<span class='bad'>[all_materials[M]/coeff] [CallMaterialName(M)]</span>"
// 		else
// 			temp_material += " [all_materials[M]/coeff] [CallMaterialName(M)]"
// 		c = min(c,t)

// 	if (c >= 1)
// 		l += "<A href='?src=[REF(src)];build=[D.id];amount=1'>[D.name]</A>[RDSCREEN_NOBREAK]"
// 		if(c >= 5)
// 			l += "<A href='?src=[REF(src)];build=[D.id];amount=5'>x5</A>[RDSCREEN_NOBREAK]"
// 		if(c >= 10)
// 			l += "<A href='?src=[REF(src)];build=[D.id];amount=10'>x10</A>[RDSCREEN_NOBREAK]"
// 		l += "[temp_material][RDSCREEN_NOBREAK]"
// 	else
// 		l += "<span class='linkOff'>[D.name]</span>[temp_material][RDSCREEN_NOBREAK]"
// 	l += ""
// 	return l

/obj/machinery/rnd/production/Topic(raw, ls)
	if(..())
		return
	add_fingerprint(usr)
	usr.set_machine(src)
	if(ls["switch_screen"])
		screen = text2num(ls["switch_screen"])
	if(ls["build"]) //Causes the Protolathe to build something.
		if(busy)
			state("Warning: Fabricators busy!")
		else
			user_try_print_id(ls["build"], ls["amount"])
	if(ls["search"]) //Search for designs with name matching pattern
		search(ls["to_search"])
		screen = RESEARCH_FABRICATOR_SCREEN_SEARCH
	if(ls["sync_research"])
		update_research()
		state("Synchronizing research with host technology database.")
	if(ls["category"])
		selected_category = ls["category"]
	if(ls["dispose"])  //Causes the protolathe to dispose of a single reagent (all of it)
		reagents.del_reagent(ls["dispose"])
	if(ls["disposeall"]) //Causes the protolathe to dispose of all it's reagents.
		reagents.clear_reagents()
	if(ls["remove"]) // Causes protolathe to remove a queued item
		removeFromQueue(text2num(ls["remove"]))
	if(ls["ejectsheet"]) //Causes the protolathe to eject a sheet of material
		var/material/M = locate(ls["ejectsheet"])
		eject_sheets(M, ls["amount"])
	updateUsrDialog()

/obj/machinery/rnd/production/proc/eject_sheets(eject_sheet, eject_amt)
	var/datum/material_container/mat_container = materials.mat_container
	if (!mat_container)
		state("No access to material storage, please contact the quartermaster.")
		return 0
	if (materials.on_hold())
		state("Mineral access is on hold, please contact the quartermaster.")
		return 0
	var/count = mat_container.retrieve_sheets(text2num(eject_amt), eject_sheet, drop_location())
	var/list/matlist = list()
	matlist[eject_sheet] = SHEET_MATERIAL_AMOUNT
	materials.silo_log(src, "ejected", -count, "sheets", matlist)
	return count

// /obj/machinery/rnd/production/proc/ui_screen_main()
// 	var/list/l = list()
// 	l += "<form name='search' action='?src=[REF(src)]'>\
// 	<input type='hidden' name='src' value='[REF(src)]'>\
// 	<input type='hidden' name='search' value='to_search'>\
// 	<input type='hidden' name='type' value='proto'>\
// 	<input type='text' name='to_search'>\
// 	<input type='submit' value='Search'>\
// 	</form><HR>"

// 	l += list_categories(categories, RESEARCH_FABRICATOR_SCREEN_CATEGORYVIEW)

// 	return l

// /obj/machinery/rnd/production/proc/ui_screen_category_view()
// 	if(!selected_category)
// 		return ui_screen_main()
// 	var/list/l = list()
// 	l += "<div class='statusDisplay'><h3>Browsing [selected_category]:</h3>"
// 	var/coeff = efficiency_coeff
// 	for(var/v in stored_research.researched_designs)
// 		var/datum/design/D = SSresearch.techweb_design_by_id(v)
// 		if(!(selected_category == D.category || (selected_category in D.category)) || !(D.build_type & allowed_buildtypes))
// 			continue
// 		if(!(isnull(allowed_department_flags) || (D.departmental_flags & allowed_department_flags)))
// 			continue
// 		l += design_menu_entry(D, coeff)
// 	l += "</div>"
// 	return l

// /obj/machinery/rnd/production/proc/list_categories(list/categories, menu_num)
// 	if(!categories)
// 		return

// 	var/line_length = 1
// 	var/list/l = "<table style='width:100%' align='center'><tr>"

// 	for(var/C in categories)
// 		if(line_length > 2)
// 			l += "</tr><tr>"
// 			line_length = 1

// 		l += "<td><A href='?src=[REF(src)];category=[C];switch_screen=[menu_num]'>[C]</A></td>"
// 		line_length++

// 	l += "</tr></table></div>"
// 	return l
