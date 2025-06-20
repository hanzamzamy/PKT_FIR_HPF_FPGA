library ieee;
use ieee.std_logic_1164.all;

-- This entity is a simple wrapper to connect the packet generator and the UART transmitter.
entity min_system_test is
    port (
        clk_i              : in  std_logic;
        rst_i              : in  std_logic;

        -- Stimulus Inputs for the test
        unfiltered_data_i  : in  std_logic_vector(11 downto 0);
        filtered_data_i    : in  std_logic_vector(11 downto 0);
        data_valid_i       : in  std_logic;

        -- Final output to observe
        uart_tx_pin_o      : out std_logic
    );
end entity min_system_test;

architecture structural of min_system_test is

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

    -- Internal signals to connect the two components
    signal s_uart_data : std_logic_vector(7 downto 0);
    signal s_uart_start: std_logic;
    signal s_uart_busy : std_logic;

begin

    -- Instantiate the Packet Generator
    packet_inst : component tx_packet_gen
        port map (
            clk_i             => clk_i,
            rst_i             => rst_i,
            unfiltered_data_i => unfiltered_data_i,
            filtered_data_i   => filtered_data_i,
            data_valid_i      => data_valid_i,
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
