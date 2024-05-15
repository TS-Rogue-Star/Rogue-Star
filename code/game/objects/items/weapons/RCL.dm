/obj/item/weapon/material/twohanded/rcl //WHY IS YOUR TWO HANDED CODE MARKED 'MATERIAL', POLARIS?! WHAT IS MATERIAL ABOUT IT?!
	name = "rapid cable layer"
	desc = "A device used to rapidly deploy cables. It has screws on the side which can be removed to slide off the cables. Do not use without insulation!"
	icon = 'icons/obj/tools.dmi'
	icon_state = "rcl-empty"
	item_state = "rcl-0"
	var/obj/structure/cable/last
	var/obj/item/stack/cable_coil/loaded
	opacity = FALSE
	flags = NOBLUDGEON
	force = 5
	throwforce = 5
	throw_speed = 1
	throw_range = 5
	w_class = ITEMSIZE_NORMAL
	origin_tech = list(TECH_ENGINEERING = 2, TECH_MATERIAL = 2)
	var/max_amount = 90
	var/active = FALSE
	actions_types = list(/datum/action/item_action/rcl_col,/datum/action/item_action/rcl_gui)
	var/list/colors = GLOB.possible_cable_coil_colours
	var/current_color_index = 1
	var/datum/component/mobhook
	var/datum/radial_menu/persistent/wiring_gui_menu

/obj/item/weapon/material/twohanded/rcl/attackby(obj/item/W, mob/user)
	if(istype(W, /obj/item/stack/cable_coil))
		var/obj/item/stack/cable_coil/C = W

		if(!loaded)
			if(!user.drop_location(W, src))
				to_chat(user, "<span class='warning'>[src] is stuck to your hand!</span>")
				return
			else
				loaded = W //W.loc is src at this point.
				loaded.max_amount = max_amount //We store a lot.
				return

		if(loaded.amount < max_amount)
			var/transfer_amount = min(max_amount - loaded.amount, C.amount)
			C.use(transfer_amount)
			loaded.amount += transfer_amount
		else
			return
		update_icon()
		to_chat(user, "<span class='notice'>You add the cables to [src]. It now contains [loaded.amount].</span>")
	else if(W.has_tool_quality(TOOL_SCREWDRIVER))
		if(!loaded)
			return
		to_chat(user, "<span class='notice'>You loosen the securing screws on the side, allowing you to lower the guiding edge and retrieve the wires.</span>")
		while(loaded.amount > 30) //There are only two kinds of situations: "nodiff" (60,90), or "diff" (31-59, 61-89)
			var/diff = loaded.amount % 30
			if(diff)
				loaded.use(diff)
				new /obj/item/stack/cable_coil(get_turf(user), diff)
			else
				loaded.use(30)
				new /obj/item/stack/cable_coil(get_turf(user), 30)
		loaded.max_amount = initial(loaded.max_amount)
		if(!user.put_in_hands(loaded))
			loaded.forceMove(get_turf(user))

		loaded = null
		update_icon()
	else
		..()

/obj/item/weapon/material/twohanded/rcl/examine(mob/user)
	. = ..()
	. += "Dual wield & walk over floors to lay cable."
	. += "It has [loaded.amount] pieces remaining."
	. += "Right click on it to dispense a custom amount of cable."
	. += "Alt click to change cable layer."

/obj/item/weapon/material/twohanded/rcl/Destroy()
	QDEL_NULL(loaded)
	last = null
	QDEL_NULL(mobhook)
	QDEL_NULL(wiring_gui_menu)
	return ..()

/obj/item/weapon/material/twohanded/rcl/update_icon()
	if(!loaded)
		icon_state = "rcl-empty"
		item_state = "rcl-empty"
		return
	cut_overlays()
	var/cable_amount = 0
	switch(loaded.amount)
		if(61 to INFINITY)
			cable_amount = 3
		if(31 to 60)
			cable_amount = 2
		if(1 to 30)
			cable_amount = 1
		else
			cable_amount = 0

	var/mutable_appearance/cable_overlay = mutable_appearance(icon, "rcl-[cable_amount]")
	cable_overlay.color = GLOB.cable_colors[colors[current_color_index]]
	if(cable_amount >= 1)
		icon_state = "rcl"
		item_state = "rcl"
		add_overlay(cable_overlay)
	else
		icon_state = "rcl-empty"
		item_state = "rcl-0"
		add_overlay(cable_overlay)


