cmake_minimum_required(VERSION 3.22)
include(ExternalProject)
include(../cmake_common/embed.cmake)
project(ShoreAndroid LANGUAGES CXX)

set(SHORE_SDK_PATH ${CMAKE_SOURCE_DIR}/ShoreSDK CACHE PATH "Select path to \
                                                                SHORE SDKs!")
set(SHORE_VERSION 310 CACHE STRING "Select required version of SHORE!" )
set(APP_PLATFORM "android-23" CACHE STRING "APP_PLATFORM version for the build")
set(NDK_BUILD "" CACHE STRING "Set to the absolute path of the \"ndk-build\" \
                                                  script from the Android NDK")

if(NOT UNIX)
    message(FATAL_ERROR "Non Linux systems are not supported at the moment")
endif()

if ("${NDK_BUILD}" STREQUAL "")
    message(FATAL_ERROR "Plese set the NDK_BUILD variable to the absolute \
                    path of the \"ndk-build\" script from the Android SDK")
endif()

get_filename_component(NDK_ROOT "${NDK_BUILD}" DIRECTORY)
set(NDK_LD ${NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64/bin/ld CACHE STRING
        "Set to the ld binary of the NDK")
if(NOT EXISTS "${NDK_LD}")
    message(FATAL_ERROR "Cannot find NDK ld at ${NDK_LD} - please configure it")
endif()

# find all directories in ShoreSDK/ and check whether they are
# known EABIs
file(GLOB SHORE_SDK_EABIS LIST_DIRECTORIES=true
    ${SHORE_SDK_PATH}/*/
)
if (SHORE_SDK_EABIS)
    set (SHORE_LIB_TYPE SHARED)
    foreach(FILENAME ${SHORE_SDK_EABIS})
        if(IS_DIRECTORY "${FILENAME}")
            get_filename_component(EABI "${FILENAME}" NAME)
            message(STATUS "EABI: ${EABI}")
            if (${EABI} STREQUAL "arm64-v8a")
                list(APPEND EABIS "arm64-v8a")
            elseif(${EABI} STREQUAL "armeabi-v7a")
                list(APPEND EABIS "armeabi-v7a")
            elseif(${EABI} STREQUAL "x86_64")
                list(APPEND EABIS "x86_64")
            else()
                message(WARNING "Unsupported eabi: ${EABI}")
            endif()
        endif()
    endforeach()
else()
    message(FATAL_ERROR "No supported EABIS found, please make sure \
                            to create the correct directory structure.")
endif()

set(LD_COMMAND ${NDK_LD})

message(STATUS "Found EABIS: ${EABIS}")

# fill the APP_ABI list for the Application.mk and
# create an object file for the ShapeLocator model for each architecture
# strictly speaking we could use the same CTM file as an input for all
# architectures but using the one from the respective SDK is cleaner
# Please note: embed_binary returns a list of *.a files via the OUTPUT variable
# we do, however, not use this list because Android.mk expects one single
# filename that is created from the $(TARGET_ARCH_ABI) - see the definition
# of the shapelocator module in jni/Android.mk.in
foreach(EABI ${EABIS})
    set(APP_ABI "${APP_ABI} ${EABI}")
    set(CTM "${SHORE_SDK_PATH}/${EABI}/Model/ShapeLocator_68_2018_01_17_094200.ctm")
    embed_binary(SOURCES ${CTM} ABI ${EABI} OUTPUT out)
endforeach()

list(GET EABIS 0 PRIMARY_SHORE_SDK)
FILE(GLOB SHORE_MODEL_SOURCE RELATIVE ${SHORE_SDK_PATH}/${PRIMARY_SHORE_SDK}/Model/
    ${SHORE_SDK_PATH}/${PRIMARY_SHORE_SDK}/Model/*.cpp)
list(TRANSFORM SHORE_MODEL_SOURCE PREPEND "\$(SHORE_MODEL_DIR)/")
FILE(GLOB ADDITIONAL_SRC_FILES ${CMAKE_SOURCE_DIR}/*.cpp)
string(REPLACE ";" " \\\n" SHORE_MODEL_SOURCE "${SHORE_MODEL_SOURCE}")
string(REPLACE ";" " \\\n" ADDITIONAL_SRC_FILES "${ADDITIONAL_SRC_FILES}")

# set the APP_OPTIM variable for Application.mk
if("${CMAKE_BUILD_TYPE}" STREQUAL "")
    set(APP_OPTIM "release")
elseif("${CMAKE_BUILD_TYPE}" STREQUAL "Release")
    set(APP_OPTIM "release")
elseif("${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
    set(APP_OPTIM "debug")
else()
    message(FATAL_ERROR "Unsupported build type: ${CMAKE_BUILD_TYPE}")
endif()


# Replaces the following in the Application.mk.in file:
# APP_ABI
# APP_OPTIM
# APP_PLATFORM
configure_file(${CMAKE_SOURCE_DIR}/jni/Application.mk.in
               ${CMAKE_SOURCE_DIR}/jni/Application.mk
               @ONLY)
# Replaces the following in the Android.mk.in file:
# SHORE_SDK_PATH
# SHORE_VERSION
# CMAKE_BINARY_PATH
# SHORE_MODEL_SOURCE
# ADDITIONAL_SRC_FILES
configure_file(${CMAKE_SOURCE_DIR}/jni/Android.mk.in
               ${CMAKE_SOURCE_DIR}/jni/Android.mk
               @ONLY)
file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/aar/jni")

# clear these directories if "make clean" is invoked
# to remove intermediate files generated in the custom targets
set(CLEAN_DIRS "${CMAKE_SOURCE_DIR}/libs"
               "${CMAKE_SOURCE_DIR}/obj"
               "${CMAKE_SOURCE_DIR}/shore_java_build"
               "${CMAKE_SOURCE_DIR}/shore_java_tmp"
               "${CMAKE_SOURCE_DIR}/INSTALL"
               "${CMAKE_BINARY_DIR}/aar")
set_property(DIRECTORY PROPERTY ADDITIONAL_MAKE_CLEAN_FILES ${CLEAN_DIRS})

# build ShoreJava because it's needed for ShoreAndroid
# Please note: the Java-Bindings are not cross-compiled, i.e.
# the default host compiler is used - this is also the reason why we
# set the ANDROID_BUILD option - this prevents the swig compilation step
# in ShoreJava from trying to link the compiled objects files to the library
# from our (ARM) SHORE library - this is not nice, but CMake doesn't allow us to
# do it differently
list(GET EABIS 0 SHORE_SDK_PATH_JAVA)
set(SHORE_SDK_PATH_JAVA "${SHORE_SDK_PATH}/${SHORE_SDK_PATH_JAVA}")
ExternalProject_Add(ShoreJava PREFIX "${CMAKE_SOURCE_DIR}/../java"
                    SOURCE_DIR "${CMAKE_SOURCE_DIR}/../java"
                    BINARY_DIR "${CMAKE_SOURCE_DIR}/shore_java_build"
                    TMP_DIR "${CMAKE_SOURCE_DIR}/shore_java_tmp"
                    BUILD_COMMAND make ShoreWrapper_swig_compilation
                                       ShoreJavaWrapper
                    CMAKE_ARGS -DSHORE_SDK_PATH=${SHORE_SDK_PATH_JAVA}
                               -DANDROID_BUILD=true
                               -DSHORE_VERSION=${SHORE_VERSION}
                    INSTALL_COMMAND ""
                    )

# Start the NDK build but copy the generated ShoreJAVA_wrap.cxx from ShoreJava
# first. The output of this step is found in the libs/ directory
add_custom_target(ShoreNDK ALL
    COMMAND cp "${CMAKE_SOURCE_DIR}/shore_java_build/javagen/ShoreJAVA_wrap.cxx"
                "${CMAKE_SOURCE_DIR}/jni/"
    COMMAND ${NDK_BUILD} -j
)

# create the output AAR file (with a zip extension - this is changed in
# the install step)
add_custom_target(ShoreAndroid ALL
    COMMAND ${CMAKE_COMMAND} -E rm -rf ${CMAKE_BINARY_DIR}/aar/*
    COMMAND ${CMAKE_COMMAND} -E copy
                ${CMAKE_SOURCE_DIR}/shore_java_build/ShoreJavaWrapper.jar
                "${CMAKE_BINARY_DIR}/aar/classes.jar"
    COMMAND ${CMAKE_COMMAND} -E copy_directory
                ${CMAKE_SOURCE_DIR}/aar/
                "${CMAKE_BINARY_DIR}/aar/"
    COMMAND ${CMAKE_COMMAND} -E copy_directory
                ${CMAKE_SOURCE_DIR}/libs/
                "${CMAKE_BINARY_DIR}/aar/jni"
    COMMAND ${CMAKE_COMMAND} -E tar
                "cfv" "ShoreAndroid.zip" --format=zip -- *
    WORKING_DIRECTORY "${CMAKE_BINARY_DIR}/aar"
)

add_dependencies(ShoreNDK ShoreJava)
add_dependencies(ShoreAndroid ShoreNDK)

set(INSTALL_DIR ${CMAKE_SOURCE_DIR}/INSTALL)
install(FILES "${CMAKE_BINARY_DIR}/aar/ShoreAndroid.zip"
        DESTINATION ${INSTALL_DIR}
        RENAME "ShoreAndroid.aar")
