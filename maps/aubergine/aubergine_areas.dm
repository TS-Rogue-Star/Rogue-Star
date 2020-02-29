/area
	var/secure = FALSE //Has access
	var/list/req_access = list() //List if you want to define access.

/area/aubergine/surface/cool
	name = "aubergine inner perimeter"
	icon = 'icons/turf/areas_vr.dmi'
	sound_env = MOUNTAINS
	icon_state = "outside1"

/area/aubergine/surface/hot
	name = "aubergine outer perimeter"
	icon = 'icons/turf/areas_vr.dmi'
	sound_env = MOUNTAINS
	icon_state = "outside2"

/area/aubergine/hallway/main
	name = "aubergine main hallway"

/area/aubergine/eng/solarmaint
	name = "aubergine solar maint"

/area/aubergine/eng/storage
	name = "aubergine engineering storage"

/area/aubergine/hallway/qpads
	name = "aubergine transit station"
