# Description:
#  - CLR Configuration + WINDOWS/MFC/ATL macros defined.
cmake_minimum_required(VERSION 3.27)

include_guard(GLOBAL)


include("${CMAKE_CURRENT_LIST_DIR}/ConfigClr.cmake")


if(NOT MSVC)
	return() # CLR Configuration only exists for MSVC
endif()

message(STATUS "")
message(STATUS "----- Configuration CLR Win -----")
message(STATUS "---------------------------------")
message(STATUS "- Use ALIAS:             Config::ClrWin")
message(STATUS "- Use Compiler Flags:    Same as Config::Clr")
message(STATUS "- Use Linker Flags:      Same as Config::Clr")

set(targetName "ConfigClrWin")

add_library(${targetName} INTERFACE)
add_library(Config::ClrWin ALIAS ${targetName})

target_link_libraries(${targetName} INTERFACE Config::Clr) # Same base configuration as Config::Clr
set_target_options_macros_win(${targetName})               # Macro definitions
