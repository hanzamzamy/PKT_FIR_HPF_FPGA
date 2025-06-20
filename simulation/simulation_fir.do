echo "==================================================="
echo "FIR_FILTER UNIT TEST SCRIPT"
echo "==================================================="

# Create environment
vlib work
vmap work work

vcom -work work -2008 ../fir_filter.vhd
echo "INFO: Compilation complete."

# Load the fir_filter entity into the simulator
vsim -voptargs="+acc" work.fir_filter

# Add signals to the wave window
add wave -divider "Inputs"
add wave /fir_filter/clk_i
add wave /fir_filter/rst_i
add wave -radix signed /fir_filter/sample_i
add wave /fir_filter/sample_valid_i
add wave -divider "Outputs"
add wave -radix signed /fir_filter/filtered_o
add wave /fir_filter/filtered_valid_o

add wave -divider "Accumulator"
add wave -radix signed /fir_filter/accumulator_o


proc run_test_and_export {} {
    # --- File I/O Setup ---
    set fileId [open "sim_data.csv" w]
    # Write the header row for our CSV file
    puts $fileId "Sample,Sample_Input,Filtered_Output"
    set sample_count 0

    # --- Stimulus Setup ---
    set clk_period 20
    set sample_period 50000
    force -freeze /fir_filter/clk_i 1 0, 0 [expr {$clk_period / 2}]ns -repeat [expr {$clk_period}]ns
    force /fir_filter/sample_i 0
    force /fir_filter/sample_valid_i 0
    force /fir_filter/rst_i 1
    run 200 ns
    force /fir_filter/rst_i 0
    run 200 ns
    set f [open "sine_stimulus.txt" r]
    set sine_values [split [string trim [read $f]] "\n"]
    close $f
    set num_values [llength $sine_values]

    echo "Beginning stimulus and data export loop..."
    # Loop for 200 samples
    for {set i 0} {$i < 200} {incr i} {
        set current_index [expr {$i % $num_values}]
        set current_value [lindex $sine_values $current_index]
        if {$current_value < 0} {
            set force_value [expr {(1 << 12) + $current_value}]
        } else {
            set force_value $current_value
        }
        force /fir_filter/sample_i "12'd$force_value"

        # Create the sample_valid pulse
        force /fir_filter/sample_valid_i 1
        run $clk_period ns
        force /fir_filter/sample_valid_i 0

        # --- DATA CAPTURE ---
        # At this exact moment, the calculation is done and outputs are valid.
        set sample_in [examine -radix signed /fir_filter/sample_i]
        set accum_out [examine -radix signed /fir_filter/filtered_o]
        # Write the captured values to the file
        puts $fileId "$sample_count,$sample_in,$accum_out"
        set sample_count [expr {$sample_count + 1}]

        # Run for the rest of the sample period
        run [expr {$sample_period - $clk_period}]ns
    }

    # --- Cleanup ---
    close $fileId
    echo "--- Data export finished. See sim_data.csv ---"
    wave zoom full
}

# Execute the test
run_test
