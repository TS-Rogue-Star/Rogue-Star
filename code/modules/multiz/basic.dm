// If you add a more comprehensive system, just untick this file.
var/list/z_levels = list()// Each bit re... haha just kidding this is a list of bools now

// If the height is more than 1, we mark all contained levels as connected.
/obj/effect/landmark/map_data/New()
	for(var/i = (z - height + 1) to (z-1))
		if (z_levels.len <i)
			z_levels.len = i
		z_levels[i] = TRUE

/obj/effect/landmark/map_data/Initialize()
	..()
	return INITIALIZE_HINT_QDEL

// The storage of connections between adjacent levels means some bitwise magic is needed.
/proc/HasAbove(var/z)
	if(z >= world.maxz || z < 1 || z > z_levels.len)
		return 0
	return z_levels[z]

/proc/HasBelow(var/z)
	if(z > world.maxz || z < 2 || (z-1) > z_levels.len)
		return 0
	return z_levels[z-1]

// Thankfully, no bitwise magic is needed here.
/proc/GetAbove(var/atom/atom)
	var/turf/turf = get_turf(atom)
	if(!turf)
		return null
	return HasAbove(turf.z) ? get_step(turf, UP) : null

/proc/GetBelow(var/atom/atom)
	var/turf/turf = get_turf(atom)
	if(!turf)
		return null
	return HasBelow(turf.z) ? get_step(turf, DOWN) : null

/proc/GetConnectedZlevels(z)
	. = list(z)
	for(var/level = z, HasBelow(level), level--)
		. |= level-1
	for(var/level = z, HasAbove(level), level++)
		. |= level+1

/proc/AreConnectedZLevels(var/zA, var/zB)
	return zA == zB || (zB in GetConnectedZlevels(zA))

/proc/get_zstep(ref, dir)
	if(dir == UP)
		. = GetAbove(ref)
	else if (dir == DOWN)
		. = GetBelow(ref)
	else
		. = get_step(ref, dir)

//RS ADD START
/proc/CheckMobZConnection(var/mob/living/A, var/mob/living/B)
	var/turf/Aturf = get_turf(A)
	var/turf/Bturf = get_turf(B)
	if(Aturf.z == Bturf.z)
		return TRUE
	if(AreConnectedZLevels(Aturf.z, Bturf.z))
		return TRUE
	var/obj/effect/overmap/visitable/V = get_overmap_sector(Aturf.z)
	if(!V)
		return FALSE
	if(!(Aturf.z in V.map_z))
		return FALSE
	if(!(Bturf.z in V.map_z))
		return FALSE
	return TRUE
//RS ADD END
