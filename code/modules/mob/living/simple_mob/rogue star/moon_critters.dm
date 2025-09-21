//RS FILE

/////MOON DEER/////
/mob/living/simple_mob/vore/prancer
	name = "lunar prancer"
	desc = "A creature with a long neck and four long legs, strikingly, each leg ends in a vicious looking crystal spike, which it walks around upon. It has several small crystal horns on its head in a kind of crownlike pattern, and an almost poofy looking tail made of crystal! It looks quite soft!"
	icon = 'icons/rogue-star/mobx32.dmi'
	icon_state = "moon_deer"
	icon_living = "moon_deer"
	icon_dead = "moon_deer_dead"

	var/list/overlays_cache = list()
	var/crystal_color

	vore_capacity = 1

	tt_desc = "lunariad cervune"

	faction = "prancer"
	maxHealth = 200
	health = 200
	movement_cooldown = 2
	meat_amount = 5
	meat_type = /obj/item/weapon/reagent_containers/food/snacks/meat

	response_help = "pets"
	response_disarm = "rudely paps"
	response_harm = "punches"

	melee_damage_lower = 1
	melee_damage_upper = 10
	attack_sharp = TRUE
	attack_edge = TRUE
	catalogue_data = list(/datum/category_item/catalogue/fauna/moon_deer)

	attacktext = list("nipped", "kicked", "bonked","stabbed")
	friendly = list("sniffs", "nuzzles", "nibbles")

	ai_holder_type = /datum/ai_holder/simple_mob/oregrub

	mob_size = MOB_MEDIUM

	has_langs = list(LANGUAGE_ANIMAL)
	say_list_type = /datum/say_list/deer/moon

	min_oxy = 0
	max_oxy = 0
	min_tox = 0
	max_tox = 0
	min_co2 = 0
	max_co2 = 0
	min_n2 = 0
	max_n2 = 0
	minbodytemp = 0

	hunter = TRUE
	food_pref = ROBOVORE
	food_pref_obligate = TRUE

/////////////////////////////////////// Vore stuff ///////////////////////////////////////////

	swallowTime = 3 SECONDS
	vore_active = 1
	vore_capacity = 1
	vore_bump_chance = 1
	vore_bump_emote	= "suddenly pounces on"
	vore_ignores_undigestable = 0
	vore_default_mode = DM_DIGEST
	vore_icons = SA_ICON_LIVING
	vore_stomach_name = "nitorepetrae"
	vore_default_contamination_flavor = "Wet"
	vore_default_contamination_color = "grey"
	vore_default_item_mode = IM_DIGEST
	vore_bump_chance = 5
	vore_pounce_chance = 35
	vore_pounce_falloff = 0
	vore_standing_too = TRUE

