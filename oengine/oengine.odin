package oengine

OE_DEBUG := false
PHYS_DEBUG := false
PHYS_OCTREE_DEBUG := false

OE_DEBUG_COLOR :: GREEN
PHYS_DEBUG_COLOR :: BLUE

OE_USE_MESHES :: #config(USE_MESHES, true)
OE_MESHES_PATH :: #config(MESHES_PATH, "../resources/meshes/")
OE_FONTS_PATH :: #config(FONTS_PATH, "../resources/fonts/")
OE_FAE :: #config(FAE, false)
OE_SLOPE_THRESHOLD :: #config(SLOPE_THRESHOLD, 0.7)
OE_SLOPE_SLIDING :: #config(SLOPE_SLIDING, false)

DATA_PATH :: "set from data!"

QUOTES :: "\""

CSG_RB :: "csg_box_rb"
CSG_SM :: "csg_box_sm"
