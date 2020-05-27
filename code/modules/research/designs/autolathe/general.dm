//////// General Autolathe Designs ////////
/datum/design/autolathe/general
	category = "General"

/datum/design/autolathe/general/bucket
	name = "bucket"
	id = "bucket"
	materials = list(DEFAULT_WALL_MATERIAL = 200)
	build_path = /obj/item/weapon/reagent_containers/glass/bucket

/datum/design/autolathe/general/cooler_bottle
	name = "water-cooler bottle"
	id = "cooler_bottle"
	materials = list(MAT_GLASS = 2000)
	build_path = /obj/item/weapon/reagent_containers/glass/cooler_bottle

// These glasses don't have icon_state on the item definition so we must specify.
/datum/design/autolathe/general/drinkingglass
	research_icon = 'icons/pdrink.dmi'

/datum/design/autolathe/general/drinkingglass/square
	name = "half-pint glass"
	id = "drinkingglass_square"
	materials = list(MAT_GLASS = 60)
	build_path = /obj/item/weapon/reagent_containers/food/drinks/glass2/square
	research_icon_state = "square"

/datum/design/autolathe/general/drinkingglass/rocks
	name = "rocks glass"
	id = "drinkingglass_rocks"
	materials = list(MAT_GLASS = 40)
	build_path = /obj/item/weapon/reagent_containers/food/drinks/glass2/rocks
	research_icon_state = "rocks"

/datum/design/autolathe/general/drinkingglass/shake
	name = "milkshake glass"
	id = "drinkingglass_shake"
	materials = list(MAT_GLASS = 30)
	build_path = /obj/item/weapon/reagent_containers/food/drinks/glass2/shake
	research_icon_state = "shake"

/datum/design/autolathe/general/drinkingglass/cocktail
	name = "cocktail glass"
	id = "drinkingglass_cocktail"
	materials = list(MAT_GLASS = 30)
	build_path = /obj/item/weapon/reagent_containers/food/drinks/glass2/cocktail
	research_icon_state = "cocktail"

/datum/design/autolathe/general/drinkingglass/shot
	name = "shot glass"
	id = "drinkingglass_shot"
	materials = list(MAT_GLASS = 10)
	build_path = /obj/item/weapon/reagent_containers/food/drinks/glass2/shot
	research_icon_state = "shot"

/datum/design/autolathe/general/drinkingglass/pint
	name = "pint glass"
	id = "drinkingglass_pint"
	materials = list(MAT_GLASS = 120)
	build_path = /obj/item/weapon/reagent_containers/food/drinks/glass2/pint
	research_icon_state = "pint"

/datum/design/autolathe/general/drinkingglass/mug
	name = "glass mug"
	id = "drinkingglass_mug"
	materials = list(MAT_GLASS = 80)
	build_path = /obj/item/weapon/reagent_containers/food/drinks/glass2/mug
	research_icon_state = "mug"

/datum/design/autolathe/general/drinkingglass/wine
	name = "wine glass"
	id = "drinkingglass_wine"
	materials = list(MAT_GLASS = 50)
	build_path = /obj/item/weapon/reagent_containers/food/drinks/glass2/wine
	research_icon_state = "wine"

/datum/design/autolathe/general/flashlight
	name = "flashlight"
	id = "flashlight"
	materials = list(DEFAULT_WALL_MATERIAL = 50, MAT_GLASS = 20)
	build_path = /obj/item/device/flashlight

/datum/design/autolathe/general/floor_light
	name = "floor light"
	id = "floor_light"
	materials = list(DEFAULT_WALL_MATERIAL = 2500, MAT_GLASS = 2750)
	build_path = /obj/machinery/floor_light

/datum/design/autolathe/general/extinguisher
	name = "extinguisher"
	id = "extinguisher"
	materials = list(DEFAULT_WALL_MATERIAL = 90)
	build_path = /obj/item/weapon/extinguisher

/datum/design/autolathe/general/jar
	name = "jar"
	id = "jar"
	materials = list(MAT_GLASS = 200)
	build_path = /obj/item/glass_jar

/datum/design/autolathe/general/radio_headset
	name = "radio headset"
	id = "radio_headset"
	materials = list(DEFAULT_WALL_MATERIAL = 75)
	build_path = /obj/item/device/radio/headset

