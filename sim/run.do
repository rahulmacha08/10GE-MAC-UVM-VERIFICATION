vlib work
vdel -all
vlib work

vlog design.v ethernet_top.sv +acc +cover -coveropt 3 -sv +incdir+ /questasim64_10.7/verilog_src/uvm-1.1d/src +incdir+.

vsim -coverage work.top -assertdebug -sv_lib /questasim64_10.7c/uvm-1.1d/win64/uvm_dpi +UVM_VERBOSITY=UVM_MEDIUM +UVM_TESTNAME=runt_test -l run.log5

# --- ADD WAVE COMMANDS HERE ---
add wave -position insertpoint sim:/top/intf/*
add wave -position insertpoint sim:/top/d1/*

# --- RUN THE SIMULATION ---
run -all
