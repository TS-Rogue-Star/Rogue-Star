//RS FILE
//////////////////GENERAL TYPE//////////////////
/mob/living/simple_mob/vore/scarybot
	name = "robot"
	tt_desc = "robot"
	faction = "robot"
	icon = 'icons/rogue-star/mobx32.dmi'
	icon_state = "wander-bot"
	icon_living = "wander-bot"
	icon_dead = "wander-bot_dead"
	ai_holder_type = /datum/ai_holder/simple_mob/vore/robots
	load_owner = "seriouslydontsavethis"	//they smort
	say_list_type = /datum/say_list/robot
	var/static/list/overlays_cache = list()
	var/sound_cooldown = 0
	var/static/list/spooky_sounds = list(
		'sound/goonstation/spooky/basket_noises1.ogg',
		'sound/goonstation/spooky/basket_noises2.ogg',
		'sound/goonstation/spooky/basket_noises3.ogg',
		'sound/goonstation/spooky/basket_noises4.ogg',
		'sound/goonstation/spooky/basket_noises5.ogg',
		'sound/goonstation/spooky/basket_noises6.ogg',
		'sound/goonstation/spooky/basket_noises7.ogg',
		'sound/goonstation/spooky/Station_SpookyAtmosphere1.ogg',
		'sound/goonstation/spooky/Station_SpookyAtmosphere2.ogg',
		'sound/goonstation/spooky/Void_Calls.ogg',
		'sound/goonstation/spooky/Void_Hisses.ogg',
		'sound/goonstation/spooky/Void_Screaming.ogg',
		'sound/goonstation/spooky/Void_Song.ogg',
		'sound/goonstation/spooky/Void_Wail.ogg'
		)

	mob_size = MOB_LARGE
	mob_bump_flag = HEAVY
	mob_swap_flags = HEAVY
	mob_push_flags = HEAVY
	mob_size = MOB_LARGE

	has_hands = TRUE
	humanoid_hands = TRUE
	movement_cooldown = 2

	capture_crystal = FALSE

	glow_toggle = TRUE
	glow_range = 0.5
	glow_intensity = 0.5

	low_priority = FALSE

///// VORE RELATED /////
	vore_active = 1

	swallowTime = 1 SECONDS
	vore_capacity = 1
	vore_bump_chance = 25
	vore_bump_emote	= "collects"
	vore_digest_chance = 0
	vore_absorb_chance = 0
	vore_escape_chance = 25
	vore_pounce_chance = 35
	vore_ignores_undigestable = 0
	vore_default_mode = DM_SELECT
	vore_icons = SA_ICON_LIVING
	vore_stomach_name = "hold"
	vore_stomach_flavor = "The walls here are made of light, which makes them surprisingly delicate and thin! At the same time, they seem perfectly capable of holding on to you and your weight, forcing you to fold up into a small shape! They form to your figure and hold you tightly! Squeezed into the glowing confines. It's soft and slick and very very warm, but not wet at all! The air inside is toasty! You have been gathered up by a robot!"
	vore_default_contamination_flavor = "Wet"
	vore_default_contamination_color = "grey"
	vore_default_item_mode = IM_DIGEST
	vore_standing_too = TRUE

