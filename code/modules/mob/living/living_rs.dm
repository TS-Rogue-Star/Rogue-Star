/mob/living
	/// Shadekin Vars
	var/flicker_time = 10
	var/flicker_break_chance = 0
	var/flicker_color = LIGHT_COLOR_INCANDESCENT_TUBE //Ok so, yes. You are looking at this right. It's set to LIGHT_COLOR_INCANDESCENT_TUBE even though there is technically LIGHT_COLOR_INCANDESCENT_BULB as well. They're CLOSE ENOUGH that it's not really too noticible. If I made it so the flicker var detected the light fixture type and that you didn't have the color set to something custom, it'd take so much extra code my head would explode. So, instead, you get this. If you want to fix this, please feel free to as I'd be happy to see that.