/mob/living/simple_mob/vore/prancer/init_vore()
	..()

	var/obj/belly/base = vore_selected
	base.name = "nitorepetrae" //"Polish rock"
	base.desc = "Despite being contained within a creature, you find that you can actually kind of sort of see inside of it! The flesh ripples and distorts the light that finds its way inside, but you find that the flesh is actually mostly transparent, and you can see out between the gaps in the bones and plates of the creature. You can see the lattice of crystal that coats its bones, and indeed, you can see into other areas within the creature, you can see its body pulse and heave and churn all throughout! Importantly though, you are actually quite imminently at the mercy of that squeezing flesh. Laced with minerals, the walls are heavy against you! It is difficult to move at all as they hold you, slowly flexing inward against you, pushing you here, really grinding over you as they pour a thick sludgy slime across your body. When the flesh squeezes over you, you can feel the almost gritty texture of the ooze it is rubbing into you, as it works heavily upon your outer layers… polishing you up… knocking off your imperfections… working on working you down…"
	base.belly_fullscreen = "semitrans"
	base.colorization_enabled = TRUE
	base.belly_fullscreen_color = crystal_color
	base.belly_healthbar_overlay_theme = "Churn"
	base.belly_healthbar_overlay_color = crystal_color
	base.digest_brute = 0.1
	base.digest_burn = 0.1
	base.digestchance = 0
	base.absorbchance = 0
	base.escapechance = 10
	base.transferchance = 20
	base.transferlocation = "contritipetram"
	base.transferchance_secondary = 0
	base.autotransfer_enabled = 1
	base.autotransferchance = 10
	base.autotransferwait = 20 SECONDS
	base.autotransferlocation = "contritipetram"

	base.struggle_messages_inside = list(
		"You squirm and shove against the slick, pliable interior of %pred! Kicking and shoving and squirming, while those walls simply bump and bounce right back into you, letting you wear yourself out...",
		"You push against the heavy walls, trying to make some space for yourself, but the muscles simply flex in on you, shoving you into a cramped position with a deep, resounding GLORP...",
		"You slap and press against %pred's %belly as it scrunshes down on you! You stretch the flesh out a bit with a rolling groooooooan, before it collapses back in on you, a messy glurgle bubbling against you.",
		"When you push out your limbs sink deep into the molten flesh! The gooey texture flows against you, caressing your shape and forming to you for a moment, clinging tightly to you and folding you into an awkward shape. Then with a squelch your limbs are released and you are made to curl up once more.",
		"You try to struggle, but in the same instant you can feel %pred flex inward upon you, as if anticipating your motion, and putting a stop to it before you can do it. The walls roll over you and pin you firmly, squelching and groaning over you as %pred's heartbeat thunders in your ears.",
		"Before you can squirm %pred's walls fold over you, squeezing you tighter, possessive. Not even providing you the opportunity to squirm, positively dominating your experience with a gurgling, groaning press, smothering you heavily for several long moments. You feel all worn out in the aftermath as those walls ease up... if briefly..."
		)

	base.struggle_messages_outside = list(
		"Vague shapes shift under %pred’s hide...",
		"Something solid squirms within %pred...",
		"%pred emits a low ‘uurp’ as something shifts within.",
		"Something bumps and thumps against the inside of %pred.",
		"Something glorps inside of %pred.",
		"%pred’s gut grumbles around something solid...",
		"%pred’s belly rumbles and sways as something moves inside.",
		"Something sloshes inside of %pred.",
		"%pred’s belly burbles noisily.",
		"%pred’s belly shifts noticeably.")

	base.examine_messages = list(
		"There is a noticable swell on their belly.",
		"Their belly seems to hang a bit low.",
		"There seems to be a solid shape distending their belly.")

	base.digest_messages_prey = list(
		"Your vision begins to fade even as the see through flesh folds over your features, collapsing in on you, your softening shape deforming to that of the gut that contained you! Deep bellowing gurgles fill your ears, your senses dulling into nothingness as you are smothered and churned and digested! GWORGLL… Soon there’s nothing but a sticky mess left… a mess that those guts would no doubt relish in soaking up and adding to the glittering body~ Your own mineral content might even add to those pretty gems, living on within the creature..."
		)

	base.emote_lists[DM_DIGEST] = list(
		"The world outside glitters through the flesh to you as you are smothered over and over again in waves of needy pressure. Thick slime sloshes over you as the %belly attempts to soften you up...",
		"%pred's %belly grinds over you heavily, forcing you to curl up into a tiny little ball, smothered in gastric attention.",
		"The walls offer a distorted view of the outside world here, but still hold you fast! Pumping and squeezing against you as they slather you in colorful digestive fluids.",
		"The hot, tight space of %pred's %belly doesn't give you much room to move around, and now and then it seems like the creature delibarately flexes upon you, squeeeeezing you tighter... forcing you a little deeper. Gloorrrggll..."
		)

	base.emote_lists[DM_ABSORB] = list(
		"The walls here are immensely soft, and being as you can see through them a bit, you can actually SEE your own digits sinking into them, see the glittering walls forming to your figure, like being on the inside of a vacuum bag...",
		"The flesh holds you tightly, hot and heavy and oh so soft, squeezing you heavily like a passionate lover, eager for some more attention. %pred's beating heart throbs through everything that touches you.",
		"There is absolutely no space in here that you aren't occupying, and even that space the flesh seems insistent upon reclaiming, squeezing close to you, holding you tighter and tighter, sinking you into the folds little by little, until... well, it's getting hard to tell where you end, and where %pred begins...",
		"The hot, tight space of %pred's %belly doesn't give you much room to move around, and now and then it seems like the creature delibarately flexes upon you, squeeeeezing you tighter... forcing you a little deeper. Gloorrrggll..."
		)

	var/obj/belly/iteration = new /obj/belly(src)
	iteration.name = "contritipetram"	//"I will crush you"
	iteration.desc = "The transparent flesh provides some light through the gaps in the plates here too as you are accepted into the more active chamber. Here, the heavy flesh squeezes more insistently, in quick, tight motions, pumping down on you. While it is slick and lubricated inside of here with a similar gritty fluid, it’s surprisingly dry! You are much more tumbled here, shoved there, worked back to front, front to back, while those walls jerk and smack and work on crushing their contents away into more manageable rubble… Every flex causing the light from outside to wobble and waver, distorted by the flexing muscles."
	iteration.mode_flags = DM_FLAG_THICKBELLY | DM_FLAG_NUMBING
	iteration.belly_fullscreen = "semitrans"
	iteration.colorization_enabled = TRUE
	iteration.belly_fullscreen_color = crystal_color
	iteration.belly_healthbar_overlay_theme = "Tight"
	iteration.belly_healthbar_overlay_color = crystal_color
	iteration.digest_mode = DM_DIGEST
	iteration.digest_brute = 2
	iteration.digest_burn = 0
	iteration.digestchance = 0
	iteration.absorbchance = 0
	iteration.escapechance = 0
	iteration.escapable = TRUE
	iteration.transferchance = 20
	iteration.transferlocation = "tabescet"
	iteration.transferchance_secondary = 10
	iteration.transferlocation_secondary = "nitorepetrae"
	iteration.autotransfer_enabled = 1
	iteration.autotransferchance = 10
	iteration.autotransferwait = 5 SECONDS
	iteration.autotransferlocation = "tabescet"


	iteration.emote_lists[DM_DIGEST] = base.emote_lists[DM_DIGEST]

	iteration.emote_lists[DM_HOLD] = base.emote_lists[DM_HOLD]

	iteration.emote_lists[DM_ABSORB] = base.emote_lists[DM_ABSORB]

	iteration.struggle_messages_inside = base.struggle_messages_inside

	iteration.struggle_messages_outside = base.struggle_messages_outside

	iteration.examine_messages = base.examine_messages

	iteration.digest_messages_prey = base.digest_messages_prey

	iteration = new /obj/belly(src)
	iteration.name = "tabescet"	//"it will melt"
	iteration.desc = "You are quite deep into the creature now, the transparent flesh still provides light, but it is increasingly distorted, hidden away from you as this chamber oozes a thick, strong smelling acid over you. The walls drooling the fluid out, and you can see it welling up behind the flesh before it even flows out and coats you! Any of the gritty fluid from the earlier chambers is broken down into a smooth slurry here as you are given something of a bath in that thick fluid. The chamber itself isn’t all that active, just sort of rocking its contents a little here and there with gentle rolling rings of muscle contracting, just enough to keep anything from settling in too much, ensuring that everything stays moving, stays nice and mixed. It means that it’s a pretty gentle rubbing motion over you, however, even the rocks melt in here…"
	iteration.mode_flags = DM_FLAG_THICKBELLY | DM_FLAG_NUMBING
	iteration.belly_fullscreen = "semitrans"
	iteration.colorization_enabled = TRUE
	iteration.belly_fullscreen_color = crystal_color
	iteration.belly_healthbar_overlay_theme = "Churn"
	iteration.belly_healthbar_overlay_color = crystal_color
	iteration.digest_mode = DM_DIGEST
	iteration.digest_brute = 0
	iteration.digest_burn = 2
	iteration.digestchance = 0
	iteration.absorbchance = 0
	iteration.escapechance = 0
	iteration.escapable = TRUE
	iteration.transferchance = 20
	iteration.transferlocation = "meusestu"
	iteration.transferchance_secondary = 10
	iteration.transferlocation_secondary = "contritipetram"
	iteration.autotransfer_enabled = 1
	iteration.autotransferchance = 10
	iteration.autotransferwait = 5 SECONDS
	iteration.autotransferlocation = "meusestu"

	iteration.emote_lists[DM_DRAIN] = base.emote_lists[DM_DRAIN]

	iteration.emote_lists[DM_DIGEST] = base.emote_lists[DM_DIGEST]

	iteration.emote_lists[DM_HOLD] = base.emote_lists[DM_HOLD]

	iteration.emote_lists[DM_ABSORB] = base.emote_lists[DM_ABSORB]

	iteration.emote_lists[DM_HEAL] = base.emote_lists[DM_HEAL]

	iteration.struggle_messages_inside = base.struggle_messages_inside

	iteration.struggle_messages_outside = base.struggle_messages_outside

	iteration.examine_messages = base.examine_messages

	iteration.digest_messages_prey = base.digest_messages_prey


	iteration = new /obj/belly(src)
	iteration.name = "meusestu" // "with me"
	iteration.desc = "Compared to the previous chambers, the flesh here is surprisingly soft and light. That’s not to say that it isn’t smothering tight and strong, because it is, but it has much more yield to it here! It squeezes into you, filling in the gaps, grinding over you, soaking you in clear fluids and ensuring you can’t move anywhere it doesn’t want! It seems almost to bear down on you the more you squirm! That clear flesh flexing so much that the outside world becomes nothing more than a hazy glow! Hot, heaving flesh pumps against you as your figure sinks against that immensely soft flesh. Whatever was left of the minerals this thing ate would be soaked up here. Pump and churn, glorrgle glorp… perhaps you will be too. "
	iteration.mode_flags = DM_FLAG_THICKBELLY | DM_FLAG_NUMBING
	iteration.belly_fullscreen = "semitrans"
	iteration.colorization_enabled = TRUE
	iteration.belly_fullscreen_color = crystal_color
	iteration.belly_healthbar_overlay_theme = "Tight"
	iteration.belly_healthbar_overlay_color = crystal_color
	iteration.digest_mode = DM_ABSORB
	iteration.digest_brute = 0
	iteration.digest_burn = 0
	iteration.digestchance = 0
	iteration.absorbchance = 0
	iteration.escapechance = 10
	iteration.escapable = TRUE
	iteration.transferchance = 10
	iteration.transferlocation = "tabescet"

	iteration.emote_lists[DM_DRAIN] = base.emote_lists[DM_DRAIN]

	iteration.emote_lists[DM_DIGEST] = base.emote_lists[DM_DIGEST]

	iteration.emote_lists[DM_HOLD] = base.emote_lists[DM_HOLD]

	iteration.emote_lists[DM_ABSORB] = base.emote_lists[DM_ABSORB]

	iteration.emote_lists[DM_HEAL] = base.emote_lists[DM_HEAL]

	iteration.struggle_messages_inside = base.struggle_messages_inside

	iteration.struggle_messages_outside = base.struggle_messages_outside

	iteration.examine_messages = base.examine_messages

	iteration.digest_messages_prey = base.digest_messages_prey


