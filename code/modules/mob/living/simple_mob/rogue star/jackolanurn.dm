/mob/living/simple_mob/vore/jackolanturn
	name = "pumpkin"
	desc = "is some kinna pumkin woah"
	icon = 'icons/mob/vore32x64.dmi'
	icon_state = "vines"
	icon_living = "vines"
	icon_dead = "vines_dead"
	maxHealth = 10
	health = 10
	movement_cooldown = -1
	resting = TRUE

	vore_active = TRUE
	vore_capacity = 1

	glow_toggle = TRUE
	glow_range = 1.5
	glow_color = "#E09D37"

	ai_holder_type = /datum/ai_holder/simple_mob/vore

	faction = "shitty pumpkin asshole"

	var/static/list/overlays_cache = list()
	var/carve_state

	swallowTime = 1 SECONDS
	vore_active = 1
	vore_capacity = 1
	vore_bump_chance = 75
	vore_bump_emote	= "wraps up"
	vore_ignores_undigestable = 0
	vore_default_mode = DM_SELECT
	vore_icons = SA_ICON_LIVING
	vore_stomach_name = "gastric chamber"
	vore_default_item_mode = IM_DIGEST
	vore_pounce_chance = 75
	vore_pounce_cooldown = 10
	vore_pounce_successrate	= 75
	vore_pounce_falloff = 0
	vore_pounce_maxhealth = 100
	vore_standing_too = TRUE
	can_be_drop_prey = FALSE
	can_be_drop_pred = TRUE
	throw_vore = TRUE
	unacidable = TRUE

/mob/living/simple_mob/vore/jackolanturn/init_vore()
	..()
	var/obj/belly/B = vore_selected
	B.name = "gastric chamber"
	B.desc = "Immensely tight and slimy, the SPOOKY interior of the jackolanturn's stalk caresses you with heavy churns, squeezing you into a tight orb amid the writhing green tendrils. You can feel how it all throbs around you as you are soaked in tingling slimes."
	B.mode_flags = DM_FLAG_THICKBELLY | DM_FLAG_NUMBING
	B.belly_fullscreen = "yet_another_tumby"
	B.digest_brute = 2
	B.digest_burn = 2
	B.digestchance = 0
	B.absorbchance = 0
	B.escapechance = 25
	B.colorization_enabled = TRUE
	B.belly_fullscreen_color = "#ff8800"
	B.escape_stun = 3

/mob/living/simple_mob/vore/jackolanturn/Initialize()
	. = ..()
	update_icon()

/mob/living/simple_mob/vore/jackolanturn/update_icon()
	. = ..()
	if(stat == DEAD)
		glow_toggle = FALSE
		icon_state = icon_dead
		return
	var/offset = 0
	if(resting)
		icon_state = null
	else
		offset = 32
		update_fullness()
		if(vore_fullness)
			icon_state = "[icon_living]-[vore_fullness]"
		else
			icon_state = icon_living
	var/image/head = overlays_cache["head[resting]"]
	if(!head)
		head = image('icons/obj/flora/pumpkins.dmi',null,"decor-pumpkin",pixel_y = offset)
		head.color = "#FFFFFF"
		head.appearance_flags = RESET_COLOR|KEEP_APART|PIXEL_SCALE
		overlays_cache["head[resting]"] = head
	add_overlay(head)

	if(!carve_state)
		var/list/carvings = list(
		"agony",
		"bat",
		"bird",
		"bug",
		"candle-face",
		"cat-face",
		"deadface",
		"despair",
		"duality",
		"evil",
		"g",
		"girly",
		"he",
		"house",
		"kevin",
		"kinface",
		"kissy",
		"krimgulus",
		"lost",
		"midnight-lampoon",
		"monster",
		"ness",
		"old",
		"ominous",
		"owo-a",
		"owo-b",
		"pawb",
		"peek",
		"rodent",
		"scary",
		"scream",
		"screm",
		"smile",
		"smooch",
		"spider-owo",
		"tiers",
		"teeth"
		)
		carve_state = pick(carvings)

	var/image/carving_light = overlays_cache["[carve_state]-l[resting]"]
	if(!carving_light)
		carving_light = image('icons/obj/flora/pumpkins.dmi',null,"[carve_state]-l",pixel_y = offset)
		carving_light.appearance_flags = KEEP_APART|PIXEL_SCALE
		carving_light.plane = PLANE_LIGHTING_ABOVE
		overlays_cache["[carve_state]-l[resting]"] = carving_light
	add_overlay(carving_light)

	lets_desc()

/mob/living/simple_mob/vore/jackolanturn/Life()
	. = ..()

	if(client)
		return
	if(resting)
		for(var/mob/living/L in range(3,get_turf(src)))
			if(!isliving(L))
				continue
			if(!will_eat(L))
				continue
			if(L.faction == faction)
				continue
			lay_down()
			ai_holder.give_target(L)
	else if(ai_holder.stance == STANCE_IDLE)
		lay_down()
		ai_holder.wander = FALSE

