# Description:
#  - Compiler/Linker: Only parallel build, optimization, and debug information settings
#  - Macros:          Only _DEBUG and NDEBUG macros
#  - Warnings:        No special setup
cmake_minimum_required(VERSION 3.27)

include_guard(GLOBAL)


function(_set_target_options_compiler_min targetName)
	# ----- Setup variables -----
	# MSVC compiler flags
	set(MSVC_ALL
		/MP         # Enable multiprocessor compilation.
		/FS         # Force synchronous .pdb file write. Required for /MP.
	)
	set(MSVC_DEBUG
		${MSVC_ALL}
		/Od         # Optimization disabled. Fast compilation and simplify debugging.
		/ZI         # Produce a PDB that supports the Edit and Continue feature. Auto-Sets: /Gy in linker
	)
	set(MSVC_RELEASE
		${MSVC_ALL}
		/O2         # Optimization for speed.            Auto-Sets:  /Gy
	)
	set(MSVC_RELEASE_DEBINFO
		${MSVC_ALL}
		/O2         # Optimization for speed.            Auto-Sets:  /Gy
		/Zi         # Produce a PDB that contains all the symbolic debugging information.
	)

	# GCC compiler flags
	set(GCC_DEBUG
		-Og  # No optimization
		-g   # Create debugging information
	)
	set(GCC_RELEASE
		-O3  # Maximize optimization
	)
	set(GCC_RELEASE_DEBINFO
		-O3  # Maximize optimization
		-g   # Create debugging information
	)


	# Clang compiler flags
	set(CLANG_DEBUG
		-Og  # No optimization
		-g   # Create debugging information
	)
	set(CLANG_RELEASE
		-O3  # Maximize optimization
	)
	set(CLANG_RELEASE_DEBINFO
		-O3  # Maximize optimization
		-g   # Create debugging information (May sometimes be weird because of optimization)
	)

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

function(_set_target_options_linker_min targetName)
	# ----- Setup variables -----

	# MSVC linker flags
	set(MSVC_DEBUG
		/DEBUG       # Create a debugging information file for the executable.
		/OPT:NOREF   # Keep unreferenced functions.      Set by default when /DEBUG is specified.
		/OPT:NOICF   # Disable identical COMDAT folding. Set by default when /DEBUG is specified.
	)
	set(MSVC_RELEASE
		/OPT:REF        # Remove unreferenced functions.   Set by default unless /DEBUG is specified. Disables /INCREMENTAL
		/OPT:ICF        # Enable identical COMDAT folding. Set by default unless /DEBUG is specified.
	)
	set(MSVC_RELEASE_DEBINFO
		/DEBUG           # Create a debugging information file for the executable.
		${MSVC_RELEASE}  # Ensure /OPT explicitly set. Default off due to /DEBUG.
	)

	# GCC linker flags
	# TODO

	# Clang linker flags
	# TODO

	set(OPTIONS_DEBUG)
	set(OPTIONS_RELEASE)
	set(OPTIONS_RELEASE_DEBINFO)

	if(MSVC)                                         # MSVC
		set(OPTIONS_DEBUG   ${MSVC_DEBUG})
		set(OPTIONS_RELEASE ${MSVC_RELEASE})
		set(OPTIONS_RELEASE ${MSVC_RELEASE_DEBINFO})
	elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")     # GCC
		set(OPTIONS_DEBUG   ${GCC_DEBUG})
		set(OPTIONS_RELEASE ${GCC_RELEASE})
		# TODO: DEBINFO
	elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang")  # Clang / AppleClang
		set(OPTIONS_DEBUG   ${CLANG_DEBUG})
		set(OPTIONS_RELEASE ${CLANG_RELEASE})
		# TODO: DEBINFO
	else()                                           # Else
		message(AUTHOR_WARNING "No extra linker flags set for '${CMAKE_CXX_COMPILER_ID}' compiler.")
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


message("----- Configuration Minimal -----")
message("---------------------------------")
message("- Use ALIAS:             Config::Minimal")

set(targetName "ConfigMinimal")

add_library(${targetName} INTERFACE)
add_library(Config::Minimal ALIAS ${targetName})

target_compile_features(${targetName} INTERFACE cxx_std_20)  # Special features
_set_target_options_compiler_min(${targetName})              # Compiler Flags
_set_target_options_linker_min(${targetName})                # Linker   Flags
set_target_options_macros_default(${targetName})             # Macro definitions
