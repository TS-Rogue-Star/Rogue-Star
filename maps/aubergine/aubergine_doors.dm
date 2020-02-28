#define BOLTS_FINE 0
#define BOLTS_EXPOSED 1
#define BOLTS_CUT 2

#define AIRLOCK_CLOSED	1
#define AIRLOCK_CLOSING	2
#define AIRLOCK_OPEN	3
#define AIRLOCK_OPENING	4
#define AIRLOCK_DENY	5
#define AIRLOCK_EMAG	6

#define AIRLOCK_PAINTABLE 1
#define AIRLOCK_STRIPABLE 2
#define AIRLOCK_DETAILABLE 4


/obj/machinery/door
	var/list/connections = list("0", "0", "0", "0")
	var/list/blend_objects = list(/obj/structure/window, /obj/structure/grille) // Objects which to blend with
	var/autoset_access = TRUE

/obj/machinery/door/LateInitialize()
	. = ..()
	if(autoset_access) // Delayed because apparently the dir is not set by mapping and we need to wait for nearby walls to init and turn us.
		inherit_access_from_area()

// Auto access by area
/obj/machinery/door/proc/inherit_access_from_area()
	var/area/fore = access_area_by_dir(dir)
	var/area/aft = access_area_by_dir(reverse_dir[dir])
	fore = fore || aft
	aft = aft || fore

	if (!fore && !aft)
		req_access = list()
	else if (fore.secure || aft.secure)
		req_access = req_access_union(fore, aft)
	else
		req_access = req_access_diff(fore, aft)

/obj/machinery/door/proc/access_area_by_dir(direction)
	var/turf/T = get_turf(get_step(src, direction))
	if (T && !T.density)
		return get_area(T)



/obj/machinery/door/airlock
	name = "airlock"
	icon = 'icons/obj/doors/baydoors/station/door.dmi'
	icon_state = "preview"

	var/airlock_type = "Standard"
	var/door_color = null
	var/stripe_color = null
	var/symbol_color = null

	//var/obj/item/weapon/airlock_brace/brace = null

	var/paintable = AIRLOCK_PAINTABLE|AIRLOCK_STRIPABLE //0 = Not paintable, 1 = Paintable, 3 = Paintable and Stripable, 7 for Paintable, Stripable and Detailable.

	var/fill_file = 'icons/obj/doors/baydoors/station/fill_steel.dmi'
	var/color_file = 'icons/obj/doors/baydoors/station/color.dmi'
	var/color_fill_file = 'icons/obj/doors/baydoors/station/fill_color.dmi'
	var/stripe_file = 'icons/obj/doors/baydoors/station/stripe.dmi'
	var/stripe_fill_file = 'icons/obj/doors/baydoors/station/fill_stripe.dmi'
	var/glass_file = 'icons/obj/doors/baydoors/station/fill_glass.dmi'
	var/bolts_file = 'icons/obj/doors/baydoors/station/lights_bolts.dmi'
	var/deny_file = 'icons/obj/doors/baydoors/station/lights_deny.dmi'
	var/lights_file = 'icons/obj/doors/baydoors/station/lights_green.dmi'
	var/panel_file = 'icons/obj/doors/baydoors/station/panel.dmi'
	var/sparks_damaged_file = 'icons/obj/doors/baydoors/station/sparks_damaged.dmi'
	var/sparks_broken_file = 'icons/obj/doors/baydoors/station/sparks_broken.dmi'
	var/welded_file = 'icons/obj/doors/baydoors/station/welded.dmi'
	var/emag_file = 'icons/obj/doors/baydoors/station/emag.dmi'

	open_sound_powered = 'sound/machines/baydoors/airlock_open.ogg'
	open_sound_unpowered = 'sound/machines/baydoors/airlock_open_force.ogg'
	var/open_failure_access_denied = 'sound/machines/baydoors/buzz-two.ogg'

	close_sound_powered = 'sound/machines/baydoors/airlock_close.ogg'
	var/close_sound_unpowered = 'sound/machines/baydoors/airlock_close_force.ogg'
	var/close_failure_blocked = 'sound/machines/baydoors/triple_beep.ogg'

	var/bolts_rising = 'sound/machines/baydoors/bolts_up.ogg'
	var/bolts_dropping = 'sound/machines/baydoors/bolts_down.ogg'

