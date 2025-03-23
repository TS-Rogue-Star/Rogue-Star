/////ISOPODS ARE OUR FRIENDS WE LOVE ISOPODS!!!/////
//RS FILE

/mob/living/simple_mob/vore/isopod
	name = "isopod"
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

	holder_type = null

	ai_holder_type = /datum/ai_holder/simple_mob/isopod
	ai_ignores = TRUE

	catalogue_data = list(/datum/category_item/catalogue/fauna/isopod)

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
	var/isopod_setup = FALSE
	var/isopod_clean_duration = 2

///// VORE RELATED /////
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
	vore_stomach_flavor = "The slimy flesh of the isopod's stomach presses in tightly around you, churning inward with a hungry insistence! A heavy pressure squeezes and throbs around you, forming to your shape and keeping you neatly packed within the creature. It may come as something of a surprise, that despite being on the inside, it is only just comfortably warm inside, so rather than an oppressive atmosphere, it's actually kind of snug, like a big hug. Of course, those walls are squeezing and working over you quite forcefully, so who knows how safe it is, the creature's organ seems very insistent about how it is churning and clinging to you..."
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

	if(isopod_small)
		can_be_drop_pred = FALSE

	b.selective_preference = DM_DIGEST
	b.digest_brute = 0.05
	b.digest_burn = 0.05
	b.mode_flags = DM_FLAG_THICKBELLY | DM_FLAG_NUMBING

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
	leggy_zone.desc = "Caught at the center of the isopod's curl, you find yourself surrounded by many legs! Fourteen, in fact, all pressing close and wrapped around you to hold you close against its tummy! The soft underbelly of the isopod smooshes against you as you are forced to curl up against it, and with how the isopod curls around you like it does, that means that the soft squishy underside of the creature presses to you on just about all sides! It is a confusing place to be stuck! As you settle here, you notice that the head of the creature laps at any scrapes or injuries it, and you may have taken! Aches and pains soothe away as it does so. There doesn't seem to be any easy way out of here though, and who knows, squirming to try to get away while the creature's mouth is so close by may not be the most wise..."
	leggy_zone.contaminates = 0
	leggy_zone.item_digest_mode = IM_HOLD
	leggy_zone.fancy_vore = 1
	leggy_zone.vore_verb = "curl"
	leggy_zone.transferlocation = vore_selected.name
	leggy_zone.transferchance = 5
	leggy_zone.escapable = TRUE
	leggy_zone.belly_fullscreen = "squeeze"
	leggy_zone.affects_vore_sprites = TRUE
	leggy_zone.is_wet = FALSE
	leggy_zone.wet_loop = FALSE
	leggy_zone.vore_sound = "None"
	leggy_zone.release_sound = "None"

	leggy_zone.struggle_messages_outside = list(
		"%pred wobbles a bit as something shifts inside.",
		"%pred's form shifts a bit as something moves about their center.",
		"%pred's body rolls slightly as something struggles inside."
		)

	leggy_zone.struggle_messages_inside = list(
		"As you struggle %pred's many legs attempt to hold you a little closer to their tummy!",
		"When you shift in its hold, %pred seems to chitter anxiously...",
		"While you struggle %pred holds you more tightly!",
		"When you try to squirm, %pred gives you many soothing pats!",
		"It's so cramped and tight that it's hard to move at all without being squeezed!"
	)

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

	do_isopod_coloring()
	do_name()
	if(isopod_small) return
	if(prob(25))
		resize(rand(75,125) / 100)


/mob/living/simple_mob/vore/isopod/proc/do_isopod_coloring()
	if(isopod_small)
		icon = 'icons/rogue-star/mobx32.dmi'
	else
		icon = 'icons/rogue-star/mob_64x32.dmi'

	if(isopod_setup)
		update_icon()
		return

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

		visible_message(SPAN_WARNING("\The [src] rolls up protectively!!!"),runemessage = "! ! !")
	health = maxHealth
	lay_down()
	rolled_up_countdown = rand(10,50)

/mob/living/simple_mob/vore/isopod/proc/ate()
	var/howmuch = 25
	if(isopod_small)
		howmuch = 50
	if(prob(howmuch))
		if(size_multiplier < 5)
			howmuch = rand(10,25)
			if(isopod_small)
				howmuch *= 0.01
			else
				howmuch *= 0.001
			resize(size_multiplier + howmuch, uncapped = TRUE)
		var/obj/item/stack/wetleather/leather = new(get_turf(src), 1)
		leather.name = "isopod shedding"
		visible_message(runemessage = "bwomp")

/mob/living/simple_mob/vore/isopod/proc/isopod_icon()
	cut_overlays()
	consider_isopod_icon()

	if(body_color)
		color = body_color

	if(resting)
		return

	icon_state = icon_living

	if(isopod_small)
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
		mob_always_swap = TRUE
		mob_bump_flag = null
		mob_swap_flags = 0
		mob_push_flags = 0
		pixel_x = 0
		default_pixel_x = 0
	else
		icon = 'icons/rogue-star/mob_64x32.dmi'
		mob_size = MOB_LARGE
		mob_always_swap = FALSE
		mob_bump_flag = HEAVY
		mob_swap_flags = ~HEAVY
		mob_push_flags = ~HEAVY
		pixel_x = -16
		default_pixel_x = -16

	if(body_color)
		icon_living = "w-isopod"
		icon_rest = "w-isopod_resting"
	else
		icon_living = "isopod"
		icon_rest = "isopod_resting"

