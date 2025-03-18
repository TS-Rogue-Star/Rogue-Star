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

	low_priority = FALSE //Intended to be used in places where there may no longer be players, to help clean up after events and stuff

	has_langs = list(LANGUAGE_ANIMAL)
	say_list_type = /datum/say_list/isopod

	health = 1
	maxHealth = 1

	harm_intent_damage = 0
	melee_damage_lower = 1
	melee_damage_upper = 1

	response_help   = "pets"
	response_disarm = "pushes"
	response_harm   = "smacks"

	tt_desc = "Isopoda Extralium"

	pixel_x = -16
	default_pixel_x = -16

	makes_dirt = FALSE	//They clean dirt up, so let's not have them create more in the process

	attacktext = list("nibbled")
	friendly = list("nuzzles", "nibbles", "wiggles its antennae at", "rubs against")

	mob_size = MOB_LARGE
	mob_bump_flag = HEAVY
	mob_swap_flags = ~HEAVY
	mob_push_flags = ~HEAVY

	ai_holder_type = /datum/ai_holder/simple_mob/isopod
	ai_ignores = TRUE

	///// ISOPOD SPECIFIC /////
	var/body_color
	var/under_color
	var/antennae_color
	var/antennae_end_color
	var/eye_color
	var/list/overlays_cache = list()

	var/static/list/p_body_colors = list("#5f3519","#18123a","#462461","#944815","#742e5f")
	var/static/list/p_under_colors = list("#1d120c","#0e0c1a","#160e1d","#1f150f","#1b0d17")
	var/static/list/p_antennae_colors = list("#57003d","#534000","#00054d","#430063","#643900","#cacaca")
	var/static/list/p_antennae_end_colors = list("#ff00b3","#ffc400","#0011ff","#ae00ff","#ff9100")

	var/rolled_up_countdown = 0
	var/isopod_voice_rate = 1
	var/isopod_next_voice = 0
	var/list/isopod_voice_sound_list = list(
			'sound/voice/knuckles.ogg',
			'sound/voice/spiderchitter.ogg',
			'sound/voice/spiderpurr.ogg',
			'sound/voice/wurble.ogg'
		)
	var/isopod_small = FALSE

///// VORE RELATED /////
	vore_active = 1

	swallowTime = 2 SECONDS
	vore_capacity = 2
	vore_bump_chance = 0
	vore_bump_emote	= "greedily homms at"
	vore_digest_chance = 0
	vore_absorb_chance = 0
	vore_escape_chance = 10
	vore_pounce_chance = 0
	vore_ignores_undigestable = 0
	vore_default_mode = DM_SELECT
	vore_icons = SA_ICON_LIVING
	vore_stomach_name = "stomach"
	vore_stomach_flavor = "It's slimy wow!"
	vore_default_contamination_flavor = "Wet"
	vore_default_contamination_color = "grey"
	vore_default_item_mode = IM_DIGEST

	devourable = TRUE
	digestable = FALSE

	var/obj/belly/leggy_zone

/mob/living/simple_mob/vore/isopod/init_vore()
	..()
	var/obj/belly/b = vore_selected
	b.belly_fullscreen = "anibelly"
	b.colorization_enabled = TRUE
	if(antennae_color)
		b.belly_fullscreen_color = antennae_color
	else
		b.belly_fullscreen_color = "#292031"

	//DO THE REST OF THE STOMACH SETUP HERE

	b = new /obj/belly(src)
	leggy_zone = b

	leggy_zone.immutable = TRUE
	leggy_zone.mode_flags = DM_FLAG_THICKBELLY
	leggy_zone.human_prey_swallow_time = 0.01 SECONDS
	leggy_zone.digestchance = 0
	leggy_zone.digest_brute = 0
	leggy_zone.digest_burn = 0
	leggy_zone.absorbchance = 0
	leggy_zone.escapechance = 0
	leggy_zone.digest_mode = DM_HEAL
	leggy_zone.name = "interior"
	leggy_zone.desc = "Welcome to the leggy zone"
	leggy_zone.contaminates = 0
	leggy_zone.item_digest_mode = IM_HOLD
	leggy_zone.fancy_vore = 1
	leggy_zone.vore_verb = "curl"
	leggy_zone.transferlocation = vore_selected.name
	leggy_zone.transferchance = 5
	leggy_zone.escapable = TRUE
	leggy_zone.belly_fullscreen = "squeeze"
	leggy_zone.affects_vore_sprites = TRUE

