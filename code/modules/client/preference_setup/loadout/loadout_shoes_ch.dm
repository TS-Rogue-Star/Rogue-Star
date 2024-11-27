//RS Add || Chomp Port

/datum/gear/shoes/mech_shoes
	display_name = "stepsound shoes selection"
	path = /obj/item/clothing/shoes/mech_shoes
	cost = 1

/datum/gear/shoes/mech_shoes/New()
	..()
	var/list/mechshoes = list(
	"hefty jackboots" = /obj/item/clothing/shoes/mech_shoes/heftyjackboots/, //RS Edit
	"hefty toe-less jackboots" = /obj/item/clothing/shoes/mech_shoes/heftyjackboots/toeless //RS Edit
	)
	gear_tweaks += new/datum/gear_tweak/path(mechshoes)
