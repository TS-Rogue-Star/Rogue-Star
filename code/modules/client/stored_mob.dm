// RS File

//Let's go wild let's go stupid
//My code is an atrocity, may it stand as a testement for all who gaze my way, look and be afraid

///////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star September 2026: Pet Register Interface //
///////////////////////////////////////////////////////////////////////////

/obj/machinery/mob_bank
	name = "\improper PET System"
	desc = "It's the petatronic energy transport system! It's a machine that can scan and retrieve your pets!"
	icon = 'icons/rogue-star/machinex32.dmi'
	icon_state = "mob_bank"
	idle_power_usage = 1
	active_power_usage = 5
	anchored = TRUE
	density = FALSE
	pixel_y = 20	// Push it up on the north wall baby
	var/busy_bank = FALSE
	var/static/list/mob_takers = list()
	var/static/list/mob_savers = list()

/obj/machinery/mob_bank/examine(mob/user, infix, suffix)
	. = ..()
	. += SPAN_NOTICE("The pet system allows one to save and store pets to be retrieved on future shifts. Only one pet may be out at a time, to retrieve other pets, one must store their pet first.")
	. += SPAN_NOTICE("To save a pet or store a pet, click and drag the pet onto \the [src]. Only your registered pets may be stored.")
	. += SPAN_NOTICE("Only one pet may be saved per shift normally.")
	. += SPAN_WARNING("There are some restrictions about which creatures may be saved as pets. Things like crew members or similarly complicated creatures, otherwise sapient (player controlled) creatures, and hostile entities will not be allowed to be saved. Some creatures may have special conditions before they can be saved, while others may simply be unable to be saved.")
	. += span_green("Pet storage can be expanded with ◬. Place your ◬ into an electronic lockbox, and \the [src] will be able to withdraw it from your account.")

/obj/machinery/mob_bank/attack_hand(mob/living/user)
	. = ..()
	if(!ishuman(user))
		return
	if(istype(user) && Adjacent(user))
		if(inoperable() || panel_open)
			to_chat(user, "<span class='warning'>\The [src] seems to be nonfunctional...</span>")
		else
			start_using(user)

/obj/machinery/mob_bank/update_icon()
	if(busy_bank)
		icon_state = "mob_bank_a"
	else
		icon_state = "mob_bank"
		..()

/obj/machinery/mob_bank/proc/start_using(mob/living/user)
	if(can_use_pet_register(user, TRUE))
		tgui_interact(user)

/obj/machinery/mob_bank/proc/persist_mob_savefile_path(mob/user)
	return "data/player_saves/[copytext(user.ckey, 1, 2)]/[user.ckey]/pet/slot[user.client.prefs.default_slot].json"

