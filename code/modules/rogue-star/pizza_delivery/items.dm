/obj/item/pizzabox/pizzastation
	name = "pizza station pizza box"
	desc = "A box suited for pizzas, this one seems to be from pizza station."
	icon = 'icons/rogue-star/pizza_delivery/items_rs.dmi'
	icon_state = "pizzabox1"
	item_icons = list(
		slot_l_hand_str = 'icons/rogue-star/pizza_delivery/items_left_hand_rs.dmi',
		slot_r_hand_str = 'icons/rogue-star/pizza_delivery/items_right_hand_rs.dmi',
		)

/obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/margherita/pizzastation
	icon = 'icons/rogue-star/pizza_delivery/items_rs.dmi'
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/slice/margherita/pizzastation

/obj/item/weapon/reagent_containers/food/snacks/slice/margherita/pizzastation
	icon = 'icons/rogue-star/pizza_delivery/items_rs.dmi'
	whole_path = /obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/margherita/pizzastation

/obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/pineapple/pizzastation
	icon = 'icons/rogue-star/pizza_delivery/items_rs.dmi'
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/slice/pineapple/pizzastation

/obj/item/weapon/reagent_containers/food/snacks/slice/pineapple/pizzastation
	icon = 'icons/rogue-star/pizza_delivery/items_rs.dmi'
	whole_path = /obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/pineapple/pizzastation

/obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/meatpizza/pizzastation
	icon = 'icons/rogue-star/pizza_delivery/items_rs.dmi'
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/slice/meatpizza/pizzastation

/obj/item/weapon/reagent_containers/food/snacks/slice/meatpizza/pizzastation
	icon = 'icons/rogue-star/pizza_delivery/items_rs.dmi'
	whole_path = /obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/meatpizza/pizzastation

/obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/mushroompizza/pizzastation
	icon = 'icons/rogue-star/pizza_delivery/items_rs.dmi'
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/slice/mushroompizza/pizzastation

/obj/item/weapon/reagent_containers/food/snacks/slice/mushroompizza/pizzastation
	icon = 'icons/rogue-star/pizza_delivery/items_rs.dmi'
	whole_path = /obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/mushroompizza/pizzastation

/obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/vegetablepizza/pizzastation
	icon = 'icons/rogue-star/pizza_delivery/items_rs.dmi'
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/slice/vegetablepizza/pizzastation

/obj/item/weapon/reagent_containers/food/snacks/slice/vegetablepizza/pizzastation
	icon = 'icons/rogue-star/pizza_delivery/items_rs.dmi'
	whole_path = /obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/vegetablepizza/pizzastation

/obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/donkpocket/pizzastation
	name = "Donkpocket pizza"
	desc = "An excellent, lazily made pizza with meat pastries on top."
	icon = 'icons/rogue-star/pizza_delivery/items_rs.dmi'
	icon_state = "donkpocketpizza"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/slice/donkpocket/pizzastation
	slices_num = 6
	center_of_mass = list("x"=16, "y"=11)
	nutriment_desc = list("pizza crust" = 1, "tomato" = 1, "cheese" = 1, "umami" = 1, "laziness" = 1)
	nutriment_amt = 20
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/donkpocket/pizzastation/Initialize()
	. = ..()
	reagents.add_reagent("protein", 15)
	reagents.add_reagent("tomatojuice", 6)
	reagents.add_reagent("tricordrazine", 10)
	reagents.add_reagent("paracetamol", 4)
	reagents.add_reagent("enzyme", 1)
	reagents.add_reagent("iron", 2)

/obj/item/weapon/reagent_containers/food/snacks/slice/donkpocket/pizzastation
	name = "Donkpocket pizza slice"
	desc = "Smells like donkpocket."
	icon = 'icons/rogue-star/pizza_delivery/items_rs.dmi'
	icon_state = "donkpocketpizzaslice"
	filling_color = "#BAA14C"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=13)
	whole_path = /obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/donkpocket/pizzastation

/obj/item/weapon/reagent_containers/food/snacks/slice/donkpocket/pizzastation/filled
	filled = TRUE

/obj/item/weapon/reagent_containers/food/snacks/meat_calzone
	name = "meat calzone"
	desc = "A calzone filled with cheese, meat, and a tomato sauce. Don't burn your tongue!"
	icon = 'icons/rogue-star/pizza_delivery/items_rs.dmi'
	icon_state = "meat_calzone"
	nutriment_desc = list("baked dough" = 1, "tomato sauce" = 1, "melted cheese" = 1, "juicy meat" = 1)
	nutriment_amt = 8

/obj/item/weapon/reagent_containers/food/snacks/meat_calzone/Initialize()
	. = ..()
	reagents.add_reagent("protein", 6)
	reagents.add_reagent("tricordrazine", 5)
	reagents.add_reagent("paracetamol", 5)
	reagents.add_reagent("enzyme", 1)
	reagents.add_reagent("iron", 3)
	reagents.add_reagent("tomatojuice", 6)

/obj/item/weapon/reagent_containers/food/snacks/vegetarian_calzone
	name = "vegetarian calzone"
	desc = "A calzone filled with mixed vegetables and a tomato sauce. A healthier, yet less satisfying alternative."
	icon = 'icons/rogue-star/pizza_delivery/items_rs.dmi'
	icon_state = "vegetarian_calzone"
	nutriment_desc = list("baked dough" = 1, "baked vegetables" = 1, "tomato sauce" = 1)
	nutriment_amt = 10

