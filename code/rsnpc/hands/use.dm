GLOBAL_DATUM_INIT(npc_tgui_state, /datum/tgui_state/npc, new)

/datum/tgui_state/npc/can_use_topic(src_object, mob/user)
	var/mob/living/carbon/human/H = user
	if(!istype(H))
		return STATUS_CLOSE
	if(H.stat)
		return STATUS_DISABLED
	if(H.incapacitated())
		return STATUS_UPDATE
	return H.shared_living_tgui_distance(src_object)

/datum/ai_holder/rsnpc/proc/press(datum/machine, action, list/params)
	if(machine.tgui_status(holder, GLOB.npc_tgui_state) != STATUS_INTERACTIVE)
		return FALSE
	var/datum/tgui/ui = new(holder, machine, "npc")
	ui.state = GLOB.npc_tgui_state
	ui.status = STATUS_INTERACTIVE
	var/old_usr = usr
	usr = holder
	machine.tgui_act(action, params || list(), ui, ui.state)
	usr = old_usr
	qdel(ui)
	return TRUE
