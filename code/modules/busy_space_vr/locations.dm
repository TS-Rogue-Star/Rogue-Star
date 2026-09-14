//////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2026: Hub for location lore //
//////////////////////////////////////////////////////////////////////////

/datum/lore/location
	var/name = ""
	var/preference_value
	var/kind = "unknown"
	var/parent_system
	var/desc = ""

/datum/lore/location/system
	kind = "system"
	var/overview

/datum/lore/location/planet
	kind = "planet"

/datum/lore/location/moon
	kind = "moon"

/datum/lore/location/compact
	kind = "compact"

/datum/lore/location/habitat
	kind = "habitat"

/datum/lore/location/flotilla
	kind = "flotilla"

// Sources: https://wiki.vore-station.net/index.php?title=Virgo-Erigone&oldid=10679
/datum/lore/location/system/virgo_erigone
	name = "Virgo-Erigone"
	preference_value = "Virgo-Erigone"
	desc = "An aging F-type main-sequence star also known as Virgo or Alat-Hahr. Its five numbered worlds include the phoron-rich brown dwarf Geret Baht (Virgo III), the Zorren homeworld Menhir (Virgo IV), and the outermost planet Mahir (Virgo V). NanoTrasen maintains extensive phoron mining and research operations in the system."

// Sources: /datum/locations/sol
/datum/lore/location/system/sol
	name = "Sol"
	preference_value = "Sol"
	desc = "The home system of humanity."

// Sources: /datum/trade_destination/nohio, /datum/event/lore_news/announce(), /datum/lore/organization/New()
/datum/lore/location/system/new_ohio
	name = "New Ohio"
	desc = "A Commonwealth frontier system in the Sagittarius Heights, on the border with the Skrell Consensus territory."

// Sources: /datum/lore/organization/gov/fyrds, /obj/item/weapon/entrepreneur/horoscope, https://wiki.vore-station.net/index.php?title=Unitary_Alliance_of_Salthan_Fyrds&oldid=10031
/datum/lore/location/system/myria
	name = "Myria"
	desc = "A fortified capital system of the Salthan Fyrds. Its principal world, Salthan, and the surrounding inhabited planets, moons, and orbital settlements form the Pact, the Alliance's founding military and administrative center."

// Sources: home_system_choices, /obj/item/weapon/storage/chewables/tobacco, https://ss13polaris.com/wiki/index.php?title=Alpha_Centauri&oldid=3926
/datum/lore/location/system/alpha_centauri
	name = "Alpha Centauri"
	desc = "A human-settled system containing biosphere-farming Kishar and its metal-rich industrial moon Anshar, along with the Heaven orbital complex."

// Sources: /datum/lore/organization/gov/commonwealth, https://wiki.vore-station.net/index.php?title=Commonwealth_of_Sol-Procyon&oldid=9940
/datum/lore/location/system/procyon
	name = "Procyon"
	preference_value = "Procyon"
	desc = "One of the Commonwealth's eponymous systems and one of its Big Five federal members, with major cultural, industrial, and economic influence."

// Sources: https://wiki.vore-station.net/index.php?title=Commonwealth_of_Sol-Procyon&oldid=9940
/datum/lore/location/system/altair
	name = "Altair"
	preference_value = "Altair"
	desc = "One of the Commonwealth's Big Five federal systems, with substantial cultural, industrial, and economic influence."

// Sources: /datum/locations/vir
/datum/lore/location/system/vir
	name = "Vir"
	desc = "A human system between the inner and outer regions of human-controlled space."

// Sources: /datum/locations/nyx
/datum/lore/location/system/nyx
	name = "Nyx"
	desc = "An outer frontier system centered on a red-dwarf flare star, with four planets and the substellar companion Erebus."

// Sources: /datum/locations/tau_ceti
/datum/lore/location/system/tau_ceti
	name = "Tau Ceti"
	desc = "A relatively populated system between the inner and outer regions of human-colonized space."

// Sources: /datum/locations/qerrvallis
/datum/lore/location/system/qerr_vallis
	name = "Qerr'Vallis"
	desc = "The Skrell home system. Its name translates as 'Star of the Royals' or 'Light of the Crown'."

