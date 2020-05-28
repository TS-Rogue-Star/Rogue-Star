#define QUEUE_DESIGN 1	// Index in queue entry list for the design to build.
#define QUEUE_QTY 2		// Index in queue entry list for quantity to build.

/obj/machinery/autolathe
	name = "autolathe"
	desc = "It produces items using metal and glass."
	icon_state = "autolathe"
	density = 1
	anchored = 1
	use_power = USE_POWER_IDLE
	idle_power_usage = 10
	active_power_usage = 2000
	clicksound = "keyboard"
	clickvol = 30

	circuit = /obj/item/weapon/circuitboard/autolathe
	var/list/stored_material =  list(DEFAULT_WALL_MATERIAL = 0, MAT_GLASS = 0)
	var/list/storage_capacity = list(DEFAULT_WALL_MATERIAL = 0, MAT_GLASS = 0)
	
	var/datum/techweb/stored_research		// Local repository of research.
	var/list/datum/design/cached_designs	// Local cache of designs this machine knows how to build.

	var/list/categories = list()			// Cached list of distinct categories from cached_designs
	var/current_category = null				// Currently selected category for UI filtering.

	var/progress = 0						// Progress towards current build
	var/list/queue = list()					// The build queue! List of list(design_to_build, qty_to_build)
	var/build_status = BUILD_IDLE			// Current state of build queue processing.

	var/sound/success_sound = 'sound/machines/ping.ogg'			// Plays when queue finished
	var/sound/error_sound = 'sound/machines/buzz-sigh.ogg'		// Plays to alert about an error.

	var/hacked = 0
	var/disabled = 0
	var/shocked = 0

	var/mat_efficiency = 1
	var/build_speed = 10

	var/datum/wires/autolathe/wires = null
	var/ui_template = "autolathe.tmpl"

	var/filtertext

/obj/machinery/autolathe/Initialize()
	. = ..()
	wires = new(src)
	stored_research = new /datum/techweb/specialized/autounlocking/autolathe
	default_apply_parts()
	RefreshParts()
	update_designs()

/obj/machinery/autolathe/Destroy()
	qdel(wires)
	wires = null
	return ..()

// Update the recipie list from stored research!
/obj/machinery/autolathe/proc/update_designs()
	cached_designs.Cut()
	categories.Cut()
	for(var/id in stored_research.researched_designs)
		var/datum/design/D = SSresearch.techweb_design_by_id(id)
		if(D.build_type & AUTOLATHE && (!D.contraband || hacked))
			cached_designs |= D
			categories |= D.category
	listclearnulls(categories)
	if(!current_category || !(current_category in categories))
		current_category = LAZYACCESS(categories, 1)

// Return data for NanoUI interface, called by ui_interact
/obj/machinery/autolathe/proc/get_ui_data()
	var/list/data = list()

	data["build_status"] = build_status
	var/list/current = queue.len ? queue[1] : null
	if(current)
		var/datum/design/current_design = current[QUEUE_DESIGN]
		data["current"] = list(
			"name" = current_design.name,
			"builtperc" = round((progress / current_design.time) * 100),
			"qty" = current[QUEUE_QTY])
	data["queue"] = get_ui_data_queue()
	data["buildable"] = get_ui_data_build_options()
	data["category"] =  current_category
	data["categories"] = categories
	data["materials"] = get_ui_data_materials()

	return data;

/obj/machinery/autolathe/proc/get_ui_data_queue()
	var/list/queue_data = list()
	var/temp_metal = stored_material[DEFAULT_WALL_MATERIAL]
	var/temp_glass = stored_material[MAT_GLASS]
	for(var/i in queue)
		var/datum/design/D = queue[i][QUEUE_DESIGN]
		var/qty = queue[i][QUEUE_QTY]
		var/mat_multiplier = qty * (MATERIAL_EFFICIENT(D.build_path) ? mat_efficiency : 1)
		temp_metal -= max(0, D.materials[DEFAULT_WALL_MATERIAL] * mat_multiplier)
		temp_glass -= max(0, D.materials[MAT_GLASS] * mat_multiplier)
		var/can_build = temp_metal >= 0 && temp_glass >= 0
		queue_data[++queue_data.len] = list("name" = D.name, "qty" = qty, "can_build" = can_build)
	return queue_data

/obj/machinery/autolathe/proc/get_ui_data_materials()
	var/list/materials_ui = list()
	for(var/mat in stored_material)
		var/amount = stored_material[mat]
		materials_ui[++materials_ui.len] = list(
				"id" = mat,
				"name" = material_display_name(mat),
				"amt" = amount,
				"max" = storage_capacity[mat]
		)
	return materials_ui

