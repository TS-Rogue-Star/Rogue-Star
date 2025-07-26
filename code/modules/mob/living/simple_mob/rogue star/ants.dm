//This is why we can't have nice things!
/mob/living/simple_mob/vore/ant
	name = "ant"
	desc = "Just a little guy!"
	icon = 'icons/rogue-star/mobx32.dmi'
	icon_living = "ant"
	icon_state = "ant"
	icon_dead = "ant_dead"
	maxHealth = 5
	health = 5
	melee_damage_upper = 5
	melee_damage_lower = 0

	mob_size = MOB_TINY
	mob_always_swap = TRUE
	mob_bump_flag = null
	mob_swap_flags = 0
	mob_push_flags = 0

	ai_holder_type = /datum/ai_holder/simple_mob/ant

	var/queen = 0	//Extra stuff gets considered if this is true
	var/list/overlays_cache = list()	//Holds on to eyes and crowns mostly
	var/team_color = null				//Just to keep track, gets converted to color
	var/eye_color = null				//Keeps track of eye color for sprite building

	vore_active = 1

	swallowTime = 2 SECONDS
	vore_capacity = 2
	vore_bump_chance = 0
	vore_digest_chance = 0
	vore_absorb_chance = 0
	vore_escape_chance = 10
	vore_pounce_chance = 0
	vore_ignores_undigestable = 0
	vore_default_mode = DM_DIGEST
	vore_icons = SA_ICON_LIVING
	vore_stomach_name = "stomach"
	vore_stomach_flavor = "ant tummy!!!"
	vore_default_contamination_flavor = "Wet"
	vore_default_contamination_color = "grey"
	vore_default_item_mode = IM_DIGEST

	devourable = TRUE

/mob/living/simple_mob/vore/ant/init_vore()
	..()
	var/obj/belly/b = vore_selected
	b.belly_fullscreen = "anibelly"
	b.colorization_enabled = TRUE
	b.belly_fullscreen_color = "#292031"

	b.selective_preference = DM_DIGEST
	b.digest_brute = 0.1
	b.digest_burn = 0.1
	b.mode_flags = DM_FLAG_THICKBELLY | DM_FLAG_NUMBING

/mob/living/simple_mob/vore/ant/New(newloc,var/team,var/oureyes)
	. = ..()
	if(team)
		team_color = team
	if(oureyes)
		eye_color = oureyes
	if(!team_color)
		team_color = pick(list("#640a06","#1f1f33","#d4ac3d","#183d1d"))

	faction = team_color
	color = team_color
	if(!eye_color)
		eye_color = random_color()
	update_icon()

/mob/living/simple_mob/vore/ant/death(var/squish = FALSE)
	. = ..()
	new /obj/effect/decal/cleanable/bug_remains(src.loc)
	qdel(src)

/mob/living/simple_mob/vore/ant/examine(mob/user)
	. = ..()
	if(queen > 0)
		. += SPAN_NOTICE("She appears to be wearing [queen] crowns.")

/mob/living/simple_mob/vore/ant/proc/ant_stun(var/mob/living/prey)
	if(!will_eat(prey))
		return FALSE
	if(z != prey.z)
		return FALSE
	prey.Weaken(10)

/mob/living/simple_mob/vore/ant/proc/queen_me()
	var/mob/living/simple_mob/vore/ant/queen/Q = new(get_turf(src),team_color,eye_color)
	Q.dir = dir
	qdel(src)

/mob/living/simple_mob/vore/ant/update_icon()
	. = ..()
	cut_overlays()
	if(stat == DEAD)
		return
	if(team_color)
		color = team_color

	var/combine_key
	var/image/our_image
	our_image = null

	//eyes first
	combine_key = "eye-[eye_color]-[queen]"
	our_image = overlays_cache[combine_key]
	if(!our_image)
		our_image = image(icon,null,"ant_eyes")
		our_image.color = eye_color
		our_image.appearance_flags = RESET_COLOR|KEEP_APART|PIXEL_SCALE
		overlays_cache[combine_key] = our_image
	add_overlay(our_image)

	if(queen > 0)	//crown
		our_image = null
		combine_key = "crown[queen]"
		our_image = overlays_cache[combine_key]
		if(!our_image)
			var/ourcrown
			switch(queen)
				if(1)
					ourcrown = "queen_crown"
				if(2)
					ourcrown = "double_queen_crown"
				if(3)
					ourcrown = "triple_queen_crown"
				if(4 to INFINITY)
					ourcrown = "quadruple_queen_crown"
				else
					ourcrown = null
			if(ourcrown)
				our_image = image(icon,null,ourcrown)
				our_image.appearance_flags = RESET_COLOR|KEEP_APART|PIXEL_SCALE
				overlays_cache[combine_key] = our_image
				add_overlay(our_image)

	pixel_x = default_pixel_x

