echo "==================================================="
echo "MINIMUM SYSTEM TEST : FIR + PACKET + UART"
echo "==================================================="

# Create environment
vlib work
vmap work work

echo "INFO: Compiling VHDL source files..."
vcom -work work -2008 ../uart_tx.vhd
vcom -work work -2008 ../fir_filter.vhd
vcom -work work -2008 ../tx_packet_gen.vhd
vcom -work work -2008 ./tb_wrapper/min_system_fir_test.vhd
echo "INFO: Compilation complete."

# Load the min_system_fir_test entity into the simulator
echo "INFO: Loading min_system_fir_test entity into simulator..."
vsim -voptargs="+acc" work.min_system_fir_test

# Add signals to the wave window
echo "INFO: Adding signals to wave window..."
add wave -divider "Top-Level I/O"
add wave /min_system_fir_test/clk_i
add wave /min_system_fir_test/rst_i
add wave /min_system_fir_test/sample_valid_i
add wave -radix signed /min_system_fir_test/stimulus_i
add wave /min_system_fir_test/uart_tx_pin_o

add wave -divider "FIR Filter Output"
add wave -radix signed /min_system_fir_test/fir_inst/filtered_o

add wave -divider "Packet Gen -> UART Interface"
add wave /min_system_fir_test/s_uart_busy
add wave /min_system_fir_test/s_uart_start
add wave -radix hex /min_system_fir_test/s_uart_data


proc run_test {} {
    echo "--- Starting Sine Wave Test Procedure ---"

    # Define simulation parameters
    set clk_period 20 ;       # 20ns = 50MHz
    set sample_period 50000 ; # 50us = 20kHz

    # Generate the main 50MHz clock
    force -freeze /min_system_fir_test/clk_i 1 0, 0 [expr {$clk_period / 2}]ns -repeat [expr {$clk_period}]ns

    # Initialize inputs
    force /min_system_fir_test/stimulus_i 0
    force /min_system_fir_test/sample_valid_i 0

    # Apply reset
    echo "Applying reset..."
    force /min_system_fir_test/rst_i 1
    run [expr {$clk_period * 10}]ns
    force /min_system_fir_test/rst_i 0
    echo "Reset released."
    run [expr {$clk_period * 10}]ns

    # Read the pre-generated sine values into a Tcl list
    set f [open "sine_stimulus.txt" r]
    set sine_values [split [string trim [read $f]] "\n"]
    close $f
    set num_values [llength $sine_values]

    echo "Beginning stimulus loop..."
    # This single loop will run for 200 samples
    for {set i 0} {$i < 200} {incr i} {

        # Get the next sine value from the list, wrapping around if necessary
        set current_index [expr {$i % $num_values}]
        set current_value [lindex $sine_values $current_index]

        # Handle negative numbers
        if {$current_value < 0} {
            set force_value [expr {(1 << 12) + $current_value}]
        } else {
            set force_value $current_value
        }

        # Apply the new sine value to the top-level stimulus input
        force /min_system_fir_test/stimulus_i "12'd$force_value"

        # Create the one-cycle sample_valid pulse
        force /min_system_fir_test/sample_valid_i 1
        run $clk_period ns
        force /min_system_fir_test/sample_valid_i 0

        # Run for the rest of the sample period before the loop repeats
        run [expr {$sample_period - $clk_period}]ns
    }

    echo "--- Test Procedure Finished ---"
    wave zoom full
}

# Execute the test
run_test
