//This file was auto-corrected by findeclaration.exe on 25.5.2012 20:42:33

/obj/machinery/containment_field
	name = "Containment Field"
	desc = "An energy field."
	icon = 'icons/obj/machines/power/singularity/field_generator.dmi'
	icon_state = "Contain_F"
	anchored = TRUE
	density = FALSE
	unacidable = TRUE
	use_power = USE_POWER_OFF
	light_on = TRUE
	light_range = 2
	light_power = 0.5
	light_color = "#5BA8FF"
	var/obj/machinery/field_generator/FG1 = null
	var/obj/machinery/field_generator/FG2 = null
	var/list/shockdirs
	var/hasShocked = FALSE //Used to add a delay between shocks. In some cases this used to crash servers by spawning hundreds of sparks every second.
	plane = PLANE_LIGHTING_ABOVE

/obj/machinery/containment_field/Initialize()
	. = ..()
	shockdirs = list(turn(dir,90),turn(dir,-90))
	sense_proximity(callback = /atom/proc/HasProximity)

/obj/machinery/containment_field/set_dir(new_dir)
	. = ..()
	if(.)
		shockdirs = list(turn(dir,90),turn(dir,-90))

/obj/machinery/containment_field/Destroy()
	unsense_proximity(callback = /atom/proc/HasProximity)
	if(FG1 && !FG1.clean_up)
		FG1.cleanup()
	if(FG2 && !FG2.clean_up)
		FG2.cleanup()
	. = ..()

/obj/machinery/containment_field/attack_hand(mob/user as mob)
	if(get_dist(src, user) > 1)
		return FALSE
	else
		shock(user)
		return TRUE


/obj/machinery/containment_field/ex_act(severity)
	return FALSE

/obj/machinery/containment_field/Crossed(mob/living/L)
	if(!istype(L) || L.incorporeal_move)
		return
	shock(L)

/obj/machinery/containment_field/HasProximity(turf/T, atom/movable/AM, old_loc)
	if(!istype(AM, /mob/living) || AM:incorporeal_move)
		return FALSE
	if(!(get_dir(src,AM) in shockdirs))
		return FALSE
	if(issilicon(AM) ? prob(40) : prob(50))
		shock(AM)
		return TRUE
	return FALSE

/obj/machinery/containment_field/shock(mob/living/user as mob)
	if(hasShocked)
		return FALSE
	if(!FG1 || !FG2)
		qdel(src)
		return FALSE
	if(isliving(user))
		hasShocked = TRUE
		var/shock_damage = min(rand(30,40),rand(30,40))
		user.electrocute_act(shock_damage, src, 1, BP_TORSO)

		var/atom/target = get_edge_target_turf(user, get_dir(src, get_step_away(user, src)))
		user.throw_at(target, 200, 4)

		sleep(20)

		hasShocked = FALSE

/obj/machinery/containment_field/proc/set_master(var/master1,var/master2)
	if(!master1 || !master2)
		return FALSE
	FG1 = master1
	FG2 = master2
	return TRUE