/obj/item/weapon/reagent_containers/food/snacks/vegetarian_calzone/Initialize()
	. = ..()
	reagents.add_reagent("tricordrazine", 6)
	reagents.add_reagent("paracetamol", 6)
	reagents.add_reagent("enzyme", 1)
	reagents.add_reagent("iron", 4)

/obj/item/pizzabox/pizzastation/margherita/Initialize()
	pizza = new /obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/margherita/pizzastation(src)
	boxtag = "Pizza Station's Margherita Deluxe"
	. = ..()

/obj/item/pizzabox/pizzastation/vegetable/Initialize()
	pizza = new /obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/vegetablepizza/pizzastation(src)
	boxtag = "Pizza Station's Gourmet Vegatable"
	. = ..()

/obj/item/pizzabox/pizzastation/mushroom/Initialize()
	pizza = new /obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/mushroompizza/pizzastation(src)
	boxtag = "Pizza Station's Mushroom Special"
	. = ..()

/obj/item/pizzabox/pizzastation/meat/Initialize()
	pizza = new /obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/meatpizza/pizzastation(src)
	boxtag = "Pizza Station's Meatlover's Supreme"
	. = ..()

/obj/item/pizzabox/pizzastation/pineapple/Initialize()
	pizza = new /obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/pineapple/pizzastation(src)
	boxtag = "Pizza Station's Hawaiian Sunrise"
	. = ..()

/obj/item/pizzabox/pizzastation/donkpocket/Initialize()
	pizza = new /obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/donkpocket/pizzastation(src)
	boxtag = "Pizza Station's Bangin' Donk"
	. = ..()

/obj/item/weapon/reagent_containers/food/drinks/cans/dr_gibb/pizzastation
	icon = 'icons/rogue-star/pizza_delivery/items_rs.dmi'
	item_icons = list(
		slot_l_hand_str = 'icons/rogue-star/pizza_delivery/items_left_hand_rs.dmi',
		slot_r_hand_str = 'icons/rogue-star/pizza_delivery/items_right_hand_rs.dmi',
		)

/obj/item/weapon/reagent_containers/food/drinks/cans/space_up/pizzastation
	icon = 'icons/rogue-star/pizza_delivery/items_rs.dmi'
	item_icons = list(
		slot_l_hand_str = 'icons/rogue-star/pizza_delivery/items_left_hand_rs.dmi',
		slot_r_hand_str = 'icons/rogue-star/pizza_delivery/items_right_hand_rs.dmi',
		)

/obj/item/weapon/reagent_containers/food/drinks/cans/cola/pizzastation
	icon = 'icons/rogue-star/pizza_delivery/items_rs.dmi'
	item_icons = list(
		slot_l_hand_str = 'icons/rogue-star/pizza_delivery/items_left_hand_rs.dmi',
		slot_r_hand_str = 'icons/rogue-star/pizza_delivery/items_right_hand_rs.dmi',
		)

/obj/item/weapon/storage/fancy/soda
	name = "can ring"
	desc = "Holds up to six soda cans."
	icon = 'icons/rogue-star/pizza_delivery/items_rs.dmi'
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
	icon = 'icons/rogue-star/pizza_delivery/items_rs.dmi'
	icon_state = "dgcanholder6"
	w_class = ITEMSIZE_NORMAL
	throwforce = 2
	slot_flags = SLOT_BELT
	max_storage_space = ITEMSIZE_COST_SMALL * 6
	storage_slots = 6
	can_hold = list(/obj/item/weapon/reagent_containers/food/drinks/cans/dr_gibb/pizzastation)
	starts_with = list(/obj/item/weapon/reagent_containers/food/drinks/cans/dr_gibb/pizzastation = 6)

/obj/item/weapon/storage/fancy/soda/dr_gibb/update_icon(var/itemremoved = 0)
	var/total_contents = contents.len - itemremoved
	icon_state = "dgcanholder[total_contents]"

/obj/item/weapon/storage/fancy/soda/space_up
	name = "Space Up can ring"
	desc = "Holds up to six soda cans."
	icon = 'icons/rogue-star/pizza_delivery/items_rs.dmi'
	icon_state = "sucanholder6"
	w_class = ITEMSIZE_NORMAL
	throwforce = 2
	slot_flags = SLOT_BELT
	max_storage_space = ITEMSIZE_COST_SMALL * 6
	storage_slots = 6
	can_hold = list(/obj/item/weapon/reagent_containers/food/drinks/cans/space_up/pizzastation)
	starts_with = list(/obj/item/weapon/reagent_containers/food/drinks/cans/space_up/pizzastation = 6)

/obj/item/weapon/storage/fancy/soda/space_up/update_icon(var/itemremoved = 0)
	var/total_contents = contents.len - itemremoved
	icon_state = "sucanholder[total_contents]"

/obj/item/weapon/storage/fancy/soda/cola
	name = "Space Cola can ring"
	desc = "Holds up to six soda cans."
	icon = 'icons/rogue-star/pizza_delivery/items_rs.dmi'
	icon_state = "cocanholder6"
	w_class = ITEMSIZE_NORMAL
	throwforce = 2
	slot_flags = SLOT_BELT
	max_storage_space = ITEMSIZE_COST_SMALL * 6
	storage_slots = 6
	can_hold = list(/obj/item/weapon/reagent_containers/food/drinks/cans/cola/pizzastation)
	starts_with = list(/obj/item/weapon/reagent_containers/food/drinks/cans/cola/pizzastation = 6)

/obj/item/weapon/storage/fancy/soda/cola/update_icon(var/itemremoved = 0)
	var/total_contents = contents.len - itemremoved
	icon_state = "cocanholder[total_contents]"
