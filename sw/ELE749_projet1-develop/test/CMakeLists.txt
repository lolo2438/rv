file(GLOB SOURCES ./*.c ../src/*[!main].c)

include_directories("${PROJECT_SOURCE_DIR}/include/" "${PROJECT_SOURCE_DIR}/src/")

add_subdirectory(unity)
add_executable(test ${SOURCES})
target_link_libraries(test unity)
