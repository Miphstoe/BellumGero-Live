# Copyright (C) 2007 <SWGEmu>. All rights reserved.
# Distribution of this file for usage outside of Core3 is prohibited.

# Add discord manager sources
file(GLOB_RECURSE discordmanager_sources "*.cpp")
file(GLOB_RECURSE discordmanager_headers "*.h")

# Add discord manager includes
include_directories(../..)

# Create discord manager library
add_library(discordmanager STATIC ${discordmanager_sources} ${discordmanager_headers})

# Link DPP library if available
if(DPP_FOUND)
	target_include_directories(discordmanager PRIVATE ${DPP_INCLUDE_DIRS})
	target_link_libraries(discordmanager ${DPP_LIBRARIES})
	target_compile_options(discordmanager PRIVATE ${DPP_CFLAGS_OTHER})
endif()

add_dependencies(discordmanager idlobjects) 
