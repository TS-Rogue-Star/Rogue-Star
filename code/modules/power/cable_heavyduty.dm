/obj/item/stack/cable_coil/heavyduty
	name = "heavy cable coil"
	desc = "Extremely thick cable designed for durability with high power loads. Only recommended for power transmission to SMES connections."
	icon = 'icons/obj/power.dmi'
	icon_state = "wire"
	target_layer = CABLE_LAYER_4
	matter = list(MAT_STEEL = 200, MAT_GLASS = 200)
	color = COLOR_WHITE
	target_type = /obj/structure/cable/heavyduty


/obj/item/stack/cable_coil/heavyduty/attack_self(mob/living/user)
	if(!user)
		return

	var/image/ender_icon = image(icon = 'icons/mob/radial.dmi', icon_state = "heavy-ender")
	ender_icon.maptext = "<span [amount >= 20 ? "" : "style='color: red'"]>[20]</span>"

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
		if("H.Cable 'ender'")
			if (amount >= 20)
				if(use(20))
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
	///so it doesn't cross with normal powers. they'll only hook to SMES units
	cable_layer = CABLE_LAYER_4 //bitflag 8

/obj/structure/cable/heavyduty/attackby(obj/item/W, mob/user)
	var/turf/T = get_turf(user)
	if(!T.is_plating())
		return
	if(W.has_tool_quality(TOOL_CABLE_COIL))
		to_chat(user, "<span class='notice'>You will need heavier cables to connect to these.</span>")
		return
	if(istype(W, /obj/item/stack/cable_coil/heavyduty)
		to_chat(user, "<span class='notice'>There is already heavy cabling here.</span>")
		return
	else
		..()

// they are hard to destroy because repairing them is a pain, actually.
/obj/structure/cable/heavyduty/ex_act(severity)
	return

//if powernetless_only = TRUE, will only get connections without powernet
/obj/structure/cable/heavyduty/ender
	// Pretend to be heavy duty power cable //we ARE heavy power cables :)))
	var/id = null

/obj/structure/cable/heavyduty/ender/attackby(obj/item/W, mob/user)
	. = ..()
	if(W.has_tool_quality(TOOL_MULTITOOL))
		var/newid = sanitizeSafe(tgui_input_text(user, "Enter a Power transmission ID", "Transmission ID", id, MAX_NAME_LEN), MAX_NAME_LEN)
		if(length(newid) > 50)
			to_chat(user, "<span class='notice'>The id can be at most 50 characters long.</span>")
			return
		else
			to_chat(user, "<span class='notice'>You set the communication id to \"[newid]\".</span>")
			id = newid

/obj/structure/cable/heavyduty/ender/Connect_cable(var/powernetless_only = FALSE)
	. = ..() // Do the normal stuff
	if(id)
		for(var/obj/structure/cable/heavyduty/ender/target in GLOB.cable_list)
			if(target.id == id)
				if (!powernetless_only || !target.powernet)
					. |= target
