//Let's go wild let's go stupid
//My code is an atrocity, may it stand as a testement for all who gaze my way, look and be afraid
/obj/machinery/mob_bank
	name = "PET System"
	desc = "It's the petatronic energy transport system! It's a machine that can scan and retrieve your pets!"
	description_fluff = "You can use this machine to take a scan of your pets so that they can be retrieved in future shifts. This system allows you to save one mob as a pet per character. Saving or loading mobs is only available one time per shift on an account basis. (Ckey) Saving a pet makes loading a pet unavalable for the duration of the shift. There are a number of restrictions about what pets can be stored. No crew members or other similarly complicated/intelligent creatures (monkeys/carbons/borgs), no otherwise sapient creatures (player controlled mobs), and no hostile entities. Any already registered pets will also not be able to be registered. Further, some kinds of creatures may have their own individual restrictions. One can register a pet by presenting the pet to the scanning device. (Click and drag your mob's sprite onto the sprite of the bank.) Once one has registered a pet, they can retrieve that pet in future shifts. One can not retrieve their pet on the same shift that they registered it, as the pet will still be present!"
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

	if(!user.etching)
		to_chat(user, SPAN_WARNING("You cannot use \the [src] at this time. Your mob either cannot use \the [src] or something has gone wrong and you should contact a developer."))
		return
	var/pet_total = 0
	if(user.etching.pet_data)
		pet_total = user.etching.pet_data.len
<<<<<<< HEAD
	var/msg = "Pet slots: [pet_total]/[user.etching.pet_slots]"
	var/choice = tgui_input_list(user, msg, "[src]", list("Retrieve","Manage","Purchase Storage"))
=======

	var/choice = tgui_input_list(user, "Pet slots: [pet_total]/[user.etching.pet_slots]", "[src]", list("Retrieve","Manage","Purchase Storage"))
>>>>>>> e477c2a2d4749f994460195ba4a442053ef845a0

	switch(choice)
		if("Purchase Storage")
			if(user.etching.purchase_pet_slot())
				visible_message(SPAN_NOTICE("\The [src] pings happily!"), runemessage = "ping!")
			else
				visible_message(SPAN_WARNING("\The [src] boops..."), runemessage = "boop. . .")
		if("Retrieve")
			if(user.ckey in mob_takers)
				to_chat(user, "<span class='warning'>You have already saved or retrieved a pet from \the [src] this shift.</span>")
				return
			if(!Adjacent(user) || inoperable() || panel_open)
				visible_message("<span class='warning'>\The [src] boops sadly...</span>", runemessage = "boop...")
				return
			begin_use(10)
			if(!persist_mob_load(user))
				visible_message("<span class='warning'>\The [src] boops sadly...</span>", runemessage = "boop...")
			else
				visible_message("<span class='notice'>\The [src] pings happily!</span>", runemessage = "Ping!")
		if("Manage")
			user.etching.manage_pets()

/obj/machinery/mob_bank/proc/persist_mob_savefile_path(mob/user)
	return "data/player_saves/[copytext(user.ckey, 1, 2)]/[user.ckey]/pet/slot[user.client.prefs.default_slot].json"