/obj/machinery/mob_bank/proc/persist_mob_save(mob/living/user, mob/living/simple_mob/ourmob, pet_name, destination, replacement)
	if(!can_use_pet_register(user) || !pet_candidate_valid(user, ourmob))
		return FALSE
	if(destination == "store")
		if(!is_registered_pet(user, ourmob))
			return FALSE
		if(!user.etching.pet_save(ourmob, ourmob.registered_pet_name))	//Save mob to character etching
			return FALSE
		var/list/verbs = list("ingests", "slurps", "gobbles", "gulps", "gathers", "snarfs", "guzzles", "glorps", "devours", "inserts")
		visible_message(span_green("\The [src] [pick(verbs)] \the [ourmob] into its petatronic storage matrix!"), runemessage = "burps. . .")
		if(ourmob.registered_pet_name == user.etching.loaded_pet)
			user.etching.loaded_pet = null
		qdel(ourmob)
		mob_takers -= user.ckey
		return TRUE
	if(user.ckey in mob_savers)
		return FALSE
	if(!pet_register_name_valid(pet_name))
		return FALSE
	if(destination == "station")
		if(ourmob.load_owner)
			return FALSE
		var/list/record = ourmob.mob_bank_save(user, TRUE)
		if(!islist(record) || !record.len)
			return FALSE
		record["name"] = pet_name
		record["ckey"] = user.ckey
		record["type"] = "[ourmob.type]"
		SSpersistence.stored_pets |= list(record)
		ourmob.name = pet_name
		ourmob.real_name = pet_name
		ourmob.load_owner = "STATION"
		mob_savers |= user.ckey
		log_admin("[user.ckey] saved [ourmob] - [ourmob.type] to the station pet pool.")
		return TRUE
	if(destination != "personal" || (user.ckey in mob_takers) || user.etching.loaded_pet)
		return FALSE
	if(!user.etching.pet_save(ourmob, pet_name, replacement))	//Save mob to character etching
		return FALSE
	user.etching.loaded_pet = pet_name
	ourmob.registered_pet_name = pet_name
	ourmob.name = pet_name
	ourmob.real_name = pet_name
	ourmob.load_owner = user.ckey
	ourmob.faction = user.faction
	ourmob.hunter = FALSE
	ourmob.verbs |= /mob/living/simple_mob/proc/toggle_ghostjoin
	ourmob.verbs |= /mob/living/simple_mob/proc/toggle_follow
	user.verbs |= /mob/living/proc/toggle_pet_swap
	LAZYCLEARLIST(user.client.multichar_list)
	if(!user.client.multichar_list)
		user.client.multichar_list = list()
	user.client.multichar_list |= ourmob
	user.client.multichar_list |= user
	user.client.multichar_last = ourmob
	ourmob.verbs |= /mob/living/proc/toggle_pet_swap
	if(ourmob.ai_holder?.hostile)
		ourmob.verbs |= /mob/living/simple_mob/proc/toggle_hostile
		ourmob.ai_holder.hostile = FALSE
		ourmob.ai_holder.vore_hostile = FALSE
	mob_takers |= user.ckey
	mob_savers |= user.ckey
	log_admin("[user.ckey] saved [ourmob] - [ourmob.type] to their personal file.")
	return TRUE

/obj/machinery/mob_bank/proc/persist_mob_load(mob/living/user, pet_name)
	if(!can_use_pet_register(user) || (user.ckey in mob_takers) || user.etching.loaded_pet)
		return FALSE
	var/mob/living/simple_mob/M = user.etching.pet_load(get_turf(src), pet_name)
	if(!M)
		return FALSE
	to_chat(user,"<span class = 'notice'>\The [M] appears from \the [src]!</span>")
	log_admin("[key_name_admin(user)] retrieved [M] || [M.type] from the mob bank.")
	mob_takers |= user.ckey
	return M

/obj/machinery/mob_bank/proc/read_legacy_pet(mob/living/user, datum/pet_register_session/session)
	if(session)
		session.legacy_slot_mismatch = FALSE
		session.legacy_load_failed = FALSE
	if(!user?.client || !user.etching)
		return null
	if(user.real_name != user.client.prefs.real_name)	//Legacy pets were saved using the character slot, so we care when trying to check for backwards compatibility
		if(session)
			session.legacy_slot_mismatch = TRUE
		return null
	//Backwards compatibility
	var/path = persist_mob_savefile_path(user)
	if(!fexists(path))
		return null
	var/list/record
	try
		record = json_decode(file2text(path))
	catch(var/exception/error)
		if(session)
			session.legacy_load_failed = TRUE
		log_runtime(error, src, "Could not read legacy pet record: [path]")
		return null
	if(!islist(record) || !pet_register_name_valid(record["name"]) || !pet_register_type(record["type"]))
		if(session)
			session.legacy_load_failed = TRUE
		log_error("Invalid legacy pet record: [path]")
		return null
	return record

/obj/machinery/mob_bank/MouseDrop_T(mob/living/M, mob/living/user)
	. = ..()
	offer_pet_candidate(user, M)

/obj/machinery/mob_bank/proc/begin_use(var/howmany)
	if(howmany)
		busy_bank = howmany
	START_PROCESSING(SSobj, src)
	update_icon()

/obj/machinery/mob_bank/process()
	busy_bank --
	if(busy_bank <= 0)
		stop_use()

