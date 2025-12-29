cmake_minimum_required(VERSION 4.1)
project(GameScrcpyCore)
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include_directories(.)

if (MSVC)
    if (CMAKE_SYSTEM_PROCESSOR MATCHES "^(x86_64|AMD64|amd64)$")
        add_compile_definitions(_AMD64_)
    elseif (CMAKE_SYSTEM_PROCESSOR MATCHES "^(i386|i486|i586|i686|x86)$")
        add_compile_definitions(_X86_)
    elseif (CMAKE_SYSTEM_PROCESSOR MATCHES "^(ARM64|aarch64)$")
        add_compile_definitions(_ARM64_)
    elseif (CMAKE_SYSTEM_PROCESSOR MATCHES "^(ARM|arm)$")
        add_compile_definitions(_ARM_)
    endif ()
endif ()

if (DEFINED ENV{FFMPEG_ROOT})
    set (FFMPEG_ROOT $ENV{FFMPEG_ROOT})
endif ()

if (FFMPEG_ROOT)
    message(STATUS "FFMPEG_ROOT is set to ${FFMPEG_ROOT}")
    find_library(AVCODEC_LIBRARY avcodec PATHS "${FFMPEG_ROOT}/lib" NO_DEFAULT_PATH)
    find_library(AVFORMAT_LIBRARY avformat PATHS "${FFMPEG_ROOT}/lib" NO_DEFAULT_PATH)
    find_library(AVUTIL_LIBRARY avutil PATHS "${FFMPEG_ROOT}/lib" NO_DEFAULT_PATH)
    find_library(SWSCALE_LIBRARY swscale PATHS "${FFMPEG_ROOT}/lib" NO_DEFAULT_PATH)
    find_library(SWRESAMPLE_LIBRARY swresample PATHS "${FFMPEG_ROOT}/lib" NO_DEFAULT_PATH)
    set (FFMPEG_INCLUDE_DIR "${FFMPEG_ROOT}/include")
else ()
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(AVCODEC REQUIRED libavcodec)
    pkg_check_modules(AVFORMAT REQUIRED libavformat)
    pkg_check_modules(AVUTIL REQUIRED libavutil)
    pkg_check_modules(SWSCALE REQUIRED libswscale)
    pkg_check_modules(SWRESAMPLE REQUIRED libswresample)
    message(STATUS "FFMPEG libraries found via pkg-config")
endif ()

if (DEFINED ENV{SDL3_ROOT})
    set (SDL3_ROOT $ENV{SDL3_ROOT})
endif ()

if (SDL3_ROOT)
    list(APPEND CMAKE_PREFIX_PATH "${SDL3_ROOT}")
    message(STATUS "SDL3_ROOT is set to ${SDL3_ROOT}")
    find_package(SDL3 REQUIRED)
    if(TARGET SDL3::SDL3)
        set(SDL3_LIBRARIES SDL3::SDL3)
    endif()
else ()
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(SDL3 REQUIRED sdl3)
    message(STATUS "SDL3 library found via pkg-config")
endif ()

if (CMAKE_BUILD_TYPE STREQUAL "Debug")
    add_compile_definitions(DEBUG_MODE=1)
    get_filename_component(PARENT_DIR "${CMAKE_SOURCE_DIR}/.." ABSOLUTE)
    message(STATUS "Parent directory: ${PARENT_DIR}")
    add_compile_definitions(PROJECT_ROOT_DIR="${PARENT_DIR}")
endif ()


add_subdirectory(third_party)
add_subdirectory(view)

add_executable(${PROJECT_NAME} main.cpp
        Logger.cpp
        Logger.h)

target_include_directories(${PROJECT_NAME} PRIVATE
        ${FFMPEG_INCLUDE_DIR}
        ${SDL3_INCLUDE_DIRS}
)

target_link_libraries(${PROJECT_NAME} PRIVATE
        argparse
        view
        ${AVCODEC_LIBRARY}
        ${AVFORMAT_LIBRARY}
        ${AVUTIL_LIBRARY}
        ${SWSCALE_LIBRARY}
        ${SWRESAMPLE_LIBRARY}
        ${SDL3_LIBRARIES}
)