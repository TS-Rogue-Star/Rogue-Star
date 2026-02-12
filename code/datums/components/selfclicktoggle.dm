// RS File
/datum/component/selfclicktoggle
	var/atom/movable/clickthroughatom
	var/image/selfinvis
	var/image/clickthroughimage
	var/active = FALSE

/datum/component/selfclicktoggle/Initialize()
	. = ..()

	if(!ismob(parent))
		return COMPONENT_INCOMPATIBLE

	src.clickthroughatom = new()
	clickthroughatom.appearance_flags = KEEP_APART
	clickthroughatom.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	clickthroughatom.vis_flags = (VIS_INHERIT_PLANE|VIS_INHERIT_LAYER)

	selfinvis = image(null, parent) // mouse_opacity is ignored for image objects, so instead we make the mob take up 0 pixels on the client's screen by overriding it with a null icon.
	selfinvis.override = 1

	RegisterSignal(parent, COMSIG_MOB_LOGOUT, PROC_REF(_clickthrough_on_logout), TRUE)
	RegisterSignal(parent, COMSIG_PARENT_QDELETING, PROC_REF(_clickthrough_on_logout), TRUE)

/datum/component/selfclicktoggle/Destroy(force)
	QDEL_NULL(clickthroughatom)
	_clickthrough_unregister_signals()
	UnregisterSignal(parent, list(COMSIG_MOB_LOGOUT, COMSIG_PARENT_QDELETING))
	return ..()

/datum/component/selfclicktoggle/proc/_clickthrough_register_signals()
	SIGNAL_HANDLER

	RegisterSignal(parent, COMSIG_ATOM_DIR_CHANGE, PROC_REF(_clickthrough_dir_change), TRUE)
	RegisterSignal(parent, COMSIG_ATOM_UPDATE_OVERLAYS, PROC_REF(_update_clickthrough_image), TRUE)

/datum/component/selfclicktoggle/proc/_clickthrough_unregister_signals()
	UnregisterSignal(parent, list(COMSIG_ATOM_DIR_CHANGE, COMSIG_ATOM_UPDATE_OVERLAYS))

/datum/component/selfclicktoggle/proc/_clickthrough_dir_change(atom/source, old_dir, new_dir)
	SIGNAL_HANDLER
	clickthroughimage.dir = new_dir

/datum/component/selfclicktoggle/proc/_clickthrough_on_logout()
	SIGNAL_HANDLER
	Destroy()

/datum/component/selfclicktoggle/proc/_update_clickthrough_image()
	SIGNAL_HANDLER
	var/mob/parentmob = parent
	if(!parentmob.client)
		return
	var/image/I = clickthroughimage
	if(!I)
		return
	if(!parentmob.client.images || !parentmob.client.images.Find(I))
		return
	I.appearance = parentmob.appearance
	I.pixel_x = 0
	I.pixel_y = 0
	I.alpha = 50
	I.dir = parentmob.dir
	I.transform = new()

/datum/component/selfclicktoggle/proc/do_the_thing()
	SIGNAL_HANDLER
	var/mob/parentmob = parent
	if(!parentmob.client)
		return
	if(isnull(clickthroughimage))
		clickthroughimage = image(parentmob, clickthroughatom)
	if(!parentmob.vis_contents.Find(clickthroughatom))
		parentmob.vis_contents += clickthroughatom
		clickthroughatom.transform = new()
	if(parentmob.client.images.Find(selfinvis) || parentmob.client.images.Find(clickthroughimage))
		parentmob.client.images -= selfinvis
		parentmob.client.images -= clickthroughimage
		_clickthrough_unregister_signals()
		active = FALSE
	else
		parentmob.client.images += clickthroughimage
		parentmob.client.images += selfinvis
		_update_clickthrough_image()
		_clickthrough_register_signals()
		active = TRUE

/client/verb/toggle_clickthroughself()
	set name = "Self-Click Toggle"
	set desc = "Toggle being able to click yourself"
	set category = "IC"
	var/mob/M = mob
	if(isnull(M))
		to_chat(usr, "<span class='warning'>You can't click yourself if you don't exist!</span>")
		return
	if(isnull(M.loc))
		to_chat(usr, "<span class='warning'>You can't click yourself in nullspace!</span>")
		return

	var/datum/component/selfclicktoggle/transparency = M.LoadComponent(/datum/component/selfclicktoggle)
	transparency.do_the_thing()
	return transparency.active
