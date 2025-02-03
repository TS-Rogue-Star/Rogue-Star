/obj/machinery/vending/wardrobe/talondrobe
	name = "ITV Talon wardrobe vendor"
	desc = "All the things you need to perform your job! Why didn't you already have them?"
	product_slogans = "Want to do your job? Sure you do!"
	icon_state = "detdrobe"
	req_access = list(access_talon)
	products = list(
		/obj/item/clothing/accessory/talon = 5,
		/obj/item/clothing/head/det/grey = 5,
		/obj/item/clothing/head/neo_irs = 5,
		/obj/item/clothing/shoes/brown = 5,
		/obj/item/clothing/shoes/laceup = 5,
		/obj/item/clothing/under/det = 5,
		/obj/item/clothing/under/det/waistcoat = 5,
		/obj/item/clothing/under/det/grey = 5,
		/obj/item/clothing/under/det/grey/waistcoat = 5,
		/obj/item/clothing/under/det/black = 5,
		/obj/item/clothing/under/det/skirt,
		/obj/item/clothing/under/det/corporate = 5,
		/obj/item/clothing/suit/storage/det_trench = 5,
		/obj/item/clothing/suit/storage/det_trench/grey = 5,
		/obj/item/clothing/suit/storage/forensics/blue = 5,
		/obj/item/clothing/suit/storage/forensics/red = 5
	)
	req_log_access = access_talon_bridge
	has_logs = 1