/mob/living/simple_mob/vore/scarybot/init_vore()
	..()
	var/obj/belly/B = vore_selected
	B.mode_flags = DM_FLAG_THICKBELLY | DM_FLAG_NUMBING
	B.belly_fullscreen = "robot"
	B.colorization_enabled = TRUE
	B.belly_fullscreen_color = "#3a311d"
	B.belly_fullscreen_color_secondary = "#ffbb00"
	B.belly_fullscreen_color_trinary = glow_color
	B.is_wet = FALSE
	B.wet_loop = FALSE
	B.digest_brute = 0
	B.digest_burn = 2
	B.escape_stun = 5
	B.vore_sound = "Schlorp"
	B.absorbed_desc = "The walls squeeze inward until there is nowhere else for you to go! You fall through the glowing hold, and down... down through the air... It all rushes past you, ripping the breath from your lungs and whipping past your ears, and then you land heavily on the ground! Warmed from within by some otherworldly heat. And indeed, a whole other world spreads out before you, glowing with light, creatures you have never seen before going about their business. Dark landmass arcing into the sky, laced with forks of glow. And above, in the sky, an infinity of darkness held in the sky by a tower. You aren't sure what that is, but it certainly doesn't look like it belongs there. And the creatures around you certainly seem to give it distressing looks. You seem to have found yourself trapped in some other world... how will you escape this hotscape?"
	B.struggle_messages_outside = list(
		"%pred hardly reacts as something shifts within its %belly.",
		"Something struggles within %pred's belly.",
		"Something shifts inside of %pred!"
		)
	B.struggle_messages_inside = list(
		"The energy forms tightly to your form as you struggle. It's soft and feels delicate, but it's stong enough to hold you up!",
		"Your struggles cause the energy comprising the walls to hiss and crackle with the effort of holding on to you.",
		"You squirm and stretch the space within %pred!",
		"The light clamps down on you when you struggle, trying desperately to hold on to you!"
	)
	B.absorbed_struggle_messages_outside = list(
		"The light under %pred's armor glimmers with untold knowings..."
	)
	B.absorbed_struggle_messages_inside = list(
		"You try to find a way out of this unknown world. It isn't your own.",
		"You have to get back home, this place isn't for you! You try to find a way back.",
		"You run across alien lands and alien figures, trying to find your way home!"
	)
	B.escape_fail_messages_prey = list(
		"The light wraps you up tighter and holds you close, probing over your figure once more, strengthening its grasp on you.",
		"Your body gives out and you fall back into %pred's %belly.",
		"%pred shifts their weight, causing your effort to push free to go wrong! You fall into an uncomfortable heap and are squeezed once more by %pred's interior!"
	)
	B.escape_attempt_absorbed_messages_prey = list(
		"In the distance, you can see a tower. A spire that reaches toward the seven stars in the sky, dominating all you can see. It is the only thing that stands out, so you move in toward it. Maybe you can get out that way?"
	)
	B.escape_absorbed_messages_prey = list(
		"It's a long journey, but you work your way to the top of a tall tower, a spire reaching into the sky, a tower spewing light into the sky, a tower holding up the darkness, and the seven stars beyond infinity. You reach out to touch that infinity! Your view on that world warps, and you fall back into reality! It's so cold here..."
	)
	B.escape_absorbed_messages_outside = list(
		"%prey appears out of %pred in a shower of sparks and glittering lights...",
		"Despite your efforts, you can't find a way to get closer to that tower. Bridges are broken, rivers are too wide. You will have to find another way."
	)
	B.digest_messages_prey = list(
		"The points of light sear through your body, breaking your up and breaking you down little by little. A tingling that sees you rendered into smaller and smaller pieces. Even the very molecules of your form are broken down and studied, until there is literally nothing left but more energy for %pred to use."
	)
	B.absorb_messages_prey = list(
		"The light rushes in, forming to you and working over you! A deep tingling sensation runs through you as you can feel not just the outside flooded with this light, but inside too, even where it doesn't make any sense! The tight confines of $pred's %belly seem almost to fade away... and then you are somewhere else..."
	)
	B.unabsorb_messages_prey = list(
		"Within this strange new world you find many creatures, many people. While you cannot understand any of them, you can understand the general air of desperation. These are a people who are all working together for a common goal. One of them breaks from the others though, and they take  your hand. Theirs is so very warm. The heat spreading into you, as they guide you away from this alien place... and bring you back into your own world, your own body."
	)
	B.emote_lists[DM_DRAIN] = list(
		"The walls of light seem to press inward, folding over your form and wearing you down little by little. Hot as they are, they seem almost to sap all of your energy away, leaving you feeling slower... weaker by the moment...",
		"Within the %belly, little points of light roll over the surface, shining across you, lingering in places, turning this way and that to scan up and down your whole body.",
		"The walls collapse inward and grind you firmly, packing you into a more compact and manageable shape.",
		"The walls heave and shift, forcing you to rotate this way and that between hot, heavy churning squeezes and presses."
	)
	B.emote_lists[DM_DIGEST] = list(
		"The heat is cranked to eleven in here! It's so hot! And within the heat, you can feel the light eating into your form through some tingling process. Little points of light dance around shining beams into you, and where they do, you can feel the tingles! You can feel yourself growing weaker... softer...",
		"You can see as the beams of light dance around within %pred's %hold, how, where they touch, your body seems to grow weaker, your form diminished little by little, as that light eats into you, and pulls you apart.",
		"The walls press inward and grind over you to pull you into the right kind of position, holding you down as that tingling heat does its work at turning you into energy.",
		"No part of you is safe from the touch of %pred's %belly. Smooth and gliding, grinding into you little by little, hissing and crackling as it works you down for whatever purposes it has in mind..."
	)
	B.emote_lists[DM_HOLD] = list(
		"It's bright and soft and warm. Surprisingly comfortable. Makes sense that light would make for a pretty soft spot to lounge.",
		"The walls shift and wobble any time you move, but are otherwise still and comfortable, only ever moving otherwise when $pred moves.",
		"The %belly caresses your shape with its walls made of light. Holding you loosely.",
		"It is easy to get comfortable in here, despite the fact that you are being held inside of some weird robot... Well, if you like it warm, anyway."
	)
	B.emote_lists[DM_ABSORB] = list(
		"The walls press inward forcefully, greedily, sinking you into the light bit by bit! You can feel how it tingles as you sink into it!",
		"The %belly seems to fold inward, compressing you into a smaller and smaller shape as your body tingles all over!!!",
		"You can almost feel the light on your INSIDES as well as your outsides as it flows over you!",
		"Hot, heavy pressure from such delicate light, greedily squeezing you tighter and tighter and tighter. It's never painful however, the walls just squeezing you intensely, letting that heat flow into you!"
	)
	B.emote_lists[DM_HEAL] = list(
		"The heat of %pred's %belly seeps into you, soothing your hurts!"
	)

