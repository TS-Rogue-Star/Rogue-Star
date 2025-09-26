/proc/add_trait_to_species(var/datum/species, var/traitpath, var/datum/trait/T)
	var/category = T.category
	switch(category)
		if(-INFINITY to -0.1)
			negative_traits_map[species][traitpath] = T
		if(0)
			neutral_traits_map[species][traitpath] = T
		if(0.1 to INFINITY)
			positive_traits_map[species][traitpath] = T
