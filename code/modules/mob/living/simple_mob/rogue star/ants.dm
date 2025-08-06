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
	melee_damage_upper = 1
	melee_damage_lower = 0.1

	mob_size = MOB_TINY
	mob_always_swap = TRUE
	mob_bump_flag = null
	mob_swap_flags = 0
	mob_push_flags = 0

	ai_holder_type = /datum/ai_holder/simple_mob/ant

	has_langs = list(LANGUAGE_ANIMAL)
	say_list_type = /datum/say_list/ant
	tt_desc = "Formica Stelarium"

	attacktext = list("nibbled")
	friendly = list("nuzzles", "nibbles", "wiggles its antennae at", "rubs against")
	catalogue_data = list(/datum/category_item/catalogue/fauna/ant)

	response_help   = "pets"
	response_disarm = "bops"
	response_harm   = "attacks"

	var/queen = 0	//Extra stuff gets considered if this is true
	var/list/overlays_cache = list()	//Holds on to eyes and crowns mostly
	var/team_color = null				//Just to keep track, gets converted to color
	var/eye_color = null				//Keeps track of eye color for sprite building
	var/kiss_cooldown = 0				//Don't spam transfer!
	var/reproduce_cooldown = 0			//Don't be a machine gun

	vore_active = 1

	swallowTime = 2 SECONDS
	vore_capacity = 2
	vore_bump_chance = 10
	vore_digest_chance = 0
	vore_absorb_chance = 0
	vore_escape_chance = 10
	vore_pounce_chance = 25
	vore_ignores_undigestable = 0
	vore_default_mode = DM_SELECT
	selective_preference = DM_DIGEST
	vore_icons = SA_ICON_LIVING
	vore_stomach_name = "stomach"
	vore_stomach_flavor = "The slick smooth surfaces of the stretchy insect flesh form against your figure as you settle inside. The walls hold you securely behind armor plating, trapped in the churning heat of the soft insides of this bug. The rolling burbles of its social stomach squeezing against you in rhythmic undulations, stirring up everything within, and mooshing everything into one mass."
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
	b.belly_healthbar_overlay_theme = "Tight"
	b.belly_healthbar_overlay_color = "#292031"

	b.selective_preference = DM_DIGEST
	if(queen)
		b.digest_brute = 2
		b.digest_burn = 2
		b.escapechance = 5
		b.desc = "The slick smooth surfaces of the stretchy insect flesh form against your figure as you settle inside. The walls hold you securely behind armor plating, trapped in the churning heat of the soft insides of this bug. A chaotic ness of hot, heavy flesh pressing inward against you, heaving and grinding and mashing into you, trying to break everything down, her body desperately trying to turn everything into more of her army! Hot slopping fluid tingling against you as her body groans and gurgles. You are food for royalty at least~"
	else
		b.digest_brute = 0.1
		b.digest_burn = 0.1
	b.mode_flags = DM_FLAG_THICKBELLY | DM_FLAG_NUMBING

/mob/living/simple_mob/vore/ant/New(newloc,var/team,var/oureyes)
	. = ..()
	if(team)
		if(istype(team,/mob/living/simple_mob/vore/ant))
			var/mob/living/simple_mob/vore/ant/A = team
			team_color = A.team_color
			faction = A.faction
		else
			team_color = team
			faction = team_color
	if(oureyes)
		eye_color = oureyes
	if(!team_color)
		team_color = pick(list("#640a06","#1f1f33","#d4ac3d","#183d1d"))
		faction = team_color
	color = team_color
	if(!eye_color)
		eye_color = random_color()
	update_icon()
	if(!queen)
		silly_name()

