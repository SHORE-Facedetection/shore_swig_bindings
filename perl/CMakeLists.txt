cmake_minimum_required(VERSION 3.15)

project(ShorePerl LANGUAGES CXX)
include(../cmake_common/embed.cmake)

set(SHORE_SDK_PATH ${CMAKE_SOURCE_DIR}/ShoreSDK CACHE PATH "Select path to SHORE SDK!")
set(SHORE_VERSION 310 CACHE STRING "Select required version of SHORE!" )
set(SHORE_LIB_PREFIX CACHE STRING 
    "Select Shore lib Prefix(e.g. Win32|Win64|Linux_x64|Linux_x86|Linux_armv7hf). Leave empty to autodetect")

file(GLOB_RECURSE SHORE_LIB_PATH_SHARED LIST_DIRECTORIES=false 
    ${SHORE_SDK_PATH}/Lib/${SHORE_LIB_PREFIX}*/${CMAKE_SHARED_LIBRARY_PREFIX}Shore${SHORE_VERSION}${CMAKE_SHARED_LIBRARY_SUFFIX}
)
file(GLOB_RECURSE SHORE_LIB_PATH_STATIC LIST_DIRECTORIES=false
    ${SHORE_SDK_PATH}/Lib/${SHORE_LIB_PREFIX}*/${CMAKE_STATIC_LIBRARY_PREFIX}Shore${SHORE_VERSION}${CMAKE_STATIC_LIBRARY_SUFFIX}
)

if (SHORE_LIB_PATH_SHARED AND NOT SHORE_LIB_PATH_STATIC)
    set (SHORE_LIB_TYPE SHARED)
    set (SHORE_LIB_PATH ${SHORE_LIB_PATH_SHARED})
elseif (SHORE_LIB_PATH_STATIC AND NOT SHORE_LIB_PATH_SHARED)
    set (SHORE_LIB_TYPE STATIC)
    set (SHORE_LIB_PATH ${SHORE_LIB_PATH_STATIC})
elseif (SHORE_LIB_PATH_SHARED AND SHORE_LIB_PATH_STATIC AND WIN32)
    set (SHORE_LIB_TYPE SHARED)
    set (SHORE_LIB_PATH ${SHORE_LIB_PATH_SHARED})
elseif( NOT SHORE_LIB_PATH_SHARED AND NOT SHORE_LIB_PATH_STATIC )
    message( FATAL_ERROR "SHORE library not found")
else()
    message(FATAL_ERROR "something wrong")
endif()

add_library(shore ${SHORE_LIB_TYPE} IMPORTED GLOBAL)
if( SHORE_LIB_PATH AND (NOT SHORE_LIB_PATH STREQUAL ""))
    message( STATUS "Found SHORE: ${SHORE_LIB_PATH}")
else()
    message(FATAL_ERROR "SHORE library not found")
endif()

get_filename_component(SHORE_LIB_DIR ${SHORE_LIB_PATH} DIRECTORY)

FILE(GLOB SHORE_MODEL_SOURCE ${SHORE_SDK_PATH}/Model/*.cpp)
FILE(GLOB ADDITIONAL_SRC_FILES ${CMAKE_SOURCE_DIR}/*.cpp)

set (SHORE_MODEL_CTM
    ${SHORE_SDK_PATH}/Model/ShapeLocator_68_2018_01_17_094200.ctm
)
set (SHORE_CREATE_FACE_ENGINE_CPP ${SHORE_SDK_PATH}/Lib/CreateFaceEngine.cpp)
set (SHORE_INCLUDE_DIR ${SHORE_SDK_PATH}/Lib)

find_package(Perl)
if( NOT PERL_FOUND) 
    message(FATAL_ERROR "Perl not found" )
endif()

find_package(PerlLibs)
if( NOT PERLLIBS_FOUND) 
    message(FATAL_ERROR "Perl libs not found" )
endif()

find_package(SWIG 4.0 )
if(NOT SWIG_FOUND)
    message(FATAL_ERROR "SWIG not found")
else()
    include (UseSWIG)
endif()

add_definitions(-DSHORE_REGISTER_MODELS)
embed_binary(SOURCES ${SHORE_MODEL_CTM} ABI "x86_64" OUTPUT SHAPELOCATORLIB)

if(WIN32)
elseif(UNIX AND NOT APPLE) 

    add_compile_options(-O2 -fexpensive-optimizations -pthread -DLINUX -fPIC 
                        -D_GLIBCXX_HAVE_GTHR_DEFAULT=_GLIBCXX_HAS_GTHREADS 
                        -Wno-narrowing -fpermissive -I /usr/include/)
endif()


set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED True)
set(CMAKE_INSTALL_RPATH ".")
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

list(APPEND SOURCES "Shore.i")
list(APPEND SOURCES ${SHORE_MODEL_SOURCE})
list(APPEND SOURCES ${SHORE_CREATE_FACE_ENGINE_CPP} ${ADDITIONAL_SRC_FILES})

set_property(SOURCE "Shore.i" PROPERTY CPLUSPLUS ON) 

swig_add_library(Shore TYPE ${SHORE_LIB_TYPE} OUTPUT_DIR 
    "${CMAKE_BINARY_DIR}/perl" LANGUAGE Perl SOURCES ${SOURCES} )
swig_link_libraries(Shore ${SHORE_LIB_PATH} ${SHAPELOCATORLIB})

set_property(TARGET Shore PROPERTY SWIG_USE_TARGET_INCLUDE_DIRECTORIES TRUE)
target_include_directories(Shore PUBLIC ${SHORE_INCLUDE_DIR} ${PERL_INCLUDE_PATH})

set(INSTALL_DIR ${CMAKE_SOURCE_DIR}/INSTALL)

install(TARGETS Shore DESTINATION ${INSTALL_DIR})
install(FILES ${CMAKE_SOURCE_DIR}/Shore.pl ${SHORE_LIB_PATH} 
              ${CMAKE_BINARY_DIR}/perl/Shore.pm ${CMAKE_SOURCE_DIR}/sample.png
        DESTINATION ${INSTALL_DIR})