/obj/machinery/autolathe/proc/get_ui_data_build_options()
	var/list/L = list()
	for(var/datum/design/D in cached_designs)
		if(current_category && current_category != D.category)
			continue
		if(filtertext && findtext(D.name, filtertext) == 0)
			continue
		var/mat_multiplier = (MATERIAL_EFFICIENT(D.build_path) ? mat_efficiency : 1)

		// We combined calcualting max build qty and resources list into a single pass		

		var/max_build_qty = 10 // Default max quantity
		if(ispath(D.build_type, /obj/item/stack))
			var/obj/item/stack/stack_type = D.build_type
			max_build_qty = initial(stack_type.max_amount)
		var/list/resources = list()
		for(var/mat in D.materials)
			var/have = stored_material[mat] || 0
			var/required = max(1, D.materials[mat] * mat_multiplier)
			max_build_qty = min(max_build_qty, round(have / required))
			resources[++resources.len] = list("name" = material_display_name(mat), "amt" = required, "missing" = (have < required))
		L[++L.len] = list("name" = D.name, "id" = D.id, "category" = D.category, "max" = max_build_qty, "resources" = resources)
	return L

/obj/machinery/autolathe/ui_interact(var/mob/user, var/ui_key = "main", var/datum/nanoui/ui = null, var/force_open = 1, var/datum/topic_state/state = default_state)
	var/list/data = get_ui_data()

	var/datum/asset/iconsheet/research_designs/design_icons = get_asset_datum(/datum/asset/iconsheet/research_designs)
	design_icons.send(user)

	ui = SSnanoui.try_update_ui(user, src, ui_key, ui, data, force_open)
	if(!ui)
		ui = new(user, src, ui_key, ui_template, "[capitalize(name)] UI", 800, 600)
		ui.add_template("designBuildOptions", "design_build_options.tmpl")
		ui.add_stylesheet("../../iconsheet_[design_icons.name].css")
		ui.set_initial_data(data)
		ui.open()
		ui.set_auto_update(1)


/obj/machinery/autolathe/attackby(var/obj/item/O as obj, var/mob/user as mob)
	if(busy())
		to_chat(user, "<span class='notice'>\The [src] is busy. Please wait for completion of previous operation.</span>")
		return

	if(shocked && !(O.flags & NOCONDUCT) && shock(user, 50))
		return
	if(default_deconstruction_screwdriver(user, O))
		return
	if(default_deconstruction_crowbar(user, O))
		return
	if(default_part_replacement(user, O))
		return

	if(stat)
		return

	if(panel_open)
		//Don't eat multitools or wirecutters used on an open lathe.
		if(O.is_multitool() || O.is_wirecutter())
			wires.Interact(user)
			return

	if(O.loc != user && !(istype(O,/obj/item/stack)))
		return 0

	if(is_robot_module(O))
		return 0

	if(istype(O,/obj/item/ammo_magazine/clip) || istype(O,/obj/item/ammo_magazine/s357) || istype(O,/obj/item/ammo_magazine/s38) || istype (O,/obj/item/ammo_magazine/s44)/* VOREstation Edit*/) // Prevents ammo recycling exploit with speedloaders.
		to_chat(user, "\The [O] is too hazardous to recycle with the autolathe!")
		return
		/*  ToDo: Make this actually check for ammo and change the value of the magazine if it's empty. -Spades
		var/obj/item/ammo_magazine/speedloader = O
		if(speedloader.stored_ammo)
			to_chat(user, "\The [speedloader] is too hazardous to put back into the autolathe while there's ammunition inside of it!")
			return
		else
			speedloader.matter = list(DEFAULT_WALL_MATERIAL = 75) // It's just a hunk of scrap metal now.
	if(istype(O,/obj/item/ammo_magazine)) // This was just for immersion consistency with above.
		var/obj/item/ammo_magazine/mag = O
		if(mag.stored_ammo)
			to_chat(user, "\The [mag] is too hazardous to put back into the autolathe while there's ammunition inside of it!")
			return*/

	// Unlike most machines, autolathes DO break down material sheets into their component submaterials.
	// For example if you put in a sheet of reinforced glass, it will take the steel and glass, not attempt to take rglass.

	//Resources are being loaded.
	var/obj/item/eating = O
	if(!eating.matter)
		to_chat(user, "\The [eating] does not contain significant amounts of useful materials and cannot be accepted.")
		return

	var/filltype = 0       // Used to determine message.
	var/total_used = 0     // Amount of material used.
	var/mass_per_sheet = 0 // Amount of material constituting one sheet.

	for(var/material in eating.matter)

		if(isnull(stored_material[material]) || isnull(storage_capacity[material]))
			continue

		if(stored_material[material] >= storage_capacity[material])
			continue

		var/total_material = eating.matter[material]

		//If it's a stack, we eat multiple sheets.
		if(istype(eating,/obj/item/stack))
			var/obj/item/stack/stack = eating
			total_material *= stack.get_amount()

		if(stored_material[material] + total_material > storage_capacity[material])
			total_material = storage_capacity[material] - stored_material[material]
			filltype = 1
		else
			filltype = 2

		stored_material[material] += total_material
		total_used += total_material
		mass_per_sheet += eating.matter[material]

	if(!filltype)
		to_chat(user, "<span class='notice'>\The [src] is full. Please remove material from the autolathe in order to insert more.</span>")
		return
	else if(filltype == 1)
		to_chat(user, "You fill \the [src] to capacity with \the [eating].")
	else
		to_chat(user, "You fill \the [src] with \the [eating].")

	flick("initial(icon_state)_loading", src) // Plays metal insertion animation. Work out a good way to work out a fitting animation. ~Z

	if(istype(eating,/obj/item/stack))
		var/obj/item/stack/stack = eating
		stack.use(max(1, round(total_used/mass_per_sheet))) // Always use at least 1 to prevent infinite materials.
	else
		user.remove_from_mob(O)
		qdel(O)

	return

