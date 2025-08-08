/datum/category_item/catalogue/fauna/deer
	name = "Alien Wildlife - White-tailed Chital"
	desc = "White-tailed Chital are a genetic variant based on two different species of deer originating from Sol 3. \
	Originally created by the eccentric and the wealthy to combine the appealing aesthetics of Chital and White tailed deer,\
	White-tailed Chital proliferated unexpectedly outside of captivity, and have spread to many systems due to carelessness and smuggling.\
	White-tailed Chital are hoofed medium sized evasive quadrupedal ruminant mammals of the family Cervidae.\
	Deer in general are known to be invasive and can be a hazard to ecosystems where they do not belong. Otherwise White-tailed Chital present \
	little threat to people, and are hunted for sport, meat, and furs in some regions. Commonly referred to as space deer, but despite the name \
	white-tailed Chital in fact can not survive in space."
	value = CATALOGUER_REWARD_TRIVIAL

/mob/living/simple_mob/vore/deer
	name = "space deer"
	desc = "Spotty brown fur, long neck, thin legs and hooves! Yup! Looks like a space deer!"
	tt_desc = "Odocoileus Axis"
	icon_state = "deer"
	icon_living = "deer"
	icon_dead = "deer_dead"
	icon_rest = "deer_rest"
	icon = 'icons/rogue-star/mobx32.dmi'

	faction = "deer"
	maxHealth = 60
	health = 60
	movement_cooldown = -1
	meat_amount = 5
	meat_type = /obj/item/weapon/reagent_containers/food/snacks/meat

	response_help = "pets"
	response_disarm = "rudely paps"
	response_harm = "punches"

	melee_damage_lower = 1
	melee_damage_upper = 3

	catalogue_data = list(/datum/category_item/catalogue/fauna/deer)

	attacktext = list("nipped", "kicked", "bonked")
	friendly = list("sniffs", "nuzzles", "nibbles")

	ai_holder_type = /datum/ai_holder/simple_mob/oregrub

	mob_size = MOB_MEDIUM

	has_langs = list(LANGUAGE_ANIMAL)
	say_list_type = /datum/say_list/deer

	hunter = TRUE
	food_pref = HERBIVORE
	food_pref_obligate = TRUE

	var/run_over = FALSE	//teehee

/////////////////////////////////////// Vore stuff///////////////////////////////////////////

	swallowTime = 2 SECONDS
	vore_active = 1
	vore_capacity = 2
	vore_bump_chance = 1
	vore_bump_emote	= "suddenly pounces on"
	vore_ignores_undigestable = 0
	vore_default_mode = DM_HOLD
	vore_icons = SA_ICON_LIVING
	vore_stomach_name = "rumen"
	vore_default_contamination_flavor = "Wet"
	vore_default_contamination_color = "grey"
	vore_default_item_mode = IM_DIGEST
	vore_bump_chance = 5
	vore_pounce_chance = 35
	vore_pounce_falloff = 0
	vore_standing_too = TRUE

//rumen (hold) > reticulum (light digest) > omasum (absorb) > abomasum (heavy digest)
//escapabale                                                  escapable