/mob/living/simple_mob/vore/isopod/New(loc, small, b_color, u_color, a_color, ae_color, e_color)
	. = ..()
	if(small)
		icon = 'icons/rogue-star/mobx32.dmi'
		isopod_small = TRUE
	if(b_color)
		body_color = b_color
	if(u_color)
		under_color = u_color
	if(a_color)
		antennae_color = a_color
	if(ae_color)
		antennae_end_color = ae_color
	if(e_color)
		eye_color = e_color

/mob/living/simple_mob/vore/isopod/Initialize()
	. = ..()
	if(!isopod_small)
		if(prob(25))
			resize(rand(75,125) / 100)
	else
		resize(1)

	do_isopod_coloring()
	if(prob(50))
		do_name()

/mob/living/simple_mob/vore/isopod/proc/do_isopod_coloring()
	if(isopod_small)
		icon = 'icons/rogue-star/mobx32.dmi'
	else
		icon = 'icons/rogue-star/mob_64x32.dmi'

	if(body_color)
		icon_living = "w-isopod"
		icon_state = "w-isopod"
		icon_rest = "w-isopod_resting"
	else
		if(prob(50))
			icon_living = "w-isopod"
			icon_state = "w-isopod"
			icon_rest = "w-isopod_resting"

			if(prob(10))
				body_color = random_color()
			else
				body_color = pick(p_body_colors)

	if(!under_color)
		if(body_color || prob(50))
			if(prob(10))
				under_color = random_color()
			else
				under_color = pick(p_under_colors)

	if(!antennae_color)
		if(body_color || prob(50))

			if(prob(10))
				antennae_color = random_color()
			else
				antennae_color = pick(p_antennae_colors)

	if(!antennae_end_color)
		if(antennae_color || prob(50))
			if(prob(10))
				antennae_end_color = random_color()
			else
				antennae_end_color = pick(p_antennae_end_colors)

	if(!eye_color)
		eye_color = random_color()
	update_icon()

/mob/living/simple_mob/vore/isopod/update_icon()
	. = ..()
	isopod_icon()

	if(resting && leggy_zone.GetFullnessFromBelly())
		icon_state = "[icon_rest]-full"

/mob/living/simple_mob/vore/isopod/Life()
	. = ..()
	rolled_up_countdown --
	if(!ckey)
		if(resting && rolled_up_countdown <= 0)
			lay_down()

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
		if(isopod_small)
			return ..()
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
	if(!resting)
		if(isopod_small)
			playsound(src, 'sound/voice/BugHiss.ogg', 35, 1, frequency = 70000)
		else
			playsound(src, 'sound/voice/BugHiss.ogg', 75, 1, frequency = 15000 / size_multiplier)
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

/mob/living/simple_mob/vore/isopod/proc/isopod_icon()
	cut_overlays()
	consider_isopod_icon()
	if(body_color)
		icon_living = "w-isopod"
		icon_rest = "w-isopod_resting"

	color = body_color

	if(resting || isopod_small)
		return

	var/combine_key
	var/image/our_image

	if(under_color)
		our_image = null
		combine_key = "under-[under_color]"
		our_image = overlays_cache[combine_key]
		if(!our_image)
			our_image = image(icon,null,"w-isopod-under")
			our_image.color = under_color
			our_image.appearance_flags = RESET_COLOR|KEEP_APART|PIXEL_SCALE
			overlays_cache[combine_key] = our_image
		add_overlay(our_image)

	if(antennae_color)
		our_image = null
		combine_key = "antennae-[antennae_color]"
		our_image = overlays_cache[combine_key]
		if(!our_image)
			our_image = image(icon,null,"antennae")
			our_image.color = antennae_color
			our_image.appearance_flags = RESET_COLOR|KEEP_APART|PIXEL_SCALE
			overlays_cache[combine_key] = our_image
		add_overlay(our_image)

	if(antennae_end_color)
		our_image = null
		combine_key = "antennae-end-[antennae_end_color]"
		our_image = overlays_cache[combine_key]
		if(!our_image)
			our_image = image(icon,null,"antennae-end")
			our_image.color = antennae_end_color
			our_image.appearance_flags = RESET_COLOR|KEEP_APART|PIXEL_SCALE
			overlays_cache[combine_key] = our_image
		add_overlay(our_image)

	if(eye_color)
		our_image = null
		combine_key = "eye-[eye_color]"
		our_image = overlays_cache[combine_key]
		if(!our_image)
			our_image = image(icon,null,"w-isopod-eyes")
			our_image.color = eye_color
			our_image.appearance_flags = RESET_COLOR|KEEP_APART|PIXEL_SCALE
			overlays_cache[combine_key] = our_image
		add_overlay(our_image)

	our_image = null
	combine_key = "shine"
	our_image = overlays_cache[combine_key]
	if(!our_image)
		our_image = image(icon,null,"w-isopod-eyeshine")
		our_image.color = "#ffffff"
		our_image.appearance_flags = RESET_COLOR|KEEP_APART|PIXEL_SCALE
		overlays_cache[combine_key] = our_image
	add_overlay(our_image)

