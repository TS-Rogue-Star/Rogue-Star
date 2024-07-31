/proc/make_types_fancy(list/types)
	if (ispath(types))
		types = list(types)
	var/static/list/types_to_replacement
	var/static/list/replacement_to_text
	if(!types_to_replacement)
		// Longer paths come after shorter ones, try and keep the structure
		var/list/work_from = list(
			/datum = "DATUM",
			/datum/reagent = "REAGENT",

			/area = "AREA",
			/area/redgate = "AREA_REDGATE",

			/atom/movable = "MOVABLE",
			/obj = "OBJ",
			/turf = "TURF",
			/turf/space = "SPACE",
			/turf/simulated = "SIMULATED",
			/turf/unsimulated = "UNSIMULATED",
			/turf/simulated/floor = "FLOOR",
			/turf/simulated/floor/dungeon = "DUNGEON_FLOOR",
			/turf/simulated/floor/outdoors = "OUTDOOR_FLOOR",
			/turf/simulated/floor/outdoors/snow = "OUTDOOR_SNOW",
			/turf/simulated/floor/outdoors/grass = "OUTDOOR_GRASS",
			/turf/simulated/floor/water = "WATER",
			/turf/simulated/floor/water/underwater = "UNDERWATER",
			/turf/simulated/floor/lava = "LAVA",
			/turf/simulated/shuttle = "SHUTTLE",
			/turf/simulated/wall = "WALL",
			/turf/simulated/wall/dungeon = "DUNGEON_WALL",
			/turf/simulated/wall/solidrock = "SOLID_ROCK",
			/turf/simulated/wall/eris = "ERIS_WALL",
			/turf/simulated/wall/bay = "BAY_WALL",
			/turf/simulated/wall/tgmc = "TGMC_WALL",
			/turf/simulated/flesh = "FLESH",


			/mob = "MOB",
			/mob/living = "LIVING",
			/mob/living/carbon = "CARBON",
			/mob/living/carbon/human = "HUMANOID",
			/mob/living/simple_mob = "SIMPLE",
			/mob/living/simple_mob/vore = "SIMPLE_VORE",
			/mob/living/simple_mob/vore/alienanimals = "SIMPLE_VORE_ALIENS",
			/mob/living/simple_mob/humanoid = "SIMPLE_HUMAN",
			/mob/living/simple_mob/animal = "SIMPLE_ANIMAL",
			/mob/living/simple_mob/animal/passive = "SIMPLE_PASSIVE",
			/mob/living/simple_mob/animal/giant_spider = "GIANT_SPIDER",
			/mob/living/simple_mob/animal/space = "SIMPLE_SPACE",
			/mob/living/simple_mob/animal/space/carp = "CARP",
			/mob/living/simple_mob/animal/space/goose = "GOOSE",
			/mob/living/simple_mob/animal/space/alien = "SPACE_ALIEN",
			/mob/living/silicon = "SILICON",
			/mob/living/silicon/robot = "CYBORG",

			/obj/item = "ITEM",
			/obj/item/weapon = "WEAPON",
			/obj/item/weapon/cell = "POWERCELL",
			/obj/item/mecha_parts = "MECHA_PART",
			/obj/item/mecha_parts/mecha_equipment = "MECHA_EQUIP",
			/obj/item/mecha_parts/mecha_equipment/weapon = "MECHA_WEAPON",
			/obj/item/weapon/card = "CARD",
			/obj/item/weapon/card/id = "IDCARD",
			/obj/item/weapon/tool = "TOOL",
			/obj/item/weapon/surgical = "SURGICAL",
			/obj/item/weapon/melee = "MELEE",
			/obj/item/weapon/melee/energy = "ENERGY_MELEE",
			/obj/item/weapon/gun = "GUN",
			/obj/item/weapon/gun/launcher = "GUN_LAUNCHER",
			/obj/item/weapon/gun/magic = "GUN_MAGIC",
			/obj/item/weapon/gun/energy = "GUN_ENERGY",
			/obj/item/weapon/gun/energy/laser = "GUN_LASER",
			/obj/item/weapon/gun/magnetic = "GUN_MAGNETIC",
			/obj/item/weapon/gun/projectile = "GUN_BALLISTIC",
			/obj/item/weapon/gun/projectile/automatic = "GUN_AUTOMATIC",
			/obj/item/weapon/gun/projectile/revolver = "GUN_REVOLVER",
			//obj/item/weapon/gun/projectile/rifle = "GUN_RIFLE",
			/obj/item/weapon/gun/projectile/shotgun = "GUN_SHOTGUN",
			/obj/item/stack = "STACK",
			/obj/item/stack/material = "SHEET",
			//obj/item/stack/sheet/mineral = "MINERAL_SHEET",
			/obj/item/weapon/ore = "ORE",
			/obj/item/stack/medical = "STACK_MED",
			/obj/item/weapon/aiModule = "AI_LAW_MODULE",
			/obj/item/weapon/circuitboard = "CIRCUITBOARD",
			//obj/item/weapon/circuitboard/machine = "MACHINE_BOARD",
			//obj/item/weapon/circuitboard/computer = "COMPUTER_BOARD",
			/obj/item/weapon/reagent_containers = "REAGENT_CONTAINERS",
			/obj/item/weapon/reagent_containers/glass = "GLASS",
			/obj/item/weapon/reagent_containers/glass/bottle = "BOTTLE",
			/obj/item/weapon/reagent_containers/glass/bottle/hypovial = "HYPOVIAL",
			/obj/item/weapon/reagent_containers/pill = "PILL",
			/obj/item/weapon/reagent_containers/pill/patch = "MEDPATCH",
			/obj/item/weapon/reagent_containers/hypospray/autoinjector = "AUTOINJECT",
			/obj/item/weapon/reagent_containers/food = "FOOD",
			/obj/item/weapon/reagent_containers/food/snacks = "SNACKS",
			/obj/item/weapon/reagent_containers/food/drinks = "DRINK",
			/obj/item/organ = "ORGAN",
			/obj/item/organ/external = "ORGAN_EXT",
			/obj/item/organ/internal = "ORGAN_INT",
			/obj/effect/decal/cleanable = "CLEANABLE",
			/obj/item/device = "DEVICE",
			/obj/item/device/nif = "NIF",
			/obj/item/device/radio = "RADIO",
			/obj/item/device/radio/headset = "HEADSET",
			/obj/item/clothing = "CLOTHING",
			/obj/item/clothing/accessory = "ACCESSORY",
			/obj/item/clothing/mask/gas = "GASMASK",
			/obj/item/clothing/mask = "MASK",
			/obj/item/clothing/gloves = "GLOVES",
			/obj/item/clothing/shoes = "SHOES",
			/obj/item/clothing/under = "JUMPSUIT",
			/obj/item/clothing/suit/armor = "ARMOR",
			/obj/item/clothing/suit = "SUIT",
			/obj/item/clothing/head/helmet = "HELMET",
			/obj/item/clothing/head = "HEAD",
			//obj/item/clothing/neck = "NECK",
			/obj/item/weapon/storage = "STORAGE",
			/obj/item/weapon/storage/box = "STORAGE_BOX",
			/obj/item/weapon/storage/box/fluff = "STORAGE_FLUFF",
			/obj/item/weapon/storage/firstaid = "FIRSTAID_BOX",
			/obj/item/weapon/storage/firstaid/hypokit = "HYPOKIT",
			/obj/item/weapon/storage/backpack = "BACKPACK",
			/obj/item/weapon/storage/belt = "BELT",
			/obj/item/weapon/storage/pill_bottle = "PILL_BOTTLE",
			/obj/item/weapon/storage/toolbox = "TOOLBOX",
			/obj/item/weapon/book/manual = "MANUAL",

			/obj/structure = "STRUCTURE",
			/obj/structure/closet = "CLOSET",
			/obj/structure/closet/crate = "CRATE",
			/obj/structure/closet/crate/secure = "LOCKED_CRATE",
			/obj/structure/closet/secure_closet = "LOCKED_CLOSET",
			/obj/structure/largecrate = "LARGE_CRATE",
			/obj/structure/low_wall = "LOW_WALL",
			/obj/structure/low_wall/bay = "LOW_BAY_WALL",
			/obj/structure/low_wall/eris = "LOW_ERIS_WALL",
			/obj/structure/hull_corner = "HULL_CORNER",
			/obj/structure/grille = "GRILLE",
			/obj/structure/grille/bay = "GRILLE_BAY",
			/obj/structure/window = "WINDOW",
			/obj/structure/window/bay = "WINDOW_BAY",
			/obj/structure/window/eris = "WINDOW_ERIS",
			/obj/structure/bed = "BED",
			/obj/structure/bed/chair = "CHAIR",
			/obj/structure/bed/chair/sofa = "SOFA",
			/obj/structure/bed/chair/office = "CHAIR_OFFICE",
			/obj/structure/flora = "FLORA",
			/obj/structure/prop = "PROP",

			/obj/machinery = "MACHINERY",
			/obj/machinery/atmospherics = "ATMOS_MECH",
			/obj/machinery/portable_atmospherics = "PORT_ATMOS",
			/obj/machinery/door = "DOOR",
			/obj/machinery/door/airlock = "AIRLOCK",
			//obj/machinery/rnd/production = "RND_FABRICATOR",
			/obj/machinery/computer = "COMPUTER",
			//obj/machinery/computer/camera_advanced/shuttle_docker = "DOCKING_COMPUTER",
			/obj/machinery/vending = "VENDING",
			/obj/machinery/vending/wardrobe = "JOBDROBE",
			/obj/effect = "EFFECT",
			/obj/item/projectile = "PROJECTILE",
		)
		// ignore_root_path so we can draw the root normally
		types_to_replacement = zebra_typecacheof(work_from, ignore_root_path = TRUE)
		replacement_to_text = list()
		for(var/key in work_from)
			replacement_to_text[work_from[key]] = "[key]"

	. = list()
	for(var/type in types)
		var/replace_with = types_to_replacement[type]
		if(!replace_with)
			.["[type]"] = type
			continue
		var/cut_out = replacement_to_text[replace_with]
		// + 1 to account for /
		.[replace_with + copytext("[type]", length(cut_out) + 1)] = type

/proc/get_fancy_list_of_atom_types()
	var/static/list/pre_generated_list
	if (!pre_generated_list) //init
		pre_generated_list = make_types_fancy(typesof(/atom))
	return pre_generated_list


/proc/get_fancy_list_of_datum_types()
	var/static/list/pre_generated_list
	if (!pre_generated_list) //init
		pre_generated_list = make_types_fancy(sortList(typesof(/datum) - typesof(/atom)))
	return pre_generated_list


/proc/filter_fancy_list(list/L, filter as text)
	var/list/matches = new
	var/end_len = -1
	var/list/endcheck = splittext(filter, "!")
	if(endcheck.len > 1)
		filter = endcheck[1]
		end_len = length_char(filter)

	for(var/key in L)
		var/value = L[key]
		if(findtext("[key]", filter, -end_len) || findtext("[value]", filter, -end_len))
			matches[key] = value
	return matches

/proc/return_typenames(type)
	return splittext("[type]", "/")
