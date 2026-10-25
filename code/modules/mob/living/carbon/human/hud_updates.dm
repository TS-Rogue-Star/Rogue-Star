/////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2026: HUD Optimization //
/////////////////////////////////////////////////////////////////////

/mob/living/carbon/human
	var/list/hud_last_inputs

/mob/living/carbon/human/proc/check_hud_input(index, value, update_flags)
	if(hud_last_inputs[index] == value)
		return
	hud_last_inputs[index] = value
	hud_updateflag |= update_flags

/mob/living/carbon/human/proc/refresh_hud_update_flags()
	if(!has_huds || !LAZYLEN(hud_list))
		return
	if(!hud_last_inputs)
		hud_last_inputs = new/list(TOTAL_HUDS)
		hud_updateflag = (1 << (TOTAL_HUDS + 1)) - 2
	check_hud_input(HEALTH_HUD, health, 1 << HEALTH_HUD)
	check_hud_input(HEALTH_VR_HUD, getMaxHealth(), 1 << HEALTH_HUD)
	check_hud_input(LIFE_HUD, "[stat]:[isSynthetic()]", (1 << HEALTH_HUD) | (1 << LIFE_HUD) | (1 << STATUS_HUD))
	var/disease_status = length(virus2) ? 1 : 0
	for(var/ID in virus2)
		if(ID in virusDB)
			disease_status |= 2
			break
	var/mob/living/simple_mob/animal/borer/B = has_brain_worms()
	if(B)
		disease_status |= B.controlling ? 8 : 4
	check_hud_input(STATUS_HUD, disease_status, 1 << STATUS_HUD)
	var/obj/item/weapon/card/id/I = wear_id?.GetID()
	check_hud_input(ID_HUD, I?.assignment, 1 << ID_HUD)
	check_hud_input("id_rank", I?.rank, 1 << ID_HUD)
	check_hud_input("id_type", I?.type, 1 << ID_HUD)
	check_hud_input(WANTED_HUD, I ? I.registered_name : name, 1 << WANTED_HUD)
	var/implant_flags = 0
	for(var/obj/item/weapon/implant/implant in src)
		if(!implant.implanted || implant.malfunction)
			continue
		if(istype(implant, /obj/item/weapon/implant/tracking))
			implant_flags |= 1 << IMPTRACK_HUD
		if(istype(implant, /obj/item/weapon/implant/loyalty))
			implant_flags |= 1 << IMPLOYAL_HUD
		if(istype(implant, /obj/item/weapon/implant/chem))
			implant_flags |= 1 << IMPCHEM_HUD
	check_hud_input(IMPTRACK_HUD, implant_flags, (1 << IMPTRACK_HUD) | (1 << IMPLOYAL_HUD) | (1 << IMPCHEM_HUD))
	var/backup_state = get_backup_hud_state()
	check_hud_input(BACKUP_HUD, backup_state, 1 << BACKUP_HUD)
	check_hud_input(SPECIALROLE_HUD, mind?.special_role, 1 << SPECIALROLE_HUD)
	check_hud_input(VANTAG_HUD, vantag_pref, 1 << VANTAG_HUD)

// RS Edit: HUD Optimization (Lira, September 2026)
/mob/living/carbon/human/proc/get_backup_hud_state()
	. = "hudblank"
	for(var/obj/item/organ/external/E in organs)
		for(var/obj/item/weapon/implant/backup/B in E.implants)
			if(!B.implanted)
				continue
			if(!mind)
				. = "hud_backup_nomind"
			else if(!(mind.name in B.our_db.body_scans))
				. = "hud_backup_nobody"
			else
				. = "hud_backup_norm"

/mob/living/carbon/human/proc/set_hud_icon_state(index, new_state)
	var/image/I = hud_list[index]
	if(!I)
		return FALSE
	if(I.icon_state == new_state && (I.appearance in our_overlays))
		return FALSE
	grab_hud(index)
	I.icon_state = new_state
	apply_hud(index, I)
	return TRUE

/datum/datacore
	var/list/hud_record_inputs

/datum/datacore/proc/refresh_hud_record_flags()
	var/list/current_inputs = list(length(general), length(security))
	for(var/datum/data/record/R in general)
		current_inputs.Add(R, R.fields["name"], R.fields["id"])
	for(var/datum/data/record/R in security)
		current_inputs.Add(R, R.fields["id"], R.fields["criminal"])
	var/changed = length(current_inputs) != length(hud_record_inputs)
	if(!changed)
		for(var/i in 1 to length(current_inputs))
			if(current_inputs[i] != hud_record_inputs[i])
				changed = TRUE
				break
	hud_record_inputs = current_inputs
	if(!changed)
		return FALSE
	for(var/mob/living/carbon/human/H as anything in human_mob_list)
		BITSET(H.hud_updateflag, WANTED_HUD)
	return TRUE
