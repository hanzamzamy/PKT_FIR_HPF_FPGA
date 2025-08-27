# HighPass FIR Filter on DE10-Lite FPGA

This repository contains the implementation of a high-pass FIR filter on the DE10-Lite FPGA platform. The project includes VHDL modules for FIR filtering, UART transmission, packet generation, and integration with the DE10-Lite ADC IP core.

## Repository Structure

- `fir_filter.vhd`  
  VHDL source for the FIR filter module.

- `de10_lite_adc/`  
  Contains the DE10-Lite ADC IP core files, including synthesis and simulation submodules.

- `latex/report.tex`  
  LaTeX documentation describing the design, implementation, and results.

- Other Quartus project files (`.qpf`, `.qsf`, `.sopcinfo`, etc.)

## Main Modules

- **fir_filter**  
  Implements a quantized FIR high-pass filter.

- **uart_tx**  
  UART transmitter module for sending filtered data at 1 Mbps.

- **tx_packet_gen**  
  Packs ADC input and FIR output into UART packets (1 sync byte + 3 data bytes).

- **de10_lite_adc**  
  ADC IP core for sampling analog signals at 20 kHz.

## Top-Level Design

The top-level module connects the ADC, FIR filter, packet generator, and UART transmitter. Data flow:

1. ADC samples analog input.
2. FIR filter processes the sampled data.
3. Packet generator formats the input and output data for UART transmission.
4. UART transmitter sends the packet to a host computer.

## Simulation & Synthesis

- Synthesis and simulation scripts are provided in `de10_lite_adc/simulation/` and `de10_lite_adc/synthesis/`.
- Use Quartus Prime to build and program the FPGA.

## Documentation

Report is available in [latex/report.pdf](latex/report.pdf).

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

## Author

Rayhan R. Zamzamy