/obj/item/weapon/material/twohanded/rcl/proc/is_empty(mob/user, loud = 1)
	update_icon()
	if(!loaded || !loaded.amount)
		if(loud)
			to_chat(user, "<span class='notice'>The last of the cables unreel from [src].</span>")
		if(loaded)
			QDEL_NULL(loaded)
			loaded = null
		QDEL_NULL(wiring_gui_menu)
		unwield(user)
		active = wielded
		return TRUE
	return FALSE

/obj/item/weapon/material/twohanded/rcl/pickup(mob/user)
	..()
	getMobhook(user)



/obj/item/weapon/material/twohanded/rcl/dropped(mob/wearer)
	..()
	if(mobhook)
		active = FALSE
		QDEL_NULL(mobhook)
	last = null

/obj/item/weapon/material/twohanded/rcl/attack_self(mob/user)
	..()
	active = wielded
	if(!active)
		last = null
	else if(!last)
		for(var/obj/structure/cable/C in get_turf(user))
			if(C.d1 == FALSE || C.d2 == FALSE)
				last = C
				break

obj/item/twohanded/rcl/proc/getMobhook(mob/to_hook)
	if(to_hook)
		if(mobhook && mobhook.parent != to_hook)
			QDEL_NULL(mobhook)
		if (!mobhook)
			mobhook = to_hook.AddComponent(/datum/component/redirect, list(COMSIG_MOVABLE_MOVED = CALLBACK(src, .proc/trigger)))
	else
		QDEL_NULL(mobhook)

/obj/item/weapon/material/twohanded/rcl/proc/trigger(mob/user)
	if(active)
		layCable(user)
	if(wiring_gui_menu) //update the wire options as you move
		wiringGuiUpdate(user)


//previous contents of trigger(), lays cable each time the player moves
/obj/item/weapon/material/twohanded/rcl/proc/layCable(mob/user)
	if(!isturf(user.loc))
		return
	if(is_empty(user, 0))
		to_chat(user, "<span class='warning'>\The [src] is empty!</span>")
		return
	else
		if(last)
			if(get_dist(last, user) == 1) //hacky, but it works
				var/turf/T = get_turf(user)
				if(T.is_plating || !T.can_have_cabling())
					last = null
					return
				if(get_dir(last, user) == last.d2)
					//Did we just walk backwards? Well, that's the one direction we CAN'T complete a stub.
					last = null
					return
				loaded.cable_join(last, user, FALSE)
				if(is_empty(user))
					return //If we've run out, display message and exit
			else
				last = null
		loaded.item_color	 = colors[current_color_index]
		last = loaded.place_turf(get_turf(src), user, turn(user.dir, 180))
		is_empty(user) //If we've run out, display message
	update_icon()

//searches the current tile for a stub cable of the same colour
/obj/item/weapon/material/twohanded/rcl/proc/findLinkingCable(mob/user)
	var/turf/T
	if(!isturf(user.loc))
		return

	T = get_turf(user)
	if(T.intact || !T.can_have_cabling())
		return

	for(var/obj/structure/cable/C in T)
		if(!C)
			continue
		if(C.cable_color != GLOB.cable_colors[colors[current_color_index]])
			continue
		if(C.d1 == 0)
			return C
			break
	return


/obj/item/weapon/material/twohanded/rcl/proc/wiringGuiGenerateChoices(mob/user)
	var/fromdir = 0
	var/obj/structure/cable/linkingCable = findLinkingCable(user)
	if(linkingCable)
		fromdir = linkingCable.d2

	var/list/wiredirs = list("1","5","4","6","2","10","8","9")
	for(var/icondir in wiredirs)
		var/dirnum = text2num(icondir)
		var/cablesuffix = "[min(fromdir,dirnum)]-[max(fromdir,dirnum)]"
		if(fromdir == dirnum) //cables can't loop back on themselves
			cablesuffix = "invalid"
		var/image/img = image(icon = 'icons/mob/radial.dmi', icon_state = "cable_[cablesuffix]")
		img.color = GLOB.cable_colors[colors[current_color_index]]
		wiredirs[icondir] = img
	return wiredirs

