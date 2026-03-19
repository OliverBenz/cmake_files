# Description:
#  - Does not extend the Minimal configuration as it's really a special case. Keeping separate.
#  - Compiler/Linker: Parallel Build, Whole Program Optimization, Extra debug information and checks, explicitly set defaults.
#    Adds /clr compilation for windows 
#  - Macros:          Only _DEBUG and NDEBUG macros
#  - Warnings:        W4 and extra important warnings
# Compatibility notes:
#  - MSVC  only
#  - /ZI   not compatible with /clr. Using /Zi
#  - /MT   not compatible with /clr. Ensure /MD[d]  See: fix_runtime_library_for_clr
#  - /EHsc not compatible with /clr. Use /EHa
cmake_minimum_required(VERSION 3.27)

include_guard(GLOBAL)


include("${CMAKE_CURRENT_LIST_DIR}/GlobalDefaults.cmake")


if(NOT MSVC)
	return() # CLR Configuration only exists for MSVC
endif()

# ----- Helper function for configuration -----
function(_set_target_options_compiler_clr targetName)
	# ----- Setup variables -----
	set(MSVC_ALL
		# Common Language Runtime Compilation
		/clr

		/MP            # Enable multiprocessor compilation.
		/FS            # Force synchronous .pdb file write. Required for /MP.
		/GS            # Buffer Security Check enabled.
		/GR            # Adds code to check object types at run time. On by default.
		/Gd            # Calling Convention. Explicitly use default (/Gd -> __cdecl).
		/EHa           # Exception handling model. 'a' .. Catches both structured and standard C++ exceptions.
		/fp:precise    # Floating-point behavior precise. Explicitly use default: precise.
		/permissive-   # Enforce ISO C++ standard compliance.
	)
	set(MSVC_DEBUG
		${MSVC_ALL}
		/Od   # Optimization disabled. Fast compilation and simplify debugging.
		/Zi   # Produce a PDB that contains all the symbolic debugging information. /ZI incompatible with /clr
	)
	set(MSVC_RELEASE
		${MSVC_ALL}
		/O2   # Optimization for speed.            Auto-Sets:  /Gy
		/Gy   # Enable Function-Level Linking.     Auto-Set by /O2
		/GL   # Enable whole program optimization. Auto-Sets: linker /LTCG
	)
	set(MSVC_RELEASE_DEBINFO
		${MSVC_RELEASE}
		/Zi   # Produce a PDB that contains all the symbolic debugging information.
	)
	set(MSVC_RELEASE_MINSIZE
		${MSVC_ALL}
		/O1   # Optimization for size.             Auto-Sets:  /Gy
		/Gy   # Enable Function-Level Linking.     Auto-Set by /O2
	)

	# ----- Option: Override Release config -----
	if(RELEASE_EQUALS_RELWITHDEBINFO)
		message(STATUS "- Note: Using the RelWithDebInfo compiler configuration also for Release builds.")
		set(MSVC_RELEASE ${MSVC_RELEASE_DEBINFO})
	endif()

	# ----- Print which flags used -----
	message(STATUS "- Compiler flags for Debug          ${MSVC_DEBUG}")
	message(STATUS "- Compiler flags for Release        ${MSVC_RELEASE}")
	message(STATUS "- Compiler flags for RelWithDebInfo ${MSVC_RELEASE_DEBINFO}")
	message(STATUS "- Compiler flags for MinSizeRel     ${MSVC_RELEASE_MINSIZE}")

	# ----- Add flags to target -----
	target_compile_options(${targetName} INTERFACE "$<$<CONFIG:Debug>:${MSVC_DEBUG}>")
	target_compile_options(${targetName} INTERFACE "$<$<CONFIG:Release>:${MSVC_RELEASE}>")
	target_compile_options(${targetName} INTERFACE "$<$<CONFIG:RelWithDebInfo>:${MSVC_RELEASE_DEBINFO}>")
	target_compile_options(${targetName} INTERFACE "$<$<CONFIG:MinSizeRel>:${MSVC_RELEASE_MINSIZE}>")
endfunction()


