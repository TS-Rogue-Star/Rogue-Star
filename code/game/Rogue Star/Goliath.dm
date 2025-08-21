//Goliath from /tg/! But modified to be vorny.
//If I remember properly, this used to be on baycode as well at a time. Like, baycode WAY back. During box times.
//But now, they're ported over. Converting /tg/ code to Polaris code is honestly such a hassle that I went insane. But it's done!

//Misc Helpers, procs, or others:
#define isspaceturf(A) (istype(A, /turf/space))
#define isopenspaceturf(A) (istype(A, /turf/simulated/open))
#define is_space_or_openspace(A) (isopenspaceturf(A) || isspaceturf(A))



/// Slow moving mob which attempts to immobilise its target
/mob/living/simple_mob/hostile/goliath
	name = "goliath"
	desc = "A hulking, armor-plated beast with long tendrils arching from its back."
	icon = 'code/game/Rogue Star/icons/lavaland_monsters_wide.dmi'
	icon_state = "goliath"
	icon_living = "goliath"
	icon_dead = "goliath_dead"
	faction = "hostile"
	default_pixel_x = -12
	pixel_x = -12
	a_intent  = I_HURT
	gender = MALE // Female ones are the bipedal elites
	movement_cooldown = 10 //SLOW
	mob_bump_flag = HEAVY
	maxHealth = 300
	health = 300
	vore_active = 1
	vore_capacity = 3 //Big boy.
	vore_icons = 0 // NO VORE SPRITES
	var/gut1
	vore_bump_chance = 0
	vore_ignores_undigestable = 0
	vore_default_mode = DM_ABSORB
	speak_emote = list("bellows")
	melee_damage_lower = 25
	melee_damage_upper = 25
	attack_sound = 'sound/weapons/punch1.ogg'
	attacktext = list("pulverizes")

	ai_holder_type = /datum/ai_holder/simple_mob/hostile/goliath

	special_attack_min_range = 1
	special_attack_max_range = 7
	special_attack_cooldown = 120

	loot_list = list(/obj/item/stack/animalhide/goliath = 100) // /obj/item/crusher_trophy/goliath_tentacle = 100,
	meat_type = list(/obj/item/weapon/reagent_containers/food/snacks/meat/goliath = 2)

	hunter = TRUE
	food_pref = OMNIVORE

	/*
	/// Can this kind of goliath be tamed?
	var/tameable = TRUE
	/// Has this particular goliath been tamed?
	var/tamed = FALSE
	/// Can someone ride us around like a horse?
	var/saddled = FALSE
	*/
/mob/living/simple_mob/hostile/goliath/New()
	..()

/mob/living/simple_mob/hostile/goliath/examine(mob/user)
	. = ..()
	//if (saddled)
	//	. += span_info("Someone appears to have attached a saddle to this one.")




// TUMMY STUFF

/mob/living/simple_mob/hostile/goliath/init_vore()
	..()
	var/obj/belly/B = new /obj/belly/goliath/tendril(src)
	B.emote_lists[DM_HOLD] = list(
		"The tendril you're trapped within slowly shifts and sways, every movement it made simply drenching you with another thin layer of that red, gooey fluid.",
		"You're suddenly assailed by a strong, rippling pulse of flesh from every direction, the tendril possessively squeezing around your form, tugging you a few inches deeper down that glowing, red tendril.",
		"The tendril you're within suddenly tightens, constricting any movement you might be making, gravity shifting as you feel the tendril shove downwards, clearly burrowing underground...The sensation eventually ceases, the clingy walls loosening up and letting you move once more.",
		"You hear what sounds like a loud rumble coming from somewhere right outside the tendril, the noise being  accompanied by a few loud, wet squelches before the sound ceased altogether.")
	gut1 = B
	vore_selected = B
	B = new /obj/belly/goliath/stomach(src)
	B.emote_lists[DM_ABSORB] = list(
		"The stomach slowly churns around you, slathering you in layer after layer of the slick, gooey red fluid coating the inner walls surrounding you and filling a good portion of the gut around you. Every passing moment it became more and more difficult to resist the doughy, encroaching walls, that goop only seeming to accelerate the process of assimilating your body into its own...",
		"The stomach seems to lazily just move about more like putty than muscle, slowly shifting around your form. Any shoves outwards against it to keep it from entirely engulfing you causes your appendages to sink deeper and deeper, pulling them back out proving the be quite the task.",
		"A sudden shift in gravity causes you to be flipped upside down, your body dropping against the 'bottom' of the gut with a light plap, starting to already sink into the stomach walls once again. The gooey stomach fluids that were clinginng to the 'top' of the stomach slowly began to dribble down onto you before falling all at once, completely  engulfing all but your head in the constantly glorping slime.",
		"The stomach walls suddenly shift around you, the stomach suddenly tightly squishing down around you, the stomach loosening up before trying to meld with your form as the creature lies down, taking away the precious space between you and the stomach walls you'd worked so hard on maintaining.")
	.=..()


