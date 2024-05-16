// Updated version of old powerswitch by Atlantis
// Has better texture, and is now considered electronic device
// AI has ability to toggle it in 5 seconds
// Humans need 30 seconds (AI is faster when it comes to complex electronics) //ITS A FUCKING SWITCH
// Used for advanced grid control (read: Substations)

/obj/machinery/power/breakerbox
	name = "Breaker Box"
	desc = "Large machine with heavy duty switching circuits used for advanced grid control."
	icon = 'icons/obj/power.dmi'
	icon_state = "bbox_off"
	var/icon_state_on = "bbox_on"
	var/icon_state_off = "bbox_off"
	density = TRUE
	anchored = TRUE
	unacidable = TRUE
	circuit = /obj/item/weapon/circuitboard/breakerbox
	var/obj/structure/cable/stored
	var/on = FALSE
	var/busy = FALSE
	var/RCon_tag = "NO_TAG"
	var/update_locked = FALSE

/obj/machinery/power/breakerbox/Destroy()
	for(var/obj/structure/cable/C in src.loc)
		qdel(C)
	if(stored)
		stored = null
	. = ..()
	for(var/datum/tgui_module/rcon/R in world)
		R.FindDevices()

/obj/machinery/power/breakerbox/Initialize()
	. = ..()
	default_apply_parts()

/obj/machinery/power/breakerbox/should_have_node()
	return TRUE

/obj/machinery/power/breakerbox/activated
	icon_state = "bbox_on"

// Enabled on server startup. Used in substations to keep them in bypass mode.
/obj/machinery/power/breakerbox/activated/Initialize()
	. = ..()
	return INITIALIZE_HINT_LATELOAD

/obj/machinery/power/breakerbox/activated/LateInitialize()
	set_state(TRUE)

/obj/machinery/power/breakerbox/examine(mob/user)
	. = ..()
	if(on)
		. += "<span class='notice'>It seems to be online.</span>"
	else
		. += "<span class='warning'>It seems to be offline.</span>"

/obj/machinery/power/breakerbox/attack_ai(mob/user)
	if(update_locked)
		to_chat(user, "<font color='red'>System locked. Please try again later.</font>")
		return

	if(busy)
		to_chat(user, "<font color='red'>System is busy. Please wait until current operation is finished before changing power settings.</font>")
		return

	busy = TRUE
	to_chat(user, "<font color='green'>Updating power settings...</font>")
	if(do_after(user, 5 SECONDS))
		set_state(!on)
		to_chat(user, "<font color='green'>Update Completed. New setting:[on ? "on": "off"]</font>")
		update_locked = TRUE
		spawn(10 SECONDS)	//why was it 5 minutes cool down...
			update_locked = FALSE
	busy = FALSE


/obj/machinery/power/breakerbox/attack_hand(mob/user)
	if(update_locked)
		to_chat(user, "<font color='red'>System locked. Please try again later.</font>")
		return

	if(busy)
		to_chat(user, "<font color='red'>System is busy. Please wait until current operation is finished before changing power settings.</font>")
		return

	busy = TRUE
	visible_message("<font color='red'>[user] started reprogramming [src]!</font>")

	if(do_after(user, 5 SECONDS))
		set_state(!on)
		user.visible_message(\
		"<span class='notice'>[user.name] [on ? "enabled" : "disabled"] the breaker box!</span>",\
		"<span class='notice'>You [on ? "enabled" : "disabled"] the breaker box!</span>")
		update_locked = TRUE
		spawn(10 SECONDS)
			update_locked = FALSE
	busy = FALSE

/obj/machinery/power/breakerbox/attackby(var/obj/item/weapon/W as obj, var/mob/user as mob)
	if(istype(W, /obj/item/device/multitool))
		var/newtag = tgui_input_text(user, "Enter new RCON tag. Use \"NO_TAG\" to disable RCON or leave empty to cancel.", "SMES RCON system", "", MAX_NAME_LEN)
		newtag = sanitize(newtag,MAX_NAME_LEN)
		if(newtag)
			RCon_tag = newtag
			to_chat(user, "<span class='notice'>You changed the RCON tag to: [newtag]</span>")
	if(on)
		to_chat(user, "<font color='red'>Disable the breaker before performing maintenance.</font>")
		return
	if(default_deconstruction_screwdriver(user, W))
		return
	if(default_deconstruction_crowbar(user, W))
		return
	if(default_part_replacement(user, W))
		return

/obj/machinery/power/breakerbox/proc/set_state(var/state)
	on = state
	if(on)
		icon_state = icon_state_on
		var/list/connection_dirs = list()
		for(var/direction in GLOB.cardinal)
			for(var/obj/structure/cable/C in get_step(src,direction))
				connection_dirs += direction
				cable_layer = C.cable_layer //Ensure our cable layer matches the connections
				break

		if(stored) //let's try to preserve our wire to save on generations.
			var/obj/structure/cable/C = stored
			C.loc = loc
			stored = null
			if(!C.breaker_box)
				C.breaker_box = src
			C.Connect_cable()
		else
			var/obj/structure/cable/C = new/obj/structure/cable(src.loc)
			C.cable_layer = cable_layer	//ensuring the new cable is, also, the correct layer.
			if(!C.breaker_box)
				C.breaker_box = src

	else
		icon_state = icon_state_off
		for(var/obj/structure/cable/C in src.loc)
			if(!C) return


// Used by RCON to toggle the breaker box.
/obj/machinery/power/breakerbox/proc/auto_toggle()
	if(!update_locked)
		set_state(!on)
		update_locked = TRUE
		spawn(600)
			update_locked = FALSE

/obj/machinery/power/breakerbox/process()
	return TRUE
