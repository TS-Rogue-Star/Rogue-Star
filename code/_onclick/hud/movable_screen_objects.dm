
//////////////////////////
//Movable Screen Objects//
//   By RemieRichards	//
//////////////////////////

///////////////////////////////////////////////////////////////////////////////////////////////
//Updated by Lira for Rogue Star August 2025 to allow fluid dragging of objects on the screen//
///////////////////////////////////////////////////////////////////////////////////////////////

//Movable Screen Object
//Not tied to the grid, places it's center where the cursor is

/obj/screen/movable
	var/snap2grid = FALSE
	var/moved = FALSE
	var/x_off = -16 
	var/y_off = -16
	var/dragging = FALSE //RS Add: New var to detect dragging (Lira, August 2025)
	var/drag_off_x = null //RS Add: Var for drag x-coordinate offset (Lira, August 2025)
	var/drag_off_y = null //RS Add: Var for drag y-coordinate offset (Lira, August 2025)

//RS Add: Number of tiles visible horizontally/vertically (Lira, August 2025)
/obj/screen/movable/proc/_view_tiles()
	return world.view*2 + 1

//RS Add: Convert tile+pixel to absolute pixel in viewport (Lira, August 2025)
/obj/screen/movable/proc/_abs_px(var/tile_index, var/pix)
	return (tile_index - 1) * 32 + pix

//RS Add: Clamp absolute pixel into viewport range [0, max] (Lira, August 2025)
/obj/screen/movable/proc/_clamp_abs(var/abs_px)
	var/max_abs = _view_tiles() * 32 - 1
	return clamp(abs_px, 0, max_abs)

//RS Add: Get current pixel offsets from our screen_loc (defaults to 0 if absent) (Lira, August 2025)
/obj/screen/movable/proc/get_current_pix_offsets()
	var/list/parts = splittext("[screen_loc]", ",")
	var/list/xp = splittext(parts.len >= 1 ? parts[1] : "CENTER", ":")
	var/list/yp = splittext(parts.len >= 2 ? parts[2] : "CENTER", ":")
	var/opx = (xp.len >= 2) ? text2num(xp[2]) : 0
	var/opy = (yp.len >= 2) ? text2num(yp[2]) : 0
	return list(opx, opy)

//RS Add: Decode our current anchor tile indices from screen_loc (Lira, August 2025)
/obj/screen/movable/proc/get_current_tile_indices()
	var/list/parts = splittext("[screen_loc]", ",")
	var/xa = parts.len >= 1 ? splittext(parts[1], ":")[1] : "CENTER"
	var/ya = parts.len >= 2 ? splittext(parts[2], ":")[1] : "CENTER"
	return list(decode_anchor_X(xa), decode_anchor_Y(ya))

//RS Add: Robustly decode X anchor like "WEST+3", "EAST-1", "CENTER+2", numeric (Lira, August 2025)
/obj/screen/movable/proc/decode_anchor_X(anchor)
	var/view_dist = world.view
	if(isnum(anchor))
		return text2num(anchor)
	if(findtext(anchor, "EAST-"))
		var/num = text2num(copytext(anchor, 6))
		if(!num) num = 0
		return view_dist*2 + 1 - num
	if(findtext(anchor, "WEST+"))
		var/num = text2num(copytext(anchor, 6))
		if(!num) num = 0
		return num + 1
	if(findtext(anchor, "CENTER"))
		var/base = view_dist + 1
		var/sign_pos = findtextEx(anchor, "+")
		if(!sign_pos)
			sign_pos = findtextEx(anchor, "-")
		if(sign_pos)
			var/sign = copytext(anchor, sign_pos, sign_pos+1)
			var/num = text2num(copytext(anchor, sign_pos+1))
			if(!num) num = 0
			if(sign == "+")
				return base + num
			else
				return base - num
		return base
	return view_dist + 1

//RS Add: Robustly decode Y anchor like "SOUTH+3", "NORTH-1", "CENTER-2", numeric (Lira, August 2025)
/obj/screen/movable/proc/decode_anchor_Y(anchor)
	var/view_dist = world.view
	if(isnum(anchor))
		return text2num(anchor)
	if(findtext(anchor, "NORTH-"))
		var/num = text2num(copytext(anchor, 7))
		if(!num) num = 0
		return view_dist*2 + 1 - num
	if(findtext(anchor, "SOUTH+"))
		var/num = text2num(copytext(anchor, 7))
		if(!num) num = 0
		return num + 1
	if(findtext(anchor, "CENTER"))
		var/base = view_dist + 1
		var/sign_pos = findtextEx(anchor, "+")
		if(!sign_pos)
			sign_pos = findtextEx(anchor, "-")
		if(sign_pos)
			var/sign = copytext(anchor, sign_pos, sign_pos+1)
			var/num = text2num(copytext(anchor, sign_pos+1))
			if(!num) num = 0
			if(sign == "+")
				return base + num
			else
				return base - num
		return base
	return view_dist + 1