/obj/machinery/mob_bank/proc/persist_mob_save(mob/user, mob/living/simple_mob/ourmob)
	if(IsGuestKey(user.key))
		return
	if(!user.etching)
		return
	if(user.etching.pet_data)
		var/list/petlist = user.etching.pet_data[ourmob.name]
		if(petlist)
			if(petlist["type"] == "[ourmob.type]")
				if(!tgui_alert(user, "Do you want to put [ourmob] away?", "Store [ourmob]",list("Store", "No way!"), 10 SECONDS) == "Store")
					to_chat(user, SPAN_DANGER("You decide not to put \the [ourmob] away."))
					return
				begin_use(10)
				if(!do_after(user, 10 SECONDS, src, exclusive = TASK_ALL_EXCLUSIVE) || inoperable())
					visible_message("<span class='warning'>\The [src] boops sadly...</span>", runemessage = "boop...")
					return
				if(!user.etching.pet_save(ourmob, ourmob.name))	//Save mob to character etching
					to_chat(user,SPAN_DANGER("The pet was not saved."))
					visible_message("<span class='warning'>\The [src] boops sadly...</span>", runemessage = "boop...")
					return
				else
					var/list/verbs = list("ingests", "slurps", "gobbles", "gulps", "gathers", "snarfs", "guzzles", "glorps", "devours", "inserts")
					visible_message(span_green("\The [src] [pick(verbs)] \the [ourmob] into its petatronic storage matrix!"), runemessage = "burps. . .")
				if(ourmob.name == user.etching.loaded_pet)
					user.etching.loaded_pet = null
				qdel(ourmob)
				mob_takers -= user.ckey
			return

	if(user.ckey in mob_savers)
		to_chat(user, "<span class = 'warning'>You have already registered a pet this shift, and can not register another until next shift. Sorry about that!</span>")
		return
	if(!ourmob.save_conditions(user))
		to_chat(user, "<span class = 'warning'>\The [ourmob] can not be registered into the PET system.</span>")
		return

	var/whatname = tgui_input_text(user, "What name do you want to register for \the [ourmob]? ([PET_NAME_MAX] characters)", "Pet name?", ourmob.name, max_length = PET_NAME_MAX)
	if(length(whatname) > PET_NAME_MAX)
		to_chat(user, SPAN_WARNING("[whatname] is too long. ([PET_NAME_MAX] characters)"))
		return
	if(!whatname)
		return
	var/choice = tgui_alert(user, "Do you want to store this pet for yourself, or for the station pool?", "[src]", list("For me!", "For the station", "Cancel"))
	if(choice == "For the station")
		if(ourmob.load_owner)
			to_chat(user, "<span class = 'warning'>\The [ourmob] has already been registered. It can not also be registered to the station!</span>")
			return
		visible_message("<span class='notice'>\The [src] scans \the [ourmob] thoroughly...</span>", runemessage = "wrrr...")
		begin_use(10)
		if(!do_after(user, 10 SECONDS, src, exclusive = TASK_ALL_EXCLUSIVE) || inoperable())
			visible_message("<span class='warning'>\The [src] boops sadly...</span>", runemessage = "boop...")
			return
		ourmob.name = whatname
		ourmob.real_name = whatname
		ourmob.load_owner = "STATION"
		persist_mob_save_station(user, ourmob)
		log_admin("[user.ckey] saved [ourmob] - [ourmob.type] to the station pet pool.")
		visible_message("<span class='notice'>\The [src] pings happily as it finishes scanning \the [ourmob]!</span>", runemessage = "Ping!")
		mob_savers |= user.ckey
		return

	else if(choice != "For me!")
		return
	if(user.etching.pet_data)
		if(whatname in user.etching.pet_data)
			if(tgui_alert(user, "[whatname] is a name already present in your pet storage, using this name will OVERWRITE the [whatname] you have already saved. Do you want to proceed?","OVERWRITE [whatname]",list("Cancel", "OVERWRITE")) != "OVERWRITE")
				return
	visible_message("<span class='notice'>\The [src] scans \the [ourmob] thoroughly...</span>", runemessage = "wrrr...")
	begin_use(10)
	if(!do_after(user, 10 SECONDS, src, exclusive = TASK_ALL_EXCLUSIVE) || inoperable())
		visible_message("<span class='warning'>\The [src] boops sadly...</span>", runemessage = "boop...")
		return

	if(!user.etching.pet_save(ourmob, whatname))	//Save mob to character etching
		to_chat(user,SPAN_DANGER("The pet was not saved."))
		visible_message("<span class='warning'>\The [src] boops sadly...</span>", runemessage = "boop...")
		return FALSE
	user.etching.loaded_pet = whatname
	ourmob.name = whatname
	ourmob.real_name = whatname
	ourmob.load_owner = user.ckey
	ourmob.faction = user.faction
	ourmob.hunter = FALSE
	ourmob.verbs += /mob/living/simple_mob/proc/toggle_ghostjoin
	ourmob.verbs += /mob/living/simple_mob/proc/toggle_follow
	user.verbs += /mob/living/proc/toggle_pet_swap
	LAZYCLEARLIST(user.client.multichar_list)
	if(!user.client.multichar_list)
		user.client.multichar_list = list()
	user.client.multichar_list += ourmob
	user.client.multichar_list += user
	user.client.multichar_last = ourmob
	ourmob.verbs += /mob/living/proc/toggle_pet_swap

	if(ourmob.ai_holder.hostile)
		ourmob.verbs += /mob/living/simple_mob/proc/toggle_hostile
		ourmob.ai_holder.hostile = FALSE
		ourmob.ai_holder.vore_hostile = FALSE
	mob_takers |= user.ckey
	mob_savers |= user.ckey
	to_chat(user,"<span class = 'notice'>\The [src] completes its scan of \the [ourmob].</span>")
	log_admin("[user.ckey] saved [ourmob] - [ourmob.type] to their personal file.")
	visible_message("<span class='notice'>\The [src] pings happily as it finishes scanning \the [ourmob]!</span>", runemessage = "Ping!")