/obj/machinery/door/airlock/Initialize()
	update_connections(1)
	. = ..()

// Update Icons Code
/obj/machinery/door/proc/update_connections(var/propagate = 0)
	var/dirs = 0

	for(var/direction in cardinal)
		var/turf/T = get_step(src, direction)
		var/success = 0

		if( istype(T, /turf/simulated/wall))
			success = 1
			if(propagate)
				var/turf/simulated/wall/W = T
				W.update_connections(1)
				W.update_icon()

		else if( istype(T, /turf/simulated/shuttle/wall) ||	istype(T, /turf/unsimulated/wall))
			success = 1
		else
			for(var/obj/O in T)
				for(var/b_type in blend_objects)
					if( istype(O, b_type))
						success = 1

					if(success)
						break
				if(success)
					break

		if(success)
			dirs |= direction
	connections = dirs

var/airlock_icon_cache = list()
/obj/machinery/door/airlock/update_icon(state=0, override=0)
	if(connections in list(NORTH, SOUTH, NORTH|SOUTH))
		if(connections in list(WEST, EAST, EAST|WEST))
			set_dir(SOUTH)
		else
			set_dir(EAST)
	else
		set_dir(SOUTH)

	if(density)
		icon_state = "closed"
	else
		icon_state = "open"

	set_airlock_overlays(state)

/obj/machinery/door/airlock/proc/set_airlock_overlays(state)
	var/icon/color_overlay
	var/icon/filling_overlay
	var/icon/stripe_overlay
	var/icon/stripe_filling_overlay
	var/icon/lights_overlay
	var/icon/panel_overlay
	var/icon/weld_overlay
	var/icon/damage_overlay
	var/icon/sparks_overlay
	//var/icon/brace_overlay

	set_light(0)

	if(door_color && !(door_color == "none"))
		var/ikey = "[airlock_type]-[door_color]-color"
		color_overlay = airlock_icon_cache["[ikey]"]
		if(!color_overlay)
			color_overlay = new(color_file)
			color_overlay.Blend(door_color, ICON_MULTIPLY)
			airlock_icon_cache["[ikey]"] = color_overlay
	if(glass)
		filling_overlay = glass_file
	else
		if(door_color && !(door_color == "none"))
			var/ikey = "[airlock_type]-[door_color]-fillcolor"
			filling_overlay = airlock_icon_cache["[ikey]"]
			if(!filling_overlay)
				filling_overlay = new(color_fill_file)
				filling_overlay.Blend(door_color, ICON_MULTIPLY)
				airlock_icon_cache["[ikey]"] = filling_overlay
		else
			filling_overlay = fill_file
	if(stripe_color && !(stripe_color == "none"))
		var/ikey = "[airlock_type]-[stripe_color]-stripe"
		stripe_overlay = airlock_icon_cache["[ikey]"]
		if(!stripe_overlay)
			stripe_overlay = new(stripe_file)
			stripe_overlay.Blend(stripe_color, ICON_MULTIPLY)
			airlock_icon_cache["[ikey]"] = stripe_overlay
		if(!glass)
			var/ikey2 = "[airlock_type]-[stripe_color]-fillstripe"
			stripe_filling_overlay = airlock_icon_cache["[ikey2]"]
			if(!stripe_filling_overlay)
				stripe_filling_overlay = new(stripe_fill_file)
				stripe_filling_overlay.Blend(stripe_color, ICON_MULTIPLY)
				airlock_icon_cache["[ikey2]"] = stripe_filling_overlay

	if(arePowerSystemsOn())
		switch(state)
			if(AIRLOCK_CLOSED)
				if(lights && locked)
					lights_overlay = bolts_file
					set_light(0.25, 0.1, 1, 2, COLOR_RED_LIGHT)

			if(AIRLOCK_DENY)
				if(lights)
					lights_overlay = deny_file
					set_light(0.25, 0.1, 1, 2, COLOR_RED_LIGHT)

			if(AIRLOCK_EMAG)
				sparks_overlay = emag_file

			if(AIRLOCK_CLOSING)
				if(lights)
					lights_overlay = lights_file
					set_light(0.25, 0.1, 1, 2, COLOR_LIME)

			if(AIRLOCK_OPENING)
				if(lights)
					lights_overlay = lights_file
					set_light(0.25, 0.1, 1, 2, COLOR_LIME)

		if(stat & BROKEN)
			damage_overlay = sparks_broken_file
		else if(health < maxhealth * 3/4)
			damage_overlay = sparks_damaged_file

	if(welded)
		weld_overlay = welded_file

	if(p_open)
		panel_overlay = panel_file

	/*
	if(brace)
		brace.update_icon()
		brace_overlay += image(brace.icon, brace.icon_state)
	*/

	cut_overlays()
	add_overlay(color_overlay)
	add_overlay(filling_overlay)
	add_overlay(stripe_overlay)
	add_overlay(stripe_filling_overlay)
	add_overlay(panel_overlay)
	add_overlay(weld_overlay)
	//add_overlay(brace_overlay)
	add_overlay(lights_overlay)
	add_overlay(sparks_overlay)
	add_overlay(damage_overlay)