/datum/design/autolathe/general/radio_bounced
	name = "station bounced radio"
	id = "radio_bounced"
	materials = list(DEFAULT_WALL_MATERIAL = 75, MAT_GLASS = 25)
	build_path = /obj/item/device/radio/off

/datum/design/autolathe/general/suit_cooler
	name = "suit cooling unit"
	id = "suit_cooler"
	materials = list(DEFAULT_WALL_MATERIAL = 15000, MAT_GLASS = 3500)
	build_path = /obj/item/device/suit_cooling_unit

/datum/design/autolathe/general/weldermask
	name = "welding mask"
	id = "weldermask"
	materials = list(DEFAULT_WALL_MATERIAL = 3000, MAT_GLASS = 1000)
	build_path = /obj/item/clothing/head/welding

/datum/design/autolathe/general/metal
	name = "steel sheets"
	id = "metal"
	materials = list(DEFAULT_WALL_MATERIAL = 2000)
	build_path = /obj/item/stack/material/steel
	build_multiple = TRUE
	no_scale = TRUE //prevents material duplication exploits

/datum/design/autolathe/general/glass
	name = "glass sheets"
	id = "glass"
	materials = list(MAT_GLASS = 2000)
	build_path = /obj/item/stack/material/glass
	build_multiple = TRUE
	no_scale = TRUE //prevents material duplication exploits

/datum/design/autolathe/general/rglass
	name = "reinforced glass sheets"
	id = "rglass"
	materials = list(DEFAULT_WALL_MATERIAL = 1000, MAT_GLASS = 2000)
	build_path = /obj/item/stack/material/glass/reinforced
	build_multiple = TRUE
	no_scale = TRUE //prevents material duplication exploits

/datum/design/autolathe/general/rods
	name = "metal rods"
	id = "rods"
	materials = list(DEFAULT_WALL_MATERIAL = 1000)
	build_path = /obj/item/stack/rods
	build_multiple = TRUE
	no_scale = TRUE //prevents material duplication exploits

//TFF 24/12/19 - Let people print more spray bottles if needed.
/datum/design/autolathe/general/spraybottle
	name = "spray bottle"
	id = "spraybottle"
	materials = list(DEFAULT_WALL_MATERIAL = 300, MAT_GLASS = 300)
	build_path = /obj/item/weapon/reagent_containers/spray

/datum/design/autolathe/general/knife
	name = "kitchen knife"
	id = "knife"
	materials = list(DEFAULT_WALL_MATERIAL = 300)
	build_path = /obj/item/weapon/material/knife

/datum/design/autolathe/general/taperecorder
	name = "tape recorder"
	id = "taperecorder"
	materials = list(DEFAULT_WALL_MATERIAL = 60, MAT_GLASS = 30)
	build_path = /obj/item/device/taperecorder

/datum/design/autolathe/general/tube
	name = "light tube"
	id = "tube"
	materials = list(MAT_GLASS = 100)
	build_path = /obj/item/weapon/light/tube
	build_multiple = TRUE

/datum/design/autolathe/general/bulb
	name = "light bulb"
	id = "bulb"
	materials = list(MAT_GLASS = 100)
	build_path = /obj/item/weapon/light/bulb
	build_multiple = TRUE

/datum/design/autolathe/general/ashtray_glass
	name = "glass ashtray"
	id = "ashtray_glass"
	materials = list(MAT_GLASS = 200)
	build_path = /obj/item/weapon/material/ashtray/glass

/datum/design/autolathe/general/weldinggoggles
	name = "welding goggles"
	id = "weldinggoggles"
	materials = list(DEFAULT_WALL_MATERIAL = 1500, MAT_GLASS = 1000)
	build_path = /obj/item/clothing/glasses/welding

/datum/design/autolathe/general/maglight
	name = "maglight"
	id = "maglight"
	materials = list(DEFAULT_WALL_MATERIAL = 200, MAT_GLASS = 50)
	build_path = /obj/item/device/flashlight/maglight


/datum/design/autolathe/general/handcuffs
	name = "handcuffs"
	id = "handcuffs"
	materials = list(DEFAULT_WALL_MATERIAL = 500)
	build_path = /obj/item/weapon/handcuffs
	contraband = TRUE

/datum/design/autolathe/general/legcuffs
	name = "legcuffs"
	id = "legcuffs"
	materials = list(DEFAULT_WALL_MATERIAL = 500)
	build_path = /obj/item/weapon/handcuffs/legcuffs
	contraband = TRUE
