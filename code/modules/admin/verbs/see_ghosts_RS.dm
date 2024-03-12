/client/proc/see_ghosts(var/mob/living/L in view(view))
	set name = "See Ghosts"
	set desc = "Allows one to see ghosts!"
	set category = "Fun"
	if(!check_rights(R_ADMIN, R_FUN))
		return

	if(L.see_invisible_default == SEE_INVISIBLE_LIVING)
		L.see_invisible_default = SEE_INVISIBLE_OBSERVER
		L.plane_holder.set_vis(VIS_GHOSTS, TRUE)
		to_chat(src,"<span class='warning'>\The [L] can now see ghosts.</span>")
	else
		L.see_invisible_default = SEE_INVISIBLE_LIVING
		L.plane_holder.set_vis(VIS_GHOSTS, FALSE)
		to_chat(src,"<span class='warning'>\The [L] can no longer see ghosts.</span>")

	log_and_message_admins("has toggled [key_name(L)]'s ability to see ghosts.")
	feedback_add_details("admin_verb","SEEGHOSTS")
