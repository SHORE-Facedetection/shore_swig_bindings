macro( embed_binary )
    set(singleValues ABI OUTPUT)
    set(multiValues SOURCES)
    set(prefix EMBED)

    include(CMakeParseArguments)
    cmake_parse_arguments(${prefix} "" "${singleValues}" "${multiValues}" ${ARGN})

    if( NOT DEFINED LD_COMMAND )
        message(STATUS "LD_COMMAND not defined, using ${CMAKE_LINKER}")
        set(LD_COMMAND "${CMAKE_LINKER}")
    endif()

    if(EMBED_ABI STREQUAL "armeabi-v7a")
        set(EMULATION armelf_linux_eabi)
    elseif(EMBED_ABI STREQUAL "arm64-v8a")
        set(EMULATION aarch64linux)
    elseif(EMBED_ABI STREQUAL "x86_64")
        set(EMULATION elf_x86_64)
    else()
        message(FATAL_ERROR "Unknonw options for EMBED_ABI: ${EMBED_ABI}")
    endif()

    set(EMBED_ODIR ${CMAKE_BINARY_DIR}/embed/)
    file(MAKE_DIRECTORY ${EMBED_ODIR})

    foreach(input ${EMBED_SOURCES})
        get_filename_component(EMBED_FILE_DIR "${input}" DIRECTORY)
        get_filename_component(EMBED_FILE_BASE "${input}" NAME_WLE)
        get_filename_component(EMBED_FILE "${input}" NAME)
        set(EMBED_OBJECT_FILE "${EMBED_ODIR}/${EMBED_ABI}_${EMBED_FILE_BASE}.o")
        set(EMBED_AR_FILE "${EMBED_ODIR}/${EMBED_ABI}_${EMBED_FILE_BASE}.a")
        add_custom_target(${EMULATION}_${EMBED_FILE_BASE} ALL
            COMMAND ${LD_COMMAND} -m ${EMULATION} -r -b binary --output ${EMBED_OBJECT_FILE} ${EMBED_FILE}
            COMMAND ${CMAKE_AR} rvs ${EMBED_AR_FILE} ${EMBED_OBJECT_FILE}
            WORKING_DIRECTORY ${EMBED_FILE_DIR}
            BYPRODUCTS ${EMBED_AR_FILE} ${EMBED_OBJECT_FILE}
        )
    list(APPEND ${EMBED_OUTPUT} ${EMBED_AR_FILE})
    endforeach()
endmacro()
