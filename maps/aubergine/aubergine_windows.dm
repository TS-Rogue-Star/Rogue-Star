/obj/structure/window
	blend_objects = list(/obj/machinery/door, /turf/simulated/wall) // Objects which to blend with
	noblend_objects = list(/obj/machinery/door/window)
	connections = list("0", "0", "0", "0")
	other_connections = list("0", "0", "0", "0")
	basestate = "window"
	var/reinf_basestate = "rwindow"

/obj/structure/window/Initialize()
	..()
	return INITIALIZE_HINT_LATELOAD

/obj/structure/window/LateInitialize()
	. = ..()

	update_connections(1)
	update_icon()

// Visually connect with every type of window as long as it's full-tile.
/obj/structure/window/can_visually_connect()
	return ..() && is_fulltile()

/obj/structure/window/can_visually_connect_to(var/obj/structure/S)
	return istype(S, /obj/structure/window)

//merges adjacent full-tile windows into one (blatant ripoff from game/smoothwall.dm)
/obj/structure/window/update_icon()
	//A little cludge here, since I don't know how it will work with slim windows. Most likely VERY wrong.
	//this way it will only update full-tile ones
	if(reinf)
		basestate = reinf_basestate
	else
		basestate = initial(basestate)
	cut_overlays()
	layer = WINDOW_LAYER
	if(!is_fulltile())
		icon_state = basestate
		return

	var/image/I
	icon_state = ""
	
	var/obj/item/stack/material/glass/gtype = glasstype
	var/material/mymat = get_material_by_name(initial(gtype.default_type))
	var/glasscolor = mymat?.icon_colour
	var/glassalpha = mymat?.opacity * 255

	if(is_on_frame())
		for(var/i = 1 to 4)
			if(other_connections[i] != "0")
				I = image(icon, "[basestate]_other_onframe[connections[i]]", dir = 1<<(i-1))
			else
				I = image(icon, "[basestate]_onframe[connections[i]]", dir = 1<<(i-1))
			if(mymat)
				I.color = glasscolor
				I.alpha = glassalpha
			I.layer = WINDOW_LAYER
			add_overlay(I)
	else
		for(var/i = 1 to 4)
			if(other_connections[i] != "0")
				I = image(icon, "[basestate]_other[connections[i]]", dir = 1<<(i-1))
			else
				I = image(icon, "[basestate][connections[i]]", dir = 1<<(i-1))
			if(mymat)
				I.color = glasscolor
				I.alpha = glassalpha
			I.layer = WINDOW_LAYER
			add_overlay(I)

/obj/structure/window/proc/is_on_frame()
	if(locate(/obj/structure/wall_frame) in loc)
		return TRUE