// RS File
/obj/clickthroughobj
	var/image/clickthroughimage = null

/mob
	var/image/selfinvis = null
	var/obj/clickthroughobj/clickthroughvis = null

/mob/proc/_clickthrough_register_signals()
	RegisterSignal(src, COMSIG_ATOM_DIR_CHANGE, PROC_REF(_clickthrough_dir_change), TRUE)
	RegisterSignal(src, COMSIG_MOB_LOGOUT, PROC_REF(_clickthrough_on_logout), TRUE)
	RegisterSignal(src, COMSIG_PARENT_QDELETING, PROC_REF(_clickthrough_on_logout), TRUE)

/mob/proc/_clickthrough_unregister_signals()
	UnregisterSignal(src, list(COMSIG_ATOM_DIR_CHANGE, COMSIG_MOB_LOGOUT, COMSIG_PARENT_QDELETING))

/mob/proc/_clickthrough_dir_change(atom/source, old_dir, new_dir)
	if(client && clickthroughvis && clickthroughvis.clickthroughimage)
		clickthroughvis.clickthroughimage.dir = new_dir

/mob/proc/_clickthrough_on_logout()
	_clickthrough_unregister_signals()

/mob/proc/update_clickthrough_image()
	if(!client)
		return
	if(!clickthroughvis)
		return
	var/image/I = clickthroughvis.clickthroughimage
	if(!I)
		return
	if(!client.images || !client.images.Find(I))
		return
	I.appearance = src.appearance
	I.appearance_flags = KEEP_TOGETHER|LONG_GLIDE|TILE_BOUND
	I.alpha = 50
	I.dir = dir
	I.transform = new()

/mob/UpdateOverlays()
	..()
	update_clickthrough_image()

/mob/verb/toggle_clickthroughself()
	set name = "Self-Click Toggle"
	set desc = "Toggle being able to click yourself"
	set category = "IC"
	if(isnull(loc))
		to_chat(usr, "<span class='warning'>You can't click yourself if you don't exist anywhere!</span>")
		return

	if(isnull(selfinvis))
		selfinvis = image(null, src) // mouse_opacity is ignored for image objects, so instead we make the mob take up 0 pixels on the client's screen by overriding it with a null icon.
		selfinvis.override = 1
	if(isnull(clickthroughvis))
		clickthroughvis = new()
		clickthroughvis.mouse_opacity = 0
		clickthroughvis.vis_flags = VIS_INHERIT_LAYER|VIS_INHERIT_PLANE
		clickthroughvis.appearance_flags = KEEP_APART|LONG_GLIDE|TILE_BOUND
	if(isnull(clickthroughvis.clickthroughimage))
		clickthroughvis.clickthroughimage = image(src, clickthroughvis)
	if(!vis_contents.Find(clickthroughvis))
		vis_contents += clickthroughvis
		clickthroughvis.transform = new()
	if(client.images.Find(selfinvis) || client.images.Find(clickthroughvis.clickthroughimage))
		client.images -= selfinvis
		client.images -= clickthroughvis.clickthroughimage
		_clickthrough_unregister_signals()
	else
		client.images += clickthroughvis.clickthroughimage
		client.images += selfinvis
		update_clickthrough_image()
		_clickthrough_register_signals()