/obj/machinery/autolathe/attack_hand(mob/user as mob)
	if(..())
		return 1
	else if(disabled && !panel_open)
		to_chat(user, "<span class='danger'>\The [src] is disabled!</span>")
		return 1
	if(shocked)
		shock(user, 50)
	
	user.set_machine(src)	
	ui_interact(user)

/obj/machinery/autolathe/Topic(href, href_list)
	if(..())
		return

	usr.set_machine(src)
	add_fingerprint(usr)

	if(busy())
		to_chat(usr, "<span class='notice'>The autolathe is busy. Please wait for completion of previous operation.</span>")
		return

	if(!isnull(href_list["search"]))
		var/filterstring = href_list["search"]
		if(!filterstring || length(filterstring) <= 0)
			filterstring = null
		else
			filtertext = sanitize(filterstring, 25)

	if(!isnull(href_list["category"]))
		current_category = href_list["category"]

	if(href_list["build"])
		user_try_print_id(href_list["build"], text2num(href_list["amount"]))

/obj/machinery/autolathe/update_icon()
	if(panel_open)
		add_overlay("[initial(icon_state)]_panel")
	else
		cut_overlay("[initial(icon_state)]_panel")

	if(stat & NOPOWER)
		icon_state = initial(icon_state)
		return
	switch(build_status)
		if(BUILD_WORKING)
			icon_state = "[initial(icon_state)]_work"
		if(BUILD_ERROR, BUILD_PAUSED)
			icon_state = "[initial(icon_state)]_pause"
		else
			icon_state = initial(icon_state)

/obj/machinery/autolathe/proc/update_build_status(var/new_build_status)
	if(new_build_status == build_status)
		return FALSE
	build_status = new_build_status
	update_icon()
	return TRUE

/// Check if autolathe is too busy to do things like load material or refresh parts
/obj/machinery/autolathe/proc/busy()
	return (build_status == BUILD_WORKING)

/obj/machinery/autolathe/proc/user_try_print_id(id, multiplier = 1)
	var/datum/design/D = stored_research.isDesignResearchedID(id)
	if(!istype(D))
		log_debug("[usr] invoked [src].user_try_print_id() with un-researched design id [id]")
		return
	if(D.build_type && !(D.build_type & AUTOLATHE))
		state("This machine does not have the necessary manipulation systems for this design. Please contact Nanotrasen Support!")
		return FALSE
	multiplier = clamp(multiplier, 1, 50) // Sanity check
	add_to_queue(D, multiplier)
	return TRUE

/obj/machinery/autolathe/proc/add_to_queue(datum/design/D, qty = 1)
	queue[++queue.len] = list(D, qty)
	if(build_status == BUILD_IDLE)
		update_build_status(BUILD_WORKING)
	START_MACHINE_PROCESSING(src)
	return