/mob/living/simple_mob/vore/prancer/New()
	color = pick(list("#FFFFFF","#fff9d9","#d9fbff","#f1d9ff","#ffd9d9","#3b3b3b"))
	. = ..()
	crystal_color = random_color()
	update_icon()

/mob/living/simple_mob/vore/prancer/update_icon()
	. = ..()

	var/combine_key = "crystal-[crystal_color]"
	if(stat == DEAD)
		combine_key = "[combine_key]-dead"
	var/image/our_image = overlays_cache[combine_key]
	if(!our_image)
		if(stat == DEAD)
			our_image = image(icon,null,"moon_deer_dead_crystal")
		else
			our_image = image(icon,null,"moon_deer_crystal")
		our_image.color = crystal_color
		our_image.appearance_flags = RESET_COLOR|KEEP_APART|PIXEL_SCALE
		overlays_cache[combine_key] = our_image
	add_overlay(our_image)

	if(stat == DEAD)
		return

	combine_key = "shine"
	our_image = overlays_cache[combine_key]
	if(!our_image)
		our_image = image(icon,null,"moon_deer_shine")
		our_image.appearance_flags = RESET_COLOR|KEEP_APART|PIXEL_SCALE
		overlays_cache[combine_key] = our_image
	add_overlay(our_image)

