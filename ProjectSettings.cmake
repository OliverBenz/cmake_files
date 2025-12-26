# The project settings contains information for
#  - Build type
#  - Optimization settings
#  - Output directory
#  - IDE project tree

# ----- Setup build type settings -----
if (NOT CMAKE_BUILD_TYPE)
    message(STATUS "No build type specified - 'Debug' used.")
    set(CMAKE_BUILD_TYPE Debug CACHE STRING "Choose the build type." FORCE)

    set_property(CACHE CMAKE_BUILD_TYPE
            PROPERTY STRINGS
            "Debug"
            "Release")
endif()

# Use different name for debug library.
set(CMAKE_DEBUG_POSTFIX d CACHE STRING "Add 'd' to lib name in Debug build")


# ----- Setup ide folders -----
set_property(GLOBAL PROPERTY USE_FOLDERS TRUE)  # In solution files; we want the projects to be categorized

set(IDE_FOLDER_SOURCE   "Source"   CACHE STRING "IDE folder for source projects.")
set(IDE_FOLDER_EXAMPLES "Examples" CACHE STRING "IDE folder for example projects.")
set(IDE_FOLDER_EXTERNAL "External" CACHE STRING "IDE folder for external projects.")
set(IDE_FOLDER_TESTS    "Tests"    CACHE STRING "IDE folder for testing projects.")


# ----- Helper functions -----
# Get the system architecture (x64, x86, etc) as a string.
# OUT_VAR [OUT] System architecture string.
function(project_settings_normalize_architecture OUT_VAR)
    set(_ps_arch "${CMAKE_SYSTEM_PROCESSOR}")
    if(NOT _ps_arch)
        set(_ps_arch "${CMAKE_HOST_SYSTEM_PROCESSOR}")
    endif()

    string(TOLOWER "${_ps_arch}" _ps_arch_lower)
    
    if(_ps_arch_lower STREQUAL "x86_64" OR _ps_arch_lower STREQUAL "amd64")
        set(_ps_arch_norm "x64")
    elseif(_ps_arch_lower STREQUAL "i386" OR _ps_arch_lower STREQUAL "i686")
        set(_ps_arch_norm "x86")
    elseif(_ps_arch_lower STREQUAL "aarch64" OR _ps_arch_lower STREQUAL "arm64")
        set(_ps_arch_norm "arm64")
    elseif(_ps_arch_lower MATCHES "^armv7")
        set(_ps_arch_norm "armv7")
    else()
        set(_ps_arch_norm "${_ps_arch}")
    endif()

    set(${OUT_VAR} "${_ps_arch_norm}" PARENT_SCOPE)
    
    unset(_ps_arch)
    unset(_ps_arch_lower)
    unset(_ps_arch_norm)
endfunction()

# Get the required strings to construct the build directory output layout.
# ARCH_VAR   [OUT] System architecture as string.
# CONFIG_VAR [OUT] Build configuration as string.
# BASE_VAR   [OUT] Base path for the output directory.
function(project_settings_configure_build_layout ARCH_VAR CONFIG_VAR BASE_VAR)
    project_settings_normalize_architecture(_ps_arch_norm)

    set(${ARCH_VAR} "${_ps_arch_norm}" PARENT_SCOPE)
    set(${CONFIG_VAR} "$<CONFIG>" PARENT_SCOPE)
    set(${BASE_VAR} "${CMAKE_BINARY_DIR}/out" PARENT_SCOPE)

    unset(_ps_arch_norm)
endfunction()

