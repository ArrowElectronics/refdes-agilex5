#
# SPDX-FileCopyrightText: Copyright (C) 2026 Arrow Electronics, Inc.
# SPDX-License-Identifier: MIT-0
#

# Remove existing memory regions and section mappings
foreach region_info [get_current_memory_regions] {
    delete_memory_region [lindex $region_info 0]
}

foreach mapping_info [get_current_section_mappings] {
    delete_section_mapping [lindex $mapping_info 0]
}

# Settings
set_setting intel_lw_uart.enable_small_driver {false}
set_setting hal.dfl_start_address {-1}
set_setting hal.enable_c_plus_plus {true}
set_setting hal.enable_clean_exit {true}
set_setting hal.enable_exit {true}
set_setting hal.enable_instruction_related_exceptions_api {false}
set_setting hal.enable_lightweight_device_driver_api {false}
set_setting hal.enable_reduced_device_drivers {false}
set_setting hal.enable_runtime_stack_checking {false}
set_setting hal.enable_sim_optimize {false}
set_setting hal.linker.allow_code_at_reset {true}
set_setting hal.linker.enable_alt_load {false}
set_setting hal.linker.enable_alt_load_copy_exceptions {false}
set_setting hal.linker.enable_alt_load_copy_rodata {false}
set_setting hal.linker.enable_alt_load_copy_rwdata {false}
set_setting hal.linker.enable_exception_stack {false}
set_setting hal.linker.exception_stack_memory_region_name {none}
set_setting hal.linker.exception_stack_size {1024}
set_setting hal.linker.use_picolibc {false}
set_setting hal.log_flags {0}
set_setting hal.log_port {none}
set_setting hal.make.asflags {-Wa,-gdwarf2}
set_setting hal.make.cflags_debug {-g}
set_setting hal.make.cflags_defined_symbols {none}
set_setting hal.make.cflags_optimization {-O2}
set_setting hal.make.cflags_undefined_symbols {none}
set_setting hal.make.cflags_user_flags {none}
set_setting hal.make.cflags_warnings {-Wall -Wformat-security}
set_setting hal.make.cxx_flags {none}
set_setting hal.make.enable_cflag_fstack_protector_strong {true}
set_setting hal.make.enable_cflag_wformat_security {true}
set_setting hal.make.link_flags {none}
set_setting hal.make.objdump_flags {-Sdtx}
set_setting hal.max_file_descriptors {32}
set_setting hal.stderr {niosv_system_0_lw_uart}
set_setting hal.stdin {niosv_system_0_lw_uart}
set_setting hal.stdout {niosv_system_0_lw_uart}
set_setting hal.sys_clk_timer {niosv_system_0_niosv_g}
set_setting hal.timestamp_timer {niosv_system_0_niosv_g}
set_setting hal.toolchain.ar {riscv32-unknown-elf-ar}
set_setting hal.toolchain.as {riscv32-unknown-elf-gcc}
set_setting hal.toolchain.cc {riscv32-unknown-elf-gcc}
set_setting hal.toolchain.cxx {riscv32-unknown-elf-g++}
set_setting hal.toolchain.enable_executable_overrides {false}
set_setting hal.toolchain.objdump {riscv32-unknown-elf-objdump}
set_setting hal.toolchain.prefix {riscv32-unknown-elf-}
set_setting hal.use_dfl_walker {false}
set_setting intel_niosv_g_hal_driver.internal_timer_ticks_per_sec {1000}

# Software packages

# Drivers
set_driver intel_lw_uart niosv_system_0_lw_uart
set_driver intel_mailbox_client niosv_system_0_mailbox_client
set_driver intel_niosv_g_hal_driver niosv_system_0_niosv_g
set_driver altera_avalon_pio_driver niosv_system_0_pio_led
set_driver altera_avalon_pio_driver niosv_system_0_pio_pb
set_driver altera_avalon_sysid_qsys_driver niosv_system_0_sysid



# User devices

# Linker memory regions
add_memory_region niosv_system_0_bootcopier_ocm niosv_system_0_bootcopier_ocm 32 65504
add_memory_region reset niosv_system_0_bootcopier_ocm 0 32
add_memory_region niosv_system_0_sll_xspi_mc niosv_system_0_sll_xspi_mc 0 16777216

# Linker section mappings
add_section_mapping .text niosv_system_0_bootcopier_ocm
add_section_mapping .exceptions niosv_system_0_bootcopier_ocm
add_section_mapping .rodata niosv_system_0_bootcopier_ocm
add_section_mapping .rwdata niosv_system_0_bootcopier_ocm
add_section_mapping .bss niosv_system_0_bootcopier_ocm
add_section_mapping .heap niosv_system_0_bootcopier_ocm
add_section_mapping .stack niosv_system_0_bootcopier_ocm