/datum/say_list/deer/moon
	speak = list("Rooohhh...","Rrrrhhh...","Wooooohhhh...","Wrooh.","Hroh.")

/datum/category_item/catalogue/fauna/moon_deer
	name = "Alien Wildlife - Lunariad Cervune"
	desc = "Despite its soft appearance, this creature is actually quite hard and durable. It partakes of a diet high in minerals, which its body has formed into an incredibly durable armor just under the surface of its skin. The minerals are most notable along its head, back end, and feet, where they are not contained by skin or flesh. The top of its head is adorned in a crown of several sharp horns, and what might otherwise be considered a tail, is a large outcropping of these same crystals. Of note, this creature lacks any feet in the traditional sense, instead having something resembling hooves, but made out of that same crystal. These creatures seem to have a method of chipping and sharpening their hooves, so they are each quite dangerous! With its high mineral diet, this creature has a highly specialized multi compartment digestive tract, and it seems quite capable of and willing to scrap for mineral based meals both processed and otherwise. These creatures are considered a nuisance, as they have a tendency to nibble wires and at the edges of structures, and upon some technology."
	value = CATALOGUER_REWARD_TRIVIAL

/////SKITTERER/////
/mob/living/simple_mob/vore/stellagan
	name = "stellagan"
	desc = "A creature covered in sharp looking plates. It has at least four legs, a long pointy tail, and beady little eyes. It seems to be a fairly well armored little thing!"
	icon = 'icons/rogue-star/mobx32.dmi'
	icon_state = "skitterer"
	icon_living = "skitterer"
	icon_rest = "skitterer-roll"
	icon_dead = "skitterer_dead"
	tt_desc = "lunam serpere"

	ai_holder_type = /datum/ai_holder/simple_mob/passive

	min_oxy = 0
	max_oxy = 0
	min_tox = 0
	max_tox = 0
	min_co2 = 0
	max_co2 = 0
	min_n2 = 0
	max_n2 = 0
	minbodytemp = 0

	armor = list(
			"melee" = 100,
			"bullet" = 100,
			"laser" = 100,
			"energy" = 100,
			"bomb" = 0,
			"bio" = 100,
			"rad" = 100)

	armor_soak = list(
		"melee" = 30,
		"bullet" = 30,
		"laser" = 10,
		"energy" = 10,
		"bomb" = 0,
		"bio" = 100,
		"rad" = 100
		)

	response_help = "pets"
	response_disarm = "rudely paps"
	response_harm = "punches"

	var/rolled_up = FALSE
	var/roll_up_countdown = 0