/mob/living/simple_mob/vore/ant/Life()
	. = ..()
	if(ckey || load_owner)
		return
	kiss_cooldown --
	if(queen)
		if(world.time < reproduce_cooldown)
			return
		if(!isturf(loc))
			return
		if(nutrition > 150)
			nutrition -= 150
			var/mob/living/simple_mob/vore/ant/A = new(get_turf(src),src)
			reproduce_cooldown = world.time + 10 SECONDS
			visible_message("\The [A] is born from \the [src]... It's the miracle of life!", runemessage = "! ! !")
			spawn()
			if(A.ai_holder)
				A.ai_holder.home_turf = src
			A.low_priority = low_priority
	else
		if(nutrition >= 500 || vore_fullness)
			if(ai_holder)
				if(ai_holder.stance == STANCE_IDLE)
					if(ai_holder.home_turf)
						if(isturf(ai_holder.home_turf))
							if(nutrition >= 1000)
								queen_me()

						else if(ai_holder.home_turf.z == z)
							ai_holder.returns_home = TRUE

/mob/living/simple_mob/vore/ant/apply_melee_effects(var/atom/A)
	. = ..()
	if(ishuman(A))
		var/mob/living/carbon/human/H = A
		if(prob(25))
			H.adjustHalLoss(50)
			visible_message(SPAN_DANGER("\The [src] stings \the [H]!"), runemessage = "! ! !")
			H.say("*scream")

/mob/living/simple_mob/vore/ant/death(var/squish = FALSE)
	. = ..()
	var/turf/T = get_turf(src)
	if(squish)
		new /obj/effect/decal/cleanable/bug_remains(T)
		qdel(src)
	if(queen > 0)
		var/extra = FALSE
		if(queen > 4)	//Don't crash my server
			queen = 4
			extra = TRUE
		while(queen > 0)
			queen --
			var/obj/item/clothing/head/crown/cr = new(T)
			cr.name = "[src.name] crown"
			cr.pixel_x = rand(1,25)
			cr.pixel_y = rand(1,25)
			visible_message(SPAN_WARNING("\The [src]'s crown fell off!"),runemessage = "clink")
		if(extra)
			visible_message(SPAN_WARNING("All the rest of the crowns fell apart when they hit the ground! Dang!"),runemessage = "C R A S H")

/mob/living/simple_mob/vore/ant/examine(mob/user)
	. = ..()
	if(queen > 0)
		. += SPAN_NOTICE("She appears to be wearing [queen] crowns.")

/mob/living/simple_mob/vore/ant/proc/ant_stun(var/mob/living/prey)
	if(!will_eat(prey))
		return FALSE
	if(z != prey.z)
		return FALSE
	if(istype(prey,/mob/living/simple_mob/vore/ant))
		var/mob/living/simple_mob/vore/ant/A = prey
		if(A.queen)
			return FALSE
	prey.Weaken(10)

/mob/living/simple_mob/vore/ant/proc/queen_me()
	var/turf/T = get_turf(src)
	var/mob/living/simple_mob/vore/ant/queen/Q = new(T,src,eye_color)
	Q.dir = dir
	for(var/mob/living/simple_mob/vore/ant/A in oview(world.view,T))
		if(A.team_color == team_color)
			if(A.ai_holder)
				if(!A.ai_holder.home_turf)
					A.ai_holder.home_turf = Q
	if(capture_caught)
		for(var/obj/item/capture_crystal/crystal in world)
			if(istype(crystal,/obj/item/capture_crystal))
				if(crystal.bound_mob == src)
					crystal.transfer_bound_mob(Q)
	if(ckey)
		Q.ckey = ckey
	if(load_owner)
		Q.load_owner = load_owner
	qdel(src)

/mob/living/simple_mob/vore/ant/proc/silly_name()
	var/list/adjectives = list(
		"adorable",
		"antdorable",
		"awesome",
		"radical",
		"radicant",
		"determined",
		"dutiful",
		"buff",
		"swole",
		"shimmering",
		"armored",
		"speedy",
		"whimsical",
		"commited",
		"scarred",
		"insistent",
		"insistant",
		"radiant",
		"scuttling",
		"lunging",
		"greedy",
		"mighty",
		"forceful",
		"athletic",
		"hardy",
		"muscular",
		"robust",
		"stalwart",
		"vigorous",
		"well-built",
		"durable",
		"solid",
		"undaunted",
		"brave",
		"enduring",
		"heavy-duty",
		"tough",
		"antiquated",
		"antagonistic",
		"antediluvian",
		"formidible",
		"formidaeble",
		"reluctant",
		"triumphant",
		"significant",
		"important",
		"relevant"
	)

	name = "[pick(adjectives)] [name]"

