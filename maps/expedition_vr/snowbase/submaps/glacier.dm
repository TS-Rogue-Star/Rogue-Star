// This causes PoI maps to get 'checked' and compiled, when undergoing a unit test.
// This is so CI can validate PoIs, and ensure future changes don't break PoIs, as PoIs are loaded at runtime and the compiler can't catch errors.
// When adding a new PoI, please add it to this list.
#if MAP_TEST
#include "glacier_prepper1.dmm"
#include "glacier_quarantineshuttle.dmm"
#include "glacier_Mineshaft1.dmm"
#include "glacier_Scave1.dmm"
#include "glacier_crashed_ufo.dmm"
#include "glacier_crashed_ufo_frigate.dmm"
#include "glacier_crystal1.dmm"
#include "glacier_crystal2.dmm"
#include "glacier_crystal3.dmm"
#include "glacier_lost_explorer.dmm"
#include "glacier_Cavelake.dmm"
#include "glacier_Rockb1.dmm"
#include "glacier_ritual.dmm"
#include "glacier_temple.dmm"
#include "glacier_CrashedMedShuttle1.dmm"
#include "glacier_digsite.dmm"
#include "glacier_vault1.dmm"
#include "glacier_vault2.dmm"
#include "glacier_vault3.dmm"
#include "glacier_vault4.dmm"
#include "glacier_vault5.dmm"
#include "glacier_vault6.dmm"
#include "glacier_IceCave1A.dmm"
#include "glacier_SwordCave.dmm"
#include "glacier_SupplyDrop1.dmm"
#include "glacier_BlastMine1.dmm"
#include "glacier_crashedcontainmentshuttle.dmm"
#include "glacier_deadspy.dmm"
#include "glacier_lava_trench.dmm"
#include "glacier_Geyser1.dmm"
#include "glacier_Geyser2.dmm"
#include "glacier_Geyser3.dmm"
#include "glacier_Cliff1.dmm"
#include "glacier_excavation1.dmm"
#include "glacier_spatial_anomaly.dmm"
#include "glacier_speakeasy_vr.dmm"
#endif

// The glacier is the mining Z-level. There is only one pool of POIs.

/datum/map_template/surface/glacier
	name = "Glacier Content"
	desc = "Don't dig too deep!"

/**************
 * Ice Caves *
 **************/

/datum/map_template/surface/glacier/prepper1
	name = "Glacier Prepper Bunker"
	desc = "A little hideaway for someone with more time and money than sense."
	mappath = 'maps/expedition_vr/snowbase/submaps/glacier_prepper1.dmm'
	cost = 10

/datum/map_template/surface/glacier/qshuttle
	name = "Glacier Quarantined Shuttle"
	desc = "An emergency landing turned viral outbreak turned tragedy."
	mappath = 'maps/expedition_vr/snowbase/submaps/glacier_quarantineshuttle.dmm'
	cost = 20

/datum/map_template/surface/glacier/Mineshaft1
	name = "Glacier Abandoned Mineshaft 1"
	desc = "An abandoned minning tunnel from a lost money making effort."
	mappath = 'maps/expedition_vr/snowbase/submaps/glacier_Mineshaft1.dmm'
	cost = 5

/datum/map_template/surface/glacier/crystal1
	name = "Glacier Crystal Cave 1"
	desc = "A small cave with glowing gems and diamonds."
	mappath = 'maps/expedition_vr/snowbase/submaps/glacier_crystal1.dmm'
	cost = 5
	allow_duplicates = TRUE

/datum/map_template/surface/glacier/crystal2
	name = "Glacier Crystal Cave 2"
	desc = "A moderate sized cave with glowing gems and diamonds."
	mappath = 'maps/expedition_vr/snowbase/submaps/glacier_crystal2.dmm'
	cost = 10
	allow_duplicates = TRUE

/datum/map_template/surface/glacier/crystal2
	name = "Glacier Crystal Cave 3"
	desc = "A large spiral of crystals with diamonds in the center."
	mappath = 'maps/expedition_vr/snowbase/submaps/glacier_crystal3.dmm'
	cost = 15

/datum/map_template/surface/glacier/lost_explorer
	name = "Glacier Lost Explorer"
	desc = "The remains of an explorer who rotted away ages ago, and their equipment."
	mappath = 'maps/expedition_vr/snowbase/submaps/glacier_lost_explorer.dmm'
	cost = 5
	allow_duplicates = TRUE

/datum/map_template/surface/glacier/Rockb1
	name = "Glacier Rocky Base 1"
	desc = "Someones underground hidey hole"
	mappath = 'maps/expedition_vr/snowbase/submaps/glacier_Rockb1.dmm'
	cost = 15

/datum/map_template/surface/glacier/corgiritual
	name = "Glacier Dark Ritual"
	desc = "Who put all these plushies here? What are they doing?"
	mappath = 'maps/expedition_vr/snowbase/submaps/glacier_ritual.dmm'
	cost = 15

/datum/map_template/surface/glacier/abandonedtemple
	name = "Glacier Abandoned Temple"
	desc = "An ancient temple, long since abandoned. Perhaps alien in origin?"
	mappath = 'maps/expedition_vr/snowbase/submaps/glacier_temple.dmm'
	cost = 20

