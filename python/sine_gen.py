import numpy as np

# --- Configuration ---
SAMPLE_RATE = 20000  # Must match VHDL design
SINE_FREQ = 5000     # Frequency in Hz
AMPLITUDE = 1500     # Amplitude in digital value
FILENAME = "sine_stimulus.txt"

# --- Calculation ---
# Calculate the number of samples in one full sine wave cycle
num_samples = int(SAMPLE_RATE / SINE_FREQ)
# Create the time axis for one cycle
t = np.linspace(0, 1.0 / SINE_FREQ, num=num_samples, endpoint=False)
# Generate the floating-point sine wave
sine_wave_float = AMPLITUDE * np.sin(2 * np.pi * SINE_FREQ * t)
# Convert to integers
sine_wave_int = np.round(sine_wave_float).astype(int)

# --- File Writing ---
with open(FILENAME, 'w') as f:
    for val in sine_wave_int:
        f.write(f"{val}\n")

print(f"Generated {len(sine_wave_int)} samples for a {SINE_FREQ}Hz sine wave into '{FILENAME}'.")
