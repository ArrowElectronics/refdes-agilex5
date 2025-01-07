create_clock -name CLK_25M_C -period 40 -waveform {0 20} [get_ports {CLK_25M_C}]

create_clock -name {altera_reserved_tck} -period 40 {altera_reserved_tck}



