/obj/clickthroughobj
	var/image/clickthroughimage = null

/mob
	var/image/selfinvis = null
	var/obj/clickthroughobj/clickthroughvis = null

/mob/set_dir()
	. = ..()
	if(. && clickthroughvis)
		clickthroughvis.clickthroughimage.dir = dir

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
		clickthroughvis.appearance_flags = KEEP_APART|LONG_GLIDE|TILE_BOUND // KEEP_APART needs to be set, or else the clickthroughobj shows up in the right click menu.
	if(!vis_contents.Find(clickthroughvis))
		vis_contents += clickthroughvis
		clickthroughvis.transform = new()
	if(client.images.Find(selfinvis) || client.images.Find(clickthroughvis.clickthroughimage))
		client.images -= selfinvis
		client.images -= clickthroughvis.clickthroughimage
	else
		clickthroughvis.clickthroughimage = image(src, clickthroughvis)
		clickthroughvis.clickthroughimage.appearance_flags = KEEP_TOGETHER|LONG_GLIDE|TILE_BOUND
		clickthroughvis.clickthroughimage.alpha = 50
		clickthroughvis.clickthroughimage.dir = dir
		clickthroughvis.clickthroughimage.transform = new() // Fixes scaling being incorrectly applied to the image object.
		client.images += clickthroughvis.clickthroughimage
		client.images += selfinvis