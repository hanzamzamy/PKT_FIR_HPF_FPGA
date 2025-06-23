import serial
import struct
import threading
import queue
import time
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.animation as animation

# --- Configuration ---
SERIAL_PORT = '/dev/ttyUSB0'
BAUD_RATE = 1_000_000
SAMPLE_RATE = 20_000          # 20 kHz

# Plotting settings
PLOT_DURATION_S = 0.005
NUM_PLOT_SAMPLES = int(SAMPLE_RATE * PLOT_DURATION_S)

# FFT settings
FFT_SIZE = 4096

# --- Global Variables ---
data_queue = queue.Queue()
run_thread = True


def serial_reader_thread(port, baud, q):
    """Reads 4-byte packets (Sync + 3 Data) from the serial port."""
    print(f"Reader thread started on {port} at {baud} baud.")
    try:
        ser = serial.Serial(port, baud, timeout=1)
    except serial.SerialException as e:
        print(f"Error opening serial port: {e}")
        return

    sync_byte = 0xAA
    while run_thread:
        byte = ser.read(1)
        if not byte:
            continue
        if byte[0] == sync_byte:
            packet = ser.read(3)
            if len(packet) == 3:
                q.put(packet)

    ser.close()
    print("Reader thread finished.")


# --- Setup the live plot ---
fig, ax = plt.subplots()
time_axis = np.linspace(0, PLOT_DURATION_S * 1000, NUM_PLOT_SAMPLES) # Time in ms
line_unfiltered, = ax.plot(time_axis, np.zeros(NUM_PLOT_SAMPLES), lw=1, label='Unfiltered')
line_filtered, = ax.plot(time_axis, np.zeros(NUM_PLOT_SAMPLES), lw=1.5, label='Filtered')
ax.set_title('Real-Time FIR Filter Data (Press ''f'' for Frequency Response)')
ax.set_xlabel('Time (ms)')
ax.set_ylabel('ADC Value')
ax.legend(loc='upper right')
ax.grid(True)
ax.set_ylim(-2048, 2047)

# --- Data buffers and metrics variables ---
unfiltered_buffer = np.zeros(NUM_PLOT_SAMPLES)
filtered_buffer = np.zeros(NUM_PLOT_SAMPLES)

packet_counter = 0
last_update_time = time.time()

data_rate_str = "Data Rate: 0.00 KB/s"
msg_rate_str = "Msg Rate: 0 Hz"

metrics_text = ax.text(0.02, 0.95, "", transform=ax.transAxes, verticalalignment='top',
                       bbox=dict(boxstyle='round', facecolor='wheat', alpha=0.5))

def process_packet(packet):
    """Helper function to parse one 3-byte packet."""
    byte0, byte1, byte2 = packet
    unfiltered_val = ((byte2 & 0xF0) << 4) | byte0
    filtered_val = ((byte2 & 0x0F) << 8) | byte1
    if unfiltered_val > 2047: unfiltered_val -= 4096
    if filtered_val > 2047:   filtered_val -= 4096
    return unfiltered_val, filtered_val


def update_plot(frame):
    """Updates the live time-domain plot and metrics."""
    global unfiltered_buffer, filtered_buffer, packet_counter, last_update_time, data_rate_str, msg_rate_str

    packets_in_frame = 0
    while not data_queue.empty():
        try:
            packet = data_queue.get_nowait()
            packets_in_frame += 1
            unfiltered_val, filtered_val = process_packet(packet)

            unfiltered_buffer = np.roll(unfiltered_buffer, -1)
            unfiltered_buffer[-1] = unfiltered_val

            filtered_buffer = np.roll(filtered_buffer, -1)
            filtered_buffer[-1] = filtered_val
        except queue.Empty:
            break

    if packets_in_frame > 0:
        packet_counter += packets_in_frame
        current_time = time.time()
        elapsed_time = current_time - last_update_time

        if elapsed_time > 1: # Update rate every 0.5 seconds
            message_rate = packet_counter / elapsed_time
            # Each packet is 4 bytes (1 sync + 3 data)
            data_rate_kbps = (message_rate * 4) / 1024

            # Update the strings
            data_rate_str = f"Data Rate: {data_rate_kbps:.2f} KB/s"
            msg_rate_str = f"Msg Rate: {int(message_rate)} Hz"

            # Reset counters
            packet_counter = 0
            last_update_time = current_time

    # Update the metrics text on the plot
    queue_size = data_queue.qsize()
    metrics_text.set_text(f"Queue Size: {queue_size}\n{msg_rate_str}\n{data_rate_str}")

    line_unfiltered.set_ydata(unfiltered_buffer)
    line_filtered.set_ydata(filtered_buffer)

    return line_unfiltered, line_filtered, metrics_text


def calculate_and_plot_freq_response(event):
    """Captures data, performs FFT, and plots the frequency response."""
    if event.key == 'f':
        print("\n'f' key pressed. Capturing data for frequency response...")

        unfiltered_samples = []
        filtered_samples = []

        while not data_queue.empty():
            data_queue.get_nowait()

        print(f"Capturing {FFT_SIZE} samples...")
        while len(unfiltered_samples) < FFT_SIZE:
            try:
                packet = data_queue.get(timeout=1)
                unfiltered_val, filtered_val = process_packet(packet)
                unfiltered_samples.append(unfiltered_val)
                filtered_samples.append(filtered_val)
            except queue.Empty:
                print("Error: Timed out waiting for data. Is the FPGA sending?")
                return
        print("Capture complete.")

        unfiltered_np = np.array(unfiltered_samples)
        filtered_np = np.array(filtered_samples)

        fft_unfiltered = np.fft.fft(unfiltered_np)
        fft_filtered = np.fft.fft(filtered_np)

        freq_axis = np.fft.fftfreq(FFT_SIZE, d=1/SAMPLE_RATE)

        epsilon = 1e-10
        gain = np.abs(fft_filtered) / (np.abs(fft_unfiltered) + epsilon)
        gain_db = 20 * np.log10(gain + epsilon)

        plt.figure(figsize=(12, 8))
        plt.plot(freq_axis[:FFT_SIZE//2], gain_db[:FFT_SIZE//2])
        plt.title('Hardware Frequency Response')
        plt.xlabel('Frequency (Hz)')
        plt.ylabel('Magnitude (dB)')
        plt.grid(True, which='both', linestyle='--')
        plt.ylim(-80, 5)
        plt.xlim(0, SAMPLE_RATE / 2)
        plt.axvline(1800, color='r', linestyle=':', label='Theoretical Cutoff (1800 Hz)')
        plt.legend()
        plt.show()


if __name__ == '__main__':
    reader = threading.Thread(target=serial_reader_thread, args=(SERIAL_PORT, BAUD_RATE, data_queue))
    reader.daemon = True
    reader.start()

    fig.canvas.mpl_connect('key_press_event', calculate_and_plot_freq_response)

    ani = animation.FuncAnimation(fig, update_plot, interval=30, blit=False)

    try:
        plt.show()
    except KeyboardInterrupt:
        print("Plot closed.")
    finally:
        run_thread = False
        reader.join()
        print("Program finished.")
