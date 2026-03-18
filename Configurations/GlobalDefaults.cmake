# Use this function only on the predefined interface libraries.
function(set_target_options_warnings targetName)
	set(MSVC_WARNINGS
		/W4 # Baseline reasonable warnings

		/w14242 # 'identifier': conversion from 'type1' to 'type1', possible loss of data
		/w14254 # 'operator': conversion from 'type1:field_bits' to 'type2:field_bits', possible loss of data
		/w14263 # 'function': member function does not override any base class virtual member function
		/w14265 # 'classname': class has virtual functions, but destructor is not virtual instances of this class may not

		# Be destructed correctly
		/w14287 # 'operator': unsigned/negative constant mismatch
		/we4289 # Nonstandard extension used: 'variable': loop control variable declared in the for-loop is used outside

		# The for-loop scope
		/w14296 # 'operator': expression is always 'boolean_value'
		/w14311 # 'variable': pointer truncation from 'type1' to 'type2'
		/w14545 # Expression before comma evaluates to a function which is missing an argument list
		/w14546 # Function call before comma missing argument list
		/w14547 # 'operator': operator before comma has no effect; expected operator with side-effect
		/w14549 # 'operator': operator before comma has no effect; did you intend 'operator'?
		/w14555 # Expression has no effect; expected expression with side- effect
		/w14619 # Pragma warning: there is no warning number 'number'
		/w14640 # Enable warning on thread un-safe static member initialization
		/w14826 # Conversion from 'type1' to 'type_2' is sign-extended. This may cause unexpected runtime behavior.
		/w14905 # Wide string literal cast to 'LPSTR'
		/w14906 # String literal cast to 'LPWSTR'
		/w14928 # Illegal copy-initialization; more than one user-defined conversion has been implicitly applied

		$<$<CONFIG:Release,RelWithDebInfo,MinSizeRel>:/WX> # Warnings as errors
	)

	set(CLANG_WARNINGS
		-Wall
		-Wextra                      # Reasonable and standard
		-Wshadow                     # Warn the user if a variable declaration shadows one from a parent context
		-Wnon-virtual-dtor           # Warn the user if a class with virtual functions has a non-virtual destructor. This helps

		# Catch hard to track down memory errors
		-Wold-style-cast             # Warn for c-style casts
		-Wcast-align                 # Warn for potential performance problem casts
		-Wunused                     # Warn on anything being unused
		-Woverloaded-virtual         # Warn if you overload (not override) a virtual function
		-Wpedantic                   # Warn if non-standard C++ is used
		-Wconversion                 # Warn on type conversions that may lose data
		-Wsign-conversion            # Warn on sign conversions
		-Wnull-dereference           # Warn if a null dereference is detected
		-Wdouble-promotion           # Warn if float is implicit promoted to double
		-Wformat=2                   # Warn on security issues around functions that format output (ie printf)

		$<$<CONFIG:Release,RelWithDebInfo,MinSizeRel>:-Werror> # Warnings as errors
	)

	set(GCC_WARNINGS
		${CLANG_WARNINGS}
		-Wmisleading-indentation # Warn if indentation implies blocks where blocks do not exist
		-Wduplicated-cond        # Warn if if / else chain has duplicated conditions
		-Wduplicated-branches    # Warn if if / else branches have duplicated code
		-Wlogical-op             # Warn about logical operations being used where bitwise were probably wanted
		-Wuseless-cast           # Warn if you perform a cast to the same type
	)

	set(targetWarnings)
	if(MSVC)
		set(targetWarnings ${MSVC_WARNINGS})
	elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
		set(targetWarnings ${CLANG_WARNINGS})
	elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
		set(targetWarnings ${GCC_WARNINGS})
	else()
		message(AUTHOR_WARNING "No compiler warnings set for '${CMAKE_CXX_COMPILER_ID}' compiler.")
	endif()

	# ----- Print which flags used -----
	message(STATUS "- Enable Warning Settings: ${targetWarnings}")

	# ----- Add flags to target -----
	target_compile_options(${targetName} INTERFACE ${targetWarnings})
endfunction()

# Add default macros to the target.
function(set_target_options_macros_default targetName)
	set(ALL
		"$<$<CONFIG:Release,RelWithDebInfo,MinSizeRel>:NDEBUG>"
	)

	# ----- Print which flags used -----
	message(STATUS "- Use Macro Definitions: ${ALL}")

	# ----- Add flags to target -----
	target_compile_definitions(${targetName} INTERFACE ${OPTIONS})
endfunction()

# Add macros to the target specific for windows development.
function(set_target_options_macros_win targetName)
	set(OPTIONS
		NOMINMAX                            # Disable min and max macros from the MFC STL.
		WIN32_LEAN_AND_MEAN                 # Exclude rarely used includes from windows.h such as Cryptography, DDE, RPC, Shell, and Windows Sockets.
		VC_EXTRALEAN                        # Exclude rarely used includes from MFC headers.
		STRICT                              # Strict type checking in winapi. Helps us write more portable code.
		STRICT_TYPED_ITEMIDS                # Strict type checking in shell headers. Helps us write more portable code.
		_ATL_CSTRING_EXPLICIT_CONSTRUCTORS  # Makes certain CString constructors explicit.
		_ATL_ALL_WARNINGS                   # Enables warnings that were disabled in old versions of ATL.
		_AFX_ALL_WARNINGS                   # Enables all warnings hidden by MFC
	)

	# ----- Print which flags used -----
	message(STATUS "- Use Win Macro Definitions: ${OPTIONS}")

	# ----- Add flags to target -----
	target_compile_definitions(${targetName} INTERFACE ${OPTIONS})
endfunction()