/obj/belly/goliath
	autotransfer_enabled = 1  // Updated as part of broader autotransfer update
	autotransferchance = 50
	autotransferwait = 150
	escapable = 1
	escapechance = 100
	escapetime = 30
	fancy_vore = 1
	contamination_color = "red"
	contamination_flavor = "Acrid"
	vore_verb = "slurp"
	mode_flags = DM_FLAG_THICKBELLY | DM_FLAG_NUMBING
	//belly_fullscreen_color = "#711e1e"


//Hi, yes, it's me, the vorny bird. I spent 12 hours porting this over (actual coding time) and then got to the part where I-
//went "Well, time to make them vore creatures!". I then decided that hey, I already spent so much time on them already, so-
//-why not write some really long uwu descriptions for this horrid beast that you want to stay away from. (We do have quite a mob vore enjoyers)
//It's relatively easy to get grabbed by the creature if you're not cautious! And it takes a bit to both actually get /out/-
//-from it and get squelched further within! So to make up for that, we're going to make up for it by giving a nice,-
//lengthy description for the victim to read over and (presumably) get gulped down even deeper after they finish reading!
//Additionally, you only need to struggle once to escape from it's stomach. So instead of having the person struggle-
//-repeatedly hoping they get a chance to escape (and possibly reading the same struggle description multiple times!) -
//- we'll only require them to struggle once, with them being rewarded with a single detailed struggle message to read over before they get to squirm out!
//As for its stomach proper? Yeah, no holds barred. You're going to have to SQUIRM out of that one.

/obj/belly/goliath/tendril
	name = "Tendril"
	desc = "You only had mere seconds to comprehend the ground rumbling underneath your form, the ground below shattering apart before the creature's tendril suddenly shot up from underneath you. Your vision of the world was immediately obscured by the thick, red, pulsating walls that enveloped you. You were offered only a mere second of vision of the world around you before the tendril quickly closed above you, completely trapping you within, your world becoming nothing more than dark red, pulsating flesh. All around, you could hear the light thump of the creature's heartbeat coming from somewhere further within... Within moments, your form was squeezed down upon, your body being drenched in hot, gooey red fluid, every movement within the tendril causing loud glorps and squelches to emit and fill the chamber around you, the goo oozing against your form, lubricating you...Moments later, you were violently clamped down upon by a rippling wave of peristalsis, the tendril's inner walls giving you a strong, forceful tug downwards, the bulge you made within it - if any - beginning to slide deeper into the beast as the tendril began to slowly shift and sway, using the motion to glide you deeper...And deeper...If you wanted to escape and not be claimed by this goliath of a creature, now would be the time, if any..."
	escapechance = 100
	struggle_messages_inside = list(
		"You thrash about within the slick, constrictive tentacle, the gooey fluids surrounding your body letting out a loud, wet squelch. The tendril quickly responded to your movement, the light thud of the creature's heartbeat growing more rapid as the thick inner walls around you tensed up and formed a vice-like grip around you, temporarily impeding your movement...They eventually relaxed, allowing you to continue your movement towards the 'entrance' of that tendril.",
		"You shove your digits against the smooth, rippling walls surrounding your form, your digits sinking into the slick flesh, giving you just enough time to shove upwards. Your movements clearly stimulated the beast as that rhythmic swaying it was making with it's tendril sped up, the light thud you could only presume to be the beast's heartbeat growing more rapid...If you kept it up, you just might be able to climb out while the creature is distracted",
		"You go to move further within, your advance immediately being cut short by a strong, forceful clench, the small space you had surrounding you being encroached upon by those rolling, slimy walls...It almost seemed as if the creature had predicted your attempt at struggling free, giving you a clear warning that it wasn't going to let you escape so simply before loosening back up and freeing your limbs once more.",
		"With a strong, forceful shove, you manage to work your way further up the beast's tendril, your head shoving against the 'exit' of that loud, glorping chamber! You manage to work your digits into the small crease separating you from the outside world, only to be immediately met with gravity shifting around you as the tendril you're in shoves underground, blocking your escape and giving the tendril ample time to slowly suck along your body and tug you back down...It eventually moves back, allowing you to begin your ascent towards the exit to that tendril...")
	autotransferlocation = "Stomach"
	belly_fullscreen = "a_tumby"
	vore_sound = "Insertion1"


