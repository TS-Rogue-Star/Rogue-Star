// RS File

/client/proc/toggle_admin_secret_view()
	set category = "Fun"
	set name = "Toggle Admin Secrets"
	set desc = "Makes it so you can see admin secrets!"
	set popup_menu = FALSE

	if(!check_rights(R_FUN))
		return

	if(PLANE_ADMIN_SECRET in mob.planes_visible)
		mob.plane_holder.set_vis(VIS_ADMIN_SECRET, FALSE)
		to_chat(mob,SPAN_DANGER("Admin secrets disabled!"))
	else
		mob.plane_holder.set_vis(VIS_ADMIN_SECRET, TRUE)
		to_chat(mob,SPAN_NOTICE("Admin secrets enabled!"))

// New lighting manager panel (Lira, October 2025)
/client/proc/admin_lighting_manager()
	set name = "Lighting Manager"
	set desc = "Mass adjust lighting fixtures."
	set category = "Fun"

	if(!check_rights(R_FUN))
		return

	var/datum/tgui_module/admin_lighting/panel = new()
	panel.tgui_interact(usr)
	log_and_message_admins("has opened the lighting manager.")
	feedback_add_details("admin_verb", "ALMP")

// Character Designer Cache Enhancements (Lira, September 2026)
/client/proc/rebuild_custom_marking_atlas()
	set name = "Rebuild Character Designer Atlas"
	set desc = "Rebuild all static Character Designer atlas sheets, bypassing the persisted cache."
	set category = "Debug"

	if(!check_rights(R_DEBUG))
		return
	if(alert(src, "Rebuild the complete Character Designer atlas? The server will pause while it builds. Existing Designer windows keep their current assets; reopen them afterward to use the rebuilt atlas.", "Rebuild Character Designer Atlas", "Rebuild", "Cancel") != "Rebuild")
		return
	if(!check_rights(R_DEBUG) || !SScustom_marking)
		return
	log_and_message_admins("started a full Character Designer atlas rebuild, bypassing the persisted cache.")
	var/list/result = SScustom_marking.rebuild_static_atlas()
	if(result?["success"])
		log_and_message_admins("completed a full Character Designer atlas rebuild: [result["frames"]] frames, [result["sheets"]] sheets, [result["attempts"]] attempt(s), [result["seconds"]] seconds.")
		to_chat(src, SPAN_NOTICE("Character Designer atlas rebuilt successfully. Close and reopen the Designer to use the rebuilt atlas."))
	else
		var/retained_message = result?["retained_previous"] ? " The previous working atlas was retained." : ""
		var/reason = result?["reason"] || "No result was returned."
		log_and_message_admins("could not rebuild the Character Designer atlas: [reason].[retained_message]")
		to_chat(src, SPAN_WARNING("Character Designer atlas rebuild failed: [reason].[retained_message]"))

// Character Designer Cache Enhancements (Lira, September 2026)
/client/proc/reload_custom_marking_atlas()
	set name = "Reload Character Designer Atlas From Disk"
	set desc = "Validate and load a prebuilt Character Designer atlas from data/spritesheets for the current round."
	set category = "Debug"

	if(!check_rights(R_DEBUG))
		return
	if(alert(src, "Load the prebuilt Character Designer atlas from data/spritesheets/? Copy its persistent-cache JSON and every referenced .cache file there first. The server will pause during validation. An incompatible cache will be rejected, preserving the current atlas. Reopen Designer windows afterward to use the imported atlas.", "Reload Character Designer Atlas From Disk", "Load", "Cancel") != "Load")
		return
	if(!check_rights(R_DEBUG) || !SScustom_marking)
		return
	log_and_message_admins("started loading a prebuilt Character Designer atlas from disk.")
	var/list/result = SScustom_marking.reload_static_atlas()
	if(result?["success"])
		log_and_message_admins("loaded a prebuilt Character Designer atlas: [result["frames"]] frames, [result["sheets"]] sheets, [result["seconds"]] seconds.")
		to_chat(src, SPAN_NOTICE("Character Designer atlas loaded successfully. Close and reopen the Designer to use the imported atlas."))
	else
		var/reason = result?["reason"] || "No result was returned."
		log_and_message_admins("could not load the prebuilt Character Designer atlas: [reason]. The current atlas was preserved.")
		to_chat(src, SPAN_WARNING("Character Designer atlas import failed: [reason]. The current atlas was preserved."))
