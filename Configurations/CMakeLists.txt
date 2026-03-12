include_guard(GLOBAL)

# TODO: Include minimal
include("${CMAKE_CURRENT_LIST_DIR}/ConfigDefault.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/ConfigDefaultWin.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/ConfigCLR.cmake")


# Configuration Names
#  Empty:      No extra configuration.
#  Minimal:    Clean minimal amount of compiler and linker flags.
#  Default:    Default configuration with detailed compiler and linker flag usage and common macros.
#  DefaultWin: Default configuration with detailed compiler and linker flag usage and common macros. Defines further windows specific nice-to-have macros.
#  CLR:        Common Language Runtime project (MSVC only).
function(set_target_configuration targetName configName)
	if(NOT "${configName}" MATCHES "Config::")
		message(FATAL_ERROR "Invalid configuration: '${configName}'. Ensure prefix 'Config::'")
	endif()
	if(NOT TARGET ${configName})
		if("${configName}" STREQUAL "Config::Empty")
			return()  # No extra configuration
		endif()
		message(FATAL_ERROR "Configuration project does not exist: '${configName}'.")
	endif()



	target_link_libraries(${targetName} PRIVATE ${configName})
endfunction()
