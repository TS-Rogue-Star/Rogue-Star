//Pumpkins
/obj/structure/flora/pumpkin
	name = "pumpkin"
	icon = 'icons/obj/flora/pumpkins.dmi'
	desc = "A healthy, fat pumpkin. It looks as if it was freshly plucked from its vines and shows no signs of decay."
	icon_state = "decor-pumpkin"
	anchored = FALSE		//RS EDIT

/obj/structure/flora/pumpkin/attackby(obj/item/weapon/W, mob/living/user)	//RS ADD START
	. = ..()
	if(W.sharp)
		carve(user)		//RS ADD END

/obj/effect/landmark/carved_pumpkin_spawn
	name = "jack o'lantern spawn"
	icon = 'icons/obj/flora/pumpkins.dmi'
	icon_state = "spawner-jackolantern"

/obj/effect/landmark/carved_pumpkin_spawn/New()
	. = ..()

	new /obj/structure/flora/pumpkin/carved(src.loc)	//RS EDIT

/obj/effect/landmark/lit_carved_pumpkin_spawn	//RS ADD START
	name = "lit jack o'lantern spawn"
	icon = 'icons/obj/flora/pumpkins.dmi'
	icon_state = "spawner-jackolantern"

/obj/effect/landmark/lit_carved_pumpkin_spawn/New()
	. = ..()

	new /obj/structure/flora/pumpkin/carved(src.loc,null,TRUE)//RS ADD END

/obj/structure/flora/pumpkin/carved
	name = "jack o'lantern"
	desc = null		//RS EDIT
	icon_state = "decor-jackolantern"		//RS EDIT
	light_color = "#E09D37"	//RS ADD
	var/candle_lit = FALSE	//RS ADD
	var/carve_state = null	//RS ADD
	var/static/list/carving_cache = list()	//RS ADD

/obj/structure/flora/pumpkin/carved/evil	//RS EDIT
	desc = "A fat, freshly picked pumpkin. This one has a face carved into it! This one has develishly evil-looking eyes and a grinning mouth more than big enough for a very small person to hide in."
	carve_state = "evil"	//RS EDIT

/obj/structure/flora/pumpkin/carved/scream
	desc = "A fat, freshly picked pumpkin. This one has a face carved into it! This one has rounded eyes looking in completely opposite directions and a wide mouth, forever frozen in a silent scream. It looks ridiculous, actually."
	carve_state = "scream"	//RS EDIT

/obj/structure/flora/pumpkin/carved/girly
	desc = "A fat, freshly picked pumpkin. This one has a face carved into it! This one has neatly rounded eyes topped with what appear to be cartoony eyelashes, completed with what seems to have been the carver's attempt at friendly, toothy smile. The mouth is easily the scariest part of its face."
	carve_state = "girly"	//RS EDIT

/obj/structure/flora/pumpkin/carved/owo
	desc = "A fat, freshly picked pumpkin. This one has a face carved into it! This one has large, round eyes and a squiggly, cat-like smiling mouth. Its pleasantly surprised expression seems to suggest that the pumpkin has noticed something about you."
	carve_state = "owo-a"	//RS EDIT

// Various decorá
/obj/structure/flora/log1
	name = "waterlogged trunk"
	icon = 'icons/obj/flora/amayastuff.dmi'
	desc = "A part of a felled tree. Moss is growing across it."
	icon_state = "log1"

/obj/structure/flora/log2
	name = "driftwood"
	icon = 'icons/obj/flora/amayastuff.dmi'
	desc = "Driftwood carelessly lost in the water."
	icon_state = "log2"

/obj/structure/flora/lily1
	name = "red flowered lilypads"
	icon = 'icons/obj/flora/amayastuff.dmi'
	desc = "A bunch of lilypads. A beautiful red flower grows in the middle of them."
	icon_state = "lilypad1"

/obj/structure/flora/lily2
	name = "yellow flowered lilypads"
	icon = 'icons/obj/flora/amayastuff.dmi'
	desc = "A few lilypads. A sunny yellow flower stems from the water and from between the lilypads."
	icon_state = "lilypad2"

/obj/structure/flora/lily3
	name = "lilypads"
	icon = 'icons/obj/flora/amayastuff.dmi'
	desc = "A group of flowerless lilypads."
	icon_state = "lilypad3"

/obj/structure/flora/smallbould
	name = "small boulder"
	icon = 'icons/obj/flora/amayastuff.dmi'
	desc = "A small boulder, with its top smothered with moss."
	icon_state = "smallerboulder"

/obj/structure/flora/bboulder1
	name = "large boulder"
	icon = 'icons/obj/flora/amayastuff.dmi'
	desc = "Small stones sit beside this large boulder. Moss grows on the top of each of them."
	icon_state = "bigboulder1"
	density = TRUE

/obj/structure/flora/bboulder2
	name = "jagged large boulder"
	icon = 'icons/obj/flora/amayastuff.dmi'
	desc = "This boulder has had plates broken off it. Moss grows in the cracks and across the top."
	icon_state = "bigboulder2"
	density = TRUE

/obj/structure/flora/rocks1
	name = "rocks"
	icon = 'icons/obj/flora/amayastuff.dmi'
	desc = "A bunch of mossy rocks."
	icon_state = "rocks1"

/obj/structure/flora/rocks2
	name = "rocks"
	icon = 'icons/obj/flora/amayastuff.dmi'
	desc = "A bunch of mossy rocks."
	icon_state = "rocks2"

//RS ADD START - Punkins