# Get the required strings to construct the install directory output layout.
# ARCH_VAR   [OUT] System architecture as string.
# CONFIG_VAR [OUT] Build configuration as string.
# BASE_VAR   [OUT] Base path for the output directory.
# 
# PROJECT_NAME   [IN] Project name is added to the BASE_VAR
# INSTALL_PREFIX [IN] Installation path
function(project_settings_configure_install_layout ARCH_VAR CONFIG_VAR BASE_VAR)
    set(options)
    set(oneValueArgs PROJECT_NAME INSTALL_PREFIX)
    cmake_parse_arguments(INSTALLLAYOUT "" "${oneValueArgs}" "" ${ARGN})

    if(NOT INSTALLLAYOUT_PROJECT_NAME)
        message(FATAL_ERROR "project_settings_configure_install_layout requires PROJECT_NAME to be set.")
    endif()

    # Determine effective prefix (pure computation, no cache mutation)
    if(INSTALLLAYOUT_INSTALL_PREFIX)
        set(_ps_prefix "${INSTALLLAYOUT_INSTALL_PREFIX}")
    else()
        set(_ps_prefix "${CMAKE_INSTALL_PREFIX}")
    endif()

    # Normalize architecture naming
    project_settings_normalize_architecture(_ps_arch_norm)

    # Export computed layout
    set(${ARCH_VAR}  "${_ps_arch_norm}" PARENT_SCOPE)
    set(${CONFIG_VAR} "\${CMAKE_INSTALL_CONFIG_NAME}" PARENT_SCOPE)
    set(${BASE_VAR}  "${_ps_prefix}/${INSTALLLAYOUT_PROJECT_NAME}" PARENT_SCOPE)
endfunction()

function(set_compile_options targetName)
    set(optionsDebug)
    set(optionsRelease)

    # ----- Setup variables -----
    # MSVC compiler flags
    set(MSVC_DEBUG
        /MP  # Multiprocess compiling
        /Od  # Disable optimization
        /ZI  # Create full PDB file
    )
    set(MSVC_RELEASE
        /MP  # Multiprocess compiling
        /O2  # Maximize speed
        /Zi  # Create small PDB while keeping optimization
    )

    # GCC compiler flags
    set(GCC_DEBUG
        -Og  # No optimization
        -g   # Create debugging information
    )
    set(GCC_RELEASE
        -O3  # Maximize optimization
        -g   # Create debugging information (May sometimes be weird because of optimization)
    )

    # Clang compiler flags
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

    if(MSVC)                                         # MSVC
        set(OPTIONS_DEBUG   ${MSVC_DEBUG})
        set(OPTIONS_RELEASE ${MSVC_RELEASE})
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")     # GCC
        set(OPTIONS_DEBUG   ${GCC_DEBUG})
        set(OPTIONS_RELEASE ${GCC_RELEASE})
    elseif(CMAKE_CXX_COMPILER_ID MATCHES ".*Clang")  # Clang / AppleClang
        set(OPTIONS_DEBUG   ${CLANG_DEBUG})
        set(OPTIONS_RELEASE ${CLANG_RELEASE})
    else()                                           # Else
        message(AUTHOR_WARNING "No extra compiler flags set for '${CMAKE_CXX_COMPILER_ID}' compiler.")
    endif()


    # ----- Print which flags used -----
    message(STATUS "Compiler flags for Debug   ${OPTIONS_DEBUG}")
    message(STATUS "Compiler flags for Release ${OPTIONS_RELEASE}")

    # ----- Add flags to target -----
    target_compile_options(${targetName} PRIVATE "$<$<CONFIG:DEBUG>:${OPTIONS_DEBUG}>")
    target_compile_options(${targetName} PRIVATE "$<$<CONFIG:RELEASE>:${OPTIONS_RELEASE}>")
endfunction()


function(set_compile_definitions targetName)
    # NOTE: NDEBUG is already defined by default
    # target_compile_definitions(${targetName} PRIVATE $<$<CONFIG:Debug>:DEBUG>>)
    # target_compile_definitions(${targetName} PRIVATE $<$<CONFIG:Release>:NDEBUG>>)
endfunction()

# Set the output directory of a given target
# targetName [IN] target name. 
function(set_output_directory targetName)
    # Get the sanitized variables 
    project_settings_configure_build_layout(
        _ps_arch
        _ps_config
        _ps_build_base
    )

    set_target_properties(${targetName}
        PROPERTIES
        ARCHIVE_OUTPUT_DIRECTORY "${_ps_build_base}/lib/${_ps_arch}/${_ps_config}"
        LIBRARY_OUTPUT_DIRECTORY "${_ps_build_base}/lib/${_ps_arch}/${_ps_config}"
        RUNTIME_OUTPUT_DIRECTORY "${_ps_build_base}/bin/${_ps_arch}/${_ps_config}"
    )
endfunction()
