//RS FILE

/////MOON DEER/////
/mob/living/simple_mob/vore/prancer
	name = "lunar prancer"
	desc = "A creature with a long neck and four long legs, strikingly, each leg ends in a vicious looking crystal spike, which it walks around upon. It has several small crystal horns on its head in a kind of crownlike pattern, and an almost poofy looking tail made of crystal! It looks quite soft!"
	icon = 'icons/rogue-star/mobx32.dmi'
	icon_state = "moon_deer"
	icon_living = "moon_deer"
	icon_dead = "deer_dead"
	icon_rest = "deer_rest"

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
		"The walls squeeze and grind across your figure, bathing you in caustic slime with each pass, softening you up little by little until you fade away entirely within %pred, plumping out their body.",
		"A cacophony of gurgling and burbling sounds out as the walls collapse in on you, reducing you to naught more than sloppy nutrients for %pred to absorb!",
		"Your surroundings throb and churn around you with immense weight and powebase. Squeezing you tighter and tighter with every beat of %pred's heart! The walls fold in around you and clench you tightly until there's nothing left! %pred gives off a little belch to punctuate your stay.",
		"Each beat of %pred's heart throbs through the flesh around you, a soothing rumbling to fall into as those walls close in on you with their smothering churns. Your senses fade away as you fall into a dream, and give yourself to %pred..."
		)

	base.emote_lists[DM_HOLD] = list(
		"The walls press over you here and there as %pred moves...",
		"%pred's heartbeat pumps under the surface of the flesh surrounding you, making the whole area throb with every beat.",
		"The molten pressure of the walls forms them to your shape and fills in any space they can wedge intiteration.",
		"Every moment within %pred gets you ever more soaked, dripping with stringy fluids that connect between you and the surroundings!",
		"%pred gives a happy little sigh now and then when you shift or move.",
		"An almost deafening GLORGLE bubbles up from somewhere deeper within %pred! Oh deabase...",
		"A rush of air burbles up passed you as %pred's body CLENCHES inward around you. A moment later a rumbling 'bworp' sounds out from up above...",
		"Doughy flesh rumbles a bit as it closes in on you, holding you close as %pred takes a deep breath. As the lungs inflate somewhere nearby, you can hear the whoosh, and the space available to you shrinks as those walls close in, squeeeeeeezing you for a moment, before %pred breathes out again in a little sigh.",
		"The walls suddenly clench inward, squeezing you and squelching against your figure as %pred hiccups.",
		"Somewhere deeper within %pred something burbles, a low, deep sound."
		)

	base.emote_lists[DM_DIGEST] = list(
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

	base.emote_lists[DM_ABSORB] = list(
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
	var/image/our_image = overlays_cache[combine_key]
	if(!our_image)
		our_image = image(icon,null,"moon_deer_crystal")
		our_image.color = crystal_color
		our_image.appearance_flags = RESET_COLOR|KEEP_APART|PIXEL_SCALE
		overlays_cache[combine_key] = our_image
	add_overlay(our_image)

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
/mob/living/simple_mob/vore/moon_skitterer
	name = ""
	desc = "A creature covered in sharp looking plates. It has at least four legs, and a long, hard pointy tail."
	icon = 'icons/rogue-star/mobx32.dmi'
	icon_state = "skitterer"
	icon_living = "skitterer"
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

/mob/living/simple_mob/vore/moon_skitterer/New()
	color = pick(list("#FFFFFF","#fff9d9","#a89153","#56758f","#625569","#382d1f","#3b3b3b"))
	. = ..()


/////RAY/////
/mob/living/simple_mob/vore/moon_ray
	name = "moon ray"
	desc = "A large, somewhat flat kind of creature that has adapted to float above the ground!"
	icon = 'icons/rogue-star/mobx64.dmi'
	icon_state = "moon_ray"
	icon_living = "moon_ray"
	tt_desc = "lunae angit"
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
	ai_holder_type = /datum/ai_holder/simple_mob
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
	food_pref = CARNIVORE

	vore_active = TRUE
	vore_capacity = 1

/mob/living/simple_mob/vore/moon_ray/New()
	color = pick(list("#FFFFFF","#fff9d9","#d9fbff","#f1d9ff","#ffd9d9","#3b3b3b"))
	. = ..()
	marking_color = random_color()
	eye_color = pick(list("#e100ff","#ff0000"))
	update_icon()

/mob/living/simple_mob/vore/moon_ray/update_icon()
	. = ..()

	var/our_state = "moon_ray_marking"
	if(vore_fullness)
		our_state = "[our_state]-[vore_fullness]"
		icon_state = "[icon_living]-[vore_fullness]"
	var/combine_key = "marking-[marking_color]-[vore_fullness]"
	var/image/our_image = overlays_cache[combine_key]
	if(!our_image)
		our_image = image(icon,null,our_state)
		our_image.color = marking_color
		our_image.appearance_flags = RESET_COLOR|KEEP_APART|PIXEL_SCALE
		overlays_cache[combine_key] = our_image
	add_overlay(our_image)

	combine_key = "eye-[eye_color]"
	our_image = overlays_cache[combine_key]
	if(!our_image)
		our_image = image(icon,null,"moon_ray_eyes")
		our_image.color = eye_color
		our_image.appearance_flags = RESET_COLOR|KEEP_APART|PIXEL_SCALE
		our_image.plane = PLANE_LIGHTING_ABOVE
		overlays_cache[combine_key] = our_image
	add_overlay(our_image)

/mob/living/simple_mob/vore/moon_ray/Life()
	. = ..()
	if(ai_holder.stance == STANCE_IDLE)
		if(alpha == 255)
			if(prob(10))
				ai_holder.wander = FALSE
				chameleon_blend()
			else
				ai_holder.wander = TRUE



















/mob/living/simple_mob/vore/scarybot/quad_bot/do_special_attack(atom/A)
	set waitfor = FALSE
	if(!isliving(A))
		return FALSE
	var/mob/living/L = A

	if(L.stat != CONSCIOUS)
		return FALSE

	set_AI_busy(TRUE)
	visible_message(span("warning","\The [src]'s eyes flash ominously!"))
	// Telegraph, since getting stunned suddenly feels bad.
	do_windup_animation(L, 0.5 SECOND)
	sleep(0.5 SECOND) // For the telegraphing.

	// Do the actual leap.
	visible_message(span("critical","\The [src] leaps at \the [L]!"))
	throw_at(get_step(L, get_turf(src)), 3, 1, src)
	playsound(src, 'sound/effects/teleport.ogg', 75, 1)

	sleep(5) // For the throw to complete. It won't hold up the AI ticker due to waitfor being false.

	set_AI_busy(FALSE)

	visible_message(span("danger","\The [src] emits a shrill metalic shriek!!!"))
	playsound(src, 'sound/effects/screech.ogg', 75, 1)
	Weaken(1)
	for(var/mob/living/thing in view(2,get_turf(src)))
		if(isliving(thing))
			if(thing.faction != faction)
				if(thing.client)
					to_chat(thing,span("critical","The sound causes you to stumble!"))
				thing.Weaken(2)
				forceMove(get_turf(thing))
				thing.add_modifier(/datum/modifier/ray_pinned,5 SECONDS)
				break






/datum/modifier/ray_pinned
	name = "Ray Pinned"
	var/mob/living/our_ray

/datum/modifier/ray_pinned/New(new_holder, new_origin)
	. = ..()
	if(isliving(new_origin))
		our_ray = new_origin
	our_ray.ai_holder.set_AI_busy(TRUE)
	holder.weakened = 2
	our_ray.weakened = 2

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
	our_ray.ai_holder.set_AI_busy(TRUE)
	if(ishuman(holder))
		var/mob/living/carbon/human/H
		H.remove_blood(82)
	else
		holder.adjustOxyLoss(25)
	our_ray.adjust_nutrition(250)
	holder.weakened = 2
	our_ray.weakened = 2

/datum/modifier/ray_pinned/expire(silent)
	. = ..()

	our_ray.ai_holder.set_AI_busy(FALSE)



/////OUTISE MVP/////
/mob/living/simple_mob/vore/moon_dragon
	name = "moon dragon"
	desc = "A dragon from the moon, can't get much more obvious than that! Does it have three eyes?"
