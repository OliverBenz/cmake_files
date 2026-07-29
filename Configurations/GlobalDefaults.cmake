include_guard(GLOBAL)

# Use this function only on the predefined interface libraries.
function(set_target_options_warnings targetName)
	# Microslop disables noisy warnings. We prefer finding bugs.
	set(MSVC_WARNINGS
		/W4     # Baseline reasonable warnings

		# ATL Related
		/w14905 # Wide string literal cast to 'LPSTR'
		/w14906 # String literal cast to 'LPWSTR'
		/w14165 # 'HRESULT' is being converted to 'bool'; are you sure this is what you want?

		# Comma Invalid
		/w14545 # expression before comma evaluates to a function which is missing an argument list
		/w14546 # function call before comma missing argument list
		/w14547 # 'operator': operator before comma has no effect; expected operator with side-effect
		/w14548 # expression before comma has no effect; expected expression with side-effect
		/w14549 # 'operator1': operator before comma has no effect; did you intend 'operator2'?

		# Data Loss
		/w14242 # 'identifier': conversion from 'type1' to 'type2', possible loss of data
		/w14254 # 'operator': conversion from 'type1' to 'type2', possible loss of data
		/w14365 # 'action': conversion from 'type_1' to 'type_2', signed/unsigned mismatch
		/w14388 # signed/unsigned mismatch
		/w14287 # 'operator': unsigned/negative constant mismatch
		/w14800 # Implicit conversion from 'type' to bool. Possible information loss 16.0
		/w14826 # Conversion from 'type1' to 'type2' is sign-extended. This may cause unexpected runtime behavior.
		/w15219 # implicit conversion from 'type-1' to 'type-2', possible loss of data 16.7
		/w14302 # 'conversion': truncation from 'type1' to 'type2'
		/w14311 # 'variable': pointer truncation from 'type' to 'type'

		# Safety
		/w14061 # enumerator 'identifier' in a switch of enum 'enumeration' is not explicitly handled by a case label.
		/w14062 # enumerator 'identifier' in a switch of enum 'enumeration' is not handled.
		/w14191 # 'operator': unsafe conversion from 'type_of_expression' to 'type_required'
		/w14263 # 'function': member function does not override any base class virtual member function
		/w14264 # 'virtual_function': no override available for virtual member function from base 'class'; function is hidden
		/w14265 # 'class': class has virtual functions, but destructor is not virtual
		/w14266 # 'function': no override available for virtual member function from base 'type'; function is hidden
		/w14928 # Illegal copy-initialization; more than one user-defined conversion has been implicitly applied

		# Object Model
		/w15038 # data member 'member1' will be initialized after data member 'member2' 15.3
		/w14623 # default constructor could not be generated because a base class default constructor is inaccessible
		/w14625 # copy constructor could not be generated because a base class copy constructor is inaccessible
		/w14626 # assignment operator could not be generated because a base class assignment operator is inaccessible

		# Hygiene
		/w14555 # expression has no effect; expected expression with side-effect
		/w34619 # #pragma warning: there is no warning number 'number'
		/w44296 # 'operator': expression is always false
		/w44464 # relative include path contains '..'
		/w44654 # Code placed before include of precompiled header line will be ignored. Add code to precompiled header. 14.1
		/w14822 # 'member': local class member function does not have a body
		/w14946 # reinterpret_cast used between related classes: 'class1' and 'class2'
		/w45031 # #pragma warning(pop): likely mismatch, popping warning state pushed in different file 14.1
		/w45032 # detected #pragma warning(push) with no corresponding #pragma warning(pop) 14.1
		/w45233 # explicit lambda capture 'identifier' is not used 16.10
		/w45240 # 'attribute-name': attribute is ignored in this syntactic position 16.10
		/w15246 # 'member': the initialization of a subobject should be wrapped in braces 16.10
		/w45258 # explicit capture of 'symbol' is not required for this use 17.2
		/w45263 # calling 'std::move' on a temporary object prevents copy elision 17.4
		/w45264 # 'variable-name': 'const' variable is not used 17.4
		/w45266 # 'const' qualifier on return type has no effect 17.6
		/w44289 # nonstandard extension used : 'var' : loop control variable declared in the for-loop is used outside the for-loop scope

		# Standard Compliance
		/w14987 # nonstandard extension used: 'throw (...)'
		/w15029 # nonstandard extension used: alignment attributes in C++ apply to variables, data members and tag types only
		/w15042 # 'function': function declarations at block scope cannot be specified 'inline' in standard C++; remove 'inline' specifier 15.5

		$<$<NOT:$<CONFIG:Debug>>:/WX> # Warnings as errors
	)

	set(CLANG_WARNINGS
		-Wall
		-Wextra                      # Reasonable and standard
		-Wpedantic                   # Warn if non-standard C++ is used
		-Wshadow                     # Warn the user if a variable declaration shadows one from a parent context
		-Wnon-virtual-dtor           # Warn the user if a class with virtual functions has a non-virtual destructor. This helps

		# Catch hard to track down memory errors
		-Wold-style-cast             # Warn for c-style casts
		-Wcast-align                 # Warn for potential performance problem casts
		-Wunused                     # Warn on anything being unused
		-Woverloaded-virtual         # Warn if you overload (not override) a virtual function
		-Wconversion                 # Warn on type conversions that may lose data
		-Wsign-conversion            # Warn on sign conversions
		-Wnull-dereference           # Warn if a null dereference is detected
		-Wdouble-promotion           # Warn if float is implicit promoted to double
		-Wformat=2                   # Warn on security issues around functions that format output (ie printf)

		# Warnings as errors on Release builds
		$<$<CONFIG:Release,RelWithDebInfo,MinSizeRel>:-Werror>
	)

	set(GCC_WARNINGS
		${CLANG_WARNINGS}
		-Wmisleading-indentation # Warn if indentation implies blocks where blocks do not exist
		-Wduplicated-cond        # Warn if if / else chain has duplicated conditions
		-Wduplicated-branches    # Warn if if / else branches have duplicated code
		-Wlogical-op             # Warn about logical operations being used where bitwise were probably wanted
		-Wuseless-cast           # Warn if you perform a cast to the same type
	)

	unset(targetWarnings)
	if(MSVC)
		set(targetWarnings ${MSVC_WARNINGS})
	elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
		set(targetWarnings ${CLANG_WARNINGS})
	elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
		set(targetWarnings ${GCC_WARNINGS})
	else()
		message(AUTHOR_WARNING "No compiler warnings set for '${CMAKE_CXX_COMPILER_ID}' compiler.")
		return()
	endif()

	# ----- Print which flags used -----
	message(STATUS "- Enable Warnings Settings: ${targetWarnings}")

	# ----- Add flags to target -----
	target_compile_options(${targetName} INTERFACE ${targetWarnings})
