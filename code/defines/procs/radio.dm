#define TELECOMMS_RECEPTION_NONE 0
#define TELECOMMS_RECEPTION_SENDER 1
#define TELECOMMS_RECEPTION_RECEIVER 2
#define TELECOMMS_RECEPTION_BOTH 3

/proc/register_radio(source, old_frequency, new_frequency, radio_filter)
	if(old_frequency)
		radio_controller.remove_object(source, old_frequency)
	if(new_frequency)
		return radio_controller.add_object(source, new_frequency, radio_filter)

/proc/unregister_radio(source, frequency)
	if(radio_controller)
		radio_controller.remove_object(source, frequency)

// RS Add: Arrivals Notification Z-Fix (Lira, April 2026)
/proc/get_telecomms_reachable_zlevels(var/source_z, var/channel = "Common")
	if(!source_z || !radio_controller)
		return list()

	var/frequency = radiochannels[channel]
	if(!frequency)
		return list()

	var/datum/signal/signal = new
	signal.transmission_method = TRANSMISSION_SUBSPACE
	signal.frequency = frequency
	signal.data = list(
		"slow" = 0,
		"message" = "TELECOMMS_PROBE_[world.time]_[source_z]_[frequency]_[rand(1, 1000000)]",
		"compression" = 0,
		"traffic" = 0,
		"type" = SIGNAL_TEST,
		"reject" = 0,
		"done" = 0,
		"level" = source_z,
		"realname" = "telecomms probe"
	)

	for(var/obj/machinery/telecomms/receiver/R in telecomms_list)
		R.receive_signal(signal)

	if(!signal.data["done"] && using_map.use_overmap)
		for(var/obj/machinery/telecomms/allinone/A in telecomms_list)
			if(!A.on)
				continue
			if(!A.is_freq_listening(signal))
				continue

			var/list/map_levels = using_map.get_map_levels(A.z, TRUE, A.overmap_range)
			var/list/signal_levels = list()
			signal_levels += signal.data["level"]
			var/list/overlap = map_levels & signal_levels
			if(!overlap.len)
				continue

			signal.data["done"] = 1
			signal.data["compression"] = 0
			signal.data["level"] = map_levels
			break

	var/list/reachable_levels = list()
	if(islist(signal.data["level"]))
		reachable_levels |= signal.data["level"]
	else if(signal.data["level"])
		reachable_levels += signal.data["level"]

	return reachable_levels

// RS Add: Arrivals Notification Z-Fix (Lira, April 2026)
/proc/get_station_network_zlevels(var/channel = "Common")
	var/list/reachable_levels = using_map.station_levels.Copy()
	if(!reachable_levels.len)
		return reachable_levels

	for(var/source_z in using_map.station_levels)
		reachable_levels |= get_telecomms_reachable_zlevels(source_z, channel)

	return reachable_levels

/proc/get_frequency_name(var/display_freq)
	var/freq_text

	// the name of the channel
	if(display_freq in ANTAG_FREQS)
		freq_text = "#unkn"
	else
		for(var/channel in radiochannels)
			if(radiochannels[channel] == display_freq)
				freq_text = channel
				break

	// --- If the frequency has not been assigned a name, just use the frequency as the name ---
	if(!freq_text)
		freq_text = format_frequency(display_freq)

	return freq_text

/datum/reception
	var/obj/machinery/message_server/message_server = null
	var/telecomms_reception = TELECOMMS_RECEPTION_NONE
	var/message = ""

/datum/receptions
	var/obj/machinery/message_server/message_server = null
	var/sender_reception = TELECOMMS_RECEPTION_NONE
	var/list/receiver_reception = new

/proc/get_message_server()
	if(message_servers)
		for (var/obj/machinery/message_server/MS in message_servers)
			if(MS.active)
				return MS
	return null

/proc/check_signal(var/datum/signal/signal)
	return signal && signal.data["done"]

/proc/get_sender_reception(var/atom/sender, var/datum/signal/signal)
	return check_signal(signal) ? TELECOMMS_RECEPTION_SENDER : TELECOMMS_RECEPTION_NONE

/proc/get_receiver_reception(var/receiver, var/datum/signal/signal)
	if(receiver && check_signal(signal))
		var/turf/pos = get_turf(receiver)
		if(pos && (pos.z in signal.data["level"]))
			return TELECOMMS_RECEPTION_RECEIVER
	return TELECOMMS_RECEPTION_NONE

/proc/get_reception(var/atom/sender, var/receiver, var/message = "", var/do_sleep = 1)
	var/datum/reception/reception = new

	// check if telecomms I/O route 1459 is stable
	reception.message_server = get_message_server()

	var/datum/signal/signal = sender.telecomms_process(do_sleep)	// Be aware that this proc calls sleep, to simulate transmition delays
	reception.telecomms_reception |= get_sender_reception(sender, signal)
	reception.telecomms_reception |= get_receiver_reception(receiver, signal)
	reception.message = signal && signal.data["compression"] > 0 ? Gibberish(message, signal.data["compression"] + 50) : message

	return reception

/proc/get_receptions(var/atom/sender, var/list/atom/receivers, var/do_sleep = 1)
	var/datum/receptions/receptions = new
	receptions.message_server = get_message_server()

	var/datum/signal/signal
	if(sender)
		signal = sender.telecomms_process(do_sleep)
		receptions.sender_reception = get_sender_reception(sender, signal)

	for(var/atom/receiver in receivers)
		if(!signal)
			signal = receiver.telecomms_process()
		receptions.receiver_reception[receiver] = get_receiver_reception(receiver, signal)

	return receptions
