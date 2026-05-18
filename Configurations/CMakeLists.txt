cmake_minimum_required(VERSION 3.20)

include_guard(GLOBAL)


# ----- Settings -----
# -- We want to use LLD Linker on Mac/Linux if available
find_program(LLD_LINKER lld)
if(LLD_LINKER)
    message(STATUS "lld found: ${LLD_LINKER} - enabling LLD linker and ICF")
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
include("${CMAKE_CURRENT_LIST_DIR}/ConfigClr.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/ConfigClrWin.cmake")


# ----- Interface -----
# Set a configuration and optionally the character set for a specific target.
# Also hide symbols in shared libraries by default. Export manually with generate_export_header pattern.
#
# Parsed Arguments [Optional]:
#   CHARSET:         For Windows: ["Unicode", "MBCS", "SBCS"]. Default if not specified: "Unicode"
#
# Exception Handling
#   By default, we enable standard stack unwinding with synchronous exception handling.
#   Set the target property CONFIG_EH_ASYNC to also catch asynchronous (hardware) exceptions such as null pointer dereferences and divide-by-zero via catch(...).
#   Note: catching hardware exceptions is generally discouraged; prefer platform crash handlers.
#
#   Usage: set_target_properties(targetName PROPERTIES CONFIG_EH_ASYNC TRUE)
#
#   MSVC:
#     Default:         /EHsc
#     CONFIG_EH_ASYNC: /EHa
#   GCC/Clang:
#     Default:         -fexceptions
#     CONFIG_EH_ASYNC: -fexceptions -fnon-call-exceptions
#
# Configuration Names
#  Empty:      No extra configuration.
#  Minimal:    Clean minimal set of compiler and linker flags.
#  Default:    Default configuration with detailed compiler and linker flag usage and common macros.
#  DefaultWin: Default configuration with detailed compiler and linker flag usage and common macros. Defines further windows specific nice-to-have macros.
#  Clr:        Common Language Runtime project (MSVC only). Call fix_runtime_library_for_clr after setting up your target.
#  ClrWin:     Common Language Runtime project (MSVC only). Defines further windows specific nice-to-have macros. Call fix_runtime_library_for_clr after setting up your target.
#
# Note: You can also just directly link to the configuration target. This function can be useful in patterns where e.g. a configuration choice is enforced.
function(set_target_configuration targetName configName)
	# Parse optional function arguments 
	cmake_parse_arguments(ARG "" "CHARSET" "" ${ARGN})

	# Handle Configurations
	if(NOT "${configName}" MATCHES "^Config::")
		message(FATAL_ERROR "Invalid configuration: '${configName}'. Ensure prefix 'Config::'")
	endif()

	if("${configName}" MATCHES "^Config::Clr" AND NOT MSVC)
		message(FATAL_ERROR "The configuration 'Config::Clr' is only available for MSVC.")
	endif()

	if(NOT TARGET ${configName})
		if("${configName}" STREQUAL "Config::Empty")
			return()  # No extra configuration
		endif()
		message(FATAL_ERROR "Configuration project does not exist: '${configName}'.")
	endif()
	target_link_libraries(${targetName} PRIVATE ${configName})

	# Handle Character Set (Unicode, MBCS, SBCS)
	if(WIN32)
		set(charsetMacros)
		if("${ARG_CHARSET}" STREQUAL "Unicode" OR "${ARG_CHARSET}" STREQUAL "")
			set(charsetMacros _UNICODE UNICODE)
		elseif("${ARG_CHARSET}" STREQUAL "MBCS")
			set(charsetMacros _MBCS)
		elseif("${ARG_CHARSET}" STREQUAL "SBCS")
			set(charsetMacros _SBCS)
		else()
			message(FATAL_ERROR "Invalid character set configuration specified '${ARG_CHARSET}'. Use: ['Unicode', 'MBCS', 'SBCS'].")
		endif()

		target_compile_definitions(${targetName} PRIVATE ${charsetMacros})
	endif()

	# Hide symbols in shared libraries by default.
	set_target_properties(${targetName} PROPERTIES
		CXX_VISIBILITY_PRESET     hidden
		VISIBILITY_INLINES_HIDDEN YES
	)
endfunction()
