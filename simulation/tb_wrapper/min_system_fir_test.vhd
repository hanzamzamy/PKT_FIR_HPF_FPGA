library ieee;
use ieee.std_logic_1164.all;

-- This wrapper now connects a stimulus input through the FIR filter
-- and then to the packet generator and UART transmitter.
entity min_system_fir_test is
    port (
        clk_i         : in  std_logic;
        rst_i         : in  std_logic;

        -- Stimulus Inputs for the test
        sample_valid_i : in  std_logic; -- A pulse at the sampling frequency
        stimulus_i     : in  std_logic_vector(11 downto 0); -- The digital test signal

        -- Final output to observe
        uart_tx_pin_o  : out std_logic
    );
end entity min_system_fir_test;

architecture structural of min_system_fir_test is

    component fir_filter is
        port (
            clk_i            : in  std_logic;
            rst_i            : in  std_logic;
            sample_i         : in  std_logic_vector(11 downto 0);
            sample_valid_i   : in  std_logic;
            filtered_o       : out std_logic_vector(11 downto 0);
            filtered_valid_o : out std_logic
        );
    end component fir_filter;

    component tx_packet_gen is
        port (
            clk_i              : in  std_logic;
            rst_i              : in  std_logic;
            unfiltered_data_i  : in  std_logic_vector(11 downto 0);
            filtered_data_i    : in  std_logic_vector(11 downto 0);
            data_valid_i       : in  std_logic;
            uart_data_o        : out std_logic_vector(7 downto 0);
            uart_start_o       : out std_logic;
            uart_busy_i        : in  std_logic
        );
    end component tx_packet_gen;

    component uart_tx is
        generic (
            CLK_FREQ  : integer;
            BAUD_RATE : integer
        );
        port (
            clk_i      : in  std_logic;
            rst_i      : in  std_logic;
            tx_start_i : in  std_logic;
            data_i     : in  std_logic_vector(7 downto 0);
            tx_busy_o  : out std_logic;
            tx_o       : out std_logic
        );
    end component uart_tx;

    -- Internal signals to connect the components
    signal s_filtered_data    : std_logic_vector(11 downto 0);
    signal s_fir_output_valid : std_logic;
    signal s_uart_data        : std_logic_vector(7 downto 0);
    signal s_uart_start       : std_logic;
    signal s_uart_busy        : std_logic;

begin

    -- Instantiate the FIR Filter
    fir_inst : component fir_filter
        port map (
            clk_i            => clk_i,
            rst_i            => rst_i,
            sample_i         => stimulus_i, -- The test signal is the input
            sample_valid_i   => sample_valid_i,
            filtered_o       => s_filtered_data,
            filtered_valid_o => s_fir_output_valid
        );

    -- Instantiate the Packet Generator
    packet_inst : component tx_packet_gen
        port map (
            clk_i             => clk_i,
            rst_i             => rst_i,
            unfiltered_data_i => stimulus_i, -- Pass the original stimulus through
            filtered_data_i   => s_filtered_data, -- Use the output from the filter
            data_valid_i      => s_fir_output_valid,
            uart_data_o       => s_uart_data,
            uart_start_o      => s_uart_start,
            uart_busy_i       => s_uart_busy
        );

    -- Instantiate the UART Transmitter
    uart_inst : component uart_tx
        generic map (
            CLK_FREQ  => 50_000_000,
            BAUD_RATE => 1_000_000
        )
        port map (
            clk_i      => clk_i,
            rst_i      => rst_i,
            tx_start_i => s_uart_start,
            data_i     => s_uart_data,
            tx_busy_o  => s_uart_busy,
            tx_o       => uart_tx_pin_o
        );

end architecture structural;