/////////////////////////////////////// Vore stuff ///////////////////////////////////////////

	swallowTime = 3 SECONDS
	vore_active = 1
	vore_capacity = 1
	vore_bump_chance = 1
	vore_bump_emote	= "suddenly pounces on"
	vore_ignores_undigestable = 0
	vore_default_mode = DM_SELECT
	vore_icons = SA_ICON_LIVING
	vore_stomach_name = "stomach"
	vore_default_contamination_flavor = "Wet"
	vore_default_contamination_color = "grey"
	vore_default_item_mode = IM_HOLD
	vore_bump_chance = 1
	vore_pounce_chance = 1
	vore_pounce_falloff = 0
	vore_standing_too = TRUE

/mob/living/simple_mob/vore/stellagan/init_vore()
	..()

	var/obj/belly/base = vore_selected
	base.name = "stomach"
	base.desc = "The flesh surrounding you is surprisingly soft and pillowy. Smushy in a pleasant kind of way, holding to you securely! You can feel the throb of the creature’s heart pump through the flesh all around you, compressing you a little bit more with each and every beat. A thick, almost jiggly slime coats everything, and seems almost to crawl across your body. It’s hard to tell though if the slime is moving, or if it is just the motion of the insides of the creature and your own body causing the sensation! Either way, it’s hot, steamy, and incredibly tight inside of here!!!"
	base.belly_fullscreen = "anibelly"
	base.belly_healthbar_overlay_theme = "Tight"
	base.belly_healthbar_overlay_color = base.belly_fullscreen_color
	base.digest_brute = 1
	base.digest_burn = 0.5
	base.digest_oxy = 0
	base.digestchance = 0
	base.absorbchance = 0
	base.escapechance = 25

/mob/living/simple_mob/vore/stellagan/New()
	color = pick(list("#FFFFFF","#fff9d9","#a89153","#56758f","#625569","#382d1f","#3b3b3b"))
	var/adjectives = list(
		"brave",
		"undaunted",
		"powerful",
		"asteroid",
		"lunar",
		"skittering",
		"polite",
		"curious",
		"eager",
		"cautious",
		"playful",
		"bounding",
		"prickly",
		"pointy",
		"sharp",
		"bright-eyed",
		"mirthful",
		"dauntless",
		"tiny",
		"little",
		"big",
		"enormouse",
		"needy",
		"aloof",
		)
	name = "[pick(adjectives)] [name]"
	. = ..()

/mob/living/simple_mob/vore/stellagan/verb/roll_up()
	set name = "Roll"
	set desc = "Roll around at the speed of sound, or therabouts."
	set category = "Abilities"

	rolled_up = !rolled_up
	if(rolled_up)
		if(!client)
			roll_up_countdown = 20
		movement_cooldown = -3
	else
		movement_cooldown = 3

	update_icon()

/mob/living/simple_mob/vore/stellagan/Life()
	. = ..()
	if(!client)
		if(roll_up_countdown > 0)
			roll_up_countdown --
		else if(rolled_up)
			roll_up()

/mob/living/simple_mob/vore/stellagan/update_icon()
	. = ..()
	if(stat == DEAD)
		return
	if(rolled_up)
		icon_state = "skitterer-roll"

/mob/living/simple_mob/vore/stellagan/adjustOxyLoss(amount)
	if(amount >= 0 && !rolled_up)
		roll_up()

/mob/living/simple_mob/vore/stellagan/adjustCloneLoss(amount)
	if(amount >= 0 && !rolled_up)
		roll_up()