# Note: We use CMAKE_SIZEOF_VOID_P (void pointer size) to check for x86 vs x64 on a MSVC flag.
function(_set_target_options_linker_clr targetName)
	# ----- Setup variables -----
	set(MSVC_DEBUG
		/DEBUG       # Create a debugging information file for the executable.
		/INCREMENTAL # Link incrementally. Don't always perform a full link.
		/OPT:NOREF   # Keep unreferenced functions.      Set by default when /DEBUG is specified.
		/OPT:NOICF   # Disable identical COMDAT folding. Set by default when /DEBUG is specified.
	)
	set(MSVC_RELEASE
		/LTCG           # Link-time code generation. For WholeProgramOptimization.
		/INCREMENTAL:NO # Always perform a full link. /INCREMENTAL not compatible with /LTCG (in WholeProgramOptimization)
		/OPT:REF        # Remove unreferenced functions.   Set by default unless /DEBUG is specified. Disables /INCREMENTAL
		/OPT:ICF        # Enable identical COMDAT folding. Set by default unless /DEBUG is specified.
		$<$<STREQUAL:${CMAKE_VS_PLATFORM_NAME},Win32>:/SAFESEH>  # Only produces an image if we can produce a table of the image's safe exception handlers. Only valid for x86 targets.
	)
	set(MSVC_RELEASE_DEBINFO
		/DEBUG           # Create a debugging information file for the executable.
		${MSVC_RELEASE}  # Ensure /OPT explicitly set. Default off due to /DEBUG.
	)
	set(MSVC_RELEASE_MINSIZE
		/INCREMENTAL:NO # Always perform a full link. /INCREMENTAL not compatible with /LTCG (in WholeProgramOptimization)
		/OPT:REF        # Remove unreferenced functions.   Set by default unless /DEBUG is specified. Disables /INCREMENTAL
		/OPT:ICF        # Enable identical COMDAT folding. Set by default unless /DEBUG is specified.
		$<$<EQUAL:${CMAKE_SIZEOF_VOID_P},4>:/SAFESEH>  # Only produces an image if we can produce a table of the image's safe exception handlers. Only valid for x86 targets.
	)
	
	# ----- Option: Override Release config -----
	if(RELEASE_EQUALS_RELWITHDEBINFO)
		message(STATUS "- Note: Using the RelWithDebInfo linker configuration also for Release builds.")
		set(MSVC_RELEASE ${MSVC_RELEASE_DEBINFO})
	endif()

	# ----- Print which flags used -----
	message(STATUS "- Linker flags for Debug          ${MSVC_DEBUG}")
	message(STATUS "- Linker flags for Release        ${MSVC_RELEASE}")
	message(STATUS "- Linker flags for RelWithDebInfo ${MSVC_RELEASE_DEBINFO}")
	message(STATUS "- Linker flags for MinSizeRel     ${MSVC_RELEASE_MINSIZE}")

	# ----- Add flags to target -----
	target_link_options(${targetName} INTERFACE "$<$<CONFIG:Debug>:${MSVC_DEBUG}>")
	target_link_options(${targetName} INTERFACE "$<$<CONFIG:Release>:${MSVC_RELEASE}>")
	target_link_options(${targetName} INTERFACE "$<$<CONFIG:RelWithDebInfo>:${MSVC_RELEASE_DEBINFO}>")
	target_link_options(${targetName} INTERFACE "$<$<CONFIG:MinSizeRel>:${MSVC_RELEASE_MINSIZE}>")
endfunction()


function(fix_runtime_library_for_clr TARGET_NAME)
	if(NOT MSVC)
		message(AUTHOR_WARNING "MSVC only configuration!") #What are you even doing?
		return()
	endif()

	# Set the MSVC_RUNTIME_LIBRARY to /MD[d]
	set_target_properties(${TARGET_NAME} PROPERTIES
		MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL"
	)
endfunction()


message(STATUS "")
message(STATUS "----- Configuration CLR -----")
message(STATUS "-----------------------------")
message(STATUS "- Use ALIAS:             Config::Clr")

set(targetName "ConfigClr")

add_library(${targetName} INTERFACE)
add_library(Config::Clr ALIAS ${targetName})

set_target_options_warnings(${targetName})                   # Warning  Flags
_set_target_options_compiler_clr(${targetName})              # Compiler Flags
_set_target_options_linker_clr(${targetName})                # Linker   Flags

set_target_options_macros(${targetName})                     # Macro definitions