/obj/belly/goliath/stomach
	name = "Stomach"
	escapechance = 0
	transferchance = 10 //This one you will have to spam to get out, so short struggle messages!
	transferlocation = "Tendril"
	desc = "With a rather unceremonious squelch, your form is clamped down upon by the last part of the tendril, being quickly thrust right within the stomach of the beast. You quickly sink into a pool of thick goop, the stomach seeming to pause at first as it attempts to decide what to do with you, leaving you laying in that slimy pool of fluid, the only thing to accompany you being the loud, heavy thuds of the creature's heart from above you and the occasional whoosh of the creature's airsacks as they breathe. The stomach fluids didn't seem to be digesting you, seeming to have very little effect whatsoever! Eventually, however, the creature seemed to have finally decided on your fate, as the stomach beginning to rather nosily begin to churn to life, the stomach walls squeezing in upon you...For as aggressive of a creature as it was, the stomach was softer than one would expect, kneading across your body in slow, rhythmic waves, jostling you this way and that, shoving you against the stomach walls... Your form starting to sink into the oddly doughy inner stomach surrounding you, the stomach threatening to entirely claim you at a moment's notice unless you stayed acutely aware! Pulling yourself back away from those clingy, possessive inner walls proved to be a struggle, a loud glorp filling the chamber as you finally managed to pull back, only to be squelched into another warm, slick fold of flesh, having to repeat it again...And again...You could only keep this up for so long before you'd just sink right into them for good..."
	digest_mode = DM_ABSORB //It was either this or digest, and I like the idea of 'oh no I was mining and got nabbed by the goliath come rescue me' being possible (given how strong goliaths are) vs just shrugging and goin 'well, they'll be digested before we can get to them, start the resleever up'
	struggle_messages_inside = list(
		"You try to get a foothold within the constantly churning stomach, trying to shove back upwards towards, your limbs starting to sink down further into those doughy walls.",
		"The soft, posessive stomach squelches down upon your form, surprisingly gentle given the fierceness of the beast...Loud, wet schlorps fill the chamber around you as you sink into the gut...",
		"The stomach suddenly grows tighter around you, encroaching upon the small bit of space you had within, making it impossible to tell where you ended and the stomach began.",
		"Shoving downwards, you begin to squirm your way back up, coming to a tight valve leading in some direction... Pushing onnwards, you find it to lead into one of the beast's tendrils, managing to work yourself partway into it before a sudden clench shoved you right back down into the beast's warm gut.",
		"You squirm and shove about, pushing against the slowly enroaching walls, trying to make space for yourself and keep the warm, doughy insides from completley engulfing you...At least, for now.")
	belly_fullscreen = "da_tumby"
	vore_sound = "Stomach Move"

// Goliaths can summon tentacles more frequently as they take damage, scary.
/mob/living/simple_mob/hostile/goliath/apply_damage(damage, damagetype, def_zone, blocked, soaked, used_weapon, sharp, edge, used_weapon)
	. = ..()
	if (. <= 0)
		return
	if (last_special > (world.time+ 1 SECONDS))
		last_special -= 1 SECONDS