/obj/machinery/door/airlock/do_animate(animation)
	if(overlays)
		overlays.Cut()

	switch(animation)
		if("opening")
			set_airlock_overlays(AIRLOCK_OPENING)
			flick("opening", src)
			update_icon(AIRLOCK_OPEN)
		if("closing")
			set_airlock_overlays(AIRLOCK_CLOSING)
			flick("closing", src)
			update_icon(AIRLOCK_CLOSED)
		if("deny")
			set_airlock_overlays(AIRLOCK_DENY)
			if(density && arePowerSystemsOn())
				flick("deny", src)
				if(secured_wires)
					playsound(loc, open_failure_access_denied, 50, 0)
			update_icon(AIRLOCK_CLOSED)
		if("emag")
			set_airlock_overlays(AIRLOCK_EMAG)
			if(density && arePowerSystemsOn())
				flick("deny", src)
		else
			update_icon()
	return

// Preset airlock types

/obj/machinery/door/airlock/command
	icon = 'icons/obj/doors/baydoors/station/door.dmi'
	door_color = COLOR_COMMAND_BLUE

/obj/machinery/door/airlock/security
	icon = 'icons/obj/doors/baydoors/station/door.dmi'
	door_color = COLOR_NT_RED

/obj/machinery/door/airlock/security/research
	icon = 'icons/obj/doors/baydoors/station/door.dmi'
	door_color = COLOR_WHITE
	stripe_color = COLOR_NT_RED

/obj/machinery/door/airlock/engineering
	icon = 'icons/obj/doors/baydoors/station/door.dmi'
	name = "Maintenance Hatch"
	door_color = COLOR_AMBER

/obj/machinery/door/airlock/medical
	icon = 'icons/obj/doors/baydoors/station/door.dmi'
	door_color = COLOR_WHITE
	stripe_color = COLOR_DEEP_SKY_BLUE

/obj/machinery/door/airlock/virology
	icon = 'icons/obj/doors/baydoors/station/door.dmi'
	door_color = COLOR_WHITE
	stripe_color = COLOR_GREEN

/obj/machinery/door/airlock/mining
	icon = 'icons/obj/doors/baydoors/station/door.dmi'
	name = "Mining Airlock"
	door_color = COLOR_PALE_ORANGE
	stripe_color = COLOR_BEASTY_BROWN

