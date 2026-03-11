include_guard(GLOBAL)

# TODO: Whole program optimization
# TODO: Move flags for gcc and clang
# TODO: RelWithDebInfo for gcc and clang
# TODO: MinSizeRel
function(set_target_options_compiler targetName)
    # ----- Setup variables -----
    # MSVC compiler flags
	set(MSVC_ALL
		/W4            # Enable warning level 4.
		/MP            # Enable multiprocessor compilation.
		/FS            # Force synchronous .pdb file write. Required for /MP.
		/GS            # Buffer Security Check enabled.
		/GR            # Adds code to check object types at run time. On by default.
		/Gd            # Calling Convention. Explicitly use default (/Gd -> __cdecl).
		/EHsc          # Exception handling model. 's' .. Standard stack unwinding and 'c' .. extern "C" functions never throw C++ exceptions.
		/fp:precise    # Floating-point behavior precise. Explicitly use default: precise.
		/permissive-   # Enforce ISO C++ standard compliance.
	)

	# TODO: Whole program optimization per target

    set(MSVC_DEBUG
		${MSVC_ALL}
        /Od   # Optimization disabled. Fast compilation and simplify debugging.
		/RTC1 # Enable Runtime Error Checks. Equivalent to RTCsu.
		/Gy   # Enable Function-Level Linking. Auto-Set by /ZI
		/ZI   # Produce a PDB that supports the Edit and Continue feature. Auto-Sets: /Gy in linker
    )
    set(MSVC_RELEASE
		${MSVC_ALL}
        /O2   # Optimization for speed.        Auto-Sets:  /Gy
		/Gy   # Enable Function-Level Linking. Auto-Set by /O2
    )
	set(MSVC_RELEASE_DEBINFO
		${MSVC_RELEASE}
		/Zi   # Produce a PDB that contains all the symbolic debugging information.
	)

    # GCC compiler flags
	# TODO: GCC_ALL for more flags
	# TODO: GCC_RELEASE_DEBINFO
    set(GCC_DEBUG
        -Og  # No optimization
        -g   # Create debugging information
    )
    set(GCC_RELEASE
        -O3  # Maximize optimization
        -g   # Create debugging information (May sometimes be weird because of optimization)
    )

    # Clang compiler flags
	# TODO: CLANG_ALL for more flags
	# TODO: CLANG_RELEASE_DEBINFO
    set(CLANG_DEBUG
        -Og  # No optimization
        -g   # Create debugging information
    )
    set(CLANG_RELEASE
        -O3  # Maximize optimization
        -g   # Create debugging information (May sometimes be weird because of optimization)
    )

    # ----- Switch which variables to use -----
    # Use the correct set of options depending on the compiler
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
        message(AUTHOR_WARNING "No extra compiler flags set for '${CMAKE_CXX_COMPILER_ID}' compiler.")
    endif()


    # ----- Print which flags used -----
    message(STATUS "Compiler flags for Debug          ${OPTIONS_DEBUG}")
    message(STATUS "Compiler flags for Release        ${OPTIONS_RELEASE}")
	message(STATUS "Compiler flags for RelWithDebInfo ${OPTIONS_RELEASE_DEBINFO}")

    # ----- Add flags to target -----
	target_compile_options(${targetName} INTERFACE "$<$<CONFIG:Debug>:${OPTIONS_DEBUG}>")
	target_compile_options(${targetName} INTERFACE "$<$<CONFIG:Release>:${OPTIONS_RELEASE}>")
	target_compile_options(${targetName} INTERFACE "$<$<CONFIG:RelWithDebInfo>:${OPTIONS_RELEASE_DEBINFO}>")
endfunction()


