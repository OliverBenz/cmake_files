# The Policy System: Allows to specify a number of special policies per project. These may be specialised to your individual needs.
# Motivation:
#   Imagine you maintain a legacy windows codebase with heavy use of MFC and no clear separation of Data Layer, Business Logic, Presentation Layer, ..
#   You want to start splitting your targets apart to enfoce a clean separation of layers.
#   Problem: Who enforces that we only use MFC in the presentation layer?
#   Answer:  Custom Policies!
#     Each target may specify a set of policies (a set of custom variables specific to that target) which may be "ALLOW_USAGE_OF_MFC=OFF", for example, set_target_policies(ALLOW_USAGE_OF_MFC OFF ...).
#     At the end of your root CMakeLists, you can then generate custom yaml files that include said policies and connect any script to these yaml files which enforces the policies as you see fit.
#
# Note: Policies do not need to be restrictions but can be any information you may want to attach to a project. All the policies do is create yaml files. Since CMake already builds a database-like structure of our projects, why not reuse this system to collect more information?
#       The goal is simply to create a single source of truth of what a target is, what is can do, and how it must behave - not just how it's built.
#
# Usage: Include once in root CMakeLists.txt
#   1. Define output files and their policy mappings via policy_define_output()
#   2. Register targets via set_target_policies()
#   3. Call policy_generate_all() at the end of root CMakeLists.txt
#
# Full Example:
# -----------------------
#  // LibName.cmake
#  [...]
#  add_library(LibName STATIC [...])
#  [...]
#  set_target_policies(
#    ALLOW_USAGE_OF_MFC    ON                       # Allow this library to use MFC.
#    ALLOW_USAGE_OF_WINAPI ON                       # Allow this library to use the winapi.
#    RESOURCE_HEADER_PATH  "<Path>/LibNameRes.h"    # Full path to the resource header.
#    RESOURCE_ID_COUNT     200                      # Number of resources this library defined + padding.
#    ENFORCE_CLANG_FORMAT  ON                       # Force this library to adhere by our clang format rules.
#    DESCRIPTION           "One-line Documentation" # Single-Line documentation of this target.
#  )
#
# // Root: CMakeLists.txt
# policy_define_output(
#   FILE "${CMAKE_SOURCE_DIR}/Policies/Resources.yaml"
#   POLICIES
#     RESOURCE_HEADER_PATH AS "resource_header"
#     RESOURCE_ID_COUNT    AS "id_count"
# )
# policy_define_output(
#   FILE "${CMAKE_SOURCE_DIR}/Policies/Dependencies.yaml"
#   POLICIES
#     ALLOW_USAGE_OF_MFC    AS "allow_mfc"
#     ALLOW_USAGE_OF_WINAPI AS "allow_winapi"
# )
#
# [...]
# add_subdirectory("LibName/")  # Directory containing the LibName.cmake
# [...]
#
# policy_generate_all()
#
# -----------------------
#


include_guard(GLOBAL)