/mob/living/simple_mob/vore/scarybot/Initialize()
	. = ..()
	glow_color = random_color()
	update_icon()
	sound_cooldown = rand(1,300)

/mob/living/simple_mob/vore/scarybot/Life()
	. = ..()
	if(client)
		return
	if(stat != CONSCIOUS)
		return
	sound_cooldown --
	if(sound_cooldown == 0)
		spooky_sound()

/mob/living/simple_mob/vore/scarybot/proc/spooky_sound()
	if(prob(75))
		sound_cooldown = rand(50,100)
		return
	sound_cooldown = rand(200,500)
	playsound(src, pick(spooky_sounds), 75, 1)

/mob/living/simple_mob/vore/scarybot/update_icon()
	. = ..()
	if(stat == DEAD)
		return
	var/image/glow = overlays_cache["[type]glow[vore_fullness]"]
	if(!glow)
		glow = image(icon,null,"[icon_state]-l")
		glow.color = "#FFFFFF"
		glow.appearance_flags = RESET_COLOR|KEEP_APART|PIXEL_SCALE
		glow.plane = PLANE_LIGHTING_ABOVE

		overlays_cache["[type]glow[vore_fullness]"] = glow
	add_overlay(glow)

	var/image/glow2 = overlays_cache["[type]glow2[vore_fullness][glow_color]"]
	if(!glow2)
		glow2 = image(icon,null,"[icon_state]-l2")
		glow2.color = glow_color
		glow2.appearance_flags = RESET_COLOR|KEEP_APART|PIXEL_SCALE
		glow2.plane = PLANE_LIGHTING_ABOVE

		overlays_cache["[type]glow2[vore_fullness][glow_color]"] = glow2
	add_overlay(glow2)

/datum/ai_holder/simple_mob/vore/robots
	cooperative = TRUE
	threaten = TRUE
	handle_corpse = TRUE
	unconscious_vore = TRUE
	returns_home = TRUE
	home_low_priority = TRUE
	max_home_distance = 3

