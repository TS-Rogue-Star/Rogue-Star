//RS CUSTOM FLUFF ITEMS BEGIN

/obj/item/clothing/head/fluff/dulahan_fire		//hiddenname1702 fluff item	- Sprites by VerySoft
	name = "dulahan's fire"
	desc = "This Dulahan's head appears to be missing, and a fire rests in it's place."
	icon = 'icons/rogue-star/hats.dmi'
	icon_state = "d_fire"
	icon_override = 'icons/rogue-star/hats.dmi'
	item_state = "d_fire"
	body_parts_covered = HEAD
	plane = PLANE_LIGHTING_ABOVE
	light_range = 2
	light_overlay = null
	light_system = MOVABLE_LIGHT

/obj/item/clothing/head/fluff/dulahan_fire/Initialize()
	. = ..()
	update_flashlight()

/obj/item/clothing/head/fluff/dulahan_fire/update_flashlight(mob/user)
	light_color = color
	return ..()

/obj/item/weapon/fluff/ena_head
	name = "Ena's Head"
	desc = "The head of a Dulahan, careful it doesn't bite you!"
	icon = 'icons/vore/custom_items_rs.dmi'
	icon_state = "ena_head"
	force = 1
	throwforce = 1
	throw_speed = 4
	throw_range = 20

/obj/item/toy/plushie/snakeplushie/fluff/river
	name = "Vivid's River"
	desc = "An aquatic noodle that Vivid uses to showcase the actions of their blue wyrm"
	icon = 'icons/vore/custom_items_rs.dmi'
	icon_state = "river"
	drop_sound = "generic_drop"

/obj/item/toy/plushie/snakeplushie/fluff/jyen
	name = "Vivid's Jyen"
	desc = "A fluffy noodle that Vivid uses to showcase the actions of their white wyrm"
	icon = 'icons/vore/custom_items_rs.dmi'
	icon_state = "jyen"
	drop_sound = "generic_drop"

/obj/item/toy/plushie/snakeplushie/fluff/raye
	name = "Vivid's Raye"
	desc = "An acid noodle that Vivid uses to showcase the actions of their green wyrm"
	icon = 'icons/vore/custom_items_rs.dmi'
	icon_state = "raye"
	drop_sound = "generic_drop"

/obj/item/toy/plushie/snakeplushie/fluff/zoey
	name = "Vivid's Zoey"
	desc = "A hypnotic noodle that Vivid uses to showcase the actions of their yellow wyrm"
	icon = 'icons/vore/custom_items_rs.dmi'
	icon_state = "zoey"
	drop_sound = "generic_drop"

/obj/item/clothing/under/permit/fluff/tracking_implant
	name = "embedded tracker implant"
	desc = "A small, spherical black device. Emblazoned with a crimson Y-like logo on one side and the numbers 53799 stamped on the back."
	icon = 'icons/vore/custom_items_rs.dmi'
	icon_state = "anoscetiaImplant"
	var/obj/item/device/gps/gps_tracker		//It has a secret GPS device in it

/obj/item/clothing/under/permit/fluff/tracking_implant/Initialize()
	. = ..()
	gps_tracker = new(src)
	gps_tracker.gps_tag = "Syne"
	gps_tracker.tracking = TRUE

/obj/item/clothing/under/permit/fluff/tracking_implant/Destroy()
	gps_tracker = null
	return ..()

/obj/item/weapon/reagent_containers/food/drinks/bottle/bottleofnothing/fluff/fiddle
	name = "Infinite Bottle of Nothing"
	desc = "A bottle filled with nothing. It seems infinitely empty."
	icon_state = "bottleofnothing"

/obj/item/weapon/reagent_containers/food/drinks/bottle/bottleofnothing/fluff/fiddle/Initialize()
	. = ..()
	START_PROCESSING(SSobj, src) // 1/sec

/obj/item/weapon/reagent_containers/food/drinks/bottle/bottleofnothing/fluff/fiddle/Destroy()
	STOP_PROCESSING(SSobj, src) // It sorta handles this itself but save it the trouble
	return ..()

/obj/item/weapon/reagent_containers/food/drinks/bottle/bottleofnothing/fluff/fiddle/process()
	reagents.add_reagent("nothing", 0.5) // Full bottle refill in ~3.3 minutes

/obj/item/weapon/tool/screwdriver/fluff/fiddle
	name = "Mimedriver"
	desc = "A black and white tool used for screwing. This one seems to be made of some alien material which doesn't make any sounds..."
	catalogue_data = list(/datum/category_item/catalogue/anomalous/precursor_a/alien_screwdriver) //it's made of tranquillite
	icon = 'icons/vore/custom_items_rs.dmi'
	icon_state = "mimedriver"
	force = 0
	throwforce = 0
	hitsound = null
	usesound = null
	drop_sound = null
	pickup_sound = null
	matter = null
	random_color = FALSE

/obj/item/clothing/suit/cultrobes/alt/fluff
	desc = "A set of common robes designed in imitation of a particular occult style."
	armor = list(melee = 0, bullet = 0, laser = 0, energy = 0, bomb = 0, bio = 0, rad = 0)
	origin_tech = list(TECH_MATERIAL = 3)
	siemens_coefficient = 0.9

/obj/item/clothing/head/culthood/alt/fluff
	desc = "A common hood designed in imitation of a particular occult style."
	armor = list(melee = 0, bullet = 0, laser = 0, energy = 0, bomb = 0, bio = 0, rad = 0)
	origin_tech = list(TECH_MATERIAL = 3)
	siemens_coefficient = 0.9

