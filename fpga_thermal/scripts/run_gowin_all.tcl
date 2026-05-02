# Gowin command-line full implementation script.
# Reference: SUG100-2.6 chapter 8, gw_sh.exe [script file] and run all.

set script_path [file normalize [info script]]
set script_dir [file dirname $script_path]
set project_root [file normalize [file join $script_dir ".."]]
cd $project_root

set_device -name GW1NR-9C GW1NR-LV9QN88PC6/I5

add_file rtl/spi_rx_tiny1c.v
add_file rtl/norm16_to_u8.v
add_file rtl/roi_crop.v
add_file rtl/scaler_nearest.v
add_file rtl/scaler_bilinear.v
add_file rtl/line_buffer_3row.v
add_file rtl/window_3x3.v
add_file rtl/sobel3x3.v
add_file rtl/edge_blend.v
add_file rtl/thumb_gen.v
add_file rtl/candidate_mask_gen.v
add_file rtl/meta_extract.v
add_file rtl/cfg_regs.v
add_file rtl/packet_tx_spi.v
add_file rtl/top_tiny1c_fpga.v
add_file rtl/top_tangnano9k.v
add_file constraints/tangnano9k.sdc
add_file constraints/tangnano9k.cst

set_option -top_module top_tangnano9k
set_option -verilog_std v2001
set_option -output_base_name fpga_thermal_all
set_option -rw_check_on_ram 0
set_option -print_all_synthesis_warning 1
set_option -gen_text_timing_rpt 1

run all
