# Description:
#  - Default Configuration + WINDOWS/MFC/ATL macros defined.
cmake_minimum_required(VERSION 3.27)

include_guard(GLOBAL)


include("${CMAKE_CURRENT_LIST_DIR}/ConfigDefault.cmake")


message(STATUS "")
message(STATUS "----- Configuration Default Windows -----")
message(STATUS "-----------------------------------------")
message(STATUS "- Use ALIAS:             Config::DefaultWin")
message(STATUS "- Use Compiler Flags:    Same as Default")
message(STATUS "- Use Linker Flags:      Same as Default")

set(targetName "ConfigDefaultWin")

add_library(${targetName} INTERFACE)
add_library(Config::DefaultWin ALIAS ${targetName})

target_link_libraries(${targetName} INTERFACE Config::Default) # Same base configuration as Config::Default
set_target_options_macros_win(${targetName})                   # Macro definitions

