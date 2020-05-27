//////// Tools Autolathe Designs ////////
/datum/design/autolathe/tools
	category = "Tools"


/datum/design/autolathe/tools/crowbar
	name = "crowbar"
	id = "crowbar"
	materials = list(DEFAULT_WALL_MATERIAL = 50)
	build_path = /obj/item/weapon/tool/crowbar

/datum/design/autolathe/tools/multitool
	name = "multitool"
	id = "multitool"
	materials = list(DEFAULT_WALL_MATERIAL = 50, MAT_GLASS = 20)
	build_path = /obj/item/device/multitool

/datum/design/autolathe/tools/t_scanner
	name = "T-ray scanner"
	id = "t_scanner"
	materials = list(DEFAULT_WALL_MATERIAL = 150)
	build_path = /obj/item/device/t_scanner

/datum/design/autolathe/tools/weldertool
	name = "welding tool"
	id = "weldertool"
	materials = list(DEFAULT_WALL_MATERIAL = 70, MAT_GLASS = 30)
	build_path = /obj/item/weapon/weldingtool

/datum/design/autolathe/tools/electric_welder
	name = "electric welding tool"
	id = "electric_welder"
	materials = list(DEFAULT_WALL_MATERIAL = 70, MAT_GLASS = 30)
	build_path = /obj/item/weapon/weldingtool/electric/unloaded
	contraband = TRUE

/datum/design/autolathe/tools/screwdriver
	name = "screwdriver"
	id = "screwdriver"
	materials = list(DEFAULT_WALL_MATERIAL = 75)
	build_path = /obj/item/weapon/tool/screwdriver

/datum/design/autolathe/tools/wirecutters
	name = "wirecutters"
	id = "wirecutters"
	materials = list(DEFAULT_WALL_MATERIAL = 80)
	build_path = /obj/item/weapon/tool/wirecutters

/datum/design/autolathe/tools/wrench
	name = "wrench"
	id = "wrench"
	materials = list(DEFAULT_WALL_MATERIAL = 150)
	build_path = /obj/item/weapon/tool/wrench

/datum/design/autolathe/tools/hatchet
	name = "hatchet"
	id = "hatchet"
	materials = list(DEFAULT_WALL_MATERIAL = 400)
	build_path = /obj/item/weapon/material/knife/machete/hatchet

/datum/design/autolathe/tools/minihoe
	name = "mini hoe"
	id = "minihoe"
	materials = list(DEFAULT_WALL_MATERIAL = 500)
	build_path = /obj/item/weapon/material/minihoe

/datum/design/autolathe/tools/welder_industrial
	name = "industrial welding tool"
	id = "welder_industrial"
	materials = list(DEFAULT_WALL_MATERIAL = 70, MAT_GLASS = 60)
	build_path = /obj/item/weapon/weldingtool/largetank
