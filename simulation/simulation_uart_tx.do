echo "==================================================="
echo "UART_TX UNIT TEST SCRIPT"
echo "==================================================="

# Create environment
if {[file isdirectory work]} { file delete -force work }
vlib work
vmap work work

echo "INFO: Compiling uart_tx.vhd..."
vcom -work work -2008 ../uart_tx.vhd
echo "INFO: Compilation complete."


# Load the uart_tx entity into the simulator
# Note: This is loading the component itself, not the top-level design.
# This will use the default generic values (50MHz clock, 1Mbaud).
echo "INFO: Loading uart_tx entity into simulator..."
vsim -voptargs="+acc" work.uart_tx

# Add all internal and port signals to the wave window
echo "INFO: Adding all internal signals to wave window..."
add wave -divider "Ports"
add wave /uart_tx/clk_i
add wave /uart_tx/rst_i
add wave /uart_tx/tx_start_i
add wave -radix hex /uart_tx/data_i
add wave /uart_tx/tx_busy_o
add wave /uart_tx/tx_o

# Add the state machine signal to see it change from IDLE -> START -> DATA -> STOP
add wave -divider "Internal State"
add wave /uart_tx/s_state

# Add the internal counters to see the timing logic at work
add wave -divider "Internal Counters"
add wave /uart_tx/s_clk_counter
add wave /uart_tx/s_bit_counter
add wave -radix binary /uart_tx/s_data_reg


proc run_uart_byte_test {} {
    echo "--- Starting UART TX Test Procedure ---"

    # Generate the 50MHz clock on the input port
    force -freeze /uart_tx/clk_i 1 0, 0 {10 ns} -repeat {20 ns}

    # Set initial values for inputs
    force /uart_tx/tx_start_i 0
    force /uart_tx/data_i 8'h00

    # Apply reset for 200ns
    echo "Applying reset..."
    force /uart_tx/rst_i 1
    run 200 ns
    force /uart_tx/rst_i 0
    echo "Reset released. UART is in IDLE state."
    run 200 ns

    # Send one byte: 0x5A (binary 01011010)
    echo "Sending byte 0x5A..."
    force /uart_tx/data_i 8'h5A

    # Create a single-cycle start pulse
    force /uart_tx/tx_start_i 1
    run 20 ns ; # Hold start high for one clock cycle
    force /uart_tx/tx_start_i 0

    # Run long enough for the byte to transmit
    # 1 start bit + 8 data bits + 1 stop bit = 10 bits
    # At 1 Mbaud, each bit is 1 us long. Total time = 10 us.
    # It will run for 15 us to see it return to idle.
    echo "Running for 15 us..."
    run 15 us

    echo "--- Test Procedure Finished ---"
    wave zoom full
}

# Execute the test
run_uart_byte_test