// Sources: https://wiki.vore-station.net/index.php?title=Diona&oldid=9669
/datum/lore/location/system/epsilon_ursae_minoris
	name = "Epsilon Ursae Minoris"
	preference_value = "Epsilon Ursae Minoris"
	desc = "The triple-star system where the Skrell first made contact with the Dionaea, detecting immense gestalts within its stars."
	overview = "A triple-star system where the Skrell first made contact with the Dionaea."

// Sources: /datum/lore/codex/page/tajaran
/datum/lore/location/system/rarkajar
	name = "Rarkajar"
	desc = "The star system whose fourth planet, Meralar, is the cold homeworld of the Tajaran."

// Sources: https://wiki.vore-station.net/index.php?title=Nevreans&oldid=9757
/datum/lore/location/system/vilous
	name = "Vilous"
	desc = "The system containing Tal, the shared homeworld of Sergals and Nevreans. Stable space lanes and asteroid phoron deposits have made it a trading hub between the core and the periphery."

// Sources: home_system_choices, /datum/language/vulpkanin
/datum/lore/location/system/vazzend
	name = "Vazzend"
	desc = "The Vulpkanin home system. Its inhabitants use Canilunzt, combining growls, barks, yaps, and ear and tail movements."

// Sources: home_system_choices, https://wiki.vore-station.net/index.php?title=Backstory&oldid=10631
/datum/lore/location/system/kelezakata
	name = "Kelezakata"
	desc = "The home system of the Rapala, containing their homeworld Uh'Zata."

// Sources: /datum/locations/uueoa_esa
/datum/lore/location/system/uueoa_esa
	name = "Uueoa-Esa"
	desc = "The home system of the Unathi. Its name roughly translates to 'burning mother'."

// Sources: https://wiki.vore-station.net/index.php?title=Zaddat&oldid=10649
/datum/lore/location/system/vengeful_father
	name = "Vengeful Father"
	desc = "The system containing Xohok, the high-pressure Zaddat homeworld. The Zaddat are a client species of the Unathi Hegemony."

// Sources: home_system_choices, /datum/category_item/catalogue/fauna/vasilissan, https://wiki.vore-station.net/index.php?title=Vasilissans&oldid=9627
/datum/lore/location/system/antares
	name = "Antares"
	desc = "Antares contains Varilak, the humid jungle homeworld of the Vasilissans, whose architectural skill and natural silk have made them valued throughout Coreward Periphery colonies."

// Sources: home_system_choices, https://wiki.vore-station.net/index.php?title=Backstory&oldid=10631
/datum/lore/location/system/sanctum
	name = "Sanctum"
	desc = "An Elysian system containing the sharply contrasting worlds of Sanctorum and Infernum."

// Sources: https://wiki.vore-station.net/index.php?title=Alraune&oldid=9620, https://wiki.vore-station.net/index.php?title=Backstory&oldid=10631
/datum/lore/location/system/beta_carnelium_ventrum
	name = "Beta-Carnelium Ventrum"
	desc = "The system associated with the Alraune homeworld, Roanoke, a hot planet with a dense atmosphere, extensive wetlands, and tropical forests."

// Sources: /datum/lore/codex/page/akula/add_content()
/datum/lore/location/system/barkalis
	name = "Barkalis"
	desc = "The original home system of the pelagic Akula."

// Sources: /datum/lore/codex/page/human/add_content()
/datum/lore/location/planet/earth
	name = "Earth, Sol"
	preference_value = "Earth, Sol"
	parent_system = /datum/lore/location/system/sol
	desc = "Humanity's original homeworld and the center of the Commonwealth of Sol-Procyon."

// Sources: /datum/trade_destination/luna, /datum/lore/organization/tsc/nanotrasen
/datum/lore/location/moon/luna
	name = "Luna, Sol"
	preference_value = "Luna, Sol"
	parent_system = /datum/lore/location/system/sol
	desc = "The capital world of SolGov and host to NanoTrasen's corporate offices."

// Sources: /datum/trade_destination/mars
/datum/lore/location/planet/mars
	name = "Mars, Sol"
	preference_value = "Mars, Sol"
	parent_system = /datum/lore/location/system/sol
	desc = "A major industrial center in the Sol system."