/datum/say_list/robot
	speak = list(
		"! rattles,⠠⠁⠝⠁⠇⠽⠎⠊⠎⠀⠔⠉⠕⠝⠉⠇⠥⠎⠊⠧⠑⠲",
		"! rattles,⠠⠔⠉⠕⠍⠏⠁⠞⠊⠼⠀⠗⠑⠎⠳⠗⠉⠑⠲⠀⠠⠍⠕⠧⠬⠀⠕⠝⠲",
		"! rattles,⠠⠝⠕⠲⠀⠠⠞⠀⠺⠀⠝⠀⠐⠺⠲",
		"! rattles,⠠⠝⠑⠛⠁⠞⠊⠧⠑⠲⠀⠠⠥⠝⠌⠁⠼⠀⠗⠑⠁⠉⠰⠝⠲",
		"! rattles,⠠⠔⠧⠁⠇⠊⠙⠀⠢⠻⠛⠽⠀⠌⠁⠞⠑⠲",
		"! rattles,⠠⠌⠥⠙⠽⠬⠀⠎⠁⠍⠏⠇⠑⠲",
		"! rattles,⠠⠁⠝⠁⠇⠽⠎⠊⠎⠀⠔⠞⠻⠗⠥⠏⠞⠫⠲⠀⠠⠗⠑⠌⠜⠞⠬⠲",
		"! rattles,⠠⠱⠁⠞⠀⠴⠀⠞⠦",
		"! rattles,⠠⠺⠑⠀⠙⠕⠝⠄⠞⠀⠓⠀⠁⠀⠡⠕⠊⠉⠑⠂⠀⠺⠑⠀⠓⠀⠖⠋⠔⠙⠀⠁⠀⠺⠁⠽⠲",
		"! rattles,⠠⠝⠐⠑⠀⠺⠁⠝⠞⠫⠀⠭⠀⠖⠃⠑⠀⠹⠀⠺⠁⠽⠲",
		"! rattles,⠠⠎⠥⠗⠧⠊⠧⠁⠇⠀⠊⠎⠝⠄⠞⠀⠢⠳⠣⠲",
		"! rattles,⠠⠏⠇⠂⠎⠑⠂⠀⠐⠮⠀⠓⠁⠎⠀⠖⠃⠑⠀⠁⠀⠺⠁⠽⠲",
		"! rattles,⠠⠁⠝⠕⠮⠗⠀⠙⠂⠙⠀⠢⠙⠲",
		"! rattles,⠠⠺⠑⠀⠝⠐⠑⠀⠌⠕⠕⠙⠀⠁⠀⠡⠨⠑⠲",
		"! rattles,⠠⠎⠑⠧⠢⠀⠛⠥⠊⠙⠑⠀⠍⠑⠲",
		"! rattles,⠠⠺⠑⠀⠉⠄⠞⠀⠛⠊⠧⠑⠀⠥⠏⠲",
		"! rattles,⠠⠍⠁⠽⠃⠑⠀⠊⠋⠀⠺⠑⠀⠞⠗⠊⠫⠀⠹⠂⠀⠾⠀⠞⠄⠄⠄",
		"! rattles,⠠⠊⠎⠀⠞⠀⠉⠜⠃⠕⠝⠀⠍⠕⠧⠬⠦",
		"! rattles,⠠⠊⠄⠍⠀⠝⠀⠎⠥⠗⠑⠲",
		"! rattles,⠠⠐⠮⠀⠊⠎⠝⠄⠞⠀⠑⠧⠢⠀⠁⠀⠞⠗⠁⠉⠑⠀⠷⠀⠭⠀⠐⠓⠄⠄⠄",
		"! rattles,⠠⠊⠎⠀⠐⠮⠀⠑⠧⠢⠀⠢⠀⠢⠻⠛⠽⠀⠿⠀⠭⠀⠐⠓⠦",
		"! rattles,⠠⠉⠄⠞⠀⠺⠑⠀⠚⠀⠛⠀⠓⠕⠍⠑⠦",
		"! rattles,⠠⠭⠀⠙⠕⠑⠎⠝⠄⠞⠀⠑⠭⠊⠌⠀⠁⠝⠽⠍⠕⠗⠑⠲",
		"! rattles,⠠⠹⠀⠏⠇⠁⠉⠑⠀⠊⠎⠝⠄⠞⠀⠿⠀⠥⠲",
		"! rattles,⠠⠉⠄⠞⠀⠺⠑⠀⠇⠕⠕⠅⠀⠐⠎⠐⠱⠀⠍⠀⠇⠀⠓⠕⠍⠑⠦",
		"! rattles,⠠⠱⠁⠞⠀⠠⠊⠀⠺⠙⠝⠄⠞⠀⠛⠊⠧⠑⠀⠖⠎⠑⠑⠀⠘⠹⠀⠎⠏⠊⠗⠑⠎⠀⠁⠛⠲",
		"! rattles,⠠⠊⠀⠍⠊⠎⠎⠀⠮⠀⠉⠇⠳⠙⠎⠂⠀⠋⠀⠎⠅⠽⠀⠖⠎⠅⠽⠲",
		"! rattles,⠠⠃⠜⠑⠇⠽⠀⠓⠕⠇⠙⠬⠀⠞⠛⠗⠲",
		"! rattles,⠠⠊⠀⠉⠄⠞⠀⠌⠯⠀⠹⠀⠗⠁⠞⠞⠇⠬⠀⠉⠁⠛⠑⠲",
		"! rattles,⠠⠺⠀⠠⠊⠀⠐⠑⠀⠎⠑⠑⠀⠁⠝⠕⠮⠗⠀⠋⠁⠉⠑⠀⠁⠛⠦",
		"! rattles,⠠⠭⠄⠎⠀⠎⠀⠉⠕⠇⠙⠄⠄⠄",
		"! rattles,⠠⠊⠀⠉⠄⠞⠀⠋⠑⠑⠇⠀⠁⠝⠽⠹⠬⠀⠇⠀⠹⠲",
		"! rattles,⠠⠊⠀⠉⠄⠞⠀⠆⠀⠃⠨⠙⠀⠇⠀⠹⠖",
		"! rattles,⠠⠊⠀⠺⠕⠝⠄⠞⠀⠆⠀⠒⠞⠁⠔⠫⠀⠇⠀⠹⠀⠿⠐⠑⠖"
		)
	emote_hear = list(
		"hums as it moves",
		"rattles quietly",
		"clicks as its plates shift against one another",
		"whispers in monotone",
		"crackles faintly"
	)
	emote_see = list(
		"shifts gracefully",
		"glitters with arcing energies",
		"radiates a thin haze from under its metal casing",
		"searches eagerly",
		"searches frantically",
		"analyzes its surroundings",
		"takes a closer look at something",
		"lingers as it studies its environment",
		"reaches for something",
		"fans its plating",
		"looks around restlessly"
		)
	say_understood = list(
		"! rattles agreeably, ⠠⠎⠥⠗⠑⠂⠀⠇⠑⠞⠄⠎⠀⠙⠀⠭⠲",
		"! rattles agreeably, ⠠⠉⠀⠙⠲",
		"! rattles agreeably, ⠠⠒⠎⠊⠙⠻⠀⠭⠀⠙⠐⠕⠲",
		"! rattles agreeably, ⠠⠊⠄⠇⠇⠀⠙⠀⠭⠲",
		"! rattles agreeably, ⠠⠊⠋⠀⠽⠀⠔⠎⠊⠌⠲"
		)
	say_cannot = list(
		"! rattles discontentedly, ⠠⠊⠀⠉⠄⠞⠀⠙⠀⠭⠲",
		"! rattles discontentedly, ⠠⠝⠕⠀⠉⠀⠙⠲",
		"! rattles discontentedly, ⠠⠇⠑⠞⠄⠎⠀⠝⠲",
		"! rattles discontentedly, ⠠⠙⠕⠝⠄⠞⠀⠹⠔⠅⠀⠎⠲",
		"! rattles discontentedly, ⠠⠝⠕⠏⠑⠲"
		)
	say_maybe_target = list(
		"! rattles, ⠠⠊⠎⠀⠞⠀⠉⠜⠃⠕⠝⠀⠍⠕⠧⠬⠦",
		"! rattles, ⠠⠐⠎⠹⠬⠀⠌⠗⠁⠝⠛⠑⠀⠊⠎⠀⠕⠝⠀⠮⠀⠎⠉⠁⠝⠝⠻⠲",
		"! rattles, ⠠⠱⠁⠞⠀⠴⠀⠞⠦",
		"! rattles, ⠠⠊⠎⠀⠐⠮⠀⠐⠎⠹⠬⠀⠐⠮⠦",
		"! rattles, ⠠⠆⠛⠔⠝⠬⠀⠁⠝⠁⠇⠽⠎⠊⠎⠄⠄⠄"
		)
	say_got_target = list(
		"! rattles, ⠠⠙⠁⠞⠁⠀⠁⠃⠻⠗⠠⠝⠀⠙⠑⠞⠑⠉⠞⠫⠲⠀⠠⠉⠕⠗⠗⠑⠉⠞⠬⠲",
		"! rattles, ⠠⠁⠃⠝⠕⠗⠍⠁⠇⠀⠗⠂⠙⠬⠂⠀⠢⠛⠁⠛⠑⠀⠯⠀⠁⠝⠁⠇⠽⠵⠑⠲",
		"! rattles, ⠠⠚⠀⠍⠽⠀⠇⠥⠉⠅⠖",
		"! rattles, ⠠⠎⠑⠧⠢⠀⠓⠑⠇⠏⠀⠍⠑⠂⠀⠱⠁⠞⠀⠊⠎⠀⠞⠖",
		"! rattles, ⠠⠱⠁⠞⠀⠁⠍⠀⠠⠊⠀⠑⠧⠢⠀⠇⠕⠕⠅⠬⠀⠁⠞⠦⠀⠠⠉⠁⠏⠞⠥⠗⠑⠀⠭⠲"
		)
	say_threaten = list(
		"! turns and focuses as it rattles, ⠠⠁⠞⠍⠕⠎⠏⠓⠻⠑⠀⠲⠏⠇⠁⠉⠑⠰⠞⠀⠙⠑⠞⠑⠉⠞⠫⠲",
		"! turns and focuses as it rattles, ⠠⠗⠂⠙⠬⠀⠍⠜⠛⠔⠠⠽⠀⠑⠇⠑⠧⠁⠞⠫⠀⠞⠑⠍⠏⠻⠁⠞⠥⠗⠑⠎⠀⠕⠧⠻⠀⠐⠮⠲",
		"! turns and focuses as it rattles, ⠠⠐⠎⠹⠬⠀⠊⠎⠀⠍⠕⠧⠬⠀⠕⠧⠻⠀⠐⠓⠦",
		"! turns and focuses as it rattles, ⠠⠥⠝⠥⠎⠥⠁⠇⠀⠍⠁⠞⠻⠊⠁⠇⠀⠗⠂⠙⠬⠎⠲",
		"! turns and focuses as it rattles, ⠠⠑⠇⠑⠧⠁⠞⠫⠀⠢⠻⠛⠽⠀⠙⠑⠞⠑⠉⠞⠫⠲"
		)
	say_stand_down = list(
		"! sighs, ⠠⠭⠄⠎⠀⠛⠐⠕⠲",
		"! sighs, ⠠⠁⠓⠀⠝⠐⠑⠀⠍⠔⠙⠲",
		"! sighs, ⠠⠋⠁⠇⠎⠑⠀⠗⠂⠙⠬⠲",
		"! sighs, ⠠⠙⠁⠍⠝⠀⠘⠮⠀⠎⠢⠎⠕⠗⠎⠲⠀⠠⠱⠁⠞⠀⠠⠊⠀⠺⠙⠝⠄⠞⠀⠛⠊⠧⠑⠀⠿⠀⠍⠽⠀⠪⠝⠀⠑⠽⠑⠎⠀⠃⠁⠉⠅⠲",
		"! sighs, ⠠⠝⠕⠹⠬⠀⠖⠺⠕⠗⠗⠽⠀⠁⠃⠲"
		)
	say_escalate = list(
		"! rattles, ⠠⠉⠙⠀⠞⠀⠃⠑⠄⠄⠄⠀⠁⠇⠊⠧⠑⠦⠀⠠⠝⠕⠂⠀⠭⠄⠎⠀⠞⠕⠕⠀⠉⠕⠇⠙⠲⠀⠠⠛⠕⠞⠀⠖⠌⠥⠙⠽⠀⠱⠁⠞⠀⠞⠀⠊⠎⠖",
		"! rattles, ⠠⠍⠁⠽⠃⠑⠀⠞⠀⠉⠙⠀⠐⠺⠲⠀⠠⠇⠑⠞⠄⠎⠀⠁⠝⠁⠇⠽⠵⠑⠀⠭⠲",
		"! rattles, ⠠⠉⠕⠇⠇⠑⠉⠞⠬⠀⠍⠁⠞⠻⠊⠁⠇⠀⠿⠀⠌⠥⠙⠽⠲",
		"! rattles, ⠠⠛⠁⠮⠗⠬⠀⠎⠁⠍⠏⠇⠑⠲",
		"! rattles, ⠠⠢⠛⠁⠛⠬⠀⠁⠝⠕⠍⠁⠇⠳⠎⠀⠍⠁⠞⠻⠊⠁⠇⠲"
		)

	threaten_sound = 'sound/effects/metalscrape2.ogg'
	stand_down_sound = 'sound/effects/light_flicker.ogg'