/mob/living/simple_mob/vore/isopod/proc/consider_isopod_icon()
	if(isopod_small)
		icon = 'icons/rogue-star/mobx32.dmi'
		mob_size = MOB_TINY
		mob_bump_flag = 0
		mob_swap_flags = 0
		mob_push_flags = 0
		pixel_x = 0
		default_pixel_x = 0

	else
		icon = 'icons/rogue-star/mob_64x32.dmi'
		mob_size = MOB_LARGE
		mob_bump_flag = HEAVY
		mob_swap_flags = ~HEAVY
		mob_push_flags = ~HEAVY
		pixel_x = -16
		default_pixel_x = -16

/mob/living/simple_mob/vore/isopod/proc/vocalize()

	if(size_multiplier >= 1 && !isopod_small)
		playsound(src, pick(isopod_voice_sound_list), 75, 1, frequency = 15000 / size_multiplier)

/mob/living/simple_mob/vore/isopod/post_digestion()
	resize(size_multiplier + 0.01, uncapped = TRUE)

/mob/living/simple_mob/vore/isopod/proc/do_name()
	if(name != initial(name))
		return
	if(name != "space isopod")
		return
	var/list/adjectives = list(
		"rugged",
		"rowdy",
		"pretty",
		"cute",
		"photogenic",
		"zesty",
		"sweet",
		"sour",
		"kind",
		"wise",
		"grouchy",
		"plump",
		"dozey",
		"weird",
		"silly",
		"spicy",
		"cool",
		"cute",
		"dubeous",
		"mischieveous",
		"fussy",
		"pleasant",
		"elderly",
		"anxious",
		"carefree",
		"shy",
		"hyper",
		"lethargic",
		"outrageous",
		"distinguished",
		"pure",
		"cantankerous",
		"suspicious"
	)

	name = "[pick(adjectives)] [name]"

/mob/living/simple_mob/vore/isopod/attack_hand(mob/living/carbon/human/M as mob)
	if(stat == DEAD)
		return ..()
	. = ..()
	if(isopod_small)
		return
	if(client)
		return
	if(!ishuman(M))
		return
	if(M.a_intent == I_HELP)
		if(will_eat(M))
			var/damage = M.getBruteLoss() + M.getFireLoss()
			if(damage >= 5)
				face_atom(M)
				ai_holder.wander_delay = 10	//Don't wander or anything
				to_chat(M,SPAN_WARNING("\The [src] pushes you down!"))
				M.Weaken(10)	//Knock them down for a bit
				spawn(1 SECOND)		//Wait a second for it to sink in
				if(Adjacent(M))		//Only try if they are still next to us
					visible_message(SPAN_WARNING("\The [src] hunkers down over \the [M]!"), runemessage = "! ! !")
					forceMove(get_turf(M))	//Get em!
				spawn(3 SECONDS)	//You got 3 seconds or you are gotten!
				if(M.loc == loc)	//If we're in the same turf, then we can roll up!
					roll_up()		//Gottem
				ai_holder.min_distance_to_destination = initial(ai_holder.min_distance_to_destination)	//Put this back so we don't get stuck too much

/mob/living/simple_mob/vore/isopod/resize(new_size, animate, uncapped, ignore_prefs, aura_animation)
	. = ..()
	if(isopod_small && size_multiplier >= 2)
		isopod_small = FALSE
		resize(0.75)
		update_icon()

	if(!isopod_small && size_multiplier <= 0.25)
		isopod_small = TRUE
		resize(1)
		update_icon()