// Sources: https://wiki.vore-station.net/index.php?title=Sol&oldid=10723
/datum/lore/location/planet/venus
	name = "Venus, Sol"
	preference_value = "Venus, Sol"
	parent_system = /datum/lore/location/system/sol
	desc = "A hostile hothouse world settled in enormous upper-atmosphere aerostats. Atmospheric harvesting feeds sprawling agricomplexes, making Venus a breadbasket of Sol."

// Sources: /obj/item/weapon/reagent_containers/food/drinks/bottle/small/ale, /obj/item/weapon/book/manual/anomaly_testing, https://ss13polaris.com/wiki/index.php?title=Sol&oldid=1631
/datum/lore/location/moon/titan
	name = "Titan, Sol"
	preference_value = "Titan, Sol"
	parent_system = /datum/lore/location/system/sol
	desc = "A frozen moon centered on hydrocarbon extraction, processing, and research; much of its working culture and economy revolves around the oil industry."

// Sources: /datum/lore/organization/tsc/vey_med, /datum/trade_destination/nohio
/datum/lore/location/planet/toledo
	name = "Toledo, New Ohio"
	preference_value = "Toledo, New Ohio"
	parent_system = /datum/lore/location/system/new_ohio
	desc = "An inhabited planet in the New Ohio system and home to major Vey-Medical research and development facilities."

// Sources: /datum/lore/organization/gov/fyrds, /obj/item/weapon/entrepreneur/horoscope, https://wiki.vore-station.net/index.php?title=Unitary_Alliance_of_Salthan_Fyrds&oldid=10031
/datum/lore/location/compact/the_pact
	name = "The Pact, Myria"
	preference_value = "The Pact, Myria"
	parent_system = /datum/lore/location/system/myria
	desc = "The Pact is the founding capital compact of the Myria system, joining Salthan with the system's other inhabited planets, moons, and orbital settlements. Although each member retains its own Fyrd and local government, they share military command, defensive infrastructure, and the administrative institutions of the Allied Council. Salthan remains the compact's dominant world and the cultural heart of the wider Unitary Alliance."

// Sources: home_system_choices, /obj/item/weapon/storage/chewables/tobacco, /obj/item/weapon/reagent_containers/food/drinks/chaitea
/datum/lore/location/planet/kishar
	name = "Kishar, Alpha Centauri"
	preference_value = "Kishar, Alpha Centauri"
	parent_system = /datum/lore/location/system/alpha_centauri
	desc = "A biosphere-farming world where spiced chai borders on a national drink."

// Sources: https://ss13polaris.com/wiki/index.php?title=Alpha_Centauri&oldid=3926
/datum/lore/location/moon/anshar
	name = "Anshar, Alpha Centauri"
	preference_value = "Anshar, Alpha Centauri"
	parent_system = /datum/lore/location/system/alpha_centauri
	desc = "A young, volcanically active moon of Kishar with a powerful magnetosphere that shields the planet from fierce stellar wind. Rich in metals, Anshar hosts most of the pair's industry and maintains a close, economically symbiotic relationship with Kishar."

// Sources: home_system_choices, https://ss13polaris.com/wiki/index.php?title=Alpha_Centauri&oldid=3926
/datum/lore/location/habitat/heaven_complex
	name = "Heaven Complex, Alpha Centauri"
	preference_value = "Heaven Complex, Alpha Centauri"
	parent_system = /datum/lore/location/system/alpha_centauri
	desc = "An orbital complex in the Alpha Centauri system."

// Sources: /datum/locations/kara, /datum/locations/kara/New(), /datum/locations/northern_star
/datum/lore/location/planet/kara
	name = "Kara, Vir"
	preference_value = "Kara, Vir"
	parent_system = /datum/lore/location/system/vir
	desc = "A cold gas giant surrounded by captured-asteroid moons used by many companies. The Northern Star colony is its most prominent installation."

// Sources: /datum/lore/codex/page/sif/add_content()
/datum/lore/location/planet/sif
	name = "Sif, Vir"
	preference_value = "Sif, Vir"
	parent_system = /datum/lore/location/system/vir
	desc = "A habitable garden world and the capital planet of Vir, with oceans, breathable air, lower gravity, and days over 32 hours long."

