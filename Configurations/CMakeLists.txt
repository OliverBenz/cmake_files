cmake_minimum_required(VERSION 3.27)

include_guard(GLOBAL)


# ----- Settings -----
# -- We want to use LLD Linker on Mac/Linux if available
find_program(LLD_LINKER lld)
if(LLD_LINKER)
    message(STATUS "lld found: ${LLD_LINKER} — enabling LLD linker and ICF")
else()
    message(STATUS "lld not found - using default linker, ICF disabled")
endif()


# -- Allow the option to override the Release build configuration with the RelWithDebInfo configuration.
#    Useful in environments where debug information is always desired on release builds or where build systems restrict you to default Release builds.
option(RELEASE_EQUALS_RELWITHDEBINFO "Use the RelWithDebInfo configuration also for Release builds." OFF)


# ----- Includes -----
include("${CMAKE_CURRENT_LIST_DIR}/ConfigMinimal.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/ConfigDefault.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/ConfigDefaultWin.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/ConfigCLR.cmake")


# ----- Interface -----
# Set a configuration for a specific target.
# Note: You can also just directly link to the configuration target. This function can be useful in patterns where e.g. a configuration choice is enforced.
#
# Configuration Names
#  Empty:      No extra configuration.
#  Minimal:    Clean minimal set of compiler and linker flags.
#  Default:    Default configuration with detailed compiler and linker flag usage and common macros.
#  DefaultWin: Default configuration with detailed compiler and linker flag usage and common macros. Defines further windows specific nice-to-have macros.
#  CLR:        Common Language Runtime project (MSVC only). Call fix_runtime_library_for_clr after setting up your target.
function(set_target_configuration targetName configName)
	if(NOT "${configName}" MATCHES "^Config::")
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