/obj/machinery/mob_bank/proc/persist_mob_load(mob/user)
	if(IsGuestKey(user.key))
		return FALSE
	if(!user.etching)
		return FALSE
	var/mob/living/simple_mob/M = user.etching.pet_load(get_turf(src))
	if(!M)
		if(user.real_name != user.client.prefs.real_name)	//Legacy pets were saved using the character slot, so we care when trying to check for backwards compatibility
			to_chat(user, SPAN_WARNING("The slot you have selected in character setup is mismatched with the character you are playing as. In order to use the PET system, please select the slot that matches your character."))
			return
		//Backwards compatibility
		var/path = persist_mob_savefile_path(user)
		if(!path)
			return FALSE
		if(!fexists(path))
			return FALSE

		var/list/load = json_decode(file2text(path))
		if(!load)
			return FALSE

		var/ourtype = load["type"]

		M = new ourtype(get_turf(src))
		M.mob_bank_load(user, load)
		M.name = load["name"]
		M.real_name = M.name
		M.load_owner = user.ckey
		M.faction = user.faction
		M.hunter = FALSE
		M.desc += " It has a PET tag: \"[M.real_name]\", if lost, return to [user.real_name]."
		M.revivedby = user.real_name
		M.verbs += /mob/living/simple_mob/proc/toggle_ghostjoin
		M.verbs += /mob/living/simple_mob/proc/toggle_follow
		if(M.ai_holder?.hostile)
			M.verbs += /mob/living/simple_mob/proc/toggle_hostile
			M.ai_holder.hostile = FALSE
			M.ai_holder.vore_hostile = FALSE
		if(!user.client.multichar_last)
			user.client.multichar_list |= M
			user.client.multichar_list |= user
			user.client.multichar_last = M
			user.verbs += /mob/living/proc/toggle_pet_swap
			M.verbs += /mob/living/proc/toggle_pet_swap
		if(M)
			var/msg = ""
			if(user.etching.pet_save(M, M.name))
				if(user.etching.pet_data[M.name])
					msg += "Pet file successfully adapted to etching format, legacy file will now be deleted."
					for(var/thing in load)
						msg += " || [thing] = [load[thing]]"
					log_debug(msg)
					fdel(path)
				else
					msg = "PET FILE ADAPTED TO ETCHING FORMAT, BUT PET NAME IS MISSING FROM PET_DATA, SOMETHING WENT WRONG, LEGACY FILE NOT DELETED, LEGACY DATA FOLLOWS || [path]"
					for(var/thing in load)
						msg += " || [thing] = [load[thing]]"
					log_and_message_admins(msg)

			else
				msg = "[user] ATTEMPTED TO LEGACY LOAD PET BUT PET SAVE FAILED, ABORTING FILE DELETE || [path]"
				for(var/thing in load)
					msg += " || [thing] = [load[thing]]"
				log_and_message_admins(msg)
	to_chat(user,"<span class = 'notice'>\The [M] appears from \the [src]!</span>")
	log_admin("[key_name_admin(user)] retrieved [M] || [M.type] from the mob bank.")
	mob_takers += user.ckey
	return M

/obj/machinery/mob_bank/MouseDrop_T(mob/living/M, mob/living/user)
	. = ..()
	persist_mob_save(user, M)

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

/mob/living/simple_mob/proc/mob_bank_save(mob/living/user, var/for_station = FALSE)
	. = list()
	if(for_station)
		.["ckey"] = user.ckey
	.["type"] = "[type]"

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