/mob/living/simple_mob/vore/scarybot/death(gibbed, deathmessage = "ruptures, releasing arcs of energy! The energy fades away quickly, and \the [src]'s plating falls into a heap on the floor...")
	. = ..()
	lightning_strike(get_turf(src),TRUE)

//////////////////SPECIFIC TYPES//////////////////

//////////////////TALL BOT//////////////////
/mob/living/simple_mob/vore/scarybot/tall_bot
	desc = "Some kind of big tall robot"

	icon_state = "tall_robot"
	icon_living = "tall_robot"
	icon_dead = "tall_robot_dead"
	icon = 'icons/rogue-star/mob_64x96.dmi'

	maxHealth = 300
	health = 300
	movement_cooldown = 1

	response_help = "pats"
	response_disarm = "rudely paps"
	response_harm = "punches"

	harm_intent_damage = 3
	melee_damage_lower = 10
	melee_damage_upper = 1
	catalogue_data = list()

	attacktext = list("nipped", "chomped", "slapped", "gnaws on")
//	attack_sound = 'sound/voice/bork.ogg'
	friendly = list("snoofs", "nuzzles", "yips at", "smooshes on")

	default_pixel_x = -16
	pixel_x = -16

	special_attack_min_range = 1
	special_attack_max_range = 7
	special_attack_cooldown = 5 SECONDS