/obj/machinery/door/airlock/atmos
	icon = 'icons/obj/doors/baydoors/station/door.dmi'
	door_color = COLOR_AMBER
	stripe_color = COLOR_CYAN

/obj/machinery/door/airlock/research
	icon = 'icons/obj/doors/baydoors/station/door.dmi'
	door_color = COLOR_WHITE
	stripe_color = COLOR_BOTTLE_GREEN

/obj/machinery/door/airlock/science
	icon = 'icons/obj/doors/baydoors/station/door.dmi'
	door_color = COLOR_WHITE
	stripe_color = COLOR_VIOLET

/obj/machinery/door/airlock/sol
	icon = 'icons/obj/doors/baydoors/station/door.dmi'
	door_color = COLOR_BLUE_GRAY

/obj/machinery/door/airlock/civilian
	icon = 'icons/obj/doors/baydoors/station/door.dmi'
	stripe_color = COLOR_CIVIE_GREEN

/obj/machinery/door/airlock/chaplain
	icon = 'icons/obj/doors/baydoors/station/door.dmi'
	stripe_color = COLOR_GRAY20

/obj/machinery/door/airlock/freezer
	icon = 'icons/obj/doors/baydoors/station/door.dmi'
	name = "Freezer Airlock"
	door_color = COLOR_WHITE

/obj/machinery/door/airlock/maintenance
	icon = 'icons/obj/doors/baydoors/station/door.dmi'
	name = "Maintenance Access"
	stripe_color = COLOR_AMBER

//Glass airlock presets

/obj/machinery/door/airlock/glass
	icon = 'icons/obj/doors/baydoors/station/door.dmi'
	name = "Glass Airlock"
	icon_state = "preview_glass"
	hitsound = 'sound/effects/Glasshit.ogg'
	maxhealth = 300
	explosion_resistance = 5
	opacity = 0
	glass = 1

/obj/machinery/door/airlock/glass/command
	icon = 'icons/obj/doors/baydoors/station/door.dmi'
	door_color = COLOR_COMMAND_BLUE
	stripe_color = COLOR_SKY_BLUE

/obj/machinery/door/airlock/glass/security
	icon = 'icons/obj/doors/baydoors/station/door.dmi'
	door_color = COLOR_NT_RED
	stripe_color = COLOR_ORANGE

/obj/machinery/door/airlock/glass/engineering
	icon = 'icons/obj/doors/baydoors/station/door.dmi'
	door_color = COLOR_AMBER
	stripe_color = COLOR_RED

/obj/machinery/door/airlock/glass/medical
	icon = 'icons/obj/doors/baydoors/station/door.dmi'
	door_color = COLOR_WHITE
	stripe_color = COLOR_DEEP_SKY_BLUE

/obj/machinery/door/airlock/glass/virology
	icon = 'icons/obj/doors/baydoors/station/door.dmi'
	door_color = COLOR_WHITE
	stripe_color = COLOR_GREEN

/obj/machinery/door/airlock/glass/mining
	icon = 'icons/obj/doors/baydoors/station/door.dmi'
	door_color = COLOR_PALE_ORANGE
	stripe_color = COLOR_BEASTY_BROWN

/obj/machinery/door/airlock/glass/atmos
	icon = 'icons/obj/doors/baydoors/station/door.dmi'
	door_color = COLOR_AMBER
	stripe_color = COLOR_CYAN

/obj/machinery/door/airlock/glass/research
	icon = 'icons/obj/doors/baydoors/station/door.dmi'
	door_color = COLOR_WHITE
	stripe_color = COLOR_RESEARCH

/obj/machinery/door/airlock/glass/science
	icon = 'icons/obj/doors/baydoors/station/door.dmi'
	door_color = COLOR_WHITE
	stripe_color = COLOR_VIOLET

/obj/machinery/door/airlock/glass/sol
	icon = 'icons/obj/doors/baydoors/station/door.dmi'
	door_color = COLOR_BLUE_GRAY
	stripe_color = COLOR_AMBER

