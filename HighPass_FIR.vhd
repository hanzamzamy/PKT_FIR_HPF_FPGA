library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity HighPass_FIR is
    port (
        ------------ CLOCK ------------
        ADC_CLK_10      : in  std_logic;
        MAX10_CLK1_50   : in  std_logic;
        MAX10_CLK2_50   : in  std_logic;
        ------------ KEY --------------
        KEY             : in  std_logic_vector(1 downto 0);
        ------------ ARDUINO ----------
        ARDUINO_IO      : inout std_logic_vector(15 downto 0);
        ARDUINO_RESET_N : inout std_logic
    );
end entity HighPass_FIR;


architecture rtl of HighPass_FIR is

    --=======================================================
    --  1. Design Parameters and Constants
    --=======================================================
    constant SAMPLING_RATE_HZ : integer := 20_000;    -- 20 kSPS
    constant BAUD_RATE_BPS    : integer := 1_000_000;  -- 1 Mbps
    constant CLK_FREQ_HZ      : integer := 50_000_000;
    constant CLK_DIVIDER      : integer := CLK_FREQ_HZ / SAMPLING_RATE_HZ;

    --=======================================================
    --  2. Component Declarations
    --=======================================================
    component de10_lite_adc is
        port (
            CLOCK : in  std_logic := '0';
            RESET : in  std_logic := '0';
            CH0   : out std_logic_vector(11 downto 0)
        );
    end component de10_lite_adc;

    component fir_filter is
        port (
            clk_i          : in  std_logic;
            rst_i          : in  std_logic;
            sample_i       : in  std_logic_vector(11 downto 0);
            sample_valid_i : in  std_logic;
            filtered_o     : out std_logic_vector(11 downto 0);
            filtered_valid_o: out std_logic
        );
    end component fir_filter;

    component tx_packet_gen is
        port (
            clk_i             : in  std_logic;
            rst_i             : in  std_logic;
            unfiltered_data_i : in  std_logic_vector(11 downto 0);
            filtered_data_i   : in  std_logic_vector(11 downto 0);
            data_valid_i      : in  std_logic;
            uart_data_o       : out std_logic_vector(7 downto 0);
            uart_start_o      : out std_logic;
            uart_busy_i       : in  std_logic
        );
    end component tx_packet_gen;

    component uart_tx is
        generic (
            CLK_FREQ  : integer := 50_000_000;
            BAUD_RATE : integer := 1_000_000
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


    --=======================================================
    --  3. Internal Signals
    --=======================================================
    signal clk                : std_logic;
    signal rst                : std_logic;
    signal sample_clk_tick    : std_logic;
    signal adc_ch0_data       : std_logic_vector(11 downto 0);
    signal filtered_data      : std_logic_vector(11 downto 0);
    signal fir_output_valid   : std_logic;
    signal uart_tx_data       : std_logic_vector(7 downto 0);
    signal uart_tx_start      : std_logic;
    signal uart_is_busy       : std_logic;
    signal uart_tx_pin        : std_logic;

begin

    --=======================================================
    --  4. Concurrent Statements and Assignments
    --=======================================================
    clk <= MAX10_CLK1_50;
    rst <= not KEY(0); -- KEYs are active-low, invert as active-high reset
    ARDUINO_IO(1) <= uart_tx_pin; -- Assign UART TX pin to Arduino D1

    --=======================================================
    --  5. Sampling Clock Generator
    --=======================================================
    sampling_clk_process: process(clk, rst)
        variable v_counter : integer range 0 to CLK_DIVIDER - 1 := 0;
    begin
        if (rst = '1') then
            v_counter       := 0;
            sample_clk_tick <= '0';
        elsif rising_edge(clk) then
            if (v_counter = CLK_DIVIDER - 1) then
                v_counter       := 0;
                sample_clk_tick <= '1';
            else
                v_counter       := v_counter + 1;
                sample_clk_tick <= '0';
            end if;
        end if;
    end process sampling_clk_process;

    --=======================================================
    --  6. Module Instantiations
    --=======================================================
    adc_inst : component de10_lite_adc
    port map (
        CLOCK => clk,
        RESET => rst,
        CH0   => adc_ch0_data
    ); -- Instantiate ADC Controller

    fir_inst : component fir_filter
    port map (
        clk_i          => clk,
        rst_i          => rst,
        sample_i       => adc_ch0_data,
        sample_valid_i => sample_clk_tick,
        filtered_o     => filtered_data,
        filtered_valid_o=> fir_output_valid
    ); -- Instantiate FIR Filter


    packet_inst : component tx_packet_gen
    port map (
        clk_i             => clk,
        rst_i             => rst,
        unfiltered_data_i => adc_ch0_data,
        filtered_data_i   => filtered_data,
        data_valid_i      => fir_output_valid,
        uart_data_o       => uart_tx_data,
        uart_start_o      => uart_tx_start,
        uart_busy_i       => uart_is_busy
    ); -- Instantiate Packet Generator


    uart_inst : component uart_tx
    generic map (
        CLK_FREQ  => CLK_FREQ_HZ,
        BAUD_RATE => BAUD_RATE_BPS
    )
    port map (
        clk_i      => clk,
        rst_i      => rst,
        tx_start_i => uart_tx_start,
        data_i     => uart_tx_data,
        tx_busy_o  => uart_is_busy,
        tx_o       => uart_tx_pin
    ); -- Instantiate UART Transmitter

end architecture rtl;
