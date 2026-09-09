//RS FILE
var/global/list/dungeon_components = list()

/datum/component/dungeon_mechanic
	var/id = "REPLACE ME"
	var/overlay_icon = 'icons/rogue-star/component_adder.dmi'
	var/overlay_state
	var/overlay_color = "#1ae200"
	var/static/list/overlays_cache = list()

/datum/component/dungeon_mechanic/Initialize(var/our_id,var/our_color)
	if(!isobj(parent))
		return COMPONENT_INCOMPATIBLE
	if(our_id)
		id = our_id
	if(our_color)
		overlay_color = our_color
	dungeon_components |= src
	var/obj/O = parent
	RegisterSignal(O, COMSIG_ATOM_UPDATE_ICON , PROC_REF(add_component_overlay))
	add_component_overlay()

/datum/component/dungeon_mechanic/proc/add_component_overlay()
	if(!overlay_state)
		return
	var/key = "[overlay_state]-[overlay_color]"
	var/image/overlay = overlays_cache[key]
	if(!overlay)
		overlay = image(overlay_icon,null,overlay_state)
		overlay.color = overlay_color
		overlay.plane = PLANE_ADMIN_SECRET
		overlay.appearance_flags = RESET_COLOR|KEEP_APART|PIXEL_SCALE
		overlays_cache[key] = overlay
	var/obj/O = parent
	O.add_overlay(overlay)

//LOCK// - It won't work unless you unlock it
/datum/component/dungeon_mechanic/lock
	overlay_state = "lock_s"
	var/locked = TRUE
	var/onetime = FALSE

/datum/component/dungeon_mechanic/lock/Initialize(var/our_id)
	. = ..()
	var/obj/O = parent
	O.dungeon_lock()

/datum/component/dungeon_mechanic/lock/proc/toggle_lock(var/obj/O)
	locked = !locked
	if(locked)
		O.dungeon_lock()
	else
		O.dungeon_unlock()

//KEY// - The thing that asks locks to unlock
/datum/component/dungeon_mechanic/key
	overlay_state = "key_s"
	var/onetime = FALSE
	var/master_key = FALSE

/datum/component/dungeon_mechanic/key/Initialize(our_id, our_color)
	. = ..()
	RegisterSignal(parent, COMSIG_RESOLVE_ATTACKBY , PROC_REF(lock_interact))

/datum/component/dungeon_mechanic/key/proc/lock_interact()
	var/obj/O = args[2]
	if(!isobj(O))
		return
	var/mob/living/user = args[3]
	var/datum/component/dungeon_mechanic/lock/L = O.getlock()
	if(!L)
		return

	if(id == L.id || master_key)
		if(!L.locked && onetime)
			to_chat(user,SPAN_NOTICE("\The [O] is already unlocked! You don't need to use \the [parent] on it."))
			return
		if(user)
			user.visible_message(SPAN_NOTICE("\The [user] inserts \the [parent] into \the [O]..."),SPAN_NOTICE("You insert \the [parent] into \the [O]..."))
		unlocked(user)
		L.toggle_lock(O)

	else if(user)
		to_chat(user,SPAN_DANGER("\The [parent] doesn't fit into \the [O]..."))

/datum/component/dungeon_mechanic/key/proc/unlocked(var/mob/user)
	if(onetime)
		if(user)
			to_chat(user,SPAN_DANGER("\The [parent] crumbles away to dust after being used."))
			user.drop_from_inventory(parent,get_turf(user))
		qdel(parent)

//RECIEVER// - The thing that gets told what to do
/datum/component/dungeon_mechanic/reciever
	overlay_state = "reciever_s"

/datum/component/dungeon_mechanic/reciever/Initialize(var/our_id)
	. = ..()
	for(var/datum/component/dungeon_mechanic/trigger/T in dungeon_components)
		if(T == src)
			continue
		if(!istype(T,/datum/component/dungeon_mechanic/trigger))
			continue
		if(T.id == id)
			RegisterSignal(T,COMSIG_DUNGEON_TRIGGER,PROC_REF(link_trigger))
			RegisterSignal(T,COMSIG_DUNGEON_UNTRIGGER,PROC_REF(link_trigger))