//RS Add: Ensure we have a stable drag offset even if first event is MouseDrag (Lira, August 2025)
/obj/screen/movable/proc/ensure_drag_offset(list/PM)
	if(isnum(drag_off_x) && isnum(drag_off_y))
		return
	if(!PM || !PM["screen-loc"])
		return
	var/list/screen_loc_params = splittext(PM["screen-loc"], ",")
	var/list/screen_loc_X = splittext(screen_loc_params[1], ":")
	var/list/screen_loc_Y = splittext(screen_loc_params[2], ":")
	var/mouse_tile_X = text2num(screen_loc_X[1])
	var/mouse_tile_Y = text2num(screen_loc_Y[1])
	var/mouse_pix_X = (screen_loc_X.len >= 2) ? text2num(screen_loc_X[2]) : 0
	var/mouse_pix_Y = (screen_loc_Y.len >= 2) ? text2num(screen_loc_Y[2]) : 0
	var/mouse_abs_x = _abs_px(mouse_tile_X, mouse_pix_X)
	var/mouse_abs_y = _abs_px(mouse_tile_Y, mouse_pix_Y)
	var/list/op = get_current_pix_offsets()
	var/list/ot = get_current_tile_indices()
	var/obj_abs_x = _abs_px(ot[1], op[1])
	var/obj_abs_y = _abs_px(ot[2], op[2])
	drag_off_x = obj_abs_x - mouse_abs_x
	drag_off_y = obj_abs_y - mouse_abs_y

//Snap Screen Object
//Tied to the grid, snaps to the nearest turf

/obj/screen/movable/snap
	snap2grid = TRUE

//RS Add: Runs before any click to prevent drags from registering as a click (Lira, August 2025)
/client/Click(atom/object, location, control, params)
	var/obj/screen/movable/M = object
	if(istype(M))
		if(M.moved)
			M.moved = FALSE
			return
	return ..()

//RS Add: Begin pixel-smooth dragging when mouse is pressed (Lira, August 2025)
/obj/screen/movable/MouseDown(location, control, params)
	. = ..()
	var/client/C = usr?.client
	if(!C)
		return .
	dragging = TRUE
	C.drag_target = src
	moved = FALSE

	// Capture the grab-point offset including tile absolute delta so no initial snap
	var/list/PM = params2list(params)
	if(PM && PM["screen-loc"])
		var/list/screen_loc_params = splittext(PM["screen-loc"], ",")
		var/list/screen_loc_X = splittext(screen_loc_params[1], ":")
		var/list/screen_loc_Y = splittext(screen_loc_params[2], ":")
		var/mouse_tile_X = text2num(screen_loc_X[1])
		var/mouse_tile_Y = text2num(screen_loc_Y[1])
		var/mouse_pix_X = (screen_loc_X.len >= 2) ? text2num(screen_loc_X[2]) : 0
		var/mouse_pix_Y = (screen_loc_Y.len >= 2) ? text2num(screen_loc_Y[2]) : 0
		var/mouse_abs_x = _abs_px(mouse_tile_X, mouse_pix_X)
		var/mouse_abs_y = _abs_px(mouse_tile_Y, mouse_pix_Y)
		var/list/op = get_current_pix_offsets()
		var/list/ot = get_current_tile_indices()
		var/obj_abs_x = _abs_px(ot[1], op[1])
		var/obj_abs_y = _abs_px(ot[2], op[2])
		drag_off_x = obj_abs_x - mouse_abs_x
		drag_off_y = obj_abs_y - mouse_abs_y
	return .

//RS Add: End drag when mouse released anywhere (Lira, August 2025)
/obj/screen/movable/MouseUp(location, control, params)
	. = ..()
	var/client/C = usr?.client
	if(C && C.drag_target == src)
		C.drag_target = null
	dragging = FALSE
	return .

