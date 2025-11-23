//RS FILE
//Elfs done got off of the shelf

/datum/category_item/catalogue/fauna/elf
	name = "Anomalous Entity - Holiday Elf"
	desc = "Thought to be short creatures with smooth skin, long noses, and pointy ears, Holiday Elfs are a jolly accompaniment to the yearly holiday season! \
	Thought to contain small amounts of magic that is able to be concentrated and enhanced in the presence of more elves, allowing many elves to collaboratively \
	achieve incredible magical feats. Thought to originate from the extreme north of Sol 3 these creatures have been reported all across known space, \
	with many cultures having myths relating to them before contact with residents of Sol 3. While Holiday Elves are an interesting thing to study within myths and \
	legends, sightings have always shown to be hoaxes or misidentifications, and as such they are classified as a purely fictional species. \
	Anyone claiming otherwise should be examined by Central Command Emercency Medical immediately."
	value = CATALOGUER_REWARD_HARD

/mob/living/simple_mob/elf
	name = "holiday elf"
	desc = "A short little fellow with a pointy hat topped with a fluffy ball and beady little eyes!"
	icon_state = "elf-base"
	icon_living = "elf"
	icon_dead = "elf"
	icon = 'icons/rogue-star/mobx32.dmi'

	faction = "holiday"
	maxHealth = 35
	health = 35
	movement_cooldown = -1
	meat_amount = 0
	meat_type = null

	response_help = "hugs"
	response_disarm = "pushes"
	response_harm = "punches"

	melee_damage_lower = 1
	melee_damage_upper = 1

	catalogue_data = list(/datum/category_item/catalogue/fauna/elf)

	attacktext = list("slapped", "screamed at", "used ANCIENT MAGIC on")
	friendly = list("hugs", "pats", "chatters at")

	loot_list = list(
		/obj/item/weapon/a_gift = 50,
		/obj/item/weapon/bluespace_harpoon = 1,
		/obj/item/device/perfect_tele = 1,
		/obj/item/weapon/gun/energy/sizegun = 2,
		/obj/item/device/slow_sizegun = 2,
		/obj/item/weapon/gun/energy/mouseray/metamorphosis = 1,
		/obj/item/weapon/deck/cards = 5,
		/obj/item/weapon/pack/cardemon = 5,
		/obj/item/weapon/deck/holder = 5,
		/obj/item/weapon/deck/cah = 5,
		/obj/item/weapon/deck/cah/black = 5,
		/obj/item/weapon/deck/tarot = 5,
		/obj/item/weapon/pack/spaceball = 5,
		/obj/item/weapon/storage/pill_bottle/dice = 5,
		/obj/item/weapon/storage/pill_bottle/dice_nerd = 5,
		/obj/item/weapon/deck/schnapsen = 5,
		/obj/item/weapon/deck/egy = 5,
		/obj/item/weapon/deck/cards/casino = 5,
		/obj/item/weapon/grenade/confetti = 50,
		/obj/item/device/survivalcapsule = 1,
		/obj/item/device/survivalcapsule/luxury = 1,
		/obj/item/device/survivalcapsule/luxurybar = 1,
		/obj/item/device/survivalcapsule/popcabin = 1,
		/obj/item/capture_crystal/random = 5,
		/obj/item/weapon/reagent_containers/food/snacks/cookie = 10,
		/obj/item/weapon/reagent_containers/food/snacks/lasagna = 1,
		/obj/item/weapon/reagent_containers/food/drinks/milk = 10,
		/obj/item/weapon/reagent_containers/food/drinks/smallchocmilk = 10
		)

	ai_holder_type = /datum/ai_holder/simple_mob/melee/elf

	mob_size = MOB_SMALL
	density = FALSE

	vore_active = FALSE
	vore_capacity = 0
	devourable = TRUE
	vore_taste = "eggnog and magic"
	vore_smell = "gingerbread and wonder"

	var/static/list/overlay_cache = list()
	var/beard = FALSE
	var/hat_alt = FALSE
	var/skin_color = "#FFFFCC"
	var/clothing_color = "#339900"