//Taming and riding code. Commented out for now.
/*
/mob/living/simple_mob/hostile/goliath/attackby(obj/item/attacking_item, mob/living/user, params)
	if (!istype(attacking_item, /obj/item/goliath_saddle))
		return ..()
	if (!tameable)
		to_chat(user, "<span class='alert'>doesn't fit!</span>")
		return
	if (saddled)
		to_chat(user, "<span class='alert'>already saddled!</span>")
		return
	if (!tamed)
		to_chat(user, "<span class='alert'>too rowdy!</span>")
		return
	to_chat(user, "<span class='alert'>affixing saddle...</span>")
	if (!do_after(user, delay = 5.5 SECONDS, target = src))
		return
	to_chat(user, "<span class='alert'>ready to ride</span>")
	qdel(attacking_item)
	make_rideable()

/mob/living/simple_mob/hostile/goliath/proc/make_rideable()
	saddled = TRUE
	add_overlay("goliath_saddled")
	// AddElement(/datum/element/ridable, /datum/component/riding/creature/goliath) //TODO: Make Rideable

/// Get ready for mounting
/mob/living/simple_mob/hostile/goliath/proc/tamed(mob/living/tamer, atom/food)
	tamed = TRUE

// Copy entire faction rather than just placing user into faction, to avoid tentacle peril on station
/mob/living/simple_mob/hostile/goliath/proc/befriend(mob/living/new_friend)
	faction = new_friend.faction

/// Version of the goliath that already starts saddled and doesn't require a lasso to be ridden.
/mob/living/simple_mob/hostile/goliath/deathmatch
	saddled = TRUE
	buckle_lying = 0

/mob/living/simple_mob/hostile/goliath/deathmatch/Initialize(mapload)
	. = ..()
	make_rideable()

/mob/living/simple_mob/hostile/goliath/deathmatch/make_rideable()
	add_overlay("goliath_saddled")
	//AddElement(/datum/element/ridable, /datum/component/riding/creature/goliath/deathmatch)
*/


/// Legacy Goliath mob with different sprites, largely the same behaviour
/mob/living/simple_mob/hostile/goliath/ancient
	name = "ancient goliath"
	desc = "A massive beast that uses long tentacles to ensnare its prey, threatening them is not advised under any conditions."
	icon = 'code/game/Rogue Star/icons/lavaland_monsters_wide.dmi'
	icon_state = "ancient_goliath"
	icon_living = "ancient_goliath"
	icon_dead = "ancient_goliath_dead"
	//tameable = FALSE

/// Rare Goliath variant which occasionally replaces the normal mining mob, releases shitloads of tentacles
/mob/living/simple_mob/hostile/goliath/ancient/immortal
	name = "immortal goliath"
	desc = "Goliaths are biologically immortal, and rare specimens have survived for centuries. \
		This one is clearly ancient, and its tentacles constantly churn the earth around it."
	maxHealth = 400
	health = 400
	//crusher_drop_chance = 30 // Wow a whole 5% more likely, how generous
	/// Don't re-check nearby turfs for this long
	COOLDOWN_DECLARE(retarget_turfs_cooldown)
	/// List of places we might spawn a tentacle, if we're alive
	var/list/tentacle_target_turfs

/mob/living/simple_mob/hostile/goliath/ancient/immortal/Life(seconds_per_tick, times_fired)
	. = ..()
	if (!. || !isturf(loc))
		return
	if (!LAZYLEN(tentacle_target_turfs) || COOLDOWN_FINISHED(src, retarget_turfs_cooldown))
		cache_nearby_turfs()
	for (var/turf/target_turf in tentacle_target_turfs)
		if (is_blocked_turf(target_turf, exclude_mobs = TRUE))
			tentacle_target_turfs -= target_turf
			continue
		if (prob(10))
			new /obj/effect/goliath_tentacle(target_turf, src)

/mob/living/simple_mob/hostile/goliath/ancient/immortal/Moved(atom/old_loc, movement_dir, forced, list/old_locs, momentum_change)
	. = ..()
	if (loc == old_loc || stat == DEAD || !isturf(loc))
		return
	cache_nearby_turfs()

