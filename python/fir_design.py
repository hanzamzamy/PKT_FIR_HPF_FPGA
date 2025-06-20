import numpy as np
from scipy import signal
import matplotlib.pyplot as plt

F_SAMP = 20000       # Sampling frequency in Hz
F_CUTOFF = 1800      # Cut-off frequency in Hz
NUM_TAPS = 101       # Number of filter taps (coefficients)
WINDOW_TYPE = 'hamming' # Window function to use

# Bit width for quantizing coefficients for the FPGA
COEFFICIENT_BIT_WIDTH = 16

# Get taps parameters (floating-point)
taps_float = signal.firwin(NUM_TAPS,
                           cutoff=F_CUTOFF,
                           fs=F_SAMP,
                           pass_zero=False,
                           window=WINDOW_TYPE)


# Calculate the maximum integer value for a signed number
# For 16 bits, range is -32768 to 32767.
max_int_value = 2**(COEFFICIENT_BIT_WIDTH - 1) - 1

# Scale the floating point taps to the integer range,
# round them, and convert to integer type.
taps_quantized = np.round(taps_float * max_int_value).astype(int)


# Get the frequency response for the ideal filter
w_ideal, h_ideal = signal.freqz(taps_float, fs=F_SAMP)

# Get the frequency response for the quantized filter
w_quant, h_quant = signal.freqz(taps_quantized, fs=F_SAMP)

# Get the gain back to match ideal gain format
gain_quant_true = np.abs(h_quant) / max_int_value
epsilon = 1e-10 # epsilon to avoid division by zero

# Create the plot
plt.figure(figsize=(12, 8))

# Plot the IDEAL filter response in dB
plt.plot(w_ideal, 20 * np.log10(abs(h_ideal) + epsilon), label='Ideal (Floating Point)', linewidth=3, alpha=0.7)

# Plot the QUANTIZED filter response in dB
plt.plot(w_quant, 20 * np.log10(gain_quant_true + epsilon), 'r--', label=f'Quantized ({COEFFICIENT_BIT_WIDTH}-bit)', linewidth=1.5)

# Mark the cutoff frequency with a vertical line
plt.axvline(F_CUTOFF, color='g', linestyle=':', linewidth=2, label=f'Cut-off Freq ({F_CUTOFF} Hz)')

# Formatting the plot for clarity
plt.title('FIR High-Pass Filter Frequency Response')
plt.xlabel('Frequency (Hz)')
plt.ylabel('Magnitude (dB)')
plt.grid(True, which='both', linestyle='--', alpha=0.6)
plt.legend()
plt.ylim(-80, 5) # Set a reasonable dB range for the y-axis
plt.xlim(0, F_SAMP / 2) # Plot up to the Nyquist frequency
plt.show()


print("--- VHDL Coefficient Array ---")
print(f"-- Filter: High-Pass, Fs={F_SAMP}Hz, Fcut={F_CUTOFF}Hz, Taps={NUM_TAPS}")
print(f"type T_COEFF_ARRAY is array (0 to {NUM_TAPS-1}) of integer;")
print(f"constant C_FIR_COEFFS : T_COEFF_ARRAY := (")

# Print coefficients in a formatted way for VHDL
for i, coeff in enumerate(taps_quantized):
    if i % 8 == 0: # Start a new line every 8 coefficients
        print("\n    ", end="")
    # Format the number to align them nicely, and add a comma
    print(f"to_signed({str(coeff):>6}", end=", 16)")
    if i < NUM_TAPS - 1:
        print(", ", end="")

print("\n);")
print("\n--- End of VHDL Array ---")
