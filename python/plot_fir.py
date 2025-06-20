import pandas as pd
import matplotlib.pyplot as plt

# --- Configuration ---
INPUT_FILENAME = "sim_data.csv"

# --- Main Script ---
try:
    df = pd.read_csv(INPUT_FILENAME)
    print("Successfully loaded sim_data.csv")
    print(df.head()) # Print first 5 rows to check
except FileNotFoundError:
    print(f"Error: Could not find the file '{INPUT_FILENAME}'.")
    exit()

# Create the plot with two subplots, sharing the x-axis
fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 8), sharex=True)
fig.suptitle('FIR Filter Simulation Results from VHDL', fontsize=16)

# Plot 1: Input
ax1.plot(df['Sample'], df['Sample_Input'], label='Sample Input', color='b')
ax1.set_ylabel('Amplitude')
ax1.set_title('Input Stimulus')
ax1.grid(True)
ax1.legend()

# Plot 2: Output
ax2.plot(df['Sample'], df['Filtered_Output'], label='Filtered Output', color='r')
ax2.set_ylabel('Amplitude (Scaled)')
ax2.set_title('Filtered Output')
ax2.set_xlabel('Sample Number')
ax2.grid(True)
ax2.legend()

# Show the plot
plt.tight_layout(rect=[0, 0, 1, 0.96])
plt.show()
