#define Z_LEVEL_GB_BOTTOM  					1
#define Z_LEVEL_GB_MIDDLE  					2
#define Z_LEVEL_GB_TOP     					3
#define Z_LEVEL_GB_ENGINESAT				4
#define Z_LEVEL_GB_WILD_N  					5
#define Z_LEVEL_GB_WILD_S  					6
#define Z_LEVEL_GB_WILD_E  					7
#define Z_LEVEL_GB_WILD_W  					8
#define Z_LEVEL_MINING						11

#define Z_LEVEL_SHIP_MAINTENANCE			1
#define Z_LEVEL_SHIP_LOW					2
#define Z_LEVEL_SHIP_MID					3
#define Z_LEVEL_SHIP_HIGH					4
#define Z_LEVEL_SPACE_ROCKS					7
#define Z_LEVEL_OVERMAP						14

// For making the 6-in-1 holomap, we calculate some offsets
#define SHIP_MAP_SIZE 140 // Width and height of compiled in tether z levels.
#define SHIP_HOLOMAP_CENTER_GUTTER 40 // 40px central gutter between columns
#define SHIP_HOLOMAP_MARGIN_X ((HOLOMAP_ICON_SIZE - (2*SHIP_MAP_SIZE) - SHIP_HOLOMAP_CENTER_GUTTER) / 2) // 80
#define SHIP_HOLOMAP_MARGIN_Y ((HOLOMAP_ICON_SIZE - (2*SHIP_MAP_SIZE)) / 2) // 30

//Camera networks
#define NETWORK_HALLS "Halls"

var/global/list/z_list = list()
