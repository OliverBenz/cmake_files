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
	set(MSVC_RELEASE_MINSIZE
		${MSVC_ALL}
		/Gy   # Enable Function-Level Linking.     Auto-Set by /O1
	)

	# ----- GCC compiler flags
	set(GCC_ALL
		-fexceptions              # Exception handling — equivalent to /EHsc
		-fstack-protector-strong  # Buffer security check — equivalent to /GS
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
		${GCC_ALL}
		-fno-omit-frame-pointer   # Restore frame pointer for profiling
		-flto                     # Link time optimization — equivalent to /GL + /LTCG
		-ffunction-sections       # Equivalent to /Gy — one section per function
		-fdata-sections           # Same for data
	)
	set(GCC_RELEASE_MINSIZE
		${GCC_ALL}
		-fomit-frame-pointer      # Allow omitting frame pointers — release only
		-ffunction-sections       # Equivalent to /Gy — one section per function
		-fdata-sections           # Same for data
	)

	# ----- Clang compiler flags
	# TODO: All gcc options exist also for clang?
	# TODO: CLANG_ALL for more flags
	set(CLANG_DEBUG           ${GCC_DEBUG})
	set(CLANG_RELEASE         ${GCC_RELEASE})
	set(CLANG_RELEASE_DEBINFO ${GCC_RELEASE_DEBINFO})
	set(CLANG_RELEASE_MINSIZE ${GCC_RELEASE_MINSIZE})

	# ----- Switch which variables to use -----
	# Use the correct set of options depending on the compiler
	set(OPTIONS_DEBUG)
	set(OPTIONS_RELEASE)
	set(OPTIONS_RELEASE_DEBINFO)
	set(OPTIONS_RELEASE_MINSIZE)
	if(MSVC)                                         # MSVC
		set(OPTIONS_DEBUG           ${MSVC_DEBUG})
		set(OPTIONS_RELEASE         ${MSVC_RELEASE})
		set(OPTIONS_RELEASE_DEBINFO ${MSVC_RELEASE_DEBINFO})
		set(OPTIONS_RELEASE_MINSIZE ${MSVC_RELEASE_MINSIZE})
	elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")     # GCC
		set(OPTIONS_DEBUG           ${GCC_DEBUG})
		set(OPTIONS_RELEASE         ${GCC_RELEASE})
		set(OPTIONS_RELEASE_DEBINFO ${GCC_RELEASE_DEBINFO})
		set(OPTIONS_RELEASE_MINSIZE ${GCC_RELEASE_MINSIZE})
	elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang")    # Clang / AppleClang
		set(OPTIONS_DEBUG           ${CLANG_DEBUG})
		set(OPTIONS_RELEASE         ${CLANG_RELEASE})
		set(OPTIONS_RELEASE_DEBINFO ${CLANG_RELEASE_DEBINFO})
		set(OPTIONS_RELEASE_MINSIZE ${CLANG_RELEASE_MINSIZE})
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
	message(STATUS "- Compiler flags for MinSizeRel     ${OPTIONS_RELEASE_MINSIZE}")

	# ----- Add flags to target -----
	target_compile_options(${targetName} INTERFACE "$<$<CONFIG:Debug>:${OPTIONS_DEBUG}>")
	target_compile_options(${targetName} INTERFACE "$<$<CONFIG:Release>:${OPTIONS_RELEASE}>")
	target_compile_options(${targetName} INTERFACE "$<$<CONFIG:RelWithDebInfo>:${OPTIONS_RELEASE_DEBINFO}>")
	target_compile_options(${targetName} INTERFACE "$<$<CONFIG:MinSizeRel>:${OPTIONS_RELEASE_MINSIZE}>")
endfunction()


