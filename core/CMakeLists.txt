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

if (WIN32)
    set(INSTALL_SCRIPT_HINT "scripts/win/install_dependencies.ps1")
else()
    set(INSTALL_SCRIPT_HINT "scripts/linux/install_dependencies.sh")
endif()

if (EXISTS "${PROJECT_SOURCE_DIR}/third_party/ffmpeg")
    message(STATUS "Found ffmpeg in third_party")
    set(FFMPEG_ROOT "${PROJECT_SOURCE_DIR}/third_party/ffmpeg")
    set(FFMPEG_INCLUDE_DIR "${FFMPEG_ROOT}/include")
    find_library(AVCODEC_LIBRARY avcodec PATHS "${FFMPEG_ROOT}/bin" "${FFMPEG_ROOT}/lib" NO_DEFAULT_PATH)
    find_library(AVFORMAT_LIBRARY avformat PATHS "${FFMPEG_ROOT}/bin" "${FFMPEG_ROOT}/lib" NO_DEFAULT_PATH)
    find_library(AVUTIL_LIBRARY avutil PATHS "${FFMPEG_ROOT}/bin" "${FFMPEG_ROOT}/lib" NO_DEFAULT_PATH)
    find_library(SWSCALE_LIBRARY swscale PATHS "${FFMPEG_ROOT}/bin" "${FFMPEG_ROOT}/lib" NO_DEFAULT_PATH)
    find_library(SWRESAMPLE_LIBRARY swresample PATHS "${FFMPEG_ROOT}/bin" "${FFMPEG_ROOT}/lib" NO_DEFAULT_PATH)
else ()
    message(FATAL_ERROR "FFmpeg not found in third_party. Please run '${INSTALL_SCRIPT_HINT}' to install dependencies.")
endif ()

if (EXISTS "${PROJECT_SOURCE_DIR}/third_party/sdl3")
    message(STATUS "Found sdl3 in third_party")
    set(SDL3_ROOT "${PROJECT_SOURCE_DIR}/third_party/sdl3")
    list(APPEND CMAKE_PREFIX_PATH "${SDL3_ROOT}")
    find_package(SDL3 REQUIRED)
    if(TARGET SDL3::SDL3)
        set(SDL3_LIBRARIES SDL3::SDL3)
    endif()
else ()
    message(FATAL_ERROR "SDL3 not found in third_party. Please run '${INSTALL_SCRIPT_HINT}' to install dependencies.")
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