/datum/map_template/surface/glacier/digsite
	name = "Glacier Dig Site"
	desc = "A small abandoned dig site."
	mappath = 'maps/expedition_vr/snowbase/submaps/glacier_digsite.dmm'
	cost = 10

/datum/map_template/surface/glacier/vault1
	name = "Glacier Mine Vault 1"
	desc = "A small vault with potential loot."
	mappath = 'maps/expedition_vr/snowbase/submaps/glacier_vault1.dmm'
	cost = 5
	allow_duplicates = TRUE
	template_group = "Buried Vaults"

/datum/map_template/surface/glacier/vault2
	name = "Glacier Mine Vault 2"
	desc = "A small vault with potential loot."
	mappath = 'maps/expedition_vr/snowbase/submaps/glacier_vault2.dmm'
	cost = 5
	allow_duplicates = TRUE
	template_group = "Buried Vaults"

/datum/map_template/surface/glacier/vault3
	name = "Glacier Mine Vault 3"
	desc = "A small vault with potential loot. Also a horrible suprise."
	mappath = 'maps/expedition_vr/snowbase/submaps/glacier_vault3.dmm'
	cost = 15
	template_group = "Buried Vaults"

/datum/map_template/surface/glacier/IceCave1A
	name = "Glacier Ice Cave 1A"
	desc = "This cave's slippery ice makes it hard to navigate, but determined explorers will be rewarded."
	mappath = 'maps/expedition_vr/snowbase/submaps/glacier_IceCave1A.dmm'
	cost = 10

/datum/map_template/surface/glacier/SwordCave
	name = "Glacier Cursed Sword Cave"
	desc = "An underground lake. The sword on the lake's island holds a terrible secret."
	mappath = 'maps/expedition_vr/snowbase/submaps/glacier_SwordCave.dmm'

/datum/map_template/surface/glacier/supplydrop1
	name = "Glacier Supply Drop 1"
	desc = "A drop pod that landed deep within the Glacier."
	mappath = 'maps/expedition_vr/snowbase/submaps/glacier_SupplyDrop1.dmm'
	cost = 10
	allow_duplicates = TRUE

/datum/map_template/surface/glacier/crashedcontainmentshuttle
	name = "Glacier Crashed Cargo Shuttle"
	desc = "A severely damaged military shuttle, its cargo seems to remain intact."
	mappath = 'maps/expedition_vr/snowbase/submaps/glacier_crashedcontainmentshuttle.dmm'
	cost = 30

/datum/map_template/surface/glacier/deadspy
	name = "Glacier Spy Remains"
	desc = "W+M1 = Salt."
	mappath = 'maps/expedition_vr/snowbase/submaps/glacier_deadspy.dmm'
	cost = 15

/datum/map_template/surface/glacier/geyser1
	name = "Glacier Ore-Rich Geyser"
	desc = "A subterranean geyser that produces steam. This one has a particularly abundant amount of materials surrounding it."
	mappath = 'maps/expedition_vr/snowbase/submaps/glacier_Geyser1.dmm'
	cost = 5
	allow_duplicates = TRUE
	template_group = "Underground Geysers"

/datum/map_template/surface/glacier/geyser2
	name = "Glacier Fenced Geyser"
	desc = "A subterranean geyser that produces steam. This one has a damaged fence surrounding it."
	mappath = 'maps/expedition_vr/snowbase/submaps/glacier_Geyser2.dmm'
	cost = 5
	allow_duplicates = TRUE
	template_group = "Underground Geysers"

/datum/map_template/surface/glacier/geyser3
	name = "Glacier Magmatic Geyser"
	desc = "A subterranean geyser that produces incendiary gas. It is recessed into the ground, and filled with magma. It's a relatively dormant volcano."
	mappath = 'maps/expedition_vr/snowbase/submaps/glacier_Geyser2.dmm'
	cost = 10
	allow_duplicates = TRUE
	template_group = "Underground Geysers"

/datum/map_template/surface/glacier/cliff1
	name = "Glacier Ore-Topped Cliff"
	desc = "A raised area of rock created by volcanic forces."
	mappath = 'maps/expedition_vr/snowbase/submaps/glacier_Cliff1.dmm'
	cost = 5
	allow_duplicates = TRUE
	template_group = "Underground Cliffs"

/datum/map_template/surface/glacier/deadly_rabbit // VOREStation Edit
	name = "Glacier The Killer Rabbit"
	desc = "A cave where the Knights of the Round have fallen to a murderous Rabbit."
	mappath = 'maps/expedition_vr/snowbase/submaps/glacier_deadly_rabbit_vr.dmm'
	cost = 5
	allow_duplicates = FALSE


/datum/map_template/surface/glacier/crashed_ufo //VOREStation Edit
	name = "Glacier Crashed UFO"
	desc = "A (formerly) flying saucer that is now embedded into the mountain, yet it still seems to be running..."
	mappath = 'maps/expedition_vr/snowbase/submaps/glacier_crashed_ufo.dmm'
	cost = 40
	discard_prob = 50