/mob/living/simple_mob/elf/Initialize()
	. = ..()
	if(prob(50))
		beard = TRUE
	if(prob(50))
		hat_alt = TRUE
	skin_color = pick(list(
		"#FFFFCC",
		"#998161",
		"#ffcb90",
		"#252524",
		"#ccfff0"
	))

	clothing_color = pick(list(
		"#339900",
		"#25498d",
		"#ff5e00",
		"#ff00f2",
		"#ff0000"
	))

	var/list/namelist = list(
		"Elf",
		"Elfy",
		"Elfo",
		"Pip",
		"Jingles",
		"Jangles",
		"Fig",
		"Figgy",
		"Cobbler",
		"Mary",
		"Merry",
		"Spark",
		"Tinsel",
		"Noel",
		"Pine",
		"Needle",
		"Glint",
		"Snickerdoodle",
		"Winston",
		"Bloop",
		"Blorp",
		"Gloop",
		"Noodle",
		"Wicket",
		"Zizz",
		"Doodle",
		"Peppermint",
		"Ginger",
		"Toffee",
		"Nog",
		"Cookie",
		"Sprinkle",
		"Springle",
		"Fudge",
		"Jelly",
		"Bonbon",
		"Truffle",
		"Barley",
		"Aspen",
		"Flurry",
		"Birch",
		"Holly",
		"Puff",
		"Cedar",
		"Frost",
		"Glacier",
		"North",
		"Boffo",
		"Gadget",
		"Zippy",
		"Sprocket",
		"Thimble",
		"Cogsworth",
		"Niblet",
		"Quill",
		"Fizzy",
		"Dumpy",
		"Thadreous",
		"Malrath",
		"Buffa",
		"Boffa",
		"Deez",
		"Dem",
		"Grumbo",
		"Glorbo",
		"Blorfus",
		"Dingle",
		"Grunch",
		"Who",
		"Star Chested",
		"Starless",
		"Proudfeet",
		"Bilbo",
		"Frodo",
		"Sam",
		"Pippin",
		"Marie",
		"Gandelf",
		"Shmebulock",
		"Oingo",
		"Boingo",
		"Nook",
		"Cranny",
		"Bib",
		"Bob",
		"Dig",
		"Dug",
		"Buddy",
		"Pride",
		"Greed",
		"Sloth",
		"Envy",
		"Gluttony",
		"Lust",
		"Wroth",
		"Larry",
		"Moe",
		"Curly",
		"Elfaba",
		"Hermey",
		"Crummis",
		"Holiday",
		"Crumbo",
		"Xmas",
		"Dorgeleous",
		"Most Ancient",
		"That Upon Which You Should Not Pick",
		"Him"
	)

	name = pick(namelist)

	switch(name)
		if("Elfaba")
			skin_color = "#276900"
			clothing_color = "#171518"
			beard = FALSE
			hat_alt = FALSE

	if(prob(20))
		var/list/titlelist = list(
			"List",
			"Yodel",
			"Tinsel",
			"Cookie",
			"Coal",
			"Lump-of-Coal",
			"Carol",
			"Reindeer",
			"Toy",
			"Jingle",
			"Gadget",
			"Cheer",
			"Glitter",
			"Nose",
			"Fruitcake",
			"Snowflake",
			"Ice-Skate",
			"Hearth",
			"Great",
			"Grand",
			"Poor",
			"Sleigh",
			"Gift",
			"Pine",
			"Snow-Globe",
			"Journeyman",
			"Ornament",
			"Peppermint",
			"Mint",
			"Candy-Cane",
			"Star",
			"Twinkle",
			"Light",
			"Gingerbread",
			"Stocking",
			"Bell",
			"Hot-Chocolate",
			"Mistletoe",
			"Chimney",
			"Glaze",
			"Fairy-Light",
			"Bow",
			"Wrapping-Paper",
			"Spice",
			"Snowball",
			"Igloo",
			"Workshop",
			"Magic",
			"Halloween Hate",
			"Anti-Halloween",
			"Singer Defrosting",
			"New Years Delayment",
			)


		var/list/ranklist = list(
			"Master",
			"Captain",
			"Wrangler",
			"Orchestrater",
			"Tinkerer",
			"Maker",
			"Certifier",
			"Organizer",
			"Polisher",
			"Checker",
			"Shaper",
			"Forger",
			"Cleaner",
			"Hopper",
			"Fixer",
			"Trainer",
			"Cuddler",
			"Designer",
			"Auditor",
			"Singer",
			"Harper",
			"Drummer",
			"Embellisher",
			"Guardian",
			"Stuffer",
			"Heater",
			"Test Pilot",
			"First Class",
			"Tummy Admirer"
			)

		name = "[name], [pick(titlelist)] [pick(ranklist)]"
	update_icon()

/mob/living/simple_mob/elf/death(deathmessage = DEATHGASP_NO_MESSAGE)
	. = ..()
	visible_message(SPAN_DANGER("\The [src] cries out in pain and disintigrates into a pile of shimmering glitter!"),runemessage = "AAAA AAA AA A . . .")
	var/turf/T = get_turf(src)

	playsound(src, 'sound/items/hooh.ogg', 50, 1)
	playsound(src, 'sound/effects/confetti_ball.ogg', 50, 1)

	var/datum/effect/effect/system/confetti_spread/confeti = new /datum/effect/effect/system/confetti_spread()
	confeti.attach(T)
	confeti.set_up(10, 0, T)
	spawn(0)
		for(var/i = 1 to rand(3,10))
			confeti.start()
		qdel(confeti)
		qdel(src)

/mob/living/simple_mob/elf/update_icon()
	. = ..()
	cut_overlays()

	//SKIN
	var/key = "skin-[skin_color]"
	var/image/ourimage = overlay_cache[key]
	if(!ourimage)
		ourimage = image(icon,null,"elf-skin")
		ourimage.color = skin_color
		ourimage.appearance_flags = RESET_COLOR|KEEP_APART|PIXEL_SCALE
		overlay_cache[key] = ourimage
	add_overlay(ourimage)
	ourimage = null

	//CLOTHING
	key = "clothing-[clothing_color]"
	ourimage = overlay_cache[key]
	if(!ourimage)
		ourimage = image(icon,null,"elf-clothes")
		ourimage.color = clothing_color
		ourimage.appearance_flags = RESET_COLOR|KEEP_APART|PIXEL_SCALE
		overlay_cache[key] = ourimage
	add_overlay(ourimage)
	ourimage = null

	//HAT
	if(hat_alt)
		key = "elf-hat-b"
	else
		key = "elf-hat-a"
	ourimage = overlay_cache[key]
	if(!ourimage)
		ourimage = image(icon,null,key)
		ourimage.appearance_flags = RESET_COLOR|KEEP_APART|PIXEL_SCALE
		overlay_cache[key] = ourimage
	add_overlay(ourimage)
	ourimage = null

	//BEARD
	if(beard)
		key = "beard"
		ourimage = overlay_cache[key]
		if(!ourimage)
			ourimage = image(icon,null,"elf-beard")
			ourimage.appearance_flags = RESET_COLOR|KEEP_APART|PIXEL_SCALE
			overlay_cache[key] = ourimage
		add_overlay(ourimage)

/datum/ai_holder/simple_mob/melee/elf
	hostile = FALSE
	retaliate = TRUE
	grab_hostile = FALSE
	belly_attack = FALSE
	forgive_resting = TRUE
	cooperative = TRUE
