var/datum/planet/moonbase/planet_moonbase = null

/datum/time/moonbase
	seconds_in_day = 24 HOURS

/datum/planet/moonbase
	name = "Virgo 3x"
	desc = "An airless rock in far orbit around Virgo Prime. Which seemingly barren, it posses convenient transfer orbits, and holds many secrets..."
	current_time = new /datum/time/moonbase()
//	expected_z_levels = list(1) // This is defined elsewhere.
	planetary_wall_type = /turf/unsimulated/wall/planetary

/datum/planet/moonbase/New()
	..()
	planet_moonbase = src
	weather_holder = new /datum/weather_holder/moonbase(src)

/datum/planet/moonbase/update_sun()
	..()
	var/datum/time/time = current_time
	var/length_of_day = time.seconds_in_day / 10 / 60 / 60
	var/noon = length_of_day / 2
	var/distance_from_noon = abs(text2num(time.show_time("hh")) - noon)
	sun_position = distance_from_noon / noon
	sun_position = abs(sun_position - 1)

	var/low_brightness = null
	var/high_brightness = null

	var/low_color = null
	var/high_color = null
	var/min = 0

	switch(sun_position)
		if(0 to 0.20) // Night
			low_brightness = 0.3
			low_color = "#000066"

			high_brightness = 0.5
			high_color = "#66004D"
			min = 0

		if(0.20 to 0.30) // Twilight
			low_brightness = 0.5
			low_color = "#66004D"

			high_brightness = 0.9
			high_color = "#CC3300"
			min = 0.40

		if(0.30 to 0.40) // Sunrise/set
			low_brightness = 0.9
			low_color = "#CC3300"

			high_brightness = 3.0
			high_color = "#FF9933"
			min = 0.50

		if(0.40 to 1.00) // Noon
			low_brightness = 3.0
			low_color = "#DDDDDD"

			high_brightness = 10.0
			high_color = "#FFFFFF"
			min = 0.70

	var/interpolate_weight = (abs(min - sun_position)) * 4
	var/weather_light_modifier = 1
	if(weather_holder && weather_holder.current_weather)
		weather_light_modifier = weather_holder.current_weather.light_modifier

	var/new_brightness = (LERP(low_brightness, high_brightness, interpolate_weight) ) * weather_light_modifier

	var/new_color = null
	if(weather_holder && weather_holder.current_weather && weather_holder.current_weather.light_color)
		new_color = weather_holder.current_weather.light_color
	else
		var/list/low_color_list = hex2rgb(low_color)
		var/low_r = low_color_list[1]
		var/low_g = low_color_list[2]
		var/low_b = low_color_list[3]

		var/list/high_color_list = hex2rgb(high_color)
		var/high_r = high_color_list[1]
		var/high_g = high_color_list[2]
		var/high_b = high_color_list[3]

		var/new_r = LERP(low_r, high_r, interpolate_weight)
		var/new_g = LERP(low_g, high_g, interpolate_weight)
		var/new_b = LERP(low_b, high_b, interpolate_weight)

		new_color = rgb(new_r, new_g, new_b)

	spawn(1)
		update_sun_deferred(new_brightness, new_color)


/datum/weather_holder/moonbase
	temperature = TCMB
	allowed_weather_types = list(
		WEATHER_CLEAR			= new /datum/weather/moonbase/clear(),
		)
	roundstart_weather_chances = list(
		WEATHER_CLEAR		= 100
		)

/datum/weather/moonbase
	name = "moonbase"
	temp_high = 2.7
	temp_low = 2.7

/datum/weather/moonbase/clear
	name = "clear"
	transition_chances = list(
		WEATHER_CLAER = 100)
	transition_messages = list(
	"The sky turns static and cold."
		)
	sky_visible = TRUE
	observed_message = "The sky is clear."
	imminent_transition_message = "The sky is returning to its normal emptiness."