/obj/machinery/door/airlock/glass/freezer
	icon = 'icons/obj/doors/baydoors/station/door.dmi'
	door_color = COLOR_WHITE

/obj/machinery/door/airlock/glass/maintenance
	icon = 'icons/obj/doors/baydoors/station/door.dmi'
	name = "Maintenance Access"
	stripe_color = COLOR_AMBER

/obj/machinery/door/airlock/glass/civilian
	icon = 'icons/obj/doors/baydoors/station/door.dmi'
	stripe_color = COLOR_CIVIE_GREEN

/obj/machinery/door/airlock/external
	airlock_type = "External"
	name = "External Airlock"
	icon = 'icons/obj/doors/baydoors/external/door.dmi'
	fill_file = 'icons/obj/doors/baydoors/external/fill_steel.dmi'
	color_file = 'icons/obj/doors/baydoors/external/color.dmi'
	color_fill_file = 'icons/obj/doors/baydoors/external/fill_color.dmi'
	glass_file = 'icons/obj/doors/baydoors/external/fill_glass.dmi'
	bolts_file = 'icons/obj/doors/baydoors/external/lights_bolts.dmi'
	deny_file = 'icons/obj/doors/baydoors/external/lights_deny.dmi'
	lights_file = 'icons/obj/doors/baydoors/external/lights_green.dmi'
	emag_file = 'icons/obj/doors/baydoors/external/emag.dmi'
	assembly_type = /obj/structure/door_assembly/door_assembly_ext
	door_color = COLOR_NT_RED
	paintable = AIRLOCK_PAINTABLE

/obj/machinery/door/airlock/external/inherit_access_from_area()
	..()
	if(isStationLevel(z))
		add_access_requirement(req_access, access_external_airlocks)

/obj/machinery/door/airlock/external/escapepod
	name = "Escape Pod"
	frequency =  1380
	locked = 1

/obj/machinery/door/airlock/external/escapepod/attackby(obj/item/C, mob/user)
	if(p_open && !arePowerSystemsOn())
		if(C.is_wrench())
			playsound(src.loc, 'sound/items/Ratchet.ogg', 50, 1)
			user.visible_message("<span class='warning'>[user.name] starts frantically pumping the bolt override mechanism!</span>", "<span class='warning'>You start frantically pumping the bolt override mechanism!</span>")
			if(do_after(user, 160) && locked)
				visible_message("\The [src] bolts disengage!")
				locked = 0
				return
			else
				visible_message("\The [src] bolts engage!")
				locked = 1
				return
	..()

/obj/machinery/door/airlock/external/bolted
	locked = 1

/obj/machinery/door/airlock/external/bolted/cycling
	frequency = 1379

/obj/machinery/door/airlock/external/bolted_open
	density = 0
	locked = 1
	opacity = 0

/obj/machinery/door/airlock/external/glass
	maxhealth = 300
	explosion_resistance = 5
	opacity = 0
	glass = 1

/obj/machinery/door/airlock/external/glass/bolted
	locked = 1

/obj/machinery/door/airlock/external/glass/bolted/cycling
	frequency = 1379

/obj/machinery/door/airlock/external/glass/bolted_open
	density = 0
	locked = 1
	opacity = 0

/obj/machinery/door/airlock/gold
	icon = 'icons/obj/doors/baydoors/station/door.dmi'
	name = "Gold Airlock"
	door_color = COLOR_SUN
	mineral = MAT_GOLD
/*
/obj/machinery/door/airlock/crystal
	name = "Crystal Airlock"
	door_color = COLOR_CRYSTAL
	mineral = MAT_CRYSTAL
*/
/obj/machinery/door/airlock/silver
	icon = 'icons/obj/doors/baydoors/station/door.dmi'
	name = "Silver Airlock"
	door_color = COLOR_SILVER
	mineral = MAT_SILVER

