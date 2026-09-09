//RS FILE
/proc/find_opposite_turf(var/atom/movable/to_move,var/atom/source,var/atom/target)	//This finds the turf on the opposite side of the target gate from where you are
	var/offset_x = clamp(source.x - to_move.x,-1,1)										//used for more smooth teleporting
	var/offset_y = clamp(source.y - to_move.y,-1,1)

	var/turf/temptarg = locate((target.x + offset_x),(target.y + offset_y),target.z)

	return temptarg

/proc/find_random_adjacent_turf(var/atom/target,var/check_density = TRUE)
	var/list/potential_turfs = list()
	var/turf/ourturf = get_turf(target)
	for(var/turf/T in orange(1, ourturf))
		if(T == ourturf)
			continue
		if(check_density && T.check_density(FALSE,TRUE))
			continue
		potential_turfs |= T

	if(potential_turfs.len <= 0)
		return FALSE
	return pick(potential_turfs)

/proc/find_opposite_side_or_randomize(var/atom/movable/to_teleport,var/atom/movable/source,var/atom/movable/target)
	var/turf/destination
	destination = find_opposite_turf(to_teleport,source,target)
	if(destination)
		if(destination.check_density(FALSE,TRUE))
			destination = null
	if(!destination)
		destination = find_random_adjacent_turf(target)

	return destination

/proc/teleport_to_opposite_side_or_randomize(var/atom/movable/to_teleport,var/atom/movable/source,var/atom/movable/target)
	to_teleport.forceMove(find_opposite_side_or_randomize(to_teleport,source,target))
