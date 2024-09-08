//RS Add || Chomp Port

/obj/item/clothing/shoes/mech_shoes
	name = "mech shoes"
	desc = "Thud thud."
	armor = list(melee = 30, bullet = 10, laser = 10, energy = 15, bomb = 20, bio = 0, rad = 0) // Same as loadout jackboots.
	siemens_coefficient = 0.7 // Same as loadout jackboots.
	can_hold_knife = 1
	force = 2
	species_restricted = null
	var/list/squeak_sound = list("mechstep"=1)	//Squeak sound list. Necessary so our subtypes can have different sounds loaded into their component

/obj/item/clothing/shoes/mech_shoes/Initialize(mapload)
	.=..()
	LoadComponent(/datum/component/squeak, squeak_sound, 15*step_volume_mod)

/obj/item/clothing/shoes/mech_shoes/heftyjackboots  //RS Add
	name = "hefty jackboots"
	desc = "Now with one hundred percent more stomp."
	squeak_sound = list('sound/effects/footstep/shoes/boots.ogg'=1)
	step_volume_mod = 5
	icon_state = "jackboots"

/obj/item/clothing/shoes/mech_shoes/heftyjackboots/toeless //RS Add
	name = "hefty toe-less jackboots"
	icon_state = "digiboots"