/// Store nearby turfs in our list so we can pop them out later
/mob/living/simple_mob/hostile/goliath/ancient/immortal/proc/cache_nearby_turfs()
	COOLDOWN_START(src, retarget_turfs_cooldown, 10 SECONDS)
	LAZYCLEARLIST(tentacle_target_turfs)
	for(var/turf/floor in orange(4, loc))
		LAZYADD(tentacle_target_turfs, floor)

///MOB AI
/datum/ai_holder/simple_mob/hostile/goliath
	forgive_resting = FALSE
	threaten = TRUE
	threaten_delay = 3 SECONDS //3 seconds to run!
	threaten_timeout = 30 SECONDS

/// Go for the tentacles if they're available

/mob/living/simple_mob/hostile/goliath/do_special_attack(atom/A) //goliath_tentacles attack!
	if(!mind) //No controller?
		var/random = rand(1,3)
		if(random == 1)
			if(a_intent == I_HURT) //Grab. Under their tile and around them.
				for(var/mob/living/L in range(7, src))
					shake_camera(L, 1.5 SECONDS, 0.5)
				playsound(src, 'code/game/Rogue Star/sounds/demon_attack1.ogg', vol = 50, vary = TRUE)
				goliath_tentacles(A)
		if(random == 2)
			for(var/mob/living/L in range(7, src))
				shake_camera(L, 1.5 SECONDS, 0.5)
			playsound(src, 'code/game/Rogue Star/sounds/demon_attack1.ogg', vol = 50, vary = TRUE)
			tentacle_grasp(A)
		else
			for(var/mob/living/L in range(7, src))
				shake_camera(L, 1.5 SECONDS, 0.5)
			playsound(src, 'code/game/Rogue Star/sounds/demon_attack1.ogg', vol = 50, vary = TRUE)
			tentacle_burst(src)
	else
		if(a_intent == I_HURT) //Grab. Under their tile and around them. 100% working
			for(var/mob/living/L in range(7, src))
				shake_camera(L, 1.5 SECONDS, 0.5)
			playsound(src, 'code/game/Rogue Star/sounds/demon_attack1.ogg', vol = 50, vary = TRUE)
			goliath_tentacles(A)
		if(a_intent == I_GRAB) //Throw a range towards them.
			for(var/mob/living/L in range(7, src))
				shake_camera(L, 1.5 SECONDS, 0.5)
			playsound(src, 'code/game/Rogue Star/sounds/demon_attack1.ogg', vol = 50, vary = TRUE)
			tentacle_grasp(A)
		if(a_intent == I_DISARM) //AOE around yourself. 100% working
			for(var/mob/living/L in range(7, src))
				shake_camera(L, 1.5 SECONDS, 0.5)
			playsound(src, 'code/game/Rogue Star/sounds/demon_attack1.ogg', vol = 50, vary = TRUE)
			tentacle_burst(src)


//THE ABILITIES BUT MODIFIED

//This is the 'grab under them and 3 tiles around them'
/mob/living/simple_mob/hostile/goliath/proc/goliath_tentacles(var/atom/target)
	target = get_turf(target)
	var/max_range = 7
	var/cooldown_time = 12 SECONDS
	if (get_dist(src, target) > max_range)
		return FALSE

	new /obj/effect/goliath_tentacle(target, src)
	var/list/directions = cardinal.Copy()
	for(var/i in 1 to 3)
		var/spawndir = pick_n_take(directions)
		var/turf/adjacent_target = get_step(target, spawndir)
		if(adjacent_target)
			new /obj/effect/goliath_tentacle(adjacent_target, src)

	if (isliving(target))
		visible_message(span_warning("[src] digs its tentacles under [target]!"))
	last_special = world.time + cooldown_time //Cooldown timer.
	return TRUE

