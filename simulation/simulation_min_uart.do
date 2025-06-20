# =============================================================================
# Pure TCL Integration Test for the Packet Generator + UART TX system
# =============================================================================

echo "==================================================="
echo "MINIMUM SYSTEM TEST : PACKET + UART"
echo "==================================================="

# Create environment
if {[file isdirectory work]} { file delete -force work }
vlib work
vmap work work

echo "INFO: Compiling VHDL source files..."
vcom -work work -2008 ../uart_tx.vhd
vcom -work work -2008 ../tx_packet_gen.vhd
vcom -work work -2008 ./tb_wrapper/min_system_test.vhd
echo "INFO: Compilation complete."


# Load the min_system_test entity into the simulator
echo "INFO: Loading min_system_test entity into simulator..."
vsim -voptargs="+acc" work.min_system_test

# Add signals to the wave window
echo "INFO: Adding signals to wave window..."
add wave -divider "Top-Level Ports"
add wave /min_system_test/clk_i
add wave /min_system_test/rst_i
add wave /min_system_test/data_valid_i
add wave /min_system_test/uart_tx_pin_o

add wave -divider "Internal Wiring"
add wave -radix hex /min_system_test/s_uart_data
add wave /min_system_test/s_uart_start
add wave /min_system_test/s_uart_busy


proc run_test {} {
    echo "--- Starting Test Procedure ---"

    # Generate the 50MHz clock
    force -freeze /min_system_test/clk_i 1 0, 0 {10 ns} -repeat {20 ns}

    # Provide dummy data inputs
    force /min_system_test/unfiltered_data_i 12'hABC
    force /min_system_test/filtered_data_i   12'h123
    force /min_system_test/data_valid_i 0

    # Apply reset
    echo "Applying reset..."
    force /min_system_test/rst_i 1
    run 200 ns
    force /min_system_test/rst_i 0
    echo "Reset released."
    run 200 ns

    # Trigger the packet generator with a single-cycle pulse
    echo "Pulsing data_valid_i to start packet transmission..."
    force /min_system_test/data_valid_i 1
    run 20 ns
    force /min_system_test/data_valid_i 0

    # Run long enough for the entire 4-byte packet to be sent
    # 4 bytes * 10 bit-times/byte * 1us/bit-time = 40us
    # It will run for 50us to see it return to idle.
    echo "Running simulation for 50 us..."
    run 50 us

    echo "--- Test Procedure Finished ---"
    wave zoom full
}

# Execute the test
run_test