/mob/living/simple_mob/vore/isopod/proc/vocalize()

	if(size_multiplier >= 1 && !isopod_small)
		playsound(src, pick(isopod_voice_sound_list), 75, 1, frequency = 15000 / size_multiplier)

/mob/living/simple_mob/vore/isopod/post_digestion()
	resize(size_multiplier + 0.01, uncapped = TRUE)

/mob/living/simple_mob/vore/isopod/proc/do_name()
	if(name != initial(name))
		return
	if(name != "isopod")
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
		"suspicious",
		"space",
		"starry eyed",
		"scrungly",
		"attractive",
		"powerful"
	)

	name = "[pick(adjectives)] [name]"

/mob/living/simple_mob/vore/isopod/attack_hand(mob/living/carbon/human/M as mob)
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

/mob/living/simple_mob/vore/isopod/attackby(obj/item/O, mob/user)

	visible_message(SPAN_NOTICE("\The [user] offers [O] to \the [src]..."))
	user.drop_from_inventory(O)
	if(!eat_object(O))
		if(O.z == z)
			visible_message(SPAN_WARNING("\The [src] doesn't seem interested..."), runemessage = ". . .")
		if(isliving(O.loc))
			visible_message(SPAN_DANGER("\The [src] looks at \the [O.loc] sadly as \the [O] is taken away. . ."), runemessage = ". . .")
			return
	else return

	. = ..()

/mob/living/simple_mob/vore/isopod/resize(new_size, animate, uncapped, ignore_prefs, aura_animation)
	. = ..()
	if(isopod_small && size_multiplier >= 2)
		isopod_small = FALSE
		resize(1)
		update_icon()
		holder_type = null
		if(!client)
			can_be_drop_pred = TRUE

	if(!isopod_small && size_multiplier <= 0.25)
		isopod_small = TRUE
		resize(1)
		update_icon()
		holder_type = /obj/item/weapon/holder/isopod
		if(!client)
			can_be_drop_pred = FALSE

/mob/living/simple_mob/vore/isopod/get_effective_size(micro)
	if(isopod_small)
		return size_multiplier * 0.25
	else return ..()

/mob/living/simple_mob/vore/isopod/can_eat(var/atom/movable/food)
	if(food.z != z)
		return FALSE
	if(isliving(food))
		var/mob/living/L = food

		if(L.player_login_key_log)
			return FALSE

		if(L.stat != DEAD)
			return FALSE		//We only want dead people

		if(!L.digestable)
			return FALSE

		if(L.faction == faction)
			return FALSE	//We don't want to eat our friends

		if(!will_eat(L))
			return FALSE		//Check prefs first

		if(isopod_small)
			if(L.size_multiplier > 0.35)
				return FALSE

		return TRUE
	if(istype(food, /obj/item/weapon/reagent_containers/food) || istype(food, /obj/item/trash) || istype(food, /obj/effect/decal/cleanable) || istype(food, /obj/effect/decal/remains))
		return TRUE
	return FALSE

/mob/living/simple_mob/vore/isopod/proc/eat_object(atom/A)
	if(can_eat(A))
		var/turf/simulated/T = get_turf(A)
		if(!istype(T,/turf/simulated))
			T = null
		if(ismob(A))
			return FALSE
		ai_holder.set_busy(TRUE)
		visible_message(SPAN_WARNING("\The [src] approaches \the [A]. . . "), runemessage = ". . .")

		var/howlong = isopod_clean_duration SECONDS
		var/ourvol = 75
		if(isopod_small)
			howlong *= 2
			ourvol *= 0.5
		if(!do_after(src,howlong,A,exclusive = TRUE))
			ai_holder.set_busy(FALSE)
			ai_holder.lose_target()
			return FALSE

		if(resting || A.z != z || !Adjacent(A))
			ai_holder.set_busy(FALSE)
			ai_holder.lose_target()
			return FALSE

		var/delet = FALSE
		if(istype(A, /obj/item/weapon/reagent_containers/food) || istype(A, /obj/item/trash))
			playsound(src, 'sound/items/eatfood.ogg', ourvol, 1)
		if(istype(A, /obj/effect/decal/cleanable) || istype(A,/obj/effect/decal/remains))
			playsound(src, 'sound/items/drop/flesh.ogg', ourvol, 1)
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
		visible_message(SPAN_DANGER("\The [src] [pick(emotion)] [pick(nomverbs)] \the [A]!"),runemessage = "! ! !")
		ate()
		ai_holder.set_stance(STANCE_IDLE)
		if(delet)
			qdel(A)
		else
			I.forceMove(vore_selected)
		if(T)
			T.dirt = 0
		ai_holder.set_busy(FALSE)
		ai_holder.lose_target()
		return TRUE
	else
		ai_holder.lose_target()
		return FALSE