//Reaches out, leaves a trail.
/mob/living/simple_mob/hostile/goliath/proc/tentacle_grasp(var/atom/target)
	var/max_range = 7
	var/cooldown_time = 12 SECONDS
	if (get_dist(src, target) > max_range)
		return FALSE
	if (isliving(target))
		visible_message(span_warning("[src] reaches for [target] with its tentacles!"))
	new /obj/effect/temp_visual/effect_trail/burrowed_tentacle(src.loc, target.loc, src)

	for(var/mob/living/L in range(7, src))
		shake_camera(L, 1.5 SECONDS, 0.5)
	playsound(src, 'code/game/Rogue Star/sounds/demon_attack1.ogg', vol = 50, vary = TRUE)
	last_special = world.time + cooldown_time //Cooldown timer.
	return TRUE

//AOE around yourself
/mob/living/simple_mob/hostile/goliath/proc/tentacle_burst(atom/target)
	var/cooldown_time = 6 SECONDS
	var/list/directions = GLOB.alldirs.Copy()
	for (var/dir in directions)
		var/turf/adjacent_target = get_step(target, dir)
		if(adjacent_target)
			new /obj/effect/goliath_tentacle(adjacent_target, src)
	visible_message(span_warning("[src] unleashes tentacles from the ground around it!"))
	for(var/mob/living/L in range(7, src))
		shake_camera(L, 1.5 SECONDS, 0.5)
	playsound(src, 'code/game/Rogue Star/sounds/demon_attack1.ogg', vol = 50, vary = TRUE)
	last_special = world.time + cooldown_time //Cooldown timer.
	return TRUE

/// An invisible effect which chases a target, spawning tentacles every so often.
/obj/effect/temp_visual/effect_trail/burrowed_tentacle
	name = "burrowed_tentacle"
	duration = 5 SECONDS
	movement_delay = 5
	spawn_interval = 0.25 SECONDS
	max_range = 7
	max_spawned = 7
	spawned_effect = /obj/effect/goliath_tentacle

//THE TENTACLES THEIRSELF
/// A tentacle which grabs you if you don't get away from it.
/// Takes 5 seconds to break free from.
/obj/effect/goliath_tentacle
	name = "goliath tentacle"
	icon = 'code/game/Rogue Star/icons/lavaland_monsters.dmi'
	icon_state = "goliath_tentacle_spawn"
	layer = BELOW_MOB_LAYER
	plane = MOB_PLANE
	anchored = TRUE
	/// Timer for our current action stage
	var/action_timer
	/// Time in which to grab people
	var/grapple_time = 10 SECONDS
	/// Lower bound of damage to inflict
	var/min_damage = 10
	/// Upper bound of damage to inflict
	var/max_damage =  15
	/// How long it takes to escape
	var/escape_time = 5 SECONDS
	/// The owner of said tentacle. Used for vore stuff.
	var/mob/living/tentacle_owner

/obj/effect/goliath_tentacle/Initialize(mapload, owner)
	. = ..()
	tentacle_owner = owner
	if (ismineralturf(loc))
		var/turf/simulated/mineral/floor = loc
		floor.GetDrilled()
	if (is_space_or_openspace(loc))
		return INITIALIZE_HINT_QDEL
	for (var/obj/effect/goliath_tentacle/tentacle in loc)
		if (tentacle != src)
			return INITIALIZE_HINT_QDEL
	deltimer(action_timer)
	action_timer = addtimer(CALLBACK(src, PROC_REF(animate_grab)), 0.7 SECONDS, TIMER_STOPPABLE)

/obj/effect/goliath_tentacle/Destroy()
	deltimer(action_timer)
	return ..()

/// Change to next icon state and set up grapple
/obj/effect/goliath_tentacle/proc/animate_grab()
	icon_state = "goliath_tentacle_wiggle"
	deltimer(action_timer)
	addtimer(CALLBACK(src, PROC_REF(grab)), 0.3 SECONDS, TIMER_STOPPABLE)

