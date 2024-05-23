/obj/item/stack/cable_coil/heavyduty
	name = "heavy cable coil"
	desc = "Extremely thick cable designed for durability with high power loads. Only recommended for power transmission to SMES connections."
	icon = 'icons/obj/power.dmi'
	icon_state = "coil-wire"
	item_state = "coil-wire"
	target_layer = CABLE_LAYER_4
	matter = list(MAT_STEEL = 200, MAT_GLASS = 200)
	color = COLOR_WHITE
	target_type = /obj/structure/cable/heavyduty
	tool_qualities = list(TOOL_CABLE_COIL)

/obj/item/stack/cable_coil/heavyduty/examine(mob/user)
	. = ..()
	. += "<b>Use it in hand</b> to construct a power transfer node. Rename its ID with your multitool."

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

/obj/item/stack/cable_coil/heavyduty/attack_self(mob/living/user)
	if(!user)
		return

	var/image/ender_icon = image(icon = 'icons/mob/radial.dmi', icon_state = "heavy-ender")
	ender_icon.maptext = "<span [amount >= CABLE_CONSTRUCTIONS_COSTS ? "" : "style='color: red'"]>[CABLE_CONSTRUCTIONS_COSTS]</span>"

	var/list/radial_menu = list(
	"Regular H.Cable" = image(icon = 'icons/mob/radial.dmi', icon_state = "heavy"),
	"H.Cable 'ender'" = ender_icon
	)
	var/layer_result = show_radial_menu(user, src, radial_menu, custom_check = CALLBACK(src, PROC_REF(check_menu), user), require_near = TRUE, tooltips = TRUE)
	if(!check_menu(user))
		return
	switch(layer_result)
		if("Regular H.Cable")
			name = "heavy cable coil"
			icon_state = "wire"
			target_type = /obj/item/stack/cable_coil/heavyduty
			target_layer = CABLE_LAYER_4
		if("H.Cable 'ender'")
			if (amount >= CABLE_CONSTRUCTIONS_COSTS)
				if(use(CABLE_CONSTRUCTIONS_COSTS))
					var/obj/structure/cable/heavyduty/ender/emplace = new(user.loc)
					emplace.Connect_cable()
	update_icon()

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
		to_chat(user, "<span class='notice'>There is already heavy cabling here.</span>")
		return
	if(W.has_tool_quality(TOOL_CABLE_COIL))
		to_chat(user, "<span class='notice'>You will need heavier cables to connect to these.</span>")
		return
	else
		..()

// they are hard to destroy because repairing them is a pain, actually.
/obj/structure/cable/heavyduty/ex_act(severity)
	return

//if powernetless_only = TRUE, will only get connections without powernet
/obj/structure/cable/heavyduty/ender
	name = "large power transfer node"
	desc = "This cable is tough. It cannot be cut with simple hand tools."
	// Pretend to be heavy duty power cable //we ARE heavy power cables :)))
	var/id = null

/obj/structure/cable/heavyduty/ender/Initialize(mapload)
	. = ..()
	cable_list += src
	return INITIALIZE_HINT_LATELOAD

//This is needed after all the powernet nonsense
/obj/structure/cable/heavyduty/ender/LateInitialize()
	. = ..()
	Connect_cable(FALSE)

/obj/structure/cable/heavyduty/ender/examine(mob/user)
	. = ..()
	if(id)
		. += "It is registered to the id tag of: [id]."
	. += "Use a multitool to set a new ID tag. The sender and reciever must be identical!"

/obj/structure/cable/heavyduty/ender/attackby(obj/item/W, mob/user)
	. = ..()
	if(W.has_tool_quality(TOOL_MULTITOOL))
		var/new_ident = tgui_input_text(usr, "Enter a new ident tag.", "Power Transmitter", id, MAX_NAME_LEN)
		new_ident = sanitize(new_ident,MAX_NAME_LEN)
		if(new_ident && user.Adjacent(src))
			id = new_ident
		return

/obj/structure/cable/heavyduty/ender/Connect_cable(var/powernetless_only = FALSE)
	. = ..() // Do the normal stuff
	if(id)
		for(var/obj/structure/cable/heavyduty/ender/target in cable_list)
			if(target.id == id)
				if (!powernetless_only || !target.powernet)
					. |= target