/obj/screen/movable/MouseDrop(over_object, src_location, over_location, src_control, over_control, params) //RS Edit: Updated for fluid drag to preserve offset (Lira, August 2025)
	var/list/PM = params2list(params)

	//No screen-loc information? abort.
	if(!PM || !PM["screen-loc"])
		return

	//Split screen-loc up into X+Pixel_X and Y+Pixel_Y
	var/list/screen_loc_params = splittext(PM["screen-loc"], ",")

	//Split X+Pixel_X up into list(X, Pixel_X)
	var/list/screen_loc_X = splittext(screen_loc_params[1],":")
	//Split Y+Pixel_Y up into list(Y, Pixel_Y)
	var/list/screen_loc_Y = splittext(screen_loc_params[2],":")

	if(snap2grid) //Discard Pixel Values
		var/tile_x = text2num(screen_loc_X[1])
		var/tile_y = text2num(screen_loc_Y[1])
		screen_loc = "[encode_screen_X(tile_x)],[encode_screen_Y(tile_y)]"
	else //Use absolute pixel math with preserved grab offset and clamp into viewport
		var/mouse_abs_x = _abs_px(text2num(screen_loc_X[1]), (screen_loc_X.len >= 2) ? text2num(screen_loc_X[2]) : 0)
		var/mouse_abs_y = _abs_px(text2num(screen_loc_Y[1]), (screen_loc_Y.len >= 2) ? text2num(screen_loc_Y[2]) : 0)
		var/new_abs_x = _clamp_abs(mouse_abs_x + (isnum(drag_off_x) ? drag_off_x : x_off))
		var/new_abs_y = _clamp_abs(mouse_abs_y + (isnum(drag_off_y) ? drag_off_y : y_off))
		var/tile_x = round(new_abs_x / 32) + 1
		var/tile_y = round(new_abs_y / 32) + 1
		var/pix_x = new_abs_x % 32
		var/pix_y = new_abs_y % 32
		screen_loc = "[encode_screen_X(tile_x)]:[pix_x],[encode_screen_Y(tile_y)]:[pix_y]"

	//Drop complete; clear preserved offset now
	drag_off_x = null
	drag_off_y = null

//RS Add: Continuously move while dragging for smoother UX (Lira, August 2025)
/obj/screen/movable/MouseDrag(over_object, src_location, over_location, src_control, over_control, params)
	var/list/PM = params2list(params)
	ensure_drag_offset(PM)

	// No screen-loc information? abort.
	if(!PM || !PM["screen-loc"])
		return

	// Split screen-loc up into X+Pixel_X and Y+Pixel_Y
	var/list/screen_loc_params = splittext(PM["screen-loc"], ",")

	// Split X+Pixel_X up into list(X, Pixel_X) and compute absolute
	var/list/screen_loc_X = splittext(screen_loc_params[1],":")
	var/list/screen_loc_Y = splittext(screen_loc_params[2],":")

	if(snap2grid)
		var/tile_x = text2num(screen_loc_X[1])
		var/tile_y = text2num(screen_loc_Y[1])
		screen_loc = "[encode_screen_X(tile_x)],[encode_screen_Y(tile_y)]"
	else
		var/mouse_abs_x = _abs_px(text2num(screen_loc_X[1]), (screen_loc_X.len >= 2) ? text2num(screen_loc_X[2]) : 0)
		var/mouse_abs_y = _abs_px(text2num(screen_loc_Y[1]), (screen_loc_Y.len >= 2) ? text2num(screen_loc_Y[2]) : 0)
		var/new_abs_x = _clamp_abs(mouse_abs_x + (isnum(drag_off_x) ? drag_off_x : x_off))
		var/new_abs_y = _clamp_abs(mouse_abs_y + (isnum(drag_off_y) ? drag_off_y : y_off))
		var/tile_x = floor(new_abs_x / 32) + 1
		var/tile_y = floor(new_abs_y / 32) + 1
		var/pix_x = new_abs_x % 32
		var/pix_y = new_abs_y % 32
		screen_loc = "[encode_screen_X(tile_x)]:[pix_x],[encode_screen_Y(tile_y)]:[pix_y]"
	moved = TRUE

//RS Add: Create drag target var (Lira, August 2025)
/client/var/obj/screen/movable/drag_target