/obj/machinery/door/airlock/diamond
	icon = 'icons/obj/doors/baydoors/station/door.dmi'
	name = "Diamond Airlock"
	door_color = COLOR_CYAN_BLUE
	mineral = MAT_DIAMOND

/obj/machinery/door/airlock/uranium
	icon = 'icons/obj/doors/baydoors/station/door.dmi'
	name = "Uranium Airlock"
	desc = "And they said I was crazy."
	door_color = COLOR_PAKISTAN_GREEN
	mineral = MAT_URANIUM

/obj/machinery/door/airlock/sandstone
	icon = 'icons/obj/doors/baydoors/station/door.dmi'
	name = "\improper Sandstone Airlock"
	door_color = COLOR_BEIGE
	mineral = "sandstone"

/obj/machinery/door/airlock/phoron
	icon = 'icons/obj/doors/baydoors/station/door.dmi'
	name = "\improper Phoron Airlock"
	desc = "No way this can end badly."
	door_color = COLOR_PURPLE
	mineral = MAT_PHORON

/obj/machinery/door/airlock/centcom
	airlock_type = "centcomm"
	name = "\improper Airlock"
	icon = 'icons/obj/doors/baydoors/centcomm/door.dmi'
	fill_file = 'icons/obj/doors/baydoors/centcomm/fill_steel.dmi'
	paintable = AIRLOCK_PAINTABLE|AIRLOCK_STRIPABLE

/obj/machinery/door/airlock/highsecurity
	airlock_type = "secure"
	name = "Secure Airlock"
	icon = 'icons/obj/doors/baydoors/secure/door.dmi'
	fill_file = 'icons/obj/doors/baydoors/secure/fill_steel.dmi'
	explosion_resistance = 20
	secured_wires = 1
	assembly_type = /obj/structure/door_assembly/door_assembly_highsecurity
	paintable = 0

/obj/machinery/door/airlock/highsecurity/bolted
	locked = 1

/obj/machinery/door/airlock/hatch
	airlock_type = "hatch"
	name = "\improper Airtight Hatch"
	icon = 'icons/obj/doors/baydoors/hatch/door.dmi'
	fill_file = 'icons/obj/doors/baydoors/hatch/fill_steel.dmi'
	stripe_file = 'icons/obj/doors/baydoors/hatch/stripe.dmi'
	stripe_fill_file = 'icons/obj/doors/baydoors/hatch/fill_stripe.dmi'
	bolts_file = 'icons/obj/doors/baydoors/hatch/lights_bolts.dmi'
	deny_file = 'icons/obj/doors/baydoors/hatch/lights_deny.dmi'
	lights_file = 'icons/obj/doors/baydoors/hatch/lights_green.dmi'
	panel_file = 'icons/obj/doors/baydoors/hatch/panel.dmi'
	welded_file = 'icons/obj/doors/baydoors/hatch/welded.dmi'
	emag_file = 'icons/obj/doors/baydoors/hatch/emag.dmi'
	explosion_resistance = 20
	opacity = 1
	assembly_type = /obj/structure/door_assembly/door_assembly_hatch
	paintable = AIRLOCK_STRIPABLE

/obj/machinery/door/airlock/hatch/maintenance
	name = "Maintenance Hatch"
	stripe_color = COLOR_AMBER

/obj/machinery/door/airlock/hatch/maintenance/bolted
	locked = 1

/obj/machinery/door/airlock/vault
	airlock_type = "vault"
	name = "Vault"
	icon = 'icons/obj/doors/baydoors/vault/door.dmi'
	fill_file = 'icons/obj/doors/baydoors/vault/fill_steel.dmi'
	explosion_resistance = 20
	opacity = 1
	secured_wires = 1
	assembly_type = /obj/structure/door_assembly/door_assembly_highsecurity //Until somebody makes better sprites.
	paintable = AIRLOCK_PAINTABLE|AIRLOCK_STRIPABLE

/obj/machinery/door/airlock/vault/bolted
	locked = 1