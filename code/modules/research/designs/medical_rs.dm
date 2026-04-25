/*
	KX - Bluespace Medigun
		KXAAA - gun
		KXAAB - upgrade kit
*/

// BSM-92 medigun and upgrade
/datum/design/item/medical/bluespacemedigun/AssembleDesignName()
	..()
	name = "Bluespace Medigun ([item_name])"

/datum/design/item/medical/bluespacemedigun
	name = "BSM-92"
	id = "bluespace_medigun"
	req_tech = list(TECH_MATERIAL = 6, TECH_MAGNET = 4, TECH_POWER = 3, TECH_BIO = 5)
	materials = list(MAT_STEEL = 8000, MAT_PLASTIC = 8000, MAT_GLASS = 5000, MAT_SILVER = 1000, MAT_GOLD = 1000, MAT_URANIUM = 1000)
	build_path = /obj/item/device/continuous_medigun
	sort_string = "KXAAA"

/datum/design/item/medical/bluespacemedigun/upgrade
	name = "BSM-92 Upgrade Kit"
	id = "bsm92_upgrade"
	req_tech = list(TECH_MATERIAL = 7, TECH_MAGNET = 6, TECH_POWER = 4, TECH_BIO = 7)
	materials = list(MAT_STEEL = 5000, MAT_PLASTIC = 10000, MAT_GLASS = 5000, MAT_SILVER = 1500, MAT_GOLD = 1500, MAT_DIAMOND = 5000)
	build_path = /obj/item/device/continuous_medigun_modkit
	sort_string = "KXAAB"