/datum/component/dungeon_mechanic/reciever/Destroy(force, silent)
	dungeon_components -= src
	for(var/datum/component/dungeon_mechanic/trigger/T in dungeon_components)
		if(id == T.id)
			UnregisterSignal(T,COMSIG_DUNGEON_TRIGGER)
			UnregisterSignal(T,COMSIG_DUNGEON_UNTRIGGER)
	return ..()

/datum/component/dungeon_mechanic/reciever/proc/link_trigger()
	var/obj/O = parent
	O.dungeon_trigger()

//TRIGGER// - The thing that tells other things to do things
/datum/component/dungeon_mechanic/trigger
	overlay_state = "trigger_s"
	var/triggered = FALSE	//Are we triggered or untriggered
	var/onetime = FALSE		//If true we can only be triggered, once triggered, we can not be untriggered
	var/solo = TRUE			//If FALSE will require ALL of the triggers with the same ID to be triggered before it will send the trigger signal
	var/key_lock = FALSE	//If TRUE (and solo is FALSE) requires unique ckeys to hit each trigger
	var/triggered_by		//A recording of who triggered the trigger (only relevent if key_lock is TRUE)
	var/last_triggered = 0

/datum/component/dungeon_mechanic/trigger/Initialize(our_id)
	. = ..()
	RegisterSignal(parent, COMSIG_DUNGEON_TRIGGER , PROC_REF(toggle_trigger))
	RegisterSignal(parent, COMSIG_DUNGEON_UNTRIGGER , PROC_REF(toggle_trigger))

/datum/component/dungeon_mechanic/trigger/Destroy(force, silent)
	dungeon_components -= src
	UnregisterSignal(parent, COMSIG_DUNGEON_TRIGGER)
	UnregisterSignal(parent, COMSIG_DUNGEON_UNTRIGGER)

	for(var/datum/component/dungeon_mechanic/reciever/L in dungeon_components)
		if(id == L.id)
			L.UnregisterSignal(src,COMSIG_DUNGEON_TRIGGER)
	return ..()

/datum/component/dungeon_mechanic/trigger/proc/toggle_trigger()
	if(last_triggered + 2 > world.time)
		return
	var/mob/user
	if(args.len >= 2)
		user = args[2]

	if(!triggered)
		trigger(user)
	else
		untrigger()

/datum/component/dungeon_mechanic/trigger/proc/should_key_trigger(var/key)
	if(!key_lock)
		return TRUE

	for(var/datum/component/dungeon_mechanic/trigger/T in dungeon_components)
		if(T.id != id)
			continue
		if(!T.triggered_by)
			continue
		if(T.triggered_by == key)
			return FALSE

	return TRUE

/datum/component/dungeon_mechanic/trigger/proc/trigger(var/mob/user)
	last_triggered = world.time
	var/signal = TRUE
	if(!solo)
		for(var/datum/component/dungeon_mechanic/trigger/T in dungeon_components)
			if(T == src)
				continue
			if(T.id != id)
				continue
			if(key_lock)	//If key_lock is true then we need unique ckeys for each trigger.
				if(!user)
					return
				if(!user.ckey)
					return
				if(T.triggered_by == user.ckey)
					to_chat(user,SPAN_WARNING("\The [parent] very unsatisfyingly does nothing when you interact with it. Perhaps someone else needs to interact with this one."))
					return
			if(!T.triggered)
				signal = FALSE

	if(user?.ckey)
		triggered_by = user.ckey

	triggered = TRUE
	var/obj/P = parent
	P.dungeon_trigger()
	if(signal)
		SEND_SIGNAL(src,COMSIG_DUNGEON_TRIGGER)
	var/turf/T = get_turf(parent)
	T.visible_message("\The [parent] clicks audibly as it is triggered...",runemessage = "click...")

