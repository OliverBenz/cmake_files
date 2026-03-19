# Description:
#  - Compiler/Linker: Only parallel build, optimization, and debug information settings
#  - Macros:          Only _DEBUG and NDEBUG macros
#  - Warnings:        No special setup
cmake_minimum_required(VERSION 3.27)

include_guard(GLOBAL)


include("${CMAKE_CURRENT_LIST_DIR}/GlobalDefaults.cmake")


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
	set(MSVC_RELEASE_MINSIZE
		${MSVC_ALL}
		/O1         # Optimization for size.            Auto-Sets:  /Gy
	)

	# GCC compiler flags
	set(GCC_DEBUG
		-Og  # No optimization
		-g3  # Create debugging information
	)
	set(GCC_RELEASE
		-O3  # Maximize optimization
	)
	set(GCC_RELEASE_DEBINFO
		-O3  # Maximize optimization
		-g   # Create debugging information
	)
	set(GCC_RELEASE_MINSIZE
		-Os  # Optimization for size
		-g   # Create debugging information
	)

	# Clang compiler flags
	set(CLANG_DEBUG
		-Og  # No optimization
		-g3  # Create debugging information
	)
	set(CLANG_RELEASE
		-O3  # Maximize optimization
	)
	set(CLANG_RELEASE_DEBINFO
		-O3  # Maximize optimization
		-g   # Create debugging information (May sometimes be weird because of optimization)
	)
	set(CLANG_RELEASE_MINSIZE
		-Os  # Optimization for size
	)

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
	set(MSVC_RELEASE_MINSIZE ${MSVC_RELEASE})

	# GCC linker flags
	set(GCC_ALL
		$<$<BOOL:${LLD_LINKER}>:-fuse-ld=lld>  # Use LLD Linker is available
	)
	set(GCC_DEBUG
		${GCC_ALL}
		-Wl,--no-gc-sections # Keep all sections - opposite of release, don't strip anything
	)
	set(GCC_RELEASE
		${GCC_ALL}
		-Wl,--gc-sections # Strip unused sections
	)
	set(GCC_RELEASE_DEBINFO ${GCC_RELEASE})
	set(GCC_RELEASE_MINSIZE ${GCC_RELEASE})

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
message(STATUS "----- Configuration Minimal -----")
message(STATUS "---------------------------------")
message(STATUS "- Use ALIAS:             Config::Minimal")

set(targetName "ConfigMinimal")

add_library(${targetName} INTERFACE)
add_library(Config::Minimal ALIAS ${targetName})

_set_target_options_compiler_min(${targetName})              # Compiler Flags
_set_target_options_linker_min(${targetName})                # Linker   Flags
set_target_options_macros(${targetName})                     # Macro definitions
