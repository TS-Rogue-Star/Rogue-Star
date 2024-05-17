#define RCLMAXCAPACITY 90	//three full stacks

/obj/item/weapon/material/twohanded/rcl //WHY IS YOUR TWO HANDED CODE MARKED 'MATERIAL', POLARIS?! WHAT IS MATERIAL ABOUT IT?!
	name = "rapid cable layer"
	desc = "A device used to rapidly deploy cables. It has screws on the side which can be removed to slide off the cables. Do not use without insulation!"
	icon = 'icons/obj/tools.dmi'
	icon_state = "rcl"
	base_icon = "rcl"
	drop_sound = 'sound/items/drop/gun.ogg'
	pickup_sound = 'sound/items/pickup/gun.ogg'
	opacity = FALSE
	flags = NOBLUDGEON
	force = 5
	throwforce = 5
	throw_speed = 1
	throw_range = 5
	w_class = ITEMSIZE_NORMAL
	origin_tech = list(TECH_ENGINEERING = 2, TECH_MATERIAL = 2)
	/// maximum amount of cable this device can hold
	var/max_amount = RCLMAXCAPACITY
	/// current amount of cable in the machine
	var/current_amount = 0
	/// the player currently holding this device.
	var/mob/listeningTo
	/// what layer of cable are we working with
	var/cable_layer = CABLE_LAYER_2
	/// what color we'll be using for both the sprites and cables
	var/layingcolor = CABLELAYERTWOCOLOR
	/// optional locked color for avoiding recoloring wires on modify_cable
	var/layercolorlock = FALSE
	/// cached reference of the cable used in the device
	var/obj/item/stack/cable_coil/cable
	/// radial menu to select cable layer
	var/list/radial_menu = null
	/// Allow people to directly build terminals and wire machines with it
	tool_qualities = list(TOOL_CABLE_COIL)

/obj/item/weapon/material/twohanded/rcl/Initialize(mapload)
	. = ..()

/obj/item/weapon/material/twohanded/rcl/Destroy(force)
	. = ..()
	if(!QDELETED(cable))
		QDEL_NULL(cable)

/obj/item/weapon/material/twohanded/rcl/examine(mob/user)
	. = ..()
	if(cable)
		. += to_chat(user, "<span class='notice'>It contains [cable.amount]/[max_amount] cables.</span>")
	. += to_chat(user, "<span class='notice'>It's set to [LOWER_TEXT(GLOB.cable_layer_to_name["[cable_layer]"])].</span>")
	. += to_chat(user, "<span class='notice'>Alt click to adjust layers.</span>")
	. += to_chat(user, "<span class='notice'>Ctrl click to toggle the cable painting lock. It is currently [layercolorlock ? "locked." : "unlocked."]</span>")

/obj/item/weapon/material/twohanded/rcl/attackby(obj/item/W, mob/user)
	if(W.has_tool_quality(TOOL_CABLE_COIL))
		var/obj/item/stack/cable_coil/C = W

		if(!cable)
			if(!user.drop_location(W, src))
				to_chat(user, "<span class='warning'>[src] is stuck to your hand!</span>")
				return
			else
				cable = W //W.loc is src at this point.
				cable.max_amount = max_amount //We store a lot.
				return

		if(cable.amount < max_amount)
			var/transfer_amount = min(max_amount - cable.amount, C.amount)
			C.use(transfer_amount)
			cable.amount += transfer_amount
		else
			return
		update_icon()
		to_chat(user, "<span class='notice'>You add the cables to [src]. It now contains [cable.amount].</span>")
	else if(W.has_tool_quality(TOOL_SCREWDRIVER))
		if(!cable)
			return
		to_chat(user, "<span class='notice'>You loosen the securing screws on the side, allowing you to lower the guiding edge and retrieve the wires.</span>")
		while(cable.amount > 30) //There are only two kinds of situations: "nodiff" (60,90), or "diff" (31-59, 61-89)
			var/diff = cable.amount % 30
			if(diff)
				cable.use(diff)
				new /obj/item/stack/cable_coil(get_turf(user), diff)
			else
				cable.use(30)
				new /obj/item/stack/cable_coil(get_turf(user), 30)
		cable.max_amount = initial(cable.max_amount)
		if(!user.put_in_hands(cable))
			cable.forceMove(get_turf(user))

		cable = null
		update_icon()
	else
		..()

/obj/item/weapon/material/twohanded/rcl/Destroy()
	QDEL_NULL(cable)
	listeningTo = null
	return ..()

/obj/item/weapon/material/twohanded/update_held_icon()
	var/mob/living/M = loc
	if(istype(M) && M.can_wield_item(src) && is_held_twohanded(M))
		wielded = TRUE
		name = "[base_name] (wielded)"
		update_icon()
	else
		wielded = FALSE
		force = force_unwielded
		name = "[base_name]"
	update_icon()
	..()

/obj/item/weapon/material/twohanded/rcl/update_icon()
	. = ..()
	if(!cable)
		icon_state = "rcl0"
		return
	cut_overlays()
	var/cable_amount = 0
	switch(cable.amount)
		if(61 to INFINITY)
			cable_amount = 3
		if(31 to 60)
			cable_amount = 2
		if(1 to 30)
			cable_amount = 1
		else
			cable_amount = 0
	var/mutable_appearance/cable_overlay = mutable_appearance(icon, "rcl-[cable_amount]")
	cable_overlay.color = layingcolor
	if(cable_amount)
		add_overlay(cable_overlay)

