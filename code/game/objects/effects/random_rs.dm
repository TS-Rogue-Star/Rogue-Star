/obj/random/monkey_cubes
	name = "Random Monkey Cube Box"

/obj/random/monkey_cubes/item_to_spawn()
	return pick(/obj/item/weapon/storage/box/monkeycubes,
				/obj/item/weapon/storage/box/monkeycubes/farwacubes,
				/obj/item/weapon/storage/box/monkeycubes/stokcubes,
				/obj/item/weapon/storage/box/monkeycubes/neaeracubes,
				/obj/item/weapon/storage/box/monkeycubes/sobakacubes,
				/obj/item/weapon/storage/box/monkeycubes/sarucubes,
				/obj/item/weapon/storage/box/monkeycubes/sparracubes,
				/obj/item/weapon/storage/box/monkeycubes/wolpincubes)

/*
/obj/random/food
	name = "Random Food"

/obj/random/food/item_to_spawn()
	return pick(subtypesof(/obj/item/weapon/reagent_containers/food/snacks))

/obj/random/drink
	name = "Random Drink"

/obj/random/drink/item_to_spawn()
	return pick(subtypesof(/obj/item/weapon/reagent_containers/food/drinks))
*/
/turf/simulated/floor/tile/clay
	name = "clay roof"
	desc = "Dinosaurs aren't very good at standing on this."
	icon = 'icons/rogue-star/misc.dmi'
	icon_state = "clay_roof"
	outdoors = TRUE

/turf/simulated/floor/tile/clay/top
	icon_state = "clay_roof_top"

/turf/simulated/floor/tile/clay/middle
	icon_state = "clay_roof_middle"

/obj/structure/prop/coffee_maker
	name = "coffee maker"
	desc = "There's no beans..."
	icon = 'icons/rogue-star/misc.dmi'
	icon_state = "coffee_maker"
	interaction_message = "There's no beans..."

/obj/structure/prop/camera
	name = "camera"
	desc = "It seems to be recording..."
	icon = 'icons/rogue-star/misc.dmi'
	icon_state = "camera"
	interaction_message = "You try to stop it but it won't stop!"

/obj/structure/prop/tv
	name = "television"
	desc = "It's TV Time!"
	icon = 'icons/rogue-star/misc.dmi'
	icon_state = "tenna"
	interaction_message = "There's nothing on..."

/obj/structure/prop/cage
	name = "bird cage"
	desc = "For birds... or something."
	icon = 'icons/rogue-star/misc.dmi'
	icon_state = "birdcage"
	micro_target = TRUE

/turf/simulated/floor/tile/smooth
	name = "smooth tile"
	desc = "Someone spends a lot of time on their hands and knees. (To polish the tiles. What did you think I meant?)"
	icon = 'icons/rogue-star/misc.dmi'
	icon_state = "smooth_tile"

/turf/simulated/floor/tile/smooth/blue
	icon_state = "smooth_tile_blue"
/turf/simulated/floor/tile/smooth/red
	icon_state = "smooth_tile_red"
