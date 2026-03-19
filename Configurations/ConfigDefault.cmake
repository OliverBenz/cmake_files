# Description: 
#  - Extends:         Minimal Configuration + more detailed default configuration.
#  - Compiler/Linker: Parallel Build, Whole Program Optimization, Extra debug information and checks, explicitly set defaults.
#  - Macros:          Only _DEBUG and NDEBUG macros
#  - Warnings:        W4 and extra important warnings
cmake_minimum_required(VERSION 3.27)

include_guard(GLOBAL)


include("${CMAKE_CURRENT_LIST_DIR}/ConfigMinimal.cmake")


# ----- Helper function for configuration -----
# TODO: Test flags for gcc and clang
# TODO: Test RelWithDebInfo for gcc and clang
# TODO: MinSizeRel
function(_set_target_options_compiler_def targetName)
	# ----- Setup variables -----
	# ----- MSVC compiler flags
	set(MSVC_ALL
		/GS            # Buffer Security Check enabled.
		/GR            # Adds code to check object types at run time. On by default.
		/Gd            # Calling Convention. Explicitly use default (/Gd -> __cdecl).
		/EHsc          # Exception handling model. 's' .. Standard stack unwinding and 'c' .. extern "C" functions never throw C++ exceptions.
		/fp:precise    # Floating-point behavior precise. Explicitly use default: precise.
		/permissive-   # Enforce ISO C++ standard compliance.
	)

	set(MSVC_DEBUG
		${MSVC_ALL}
		/RTC1 # Enable Runtime Error Checks. Equivalent to RTCsu.
		/Gy   # Enable Function-Level Linking. Auto-Set by /ZI
	)
	set(MSVC_RELEASE
		${MSVC_ALL}
		/Gy   # Enable Function-Level Linking.     Auto-Set by /O2
		/GL   # Enable whole program optimization. Auto-Sets: linker /LTCG
	)
	set(MSVC_RELEASE_DEBINFO
		${MSVC_RELEASE}
	)

	# ----- GCC compiler flags
	set(GCC_ALL
		-fexceptions              # Exception handling — equivalent to /EHsc
		-fstack-protector-strong  # Buffer security check — equivalent to /GS
		-fPIC                     # Position independent code — good default for libraries
		-pipe                     # Use pipes instead of temp files — speeds up compilation like /MP
	)
	set(GCC_DEBUG
		${GCC_ALL}
		-fno-omit-frame-pointer  # Keep frame pointers — equivalent to /Oy-
		-fno-inline              # Disable inlining — easier debugging
	)
	set(GCC_RELEASE
		${GCC_ALL}
		-fomit-frame-pointer      # Allow omitting frame pointers — release only
		-flto                     # Link time optimization — equivalent to /GL + /LTCG
		-ffunction-sections       # Equivalent to /Gy — one section per function
		-fdata-sections           # Same for data
	)
	set(GCC_RELEASE_DEBINFO
		${GCC_RELEASE}
		-fno-omit-frame-pointer # Restore frame pointer for profiling
	)

	# ----- Clang compiler flags
	# TODO: All gcc options exist also for clang?
	# TODO: CLANG_ALL for more flags
	# TODO: CLANG_RELEASE_DEBINFO
	set(CLANG_DEBUG           ${GCC_DEBUG})
	set(CLANG_RELEASE         ${GCC_RELEASE})
	set(CLANG_RELEASE_DEBINFO ${GCC_RELEASE_DEBINFO})

	# ----- Switch which variables to use -----
	# Use the correct set of options depending on the compiler
	set(OPTIONS_DEBUG)
	set(OPTIONS_RELEASE)
	set(OPTIONS_RELEASE_DEBINFO)

	if(MSVC)                                         # MSVC
		set(OPTIONS_DEBUG           ${MSVC_DEBUG})
		set(OPTIONS_RELEASE         ${MSVC_RELEASE})
		set(OPTIONS_RELEASE_DEBINFO ${MSVC_RELEASE_DEBINFO})
	elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")     # GCC
		set(OPTIONS_DEBUG           ${GCC_DEBUG})
		set(OPTIONS_RELEASE         ${GCC_RELEASE})
		set(OPTIONS_RELEASE_DEBINFO ${GCC_RELEASE_DEBINFO})
	elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang")    # Clang / AppleClang
		set(OPTIONS_DEBUG           ${CLANG_DEBUG})
		set(OPTIONS_RELEASE         ${CLANG_RELEASE})
		set(OPTIONS_RELEASE_DEBINFO ${CLANG_RELEASE_DEBINFO})
	else()                                           # Else
		message(AUTHOR_WARNING "No extra compiler flags set for '${CMAKE_CXX_COMPILER_ID}' compiler.")
		return()
	endif()

	# ----- Option: Override Release config -----
	if(RELEASE_EQUALS_RELWITHDEBINFO)
		message(STATUS "- Note: Using the RelWithDebInfo compiler configuration also for Release builds.")
		set(OPTIONS_RELEASE ${OPTIONS_RELEASE_DEBINFO})
	endif()

	# ----- Print which flags used -----
	message(STATUS "- Compiler flags for Debug          ${OPTIONS_DEBUG}")
	message(STATUS "- Compiler flags for Release        ${OPTIONS_RELEASE}")
	message(STATUS "- Compiler flags for RelWithDebInfo ${OPTIONS_RELEASE_DEBINFO}")

	# ----- Add flags to target -----
	target_compile_options(${targetName} INTERFACE "$<$<CONFIG:Debug>:${OPTIONS_DEBUG}>")
	target_compile_options(${targetName} INTERFACE "$<$<CONFIG:Release>:${OPTIONS_RELEASE}>")
	target_compile_options(${targetName} INTERFACE "$<$<CONFIG:RelWithDebInfo>:${OPTIONS_RELEASE_DEBINFO}>")
