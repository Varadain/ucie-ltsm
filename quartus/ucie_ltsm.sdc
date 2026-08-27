create_clock -name clk_i -period 12.500 [get_ports {clk_i}]
derive_clock_uncertainty
set_false_path -from [get_ports {rst_ni}]