///////////////////////// MISC STUFF HERE /////////////////////////

/datum/say_list/isopod
	speak = list(". . .", "! ! !", "? ? ?")
	emote_hear = list("clicks", "rumbles", "sings")
	emote_see = list("sways its antennae", "wiggles its antennae", "nibbles something on the floor", "stretches its legs", "hunkers down")
	say_maybe_target = list("? ? ?")
	say_got_target = list("! ! !")

/datum/category_item/catalogue/fauna/isopod
	name = "Alien Wildlife - Isopod"
	desc = "REPLACE ME"
	value = CATALOGUER_REWARD_EASY

/mob/living/simple_mob/vore/isopod/mob_bank_save(mob/living/user)

	var/list/to_save = list(
		"ckey" = user.ckey,
		"type" = type,
		"name" = name,
		"body_color" = body_color,
		"under_color" = under_color,
		"antennae_color" = antennae_color,
		"antennae_end_color" = antennae_end_color,
		"eye_color" = eye_color
		)

	return to_save

/mob/living/simple_mob/vore/isopod/mob_bank_load(mob/living/user, list/load)
	. = ..()

	body_color = load["body_color"]
	under_color = load["under_color"]
	antennae_color = load["antennae_color"]
	antennae_end_color = load["antennae_end_color"]
	eye_color = load["eye_color"]

	update_icon()
	resize(1)

///////////////////////// AI STUFF BELOW HERE /////////////////////////

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

	speak_chance = 1

	var/item_search_cooldown = 0

/datum/ai_holder/simple_mob/isopod/handle_stance_strategical()
	if(holder.resting)	//We are rolled up so don't do it!
		return

	..()

/datum/ai_holder/simple_mob/isopod/handle_idle_speaking()
	. = ..()
	if(!.)
		return
	var/mob/living/simple_mob/vore/isopod/I = holder
	I.vocalize()

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

		var/mob/living/simple_mob/vore/isopod/our_isopod = holder
		if(our_isopod.isopod_small)
			if(L.size_multiplier > 0.35)
				return FALSE

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
		var/cooldown = rand(5,30) SECONDS
		var/mob/living/simple_mob/vore/isopod/our_isopod = holder
		if(our_isopod.isopod_small)
			cooldown *= 2
		item_search_cooldown = world.time + cooldown
		for(var/obj/O in view(holder, 3))
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
			"packs away",
			"schlorps up"
		)
		var/list/emotion = list(
			"happily",
			"gleefully",
			"thoughtfully",
			"ponderously",
			"whistfully",
			"quickly",
			"hungrily",
			"merrily",
			"joyfully",
			"contentedly",
			"elatedly",
			"gladly",
			"mirthfully",
			"elatedly"
		)
		holder.visible_message(SPAN_DANGER("\The [holder] [pick(emotion)] [pick(nomverbs)] \the [A]!"),runemessage = "! ! !")
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

	lose_target()

///////////////////////// CUSTOM VARIANTS /////////////////////////

/mob/living/simple_mob/vore/isopod/small
	icon = 'icons/rogue-star/mobx32.dmi'
	isopod_small = TRUE
	mob_size = MOB_TINY
	mob_bump_flag = 0
	mob_swap_flags = 0
	mob_push_flags = 0
	pixel_x = 0
	default_pixel_x = 0
	low_priority = TRUE

/mob/living/simple_mob/vore/isopod/small/jani
	name = "janitor pet"
	body_color = "#381c4e"
	under_color = "#3a3666"
	eye_color = "#ff00ff"
	antennae_color = "#837e58"
	antennae_end_color = "#8c00ff"
	load_owner = "STATION"

/mob/living/simple_mob/vore/isopod/cass
	body_color = "#612c08"
	under_color = "#c69c85"
	eye_color = "#612c08"
	antennae_color = "#272523"
	antennae_end_color = "#00f7ff"

/mob/living/simple_mob/vore/isopod/lira
	body_color = "#ffffc0"
	under_color = "#fdfae9"
	eye_color = "#1d7fb7"
	antennae_color = "#ffc965"
	antennae_end_color = "#00f7ff"
