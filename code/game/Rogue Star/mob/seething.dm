//RS FILE
/mob/living/simple_mob/hostile/seething
	name = "???"
	desc = "Just your average shambling seething horror. You probably don't want this to touch you."
	icon = 'icons/rogue-star/mobx32.dmi'
	icon_state = "seething"
	icon_dead = "seething_dead"

	faction = "seething"
	load_owner = "seriouslydontsavethis"

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

	ai_holder_type = /datum/ai_holder/seething	//PUT THIS BACK
	particles = new/particles/seething

/mob/living/simple_mob/hostile/seething/death()
	. = ..()
	new /obj/particle_emitter/seething/limited(get_turf(src))
	new /obj/effect/decal/cleanable/blood/gibs/core(get_turf(src))
	mouse_opacity = FALSE
	name = "dust"
	plane = DECAL_PLANE
	layer = DECAL_LAYER

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

///SPAWNER///

/mob/living/simple_mob/hostile/seething_spawner
	name = "???"
	desc = "Your head aches to behold this thing. It appears to be emanating an enormous amount of energy."
	icon = 'icons/rogue-star/mobx128.dmi'
	icon_state = "horrible"

	faction = "seething"
	density = FALSE
	plane = PLANE_LIGHTING_ABOVE

	pixel_x = -48
	default_pixel_x = -48

	movement_cooldown = 6
	melee_damage_lower = 0
	melee_damage_upper = 0
	attack_sound = 'sound/weapons/bite.ogg'
	attacktext = list("bitten","chomped","slashed","tackled","slammed")
	maxHealth = 500
	health = 500
	movement_cooldown = 999999
	grab_resist = 100
	devourable = FALSE
	load_owner = "seriouslydontsavethis"

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

	projectiletype = /obj/item/projectile/red_energy
	projectilesound = 'sound/weapons/Laser.ogg'
	projectile_dispersion = 10
	needs_reload = TRUE
	reload_max = 7
	reload_time = 10 SECONDS

	ai_holder_type = /datum/ai_holder/seething
	particles = new/particles/seething/active

/mob/living/simple_mob/hostile/seething_spawner/adjustBruteLoss(amount, include_robo)
	. = ..()
	if(amount > 0)
		if(prob(25))
			warp()
/mob/living/simple_mob/hostile/seething_spawner/adjustFireLoss(amount, include_robo)
	. = ..()
	if(amount > 0)
		if(prob(25))
			warp()

/mob/living/simple_mob/hostile/seething_spawner/death()
	. = ..()
	lightning_strike(get_turf(src),TRUE)
	new /obj/particle_emitter/seething/limited(get_turf(src))
	mouse_opacity = FALSE
	name = "dust"

/mob/living/simple_mob/hostile/seething_spawner/Initialize()
	. = ..()
	var/list/adj = list(
		"terrifying",
		"horrifying",
		"horrible",
		"terrible",
		"singing",
		"radiant"
	)

	name = "[pick(adj)] thing"

/mob/living/simple_mob/hostile/seething_spawner/Life()
	. = ..()
	if(prob(10))
		var/turf/T = get_turf(src)
		if(T.check_density(FALSE,TRUE))
			return
		new /mob/living/simple_mob/hostile/seething(T)

/mob/living/simple_mob/hostile/seething_spawner/try_reload()
	warp(FALSE)
	. = ..()

/mob/living/simple_mob/hostile/seething_spawner/proc/warp(var/do_spawn = TRUE)
	var/turf/T = get_turf(src)
	var/turf/destination = find_clear_turf()
	lightning_strike(T,TRUE)
	if(do_spawn && prob(25))
		spawn_seething()
	if(isturf(destination))
		visible_message(SPAN_WARNING("\The [src] disappears!"))
		forceMove(destination)
		visible_message(SPAN_WARNING("\The [src] reappears!"))
		lightning_strike(destination,TRUE)

/mob/living/simple_mob/hostile/seething_spawner/proc/spawn_seething()
	var/howmany = rand(1,5)
	var/where = get_turf(src)
	if(!where)
		return
	while(howmany > 0)
		new /mob/living/simple_mob/hostile/seething(where)
		howmany --

/mob/living/simple_mob/hostile/seething_spawner/proc/find_clear_turf(var/checks = 0)
	var/turf/T = locate(x + rand(-7,7),y + rand(-7,7),z)
	checks ++
	if(T.check_density(FALSE, FALSE) || isspace(T))
		if(checks < 10)
			return find_clear_turf()
		return FALSE

	return T

///PARTICLES///

/particles/seething
	icon = 'icons/rogue-star/smokepuff.dmi'
	icon_state = list("s1","s2","s3","s4","s5","s6","s7","s8")
	width = 500     // 500 x 500 image to cover a moderately sized map
	height = 800
	count = 100
	spawning = 0	// per 0.1s
	bound1 = list(-1000, -300, -1000)   // end particles at Y=-300
	lifespan = 10
	position = list(0,0,0)
	gravity = list(0, 10)
	friction = 0.1
	drift = generator("sphere", 0, 5)
	fade = 1.5 SECONDS
	velocity = generator("vector",list(-50,0),list(50,0))
	spin = generator("num", -100,100)

/particles/seething/active
	spawning = 6

/obj/particle_emitter/seething
	particles = new/particles/seething/active
/obj/particle_emitter/seething/limited
	lifespan = 2

/obj/item/projectile/red_energy
	name = "???"
	icon_state = "red_pellet"
	damage = 5
	damage_type = BURN
	range = 10
	penetrating = TRUE
	check_armour = "melee"
	combustion = FALSE
	homing = TRUE
	speed = 2
