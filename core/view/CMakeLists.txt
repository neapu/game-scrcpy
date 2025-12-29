set(LIB_NAME "view")

add_library(${LIB_NAME} STATIC
        Window.cpp
        Window.h
)

target_include_directories(${LIB_NAME} PRIVATE
        ${SDL3_INCLUDE_DIRS}
)

target_link_libraries(${LIB_NAME} PRIVATE
        ${SDL3_LIBRARIES}
)