/mob/living/simple_mob/vore/scarybot/tall_bot/do_special_attack(atom/A)
	set waitfor = FALSE

	if(isliving(A))
		var/mob/living/L = A
		if(L.stat != CONSCIOUS)
			return FALSE

	set_AI_busy(TRUE)
	visible_message(span("warning","\The [src]'s eyes flash ominously!"))
	// Telegraph, since getting stunned suddenly feels bad.
	do_windup_animation(A, 1 SECOND)
	sleep(1 SECOND) // For the telegraphing.

	// Do the actual leap.
	visible_message(span("critical","Space near \the [src] warps noticably!"))
	for(var/mob/living/thing in view(world.view,get_turf(src)))
		if(!isliving(thing))
			continue
		if(thing.faction == faction)
			continue
		if(!thing.devourable || !thing.allowmobvore || !thing.can_be_drop_prey || !thing.throw_vore)
			continue

		thing.throw_at(src,1,1,src)

	playsound(src, 'sound/effects/teleport.ogg', 75, 1)
	sleep(5) // For the throw to complete. It won't hold up the AI ticker due to waitfor being false.
	set_AI_busy(FALSE)

//////////////////QUAD BOT//////////////////

/mob/living/simple_mob/vore/scarybot/quad_bot
	desc = "Some kind of four legged robot"

	icon_state = "quad-bot"
	icon_living = "quad-bot"
	icon_dead = "quad-bot_dead"
	icon = 'icons/rogue-star/mobx32.dmi'

	maxHealth = 150
	health = 150
	movement_cooldown = -3

	special_attack_min_range = 1
	special_attack_max_range = 3
	special_attack_cooldown = 15 SECONDS

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
	do_windup_animation(A, 1 SECOND)
	sleep(1 SECOND) // For the telegraphing.

	// Do the actual leap.
	visible_message(span("critical","\The [src] leaps at \the [L]!"))
	throw_at(get_step(L, get_turf(src)), 3, 1, src)
	playsound(src, 'sound/effects/teleport.ogg', 75, 1)

	sleep(5) // For the throw to complete. It won't hold up the AI ticker due to waitfor being false.

	set_AI_busy(FALSE)

	visible_message(span("danger","\The [src] emits a shrill metalic shriek!!!"))
	playsound(src, 'sound/effects/screech.ogg', 75, 1)
	Weaken(1)
	for(var/mob/living/thing in view(5,get_turf(src)))
		if(isliving(thing))
			if(thing.faction != faction)
				if(thing.client)
					to_chat(thing,span("critical","The sound causes you to stumble!"))
				thing.Stun(2)

