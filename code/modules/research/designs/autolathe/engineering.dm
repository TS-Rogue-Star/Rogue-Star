//////// Engineering Autolathe Designs ////////
/datum/design/autolathe/engineering
	category = "Engineering"


/datum/design/autolathe/engineering/airlockmodule
	name = "airlock electronics"
	id = "airlockmodule"
	materials = list(DEFAULT_WALL_MATERIAL = 50, MAT_GLASS = 50)
	build_path = /obj/item/weapon/airlock_electronics

/datum/design/autolathe/engineering/airalarm
	name = "air alarm electronics"
	id = "airalarm"
	materials = list(DEFAULT_WALL_MATERIAL = 50, MAT_GLASS = 50)
	build_path = /obj/item/weapon/circuitboard/airalarm

/datum/design/autolathe/engineering/firealarm
	name = "fire alarm electronics"
	id = "firealarm"
	materials = list(DEFAULT_WALL_MATERIAL = 50, MAT_GLASS = 50)
	build_path = /obj/item/weapon/circuitboard/firealarm

/datum/design/autolathe/engineering/powermodule
	name = "power control module"
	id = "powermodule"
	materials = list(DEFAULT_WALL_MATERIAL = 50, MAT_GLASS = 50)
	build_path = /obj/item/weapon/module/power_control

/datum/design/autolathe/engineering/statusdisplay
	name = "status display electronics"
	id = "statusdisplay"
	materials = list(DEFAULT_WALL_MATERIAL = 50, MAT_GLASS = 50)
	build_path = /obj/item/weapon/circuitboard/status_display

/datum/design/autolathe/engineering/aistatusdisplay
	name = "ai status display electronics"
	id = "aistatusdisplay"
	materials = list(DEFAULT_WALL_MATERIAL = 50, MAT_GLASS = 50)
	build_path = /obj/item/weapon/circuitboard/ai_status_display

/datum/design/autolathe/engineering/newscaster
	name = "newscaster electronics"
	id = "newscaster"
	materials = list(DEFAULT_WALL_MATERIAL = 50, MAT_GLASS = 50)
	build_path = /obj/item/weapon/circuitboard/newscaster

/datum/design/autolathe/engineering/atm
	name = "atm electronics"
	id = "atm"
	materials = list(DEFAULT_WALL_MATERIAL = 50, MAT_GLASS = 50)
	build_path = /obj/item/weapon/circuitboard/atm

/datum/design/autolathe/engineering/intercom
	name = "intercom electronics"
	id = "intercom"
	materials = list(DEFAULT_WALL_MATERIAL = 50, MAT_GLASS = 50)
	build_path = /obj/item/weapon/circuitboard/intercom

/datum/design/autolathe/engineering/holopad
	name = "holopad electronics"
	id = "holopad"
	materials = list(DEFAULT_WALL_MATERIAL = 50, MAT_GLASS = 50)
	build_path = /obj/item/weapon/circuitboard/holopad

/datum/design/autolathe/engineering/guestpass
	name = "guestpass console electronics"
	id = "guestpass"
	materials = list(DEFAULT_WALL_MATERIAL = 50, MAT_GLASS = 50)
	build_path = /obj/item/weapon/circuitboard/guestpass

/datum/design/autolathe/engineering/entertainment
	name = "entertainment camera electronics"
	id = "entertainment"
	materials = list(DEFAULT_WALL_MATERIAL = 50, MAT_GLASS = 50)
	build_path = /obj/item/weapon/circuitboard/security/telescreen/entertainment

/datum/design/autolathe/engineering/keycard
	name = "keycard authenticator electronics"
	id = "keycard"
	materials = list(DEFAULT_WALL_MATERIAL = 50, MAT_GLASS = 50)
	build_path = /obj/item/weapon/circuitboard/keycard_auth

/datum/design/autolathe/engineering/photocopier
	name = "photocopier electronics"
	id = "photocopier"
	materials = list(DEFAULT_WALL_MATERIAL = 50, MAT_GLASS = 50)
	build_path = /obj/item/weapon/circuitboard/photocopier

/datum/design/autolathe/engineering/fax
	name = "fax machine electronics"
	id = "fax"
	materials = list(DEFAULT_WALL_MATERIAL = 50, MAT_GLASS = 50)
	build_path = /obj/item/weapon/circuitboard/fax

/datum/design/autolathe/engineering/papershredder
	name = "paper shredder electronics"
	id = "papershredder"
	materials = list(DEFAULT_WALL_MATERIAL = 50, MAT_GLASS = 50)
	build_path = /obj/item/weapon/circuitboard/papershredder

/datum/design/autolathe/engineering/microwave
	name = "microwave electronics"
	id = "microwave"
	materials = list(DEFAULT_WALL_MATERIAL = 50, MAT_GLASS = 50)
	build_path = /obj/item/weapon/circuitboard/microwave

/datum/design/autolathe/engineering/washing
	name = "washing machine electronics"
	id = "washing"
	materials = list(DEFAULT_WALL_MATERIAL = 50, MAT_GLASS = 50)
	build_path = /obj/item/weapon/circuitboard/washing

/datum/design/autolathe/engineering/request
	name = "request console electronics"
	id = "request"
	materials = list(DEFAULT_WALL_MATERIAL = 50, MAT_GLASS = 50)
	build_path = /obj/item/weapon/circuitboard/request

/datum/design/autolathe/engineering/pipelayer
	name = "pipe layer electronics"
	id = "pipelayer"
	materials = list(DEFAULT_WALL_MATERIAL = 50, MAT_GLASS = 50)
	build_path = /obj/item/weapon/circuitboard/pipelayer

/datum/design/autolathe/engineering/motor
	name = "motor"
	id = "motor"
	materials = list(DEFAULT_WALL_MATERIAL = 60, MAT_GLASS = 10)
	build_path = /obj/item/weapon/stock_parts/motor

/datum/design/autolathe/engineering/gear
	name = "gear"
	id = "gear"
	materials = list(DEFAULT_WALL_MATERIAL = 50)
	build_path = /obj/item/weapon/stock_parts/gear

/datum/design/autolathe/engineering/spring
	name = "spring"
	id = "spring"
	materials = list(DEFAULT_WALL_MATERIAL = 40)
	build_path = /obj/item/weapon/stock_parts/spring

/datum/design/autolathe/engineering/rcd_ammo
	name = "matter cartridge"
	id = "rcd_ammo"
	materials = list(DEFAULT_WALL_MATERIAL = 30000, MAT_GLASS = 15000)
	build_path = /obj/item/weapon/rcd_ammo
	no_scale = TRUE //prevents material duplication exploits

/datum/design/autolathe/engineering/rcd
	name = "rapid construction device"
	id = "rcd"
	materials = list(DEFAULT_WALL_MATERIAL = 50000)
	build_path = /obj/item/weapon/rcd

/datum/design/autolathe/engineering/camera_assembly
	name = "camera assembly"
	id = "camera_assembly"
	materials = list(DEFAULT_WALL_MATERIAL = 700, MAT_GLASS = 300)
	build_path = /obj/item/weapon/camera_assembly