/datum/component/dungeon_mechanic/trigger/proc/untrigger()
	if(onetime)
		return
	last_triggered = world.time
	SEND_SIGNAL(src,COMSIG_DUNGEON_UNTRIGGER)
	triggered = FALSE
	triggered_by = null

	var/obj/P = parent
	P.dungeon_untrigger()

	var/turf/T = get_turf(parent)
	T.visible_message("\The [parent] clunks audibly as it is untriggered...",runemessage = "clunk...")

//PAIR// - So things can know about eachother, such as teleporters
/datum/component/dungeon_mechanic/pair
	overlay_state = "pair_s"
	var/list/partner = list()

/datum/component/dungeon_mechanic/pair/Initialize(our_id)
	. = ..()
	pair_with_partners()

/datum/component/dungeon_mechanic/pair/proc/pair_with_partners()
	var/paired = FALSE
	for(var/datum/component/dungeon_mechanic/pair/P in dungeon_components)
		if(P.type != type)
			continue
		if(P == src)
			continue
		if(id == P.id)
			partner |= P
			P.partner |= src
			var/obj/O = P.parent
			O.dungeon_pair()
	if(paired)
		var/obj/ourparent = parent
		ourparent.dungeon_pair()

/datum/component/dungeon_mechanic/pair/proc/unpair_with_partners()
	for(var/datum/component/dungeon_mechanic/pair/P in partner)
		P.partner -= src
		partner -= P

//////////RELATED OBJ PROCS//////////
/obj/proc/dungeon_trigger(var/mob/user)	//This is the main trigger action, if you want something that always does the same thing, use this, all the other procs default to this
	return FALSE
/obj/proc/dungeon_untrigger(var/mob/user)	//If you need a specific untrigger action
	dungeon_trigger(user)

/obj/proc/dungeon_lock(var/mob/user)	//If you need a specific lock action
	dungeon_trigger(user)

/obj/proc/dungeon_unlock(var/mob/user)	//If you need a specific unlock action
	dungeon_trigger(user)

/obj/proc/dungeon_pair()
	if(islocked())
		return FALSE
	if(getreciever())
		return FALSE
	return TRUE

/obj/proc/getlock()
	return GetComponent(/datum/component/dungeon_mechanic/lock)

/obj/proc/islocked()
	var/datum/component/dungeon_mechanic/lock/ourlock = GetComponent(/datum/component/dungeon_mechanic/lock)
	if(ourlock?.locked)
		return TRUE
	return FALSE

/obj/proc/cantrigger(var/mob/user)
	var/datum/component/dungeon_mechanic/trigger/trigger = GetComponent(/datum/component/dungeon_mechanic/trigger)
	if(!trigger)
		return FALSE
	if(trigger.onetime && trigger.triggered)
		return FALSE
	if(trigger.last_triggered + 2 > world.time)
		return FALSE
	if(trigger.key_lock)
		if(!user.ckey)
			return FALSE
		return trigger.should_key_trigger(user.ckey)

	return TRUE

/obj/proc/istriggered()
	var/datum/component/dungeon_mechanic/trigger/trigger = GetComponent(/datum/component/dungeon_mechanic/trigger)
	if(!trigger)
		return FALSE
	return trigger.triggered

/obj/proc/get_dungeon_pair()
	var/datum/component/dungeon_mechanic/pair/P = GetComponent(/datum/component/dungeon_mechanic/pair)
	if(!P)
		return FALSE
	if(P.partner)
		if(P.partner.len <= 0)
			return FALSE
	return P.partner

/obj/proc/getkey()
	var/datum/component/dungeon_mechanic/key/K = GetComponent(/datum/component/dungeon_mechanic/key)
	if(!K)
		return FALSE
	return K

/obj/proc/getreciever()
	var/datum/component/dungeon_mechanic/reciever/R = GetComponent(/datum/component/dungeon_mechanic/reciever)
	if(!R)
		return FALSE
	return R