//RS Add: Client-driven pixel-smooth drag follow even while over same UI (Lira, August 2025)
/client/MouseMove(atom/over_object, src_location, over_location, src_control, over_control, params)
	// If not dragging a screen object, default behavior
	if(!drag_target || !drag_target.dragging)
		return ..()

	var/list/PM = params2list(params)
	if(!PM || !PM["screen-loc"]) // No screen info; fall back to default
		return ..()

	// Parse screen-loc and update the dragged object's position using absolute pixels with clamping
	var/list/screen_loc_params = splittext(PM["screen-loc"], ",")
	var/list/screen_loc_X = splittext(screen_loc_params[1],":")
	var/list/screen_loc_Y = splittext(screen_loc_params[2],":")

	if(drag_target.snap2grid)
		var/tile_x = text2num(screen_loc_X[1])
		var/tile_y = text2num(screen_loc_Y[1])
		drag_target.screen_loc = "[drag_target.encode_screen_X(tile_x)],[drag_target.encode_screen_Y(tile_y)]"
	else
		var/mouse_abs_x = drag_target._abs_px(text2num(screen_loc_X[1]), (screen_loc_X.len >= 2) ? text2num(screen_loc_X[2]) : 0)
		var/mouse_abs_y = drag_target._abs_px(text2num(screen_loc_Y[1]), (screen_loc_Y.len >= 2) ? text2num(screen_loc_Y[2]) : 0)
		var/new_abs_x = drag_target._clamp_abs(mouse_abs_x + (isnum(drag_target.drag_off_x) ? drag_target.drag_off_x : drag_target.x_off))
		var/new_abs_y = drag_target._clamp_abs(mouse_abs_y + (isnum(drag_target.drag_off_y) ? drag_target.drag_off_y : drag_target.y_off))
		var/tile_x = floor(new_abs_x / 32) + 1
		var/tile_y = floor(new_abs_y / 32) + 1
		var/pix_x = new_abs_x % 32
		var/pix_y = new_abs_y % 32
		drag_target.screen_loc = "[drag_target.encode_screen_X(tile_x)]:[pix_x],[drag_target.encode_screen_Y(tile_y)]:[pix_y]"

	drag_target.moved = TRUE
	return ..()

/obj/screen/movable/proc/encode_screen_X(X)
	var/view_dist = world.view
	if(view_dist)
		view_dist = view_dist
	if(X > view_dist+1)
		. = "EAST-[view_dist *2 + 1-X]"
	else if(X < view_dist +1)
		. = "WEST+[X-1]"
	else
		. = "CENTER"

/obj/screen/movable/proc/decode_screen_X(X)
	var/view_dist = world.view
	if(view_dist)
		view_dist = view_dist
	//Find EAST/WEST implementations
	if(findtext(X,"EAST-"))
		var/num = text2num(copytext(X,6)) //Trim EAST-
		if(!num)
			num = 0
		. = view_dist*2 + 1 - num
	else if(findtext(X,"WEST+"))
		var/num = text2num(copytext(X,6)) //Trim WEST+
		if(!num)
			num = 0
		. = num+1
	else if(findtext(X,"CENTER"))
		. = view_dist+1

/obj/screen/movable/proc/encode_screen_Y(Y)
	var/view_dist = world.view
	if(view_dist)
		view_dist = view_dist
	if(Y > view_dist+1)
		. = "NORTH-[view_dist*2 + 1-Y]"
	else if(Y < view_dist+1)
		. = "SOUTH+[Y-1]"
	else
		. = "CENTER"

/obj/screen/movable/proc/decode_screen_Y(Y)
	var/view_dist = world.view
	if(view_dist)
		view_dist = view_dist
	if(findtext(Y,"NORTH-"))
		var/num = text2num(copytext(Y,7)) //Trim NORTH-
		if(!num)
			num = 0
		. = view_dist*2 + 1 - num
	else if(findtext(Y,"SOUTH+"))
		var/num = text2num(copytext(Y,7)) //Time SOUTH+
		if(!num)
			num = 0
		. = num+1
	else if(findtext(Y,"CENTER"))
		. = view_dist+1

//Debug procs
/client/proc/test_movable_UI()
	set category = "Debug"
	set name = "Spawn Movable UI Object"

	var/obj/screen/movable/M = new()
	M.name = "Movable UI Object"
	M.icon_state = "block"
	M.maptext = "Movable"
	M.maptext_width = 64

	var/screen_l = tgui_input_text(usr,"Where on the screen? (Formatted as 'X,Y' e.g: '1,1' for bottom left)","Spawn Movable UI Object")
	if(!screen_l)
		return

	M.screen_loc = screen_l

	screen += M


/client/proc/test_snap_UI()
	set category = "Debug"
	set name = "Spawn Snap UI Object"

	var/obj/screen/movable/snap/S = new()
	S.name = "Snap UI Object"
	S.icon_state = "block"
	S.maptext = "Snap"
	S.maptext_width = 64

	var/screen_l = tgui_input_text(usr,"Where on the screen? (Formatted as 'X,Y' e.g: '1,1' for bottom left)","Spawn Snap UI Object")
	if(!screen_l)
		return

	S.screen_loc = screen_l

	screen += S