/obj/machinery/mob_bank/proc/stop_use()
	STOP_PROCESSING(SSobj, src)
	busy_bank = 0
	update_icon()

//Only simple mobs, please don't be insane
/mob/living/simple_mob
	var/load_owner = null
	var/registered_pet_name
	var/registered_pet_type

/mob/living/simple_mob/proc/mob_bank_save(mob/living/user, var/for_station = FALSE)
	. = list()
	if(for_station)
		.["ckey"] = user.ckey
	.["type"] = "[type]"
	if(for_station)
		.["name"] = name

	return .

/mob/living/simple_mob/proc/save_conditions(mob/living/user)
	if(load_owner == "STATION")
		to_chat(user, "<span class = 'warning'>\The [src] is registered as a station pet, and as such can not be registered again.</span>")
		return FALSE
	if(initial(load_owner) == "seriouslydontsavethis")
		to_chat(user,"<span class = 'warning'>\The [src] is too complicated to be able to be registered.</span>")
		return FALSE
	if(load_owner && load_owner != user.ckey)
		to_chat(user,"<span class = 'warning'>\The [src] is already registered, it already has a owner.</span>")
		return FALSE
	if(!isanimal(src))
		to_chat(user,"<span class = 'warning'>\The [src] isn't able to be registered... Like. The machine COULD register \the [src] as a pet, but that wouldn't be very ethical. The machine gives you a disapproving boop, and a judgemental glimmer from its scanner...</span>")
		return FALSE
	if(client || ckey)	//It's a player, don't save it
		to_chat(user,"<span class = 'warning'>\The [src] isn't able to be registered.</span>")
		return FALSE
	if(!ai_holder)	//It doesn't have an AI, something weird is going on, don't save it
		to_chat(user,"<span class = 'warning'>\The [src] isn't able to be registered.</span>")
		return FALSE
	if(ai_holder.hostile && faction != user.faction)	//It's hostile to the person trying to save it, don't save it
		to_chat(user,"<span class = 'warning'>\The [src] is too unruly to be registered.</span>")
		return FALSE
	if(!capture_crystal)	//If it isn't catchable with capture crystals, it probably shouldn't be saved with the storage system.
		to_chat(user,"<span class = 'warning'>\The [src] isn't able to be registered.</span>")
		return FALSE
	if(!(ai_holder.stance == STANCE_SLEEP || ai_holder.stance == STANCE_IDLE || ai_holder.stance == STANCE_FOLLOW))	//The AI is trying to do stuff, don't save it
		to_chat(user,"<span class = 'warning'>\The [src] is too unruly to be registered.</span>")
		return FALSE
	if(stat != CONSCIOUS)
		to_chat(user,"<span class = 'warning'>\The [src] is not in a condition to be scanned.</span>")
		return FALSE
	return TRUE

/mob/living/simple_mob/proc/mob_bank_load(mob/living/user, var/list/load)
	if(!user)
		load_owner = "STATION"
		name = load["name"]
		real_name = name
	else
		load_owner = user.ckey

/mob/living/simple_mob/proc/toggle_ghostjoin()
	set name = "Toggle Ghost Join"
	set category = "OOC"
	set src in view(1)

	if(!isliving(usr))
		return

	if(usr.ckey != load_owner)
		to_chat(usr, "<span class = 'warning'>This isn't your pet, you can't do that!</span>")
		return
	if(ckey)
		to_chat(usr, "<span class = 'warning'>Someone is already controlling \the [src].</span>")
		return
	ghostjoin = !ghostjoin
	to_chat(usr, "<span class = 'notice'>\The [src]'s now [ghostjoin ? "able" : "unable"] to be controlled by ghosts.</span>")
	ghostjoin_icon()

