create_clock -name REFCLK_3B0 -period 40 -waveform {0 20} [get_ports {REFCLK_3B0}]

create_clock -name {altera_reserved_tck} -period 40 {altera_reserved_tck}



