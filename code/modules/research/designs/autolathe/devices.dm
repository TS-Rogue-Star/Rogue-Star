//////// Devices and Components Autolathe Designs ////////
/datum/design/autolathe/devices
	category = "Devices and Components"


/datum/design/autolathe/devices/consolescreen
	name = "console screen"
	id = "consolescreen"
	materials = list(MAT_GLASS = 200)
	build_path = /obj/item/weapon/stock_parts/console_screen

/datum/design/autolathe/devices/igniter
	name = "igniter"
	id = "igniter"
	materials = list(DEFAULT_WALL_MATERIAL = 500, MAT_GLASS = 50)
	build_path = /obj/item/device/assembly/igniter

/datum/design/autolathe/devices/signaler
	name = "signaler"
	id = "signaler"
	materials = list(DEFAULT_WALL_MATERIAL = 1000, MAT_GLASS = 200)
	build_path = /obj/item/device/assembly/signaler

/datum/design/autolathe/devices/sensor_infra
	name = "infrared sensor"
	id = "sensor_infra"
	materials = list(DEFAULT_WALL_MATERIAL = 1000, MAT_GLASS = 500)
	build_path = /obj/item/device/assembly/infra

/datum/design/autolathe/devices/timer
	name = "timer"
	id = "timer"
	materials = list(DEFAULT_WALL_MATERIAL = 500, MAT_GLASS = 50)
	build_path = /obj/item/device/assembly/timer

/datum/design/autolathe/devices/sensor_prox
	name = "proximity sensor"
	id = "sensor_prox"
	materials = list(DEFAULT_WALL_MATERIAL = 800, MAT_GLASS = 200)
	build_path = /obj/item/device/assembly/prox_sensor

/datum/design/autolathe/devices/beartrap
	name = "mechanical trap"
	id = "beartrap"
	materials = list(DEFAULT_WALL_MATERIAL = 18750)
	build_path = /obj/item/weapon/beartrap

/datum/design/autolathe/devices/electropack
	name = "electropack"
	id = "electropack"
	materials = list(DEFAULT_WALL_MATERIAL = 10000, MAT_GLASS = 2500)
	build_path = /obj/item/device/radio/electropack
	contraband = TRUE