///////////////////////// MISC STUFF HERE /////////////////////////

/datum/say_list/isopod
	speak = list(". . .", "! ! !", "? ? ?")
	emote_hear = list("clicks", "rumbles", "sings")
	emote_see = list("sways its antennae", "wiggles its antennae", "nibbles something on the floor", "stretches its legs", "hunkers down")
	say_maybe_target = list("? ? ?")
	say_got_target = list("! ! !")

/datum/category_item/catalogue/fauna/isopod
	name = "Alien Wildlife - Isopod"
	desc = "Isopoda Extralium is a species of hard bodied crustacean found on some worlds. These creatures are notable for their extreme durability, \
	and their passiveness. When they detect danger, they will curl up on themselves to protect their more fragile parts. While curled up, they can \
	secrete a fluid from specialized glands with restorative properties. These creatures can also enter a form of long hibernation if their environment \
	is unsuitable, and will wake up when they end up somewhere more suitable. In response to being attacked, rather than attempting any form of retaliation, \
	the creatures will simply curl up and ignore its attackers. Isopoda Extralium survives off of dead and decaying matter, trash, and general foodstuffs. \
	While they have the capacity to devour large creatures, they will not ordinarily eat any living thing on purpose. Dead things on the other hand, they relish. \
	As they feed, Isopoda Extralium will slowly grow in size and shed their exoskeleton. When they get to their full grown size, they can be quite imposing and \
	difficult to move, especially large specimens presence can cause obstruction. Their shed exoskeleton can be dried out as a form of leather. \
	While Isopoda Extralium seems to care little for involving itself with living things, it does seem to have some capacity to understand and assist with injury, \
	as contacting it while injured can cause it to curl up around the injured person, and use its own restorative fluids to help them too. \
	It should be noted that, once trapped inside of its curled up shell, it is difficult to escape until it uncurls. Overall, despite its potentially \
	imposing figure, these creatures are considered harmless and helpful."
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
	isopod_setup = TRUE
	update_icon()
	resize(1)

/obj/item/weapon/holder/isopod
	icon = 'icons/rogue-star/mobx32.dmi'
	icon_state = "isopod_holder"
	desc = "Isopoda Extralium"

/obj/item/weapon/holder/isopod/Initialize(mapload, mob/held)
	. = ..()

	vis_contents -= held_mob
	var/mob/living/simple_mob/vore/isopod/I = held_mob
	if(I.body_color)
		icon_state = "w-isopod_holder"
		color = I.body_color

/obj/item/weapon/holder/isopod/Entered(mob/held, atom/OldLoc, do_vis = FALSE)
	. = ..()

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

	violent_breakthrough = FALSE

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

/datum/ai_holder/simple_mob/isopod/can_attack(atom/movable/the_target, vision_required)

	var/mob/living/simple_mob/vore/isopod/our_isopod = holder
	if(!our_isopod.can_eat(the_target)) return FALSE

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
			if(!our_isopod.can_eat(O))	//We only want food or trash
				continue
			. += O	//You left it out so it is mine
	else
		return ..()

/datum/ai_holder/simple_mob/isopod/pre_melee_attack(atom/A)
	if(isobj(A))
		var/mob/living/simple_mob/vore/isopod/our_isopod = holder
		our_isopod.eat_object(A)
	else return ..()

///////////////////////// CUSTOM VARIANTS /////////////////////////

/mob/living/simple_mob/vore/isopod/small
	icon = 'icons/rogue-star/mobx32.dmi'
	isopod_small = TRUE
	mob_size = MOB_TINY
	mob_always_swap = TRUE
	mob_bump_flag = null
	mob_swap_flags = 0
	mob_push_flags = 0
	pixel_x = 0
	default_pixel_x = 0
	low_priority = TRUE
	holder_type = /obj/item/weapon/holder/isopod
	can_be_drop_pred = FALSE

/mob/living/simple_mob/vore/isopod/small/jani
	name = "Pillbert Gamma"
	desc = "Destroyer of dirt, scarfer of scraps, friend to all!"
	under_color = "#00e1ff"
	eye_color = "#cc00ff"
	antennae_color = "#bdaa1f"
	antennae_end_color = "#ff9900"
	load_owner = "STATION"
	isopod_setup = TRUE

/mob/living/simple_mob/vore/isopod/cass
	body_color = "#612c08"
	under_color = "#c69c85"
	eye_color = "#612c08"
	antennae_color = "#272523"
	antennae_end_color = "#00f7ff"
	isopod_setup = TRUE

/mob/living/simple_mob/vore/isopod/lira
	body_color = "#ffffc0"
	under_color = "#fdfae9"
	eye_color = "#1d7fb7"
	antennae_color = "#ffc965"
	antennae_end_color = "#00f7ff"
	isopod_setup = TRUE