endfunction()

# Add default macros to the target.
function(set_target_options_macros targetName)
	set(DEFAULTS
		"$<$<CONFIG:Release,RelWithDebInfo,MinSizeRel>:NDEBUG>" # Standard NDEBUG
	)
	set(MSVC_MACROS
		${DEFAULTS}
	)
	set(GCC_MACROS
		${DEFAULTS}
		"$<$<CONFIG:Debug>:_GLIBCXX_ASSERTIONS>" # Enable ABI-safe libstdc++ assertions for debug builds
	)
	set(CLANG_MACROS
		${DEFAULTS}
		"$<$<AND:$<CONFIG:Debug>,$<PLATFORM_ID:Darwin>>:_LIBCPP_DEBUG=1>"    # macOS Clang uses libc++
		"$<$<AND:$<CONFIG:Debug>,$<PLATFORM_ID:Linux>>:_GLIBCXX_ASSERTIONS>" # Linux Clang usually uses libstdc++
	)

	unset(OPTIONS)
	if(MSVC)                                         # MSVC
		set(OPTIONS ${MSVC_MACROS})
	elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")     # GCC
		set(OPTIONS   ${GCC_MACROS})
		message(STATUS "- GNU libstdc++ ABI-safe assertions enabled in Debug builds (_GLIBCXX_ASSERTIONS).")
	elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang")    # Clang / AppleClang
		set(OPTIONS   ${CLANG_MACROS})
		message(STATUS "- GNU libstdc++ ABI-safe assertions enabled in Debug builds (_GLIBCXX_ASSERTIONS).")
	else()                                           # Else
		message(AUTHOR_WARNING "No extra macro definitions set for '${CMAKE_CXX_COMPILER_ID}' compiler.")
		return()
	endif()

	# ----- Print which flags used -----
	message(STATUS "- Use Macro Definitions: ${OPTIONS}")

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