// Sources: /datum/locations/brinkburn
/datum/lore/location/planet/brinkburn
	name = "Brinkburn, Nyx"
	preference_value = "Brinkburn, Nyx"
	parent_system = /datum/lore/location/system/nyx
	desc = "A small, dry, habitable world whose dense ring system makes entering or leaving orbit difficult."

// Sources: /datum/locations/bimna, home_system_choices
/datum/lore/location/planet/binma
	name = "Binma, Tau Ceti"
	preference_value = "Binma, Tau Ceti"
	parent_system = /datum/lore/location/system/tau_ceti
	desc = "A medium-sized Tau Ceti world with a stable economy, a large academic population, and one of the sector's largest shipyards."

// Sources: https://wiki.vore-station.net/index.php?title=Skrell&oldid=9623, https://wiki.vore-station.net/index.php?title=Backstory&oldid=10631
/datum/lore/location/planet/qerr_balak
	name = "Qerr'balak, Qerr'Vallis"
	preference_value = "Qerr'balak, Qerr'valis"
	parent_system = /datum/lore/location/system/qerr_vallis
	desc = "The Skrell homeworld, with a humid atmosphere and extensive swamps and jungles."

// Sources: /datum/lore/codex/page/tajaran
/datum/lore/location/planet/meralar
	name = "Meralar, Rarkajar"
	preference_value = "Meralar, Rarkajar"
	parent_system = /datum/lore/location/system/rarkajar
	desc = "The Tajaran homeworld, a cold subarctic planet whose temperate regions cluster around its equator and tropical belt."

// Sources: https://wiki.vore-station.net/index.php?title=Nevreans&oldid=9757
/datum/lore/location/planet/tal
	name = "Tal, Vilous"
	preference_value = "Tal, Vilous"
	parent_system = /datum/lore/location/system/vilous
	desc = "The shared homeworld of Sergals and Nevreans in the Vilous system. Early conflict and conquest gave way to cooperation as equals; today their societies participate in the Vilous Central Authority."

// Sources: https://wiki.vore-station.net/index.php?title=Virgo-Erigone&oldid=10679
/datum/lore/location/planet/menhir
	name = "Menhir, Alat-Hahr"
	preference_value = "Menhir, Alat-Hahr"
	parent_system = /datum/lore/location/system/virgo_erigone
	desc = "The arid Zorren homeworld, once much more lush and rich in resources. An unknown cataclysm devastated its precursor civilization roughly 20,000 years ago. Its inhabitants continue the slow work of restoring the planet despite conflict between its kingdoms and outside corporate interference."

// Sources: https://wiki.vore-station.net/index.php?title=Vulpkanin&oldid=9614, home_system_choices
/datum/lore/location/planet/altam
	name = "Altam, Vazzend"
	preference_value = "Altam, Vazzend"
	parent_system = /datum/lore/location/system/vazzend
	desc = "The isolated Vulpkanin homeworld. Its people descend from a lost precursor colony that regressed to an industrial level after its offworld supply lines disappeared, then gradually rebuilt its civilization."

// Sources: home_system_choices, https://wiki.vore-station.net/index.php?title=Backstory&oldid=10631
/datum/lore/location/planet/uh_zata
	name = "Uh'Zata, Kelezakata"
	preference_value = "Uh'Zata, Kelezakata"
	parent_system = /datum/lore/location/system/kelezakata
	desc = "The homeworld of the Rapala."

// Sources: https://wiki.vore-station.net/index.php?title=Moghes&oldid=4081
/datum/lore/location/planet/moghes
	name = "Moghes, Uueoa-Esa"
	preference_value = "Moghes, Uuoea-Esa"
	parent_system = /datum/lore/location/system/uueoa_esa
	desc = "The average temperature on Moghes is a warm 23C. For the most part, the surface of Moghes is land, with massive saltwater lakes and seas dotting the supercontinent's surface. The tropical band on Moghes is mostly hot, rocky plains with occasional stretches of desert, while the temperate band is mostly swampland and savannas, while the poles are mostly swampland. The Northernmost polar region is a relatively cold plain, with very unusual life, as Moghes' moon Kharet is locked in orbit above this part of the planet. Moghes was once abundant in precious metals and other minerals, in modern times the supply is running low and the Unathi are forced to turn to other planets or asteroids to obtain what they need, this his had led to several conflicts where they've taken what they want from others. "

