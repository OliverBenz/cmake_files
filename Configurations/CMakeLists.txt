include_guard(GLOBAL)

# TODO: Include minimal
include("${CMAKE_CURRENT_LIST_DIR}/ConfigDefaultWin.cmake")
# TODO: Include default win
# TODO: Include CLR

# Configuration Names
#  Minimal:    Clean minimal amount of compiler and linker flags.
#  Default:    Default configuration with detailed compiler and linker flag usage and common macros.
#  DefaultWin: Default configuration with detailed compiler and linker flag usage and common macros. Defines further windows specific nice-to-have macros.
#  CLR:        Common Language Runtime project (MSVC only).
function(set_target_configuration targetName configName)
	if("${configName}" STREQUAL "Minimal")
		target_link_libraries(${targetName} PRIVATE Config::Minimal)
	elseif("${configName}" STREQUAL "Default")
		target_link_libraries(${targetName} PRIVATE Config::Default)
	elseif("${configName}" STREQUAL "DefaultWin")
		target_link_libraries(${targetName} PRIVATE Config::DefaultWin)
	elseif("${configName}" STREQUAL "CLR")
		target_link_libraries(${targetName} PRIVATE Config::CLR)
	else()
		message(AUTHOR_WARNING "Invalid project configuration specified: '${configName}'.")
	endif()

endfunction()
