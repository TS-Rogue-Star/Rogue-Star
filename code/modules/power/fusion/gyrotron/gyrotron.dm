
GLOBAL_LIST_EMPTY(gyrotrons)

/obj/machinery/power/emitter/gyrotron
	name = "gyrotron"
	icon = 'icons/obj/machines/power/fusion.dmi'
	desc = "It is a heavy duty industrial gyrotron suited for powering fusion reactors."
	icon_state = "emitter-off"
	req_access = list(access_engine)
	use_power = USE_POWER_IDLE
	active_power_usage = 50 KILOWATTS

	circuit = /obj/item/weapon/circuitboard/gyrotron

	var/id_tag
	var/rate = 3
	var/mega_energy = 1
	///Seconds before the next shot
	fire_delay = 20 SECONDS
	///Max delay before firing
	maximum_fire_delay = 20 SECONDS
	///Min delay before firing
	minimum_fire_delay = 2 SECONDS
	can_change_cable_layer = TRUE


/obj/machinery/power/emitter/gyrotron/anchored
	anchored = TRUE
	state = EMITTER_STATE_WELDED

/obj/machinery/power/emitter/gyrotron/Initialize()
	GLOB.gyrotrons += src
	default_apply_parts()
	return ..()

/obj/machinery/power/emitter/gyrotron/Destroy()
	GLOB.gyrotrons -= src
	return ..()

/obj/machinery/power/emitter/gyrotron/proc/set_beam_power(var/new_power)
	mega_energy = new_power
	update_active_power_usage(mega_energy * initial(active_power_usage))

/obj/machinery/power/emitter/gyrotron/fire_beam(mob/user)
	var/obj/item/projectile/projectile = new projectile_type(get_turf(src))
	playsound(src, 'sound/weapons/emitter.ogg', 25, 1)
	if(prob(35))
		var/datum/effect/effect/system/spark_spread/s = new /datum/effect/effect/system/spark_spread
		s.set_up(5, 1, src)
		s.start()
	projectile.firer = src
	projectile.damage = mega_energy * 50
	projectile.fire(dir2angle(dir))
	last_shot = world.time
	if(shot_number < 3)
		fire_delay = 200
		shot_number ++
	else
		fire_delay = (rand(minimum_fire_delay,maximum_fire_delay) * 10)
		shot_number = 0
	return projectile

/obj/machinery/power/emitter/gyrotron/update_icon()
	if (active && powernet && avail(active_power_usage))
		icon_state = "emitter-on"
	else
		icon_state = "emitter-off"

/obj/machinery/power/emitter/gyrotron/attackby(var/obj/item/W, var/mob/user)
	if(W.has_tool_quality(TOOL_MULTITOOL))
		var/new_ident = tgui_input_text(usr, "Enter a new ident tag.", "Gyrotron", id_tag, MAX_NAME_LEN)
		new_ident = sanitize(new_ident,MAX_NAME_LEN)
		if(new_ident && user.Adjacent(src))
			id_tag = new_ident
		return

	if(default_deconstruction_screwdriver(user, W))
		return
	if(default_deconstruction_crowbar(user, W))
		return
	if(default_part_replacement(user, W))
		return

	return ..()
