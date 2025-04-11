cmake_minimum_required(VERSION 3.14)

add_subdirectory(../demo_bsp demo_bsp)

include(../demo_bsp/toolchain.cmake)

project(demo_app)

enable_language(ASM)
enable_language(C)
enable_language(CXX)

add_executable(demo_app.elf)

target_sources(demo_app.elf
    PRIVATE
        axe5000_demo_refdes.c
)

target_include_directories(demo_app.elf
    PRIVATE
    PUBLIC
)

target_link_libraries(demo_app.elf
    PRIVATE
        -T "${BspLinkerScript}" -nostdlib
        "${ExtraArchiveLibraries}"
        -Wl,--start-group "${BspLibraryName}" -lc -lstdc++ -lgcc -lm -Wl,--end-group
)

# Create objdump from ELF.
set(objdump demo_app.elf.objdump)
add_custom_command(
    OUTPUT "${objdump}"
    DEPENDS demo_app.elf
    COMMAND "${ToolchainObjdump}" "${ToolchainObjdumpFlags}" demo_app.elf >
            "${objdump}"
    COMMENT "Creating ${objdump}."
    VERBATIM
)
add_custom_target(create-objdump ALL DEPENDS "${objdump}")

# Report space free for stack + heap. Note that the file below is never created
# so the report is always output on build.
set(stack_report_file demo_app.elf.stack_report)
add_custom_command(
    OUTPUT "${stack_report_file}"
    DEPENDS demo_app.elf
    COMMAND niosv-stack-report -p "${ToolchainPrefix}" demo_app.elf
    COMMENT "Reporting memory available for stack + heap in demo_app.elf."
    VERBATIM
)
add_custom_target(niosv-stack-report ALL DEPENDS "${stack_report_file}")