endfunction()


function(_set_target_options_linker_def targetName)
	# ----- Setup variables -----

	# MSVC linker flags
	set(MSVC_DEBUG
		/INCREMENTAL # Link incrementally. Don't always perform a full link.
	)
	set(MSVC_RELEASE
		/LTCG           # Link-time code generation. For WholeProgramOptimization.
		/INCREMENTAL:NO # Always perform a full link. /INCREMENTAL not compatible with /LTCG (in WholeProgramOptimization)
		$<$<STREQUAL:${CMAKE_VS_PLATFORM_NAME},Win32>:/SAFESEH>  # Only produces an image if we can produce a table of the image's safe exception handlers. Only valid for x86 targets.
	)
	set(MSVC_RELEASE_DEBINFO
		${MSVC_RELEASE}  # /DEBUG inherited from Config::Minimal
	)

	# GCC linker flags
	set(GCC_ALL)
	set(GCC_DEBUG
		${GCC_ALL}
	)
	set(GCC_RELEASE
		${GCC_ALL}
		-Wl,--gc-sections # Remove unused sections — equivalent to /OPT:REF
		$<$<BOOL:${LLD_LINKER}>:-Wl,--icf=all>
	)
	set(GCC_RELEASE_DEBINFO
		${GCC_RELEASE}
	)

	# Clang linker flags
	set(CLANG_DEBUG           ${GCC_DEBUG})
	set(CLANG_RELEASE         ${GCC_RELEASE})
	set(CLANG_RELEASE_DEBINFO ${CLANG_RELEASE})

	set(OPTIONS_DEBUG)
	set(OPTIONS_RELEASE)
	set(OPTIONS_RELEASE_DEBINFO)
	if(MSVC)                                         # MSVC
		set(OPTIONS_DEBUG           ${MSVC_DEBUG})
		set(OPTIONS_RELEASE         ${MSVC_RELEASE})
		set(OPTIONS_RELEASE_DEBINFO ${MSVC_RELEASE_DEBINFO})
	elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")     # GCC
		set(OPTIONS_DEBUG           ${GCC_DEBUG})
		set(OPTIONS_RELEASE         ${GCC_RELEASE})
		set(OPTIONS_RELEASE_DEBINFO ${GCC_RELEASE_DEBINFO})
	elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang")    # Clang / AppleClang
		set(OPTIONS_DEBUG           ${CLANG_DEBUG})
		set(OPTIONS_RELEASE         ${CLANG_RELEASE})
		set(OPTIONS_RELEASE_DEBINFO ${CLANG_RELEASE_DEBINFO})
	else()                                           # Else
		message(AUTHOR_WARNING "No extra linker flags set for '${CMAKE_CXX_COMPILER_ID}' compiler.")
		return()
	endif()

	# ----- Option: Override Release config -----
	if(RELEASE_EQUALS_RELWITHDEBINFO)
		message(STATUS "- Note: Using the RelWithDebInfo linker configuration also for Release builds.")
		set(OPTIONS_RELEASE ${OPTIONS_RELEASE_DEBINFO})
	endif()

	# ----- Print which flags used -----
	message(STATUS "- Linker flags for Debug          ${OPTIONS_DEBUG}")
	message(STATUS "- Linker flags for Release        ${OPTIONS_RELEASE}")
	message(STATUS "- Linker flags for RelWithDebInfo ${OPTIONS_RELEASE_DEBINFO}")

	# ----- Add flags to target -----
	target_link_options(${targetName} INTERFACE "$<$<CONFIG:Debug>:${OPTIONS_DEBUG}>")
	target_link_options(${targetName} INTERFACE "$<$<CONFIG:Release>:${OPTIONS_RELEASE}>")
	target_link_options(${targetName} INTERFACE "$<$<CONFIG:RelWithDebInfo>:${OPTIONS_RELEASE_DEBINFO}>")
endfunction()


message(STATUS "")
message(STATUS "----- Configuration Default -----")
message(STATUS "---------------------------------")
message(STATUS "- Use ALIAS:             Config::Default")

set(targetName "ConfigDefault")

add_library(${targetName} INTERFACE)
add_library(Config::Default ALIAS ${targetName})

target_link_libraries(${targetName} INTERFACE Config::Minimal) # Same base configuration as Config::Default
set_target_options_warnings(${targetName})                     # Warning  Flags
_set_target_options_compiler_def(${targetName})                # Compiler Flags
_set_target_options_linker_def(${targetName})                  # Linker   Flags
