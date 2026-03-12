# Sets the most useful compiler warning tags for different compilers for each specific target.
# Source: https://github.com/lefticus/cppbestpractices/blob/master/02-Use_the_Tools_Available.md

# Use this function only on the predefined interface libraries.
function(set_target_options_warnings targetName)
	option(WARNINGS_AS_ERRORS "Treat compiler warnings as errors" TRUE)

	set(MSVC_WARNINGS
			/W4 # Baseline reasonable warnings
			/w14242 # 'identifier': conversion from 'type1' to 'type1', possible loss of data
			/w14254 # 'operator': conversion from 'type1:field_bits' to 'type2:field_bits', possible loss of data
			/w14263 # 'function': member function does not override any base class virtual member function
			/w14265 # 'classname': class has virtual functions, but destructor is not virtual instances of this class may not
			# be destructed correctly
			/w14287 # 'operator': unsigned/negative constant mismatch
			/we4289 # nonstandard extension used: 'variable': loop control variable declared in the for-loop is used outside
			# the for-loop scope
			/w14296 # 'operator': expression is always 'boolean_value'
			/w14311 # 'variable': pointer truncation from 'type1' to 'type2'
			/w14545 # expression before comma evaluates to a function which is missing an argument list
			/w14546 # function call before comma missing argument list
			/w14547 # 'operator': operator before comma has no effect; expected operator with side-effect
			/w14549 # 'operator': operator before comma has no effect; did you intend 'operator'?
			/w14555 # expression has no effect; expected expression with side- effect
			/w14619 # pragma warning: there is no warning number 'number'
			/w14640 # Enable warning on thread un-safe static member initialization
			/w14826 # Conversion from 'type1' to 'type_2' is sign-extended. This may cause unexpected runtime behavior.
			/w14905 # wide string literal cast to 'LPSTR'
			/w14906 # string literal cast to 'LPWSTR'
			/w14928 # illegal copy-initialization; more than one user-defined conversion has been implicitly applied
			/permissive- # standards conformance mode for MSVC compiler.
			)

	set(CLANG_WARNINGS
			-Wall
			-Wextra # reasonable and standard
			-Wshadow # warn the user if a variable declaration shadows one from a parent context
			-Wnon-virtual-dtor # warn the user if a class with virtual functions has a non-virtual destructor. This helps
			# catch hard to track down memory errors
			-Wold-style-cast # warn for c-style casts
			-Wcast-align # warn for potential performance problem casts
			-Wunused # warn on anything being unused
			-Woverloaded-virtual # warn if you overload (not override) a virtual function
			-Wpedantic # warn if non-standard C++ is used
			-Wconversion # warn on type conversions that may lose data
			-Wsign-conversion # warn on sign conversions
			-Wnull-dereference # warn if a null dereference is detected
			-Wdouble-promotion # warn if float is implicit promoted to double
			-Wformat=2 # warn on security issues around functions that format output (ie printf)
			)

	if(WARNINGS_AS_ERRORS)
		if("${CMAKE_BUILD_TYPE}" STREQUAL "Release")
			set(CLANG_WARNINGS ${CLANG_WARNINGS} -Werror)
			set(MSVC_WARNINGS ${MSVC_WARNINGS} /WX)
		endif()
	endif()

	set(GCC_WARNINGS
			${CLANG_WARNINGS}
			-Wmisleading-indentation # warn if indentation implies blocks where blocks do not exist
			-Wduplicated-cond # warn if if / else chain has duplicated conditions
			-Wduplicated-branches # warn if if / else branches have duplicated code
			-Wlogical-op # warn about logical operations being used where bitwise were probably wanted
			-Wuseless-cast # warn if you perform a cast to the same type
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
	message("- Enable Warning Settings: ${targetWarnings}")

	# ----- Add flags to target -----
	target_compile_options(${targetName} INTERFACE ${targetWarnings})
endfunction()

# Add default macros to the target.
function(set_target_options_macros_default targetName)
	set(ALL
		"$<$<CONFIG:Debug>:_DEBUG>"
		"$<$<CONFIG:Release>:NDEBUG>"
	)

	# ----- Print which flags used -----
	message("- Use Macro Definitions: ${ALL}")

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
	message("- Use Win Macro Definitions: ${OPTIONS}")

	# ----- Add flags to target -----
	target_compile_definitions(${targetName} INTERFACE ${OPTIONS})
endfunction()