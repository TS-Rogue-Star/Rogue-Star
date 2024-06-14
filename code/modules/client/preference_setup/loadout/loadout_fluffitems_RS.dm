//RS CUSTOM FLUFF ITEMS BEGIN

/datum/gear/fluff/dulahan_fire
	path = /obj/item/clothing/head/fluff/dulahan_fire
	display_name = "Dulahan's Fire"
	slot = slot_head
	ckeywhitelist = list("hiddenname1702")
	character_name = list("Ena")

/datum/gear/fluff/dulahan_flame/New()
	..()
	gear_tweaks += gear_tweak_free_color_choice

/datum/gear/fluff/ena_head
	path = /obj/item/weapon/fluff/ena_head
	display_name = "Ena's Head"
	slot = slot_head
	ckeywhitelist = list("hiddenname1702")
	character_name = list("Ena")
