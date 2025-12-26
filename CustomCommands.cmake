# ----- Helper Functions -----

# Copy the header files of a target to the output directory in a postbuild script
#
# targetName   .. Name of the target responsible for copying the header files
# headerFiles  .. List of all header files to copy to the output
# subDirectory .. Subdirectory in 'out/include' where to copy the header files to
#
function(copy_headers_to_output targetName headerFiles subDirectory)
    foreach(filePath ${headerFiles})
        get_filename_component(fileName ${filePath} NAME)

        set(outputPath ${CMAKE_BINARY_DIR}/out/include/${subDirectory}/${fileName})

        add_custom_command(
            TARGET ${targetName}
            POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_BINARY_DIR}/out/include/${subDirectory}
            COMMAND ${CMAKE_COMMAND} -E copy_if_different ${filePath} ${outputPath}
        )
    endforeach()
endfunction()