# ---------------------------------------------------------------------------
# policy_define_output
#
# Declare a YAML output file and the policy parameters it cares about.
#
# policy_define_output(
#     FILE        <output_path>
#     POLICIES    <CMAKE_PARAM> AS <yaml_key>
#                 <CMAKE_PARAM> AS <yaml_key>
#                 ...
# )
#
# Example:
#   policy_define_output(
#       FILE     "${CMAKE_SOURCE_DIR}/windows_policy.yaml"
#       POLICIES
#           WINDOWS_ALLOWED  AS  windows_allowed
#           MFC_ALLOWED      AS  mfc_allowed
#           PUBLIC_HEADERS_CLEAN AS public_headers_must_be_clean
#   )
# ---------------------------------------------------------------------------
function(policy_define_output)
    cmake_parse_arguments(ARG "" "FILE" "POLICIES" ${ARGN})

    if(NOT ARG_FILE)
        message(FATAL_ERROR "policy_define_output: FILE is required")
    endif()
    if(NOT ARG_POLICIES)
        message(FATAL_ERROR "policy_define_output: POLICIES is required")
    endif()

    # Parse  PARAM AS yaml_key  triplets
    set(PARAM_NAMES "")
    set(YAML_KEYS   "")
    set(REMAINING ${ARG_POLICIES})

    while(REMAINING)
        list(POP_FRONT REMAINING PARAM_NAME)
        list(POP_FRONT REMAINING AS_KEYWORD)
        list(POP_FRONT REMAINING YAML_KEY)

        if(NOT AS_KEYWORD STREQUAL "AS")
            message(FATAL_ERROR "policy_define_output: expected 'AS' after '${PARAM_NAME}', got '${AS_KEYWORD}'")
        endif()

        list(APPEND PARAM_NAMES "${PARAM_NAME}")
        list(APPEND YAML_KEYS   "${YAML_KEY}")
    endwhile()

    # Encode lists as strings using | as separator (safe since cmake lists use ;)
    string(REPLACE ";" "|" PARAM_NAMES_ENC "${PARAM_NAMES}")
    string(REPLACE ";" "|" YAML_KEYS_ENC   "${YAML_KEYS}")

    # Register this output file globally
    get_property(ALL_OUTPUTS GLOBAL PROPERTY POLICY_OUTPUT_FILES)
    list(APPEND ALL_OUTPUTS "${ARG_FILE}")
    set_property(GLOBAL PROPERTY POLICY_OUTPUT_FILES "${ALL_OUTPUTS}")

    # Store mapping for this file (use a sanitized property name)
    string(MAKE_C_IDENTIFIER "${ARG_FILE}" FILE_ID)
    set_property(GLOBAL PROPERTY "POLICY_OUTPUT_PARAMS_${FILE_ID}" "${PARAM_NAMES_ENC}")
    set_property(GLOBAL PROPERTY "POLICY_OUTPUT_KEYS_${FILE_ID}"   "${YAML_KEYS_ENC}")
endfunction()


# ---------------------------------------------------------------------------
# set_target_policies
#
# Register a target with its policy values.
# Any policy parameter defined across any output file can be specified here.
# Unrecognised parameters are stored as-is (forward compatible).
#
# set_target_policies(
#     TARGET   <target>
#     NOTES    <string>          # optional — appears in all output files
#     EXCLUDE_DIRS  <d1> <d2>   # optional — subdirs to skip in scanner
#     EXCLUDE_FILES <f1> <f2>   # optional
#     <POLICY_PARAM>  <value>   # one or more policy parameters
#     ...
# )
# ---------------------------------------------------------------------------
function(set_target_policies)
    cmake_parse_arguments(ARG
        ""
        "TARGET;NOTES"
        "EXCLUDE_DIRS;EXCLUDE_FILES"
        ${ARGN}
    )

    if(NOT ARG_TARGET)
        message(FATAL_ERROR "set_target_policies: TARGET is required")
    endif()
    if(NOT TARGET ${ARG_TARGET})
        message(FATAL_ERROR "set_target_policies: '${ARG_TARGET}' is not a known CMake target")
    endif()

    # Collect all known policy parameter names across all registered outputs
    get_property(ALL_OUTPUTS GLOBAL PROPERTY POLICY_OUTPUT_FILES)
    set(ALL_KNOWN_PARAMS "")
    foreach(OUTPUT_FILE IN LISTS ALL_OUTPUTS)
        string(MAKE_C_IDENTIFIER "${OUTPUT_FILE}" FILE_ID)
        get_property(PARAMS_ENC GLOBAL PROPERTY "POLICY_OUTPUT_PARAMS_${FILE_ID}")
        string(REPLACE "|" ";" PARAMS "${PARAMS_ENC}")
        list(APPEND ALL_KNOWN_PARAMS ${PARAMS})
    endforeach()
    list(REMOVE_DUPLICATES ALL_KNOWN_PARAMS)

    # Parse remaining args as PARAM VALUE pairs
    set(REMAINING ${ARG_UNPARSED_ARGUMENTS})
    while(REMAINING)
        list(POP_FRONT REMAINING PARAM)
        list(POP_FRONT REMAINING VALUE)

        if(NOT PARAM IN_LIST ALL_KNOWN_PARAMS)
            message(WARNING "set_target_policies: unknown policy parameter '${PARAM}' on target '${ARG_TARGET}' — ignoring")
            continue()
        endif()

        set_target_properties(${ARG_TARGET} PROPERTIES
            "POLICY_PARAM_${PARAM}" "${VALUE}"
        )
    endwhile()

    # Store common fields
    set_target_properties(${ARG_TARGET} PROPERTIES
        POLICY_PARTICIPANT   ON
        POLICY_NOTES         "${ARG_NOTES}"
    )
    if(ARG_EXCLUDE_DIRS)
        set_target_properties(${ARG_TARGET} PROPERTIES
            POLICY_EXCLUDE_DIRS "${ARG_EXCLUDE_DIRS}"
        )
    endif()
    if(ARG_EXCLUDE_FILES)
        set_target_properties(${ARG_TARGET} PROPERTIES
            POLICY_EXCLUDE_FILES "${ARG_EXCLUDE_FILES}"
        )
    endif()

    # Track globally
    get_property(ALL_TARGETS GLOBAL PROPERTY POLICY_TARGETS)
    list(APPEND ALL_TARGETS ${ARG_TARGET})
    list(REMOVE_DUPLICATES ALL_TARGETS)
    set_property(GLOBAL PROPERTY POLICY_TARGETS "${ALL_TARGETS}")

    message(STATUS "[Policy] Registered: ${ARG_TARGET}")
