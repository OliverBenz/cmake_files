# ----- Helper Functions -----
function(copy_headers_to_output targetName headerFiles subDirectory)
    foreach(filePath ${headerFiles})
        get_filename_component(fileName ${filePath} NAME)

        string(TOLOWER ${CMAKE_PROJECT_NAME} lowerProjectName)
        set(outputPath ${CMAKE_BINARY_DIR}/out/include/${lowerProjectName}/${subDirectory}/${fileName})

        add_custom_command(
            TARGET ${targetName}
            POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different ${filePath} ${outputPath}
        )
    endforeach()
endfunction()