/obj/item/weapon/material/twohanded/rcl/proc/showWiringGui(mob/user)
	var/list/choices = wiringGuiGenerateChoices(user)

	wiring_gui_menu = show_radial_menu_persistent(user, src , choices, select_proc = CALLBACK(src, .proc/wiringGuiReact, user), radius = 42)

/obj/item/weapon/material/twohanded/rcl/proc/wiringGuiUpdate(mob/user)
	if(!wiring_gui_menu)
		return

	wiring_gui_menu.entry_animation = FALSE //stop the open anim from playing each time we update
	var/list/choices = wiringGuiGenerateChoices(user)

	wiring_gui_menu.change_choices(choices,FALSE)


//Callback used to respond to interactions with the wiring menu
/obj/item/weapon/material/twohanded/rcl/proc/wiringGuiReact(mob/living/user,choice)
	if(!choice) //close on a null choice (the center button)
		QDEL_NULL(wiring_gui_menu)
		return

	choice = text2num(choice)

	if(!isturf(user.loc))
		return
	if(is_empty(user, 0))
		to_chat(user, "<span class='warning'>\The [src] is empty!</span>")
		return

	var/turf/T = get_turf(user)
	if(T.intact || !T.can_have_cabling())
		return

	loaded.item_color	 = colors[current_color_index]

	var/obj/structure/cable/linkingCable = findLinkingCable(user)
	if(linkingCable)
		if(choice != linkingCable.d2)
			loaded.cable_join(linkingCable, user, FALSE, choice)
			last = null
	else
		last = loaded.place_turf(get_turf(src), user, choice)

	is_empty(user) //If we've run out, display message

	wiringGuiUpdate(user)


/obj/item/weapon/material/twohanded/rcl/pre_loaded/Initialize() //Comes preloaded with cable, for testing stuff
	. = ..()
	loaded = new()
	loaded.max_amount = max_amount
	loaded.amount = max_amount
	update_icon()

/obj/item/weapon/material/twohanded/rcl/Initialize()
	. = ..()
	update_icon()

/obj/item/weapon/material/twohanded/rcl/ui_action_click(mob/user, action)
	if(istype(action, /datum/action/item_action/rcl_col))
		current_color_index++;
		if (current_color_index > colors.len)
			current_color_index = 1
		var/cwname = colors[current_color_index]
		to_chat(user, "Color changed to [cwname]!")
		if(loaded)
			loaded.item_color= colors[current_color_index]
			update_icon()
		if(wiring_gui_menu)
			wiringGuiUpdate(user)
	else if(istype(action, /datum/action/item_action/rcl_gui))
		if(wiring_gui_menu) //The menu is already open, close it
			QDEL_NULL(wiring_gui_menu)
		else //open the menu
			showWiringGui(user)

/obj/item/weapon/material/twohanded/rcl/AltClick(mob/user)
	. = ..()
	if(!radial_menu)
		radial_menu = list(
			"Layer 1" = image(icon = 'icons/hud/radial.dmi', icon_state = "coil-red"),
			"Layer 2" = image(icon = 'icons/hud/radial.dmi', icon_state = "coil-yellow"),
			"Layer 3" = image(icon = 'icons/hud/radial.dmi', icon_state = "coil-blue"),
		)

	var/layer_result = show_radial_menu(user, src, radial_menu, custom_check = CALLBACK(src, PROC_REF(check_menu), user), require_near = TRUE, tooltips = TRUE)
	if(!check_menu(user))
		return
	switch(layer_result)
		if("Layer 1")
			cable_layer = CABLE_LAYER_1
		if("Layer 2")
			cable_layer = CABLE_LAYER_2
		if("Layer 3")
			cable_layer = CABLE_LAYER_3