/datum/map_template/surface/glacier/crashed_ufo_frigate //VOREStation Edit
	name = "Glacier Crashed UFO Frigate"
	desc = "A (formerly) flying saucer that is now embedded into the mountain, yet the combat protocols still seem to be running..."
	mappath = 'maps/expedition_vr/snowbase/submaps/glacier_crashed_ufo_frigate.dmm'
	cost = 60
	discard_prob = 50

/datum/map_template/surface/glacier/Scave1 //VOREStation Edit
	name = "Glacier Spider Cave 1"
	desc = "A minning tunnel home to an aggressive collection of spiders."
	mappath = 'maps/expedition_vr/snowbase/submaps/glacier_Scave1.dmm'
	cost = 20

/datum/map_template/surface/glacier/Cavelake //VOREStation Edit
	name = "Glacier Cave Lake"
	desc = "A large underground lake."
	mappath = 'maps/expedition_vr/snowbase/submaps/glacier_Cavelake.dmm'
	cost = 20

/datum/map_template/surface/glacier/vault1 //VOREStation Edit
	name = "Glacier Mine Vault 1"
	desc = "A small vault with potential loot."
	mappath = 'maps/expedition_vr/snowbase/submaps/glacier_vault1.dmm'
	cost = 5
	allow_duplicates = TRUE
	template_group = "Buried Vaults"

/datum/map_template/surface/glacier/vault2 //VOREStation Edit
	name = "Glacier Mine Vault 2"
	desc = "A small vault with potential loot."
	mappath = 'maps/expedition_vr/snowbase/submaps/glacier_vault2.dmm'
	cost = 5
	allow_duplicates = TRUE
	template_group = "Buried Vaults"

/datum/map_template/surface/glacier/vault3 //VOREStation Edit
	name = "Glacier Mine Vault 3"
	desc = "A small vault with potential loot. Also a horrible suprise."
	mappath = 'maps/expedition_vr/snowbase/submaps/glacier_vault3.dmm'
	cost = 15
	template_group = "Buried Vaults"

/datum/map_template/surface/glacier/vault4 //VOREStation Edit
	name = "Glacier Mine Vault 4"
	desc = "A small xeno vault with potential loot. Also horrible suprises."
	mappath = 'maps/expedition_vr/snowbase/submaps/glacier_vault4.dmm'
	cost = 20
	template_group = "Buried Vaults"

/datum/map_template/surface/glacier/vault5 //VOREStation Edit
	name = "Glacier Mine Vault 5"
	desc = "A small xeno vault with potential loot. Also major horrible suprises."
	mappath = 'maps/expedition_vr/snowbase/submaps/glacier_vault5.dmm'
	cost = 25
	template_group = "Buried Vaults"

/datum/map_template/surface/glacier/vault6 //VOREStation Edit
	name = "Glacier Mine Vault 6"
	desc = "A small mercenary tower with potential loot."
	mappath = 'maps/expedition_vr/snowbase/submaps/glacier_vault6.dmm'
	cost = 25
	template_group = "Buried Vaults"

/datum/map_template/surface/glacier/BlastMine1 //VOREStation Edit
	name = "Glacier Blast Mine 1"
	desc = "An abandoned blast mining site, seems that local wildlife has moved in."
	mappath = 'maps/expedition_vr/snowbase/submaps/glacier_BlastMine1.dmm'
	cost = 20

/datum/map_template/surface/glacier/lava_trench //VOREStation Edit
	name = "Glacier lava trench"
	desc = "A long stretch of lava underground, almost river-like, with a small crystal research outpost on the side."
	mappath = 'maps/expedition_vr/snowbase/submaps/glacier_lava_trench.dmm'
	cost = 20
	fixed_orientation = TRUE

/datum/map_template/surface/glacier/crashedmedshuttle //VOREStation Edit
	name = "Glacier Crashed Med Shuttle"
	desc = "A medical response shuttle that went missing some time ago. So this is where they went."
	mappath = 'maps/expedition_vr/snowbase/submaps/glacier_CrashedMedShuttle1.dmm'
	cost = 20
	fixed_orientation = TRUE

/datum/map_template/surface/glacier/excavation1 //VOREStation Edit
	name = "Glacier Excavation Site"
	desc = "An abandoned mining site."
	mappath = 'maps/expedition_vr/snowbase/submaps/glacier_excavation1.dmm'
	cost = 20

/datum/map_template/surface/Glacier/deep/spatial_anomaly
	name = "Glacier spatial anomaly"
	desc = "A strange section of the caves that seems twist and turn in ways that shouldn't be physically possible."
	mappath = 'maps/expedition_vr/snowbase/submaps/glacier_spatial_anomaly.dmm'
	cost = 20
	fixed_orientation = TRUE

/datum/map_template/surface/glacier/Speakeasy //VOREStation add
	name = "Glacier Speakeasy"
	desc = "A hidden underground bar to serve drinks in secret and in style."
	mappath = 'maps/expedition_vr/snowbase/submaps/glacier_speakeasy_vr.dmm'
	cost = 10
	allow_duplicates = FALSE
