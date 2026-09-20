///////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star September 2026: Character Designer - Misc Settings //
///////////////////////////////////////////////////////////////////////////////////////

#define PERSIST_SPAWN		0x01	// Persist spawnpoint based on location of despawn/logout.
#define PERSIST_WEIGHT		0x02	// Persist mob weight
#define PERSIST_ORGANS		0x04	// Persist the status (normal/amputated/robotic/etc) and model (for robotic) status of organs
#define PERSIST_MARKINGS	0x08	// Persist markings
#define PERSIST_SIZE		0x10	// Persist size
#define PERSIST_COUNT		5		// Number of valid bits in this bitflag.  Keep this updated!
#define PERSIST_DEFAULT		PERSIST_SPAWN|PERSIST_ORGANS|PERSIST_MARKINGS|PERSIST_SIZE // Default setting for new folks

// Define a place to save in character setup
/datum/preferences
	var/persistence_settings = PERSIST_DEFAULT	// Control what if anything is persisted for this character between rounds.

// Definition of the stuff for Sizing
/datum/category_item/player_setup_item/vore/persistence
	name = "Persistence"
	sort_order = 5

/datum/category_item/player_setup_item/vore/persistence/load_character(var/savefile/S)
	S["persistence_settings"]		>> pref.persistence_settings
	sanitize_character() // Don't let new characters start off with nulls

/datum/category_item/player_setup_item/vore/persistence/save_character(var/savefile/S)
	S["persistence_settings"]		<< pref.persistence_settings

/datum/category_item/player_setup_item/vore/persistence/sanitize_character()
	pref.persistence_settings		= sanitize_integer(pref.persistence_settings, 0, (1<<(PERSIST_COUNT+1)-1), initial(pref.persistence_settings))