/obj/item/weapon/material/twohanded/rcl/proc/check_menu(mob/living/user)
	if(!istype(user))
		return FALSE
	if(!user.IsAdvancedToolUser())
		to_chat(user, span_warning("You don't have the dexterity to do this!"))
		return FALSE
	if(user.stat || !user.Adjacent(src))
		return FALSE
	return TRUE

/// insert cable into the rwd
/obj/item/weapon/material/twohanded/rcl/proc/add_cable(mob/user, obj/item/stack/cable_coil/cable)
	if(current_amount == max_amount)
		to_chat(user, span_warning("device is full!"))
		return

	var/insert_amount = min(cable.amount, max_amount - current_amount)
	if(!cable.use(insert_amount))
		return

	delta_cable(insert_amount, decrement = FALSE)
	update_icon()
	to_chat(user, span_warning("you insert [insert_amount] cable"))

/// modify cable properties according to its layer
/obj/item/weapon/material/twohanded/rcl/proc/modify_cable(obj/item/stack/cable_coil/target_cable)
	switch(cable_layer)
		if(CABLE_LAYER_1)
			target_cable.set_cable_color(CABLELAYERONECOLOR)
			target_cable.target_type = /obj/structure/cable/layer1
			target_cable.target_layer = CABLE_LAYER_1
		if(CABLE_LAYER_2)
			target_cable.set_cable_color(CABLELAYERTWOCOLOR)
			target_cable.target_type = /obj/structure/cable
			target_cable.target_layer = CABLE_LAYER_2
		else
			target_cable.set_cable_color(CABLELAYERTHREECOLOR)
			target_cable.target_type = /obj/structure/cable/layer3
			target_cable.target_layer = CABLE_LAYER_3
	return target_cable

/// get cached reference of cable which gets used over time
/obj/item/weapon/material/twohanded/rcl/proc/get_cable()
	if(QDELETED(cable))
		var/create_amount = min(30, current_amount)
		if(create_amount <= 0)
			return null
		cable = new/obj/item/stack/cable_coil(src, create_amount)
	return modify_cable(cable)

/// check if the turf has the same cable layer as this design. If it does don't put cable here
/obj/item/weapon/material/twohanded/rcl/proc/cable_allowed_here(turf/the_turf)
	// infer our intended cable design from the layer
	var/obj/structure/cable/design_type
	switch(cable_layer)
		if(CABLE_LAYER_1)
			design_type = /obj/structure/cable/layer1
		if(CABLE_LAYER_2)
			design_type = /obj/structure/cable
		else
			design_type = /obj/structure/cable/layer3

	for(var/obj/structure/cable/cable as anything in the_turf)
		// cable layer on the turf is the same as our intended design layer so nope
		if(cable.type == design_type)
			return FALSE

	return TRUE

/// extra safe modify just to be sure
/obj/item/weapon/material/twohanded/rcl/proc/delta_cable(amount, decrement)
	if(decrement)
		current_amount -= amount
	else
		current_amount += amount
	current_amount = clamp(current_amount, 0, max_amount)

/// stuff to do when moving
/obj/item/weapon/material/twohanded/rcl/proc/on_move(mob/user)
	SIGNAL_HANDLER

	if(!isturf(user.loc))
		return
	var/turf/the_turf = user.loc
	/**
	 * Lay cable only if
	 * - device is active
	 * - the turf can hold cable
	 * - there is no cable on the turf or there is cable on the turf but its not the same layer we are gonna put on the turf
	 */
	if(active && the_turf.can_have_cabling() && the_turf.can_lay_cable() && cable_allowed_here(the_turf))
		var/obj/item/stack/cable_coil/coil = get_cable()
		if(!coil)
			return

		coil.place_turf(the_turf, user)
		delta_cable(1, decrement = TRUE)
		update_icon()

	// pick up any stray cable pieces lying on the floor
	for(var/obj/item/stack/cable_coil/cable_piece in the_turf)
		add_cable(user, cable_piece)