/// Grab everyone we share space with. If it's nobody, go home.
/obj/effect/goliath_tentacle/proc/grab()
	for (var/mob/living/victim in loc)
		if (victim.stat == DEAD)
			continue
		if(istype(victim, /mob/living/simple_mob/hostile/goliath)) //No grabbing goliaths as a goliath.
			continue
		to_chat(victim, "<span class='alert'>You've been grabbed!</span>")
		visible_message(span_danger("[src] grabs hold of [victim]!"))
		//VORE/VORNY CODE HERE
		if(tentacle_owner && tentacle_owner.ai_holder.vore_check(victim)) //Do we have someone to link back to this tentacle AND are compatible?
			tentacle_owner.perform_the_nom(tentacle_owner,victim,tentacle_owner,tentacle_owner.vore_selected,1, TRUE) //VORE Variant
			retract()
			return
		// Waow! How compact!

		victim.adjustBruteLoss(rand(min_damage, max_damage))
		if (victim.add_modifier(/datum/modifier/incapacitating/stun/goliath_tentacled, grapple_time, src))
			buckle_mob(victim, TRUE)
	for (var/obj/mecha/mech in loc)
		mech.take_damage(rand(min_damage, max_damage), type = "brute")
	if (!has_buckled_mobs())
		retract()
		return
	deltimer(action_timer)
	action_timer = addtimer(CALLBACK(src, PROC_REF(retract)), grapple_time, TIMER_STOPPABLE)

/// Play exit animation.
/obj/effect/goliath_tentacle/proc/retract()
	if (icon_state == "goliath_tentacle_retract")
		return // Already retracting
	for(var/mob/living/mobs in buckled_mobs)
		mobs.remove_modifiers_of_type(/datum/modifier/incapacitating/stun/goliath_tentacled)
	unbuckle_all_mobs(force = TRUE)
	icon_state = "goliath_tentacle_retract"
	deltimer(action_timer)
	action_timer = QDEL_IN(src, 0.7 SECONDS)

/obj/effect/goliath_tentacle/attack_hand(mob/living/user)
	. = ..()
	if (. || !has_buckled_mobs())
		return
	retract()
	user.visible_message(span_notice("[user] pulls the tentacle from around it's victim!"))
	return TRUE

/obj/effect/goliath_tentacle/user_unbuckle_mob(mob/living/buckled_mob, mob/user)
	user.setClickCooldown(user.get_attack_speed())
	visible_message("<span class='danger'>[user] begins to tear at \the [src]!</span>")
	if(do_after(user, escape_time, src, incapacitation_flags = INCAPACITATION_DEFAULT & ~(INCAPACITATION_RESTRAINED | INCAPACITATION_BUCKLED_FULLY)))
		if(!has_buckled_mobs())
			return
		visible_message("<span class='danger'>[user] manages to tear \the [src] apart!</span>")
		unbuckle_mob(buckled_mob)



/// Goliath tentacle stun with special removal conditions
/datum/modifier/incapacitating/stun/goliath_tentacled
	name = "goliath_tentacled"
	expire_at = 10 SECONDS
	/// The tentacle that is tenderly holding us close
	var/obj/effect/goliath_tentacle/tentacle

/datum/modifier/incapacitating/stun/goliath_tentacled/on_applied(mob/living/new_owner, set_duration, obj/effect/goliath_tentacle/tentacle)
	. = ..()
	if (!.)
		return
	src.tentacle = tentacle

/datum/modifier/incapacitating/stun/goliath_tentacled/on_expire()
	if (isnull(tentacle))
		return
	tentacle.retract()
	tentacle = null

/datum/modifier/incapacitating/stun/goliath_tentacled/tick()
	if(holder.buckled && istype(holder.buckled, /obj/effect/goliath_tentacle)) //We're buckled to a tentacle!
		holder.Stun(1)
		holder.Weaken(1)
	else
		expire()
	return


//Goliath Meat, hide, etc

/obj/item/weapon/reagent_containers/food/snacks/meat/goliath
	name = "goliath meat"
	desc = "A slab of goliath meat."

/obj/item/stack/animalhide/goliath
	name = "goliath hide"
	desc = "The skin of a terrible creature."
	icon = 'code/game/Rogue Star/icons/goliath_hide.dmi'
	singular_name = "goliath hide piece"
	icon_state = "goliath_hide"
	stacktype = "goliath_hide"

/// Use this to ride a goliath
/*
/obj/item/goliath_saddle
	name = "goliath saddle"
	desc = "This rough saddle will give you a serviceable seat upon a goliath! Provided you can get one to stand still."
	icon = 'icons/obj/mining.dmi'
	icon_state = "goliath_saddle"
*/