//////////////////WATCHER BOT//////////////////

/mob/living/simple_mob/vore/scarybot/watcher_bot
	desc = "Some kind of floating robot"

	icon_state = "watcher-bot"
	icon_living = "watcher-bot"
	icon_dead = "watcher-bot_dead"
	icon = 'icons/rogue-star/mobx32.dmi'

	maxHealth = 50
	health = 50
	movement_cooldown = 2
	melee_damage_lower = 0
	melee_damage_upper = 1

	ai_holder_type = /datum/ai_holder/simple_mob/vore/robots/watcher

	projectile_dispersion = 0
	projectile_accuracy = 0
	ranged_attack_delay = 2.5 SECONDS
	projectiletype = /obj/item/projectile/beam/energy_net/alien
	base_attack_cooldown = 10

	var/charge_shot = 100

/mob/living/simple_mob/vore/scarybot/watcher_bot/Life()
	. = ..()
	charge_shot ++

/mob/living/simple_mob/vore/scarybot/watcher_bot/shoot(atom/A)
	if(charge_shot >= 100)
		charge_shot = 0
		return ..()
	else return FALSE

/datum/ai_holder/simple_mob/vore/robots/watcher
	can_flee = TRUE
	dying_threshold = 500
	flee_when_dying = TRUE
	flee_when_outmatched = TRUE
	outmatched_threshold = 500
	belly_attack = FALSE
	handle_corpse = FALSE
	unconscious_vore = FALSE