/mob/living/simple_mob/vore/ant/proc/consider_food()
	if(!ai_holder)
		return
	if(ai_holder.stance != STANCE_IDLE)
		return
	if(ai_holder.returns_home)
		return
	if(nutrition > 500)
		return
	var/datum/ai_holder/simple_mob/ant/A = ai_holder
	if(A.last_food_loc)
		if(A.last_food_loc.z != z)
			return
		if(get_dist(get_turf(src),A.last_food_loc) > 7)
			A.give_destination(A.last_food_loc)
		else
			A.last_food_loc = null

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
		if(our_image)
			add_overlay(our_image)

	pixel_x = default_pixel_x

/mob/living/simple_mob/vore/ant/can_eat(var/atom/movable/food)
	if(food.z != z)
		return FALSE
	if(istype(food, /obj/item/weapon/reagent_containers/food))
		if(ai_holder)
			var/datum/ai_holder/simple_mob/ant/A = ai_holder
			A.last_food_loc = get_turf(food)
		return TRUE
	return FALSE

//Squish code from cockroach.dm
/mob/living/simple_mob/vore/ant/Crossed(var/atom/movable/AM)
	if(ckey || load_owner || capture_caught)
		return ..()
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
		if(A.a_intent == I_HELP)
			return
		if(prob(33))
			A.visible_message("<span class='notice'>[A] squashed [src].</span>", "<span class='notice'>You squashed [src].</span>")
			spawn(0)
			death(TRUE)
		else
			if(ai_holder)
				ai_holder.add_attacker(AM)
				ai_holder.give_target(AM)
			visible_message("<span class='notice'>[src] avoids getting crushed.</span>")
	else
		if(isstructure(AM))
			if(prob(33))
				AM.visible_message("<span class='notice'>[src] was crushed under [AM].</span>")
				spawn(0)
				death(TRUE)
			else
				if(ai_holder)
					ai_holder.add_attacker(AM)
					ai_holder.give_target(AM)
				visible_message("<span class='notice'>[src] avoids getting crushed.</span>")
	return ..()

/mob/living/simple_mob/vore/ant/Bump(atom/movable/AM)
	if(istype(AM,/mob/living/simple_mob/vore/ant))
		var/mob/living/simple_mob/vore/ant/A = AM
		if(A.faction == faction)
			forceMove(AM.loc)
			return
	. = ..()

/mob/living/simple_mob/vore/ant/attackby(obj/item/O, mob/user)
	if(user.a_intent != I_HELP)
		return ..()
	if(istype(O,/obj/item/clothing/head/crown))
		user.drop_from_inventory(O)
		qdel(O)
		var/turf/T = get_turf(src)
		T.visible_message(SPAN_NOTICE("\The [user] gives \the [src] a crown!"),runemessage = "✨")
		if(queen < 1)
			queen_me()
		else
			queen ++
			update_icon()
	. = ..()

/mob/living/simple_mob/vore/ant/proc/feed_other(var/mob/living/simple_mob/vore/ant/other_ant)
	visible_message("<span class='notice'>\The [src] locks mouths with \the [other_ant] for a moment!</span>")
	playsound(get_turf(src),get_sfx("smooches"),100,TRUE)
	kiss_cooldown = 30
	if(ai_holder)
		ai_holder.returns_home = FALSE
	if(nutrition > 500)
		nutrition -= 500
		other_ant.nutrition += 500
	if(ai_holder)
		for(var/mob/living/simple_mob/vore/ant/more_ant in oview(world.view,get_turf(src)))
			if(more_ant.queen)
				continue
			if(more_ant.ai_holder)
				var/datum/ai_holder/simple_mob/ant/ant_ai = more_ant.ai_holder
				var/datum/ai_holder/simple_mob/ant/our_ai = ai_holder
				if(ant_ai.last_food_loc)
					continue
				ant_ai.last_food_loc = our_ai.last_food_loc
	if(vore_fullness)
		if(!vore_selected)
			return
		if(!other_ant.vore_selected)
			return
		for(var/thing in vore_selected)
			if(isliving(thing))
				to_chat(thing,SPAN_DANGER("Suddenly the walls around you squeeze in tightly, irresistibly you are forced along the slick chute, back toward the ant’s mouth! Instead of being released though, you are dutifully squirted into the mouth of a larger ant! A queen ant! She guzzles you down quickly, swallowing you away in a noisy GLLRP, sending you to stew in her eager stomach."))
			vore_selected.transfer_contents(thing,other_ant.vore_selected)