// Sources: https://wiki.vore-station.net/index.php?title=Zaddat&oldid=10649
/datum/lore/location/planet/xohok
	name = "Xohok, Vengeful Father"
	preference_value = "Xohok, Uuoea-Esa"
	parent_system = /datum/lore/location/system/vengeful_father
	desc = "The high-pressure, post-apocalyptic Zaddat homeworld. Its worsening conditions drive many Zaddat to seek work and living space in human territory."

// Sources: home_system_choices, https://wiki.vore-station.net/index.php?title=Vasilissans&oldid=9627
/datum/lore/location/planet/varilak
	name = "Varilak, Antares"
	preference_value = "Varilak, Antares"
	parent_system = /datum/lore/location/system/antares
	desc = "A humid, oxygen-rich jungle planet and the homeworld of the Vasilissans. Roughly sixty percent of Varilak is covered by ocean; its towering forests, giant native fauna, and unusually gem- and metal-rich crust support settlements woven from silk into enormous trees."

// Sources: https://wiki.vore-station.net/index.php?title=Sanctorum&oldid=10012, https://wiki.vore-station.net/index.php?title=Backstory&oldid=10631
/datum/lore/location/planet/sanctorum
	name = "Sanctorum, Sanctum"
	preference_value = "Sanctorum, Sanctum"
	parent_system = /datum/lore/location/system/sanctum
	desc = "A heavily engineered Elysian world of automated abundance and temperate beauty whose tranquil angel society is maintained through pervasive surveillance and social conditioning."

// Sources: https://wiki.vore-station.net/index.php?title=Infernum&oldid=10043, https://wiki.vore-station.net/index.php?title=Languages&oldid=10380, https://wiki.vore-station.net/index.php?title=Backstory&oldid=10631
/datum/lore/location/planet/infernum
	name = "Infernum, Sanctum"
	preference_value = "Infernum, Sanctum"
	parent_system = /datum/lore/location/system/sanctum
	desc = "A cold Elysian world in the Sanctum system, once a place of exile and now home to a libertine, anarcho-capitalist society. Its inhabitants rely on elaborate personal and corporate contracts. Its native demonic language uses deep chanting and is rarely spoken elsewhere because of the volume required."

// Sources: https://wiki.vore-station.net/index.php?title=Alraune&oldid=9620, https://wiki.vore-station.net/index.php?title=Backstory&oldid=10631
/datum/lore/location/planet/abundance_in_all_things_serene
	name = "Roanoke, Beta-Carnelium Ventrum"
	preference_value = "Abundance in All Things Serene, Beta-Carnelium Ventrum"
	parent_system = /datum/lore/location/system/beta_carnelium_ventrum
	desc = "The Alraune homeworld, known in Galactic Common as Roanoke. Its hot, dense atmosphere has a surface pressure of about 2.7 atmospheres. Oceans and tropical marshlands cover most of the planet, with rainforests and diverse native megafauna. Early human colonization led to conflict before a negotiated ceasefire."

// Sources: home_system_choices, /datum/lore/codex/page/akula/add_content()
/datum/lore/location/planet/jorhul
	name = "Jorhul, Barkalis"
	preference_value = "Jorhul, Barkalis"
	parent_system = /datum/lore/location/system/barkalis
	desc = "A world in Barkalis, the original home system of the pelagic Akula."

// Sources: /datum/lore/codex/page/article79, /datum/lore/organization/tsc/morpheus
/datum/lore/location/flotilla/shelf
	name = "Shelf Flotilla"
	preference_value = "Shelf Flotilla"
	desc = "A largely positronic colony fleet of more than 1,700 vessels and the home base of Morpheus Cyberkinetics."

// Sources: https://wiki.vore-station.net/index.php?title=Skrell&oldid=9623
/datum/lore/location/flotilla/ue_orsi
	name = "Ue-Orsi Flotilla"
	preference_value = "Ue-Orsi Flotilla"
	desc = "A Skrell refugee flotilla associated with the counter-cultural communities found beyond the mainstream of Skrell society."