function(set_target_options_linker targetName)
    # ----- Setup variables -----

    # MSVC linker flags
	set(MSVC_DEBUG
		/DEBUG       # Create a debugging information file for the executable.
		/INCREMENTAL # Link incrementally. Don't always perform a full link.
		/OPT:NOREF   # Keep unreferenced functions.      Set by default when /DEBUG is specified.
		/OPT:NOICF   # Disable identical COMDAT folding. Set by default when /DEBUG is specified.
	)
	set(MSVC_RELEASE
		/INCREMENTAL:NO # Always perform a full link. /INCREMENTAL not compatible with /LTCG (in WholeProgramOptimization)
		/OPT:REF        # Remove unreferenced functions.   Set by default unless /DEBUG is specified. Disables /INCREMENTAL
		/OPT:ICF        # Enable identical COMDAT folding. Set by default unless /DEBUG is specified.
		$<$<STREQUAL:${CMAKE_VS_PLATFORM_NAME},Win32>:/SAFESEH>  # Only produces an image if we can produce a table of the image's safe exception handlers. Only valid for x86 targets.
	)
	set(MSVC_RELEASE_DEBINFO
		/DEBUG           # Create a debugging information file for the executable.
		/INCREMENTAL:NO  # Always perform a full link. /INCREMENTAL not compatible with /LTCG (in WholeProgramOptimization)
		/OPT:REF         # Remove unreferenced functions.   Set by default unless /DEBUG is specified. Disables /INCREMENTAL
		/OPT:ICF         # Enable identical COMDAT folding. Set by default unless /DEBUG is specified.
		$<$<STREQUAL:${CMAKE_VS_PLATFORM_NAME},Win32>:/SAFESEH>  # Only produces an image if we can produce a table of the image's safe exception handlers. Only valid for x86 targets.
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
	message(STATUS "Linker flags for Debug          ${OPTIONS_DEBUG}")
	message(STATUS "Linker flags for Release        ${OPTIONS_RELEASE}")
	message(STATUS "Linker flags for RelWithDebInfo ${OPTIONS_RELEASE_DEBINFO}")

    # ----- Add flags to target -----
	target_link_options(${targetName} INTERFACE "$<$<CONFIG:Debug>:${OPTIONS_DEBUG}>")
	target_link_options(${targetName} INTERFACE "$<$<CONFIG:Release>:${OPTIONS_RELEASE}>")
	target_link_options(${targetName} INTERFACE "$<$<CONFIG:RelWithDebInfo>:${OPTIONS_RELEASE_DEBINFO}>")
endfunction()


function(set_target_options_macros targetName)
	set(ALL
		"$<$<CONFIG:Debug>:_DEBUG>"
		"$<$<CONFIG:Release>:NDEBUG>"
	)
	set(MSVC_FLAGS
		${ALL}
		NOMINMAX                            # Disable min and max macros from the MFC STL.
		WIN32_LEAN_AND_MEAN                 # Exclude rarely used includes from windows.h such as Cryptography, DDE, RPC, Shell, and Windows Sockets.
		VC_EXTRALEAN                        # Exclude rarely used includes from MFC headers.
		STRICT                              # Strict type checking in winapi. Helps us write more portable code.
		STRICT_TYPED_ITEMIDS                # Strict type checking in shell headers. Helps us write more portable code.
		_ATL_CSTRING_EXPLICIT_CONSTRUCTORS  # Makes certain CString constructors explicit.
		_ATL_ALL_WARNINGS                   # Enables warnings that were disabled in old versions of ATL.
		_AFX_ALL_WARNINGS                   # Enables all warnings hidden by MFC
	)

	# TODO: Clang and gcc different?

	set(OPTIONS)

    if(MSVC)                                         # MSVC
		set(OPTIONS ${MSVC_FLAGS})
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")     # GCC
		set(OPTIONS ${MSVC_FLAGS})
    elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang")    # Clang / AppleClang
		set(OPTIONS ${MSVC_FLAGS})
    else()                                           # Else
        message(AUTHOR_WARNING "No extra macro definitions set for '${CMAKE_CXX_COMPILER_ID}' compiler.")
    endif()

    # ----- Print which flags used -----
	message(STATUS "Macro definitions: ${OPTIONS_DEBUG}")

    # ----- Add flags to target -----
	target_compile_definitions(${targetName} INTERFACE ${OPTIONS})
endfunction()


set(targetName "ProjectDef")

add_library(${targetName} INTERFACE)

target_compile_features(${targetName} INTERFACE cxx_std_20)  # Special features
set_target_options_warnings(${targetName})                   # Warning  Flags
set_target_options_compiler(${targetName})                   # Compiler Flags
set_target_options_linker(${targetName})                     # Linker   Flags
set_target_options_macros(${targetName})                     # Macro definitions

