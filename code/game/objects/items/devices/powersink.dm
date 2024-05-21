// Powersink - used to drain station power

#define DISCONNECTED 0
#define CLAMPED_OFF 1
#define OPERATING 2

/obj/item/device/powersink
	name = "power sink"
	desc = "A nulling power sink which drains energy from electrical systems."
	icon_state = "powersink0"
	icon = 'icons/obj/device.dmi'
	w_class = ITEMSIZE_LARGE
	throwforce = 5
	throw_speed = 1
	throw_range = 2

	matter = list(MAT_STEEL = 750)

	origin_tech = list(TECH_POWER = 3, TECH_ILLEGAL = 5)
	var/drain_rate = 1.5 GIGAWATTS			// amount of power to drain per tick
	var/apc_drain_rate = 5 KILOWATTS 		// Max. amount drained from single APC. In Watts.
	var/dissipation_rate = 20 KILOWATTS		// Passive dissipation of drained power. In Watts.
	var/power_drained = 0 			// Amount of power drained.
	var/max_power = 10 GIGAWATTS			// Detonation point.
	var/mode = DISCONNECTED					// 0 = off, 1=clamped (off), 2=operating
	var/drained_this_tick = 0		// This is unfortunately necessary to ensure we process powersinks BEFORE other machinery such as APCs.

	var/obj/structure/cable/attached		// the attached cable

/obj/item/device/powersink/Destroy()
	STOP_PROCESSING(SSobj, src)
	STOP_PROCESSING_POWER_OBJECT(src)
	..()

/obj/item/device/powersink/attackby(var/obj/item/I, var/mob/user)
	if(I.has_tool_quality(TOOL_SCREWDRIVER))
		if(mode == DISCONNECTED)
			var/turf/T = loc
			if(isturf(T) && !!T.is_plating())
				attached = locate() in T
				if(!attached)
					to_chat(user, "No exposed cable here to attach to.")
					return
				else
					anchored = TRUE
					mode = CLAMPED_OFF
					src.visible_message("<span class='notice'>[user] attaches [src] to the cable!</span>")
					playsound(src, I.usesound, 50, 1)
					return
			else
				to_chat(user, "Device must be placed over an exposed cable to attach to it.")
				return
		else
			if (mode == OPERATING)
				STOP_PROCESSING(SSobj, src) // Now the power sink actually stops draining the station's power if you unhook it. --NeoFite
				STOP_PROCESSING_POWER_OBJECT(src)
			anchored = FALSE
			mode = DISCONNECTED
			src.visible_message("<span class='notice'>[user] detaches [src] from the cable!</span>")
			set_light(0)
			playsound(src, I.usesound, 50, 1)
			icon_state = "powersink0"

			return
	else
		..()

/obj/item/device/powersink/attack_ai()
	return

/obj/item/device/powersink/attack_hand(var/mob/user)
	switch(mode)
		if(DISCONNECTED)
			..()
		if(CLAMPED_OFF)
			src.visible_message("<span class='notice'>[user] activates [src]!</span>")
			mode = OPERATING
			icon_state = "powersink1"
			START_PROCESSING(SSobj, src)
			datum_flags &= ~DF_ISPROCESSING // Have to reset this flag so that PROCESSING_POWER_OBJECT can re-add it. It fails if the flag is already present. - Ater
			START_PROCESSING_POWER_OBJECT(src)
		if(OPERATING)  //This switch option wasn't originally included. It exists now. --NeoFite
			src.visible_message("<span class='notice'>[user] deactivates [src]!</span>")
			mode = CLAMPED_OFF
			set_light(0)
			icon_state = "powersink0"
			STOP_PROCESSING(SSobj, src)
			STOP_PROCESSING_POWER_OBJECT(src)

/obj/item/device/powersink/pwr_drain()
	var/datum/powernet/powernet = attached.powernet
	if(!attached)
		return FALSE
	if(drained_this_tick)
		return TRUE
	var/drained = 0

	set_light(12)
	powernet.trigger_warning()
	// found a powernet, so drain up to max power from it
	drained = attached.newavail()
	attached.draw_power(drained)
	// if tried to drain more than available on powernet
	// now look for APCs and drain their cells
	if(drained < drain_rate)
		for(var/obj/machinery/power/terminal/T in powernet.nodes)
			// Enough power drained this tick, no need to torture more APCs
			if(drained >= drain_rate)
				break
			if(isAPC(T.master))
				var/obj/machinery/power/apc/A = T.master
				if(A.operating && A.cell)
					drained += 0.001 * A.cell.use(0.05 * CELLRATE, force = TRUE)
	power_drained += drained
	drained_this_tick = TRUE
	return TRUE


/obj/item/device/powersink/process()
	if(!attached)
		mode = DISCONNECTED
		return
	if(mode != OPERATING)
		return
	drained_this_tick = FALSE
	drain_power()
	power_drained -= min(dissipation_rate, power_drained)
	if(power_drained > max_power * 0.95)
		playsound(src, 'sound/effects/screech.ogg', 100, 1, 1)
	if(power_drained >= max_power)
		STOP_PROCESSING(SSobj, src)
		STOP_PROCESSING_POWER_OBJECT(src)
		explosion(src.loc, 3,6,9,12)
		qdel(src)
		return
