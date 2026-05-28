//RS FILE
/obj/component_adder	//This base type doesn't do anything!
	name = "component adder"
	desc = "You shouldn't see this."
	icon = 'icons/rogue-star/component_adder.dmi'
	icon_state = "adder"
	plane = PLANE_ADMIN_SECRET
	color = "#1ae200"
	var/component_type
	var/id = "REPLACE ME"
	var/list/valid_types = list()
	var/late = FALSE

/obj/component_adder/New(loc, new_id)
	. = ..()
	if(new_id)
		id = new_id

/obj/component_adder/Initialize(mapload)
	. = ..()
	if(late)
		return INITIALIZE_HINT_LATELOAD
	seek_valid_target()
	qdel(src)

/obj/component_adder/LateInitialize()
	seek_valid_target()
	qdel(src)

/obj/component_adder/proc/seek_valid_target()
	if(!component_type)
		return
	var/turf/T = get_turf(src)
	for(var/atom/thing in T.contents)
		if(thing == src)
			continue
		for(var/type_check in valid_types)
			if(istype(thing,type_check))
				if(!special_check(thing))
					add_component(thing)

/obj/component_adder/proc/add_component(var/atom/target)
	if(!target)
		return
	. = target.LoadComponent(component_type,id,color)

/obj/component_adder/proc/consider_overlay_state(var/atom/consider)
	return null

/obj/component_adder/proc/special_check(var/atom/consider)
	return FALSE

/obj/component_adder/lock
	name = "lock component"
	icon_state = "lock"
	component_type = /datum/component/dungeon_mechanic/lock
	valid_types = list(
		/obj/machinery/door/airlock,
		/obj/structure/simple_door,
		/obj/dungeon_obstacle,
		/obj/machinery/door/blast,
		/obj/dungeon_switch,
		/obj/multipoint/teleporter,
		/obj/structure/closet,
		/obj/structure/portal_event
	)
	var/onetime = FALSE

/obj/component_adder/lock/add_component(atom/target)
	var/datum/component/dungeon_mechanic/lock/L = ..()
	L.onetime = onetime

/obj/component_adder/key
	name = "key component"
	icon_state = "key"
	component_type = /datum/component/dungeon_mechanic/key
	valid_types = list(
		/obj/item/key,
		/obj/item/weapon/card
	)
	var/onetime = FALSE
	var/master = FALSE

/obj/component_adder/key/add_component(atom/target)
	var/datum/component/dungeon_mechanic/key/K = ..()
	K.onetime = onetime
	K.master_key = master

/obj/component_adder/key/onetime
	onetime = TRUE
/obj/component_adder/key/master
	master = TRUE
/obj/component_adder/key/onetime_master
	onetime = TRUE
	master = TRUE

/obj/component_adder/trigger
	name = "trigger component"
	icon_state = "trigger"
	component_type = /datum/component/dungeon_mechanic/trigger
	valid_types = list(
		/obj/dungeon_obstacle,
		/obj/dungeon_switch,
		/obj/machinery/door/airlock,
		/obj/structure/simple_door,
		/obj/machinery/door/blast,
		/obj/multipoint_trigger,
		/obj/listener
	)
	var/onetime = FALSE
	var/solo = TRUE
	var/key_lock = FALSE

/obj/component_adder/trigger/onetime
	onetime = TRUE
/obj/component_adder/trigger/non_solo
	solo = FALSE
/obj/component_adder/trigger/puzzle
	onetime = TRUE
	solo = FALSE
/obj/component_adder/trigger/gather_gate
	onetime = TRUE
	solo = FALSE
	key_lock = TRUE

/obj/component_adder/trigger/add_component()
	var/datum/component/dungeon_mechanic/trigger/T = ..()
	T.onetime = onetime
	T.solo = solo
	T.key_lock = key_lock

/obj/component_adder/reciever
	name = "reciever component"
	icon_state = "reciever"
	component_type = /datum/component/dungeon_mechanic/reciever
	valid_types = list(
		/obj/machinery/door/airlock,
		/obj/structure/simple_door,
		/obj/dungeon_obstacle,
		/obj/machinery/door/blast,
		/obj/dungeon_switch,
		/obj/multipoint/teleporter,
		/obj/multipoint/barrier,
		/obj/structure/portal_event
	)
	late = TRUE

/obj/component_adder/pair
	name = "pair component"
	icon_state = "pair"
	component_type = /datum/component/dungeon_mechanic/pair
	valid_types = list(
		/obj/multipoint/teleporter,
		/obj/structure/portal_event
	)
	late = TRUE
