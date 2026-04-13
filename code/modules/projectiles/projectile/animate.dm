/obj/item/projectile/animate
	name = "bolt of animation"
	icon_state = "ice_1"
	damage = 0
	damage_type = BURN
	nodamage = 1
	check_armour = "energy"
	light_range = 2
	light_power = 0.5
	light_color = "#55AAFF"
	combustion = FALSE
	var/static/list/protected_objects = list() // RS Add: Animate staff fix (Lira, April 2026)

// RS Edit: Animate staff fix (Lira, April 2026)
/obj/item/projectile/animate/Bump(var/atom/change)
	if(try_animate(change))
		return TRUE
	return ..()

// RS Edit: Animate staff fix (Lira, April 2026)
/obj/item/projectile/animate/proc/try_animate(var/atom/change)
	if(!((istype(change, /obj/item) || istype(change, /obj/structure)) && !is_type_in_list(change, protected_objects)))
		return FALSE

	var/obj/O = change
	if(!isturf(O.loc))
		return FALSE

	on_impact(O)
	new /mob/living/simple_mob/hostile/mimic/copy(O.loc, O, firer)
	qdel(src)
	return TRUE