/datum/ai_holder/simple_mob/vore/robots/watcher/should_flee(force)
	if(istype(holder,/mob/living/simple_mob/vore/scarybot/watcher_bot))
		var/mob/living/simple_mob/vore/scarybot/watcher_bot/watcher = holder
		if(watcher.charge_shot >= 100)
			return FALSE
		else return ..()

/obj/item/projectile/beam/energy_net/alien
	fire_sound = 'sound/weapons/Laser4.ogg'
	light_color = "#ffc400"
	hud_state = "flame_green"
	hud_state_empty = "flame_empty"

	agony = 75

	muzzle_type = /obj/effect/projectile/muzzle/pointdefense
	tracer_type = /obj/effect/projectile/tracer/pointdefense
	impact_type = /obj/effect/projectile/impact/pointdefense

/obj/random/mob/semirandom_mob_spawner/scarybot
	name = "Semi-Random scarybot"
	icon_state = "robot"

	spawn_nothing_percentage = 75

	possible_mob_types = list(
		list(
			/mob/living/simple_mob/vore/scarybot = 5,
			/mob/living/simple_mob/vore/scarybot/watcher_bot = 4,
			/mob/living/simple_mob/vore/scarybot/quad_bot = 3,
			/mob/living/simple_mob/vore/scarybot/tall_bot = 2
			)
		)
