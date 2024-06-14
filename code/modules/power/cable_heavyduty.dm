/obj/item/stack/cable_coil/heavyduty
	name = "heavy cable coil"
	desc = "Extremely thick cable designed for durability with high power loads. Only recommended for power transmission to SMES connections."
	icon = 'icons/obj/machines/power/power.dmi'
	icon_state = "coil-wire"
	item_state = "coil-wire"
	target_layer = CABLE_LAYER_4
	matter = list(MAT_STEEL = 200, MAT_GLASS = 200)
	color = COLOR_WHITE
	target_type = /obj/structure/cable/heavyduty
	tool_qualities = list(TOOL_CABLE_COIL)

/obj/item/stack/cable_coil/heavyduty/update_icon()
	if(amount == 1)
		icon_state = "coil-wire1"
		name = "heavy cable piece"
	else if(amount == 2)
		icon_state = "coil-wire2"
		name = "heavy cable length"
	else
		icon_state = "coil-wire"
		name = initial(name)

/obj/structure/cable/heavyduty
	icon = 'icons/obj/cables/power_cond_heavy.dmi'
	icon_state = "l8-1-2-4-8-node"
	name = "large power cable"
	desc = "This cable is tough. It cannot be cut with simple hand tools."
	unacidable = TRUE
	plane = PLATING_PLANE
	layer = PIPES_LAYER - 0.05 //Just below pipes
	color = COLOR_WHITE	//so it doesn't get recolored to like, pink or something
	///so it doesn't cross with normal powers. they'll only hook to SMES units normally.
	cable_layer = CABLE_LAYER_4 //bitflag 8

/obj/structure/cable/heavyduty/attackby(obj/item/W, mob/user)
	var/turf/T = get_turf(user)
	if(!T.is_plating())
		return
	if(istype(W, /obj/item/stack/cable_coil/heavyduty))
		to_chat(user, span_notice("There is already heavy cabling here."))
		return
	if(W.has_tool_quality(TOOL_CABLE_COIL))
		to_chat(user, span_notice("You will need heavier cables to connect to these."))
		return
	else
		..()

// they are hard to destroy because repairing them is a pain, actually.
/obj/structure/cable/heavyduty/ex_act(severity)
	return