/mob/living/simple_mob/vore/deer/init_vore()
	..()

	var/obj/belly/R = vore_selected
	R.name = "rumen"
	R.desc = "Hang on just a minute. You got eaten by a deer?! It's hot and slick, the flesh squeezing in heavily across you, slick and tight... though this chamber doesn't seem to be all that active. A stuffy, squeezing holding chamber... though you can smell the acrid scents of whatever is going on deeper inside rising up passed you... Little belches rumbling out passed you here and there while the walls cling to you. You can feel the strong, steady beating of the deer's heart thundering close by, the pulse throbbing through the flesh all around you as you are held close... stocked away for when the deer is ready for you. Kept."
	R.mode_flags = DM_FLAG_THICKBELLY | DM_FLAG_NUMBING
	R.belly_fullscreen = "yet_another_tumby"
	R.digest_brute = 0
	R.digest_burn = 0
	R.digestchance = 0
	R.absorbchance = 0
	R.escapechance = 10
	R.transferchance = 20
	R.transferlocation = "reticulum"
	R.transferchance_secondary = 0
	R.autotransfer_enabled = 1  // Updated as part of broader autotransfer update
	R.autotransferchance = 10
	R.autotransferwait = 20 SECONDS
	R.autotransferlocation = "reticulum"

	R.struggle_messages_inside = list(
		"You squirm and shove against the slick, pliable interior of %pred! Kicking and shoving and squirming, while those walls simply bump and bounce right back into you, letting you wear yourself out...",
		"You push against the heavy walls, trying to make some space for yourself, but the muscles simply flex in on you, shoving you into a cramped position with a deep, resounding GLORP...",
		"You slap and press against %pred's %belly as it scrunshes down on you! You stretch the flesh out a bit with a rolling groooooooan, before it collapses back in on you, a messy glurgle bubbling against you.",
		"When you push out your limbs sink deep into the molten flesh! The gooey texture flows against you, caressing your shape and forming to you for a moment, clinging tightly to you and folding you into an awkward shape. Then with a squelch your limbs are released and you are made to curl up once more.",
		"You try to struggle, but in the same instant you can feel %pred flex inward upon you, as if anticipating your motion, and putting a stop to it before you can do it. The walls roll over you and pin you firmly, squelching and groaning over you as %pred's heartbeat thunders in your ears.",
		"Before you can squirm %pred's walls fold over you, squeezing you tighter, possessive. Not even providing you the opportunity to squirm, positively dominating your experience with a gurgling, groaning press, smothering you heavily for several long moments. You feel all worn out in the aftermath as those walls ease up... if briefly..."
		)

	R.struggle_messages_outside = list(
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

	R.examine_messages = list(
		"There is a noticable swell on their belly.",
		"Their belly seems to hang a bit low.",
		"There seems to be a solid shape distending their belly.")

	R.digest_messages_prey = list(
		"The walls squeeze and grind across your figure, bathing you in caustic slime with each pass, softening you up little by little until you fade away entirely within %pred, plumping out their body.",
		"A cacophony of gurgling and burbling sounds out as the walls collapse in on you, reducing you to naught more than sloppy nutrients for %pred to absorb!",
		"Your surroundings throb and churn around you with immense weight and power. Squeezing you tighter and tighter with every beat of %pred's heart! The walls fold in around you and clench you tightly until there's nothing left! %pred gives off a little belch to punctuate your stay.",
		"Each beat of %pred's heart throbs through the flesh around you, a soothing rumbling to fall into as those walls close in on you with their smothering churns. Your senses fade away as you fall into a dream, and give yourself to %pred..."
		)

	R.emote_lists[DM_HOLD] = list(
		"The walls press over you here and there as %pred moves...",
		"%pred's heartbeat pumps under the surface of the flesh surrounding you, making the whole area throb with every beat.",
		"The molten pressure of the walls forms them to your shape and fills in any space they can wedge into.",
		"Every moment within %pred gets you ever more soaked, dripping with stringy fluids that connect between you and the surroundings!",
		"%pred gives a happy little sigh now and then when you shift or move.",
		"An almost deafening GLORGLE bubbles up from somewhere deeper within %pred! Oh dear...",
		"A rush of air burbles up passed you as %pred's body CLENCHES inward around you. A moment later a rumbling 'bworp' sounds out from up above...",
		"Doughy flesh rumbles a bit as it closes in on you, holding you close as %pred takes a deep breath. As the lungs inflate somewhere nearby, you can hear the whoosh, and the space available to you shrinks as those walls close in, squeeeeeeezing you for a moment, before %pred breathes out again in a little sigh.",
		"The walls suddenly clench inward, squeezing you and squelching against your figure as %pred hiccups.",
		"Somewhere deeper within %pred something burbles, a low, deep sound."
		)

	R.emote_lists[DM_DIGEST] = list(
		"The walls churn intensely around you, squeezing in and smearing you in caustic slime.",
		"The steamy heat of the active walls smother over your features, gurgling and slurping against you intensely!",
		"The rhythmic motion of %pred's walls moving fills your ears with squelches and deep gurgles as they fold in over you and pin you into new, interesting shapes!",
		"The walls close in on you, squeezing you heavily, churning up and down and all around, smearing you in caustic juices!!!",
		"%pred's flesh pummels inward, gripping and pumping against your figure, actively churning you down!",
		"The folds of flesh pin your arms to your sides as they squeeze you and grind the belly's contents over your form!",
		"The fluids inside of %pred bubble and smear over your form!",
		"%pred's %belly GLORGLES and burbles against you, every shift of weight eliciting a sloppy slurp or gurgling squelch!",
		"For a moment the walls really squeeze inward on you, folding over your form and pressing down, grinding heavier and heavier!! Sloppy slimy sweltering and sticky! Immense pressure hold on to you as those gurglings fill your ears! Stringy fluids stick to you as those walls try to break you down... They slowly, slowly ease up on you over time, but never quite back off of you...",
		"Your weight bounces and tips as %pred moves around! The walls stretch and push you back into the center of the %belly through tension alone."
		)

	R.emote_lists[DM_ABSORB] = list(
		"The doughy press of the walls cling to you as they slurp and squelch with each and every move.",
		"The walls of %pred's %belly close in on you, the molten texture clinging to you, forming to your shape and squeezing in on you possessively!",
		"With every press of %pred's %belly you seem to sink into the flesh a little bit more...",
		"The walls close in on you, pressing in on you a little tighter with each beat of %pred's heart...",
		"When you shift your weight to reposition, you find that pressing any of your limbs into the flesh causes them to sink in deep, not offering you any leverage at all! It takes a lot of effort to pull it back out!",
		"%pred's %belly presses in on you tightly, not giving you any room to move at all! No matter how you squirm or pull away, the walls seem only to cling on you greedily!",
		"The moisture around you seems to soak right into %pred's flesh, and where that moisture soaks in, you find it ever more difficult to pull away!",
		"%pred slowly takes a breath, and as they doo, the space around you seems to grow tighter, squeezing you more and more snugly with each passing moment, as the lungs nearby put pressure on you, sinking you into the flesh of %pred's %belly that much more quickly!",
		"The molten touch of %pred's %belly folds over you, clenching inward and squelching as you are plunged into it with every swelling throb of that flesh!",
		"You struggle to keep your head free as the walls close in on you, squishing and slathering you in slime. You can push and shove at the flesh all you want, but it only results in your digits sinking deeper into %pred!"
		)


	var/obj/belly/reticulum = new /obj/belly(src)
	reticulum.name = "reticulum"
	reticulum.desc = "You sink deeper into the deer, squelching through a tight opening and on into the source of those acrid scents! You don't drop inside so much as slide through a valve and into the embrace of a cramped chamber, half full of mashed up grass and leaves! It's sticky and horribly smelly! A chamber for fermenting the things the deer eats! You are smeared in those tingling fluids, covered in the digesting gunk and squeezed here and there as the deer continues about its day. Whether fortunate or not, the chamber seems to be taking its time, leaving you to tingle and stew in the slowly softening cud. Now and then this chamber FLEXES tightly around you, and the smelly air is forced out and up, the deer belching loudly..."
	reticulum.mode_flags = DM_FLAG_THICKBELLY | DM_FLAG_NUMBING
	reticulum.belly_fullscreen = "multi_layer_test_tummy"
	reticulum.colorization_enabled = TRUE
	reticulum.digest_mode = DM_DIGEST
	reticulum.digest_brute = 0
	reticulum.digest_burn = 0.05
	reticulum.digestchance = 0
	reticulum.absorbchance = 0
	reticulum.escapechance = 0
	reticulum.escapable = TRUE
	reticulum.transferchance = 20
	reticulum.transferlocation = "omasum"
	reticulum.transferchance_secondary = 10
	reticulum.transferlocation_secondary = "rumen"
	reticulum.autotransfer_enabled = 1  // Updated as part of broader autotransfer update
	reticulum.autotransferchance = 10
	reticulum.autotransferwait = 5 SECONDS
	reticulum.autotransferlocation = "omasum"


	reticulum.emote_lists[DM_DIGEST] = R.emote_lists[DM_DIGEST]

	reticulum.emote_lists[DM_HOLD] = R.emote_lists[DM_HOLD]

	reticulum.emote_lists[DM_ABSORB] = R.emote_lists[DM_ABSORB]

	reticulum.struggle_messages_inside = R.struggle_messages_inside

	reticulum.struggle_messages_outside = R.struggle_messages_outside

	reticulum.examine_messages = R.examine_messages

	reticulum.digest_messages_prey = R.digest_messages_prey

	var/obj/belly/O = new /obj/belly(src)
	O.name = "omasum"
	O.desc = "You sink yet further into the deer! The cud at this point has become really sloppy and gooey, and those CLENCHING possessive walls pump in heavily against you, soaking up all of the moisture, smothering you repeatedly as they flex and squeeze and wring against your body! You find that things become relatively dry inside of there pretty quickly... but those walls are so very soft and tarry to the touch! The fold over you and squeeze you tightly, letting your figure sink deep into their hold, forming to your shape like shrink wrap! If you stay here you might get soaked right up!!!"
	O.mode_flags = DM_FLAG_THICKBELLY | DM_FLAG_NUMBING
	O.belly_fullscreen = "anibelly"
	O.colorization_enabled = TRUE
	O.digest_mode = DM_ABSORB
	O.digest_brute = 0
	O.digest_burn = 0
	O.digestchance = 0
	O.absorbchance = 0
	O.escapechance = 0
	O.escapable = TRUE
	O.transferchance = 20
	O.transferlocation = "abomasum"
	O.transferchance_secondary = 10
	O.transferlocation_secondary = "reticulum"
	O.autotransfer_enabled = 1  // Updated as part of broader autotransfer update
	O.autotransferchance = 10
	O.autotransferwait = 5 SECONDS
	O.autotransferlocation = "abomasum"

	O.emote_lists[DM_DRAIN] = R.emote_lists[DM_DRAIN]

	O.emote_lists[DM_DIGEST] = R.emote_lists[DM_DIGEST]

	O.emote_lists[DM_HOLD] = R.emote_lists[DM_HOLD]

	O.emote_lists[DM_ABSORB] = R.emote_lists[DM_ABSORB]

	O.emote_lists[DM_HEAL] = R.emote_lists[DM_HEAL]

	O.struggle_messages_inside = R.struggle_messages_inside

	O.struggle_messages_outside = R.struggle_messages_outside

	O.examine_messages = R.examine_messages

	O.digest_messages_prey = R.digest_messages_prey


	var/obj/belly/A = new /obj/belly(src)
	A.name = "abomasum"
	A.desc = "With the rest of the gunk having largely been left behind, you slide onward, yet deeper into the deer, into a somewhat larger chamber. Having more space doesn't really help you though as you quickly find that this chamber is positively oozing with highly caustic fluid. A thick layer of the stuff quickly coating you as those walls throb and pump and churn over you in an intense wash of molten hot flesh. The deer's digestive tract isn't playing around anymore, gripping you firmly and really working those fluids into you!!!"
	A.mode_flags = DM_FLAG_THICKBELLY | DM_FLAG_NUMBING
	A.belly_fullscreen = "anibelly"
	A.colorization_enabled = TRUE
	A.belly_fullscreen_color = "#411717"
	A.digest_mode = DM_DIGEST
	A.digest_brute = 2
	A.digest_burn = 6
	A.digestchance = 0
	A.absorbchance = 0
	A.escapechance = 10
	A.escapable = TRUE
	A.transferchance = 10
	A.transferlocation = "omasum"

	A.emote_lists[DM_DRAIN] = R.emote_lists[DM_DRAIN]

	A.emote_lists[DM_DIGEST] = R.emote_lists[DM_DIGEST]

	A.emote_lists[DM_HOLD] = R.emote_lists[DM_HOLD]

	A.emote_lists[DM_ABSORB] = R.emote_lists[DM_ABSORB]

	A.emote_lists[DM_HEAL] = R.emote_lists[DM_HEAL]

	A.struggle_messages_inside = R.struggle_messages_inside

	A.struggle_messages_outside = R.struggle_messages_outside

	A.examine_messages = R.examine_messages

	A.digest_messages_prey = R.digest_messages_prey


/datum/say_list/deer
	speak = list("*belch")
	emote_hear = list("grunts", "chuffs", "huffs", "bellows", "bleats")
	emote_see = list("turns its head", "looks at you", "flicks its tail", "nibbles something off of the ground", "looks around", "stops and stares at something in the distance")

/mob/living/simple_mob/vore/deer/Bumped(atom/movable/AM, yes)
	if(istype(AM, /obj/vehicle) && stat != DEAD)
		run_over = TRUE
		visible_emote("is run over by \the [AM]!!!")
		death()
	else ..()

/mob/living/simple_mob/vore/deer/update_icon()
	. = ..()
	if(run_over)
		icon_state = "deer_dead_alt"

/mob/living/simple_mob/vore/deer/Crossed(atom/movable/AM)
	if(istype(AM, /obj/vehicle) && stat != DEAD)
		run_over = TRUE
		visible_emote("is run over by \the [AM]!!!")
		death()
	else ..()

/datum/ai_holder/simple_mob/evasive
	hostile = FALSE
	retaliate = TRUE
	can_flee = TRUE
	dying_threshold = 1
	flee_when_outmatched = TRUE
	outmatched_threshold = 25
	cooperative = TRUE
