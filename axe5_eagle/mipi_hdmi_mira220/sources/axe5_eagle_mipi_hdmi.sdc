#**************************************************************
# Create Clock
#**************************************************************
create_clock -name ClkIn -period 40 [get_ports {FPGA_Clock}]

derive_pll_clocks
derive_clock_uncertainty

set_false_path -from [get_clocks {mipi_u0_CORE_CLK_0}] -to [get_clocks {niosv_subsystem|iopll|iopll_outclk1}]
set_false_path -from [get_clocks {mipi_u0_MIPI_FWD_CLK_0_BYTE_0}] -to [get_clocks {niosv_subsystem|iopll|iopll_outclk1}]
set_false_path -from [get_clocks {niosv_subsystem|iopll|iopll_outclk1}] -to [get_clocks {mipi_u0_MIPI_FWD_CLK_0_BYTE_0}]
set_false_path -from [get_clocks {niosv_subsystem|iopll|iopll|tennm_ph2_iopll|ref_clk0}] -to [get_clocks {niosv_subsystem|iopll|iopll_outclk1}]
set_false_path -from [get_clocks niosv_subsystem|iopll|iopll|tennm_ph2_iopll|ref_clk0] -to [get_clocks {niosv_subsystem|iopll|iopll_outclk1}]
set_false_path -from [get_clocks niosv_subsystem|iopll|iopll|tennm_ph2_iopll|ref_clk0] -to [get_clocks {mipi_u0_CORE_CLK_0}]
