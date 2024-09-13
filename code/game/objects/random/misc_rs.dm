// RS file

/obj/random/round_end_lasagna
	name = "round end lasagna"
	desc = "Lasagna at the CentCom cafe that everyone tries to get hands on."
	icon = 'icons/obj/food.dmi'
	icon_state = "lasagna"
	spawn_nothing_percentage = 0

/obj/random/roundend_lasagna/item_to_spawn()
	return pick(
			prob(90);/obj/item/weapon/reagent_containers/food/snacks/lasagna,
			prob(10);/obj/item/toy/plushie/lasagna
			)