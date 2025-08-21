//Let's go wild let's go stupid
//My code is an atrocity, may it stand as a testement for all who gaze my way, look and be afraid
/obj/machinery/mob_bank
	name = "PET System"
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
	if(busy_bank)
		to_chat(user, "<span class='warning'>\The [src] is already in use.</span>")
		return
	if(user.real_name != user.client.prefs.real_name)
		to_chat(user, "<span class = 'warning'>The slot you have selected in character setup is mismatched with the character you are playing as. In order to use the PET system, please select the slot that matches your character.</span>")
		return

	busy_bank = TRUE
	var/choice = tgui_alert(user, "What would you like to do [src]?", "[src]", list("Info", "Retrieve Pet","Cancel"), timeout = 10 SECONDS)

	if(choice == "Info")
		to_chat(user,"<span class = 'notice'>You can use this machine to take a scan of your pets so that they can be retrieved in future shifts. This system allows you to save one mob as a pet per character. Saving or loading mobs is only available one time per shift on an account basis. (Ckey) Saving a pet makes loading a pet unavalable for the duration of the shift. </span><span class = 'warning'>There are a number of restrictions about what pets can be stored. No crew members or other similarly complicated/intelligent creatures (monkeys/carbons/borgs), no otherwise sapient creatures (player controlled mobs), and no hostile entities. Any already registered pets will also not be able to be registered. Further, some kinds of creatures may have their own individual restrictions.</span><span class = 'notice'> One can register a pet by presenting the pet to the scanning device. (Click and drag your mob's sprite onto the sprite of the bank.) Once one has registered a pet, they can retrieve that pet in future shifts. One can not retrieve their pet on the same shift that they registered it, as the pet will still be present!</span>")
		busy_bank = FALSE
	else if (choice == "Retrieve Pet")
		if(user.ckey in mob_takers)
			to_chat(user, "<span class='warning'>You have already saved or retrieved a pet from \the [src] this shift.</span>")
			busy_bank = FALSE
			return
		choice = tgui_alert(user, "Are you sure you want to retrieve your pet?", "[src]", list("No", "Yes"), timeout = 10 SECONDS)
		update_icon()
		if(!choice || choice == "No" || !Adjacent(user) || inoperable() || panel_open)
			busy_bank = FALSE
			update_icon()
			visible_message("<span class='warning'>\The [src] boops sadly...</span>", runemessage = "boop...")
			return
		else if(!do_after(user, 10 SECONDS, src, exclusive = TASK_ALL_EXCLUSIVE) || inoperable())
			busy_bank = FALSE
			update_icon()
			visible_message("<span class='warning'>\The [src] boops sadly...</span>", runemessage = "boop...")
			return
		persist_mob_load(user)
		busy_bank = FALSE
		update_icon()
		visible_message("<span class='notice'>\The [src] pings happily!</span>", runemessage = "Ping!")
	else
		busy_bank = FALSE
		return

/obj/machinery/mob_bank/proc/persist_mob_savefile_path(mob/user)
	return "data/player_saves/[copytext(user.ckey, 1, 2)]/[user.ckey]/pet/slot[user.client.prefs.default_slot].json"