/mob/living/simple_mob/vore/stellagan/adjustBrainLoss(amount)
	if(amount >= 0 && !rolled_up)
		roll_up()

/mob/living/simple_mob/vore/stellagan/adjustToxLoss(amount)
	if(amount >= 0 && !rolled_up)
		roll_up()

/mob/living/simple_mob/vore/stellagan/adjustHalLoss(amount)
	if(amount >= 0 && !rolled_up)
		roll_up()


/datum/category_item/catalogue/fauna/stellagan
	name = "Alien Wildlife - Lunam Serpere"
	desc = "A small creature with significant armor plating. It is able to curl up its body to better protect itself from harm. This creature shows no fear or aggression to crew life, and seems quite passive in general, preferring to curl up and hide from its troubles than ever fight. It survives in extreme climates thanks to its gut biome being able to break just about anything it eats down into useful compounds that its body can absorb. This means though that as long as there is something that it can fit in its mouth, then it can survive and thrive basically anywhere, so long as whatever the substance is isn’t poisonous to the bacteria. It has six legs underneath its plated body, each tipped with a pair of claws which it can use to grip on to things, however, it is extremely difficult to get it to actually tip over without also curling up, so it is quite difficult to study while alive."
	value = CATALOGUER_REWARD_TRIVIAL

/////RAY/////
/mob/living/simple_mob/vore/dust_stalker
	name = "Dust Stalker"
	desc = "A broad, flat kind of creature. It floats silently above the ground and moves by flapping its body! It’s covered in smooth skin, textured so that it doesn’t reflect light well. "
	icon = 'icons/rogue-star/mobx64.dmi'
	icon_state = "moon_ray"
	icon_living = "moon_ray"
	icon_dead = "moon_ray_dead"
	icon_rest = "moon_ray"
	tt_desc = "sequirian sangune"
	faction = "ray"

	pixel_x = -16
	default_pixel_x = -16

	health = 200
	maxHealth = 200
	melee_damage_lower = 1
	melee_damage_upper = 2
	movement_cooldown = -1

	var/list/overlays_cache = list()
	var/marking_color
	var/eye_color

	ai_holder_type = /datum/ai_holder/simple_mob/melee/hit_and_run/dust_stalker

	min_oxy = 0
	max_oxy = 0
	min_tox = 0
	max_tox = 0
	min_co2 = 0
	max_co2 = 0
	min_n2 = 0
	max_n2 = 0
	minbodytemp = 0

	special_attack_min_range = 1
	special_attack_max_range = 3
	special_attack_cooldown = 15 SECONDS

	response_help = "pets"
	response_disarm = "rudely paps"
	response_harm = "punches"

	hunter = TRUE
	food_pref = CARNIVORE
	var/hiding = FALSE
	var/confidence = 0

/////////////////////////////////////// Vore stuff ///////////////////////////////////////////

	swallowTime = 3 SECONDS
	vore_active = 1
	vore_capacity = 1
	vore_bump_chance = 1
	vore_bump_emote	= "suddenly pounces on"
	vore_ignores_undigestable = 0
	vore_default_mode = DM_DIGEST
	vore_icons = SA_ICON_LIVING
	vore_stomach_name = "stomach"
	vore_default_contamination_flavor = "Wet"
	vore_default_contamination_color = "grey"
	vore_default_item_mode = IM_HOLD
	vore_bump_chance = 5
	vore_pounce_chance = 35
	vore_pounce_falloff = 0
	vore_standing_too = TRUE
	vore_unconcious_eject_chance = 90
	vore_default_item_mode = IM_HOLD

