//RS FILE
/mob/living/simple_mob/hostile/seething
	name = "???"
	desc = "Just your average shambling seething horror. You probably don't want this to touch you."
	icon = 'icons/rogue-star/mobx32.dmi'
	icon_state = "seething"

	faction = "seething"

	movement_cooldown = 6
	melee_damage_lower = 1
	melee_damage_upper = 2
	attack_sound = 'sound/weapons/bite.ogg'
	attacktext = list("bitten","chomped","slashed","tackled","slammed")

	maxHealth = 30
	health = 30
	armor = list(
		"melee" = 0,
		"bullet" = 0,
		"laser" = 0,
		"energy" = 0,
		"bomb" = 0,
		"bio" = 0,
		"rad" = 0)

	armor_soak = list(
		"melee" = 0,
		"bullet" = 0,
		"laser" = 0,
		"energy" = 0,
		"bomb" = 0,
		"bio" = 0,
		"rad" = 0
		)

	minbodytemp = -1
	maxbodytemp = 350
	heat_damage_per_tick = 3
	cold_damage_per_tick = 0
	min_oxy = 0
	max_oxy = 0
	min_tox = 0
	max_tox = 0
	min_co2 = 0
	max_co2 = 0
	min_n2 = 0
	max_n2 = 0
	unsuitable_atoms_damage = 0

	ai_holder_type = /datum/ai_holder/seething

/mob/living/simple_mob/hostile/seething/death()
	. = ..()
	new /obj/effect/gibspawner/generic(get_turf(src))
	qdel(src)

/mob/living/simple_mob/hostile/seething/Initialize()
	. = ..()
	var/list/adj = list(
		"shambling",
		"dripping",
		"gnashing",
		"thrashing",
		"moaning",
		"horrifying",
		"glassy eyed",
		"scary",
		"heaving",
		"disgusting",
		"disheveled",
		"charred",
		"twitching"
	)

	name = "[pick(adj)] thing"
	movement_cooldown = rand(5,10)
	default_pixel_x = rand(-10,10)
	pixel_x = default_pixel_x

/mob/living/simple_mob/hostile/seething/apply_melee_effects(atom/A)
	. = ..()
	if(!isliving(A))
		return
	if(prob(10))
		forceMove(get_turf(A))
		var/mob/living/L = A
		visible_message(span_cult("\The [src] latches on to [L]!!!"),runemessage = "C H O M P")
		L.add_modifier(/datum/modifier/latched_on,origin = src)

/mob/living/simple_mob/hostile/seething/glide_for(movetime)
	movetime = 0
	. = ..()

/datum/modifier/latched_on
	var/mob/living/our_origin

/datum/modifier/latched_on/New(new_holder, new_origin)
	. = ..()
	if(!new_origin)
		expire()
		return
	our_origin = new_origin
	holder.say("*scream")
	holder.Stun(2)
	holder.Weaken(3)

/datum/modifier/latched_on/expire(silent)
	. = ..()
	our_origin = null

/datum/modifier/latched_on/tick()
	. = ..()
	if(!our_origin)
		expire()
		return
	if(holder.loc != our_origin.loc)
		expire()
		return

	var/list/verbs = list(
		"bites",
		"gnashes",
		"claws",
		"rams into",
		"tackles",
		"shoves",
		"slashes"
	)

	our_origin.visible_message(span_cult("\The [our_origin] [pick(verbs)] \the [holder]!!!"))

	var/chance = rand(1,100)

	switch(chance)
		if(89,50)
			holder.Weaken(1)
			holder.adjustBruteLoss(1)
		if(49,6)
			holder.Stun(3)
			holder.adjustBruteLoss(5)
			holder.say("*scream")
		if(5,1)
			holder.Stun(5)
			holder.Weaken(5)
			holder.adjustBruteLoss(10)
			holder.say("*scream")
		else
			return

/datum/ai_holder/seething
	hostile = TRUE
	retaliate = TRUE
	can_flee = FALSE
	flee_when_dying = FALSE
	autopilot = TRUE
