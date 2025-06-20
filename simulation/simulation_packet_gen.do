echo "==================================================="
echo "TX_PACKET_GEN UNIT TEST SCRIPT"
echo "==================================================="

# Create environment
if {[file isdirectory work]} { file delete -force work }
vlib work
vmap work work

echo "INFO: Compiling tx_packet_gen.vhd..."
vcom -work work -2008 ../tx_packet_gen.vhd
echo "INFO: Compilation complete."

# Load the tx_packet_gen entity into the simulator
echo "INFO: Loading tx_packet_gen entity into simulator..."
vsim -voptargs="+acc" work.tx_packet_gen

# Add all internal and port signals to the wave window
echo "INFO: Adding all internal signals to wave window..."
add wave -divider "Ports"
add wave /tx_packet_gen/clk_i
add wave /tx_packet_gen/rst_i
add wave -radix hex /tx_packet_gen/unfiltered_data_i
add wave -radix hex /tx_packet_gen/filtered_data_i
add wave /tx_packet_gen/data_valid_i
add wave -radix hex /tx_packet_gen/uart_data_o
add wave /tx_packet_gen/uart_start_o
add wave /tx_packet_gen/uart_busy_i

add wave -divider "Internal State"
add wave /tx_packet_gen/s_state
add wave -radix hex /tx_packet_gen/r_byte_0
add wave -radix hex /tx_packet_gen/r_byte_1
add wave -radix hex /tx_packet_gen/r_byte_2


proc run_packet_gen_test {} {
    echo "--- Starting Packet Generator Test Procedure ---"

    # Define one clock period time for clarity
    set clk_period 20

    # Generate the 50MHz clock
    force -freeze /tx_packet_gen/clk_i 1 0, 0 [expr {$clk_period / 2}]ns -repeat [expr {$clk_period}]ns

    # Provide dummy data inputs
    force /tx_packet_gen/unfiltered_data_i 12'hABC
    force /tx_packet_gen/filtered_data_i   12'h123

    # Initialize other inputs
    force /tx_packet_gen/data_valid_i 0
    force /tx_packet_gen/uart_busy_i 0

    # Apply reset
    echo "Applying reset..."
    force /tx_packet_gen/rst_i 1
    run [expr {$clk_period * 10}]ns
    force /tx_packet_gen/rst_i 0
    echo "Reset released. Packet generator is in IDLE state."
    run [expr {$clk_period * 10}]ns

    # Trigger the state machine with a single-cycle pulse on data_valid_i
    echo "Pulsing data_valid_i to start packet transmission..."
    force /tx_packet_gen/data_valid_i 1
    run [expr {$clk_period}]ns
    force /tx_packet_gen/data_valid_i 0

    # This loop models the behavior of the UART's busy signal for all 4 bytes
    for {set i 0} {$i < 4} {incr i} {

        echo "Waiting for start pulse for byte $i..."
        # This loop will run for a maximum of 5000 clock cycles (100us)
        # It checks the uart_start_o signal on every clock cycle.
        set timeout 5000
        while {[examine /tx_packet_gen/uart_start_o] != 1 && $timeout > 0} {
            run [expr {$clk_period}]ns
            set timeout [expr {$timeout - 1}]
        }

        if {$timeout == 0} {
            echo "ERROR: Timed out waiting for uart_start_o for byte $i"
            break
        }

        # Once the start pulse has seen, simulate the UART being busy for 10us
        echo "Start pulse received for byte $i. Modeling UART as busy..."
        force /tx_packet_gen/uart_busy_i 1
        run 10us ; # 10 bits * 1us/bit = 10us for one byte at 1 Mbaud
        force /tx_packet_gen/uart_busy_i 0
        run [expr {$clk_period}]ns ; # Small delay before it can start the next byte
    }

    echo "--- Test Procedure Finished ---"
    wave zoom full
}

# Execute the test
run_packet_gen_test