/mob/living/simple_mob/vore/jackolanturn/proc/lets_desc()
	var/ourdesc = "A fat, freshly picked pumpkin. This one has a "
	switch(carve_state)
		if(null , "")
			return
		if("agony")
			ourdesc = ourdesc + "face carved into it! It appears to be in horrible agony!"
		if("bat")
			ourdesc = ourdesc + "what might be a face carved into it. Or maybe it is a bat? You aren't sure. But you ARE SPOOKED!!!"
		if("bird")
			ourdesc = ourdesc + "spooky looking bird carved into it!"
		if("bug")
			ourdesc = ourdesc + "face carved into it. It appears to be a cute bug!"
		if("candle-face")
			ourdesc = ourdesc + "an ominous visage carved into it! SPOOKY!!!"
		if("cat-face")
			ourdesc = ourdesc + "face carved into it. It's a cute cat face!"
		if("deadface")
			ourdesc = ourdesc + "face carved into it. This pumpkin looks to have passed away..."
		if("despair")
			ourdesc = ourdesc + "face carved into it. It it is the look of absolute despair! Oh no..."
		if("duality")
			ourdesc = ourdesc + "face carved into it. It looks quite uncertain. Don't worry little guy, you'll figure it out."
		if("evil")
			ourdesc = ourdesc + "face carved into it. It has develishly evil-looking eyes and a grinning mouth more than big enough for a very small person to hide in."
		if("g")
			ourdesc = ourdesc + "large stylized G carved into it. It looks almost like the logo of an evil organization! SPOOKY!!!"
		if("girly")
			ourdesc = ourdesc + "face carved into it. It has neatly rounded eyes topped with what appear to be cartoony eyelashes, completed with what seems to have been the carver's attempt at friendly, toothy smile. The mouth is easily the scariest part of its face."
		if("he")
			ourdesc = ourdesc + "figure carved into it. You aren't quite sure what it is, but one fact is absolute: He's him. This shit ain't nothin' to him man."
		if("house")
			ourdesc = ourdesc + "lone house carved into it. Isolated, on its own in a void... this is one spooky house!!"
		if("kevin")
			ourdesc = ourdesc + "face carved into it. A single eye adorns their pill shaped head. You aren't sure what this is, but it awakens an ancient fear within your heart to behold."
		if("kinface")
			ourdesc = ourdesc + "face carved into it. A pair of large eyes gaze into you with untold knowings..."
		if("kissy")
			ourdesc = ourdesc + "face carved into it. It has a pair of kissy lips and blush lines carved into it. This pumpkin looks highly smoochable. But maybe that's what it wants you to think..."
		if("krimgulus")
			ourdesc = ourdesc + "figure carved into it. A jagged void looms imposingly across its surface... you aren't quite sure if maybe someone tried to cover up a mistake by carving more away... or if someone came along and kicked a hole in it... or if indeed there is a figure so spooky to behold out there somewhere. Whatever the case, it is an ominous sight to behold..."
		if("lost")
			ourdesc = ourdesc + "face carved into it. It looks somewhat distraught, lost in the world without anyone to guide it. Someone should help it out!"
		if("midnight-lampoon")
			ourdesc = ourdesc + "bench and a lamp carved into it. A lone bench beneath a street lamp, a lonely and ominous scene. It brings feelings of isolation."
		if("monster")
			ourdesc = ourdesc + "figure carved into it. It is an ominous squiggly shape that brings deep alarm to you. It appears to be some kind of unknowable entity beyond all comprehension! It's hard to look at it without the whispers nibbling at your ears!!! Or maybe you're just being dramatic..."
		if("ness")
			ourdesc = ourdesc + "face carved into it. It looks like a friendly synthetic person's face! Comforting, despite the number of eyes."
		if("old")
			ourdesc = ourdesc + "face carved into it. It looks a little long in the tooth."
		if("ominous")
			ourdesc = ourdesc + "figure carved into it. A shape of unknown origin. It gives off an ominous vibe!!!"
		if("owo-a")
			ourdesc = ourdesc + "face carved into it. It has large, round eyes and a squiggly, cat-like smiling mouth. Its pleasantly surprised expression seems to suggest that the pumpkin has noticed something about you."
		if("owo-b")
			ourdesc = ourdesc + "face carved into it. It has large, round eyes and a squiggly, cat-like smiling mouth. Its pleasantly surprised expression seems to suggest that the pumpkin has noticed something about you... is there something stuck on your face??"
		if("pawb")
			ourdesc = ourdesc + "paw carved into it. A broad circle of pumpkin flesh has been stripped away around it, suggesting that whatever stepped here has a larger print than the cute paw pads imply..."
		if("peek")
			ourdesc = ourdesc + "face carved into it. It has large inquisitive eyes and a cute snoot. It is looking at you with interest, as if it might gallop over at any moment."
		if("rodent")
			ourdesc = ourdesc + "face carved into it. It has a cute snoot and whiskers, and beady little peepers. It looks like it is scheming."
		if("scary")
			ourdesc = ourdesc + "figure carved into it. A sharp angular shape reminds you of something fast and agressive! It brings a feeling of dread to you!"
		if("scream")
			ourdesc = ourdesc + "face carved into it. It has rounded eyes looking in completely opposite directions and a wide mouth, forever frozen in a silent scream. It looks ridiculous, actually."
		if("screm")
			ourdesc = ourdesc + "face carved into it. It has a wide open mouth as though wailing in fear! So spooky!!!"
		if("smile")
			ourdesc = ourdesc + "face carved into it. Just a simple, if somewhat menacing smile!"
		if("smooch")
			ourdesc = ourdesc + "face carved into it. It appears to be caught in an eternal smooch! Don't look a gift smooch in the mouth!"
		if("spider-owo")
			ourdesc = ourdesc + "face carved into it. It has many large eyes gazing at you and a squiggly smiling mouth. Its pleasantly surprised expression seems to suggest that the pumpkin has noticed something about you. Perhaps you have flies near you?"
		if("tiers")
			ourdesc = ourdesc + "figure carved into it. An imposing triangular shape containing more triangular shapes. It seems to imply layers, or deeper meanings. A smaller figure hovers nearby, which might contain even more secrets... an ominous prospect. You wonder how deep the rabbit hole goes..."
		if("teeth")
			ourdesc = ourdesc + "face carved into it. A sneering visage with far too many teeth!!! This pumpkin looks like it could hop up and bote you at any moment!!! RUN!!!"
		else
			ourdesc = ourdesc + "figure carved into it."
	desc = ourdesc