/obj/machinery/mob_bank/proc/persist_mob_save(mob/user, mob/living/simple_mob/ourmob)
	if(busy_bank)
		to_chat(user, "<span class='warning'>\The [src] is already in use.</span>")
		return
	if(IsGuestKey(user.key))
		return

	if(user.ckey in mob_savers)
		to_chat(user, "<span class = 'warning'>You have already registered a pet this shift, and can not register another until next shift. Sorry about that!</span>")
		return
	if(!ourmob.save_conditions(user))
		to_chat(user, "<span class = 'warning'>\The [ourmob] can not be registered into the PET system.</span>")
		return
	if(user.real_name != user.client.prefs.real_name)
		to_chat(user, "<span class = 'warning'>The slot you have selected in character setup is mismatched with the character you are playing as. In order to use the PET system, please select the slot that matches your character.</span>")
		return
	busy_bank = TRUE
	var/whatname = tgui_input_text(user, "What name do you want to register for \the [ourmob]? (25 characters)", "Pet name?", ourmob.name, max_length = 25)
	if(length(whatname) > 25)
		to_chat(user, "<span class = 'warning'>[whatname] is too long. (25 characters)</span>")
		return
	if(!whatname)
		busy_bank = FALSE
		return
	var/choice = tgui_alert(user, "Do you want to store this pet for yourself, or for the station pool?", "[src]", list("For me!", "For the station", "Cancel"), timeout = 10 SECONDS)
	if(choice == "For the station")
		if(ourmob.load_owner)
			to_chat(user, "<span class = 'warning'>\The [ourmob] has already been registered. It can not also be registered to the station!</span>")
			busy_bank = FALSE
			return
		visible_message("<span class='notice'>\The [src] scans \the [ourmob] thoroughly...</span>", runemessage = "wrrr...")
		update_icon()
		if(!do_after(user, 10 SECONDS, src, exclusive = TASK_ALL_EXCLUSIVE) || inoperable())
			visible_message("<span class='warning'>\The [src] boops sadly...</span>", runemessage = "boop...")
			busy_bank = FALSE
			update_icon()
			return
		ourmob.name = whatname
		ourmob.real_name = whatname
		ourmob.load_owner = "STATION"
		persist_mob_save_station(user, ourmob)
		busy_bank = FALSE
		log_admin("[user.ckey] saved [ourmob] - [ourmob.type] to the station pet pool.")
		visible_message("<span class='notice'>\The [src] pings happily as it finishes scanning \the [ourmob]!</span>", runemessage = "Ping!")
		mob_savers |= user.ckey
		update_icon()
		return

	else if(choice != "For me!")
		busy_bank = FALSE
		return

	visible_message("<span class='notice'>\The [src] scans \the [ourmob] thoroughly...</span>", runemessage = "wrrr...")
	update_icon()
	if(!do_after(user, 10 SECONDS, src, exclusive = TASK_ALL_EXCLUSIVE) || inoperable())
		busy_bank = FALSE
		visible_message("<span class='warning'>\The [src] boops sadly...</span>", runemessage = "boop...")
		update_icon()
		return

	var/path = persist_mob_savefile_path(user)

	if(path)
		if(fexists(path))
			var/list/load = json_decode(file2text(path))
			if(load)
				var/ourtype = load["type"]
				if(ourtype)
					if(tgui_alert(user, "It appears that you already have a pet registered! Are you sure you would like to overwrite your existing pet?", "[src]", list("No", "Yes"), timeout = 10 SECONDS) != "Yes")
						busy_bank = FALSE
						visible_message("<span class='warning'>\The [src] boops sadly...</span>", runemessage = "boop...")
						update_icon()
						return
	ourmob.name = whatname
	ourmob.real_name = whatname
	ourmob.load_owner = user.ckey
	ourmob.faction = user.faction
	ourmob.hunter = FALSE
	var/list/to_save = ourmob.mob_bank_save(user)
	ourmob.verbs += /mob/living/simple_mob/proc/toggle_ghostjoin
	ourmob.verbs += /mob/living/simple_mob/proc/toggle_follow
	if(ourmob.ai_holder.hostile)
		ourmob.verbs += /mob/living/simple_mob/proc/toggle_hostile
		ourmob.ai_holder.hostile = FALSE
		ourmob.ai_holder.vore_hostile = FALSE

	if(!to_save)
		busy_bank = FALSE
		visible_message("<span class='warning'>\The [src] boops unhappily. It encountered an error when attempting to save \the [ourmob]'s scan.</span>", runemessage = "boop...")
		update_icon()
		return

	var/json_to_file = json_encode(to_save)
	if(!json_to_file)
		log_debug("Saving: [path] failed jsonencode")
		busy_bank = FALSE
		visible_message("<span class='warning'>\The [src] boops unhappily. It encountered an error when attempting to save \the [ourmob]'s scan.</span>", runemessage = "boop...")
		update_icon()
		return

	//Write it out
	rustg_file_write(json_to_file, path)

	if(!fexists(path))
		log_debug("Saving: [path] failed file write")
		busy_bank = FALSE
		visible_message("<span class='warning'>\The [src] boops unhappily. It encountered an error when attempting to save \the [ourmob]'s scan.</span>", runemessage = "boop...")
		update_icon()
		return
	mob_takers |= user.ckey
	mob_savers |= user.ckey
	to_chat(user,"<span class = 'notice'>\The [src] completes its scan of \the [ourmob].</span>")
	log_admin("[user.ckey] saved [ourmob] - [ourmob.type] to their personal file.")
	busy_bank = FALSE
	visible_message("<span class='notice'>\The [src] pings happily as it finishes scanning \the [ourmob]!</span>", runemessage = "Ping!")
	update_icon()

/obj/machinery/mob_bank/proc/persist_mob_load(mob/user)
	if(IsGuestKey(user.key))
		return FALSE

	var/path = persist_mob_savefile_path(user)

	if(!path)
		return FALSE
	if(!fexists(path))
		return FALSE

	var/list/load = json_decode(file2text(path))
	if(!load)
		return FALSE

	var/ourtype = load["type"]

	var/mob/living/simple_mob/M = new ourtype(get_turf(src))
	M.mob_bank_load(user, load)
	M.faction = user.faction
	M.hunter = FALSE
	M.desc += " It has a PET tag: \"[M.real_name]\", if lost, return to [user.real_name]."
	M.revivedby = user.real_name
	to_chat(user,"<span class = 'notice'>\The [M] appears from \the [src]!</span>")
	log_admin("[key_name_admin(user)] retrieved [M] - [M.type] from the mob bank.")
	mob_takers += user.ckey
	M.verbs += /mob/living/simple_mob/proc/toggle_ghostjoin
	M.verbs += /mob/living/simple_mob/proc/toggle_follow
	if(M.ai_holder.hostile)
		M.verbs += /mob/living/simple_mob/proc/toggle_hostile
		M.ai_holder.hostile = FALSE
		M.ai_holder.vore_hostile = FALSE

/obj/machinery/mob_bank/MouseDrop_T(mob/living/M, mob/living/user)
	. = ..()
	persist_mob_save(user, M)

//Only simple mobs, please don't be insane
/mob/living/simple_mob
	var/load_owner = null

/mob/living/simple_mob/proc/mob_bank_save(mob/living/user)

	var/list/to_save = list(
		"ckey" = user.ckey,
		"type" = type,
		"name" = name
		)

	return to_save

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
	if(user)
		load_owner = user.ckey
	else
		load_owner = "STATION"
	name = load["name"]
	real_name = name

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
	var/list/to_save = ourmob.mob_bank_save(user)

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