/mob/living/simple_mob/vore/ant/save_conditions(mob/living/user)
	if(load_owner == "STATION")
		to_chat(user, "<span class = 'warning'>\The [src] is registered as a station pet, and as such can not be registered again.</span>")
		return FALSE
	if(initial(load_owner) == "seriouslydontsavethis")
		to_chat(user,"<span class = 'warning'>\The [src] is too complicated to be able to be registered.</span>")
		return FALSE
	if(load_owner && load_owner != user.ckey)
		to_chat(user,"<span class = 'warning'>\The [src] is already registered, it already has a owner.</span>")
		return FALSE
	if(client || ckey)	//It's a player, don't save it
		to_chat(user,"<span class = 'warning'>\The [src] isn't able to be registered.</span>")
		return FALSE
	if(!ai_holder)	//It doesn't have an AI, something weird is going on, don't save it
		to_chat(user,"<span class = 'warning'>\The [src] isn't able to be registered.</span>")
		return FALSE
	if(ai_holder.hostile && faction != user.faction)	//It's hostile to the person trying to save it, don't save it
		if(ai_holder.stance != STANCE_IDLE)
			to_chat(user,"<span class = 'warning'>\The [src] is too unruly to be registered.</span>")
			return FALSE
	if(!capture_crystal)	//If it isn't catchable with capture crystals, it probably shouldn't be saved with the storage system.
		to_chat(user,"<span class = 'warning'>\The [src] isn't able to be registered.</span>")
		return FALSE
	if(!(ai_holder.stance == STANCE_SLEEP || ai_holder.stance == STANCE_IDLE || ai_holder.stance == STANCE_FOLLOW))	//The AI is trying to do stuff, don't save it
		to_chat(user,"<span class = 'warning'>\The [src] is too unruly to be registered.</span>")
		return FALSE
	if(stat != CONSCIOUS)
		to_chat(user,"<span class = 'warning'>\The [src] is not in a condition to be scanned.</span>")
		return FALSE
	return TRUE

/mob/living/simple_mob/vore/ant/mob_bank_save(mob/living/user)

	var/list/to_save = list(
		"ckey" = user.ckey,
		"type" = /mob/living/simple_mob/vore/ant,
		"name" = name,
		"team_color" = team_color,
		"eye_color" = eye_color
		)

	return to_save

/mob/living/simple_mob/vore/ant/mob_bank_load(mob/living/user, var/list/load)
	if(user)
		load_owner = user.ckey
	else
		load_owner = "STATION"
	name = load["name"]
	real_name = name
	team_color = load["team_color"]
	color = team_color
	eye_color = load["eye_color"]

	update_icon()

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

	vore_pounce_chance = 75
	vore_pounce_maxhealth = 100
	vore_standing_too = TRUE

/mob/living/simple_mob/vore/ant/red/team_color = "#640a06"
/mob/living/simple_mob/vore/ant/black/team_color = "#1f1f33"
/mob/living/simple_mob/vore/ant/yellow/team_color = "#d4ac3d"
/mob/living/simple_mob/vore/ant/green/team_color = "#183d1d"

/mob/living/simple_mob/vore/ant/queen/red/team_color = "#640a06"
/mob/living/simple_mob/vore/ant/queen/black/team_color = "#1f1f33"
/mob/living/simple_mob/vore/ant/queen/yellow/team_color = "#d4ac3d"
/mob/living/simple_mob/vore/ant/queen/green/team_color = "#183d1d"

/mob/living/simple_mob/vore/ant/random/New(newloc, team, oureyes)
	team_color = random_color()
	faction = team_color
	. = ..()