endfunction()


# ---------------------------------------------------------------------------
# policy_generate_all
#
# Generate all declared output YAML files.
# Call once at the very end of root CMakeLists.txt.
# ---------------------------------------------------------------------------
function(policy_generate_all)
    get_property(ALL_OUTPUTS GLOBAL PROPERTY POLICY_OUTPUT_FILES)
    get_property(ALL_TARGETS GLOBAL PROPERTY POLICY_TARGETS)

    if(NOT ALL_OUTPUTS)
        message(WARNING "policy_generate_all: no output files declared via policy_define_output()")
        return()
    endif()
    if(NOT ALL_TARGETS)
        message(WARNING "policy_generate_all: no targets registered via set_target_policies()")
        return()
    endif()

    foreach(OUTPUT_FILE IN LISTS ALL_OUTPUTS)
        _policy_generate_yaml("${OUTPUT_FILE}" "${ALL_TARGETS}")
    endforeach()
endfunction()


# ---------------------------------------------------------------------------
# Internal: generate one YAML file
# ---------------------------------------------------------------------------
function(_policy_generate_yaml OUTPUT_FILE ALL_TARGETS)
    string(MAKE_C_IDENTIFIER "${OUTPUT_FILE}" FILE_ID)

    get_property(PARAMS_ENC GLOBAL PROPERTY "POLICY_OUTPUT_PARAMS_${FILE_ID}")
    get_property(KEYS_ENC   GLOBAL PROPERTY "POLICY_OUTPUT_KEYS_${FILE_ID}")

    string(REPLACE "|" ";" PARAM_NAMES "${PARAMS_ENC}")
    string(REPLACE "|" ";" YAML_KEYS   "${KEYS_ENC}")

    get_filename_component(OUTPUT_DIR "${OUTPUT_FILE}" DIRECTORY)

    set(CONTENT "# Auto-generated by CMake — do not edit manually.\n")
    string(APPEND CONTENT "# Source of truth: set_target_policies() in CMakeLists.txt files.\n")
    string(APPEND CONTENT "\n")
    string(APPEND CONTENT "projects:\n")

    foreach(TARGET_NAME IN LISTS ALL_TARGETS)
        get_target_property(SOURCE_DIR    ${TARGET_NAME} SOURCE_DIR)
        get_target_property(NOTES         ${TARGET_NAME} POLICY_NOTES)
        get_target_property(EXCLUDE_DIRS  ${TARGET_NAME} POLICY_EXCLUDE_DIRS)
        get_target_property(EXCLUDE_FILES ${TARGET_NAME} POLICY_EXCLUDE_FILES)

        file(RELATIVE_PATH REL_PATH "${OUTPUT_DIR}" "${SOURCE_DIR}")

        string(APPEND CONTENT "\n  - name: ${TARGET_NAME}\n")
        string(APPEND CONTENT "    path: ${REL_PATH}\n")

        # Emit each policy parameter this file cares about
        list(LENGTH PARAM_NAMES PARAM_COUNT)
        math(EXPR LAST_IDX "${PARAM_COUNT} - 1")

        foreach(IDX RANGE ${LAST_IDX})
            list(GET PARAM_NAMES ${IDX} PARAM)
            list(GET YAML_KEYS   ${IDX} YAML_KEY)

            get_target_property(VALUE ${TARGET_NAME} "POLICY_PARAM_${PARAM}")

            if(VALUE STREQUAL "VALUE-NOTFOUND" OR VALUE STREQUAL "POLICY_PARAM_${PARAM}-NOTFOUND")
                set(VALUE "false")  # safe default if target didn't set this param
            endif()

            # Normalize to yaml bool if value looks like a cmake bool
            _policy_to_yaml_value("${VALUE}" YAML_VALUE)
            string(APPEND CONTENT "    ${YAML_KEY}: ${YAML_VALUE}\n")
        endforeach()

        # Exclude dirs
        if(EXCLUDE_DIRS AND NOT EXCLUDE_DIRS MATCHES "NOTFOUND")
            string(APPEND CONTENT "    exclude_dirs:\n")
            foreach(DIR IN LISTS EXCLUDE_DIRS)
                string(APPEND CONTENT "      - ${DIR}\n")
            endforeach()
        endif()

        # Exclude files
        if(EXCLUDE_FILES AND NOT EXCLUDE_FILES MATCHES "NOTFOUND")
            string(APPEND CONTENT "    exclude_files:\n")
            foreach(FILE IN LISTS EXCLUDE_FILES)
                string(APPEND CONTENT "      - ${FILE}\n")
            endforeach()
        endif()

        # Notes
        if(NOTES AND NOT NOTES MATCHES "NOTFOUND" AND NOT NOTES STREQUAL "")
            string(REPLACE "\"" "\\\"" NOTES "${NOTES}")
            string(APPEND CONTENT "    notes: \"${NOTES}\"\n")
        endif()
    endforeach()

    # Only write if changed
    if(EXISTS "${OUTPUT_FILE}")
        file(READ "${OUTPUT_FILE}" EXISTING)
        if(EXISTING STREQUAL CONTENT)
            message(STATUS "[Policy] Up to date: ${OUTPUT_FILE}")
            return()
        endif()
    endif()

    file(WRITE "${OUTPUT_FILE}" "${CONTENT}")
    message(STATUS "[Policy] Generated: ${OUTPUT_FILE}")
endfunction()


# ---------------------------------------------------------------------------
# Internal: normalize CMake bool / string to yaml value
# ---------------------------------------------------------------------------
function(_policy_to_yaml_value VALUE OUT_VAR)
    string(TOUPPER "${VALUE}" UPPER)
    if(UPPER MATCHES "^(ON|TRUE|YES|1)$")
        set(${OUT_VAR} "true"  PARENT_SCOPE)
    elseif(UPPER MATCHES "^(OFF|FALSE|NO|0)$")
        set(${OUT_VAR} "false" PARENT_SCOPE)
    else()
        # Plain string value — quote it
        set(${OUT_VAR} "\"${VALUE}\"" PARENT_SCOPE)
    endif()
endfunction()