/obj/item/toy/plushie/portal
	name = "fluffy goo-wolf plushie"
	desc = "A gooey white wolf-like plushie with orange markings on the limbs, chin, tail and ears, they appear to be dripping slightly. It has a black skull-like mask over it's face and is wearing a pizza delivery uniform with a nametag depicting the name \"Portal\" on it! It looks incredibly fluffy and soft!"
	icon = 'icons/vore/custom_items_rs.dmi'
	icon_state = "portal"
	pokephrase = "Pizza Delivery~!"

/obj/item/pizzabox/pizzastation
	name = "pizza station pizza box"
	desc = "A box suited for pizzas, this one seems to be from pizza station."
	icon = 'icons/vore/custom_items_rs.dmi'
	icon_state = "pizzabox1"
	item_icons = list(
		slot_l_hand_str = 'icons/vore/custom_items_left_hand_rs.dmi',
		slot_r_hand_str = 'icons/vore/custom_items_right_hand_rs.dmi',
		)

/obj/item/pizzabox/pizzastation/margherita/Initialize()
	pizza = new /obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/margherita(src)
	boxtag = "Pizza Station's Margherita Deluxe"
	. = ..()

/obj/item/pizzabox/pizzastation/vegetable/Initialize()
	pizza = new /obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/vegetablepizza(src)
	boxtag = "Pizza Station's Gourmet Vegatable"
	. = ..()

/obj/item/pizzabox/pizzastation/mushroom/Initialize()
	pizza = new /obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/mushroompizza(src)
	boxtag = "Pizza Station's Mushroom Special"
	. = ..()

/obj/item/pizzabox/pizzastation/meat/Initialize()
	pizza = new /obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/meatpizza(src)
	boxtag = "Pizza Station's Meatlover's Supreme"
	. = ..()

/obj/item/pizzabox/pizzastation/pineapple/Initialize()
	pizza = new /obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/pineapple(src)
	boxtag = "Pizza Station's Hawaiian Sunrise"
	. = ..()

/obj/item/weapon/reagent_containers/food/drinks/cans/dr_gibb/deluxe
	description_fluff = "Following a 2490 lawsuit and a spate of deaths, Gilthari Exports reminds customers that the 'Dr.' legally stands for 'Drink', now even better.. Somehow!"
	icon = 'icons/vore/custom_items_rs.dmi'

/obj/item/weapon/reagent_containers/food/drinks/cans/space_up/deluxe
	description_fluff = "The 'Space' branding was originally added to the 'Alpha Cola' product line in order to justify selling cans for 50% higher prices to 'off-world' retailers. Despite being chemically identical, Space Cola proved so popular that Centauri Provisions eventually applied the name to the entire product line - price hike and all. Now even better.. Somehow!"
	icon = 'icons/vore/custom_items_rs.dmi'

/obj/item/weapon/storage/fancy/soda
	name = "can ring"
	desc = "Holds up to six soda cans."
	icon = 'icons/vore/custom_items_rs.dmi'
	icon_state = "canholder6"
	w_class = ITEMSIZE_NORMAL
	throwforce = 2
	slot_flags = SLOT_BELT
	max_storage_space = ITEMSIZE_COST_SMALL * 6
	storage_slots = 6
	can_hold = null
	starts_with = null

/obj/item/weapon/storage/fancy/soda/Initialize()
	. = ..()
	update_icon()

/obj/item/weapon/storage/fancy/soda/examine(mob/user)
	. = ..()

	if(Adjacent(user))
		if(!contents.len)
			. += "There are no [icon_type]s left in the can ring."
		else if(contents.len == 1)
			. += "There is one [icon_type] left in the can ring."
		else
			. += "There are [contents.len] [icon_type]s in the can ring."

/obj/item/weapon/storage/fancy/soda/update_icon(var/itemremoved = 0)
	var/total_contents = contents.len - itemremoved
	icon_state = "canholder[total_contents]"

/obj/item/weapon/storage/fancy/soda/attackby(obj/item/weapon/W as obj, mob/user as mob)
	..()
	update_icon()

/obj/item/weapon/storage/fancy/soda/dr_gibb
	name = "Dr. Gibb can ring"
	desc = "Holds up to six soda cans."
	icon = 'icons/vore/custom_items_rs.dmi'
	icon_state = "dgcanholder6"
	w_class = ITEMSIZE_NORMAL
	throwforce = 2
	slot_flags = SLOT_BELT
	max_storage_space = ITEMSIZE_COST_SMALL * 6
	storage_slots = 6
	can_hold = list(/obj/item/weapon/reagent_containers/food/drinks/cans/dr_gibb/deluxe)
	starts_with = list(/obj/item/weapon/reagent_containers/food/drinks/cans/dr_gibb/deluxe = 6)

/obj/item/weapon/storage/fancy/soda/dr_gibb/update_icon(var/itemremoved = 0)
	var/total_contents = contents.len - itemremoved
	icon_state = "dgcanholder[total_contents]"

/obj/item/weapon/storage/fancy/soda/space_up
	name = "Space Up can ring"
	desc = "Holds up to six soda cans."
	icon = 'icons/vore/custom_items_rs.dmi'
	icon_state = "sucanholder6"
	w_class = ITEMSIZE_NORMAL
	throwforce = 2
	slot_flags = SLOT_BELT
	max_storage_space = ITEMSIZE_COST_SMALL * 6
	storage_slots = 6
	can_hold = list(/obj/item/weapon/reagent_containers/food/drinks/cans/space_up/deluxe)
	starts_with = list(/obj/item/weapon/reagent_containers/food/drinks/cans/space_up/deluxe = 6)

/obj/item/weapon/storage/fancy/soda/space_up/update_icon(var/itemremoved = 0)
	var/total_contents = contents.len - itemremoved
	icon_state = "sucanholder[total_contents]"
