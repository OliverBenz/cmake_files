# Description:
#  - Default Configuration + WINDOWS/MFC/ATL macros defined.
cmake_minimum_required(VERSION 3.27)

include_guard(GLOBAL)


include("${CMAKE_CURRENT_LIST_DIR}/ConfigDefault.cmake")

function(set_target_options_macros targetName)
	set(OPTIONS
		"$<$<CONFIG:Debug>:_DEBUG>"
		"$<$<CONFIG:Release>:NDEBUG>"
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
	message("- Use Macro Definitions: ${OPTIONS}")

	# ----- Add flags to target -----
	target_compile_definitions(${targetName} INTERFACE ${OPTIONS})
endfunction()


message("----- Configuration Default Windows -----")
message("-----------------------------------------")
message("- Use ALIAS:             Config::DefaultWin")
message("- Use Compiler Flags:    Same as Default")
message("- Use Linker Flags:      Same as Default")

set(targetName "ConfigDefaultWin")

add_library(${targetName} INTERFACE)
add_library(Config::DefaultWin ALIAS ${targetName})

target_link_libraries(${targetName} INTERFACE Config::Default) # Same base configuration as Config::Default
set_target_options_macros(${targetName})                       # Macro definitions