/mob/living/simple_mob/proc/toggle_hostile()
	set name = "Toggle Hostile"
	set category = "OOC"
	set src in view(1)

	if(!isliving(usr))
		return

	if(usr.ckey != load_owner)
		to_chat(usr, "<span class = 'warning'>This isn't your pet, you can't do that!</span>")
		return
	if(ckey)
		to_chat(usr, "<span class = 'warning'>Someone is already controlling \the [src].</span>")
		return
	if(!ai_holder)
		to_chat(usr, "<span class = 'warning'>\The [src] seems to not have an AI, so you can't do that.</span>")
		return
	ai_holder.hostile = !ai_holder.hostile
	to_chat(usr, "<span class = 'notice'>\The [src] is [ai_holder.hostile ? "now hostile" : "no longer hostile"].</span>")

/mob/living/simple_mob/proc/toggle_follow()
	set name = "Toggle Follow"
	set category = "OOC"
	set src in view(1)

	if(!isliving(usr))
		return

	if(usr.ckey != load_owner)
		to_chat(usr, "<span class = 'warning'>This isn't your pet, you can't do that!</span>")
		return
	if(ckey)
		to_chat(usr, "<span class = 'warning'>Someone is already controlling \the [src].</span>")
		return
	if(!ai_holder)
		to_chat(usr, "<span class = 'warning'>\The [src] seems to not have an AI, so you can't do that.</span>")
		return
	if(!ai_holder.leader)
		ai_holder.set_follow(usr, follow_for = 10 MINUTES)
	else
		ai_holder.lose_follow()
	to_chat(usr, "<span class = 'notice'>\The [src] is [ai_holder.leader ? "now" : "no longer"] following you.</span>")

//STATION PET SAVE SYSTEM
/datum/persistent/saved_mobs
	name = "saved mobs"
	var/max_mobs = 1000

/datum/persistent/saved_mobs/SetFilename()
    filename = "data/persistent/saved_mobs.json"

/datum/persistent/saved_mobs/Shutdown()
	if(SSpersistence.stored_pets.len > max_mobs)
		var/over = SSpersistence.stored_pets.len - max_mobs
		log_admin("There are [over] more station mobs stored than the maximum allowed.")
		while(over > 0)
			var/list/d = SSpersistence.stored_pets[1]
			if(SSpersistence.stored_pets.Remove(list(d)))
				log_admin("A station pet was deleted: [d["name"]] - [d["type"]]")
			else
				log_and_message_admins("Attempted to delete a station pet, but failed.")
			over --

	if(fexists(filename))
		fdel(filename)
	to_file(file(filename), json_encode(SSpersistence.stored_pets))

/datum/persistent/saved_mobs/Initialize()
	. = ..()
	if(fexists(filename))
		SSpersistence.stored_pets = json_decode(file2text(filename))
	for(var/obj/effect/station_pet/pet in world)
		pet.do_yo_thang_gurrrrllllllll()

/obj/machinery/mob_bank/proc/persist_mob_save_station(mob/user, mob/living/simple_mob/ourmob)
	var/list/to_save = ourmob.mob_bank_save(user, TRUE)

	if(!to_save)
		return

	SSpersistence.stored_pets |= list(to_save)
	to_chat(user,"<span class = 'notice'>\The [src] completes its scan of \the [ourmob].</span>")

/obj/effect/station_pet
	icon = 'icons/rogue-star/machinex32.dmi'
	icon_state = "PET"
	var/static/list/picked = list()

/obj/effect/station_pet/proc/do_yo_thang_gurrrrllllllll()
	if(SSpersistence.stored_pets.len > picked.len)
		var/list/possible = list()
		possible += SSpersistence.stored_pets

		for(var/list/pet in picked)
			possible.Remove(list(pet))

		var/list/ourmob = pick(possible)
		picked.Add(list(ourmob))

		var/ourtype = ourmob["type"]
		var/mob/living/simple_mob/M = new ourtype(get_turf(src))
		M.mob_bank_load(load = ourmob)
		M.hunter = FALSE
		M.desc += " It has a PET tag: \"[M.real_name]\", it is registered as a station pet!"
		M.faction = "neutral"
		M.ai_holder.hostile = FALSE
		M.ai_holder.vore_hostile = FALSE

		log_admin("[M] - [M.type] was spawned from the station pet spawn list.")
	qdel(src)
