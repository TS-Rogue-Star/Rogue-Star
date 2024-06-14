//This file was auto-corrected by findeclaration.exe on 25.5.2012 20:42:33
var/global/list/rad_collectors = list()

/obj/machinery/power/rad_collector
	name = "Radiation Collector Array"
	desc = "A device which uses Hawking Radiation and phoron to produce power."
	icon = 'icons/obj/machines/power/singularity/singularity.dmi'
	icon_state = "ca"
	anchored = FALSE
	density = TRUE
	req_access = list(access_engine_equip)
//	use_power = 0
	var/obj/item/weapon/tank/phoron/P = null
	var/last_power = 0
	var/last_power_new = 0
	var/active = FALSE
	var/locked = FALSE
	var/drainratio = 1
	can_change_cable_layer = TRUE

/obj/machinery/power/rad_collector/New()
	..()
	rad_collectors += src

/obj/machinery/power/rad_collector/Destroy()
	rad_collectors -= src
	return ..()

/obj/machinery/power/rad_collector/should_have_node()
	return anchored

/obj/machinery/power/rad_collector/process()
	//so that we don't zero out the meter if the SM is processed first.
	last_power = last_power_new
	last_power_new = 0


	if(P && active)
		var/rads = SSradiation.get_rads_at_turf(get_turf(src))
		if(rads)
			receive_pulse(rads * 5) //Maths is hard

	if(P)
		if(P.air_contents.gas["phoron"] == 0)
			investigate_log("<font color='red'>out of fuel</font>.","singulo")
			eject()
		else
			P.air_contents.adjust_gas("phoron", -0.001*drainratio)
	return


/obj/machinery/power/rad_collector/attack_hand(mob/user as mob)
	if(anchored)
		if(!locked)
			toggle_power()
			user.visible_message("[user.name] turns the [name] [active? "on":"off"].", \
			"You turn the [name] [active? "on":"off"].")
			investigate_log("turned [active?"<font color='green'>on</font>":"<font color='red'>off</font>"] by [user.key]. [P?"Fuel: [round(P.air_contents.gas["phoron"]/0.29)]%":"<font color='red'>It is empty</font>"].","singulo")
			return
		else
			to_chat(user, "<font color='red'>The controls are locked!</font>")
			return


/obj/machinery/power/rad_collector/attackby(obj/item/W, mob/user)
	if(istype(W, /obj/item/weapon/tank/phoron))
		if(!anchored)
			to_chat(user, "<font color='red'>The [src] needs to be secured to the floor first.</font>")
			return TRUE
		if(P)
			to_chat(user, "<font color='red'>There's already a phoron tank loaded.</font>")
			return TRUE
		user.drop_item()
		P = W
		W.loc = src
		update_icons()
		return TRUE
	else if(W.has_tool_quality(TOOL_CROWBAR))
		if(P && !locked)
			eject()
			return TRUE
	else if(W.has_tool_quality(TOOL_WRENCH))
		if(P)
			to_chat(user, "<font color='blue'>Remove the phoron tank first.</font>")
			return TRUE
		playsound(src, W.usesound, 75, 1)
		anchored = !anchored
		user.visible_message("[user.name] [anchored? "secures":"unsecures"] the [name].", \
			"You [anchored? "secure":"undo"] the external bolts.", \
			"You hear a ratchet.")
		if(anchored)
			connect_to_network()
		else
			disconnect_from_network()
		return TRUE
	else if(istype(W, /obj/item/weapon/card/id)||istype(W, /obj/item/device/pda))
		if (allowed(user))
			if(active)
				locked = !locked
				to_chat(user, "The controls are now [locked ? "locked." : "unlocked."]")
			else
				locked = FALSE //just in case it somehow gets locked
				to_chat(user, "<font color='red'>The controls can only be locked when the [src] is active.</font>")
		else
			to_chat(user, "<font color='red'>Access denied!</font>")
		return TRUE
	return ..()

/obj/machinery/power/rad_collector/examine(mob/user)
	. = ..()
	if(get_dist(user, src) <= 3)
		. += "The meter indicates that it is collecting [last_power] W."

/obj/machinery/power/rad_collector/ex_act(severity)
	switch(severity)
		if(2, 3)
			eject()
	return ..()


/obj/machinery/power/rad_collector/proc/eject()
	locked = 0
	var/obj/item/weapon/tank/phoron/Z = P
	if (!Z)
		return
	Z.loc = get_turf(src)
	Z.layer = initial(Z.layer)
	P = null
	if(active)
		toggle_power()
	else
		update_icons()

/obj/machinery/power/rad_collector/proc/receive_pulse(var/pulse_strength)
	if(P && active)
		var/power_produced = 0
		power_produced = P.air_contents.gas["phoron"]*pulse_strength*20
		add_avail(power_produced)
		last_power_new = power_produced
		return
	return


/obj/machinery/power/rad_collector/proc/update_icons()
	cut_overlays()
	if(P)
		add_overlay("ptank")
	if(stat & (NOPOWER|BROKEN))
		return
	if(active)
		add_overlay("on")


/obj/machinery/power/rad_collector/proc/toggle_power()
	active = !active
	if(active)
		icon_state = "ca_on"
		flick("ca_active", src)
	else
		icon_state = "ca"
		flick("ca_deactive", src)
	update_icons()
	return