/obj/item/weapon/material/twohanded/rcl/equipped(mob/to_hook)
	. = ..()
	if(listeningTo == to_hook)
		return .
	if(listeningTo)
		UnregisterSignal(listeningTo, COMSIG_MOVABLE_MOVED)
	RegisterSignal(to_hook, COMSIG_MOVABLE_MOVED, PROC_REF(on_move))
	listeningTo = to_hook

/obj/item/weapon/material/twohanded/rcl/dropped(mob/wearer)
	..()
	UnregisterSignal(wearer, COMSIG_MOVABLE_MOVED)
	listeningTo = null

/obj/item/weapon/material/twohanded/rcl/attackby(obj/item/attacking_item, mob/living/user)
	if(!istype(attacking_item, /obj/item/stack/cable_coil))
		return
	if ((istype(attacking_item, /obj/item/stack/cable_coil/alien)) || (istype(attacking_item, /obj/item/stack/cable_coil/heavyduty)))
		return	//please do not vore the special coils

	var/obj/item/stack/cable_coil/cable = attacking_item
	add_cable(user, cable)
	return TRUE

/obj/item/weapon/material/twohanded/rcl/CtrlClick(mob/user)
	layercolorlock = !layercolorlock
	to_chat(user, "<span class='notice'>Wire colors are now [layercolorlock ? "locked." : "unlocked."] in. You will not replace the colors on [LOWER_TEXT(GLOB.cable_layer_to_name["[cable_layer]"])]</span>")

/obj/item/weapon/material/twohanded/rcl/AltClick(mob/user)
	if(!radial_menu)
		radial_menu = list(
			"Layer 1" = image(icon = 'icons/mob/radial.dmi', icon_state = "coil-red"),
			"Layer 2" = image(icon = 'icons/mob/radial.dmi', icon_state = "coil-yellow"),
			"Layer 3" = image(icon = 'icons/mob/radial.dmi', icon_state = "coil-blue"),
			"Color Select" = image(icon = 'icons/mob/radial.dmi', icon_state = "rcl_rainbow")
		)

	var/layer_result = show_radial_menu(user, src, radial_menu, custom_check = CALLBACK(src, PROC_REF(check_menu), user), require_near = TRUE, tooltips = TRUE)
	if(!check_menu(user))
		return FALSE
	switch(layer_result)
		if("Layer 1")
			cable_layer = CABLE_LAYER_1
			if(!layercolorlock)
				layingcolor = CABLELAYERONECOLOR
		if("Layer 2")
			cable_layer = CABLE_LAYER_2
			if(!layercolorlock)
				layingcolor = CABLELAYERTWOCOLOR
		if("Layer 3")
			cable_layer = CABLE_LAYER_3
			if(!layercolorlock)
				layingcolor = CABLELAYERTHREECOLOR
		if("Color Select")
			if(layercolorlock)
				to_chat(user, "<span class='notice'>Wire colors are locked, silly.</span>")
			var/selected_type = tgui_input_list(usr, "Pick new color to apply on this layer.", "Cable Wire Color", GLOB.possible_cable_coil_colours)
			if(!selected_type)
				return
			layingcolor = selected_type

	update_icon()
	return TRUE

/obj/item/weapon/material/twohanded/rcl/proc/check_menu(mob/living/user)
	if(!istype(user))
		return FALSE
	if(!user.IsAdvancedToolUser())
		to_chat(user, "<span class='warning'>You don't have the dexterity to do this!</span>")
		return FALSE
	if(user.stat || !user.Adjacent(src))
		return FALSE
	return TRUE

/// insert cable into the rwd
/obj/item/weapon/material/twohanded/rcl/proc/add_cable(mob/user, obj/item/stack/cable_coil/cable)
	if(current_amount == max_amount)
		to_chat(user, "<span class='warning'>The device is full!</span>")
		return

	var/insert_amount = min(cable.amount, max_amount - current_amount)
	if(!cable.use(insert_amount))
		return

	delta_cable(insert_amount, decrement = FALSE)
	update_icon()
	to_chat(user, "<span class='notice'>Inserted [insert_amount] cable.</span>")

/// modify cable properties according to its layer
/obj/item/weapon/material/twohanded/rcl/proc/modify_cable(obj/item/stack/cable_coil/target_cable)
	switch(cable_layer)
		if(CABLE_LAYER_1)
			if(!layercolorlock)
				target_cable.color = CABLELAYERONECOLOR
			else
				target_cable.set_cable_color(layingcolor)
			target_cable.target_type = /obj/structure/cable/layer1
			target_cable.target_layer = CABLE_LAYER_1
		if(CABLE_LAYER_2)
			if(!layercolorlock)
				target_cable.color = CABLELAYERTWOCOLOR
			else
				target_cable.set_cable_color(layingcolor)
			target_cable.target_type = /obj/structure/cable
			target_cable.target_layer = CABLE_LAYER_2
		else
			if(!layercolorlock)
				target_cable.color = CABLELAYERTHREECOLOR
			else
				target_cable.set_cable_color(layingcolor)
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
	if(wielded && the_turf.can_have_cabling() && the_turf.can_lay_cable() && cable_allowed_here(the_turf))
		var/obj/item/stack/cable_coil/coil = get_cable()
		if(!coil)
			return

		coil.place_turf(the_turf, user)
		delta_cable(1, decrement = TRUE)
		update_icon()

	// pick up any stray cable pieces lying on the floor
	for(var/obj/item/stack/cable_coil/cable_piece in the_turf)
		add_cable(user, cable_piece)

/obj/item/weapon/material/twohanded/rcl/preloaded
	current_amount = RCLMAXCAPACITY

/obj/item/weapon/material/twohanded/rcl/admin
	name = "admin RWD"
	max_amount = INFINITY
	current_amount = INFINITY