function(_set_target_options_linker_def targetName)
	# ----- Setup variables -----

	# MSVC linker flags
	set(MSVC_DEBUG
		/INCREMENTAL # Link incrementally. Don't always perform a full link.
	)
	set(MSVC_RELEASE
		/LTCG                                          # Link-time code generation. For WholeProgramOptimization.
		/INCREMENTAL:NO                                # Always perform a full link. /INCREMENTAL not compatible with /LTCG (in WholeProgramOptimization)
		$<$<EQUAL:${CMAKE_SIZEOF_VOID_P},4>:/SAFESEH>  # Only produces an image if we can produce a table of the image's safe exception handlers. Only valid for x86 targets.
	)
	set(MSVC_RELEASE_DEBINFO
		${MSVC_RELEASE}  # /DEBUG inherited from Config::Minimal
	)
	set(MSVC_RELEASE_MINSIZE
		/INCREMENTAL:NO                               # Always perform a full link. /INCREMENTAL not compatible with /LTCG (in WholeProgramOptimization)	
		$<$<EQUAL:${CMAKE_SIZEOF_VOID_P},4>:/SAFESEH> # Only produces an image if we can produce a table of the image's safe exception handlers. Only valid for x86 targets.
	)

	# GCC linker flags
	set(GCC_ALL)
	set(GCC_DEBUG ${GCC_ALL})
	set(GCC_RELEASE
		${GCC_ALL}
		-Wl,--gc-sections                       # Remove unused sections — equivalent to /OPT:REF
		-flto                                   # Link time optimization — pairs with -flto in compiler flags
		$<$<BOOL:${LLD_LINKER}>:-Wl,--icf=safe> # Enable Identical Code Folding. Equivalent to MSVC /OPT:ICF
	)
	set(GCC_RELEASE_DEBINFO
		${GCC_RELEASE}
	)
	set(GCC_RELEASE_MINSIZE
		${GCC_ALL}
		-Wl,--gc-sections                       # Remove unused sections — equivalent to /OPT:REF
		$<$<BOOL:${LLD_LINKER}>:-Wl,--icf=safe> # Enable Identical Code Folding. Equivalent to MSVC /OPT:ICF
	)

	# Clang linker flags
	set(CLANG_DEBUG           ${GCC_DEBUG})
	set(CLANG_RELEASE         ${GCC_RELEASE})
	set(CLANG_RELEASE_DEBINFO ${GCC_RELEASE_DEBINFO})
	set(CLANG_RELEASE_MINSIZE ${GCC_RELEASE_MINSIZE})

	set(OPTIONS_DEBUG)
	set(OPTIONS_RELEASE)
	set(OPTIONS_RELEASE_DEBINFO)
	set(OPTIONS_RELEASE_MINSIZE)
	if(MSVC)                                         # MSVC
		set(OPTIONS_DEBUG           ${MSVC_DEBUG})
		set(OPTIONS_RELEASE         ${MSVC_RELEASE})
		set(OPTIONS_RELEASE_DEBINFO ${MSVC_RELEASE_DEBINFO})
		set(OPTIONS_RELEASE_MINSIZE ${MSVC_RELEASE_MINSIZE})
	elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")     # GCC
		set(OPTIONS_DEBUG           ${GCC_DEBUG})
		set(OPTIONS_RELEASE         ${GCC_RELEASE})
		set(OPTIONS_RELEASE_DEBINFO ${GCC_RELEASE_DEBINFO})
		set(OPTIONS_RELEASE_MINSIZE ${GCC_RELEASE_MINSIZE})
	elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang")    # Clang / AppleClang
		set(OPTIONS_DEBUG           ${CLANG_DEBUG})
		set(OPTIONS_RELEASE         ${CLANG_RELEASE})
		set(OPTIONS_RELEASE_DEBINFO ${CLANG_RELEASE_DEBINFO})
		set(OPTIONS_RELEASE_MINSIZE ${CLANG_RELEASE_MINSIZE})
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
	message(STATUS "- Linker flags for MinSizeRel     ${OPTIONS_RELEASE_MINSIZE}")

	# ----- Add flags to target -----
	target_link_options(${targetName} INTERFACE "$<$<CONFIG:Debug>:${OPTIONS_DEBUG}>")
	target_link_options(${targetName} INTERFACE "$<$<CONFIG:Release>:${OPTIONS_RELEASE}>")
	target_link_options(${targetName} INTERFACE "$<$<CONFIG:RelWithDebInfo>:${OPTIONS_RELEASE_DEBINFO}>")
	target_link_options(${targetName} INTERFACE "$<$<CONFIG:MinSizeRel>:${OPTIONS_RELEASE_MINSIZE}>")
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