/obj/structure/flora/pumpkin/proc/carve(var/mob/living/user)
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
	var/ourchoice
	var/light_it = FALSE
	if(!user)
		ourchoice = pick(carvings)
		if(istype(src,/obj/structure/flora/pumpkin/carved))
			var/obj/structure/flora/pumpkin/carved/pump = src
			light_it = pump.candle_lit
	else
		if(istype(src,/obj/structure/flora/pumpkin/carved))
			var/obj/structure/flora/pumpkin/carved/pump = src
			if(pump.carve_state)
				to_chat(user,"<span class = 'warning'>\The [src] is already carved.</span>")
				return
			light_it = pump.candle_lit
		ourchoice = tgui_input_list(user,"What will you carve?","Carve",carvings)

	if(!ourchoice || QDELETED(src))
		return
	new /obj/structure/flora/pumpkin/carved(src.loc,ourchoice,light_it)
	if(user)
		user.visible_message("<span class = 'notice'>\The [user] carves \the [src]!</span>")
	qdel(src)

/obj/structure/flora/pumpkin/carved/New(newloc,new_carv,light_it)
	if(newloc)
		loc = newloc
	if(new_carv)
		carve_state = new_carv
	if(light_it)
		candle_lit = TRUE
	..()

/obj/structure/flora/pumpkin/carved/Initialize()
	. = ..()
	icon_state = "decor-pumpkin"
	if(!carve_state)
		carve()
	else
		update_icon()
	if(!desc)
		lets_desc()

/obj/structure/flora/pumpkin/carved/update_icon()
	. = ..()
	cut_overlays()
	set_light(0)
	var/image/carving = carving_cache[carve_state]
	if(!carving)
		carving = image(icon,null,carve_state)
		carving.appearance_flags = KEEP_APART|PIXEL_SCALE
		carving_cache[carve_state] = carving
	add_overlay(carving)

	if(candle_lit)
		var/image/carving_light = carving_cache["[carve_state]-l"]
		if(!carving_light)
			carving_light = image(icon,null,"[carve_state]-l")
			carving_light.appearance_flags = KEEP_APART|PIXEL_SCALE
			carving_light.plane = PLANE_LIGHTING_ABOVE
			carving_cache["[carve_state]-l"] = carving_light
		add_overlay(carving_light)
		set_light(CANDLE_LUM/2)

/obj/structure/flora/pumpkin/carved/attackby(obj/item/weapon/W, mob/living/user)
	. = ..()
	if(carve_state && !candle_lit && istype(W,/obj/item/weapon/flame/candle))
		var/obj/item/weapon/flame/candle/C = W
		if(!C.lit)
			return
		candle_lit = TRUE
		update_icon()
		qdel(W)
		user.visible_message("<span class = 'notice'>\The [user] places the candle into \the [src], causing it to glow from within!</span>")

/obj/structure/flora/pumpkin/carved/proc/lets_desc()
	var/ourdesc = "A fat, freshly picked pumpkin. This one has a "
	switch(carve_state)
		if(null , "")	//RS EDIT
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

/obj/structure/flora/pumpkin/carved/agony
	carve_state = "agony"

/obj/structure/flora/pumpkin/carved/bat
	carve_state = "bat"

/obj/structure/flora/pumpkin/carved/bird
	carve_state = "bird"

/obj/structure/flora/pumpkin/carved/bug
	carve_state = "bug"

/obj/structure/flora/pumpkin/carved/candleface
	carve_state = "candle-face"

/obj/structure/flora/pumpkin/carved/catface
	carve_state = "cat-face"

/obj/structure/flora/pumpkin/carved/deadface
	carve_state = "deadface"

/obj/structure/flora/pumpkin/carved/despair
	carve_state = "despair"

/obj/structure/flora/pumpkin/carved/duality
	carve_state = "duality"

/obj/structure/flora/pumpkin/carved/g
	carve_state = "g"

/obj/structure/flora/pumpkin/carved/girly
	carve_state = "girly"

/obj/structure/flora/pumpkin/carved/he
	carve_state = "he"

/obj/structure/flora/pumpkin/carved/house
	carve_state = "house"

/obj/structure/flora/pumpkin/carved/kevin
	carve_state = "kevin"

/obj/structure/flora/pumpkin/carved/kinface
	carve_state = "kinface"

/obj/structure/flora/pumpkin/carved/kissy
	carve_state = "kissy"

/obj/structure/flora/pumpkin/carved/krimgulus
	carve_state = "krimgulus"

/obj/structure/flora/pumpkin/carved/lost
	carve_state = "lost"

/obj/structure/flora/pumpkin/carved/midnightlampoon
	carve_state = "midnight-lampoon"

/obj/structure/flora/pumpkin/carved/monster
	carve_state = "monster"

/obj/structure/flora/pumpkin/carved/ness
	carve_state = "ness"

/obj/structure/flora/pumpkin/carved/old
	carve_state = "old"

/obj/structure/flora/pumpkin/carved/ominous
	carve_state = "ominous"

/obj/structure/flora/pumpkin/carved/owo_b
	carve_state = "owo-b"

/obj/structure/flora/pumpkin/carved/pawb
	carve_state = "pawb"

/obj/structure/flora/pumpkin/carved/peek
	carve_state = "peek"

/obj/structure/flora/pumpkin/carved/rodent
	carve_state = "rodent"

/obj/structure/flora/pumpkin/carved/scary
	carve_state = "scary"

/obj/structure/flora/pumpkin/carved/screm
	carve_state = "screm"

/obj/structure/flora/pumpkin/carved/smile
	carve_state = "smile"

/obj/structure/flora/pumpkin/carved/smooch
	carve_state = "smooch"

/obj/structure/flora/pumpkin/carved/spiderowo
	carve_state = "spider-owo"

/obj/structure/flora/pumpkin/carved/tiers
	carve_state = "tiers"

/obj/structure/flora/pumpkin/carved/teeth
	carve_state = "teeth"
//RS ADD END
