//RS FILE
/*
TO DO:
make sure multiple instances of grant xp are additive, and don't overwrite
*/

#define BASE_MAGIC_COOLDOWN 15
#define BASE_MAGIC_COST 33

/mob/living/proc/consider_magic(cost,spell_class,spell_lv,req_standing,req_corporeal,req_visible)
	if(!etching.consider_magic(cost,spell_class,spell_lv))
		return FALSE
	if(req_standing && (resting||weakened||buckled))	//Buckled is assuming that we might be restrained. Not bothering with checking carbon handcuffs, since nets exist and I am pretty sure that's just a buckle
		to_chat(src, "<span class='warning'>You need to be standing and free to move around to do that!</span>")
		return FALSE
	if(req_corporeal && incorporeal_move)
		to_chat(src, "<span class='warning'>Can't do that while phased out!</span>")
		return FALSE
	if(req_visible && invisibility)
		to_chat(src, "<span class='warning'>Can't do that without revealing yourself!</span>")
		return FALSE
	return TRUE

/mob/living/proc/consume_mana(cost,spell_lv)
	if(cost <= 0)
		return
	etching.consume_mana(cost,spell_lv)

/datum/etching
	var/true_name					//Magic bs
	var/mana = 0					//How much you have
	var/max_mana = 0				//How much you could have
	var/mana_regen = 0				//How fast it comes back
	var/mana_cooldown = 0			//How soon you can do it again
	var/mana_efficiency = 1			//Multiplier for how efficiently you use your mana
	var/core						//Head/body
	var/l_arm
	var/r_arm
	var/l_leg
	var/r_leg

/datum/etching/Destroy()
	. = ..()
	ourmob = null

/datum/etching/process_etching()
	. = ..()
	if(mana < max_mana)
		mana += mana_regen
	if(mana_cooldown)
		mana_cooldown --

/datum/etching/proc/consume_mana(cost,spell_lv)
	var/howmuch = mana - cost
	if(howmuch < 0)
		return FALSE
	mana = howmuch
	mana_cooldown = (BASE_MAGIC_COOLDOWN * spell_lv)	//life tick * lv = about 30 seconds per level
	return TRUE

///datum/etching/update_etching(mode,value)
//	. = ..()

/datum/etching/proc/report_magic()
	var/extra = FALSE
	if(core)
		. += "<span class='boldnotice'>Core</span>: [core]\n"
		extra = TRUE
	if(l_arm)
		. += "[l_arm]\n"
		extra = TRUE
	if(r_arm)
		. += "[r_arm]\n"
		extra = TRUE
	if(l_arm)
		. += "[l_leg]\n"
		extra = TRUE
	if(r_leg)
		. += "[r_leg]\n"
		extra = TRUE

	if(extra)
		. += "\n"

	return .

/datum/etching/proc/consider_magic(cost,spell_class,spell_lv)
	if(ourmob.admin_magic)
		return TRUE
	if(mana_cooldown)
		to_chat(ourmob, "<span class='warning'>You are still recovering! (([mana_cooldown]))</span>")
		return FALSE
	if(cost > mana)
		to_chat(ourmob, "<span class='warning'>You haven't got enough mana! (([mana]/[cost]))</span>")
		return FALSE

//	if(not some_kind_of_level_check())
//		return FALSE

	return TRUE

/datum/etching/proc/calculate_magic_cost(spell_class,spell_lv)
	return (BASE_MAGIC_COST * spell_lv) * mana_efficiency

/datum/etching/proc/magic_load(var/list/load)

	if(!load)
		return

	true_name = load["true_name"]
	core = load["core"]
	l_arm = load["l_arm"]
	r_arm = load["r_arm"]
	l_leg = load["l_leg"]
	r_leg = load["r_leg"]

/datum/etching/proc/magic_save()
	var/list/to_save = list(
		"true_name" = true_name,
		"core" = core,
		"l_arm" = l_arm,
		"r_arm" = r_arm,
		"l_leg" = l_leg,
		"r_leg" = r_leg
	)

	return to_save

/datum/etching/report_status()
	to_world("Hello from magic")
	. = ..()

	var/our_magic = report_magic()
	if(our_magic)
		if(.)
			. += "\n"
		. += our_magic
