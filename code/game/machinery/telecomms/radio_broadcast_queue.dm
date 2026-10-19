///////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2026: Radio Optimize //
///////////////////////////////////////////////////////////////////

GLOBAL_DATUM_INIT(radio_broadcast_queue, /datum/radio_broadcast_queue, new)

/datum/radio_broadcast_queue
	var/list/pending = list()
	var/processing = FALSE

/datum/radio_broadcast_queue/proc/enqueue(proc_path, list/broadcast_arguments)
	var/datum/callback/broadcast = new(GLOBAL_PROC, proc_path)
	broadcast.arguments = broadcast_arguments.Copy()
	for(var/i = 1 to length(broadcast.arguments))
		if(!islist(broadcast.arguments[i]))
			continue
		var/list/values = broadcast.arguments[i]
		values = values.Copy()
		for(var/j = 1 to length(values))
			var/datum/multilingual_say_piece/piece = values[j]
			if(istype(piece))
				values[j] = new /datum/multilingual_say_piece(piece.speaking, piece.message)
		broadcast.arguments[i] = values
	pending += broadcast
	if(!processing)
		drain()
	return TRUE

/datum/radio_broadcast_queue/proc/drain()
	set waitfor = FALSE
	processing = TRUE
	usr = null
	while(length(pending))
		CHECK_TICK
		var/datum/callback/broadcast = pending[1]
		pending.Cut(1, 2)
		try
			broadcast.Invoke()
		catch(var/exception/error)
			report_error(error)
		broadcast.arguments = null
		qdel(broadcast)
	processing = FALSE

/datum/radio_broadcast_queue/proc/report_error(exception/error)
	world.Error(error, src)
