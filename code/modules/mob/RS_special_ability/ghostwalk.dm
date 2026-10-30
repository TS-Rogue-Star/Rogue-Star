//RS FILE

/mob/living/proc/ghostwalk()
	set name = "Ghost Walk"
	set desc = "Walk like ghost!"
	set category = "Abilities"

	if(stat || restrained()|| stunned || weakened || sleeping || buckled)
		to_chat(src, SPAN_DANGER("You can't do that right now."))
		return
	if(isbelly(loc))
		return
	var/datum/modifier/ghostwalk/mod = get_modifier_of_type(/datum/modifier/ghostwalk)
	if(mod)
		mod.expire()
		return
	if(world.time < last_special)
		to_chat(src, SPAN_WARNING("You can't do that yet!"))
		return
	var/turf/T = get_turf(src)
	if(!T)
		return
	var/lit = T.get_lumcount()
	var/range = world.view
	if(lit <= 0)
		range = 0
	else
		range = round(range *= lit)
	if(range > 0)
		var/list/peepers = oviewers(range,src)
		if(peepers.len > 0)
			var/fail = FALSE
			for(var/mob/living/L in peepers)
				if(!isliving(L))
					continue
				if(L.incorporeal_move)
					continue
				switch(L.dir)
					if(NORTH)
						if(y < L.y)
							continue
					if(SOUTH)
						if(y > L.y)
							continue
					if(EAST)
						if(x < L.x)
							continue
					if(WEST)
						if(x > L.x)
							continue
				if(L.ckey)
					to_chat(src, span_green("You can't do that with \the [L] so close by... Maybe if it was darker, or you got behind them..."))
					fail = TRUE
			if(fail)
				return
	add_modifier(/datum/modifier/ghostwalk)

/datum/modifier/ghostwalk
	name = "Ghostwalk"

/datum/modifier/ghostwalk/New(new_holder, new_origin)
	. = ..()
	var/turf/T = get_turf(holder)
	var/cast_time = 5 SECONDS * T.get_lumcount()

	animate(holder,alpha = 0,time = cast_time)
	if(do_after(holder,cast_time, exclusive = TRUE, exclusive = TRUE))
		if(isbelly(holder.loc))
			expire()
			return
		holder.plane -= 1
		holder.incorporeal_move = 3
		holder.invisibility = INVISIBILITY_SHADEKIN
		holder.see_invisible = INVISIBILITY_SHADEKIN
		holder.see_invisible_default = INVISIBILITY_SHADEKIN
		if(ishuman(holder))
			var/mob/living/carbon/human/H = holder
			H.ability_flags |= AB_PHASE_SHIFTED
		holder.mouse_opacity = FALSE
		holder.alpha = 64
	else
		expire()

/datum/modifier/ghostwalk/expire(silent)
	. = ..()
	holder.incorporeal_move = 0
	holder.invisibility = 0
	holder.see_invisible = SEE_INVISIBLE_LIVING
	holder.see_invisible_default = SEE_INVISIBLE_LIVING
	animate(holder,alpha = 255,time = 2 SECONDS)
	holder.plane = MOB_PLANE
	holder.last_special = world.time + 5 SECONDS
	if(ishuman(holder))
		var/mob/living/carbon/human/H = holder
		H.ability_flags &= ~AB_PHASE_SHIFTED
	holder.mouse_opacity = TRUE

	if(!holder.vore_selected)
		return

	for(var/mob/living/thing in get_turf(holder))
		if(thing == holder)
			continue
		if(!isliving(thing))
			continue
		if(thing.incorporeal_move)
			continue
		if(spont_pref_check(holder,thing,SPONT_PRED))
			to_chat(thing,SPAN_OCCULT("\The [holder] phases in around you, [holder.vore_selected.vore_verb]ing you into their [holder.vore_selected.name]!"))
			thing.forceMove(holder.vore_selected)

/datum/modifier/ghostwalk/proc/consider_turf(var/turf/T)
	if(!T)
		return FALSE
	if(!isturf(T))
		return FALSE
	for(var/thing in T.contents)
		if(istype(thing, /obj/effect/abstract/directional_lighting))
			return TRUE
		if(istype(thing, /obj/item/weapon/flame/candle))
			var/obj/item/weapon/flame/candle/C = thing
			if(C.lit)
				return TRUE
	return FALSE

/turf/Entered(obj/item/I)
	if(istype(I,/obj/effect/abstract/directional_lighting))
		reveal_ghostwalkers()
	. = ..()

/turf/proc/reveal_ghostwalkers()
	for(var/mob/living/L in contents)
		if(!isliving(L))
			continue
		var/datum/modifier/ghostwalk/mod = L.get_modifier_of_type(/datum/modifier/ghostwalk)
		if(mod)
			mod.expire()

/mob/living/is_incorporeal()
	if(incorporeal_move == 3)
		return TRUE
	return FALSE

/obj/item/ghostwalk_orb
	name = "mysterious orb"
	desc = "Spooky!"
	icon = 'icons/rogue-star/misc.dmi'
	icon_state = "orb"

/obj/item/ghostwalk_orb/attack_self(mob/user)
	. = ..()
	user.verbs.Add(/mob/living/proc/ghostwalk)
	to_chat(user, SPAN_OCCULT("\The [src] sinks into your body and becomes one with you... You feel like you have gained a new ability."))
	log_admin("[user] added ghost walk via [type]")
	user.drop_from_inventory(src)
	qdel(src)
