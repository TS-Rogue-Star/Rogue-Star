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