/mob/living/simple_mob/vore/dust_stalker/init_vore()
	..()

	var/obj/belly/base = vore_selected
	base.name = "stomach"
	base.desc = "The flesh isn’t as warm as you would expect as it presses against you, it’s kind of cool and relaxing to the touch. Here and there, you can feel prickly points which poke you. The flesh clings to you, wrapping you up and SQUEEZING you intensely, the flesh folds over you and holds you securely while soaking up any fluid it is able to get ahold of! Its flat body pumps around you as it squishes you out as flat as it can! SMUSH! This must be what it feels like to be juiced… gloorrrglll…"
	base.belly_fullscreen = "anibelly"
	base.colorization_enabled = TRUE
	base.belly_fullscreen_color = marking_color
	base.belly_healthbar_overlay_theme = "Tight"
	base.belly_healthbar_overlay_color = marking_color
	base.digest_brute = 0
	base.digest_burn = 0
	base.digest_oxy = 12
	base.digestchance = 0
	base.absorbchance = 0
	base.escapechance = 10

	base.struggle_messages_outside = list(
		"Something shifts noticably inside of %pred.",
		"A muffled voice grunts out from within of %pred!",
		"Deep rolling GLORPs come out of %pred as something fights inside!"
	)

	base.digest_messages_prey = list(
		"Your world spins as your head gets more and more light, while at the same time, that flesh squeezes in on you heavier, heavier with each passing moment, the warm fluid from inside of you flows out freely, pooling around you and being soaked up through that eager, churning gut, slick squelching rolling over you in intense waves. The sounds of that gut working on you, the beast that had caught you roaring with life, its heart thundering in your ears, while your own slows, and your senses fade away as you are bled dry…",
		)

	base.emote_lists[DM_DIGEST] = list(
		"The walls squeeze you tightly, wringing you like a rag! GLOORRGGNNN...",
		"Intense waves of pressure pump against you with a powerful insistence!",
		"The %pred's heart thunders in your ears as the flesh around you squeezes you tightly!",
		"The walls pump and throb against you so intensely!",
		"The slick flesh folds over you, grinding you all over as it squeezes you so tightly!"
		)

/mob/living/simple_mob/vore/dust_stalker/New()
	color = pick(list("#FFFFFF","#fff9d9","#d9fbff","#f1d9ff","#ffd9d9","#3b3b3b"))
	. = ..()
	marking_color = random_color()
	eye_color = pick(list("#e100ff","#ff0000"))
	update_icon()

/mob/living/simple_mob/vore/dust_stalker/update_icon()
	. = ..()

	var/our_state = "moon_ray_marking"
	if(resting)
		our_state = "[our_state]-[vore_fullness]"
	else if(vore_fullness)
		our_state = "[our_state]-[vore_fullness]"
		icon_state = "[icon_living]-[vore_fullness]"
	var/combine_key = "marking-[marking_color]-[vore_fullness]"
	if(stat == DEAD)
		icon_state = icon_dead
		our_state = "moon_ray_dead_marking"
		combine_key = "marking-[marking_color]-dead"
	var/image/our_image = overlays_cache[combine_key]
	if(!our_image)
		our_image = image(icon,null,our_state)
		our_image.color = marking_color
		our_image.appearance_flags = RESET_COLOR|KEEP_APART|PIXEL_SCALE
		overlays_cache[combine_key] = our_image
	add_overlay(our_image)
	if(stat == DEAD)
		return
	combine_key = "eye-[eye_color]"
	our_image = overlays_cache[combine_key]
	if(!our_image)
		our_image = image(icon,null,"moon_ray_eyes")
		our_image.color = eye_color
		our_image.appearance_flags = RESET_COLOR|KEEP_APART|PIXEL_SCALE
		our_image.plane = PLANE_LIGHTING_ABOVE
		overlays_cache[combine_key] = our_image
	add_overlay(our_image)

/mob/living/simple_mob/vore/dust_stalker/Life()
	. = ..()
	if(resting)
		if(confidence < 20)
			confidence ++
		return
	else
		if(confidence > 0)
			confidence --
		if(health != maxHealth)
			confidence --
	if(ai_holder.stance == STANCE_IDLE)
		if(alpha == 255)
			if(prob(10))
				time_to_hide()
			else
				ai_holder.wander = TRUE

/mob/living/simple_mob/vore/dust_stalker/verb/time_to_hide()
	set name = "Stalk"
	set desc = "Stalk your prey!"
	set category = "Abilities"

	if(resting)
		return

	ai_holder.wander = FALSE
	chameleon_blend()
	cut_overlays()
	icon_state = "moon_ray_hide"
	var/combine_key = "marking-[marking_color]"
	var/image/our_image = overlays_cache[combine_key]
	if(!our_image)
		our_image = image(icon,null,"moon_ray_hide_marking")
		our_image.color = marking_color
		our_image.appearance_flags = RESET_COLOR|KEEP_APART|PIXEL_SCALE
		overlays_cache[combine_key] = our_image
	add_overlay(our_image)

	resting = TRUE

/*
/mob/living/simple_mob/vore/dust_stalker/is_cloaked()
	if(isbelly(loc))
		return TRUE
	if(alpha < 255)
		return TRUE
	if(health != maxHealth)
		return FALSE
	if(nutrition > 1250)
		return FALSE
	return TRUE
*/
/datum/ai_holder/simple_mob/melee/hit_and_run/dust_stalker/special_flee_check()
	if(!istype(holder, /mob/living/simple_mob/vore/dust_stalker))
		return FALSE
	var/mob/living/simple_mob/vore/dust_stalker/ds = holder
	if(isbelly(ds.loc))
		return FALSE
	if(ds.hiding)
		return FALSE
	if(ds.confidence > 0)
		return FALSE
	return TRUE

