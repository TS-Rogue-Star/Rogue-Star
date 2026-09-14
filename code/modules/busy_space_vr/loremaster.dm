//I AM THE LOREMASTER, ARE YOU THE GATEKEEPER?

var/datum/lore/loremaster/loremaster = new/datum/lore/loremaster

/datum/lore/loremaster
	var/list/organizations = list()
	// RS Add Start: Character Designer - Identity Tab (Lira, September 2026)
	var/list/locations = list()
	var/list/locations_by_preference_value = list()
	var/list/religions = list()
	// RS Add End

/datum/lore/loremaster/New()

	var/list/paths = subtypesof(/datum/lore/organization)
	for(var/path in paths)
		// Some intermediate paths are not real organizations (ex. /datum/lore/organization/mil). Only do ones with names
		var/datum/lore/organization/instance = path
		if(initial(instance.name))
			instance = new path()
			organizations[path] = instance

	// RS Add Start: Character Designer - Identity Tab (Lira, September 2026)
	var/list/location_paths = subtypesof(/datum/lore/location)
	for(var/location_path in location_paths)
		var/datum/lore/location/location = location_path
		if(initial(location.name))
			location = new location_path()
			locations[location_path] = location
			if(istext(location.preference_value) && length(location.preference_value))
				locations_by_preference_value[location.preference_value] = location

	var/list/religion_paths = subtypesof(/datum/lore/religion)
	for(var/religion_path in religion_paths)
		var/datum/lore/religion/religion = religion_path
		if(initial(religion.name))
			religion = new religion_path()
			religions[religion_path] = religion
	// RS Add End
