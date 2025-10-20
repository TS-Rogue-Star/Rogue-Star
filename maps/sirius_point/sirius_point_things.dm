/obj/structure/window/reinforced/full/dome
	name = "hybrid window"
	desc = "A window made of advanced composite materials. The light glimmers in pretty colors off the surface. Looks like it could survive an asteroid strike point-blank."
	icon_state = "rwindow-full"
	basestate = "rwindow"
	fulltile = TRUE
	maxhealth = 300.0//a reinforced window is 40
	maximal_heat = T0C + 7000
	damage_per_fire_tick = 1.0
	force_threshold = 10
	flags = 0

//exterior floor decal
/obj/effect/floor_decal/milspec/monotile/moonbase
	color = "#b8c0c4"

/obj/effect/floor_decal/emblem/siriuspoint
	icon = 'maps/sirius_point/sirius_point_decals.dmi'
	icon_state = "sirius_point"
/obj/effect/floor_decal/emblem/siriuspoint/center
	icon_state = "sirius_point_center"

// ### Wall Machines On Full Windows ###
// To make sure wall-mounted machines placed on full-tile windows are clickable they must be above the window
//
/obj/item/device/radio/intercom
	layer = ABOVE_WINDOW_LAYER
/obj/item/weapon/storage/secure/safe
	layer = ABOVE_WINDOW_LAYER
/obj/machinery/airlock_sensor
	layer = ABOVE_WINDOW_LAYER
/obj/machinery/alarm
	layer = ABOVE_WINDOW_LAYER
/obj/machinery/button
	layer = ABOVE_WINDOW_LAYER
/obj/machinery/access_button
	layer = ABOVE_WINDOW_LAYER
/obj/machinery/computer/guestpass
	layer = ABOVE_WINDOW_LAYER
/obj/machinery/computer/security/telescreen
	layer = ABOVE_WINDOW_LAYER
/obj/machinery/door_timer
	layer = ABOVE_WINDOW_LAYER
/obj/machinery/embedded_controller
	layer = ABOVE_WINDOW_LAYER
/obj/machinery/firealarm
	layer = ABOVE_WINDOW_LAYER
/obj/machinery/flasher
	layer = ABOVE_WINDOW_LAYER
/obj/machinery/keycard_auth
	layer = ABOVE_WINDOW_LAYER
/obj/machinery/light_switch
	layer = ABOVE_WINDOW_LAYER
/obj/machinery/mineral/processing_unit_console
	layer = ABOVE_WINDOW_LAYER
/obj/machinery/mineral/stacking_unit_console
	layer = ABOVE_WINDOW_LAYER
/obj/machinery/newscaster
	layer = ABOVE_WINDOW_LAYER
/obj/machinery/power/apc
	layer = ABOVE_WINDOW_LAYER
/obj/machinery/requests_console
	layer = ABOVE_WINDOW_LAYER
/obj/machinery/status_display
	layer = ABOVE_WINDOW_LAYER
/obj/machinery/vending/wallmed1
	layer = ABOVE_WINDOW_LAYER
/obj/machinery/vending/wallmed2
	layer = ABOVE_WINDOW_LAYER
/obj/structure/fireaxecabinet
	layer = ABOVE_WINDOW_LAYER
/obj/structure/extinguisher_cabinet
	layer = ABOVE_WINDOW_LAYER
/obj/structure/mirror
	layer = ABOVE_WINDOW_LAYER
/obj/structure/noticeboard
	layer = ABOVE_WINDOW_LAYER
/obj/machinery/disposal/wall
	layer = ABOVE_WINDOW_LAYER

/obj/item/weapon/book/manual/rover_guide
	name = "Rover User's Guide"
	icon = 'icons/obj/library.dmi'
	icon_state ="book14"
	item_state = "book14"
	author = "Autumn"		 // Who wrote the thing, can be changed by pen or PC. It is not automatically assigned
	title = "Rover User's Guide"

/obj/item/weapon/book/manual/rover_guide/New()
	..()
	dat = {"<html>
				<head>
				<style>
				h1 {font-size: 18px; margin: 15px 0px 5px;}
				h2 {font-size: 15px; margin: 15px 0px 5px;}
				h3 {font-size: 13px; margin: 15px 0px 5px;}
				li {margin: 2px 0px 2px 15px;}
				ul {margin: 5px; padding: 0px;}
				ol {margin: 5px; padding: 0px 15px;}
				body {font-size: 13px; font-family: Verdana;}
				</style>
				</head>
				<body>
				<h1>Electric Rover Use</h1>
				<br>
				The bike is as easy to drive as walking, but there's a few things you'll need to know about repairing and refueling it.
				<br><br>
				Click to mount or dismount.
				<br>
				Ctrl-click to start the engine.
				<br>
				Alt-click to remove the keys.
				<br><br>
				<h1>Maintenance</h1>
				<br>
				Use a screwdriver on the rover or the trailer to open the maintenance hatch, then you can do any of the following things:
				<br>
				Use a crowbar to pry out the power cell for recharging or replacement.
				<br>
				Use a multitool to change the color!
				<br>
				Use a welding tool to repair any damage.
				<br><br>
				<h1>Trailer Usage</h1>
				<br>
				Drag a trailer onto the rover to connect it.
				<br>
				Drag a crate, locker, ore box, or friend onto the trailer to attach them to it. Then click the trailer again to detach the box.
				<br>
				Right-click on the trailer or rover and select 'unlatch' to remove the trailer.
				</body>
			</html>"}