/mob/living/simple_mob/vore/dust_stalker/prey_unconcious(mob/living/L)
	. = ..()
	if(.)
		hiding = FALSE
		resting = FALSE
		confidence = 0

/mob/living/simple_mob/vore/dust_stalker/do_special_attack(atom/A)
	set waitfor = FALSE
	if(!isliving(A))
		return FALSE
	var/mob/living/L = A
	if(L.stat != CONSCIOUS)
		return FALSE
	if(L.isSynthetic())
		return FALSE
	set_AI_busy(TRUE)
	// Telegraph, since getting stunned suddenly feels bad.
	do_windup_animation(L, 0.5 SECOND)
	sleep(0.5 SECOND) // For the telegraphing.

	// Do the actual leap.
	visible_message(span("critical","\The [src] dashes toward \the [L]!"))
	throw_at(get_step(L, get_turf(src)), 3, 1, src)
	playsound(src, 'sound/effects/teleport.ogg', 75, 1)

	sleep(5) // For the throw to complete. It won't hold up the AI ticker due to waitfor being false.

	set_AI_busy(FALSE)

	Weaken(1)
	for(var/mob/living/thing in view(1,get_turf(src)))
		if(isliving(thing))
			if(thing.faction != faction)
				thing.Weaken(2)
				thing.Stun(2)
				sleep(5)
				throw_at(get_step(L, get_turf(src)), 3, 1, src)
				if(thing.client)
					to_chat(thing,span("critical","\The [src] pushes you down and pins you under its body!!!"))
				thing.add_modifier(/datum/modifier/ray_pinned,5 SECONDS,src)
				break
	return TRUE

/datum/modifier/ray_pinned
	name = "Ray Pinned"
	var/mob/living/our_ray

/datum/modifier/ray_pinned/New(new_holder, new_origin)
	. = ..()
	if(isliving(new_origin))
		our_ray = new_origin
	else
		expire()
		return
	our_ray.set_AI_busy(TRUE)
	holder.weakened = 2
	holder.stunned = 2
	our_ray.weakened = 2
	to_chat(holder, SPAN_DANGER("\The [our_ray] latches on to you!!!"))

/datum/modifier/ray_pinned/tick()
	. = ..()
	if(holder.stat)
		expire()
		return
	if(isbelly(holder.loc))
		expire()
		return
	if(our_ray.loc != holder.loc)
		expire()
		return
	holder.weakened = 2
	holder.stunned = 2
	our_ray.weakened = 2
	our_ray.set_AI_busy(TRUE)
	if(ishuman(holder))
		var/mob/living/carbon/human/H = holder
		H.remove_blood(15)
	else
		holder.adjustOxyLoss(15)
	our_ray.adjust_nutrition(250)
	to_chat(holder, SPAN_DANGER("\The [our_ray] sucks something out of you!!!"))
	holder.visible_message(runemessage = "glorp")

/datum/modifier/ray_pinned/expire(silent)
	. = ..()

	our_ray.set_AI_busy(FALSE)
	to_chat(holder, SPAN_NOTICE("\The [our_ray] lets you go..."))

/datum/category_item/catalogue/fauna/dust_stalker
	name = "Alien Wildlife - Sequirian Sangune"
	desc = "A dangerous predatory creature known to blend in with its surroundings and then to quickly strike, and drain blood from its victims. It floats above the ground by some unknown process, thought to be to do with some internal magnetism. Its skin can rapidly change color, and it has enough wisdom to know to stay perfectly still while so hidden. When it detects a potential prey item, it rushes them down, using its flat body to pounce upon them, and pin them to the ground, where it is free to bite them, and draw blood out. Once again, it has enough wisdom to not drain prey dry, usually trying to leave them alive so that they can be fed upon again in the future. This behavior does not extend to groups of these creatures however, as together, a group may drain someone dry in a matter of moments! These creatures have immense self preservation though, as the moment their prey is actually able to fight back, they will run away."
	value = CATALOGUER_REWARD_MEDIUM

/*
/mob/living/simple_mob/vore/moon_dragon
	name = "moon dragon"
	desc = "A dragon from the moon, can't get much more obvious than that! Does it have three eyes?"
*/