/mob/living/simple_mob/vore/ant/can_eat(var/atom/movable/food)
	if(food.z != z)
		return FALSE
	if(istype(food, /obj/item/weapon/reagent_containers/food))
		return TRUE
	return FALSE

//Squish code from cockroach.dm
/mob/living/simple_mob/vore/ant/Crossed(var/atom/movable/AM)
	if(queen)
		return FALSE
	if(stat == DEAD)
		return TRUE
	if(istype(AM,/mob/living/simple_mob/vore/ant))
		return FALSE
	if(isliving(AM))
		var/mob/living/A = AM
		if(A.is_incorporeal())
			return
		if(A.mob_size <= mob_size)
			return
		if(A.size_multiplier <= 0.5)
			return
		if(prob(33))
			A.visible_message("<span class='notice'>[A] squashed [src].</span>", "<span class='notice'>You squashed [src].</span>")
			spawn(0)
			death(TRUE)
		else
			visible_message("<span class='notice'>[src] avoids getting crushed.</span>")
	else
		if(isstructure(AM))
			if(prob(33))
				AM.visible_message("<span class='notice'>[src] was crushed under [AM].</span>")
				spawn(0)
				death(TRUE)
			else
				visible_message("<span class='notice'>[src] avoids getting crushed.</span>")
	return ..()

/mob/living/simple_mob/vore/ant/queen
	name = "queen ant"
	desc = "So regal!"
	icon = 'icons/rogue-star/mob_64x32.dmi'
	icon_state = "queen"
	icon_living = "queen"
	icon_dead = "queen_dead"
	queen = 1

	mob_size = MOB_LARGE
	mob_bump_flag = HEAVY
	mob_swap_flags = ~HEAVY
	mob_push_flags = ~HEAVY
	mob_always_swap = FALSE
	pixel_x = -16
	default_pixel_x = -16
	maxHealth = 500
	health = 500
	melee_damage_upper = 10
	melee_damage_lower = 1

/mob/living/simple_mob/vore/ant/red/team_color = "#640a06"
/mob/living/simple_mob/vore/ant/black/team_color = "#1f1f33"
/mob/living/simple_mob/vore/ant/yellow/team_color = "#d4ac3d"
/mob/living/simple_mob/vore/ant/green/team_color = "#183d1d"

//AI STUFF mostly stolen from isopods

/datum/ai_holder/simple_mob/ant
	hostile = TRUE
	retaliate = TRUE
	cooperative = FALSE

	wander = TRUE
	returns_home = FALSE
	belly_attack = FALSE

	speak_chance = 1

	violent_breakthrough = FALSE

	var/item_search_cooldown = 0

/datum/ai_holder/simple_mob/ant/can_attack(atom/movable/the_target, vision_required)

	var/mob/living/simple_mob/vore/ant/our_ant = holder

	if(isliving(the_target))
		if(!handle_corpse)
			var/mob/living/L = the_target
			if(L.stat)
				return FALSE
		if(istype(the_target,/mob/living/simple_mob/vore/ant))
			var/mob/living/simple_mob/vore/ant/target_ant = the_target
			if(target_ant.faction == our_ant.faction)
				return FALSE
			else return TRUE
		else if(check_attacker(the_target)) return TRUE
		else return FALSE
	else if(!our_ant.can_eat(the_target)) return FALSE

	return TRUE		//FEED MY PRETTY FEEED

/datum/ai_holder/simple_mob/ant/list_targets()
	if(world.time >= item_search_cooldown)	//Let's not look for items too often
		. = list()
		var/cooldown = rand(5,30) SECONDS
		var/mob/living/simple_mob/vore/ant/our_ant = holder
		item_search_cooldown = world.time + cooldown
		for(var/obj/O in view(holder, 3))
			if(!our_ant.can_eat(O))	//We only want food
				continue
			. += O	//You left it out so it is mine
	else
		return ..()

/datum/ai_holder/simple_mob/ant/pre_melee_attack(atom/A)
	if(istype(A,/mob/living/simple_mob/vore/ant))
		var/mob/living/simple_mob/vore/ant/ourant = holder
		if(prob(25))
			if(ourant.ant_stun(A))
				return
	return ..()

/datum/ai_holder/simple_mob/ant/on_attacked(atom/movable/AM)
	. = ..()
	var/mob/living/simple_mob/vore/ant/ourant = holder
	if(ourant.queen)	//Oh you attacked the queen?
		for(var/mob/living/simple_mob/S in oview(20,get_turf(src)))	//Get rekt
			if(!istype(S,/mob/living/simple_mob/vore/ant) || S.faction != ourant.faction)
				return
			if(S.ai_holder)
				S.ai_holder.add_attacker(AM)	//All of the ants near her will remember you until they die now
				S.ai_holder.give_target(AM)		//Also they all are rapidly approaching your location.
