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
