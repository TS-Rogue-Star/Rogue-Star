/////ISOPODS ARE OUR FRIENDS WE LOVE ISOPODS!!!/////
//RS FILE

/mob/living/simple_mob/vore/isopod
	name = "space isopod"
	desc = "A kind of hard shelled crustacean with many legs and a cute appearance. Known for helping break down decaying matter, and generally being friendly little guys!"
	icon = 'icons/rogue-star/mob_64x32.dmi'
	icon_living = "isopod"
	icon_state = "isopod"
	icon_rest = "isopod_resting"

	faction = "neutral"

	health = 1
	maxHealth = 1

	pixel_x = -16
	default_pixel_x = -16

	var/rolled_up_countdown = 0
	var/isopod_voice_rate = 1
	var/list/isopod_voice_sound_list = list(
			'sound/voice/knuckles.ogg',
			'sound/voice/spiderchitter.ogg',
			'sound/voice/spiderpurr.ogg',
			'sound/voice/wurble.ogg'
		)

	ai_holder_type = /datum/ai_holder/simple_mob/isopod

///// VORE RELATED /////
	vore_active = 1

	swallowTime = 2 SECONDS
	vore_capacity = 2
	vore_bump_chance = 5
	vore_bump_emote	= "greedily homms at"
	vore_digest_chance = 0
	vore_absorb_chance = 0
	vore_escape_chance = 10
	vore_pounce_chance = 5
	vore_ignores_undigestable = 0
	vore_default_mode = DM_SELECT
	vore_icons = SA_ICON_LIVING
	vore_stomach_name = "stomach"
	vore_stomach_flavor = ""
	vore_default_contamination_flavor = "Wet"
	vore_default_contamination_color = "grey"
	vore_default_item_mode = IM_DIGEST

	devourable = TRUE
	digestable = FALSE

	var/obj/belly/leggy_zone

/mob/living/simple_mob/vore/isopod/init_vore()
	..()
	var/obj/belly/b = vore_selected

	//DO THE REST OF THE STOMACH SETUP HERE

	b = new /obj/belly(src)

	b.immutable = TRUE
	b.mode_flags = DM_FLAG_THICKBELLY
	b.human_prey_swallow_time = 0.01 SECONDS
	b.digestchance = 0
	b.digest_brute = 0
	b.digest_burn = 0
	b.absorbchance = 0
	b.escapable = FALSE
	b.escapechance = 0
	b.digest_mode = DM_HEAL
	b.name = "leg dimension"
	b.desc = ""
	b.contaminates = 0
	b.item_digest_mode = IM_HOLD
	b.fancy_vore = 1
	b.vore_verb = "curl"
	leggy_zone = b

/mob/living/simple_mob/vore/isopod/Initialize()
	. = ..()
	resize(rand(75,125) / 100)

/mob/living/simple_mob/vore/isopod/Life()
	. = ..()
	rolled_up_countdown --
	if(!ckey)
		if(resting && rolled_up_countdown <= 0)
			lay_down()
	if(size_multiplier >= 1)
		if(prob(isopod_voice_rate))
			playsound(src, pick(isopod_voice_sound_list), 75, 1, frequency = 15000 / size_multiplier)

/mob/living/simple_mob/vore/isopod/adjustBruteLoss(amount, include_robo)
	if(amount >= 0)
		roll_up()

/mob/living/simple_mob/vore/isopod/adjustFireLoss(amount, include_robo)
	if(amount >= 0)
		roll_up()

/mob/living/simple_mob/vore/isopod/adjustOxyLoss(amount)
	if(amount >= 0)
		roll_up()

/mob/living/simple_mob/vore/isopod/adjustCloneLoss(amount)
	if(amount >= 0)
		roll_up()

/mob/living/simple_mob/vore/isopod/adjustBrainLoss(amount)
	if(amount >= 0)
		roll_up()

/mob/living/simple_mob/vore/isopod/adjustToxLoss(amount)
	if(amount >= 0)
		roll_up()

/mob/living/simple_mob/vore/isopod/adjustHalLoss(amount)
	if(amount >= 0)
		roll_up()

/mob/living/simple_mob/vore/isopod/death()
	roll_up()

/mob/living/simple_mob/vore/isopod/gib()
	roll_up()

/mob/living/simple_mob/vore/isopod/ex_act(severity)
	roll_up()

/mob/living/simple_mob/vore/isopod/lay_down()
	if(resting && rolled_up_countdown > 0)
		resting = TRUE
		to_chat(src, SPAN_DANGER("You can't unroll yet... it's not safe..."))
		return
	if(resting)
		leggy_zone.release_all_contents()
	else
		var/list/potentials = living_mobs(0)
		if(potentials.len)
			for(var/mob/living/target in potentials)
				if(!spont_pref_check(src,target,SPONT_PRED))
					continue
				if(target.incorporeal_move)
					continue
				if(target.buckled)
					target.buckled.unbuckle_mob(target, force = TRUE)
				target.forceMove(leggy_zone)
				to_chat(target,SPAN_WARNING("\The [src] quickly curls up around you!!!"))
	. = ..()