/mob/living/simple_mob/vore/ant/queen/random/New(newloc, team, oureyes)
	team_color = random_color()
	faction = team_color
	. = ..()

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
	var/ambivalence = 0
	var/turf/last_food_loc

/datum/ai_holder/simple_mob/ant/can_attack(atom/movable/the_target, vision_required)
	if(the_target.invisibility)
		return FALSE
	if(!can_see_target(the_target))
		ambivalence ++
	else
		ambivalence = 0
	if(ambivalence >= 100)	//Basically the ants can smell you and they HATE YOU so they can track you for a bit even if they can't see you right now
		ambivalence = 0
		return FALSE
	var/mob/living/simple_mob/vore/ant/our_ant = holder
	if(isliving(the_target))
		var/mob/living/L = the_target
		if(L.faction == our_ant.faction)
			return FALSE
		if(istype(the_target,/mob/living/simple_mob/vore/ant))	//So I see that you are an ant...
			var/mob/living/simple_mob/vore/ant/target_ant = the_target
			if(target_ant.team_color == our_ant.team_color)	//Are you an ant friend... or an antly foe...
				if(target_ant.queen && !our_ant.queen)	//You are a queen and I am not!
					if(our_ant.kiss_cooldown > 0)		//I want to kiss the queen...
						return FALSE
					if(our_ant.nutrition >= 500 || our_ant.vore_fullness)	//But only if I have something to give her...
						return TRUE
				return FALSE
			else if(target_ant.stat == DEAD)	//You are not a friend, also you are dead (lol)
				if(our_ant.vore_fullness >= our_ant.vore_capacity)	//If I have room in the tank you are toast bub
					return FALSE
				else return TRUE
			else
				return TRUE	//You're not a friend AND you're still alive, it is ON let's GO!!!
		if(!handle_corpse)
			if(L.stat)
				return FALSE
		if(check_attacker(the_target))
			return TRUE
		return FALSE
	else if(!our_ant.can_eat(the_target)) return FALSE
	return TRUE		//FEED MY PRETTY FEEED

/datum/ai_holder/simple_mob/ant/list_targets()
	if(world.time >= item_search_cooldown)	//Let's not look for items too often
		. = list()
		var/cooldown = rand(5,30) SECONDS
		var/mob/living/simple_mob/vore/ant/our_ant = holder
		item_search_cooldown = world.time + cooldown
		var/search_range = 3
		if(!our_ant.queen)
			search_range = 5
		var/search_hits = 0
		for(var/obj/O in view(holder, search_range))
			if(!our_ant.can_eat(O))	//We only want food
				continue
			. += O	//You left it out so it is mine
			search_hits ++

		if(search_hits > 0)
			return
		our_ant.consider_food()
	else
		return ..()

/datum/ai_holder/simple_mob/ant/melee_attack(atom/A)
	var/ant = FALSE
	if(istype(A,/mob/living/simple_mob/vore/ant))
		ant = TRUE
		var/mob/living/simple_mob/vore/ant/ourant = holder
		var/mob/living/simple_mob/vore/ant/other_ant = A
		if(ourant.faction == other_ant.faction)
			ourant.feed_other(other_ant)
			return
		if(ant)
			if(prob(25))
				if(ourant.ant_stun(other_ant))
					return
	. = ..()

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

/datum/category_item/catalogue/fauna/ant
	name = "Alien Wildlife - Ant"
	desc = "Ants are primarily non-agressive, but will invade areas where food has been left out in order to take it! Food that has been taken by an ant will typicallt be returned to a queen ant as soon as possible, if one exists nearby. Queen ants are the primary reproductives in an ant colony, producing new workers rapidly to spread and grow the colony! While the worker ants do not care much what you do to other workers, the colony will band together to defend the queen if she ever comes under attack."
	value = CATALOGUER_REWARD_EASY

/datum/say_list/ant
	speak = list(". . .", "! ! !", "? ? ?")
	emote_hear = list("clicks...", "clacks...")
	emote_see = list("sways its antennae", "wiggles its antennae", "nibbles something on the floor", "stretches its legs", "hunkers down")
	say_maybe_target = list("? ? ?")
	say_got_target = list("! ! !")
