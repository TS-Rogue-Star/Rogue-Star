/datum/supply_pack/supply/foodcubes
	name = "Emergency food cubes"
	contains = list(
				/obj/machinery/vending/emergencyfood/filled = 1)
	cost = 75
	containertype = /obj/structure/closet/crate/freezer
	containername = "food cubes"

/datum/supply_pack/supply/postal_service //RS add (mail system supplies)
	name = "Postal Service Supplies"
	contains = list(
		/obj/item/mail/blank = 10,
		/obj/item/weapon/pen/fountain,
		/obj/item/weapon/pen/multi,
		/obj/item/device/destTagger,
		/obj/item/weapon/storage/bag/mail
	)
	cost = 15
	containertype = /obj/structure/closet/crate/nanotrasen
	containername = "Postal Service crate"