/mob/living/simple_mob/vore/isopod/proc/roll_up()
	health = maxHealth
	lay_down()
	rolled_up_countdown = rand(10,50)

/mob/living/simple_mob/vore/isopod/proc/ate()
	if(prob(25))
		if(size_multiplier < 5)
			resize(size_multiplier + (rand(10,25)/1000), uncapped = TRUE)
		var/obj/item/stack/wetleather/leather = new(get_turf(src), 1)
		leather.name = "isopod shedding"
		visible_message(runemessage = "bwomp")

/datum/ai_holder/simple_mob/isopod
	hostile = TRUE
	retaliate = FALSE
	cooperative = FALSE

	wander = TRUE
	returns_home = FALSE
	handle_corpse = TRUE
	mauling = TRUE
	unconscious_vore = TRUE
	belly_attack = FALSE

	var/item_search_cooldown = 0

/mob/living/simple_mob/vore/isopod/post_digestion()
	resize(size_multiplier + 0.01, uncapped = TRUE)

/datum/ai_holder/simple_mob/isopod/handle_stance_strategical()
	if(holder.resting)	//We are rolled up so don't do it!
		return

	. = ..()

/datum/ai_holder/simple_mob/isopod/proc/can_eat(var/atom/movable/food)
	if(isliving(food))
		var/mob/living/L = food

		if(L.player_login_key_log)
			return FALSE

		if(L.stat != DEAD)
			return FALSE		//We only want dead people

		if(!L.digestable)
			return FALSE

		if(L.faction == holder.faction)
			return FALSE	//We don't want to eat our friends

		var/mob/living/simple_mob/vore/isopod/i = holder	//We are an isopod, if we aren't then I don't know what to tell ya it's probably gonna runtime
		if(!i.will_eat(L))
			return FALSE		//Check prefs first
		return TRUE
	if(istype(food, /obj/item/weapon/reagent_containers/food) || istype(food, /obj/item/trash) || istype(food, /obj/effect/decal/cleanable) || istype(food, /obj/effect/decal/remains))
		return TRUE
	return FALSE

/datum/ai_holder/simple_mob/isopod/can_attack(atom/movable/the_target, vision_required)

	if(!can_eat(the_target)) return FALSE

	return TRUE		//FEED MY PRETTY FEEED

/datum/ai_holder/simple_mob/isopod/list_targets()
	if(world.time >= item_search_cooldown)	//Let's not look for items too often
		. = list()
		item_search_cooldown = world.time + 10 SECONDS
		for(var/obj/O in view(holder, vision_range))
			if(!can_eat(O))	//We only want food or trash
				continue
			. += O	//You left it out so it is mine
	else
		return ..()

/datum/ai_holder/simple_mob/isopod/pre_melee_attack(atom/A)
	if(can_eat(A))
		var/turf/simulated/T = get_turf(A)
		if(!istype(T,/turf/simulated))
			T = null
		if(ismob(A))
			return ..()
		var/delet = FALSE
		if(istype(A, /obj/item/weapon/reagent_containers/food) || istype(A, /obj/item/trash))
			playsound(holder, 'sound/items/eatfood.ogg', 75, 1)
		if(istype(A, /obj/effect/decal/cleanable) || istype(A,/obj/effect/decal/remains))
			playsound(holder, 'sound/items/drop/flesh.ogg', 75, 1)
			delet = TRUE
		var/obj/item/I = A
		var/list/nomverbs = list(
			"eats",
			"scromfs",
			"nibbles up",
			"homphs",
			"cronches",
			"monches",
			"slurps",
			"gulps down",
			"gobbles up",
			"gobbles down",
			"inhales",
			"devours",
			"ingests",
			"partakes of",
			"bolts down",
			"wolfs down",
			"crams down",
			"munches",
			"grazes on",
			"noshes on",
			"scarfs",
			"dines upon",
			"glomps",
			"noms",
			"nom-noms",
			"snacks upon",
			"feasts upon",
			"chows down upon",
			"laps up",
			"packs away"
		)
		holder.visible_message(SPAN_DANGER("\The [holder] happily [pick(nomverbs)] \the [A]!"),runemessage = "! ! !")
		var/mob/living/simple_mob/vore/isopod/H = holder
		H.ate()
		set_stance(STANCE_IDLE)
		if(delet)
			qdel(A)
		else
			I.forceMove(holder.vore_selected)
		if(T)
			T.dirt = 0
		return
	..()