/obj/machinery/autolathe/proc/remove_from_queue(var/index)
	queue.Cut(index, index + 1)
	return
	
//
// Process build queue
//

/obj/machinery/autolathe/process(wait)
	if(LAZYLEN(queue) == 0)
		update_use_power(USE_POWER_IDLE)
		update_build_status(BUILD_IDLE)
		return PROCESS_KILL

	var/datum/design/D = queue[1][QUEUE_DESIGN]
	if(can_build(D, queue[1][QUEUE_QTY], say_errors = (build_status != BUILD_ERROR)))
		update_use_power(USE_POWER_ACTIVE)
		update_build_status(BUILD_WORKING)
		progress += build_speed * wait * (1/10) // Normalized to seconds even if fastprocess
		if(progress >= D.time)
			finish_queued_build(D, queue[1][QUEUE_QTY])
			remove_from_queue(1)
			progress = 0
			if(!LAZYLEN(queue) && success_sound)
				playsound(src, success_sound, 50, 0)
	else
		update_build_status(BUILD_ERROR)
		progress = 0

/// Check that we still have enough materials when popping something off the queue
/obj/machinery/autolathe/proc/can_build(datum/design/D, qty = 1, say_errors = TRUE)
	if(inoperable() || disabled)
		return FALSE // Broken or no power, oops!
	var/mat_multiplier = (MATERIAL_EFFICIENT(D.build_path) ? mat_efficiency : 1)
	for(var/mat in D.materials)
		if(stored_material[mat] < round(D.materials[mat] * mat_multiplier) * qty)
			if(say_errors)
				audible_message("[bicon(src)] <span class='warning'>Not enough materials to complete construction.</span>")
				if(error_sound)
					playsound(src, 'sound/machines/buzz-sigh.ogg', 50, 0)
			return FALSE
	return TRUE

/// Actually finish a queued build - Use materials and spawn the items - Call ONLY from process()
/obj/machinery/autolathe/proc/finish_queued_build(datum/design/D, qty = 1)
	ASSERT(qty > 0)
	//Consume materials.
	var/mat_multiplier = (MATERIAL_EFFICIENT(D.build_path) ? mat_efficiency : 1)
	var/list/efficient_mats = list()
	for(var/mat in D.materials)
		if(!isnull(stored_material[mat]))
			efficient_mats[mat] = round(D.materials[mat] * mat_multiplier)
			stored_material[mat] = max(0, stored_material[mat] - efficient_mats[mat] * qty)

	if(D.dangerous_construction)
		investigate_log("[key_name(usr)] built [qty] of [D] at [src]([type]).", INVESTIGATE_RESEARCH)
		message_admins("[ADMIN_LOOKUPFLW(usr)] has built [qty] of [D] at \a [src]([type]).")

	flick("[initial(icon_state)]_finish", src)

	//Create the desired item.
	for(var/i in 1 to qty)
		var/obj/item/I = D.Fabricate(drop_location(), src)
		if(I && LAZYLEN(I.matter) > 0) // No matter out of nowhere
			I.matter = efficient_mats.Copy()
		if(istype(I) && isturf(I.loc))
			I.randpixel_xy() // Shift them around a bit so their visible.
		if(istype(I, /obj/item/stack))
			var/obj/item/stack/S = I
			S.add(qty - 1) // If its a stack, just add remaining qty to it and we're done
			break


//Updates overall lathe storage size.
/obj/machinery/autolathe/RefreshParts()
	..()
	var/mb_rating = 0
	var/man_rating = 0
	for(var/obj/item/weapon/stock_parts/matter_bin/MB in component_parts)
		mb_rating += MB.rating
	for(var/obj/item/weapon/stock_parts/manipulator/M in component_parts)
		man_rating += M.rating

	storage_capacity[DEFAULT_WALL_MATERIAL] = mb_rating  * 25000
	storage_capacity[MAT_GLASS] = mb_rating  * 12500
	build_speed = initial(build_speed) / man_rating
	mat_efficiency = 1.3 - man_rating * 0.1 // With maximum rating of parts = 5 this goes from 1.3 to 0.8

/obj/machinery/autolathe/dismantle()
	for(var/mat in stored_material)
		var/material/M = get_material_by_name(mat)
		if(!istype(M))
			continue
		var/obj/item/stack/material/S = new M.stack_type(get_turf(src))
		if(stored_material[mat] > S.perunit)
			S.amount = round(stored_material[mat] / S.perunit)
		else
			qdel(S)
	..()
	return 1
