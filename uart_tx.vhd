library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tx is
    generic (
        CLK_FREQ     : integer := 50_000_000; -- System clock frequency in Hz
        BAUD_RATE    : integer := 1_000_000   -- Desired baud rate
    );
    port (
        clk_i       : in  std_logic;
        rst_i       : in  std_logic;

        -- Control signals
        tx_start_i  : in  std_logic; -- A one-cycle pulse to start transmission
        data_i      : in  std_logic_vector(7 downto 0); -- The 8-bit data to send

        -- Status and data output
        tx_busy_o   : out std_logic; -- High while transmitting
        tx_o        : out std_logic  -- The single serial output pin
    );
end entity uart_tx;


architecture rtl of uart_tx is

    -- Calculate how many clock cycles make up one serial bit time.
    constant CLK_PER_BIT : integer := CLK_FREQ / BAUD_RATE;

    -- Define the states for our transmission state machine.
    type T_STATE is (
        ST_IDLE,
        ST_START_BIT,
        ST_DATA_BITS,
        ST_STOP_BIT
    );

    signal s_state : T_STATE := ST_IDLE;

    -- Internal registers for the transmission logic
    signal s_clk_counter : integer range 0 to CLK_PER_BIT - 1 := 0;
    signal s_bit_counter : integer range 0 to 7 := 0;
    signal s_data_reg    : std_logic_vector(7 downto 0) := (others => '0');
    signal s_tx_busy     : std_logic := '0';

begin

    -- Assign the internal busy signal to the output port.
    tx_busy_o <= s_tx_busy;

    uart_process: process(clk_i, rst_i)
    begin
        if (rst_i = '1') then
            -- Asynchronous reset condition
            s_state       <= ST_IDLE;
            s_clk_counter <= 0;
            s_bit_counter <= 0;
            s_tx_busy     <= '0';
            tx_o          <= '1'; -- UART line is high when idle

        elsif rising_edge(clk_i) then

            case s_state is

                when ST_IDLE =>
                    s_tx_busy <= '0';
                    tx_o      <= '1'; -- Drive the line high when idle

                    -- Wait for the 'start' signal
                    if (tx_start_i = '1') then
                        s_data_reg    <= data_i; -- Latch the input data
                        s_clk_counter <= 0;
                        s_tx_busy     <= '1';
                        s_state       <= ST_START_BIT;
                    end if;

                when ST_START_BIT =>
                    tx_o <= '0'; -- Drive the line low for the start bit

                    -- Wait for one full bit time
                    if (s_clk_counter = CLK_PER_BIT - 1) then
                        s_clk_counter <= 0;
                        s_bit_counter <= 0;
                        s_state       <= ST_DATA_BITS;
                    else
                        s_clk_counter <= s_clk_counter + 1;
                    end if;

                when ST_DATA_BITS =>
                    -- Output the current bit from our latched data register
                    tx_o <= s_data_reg(s_bit_counter);

                    -- Wait for one full bit time
                    if (s_clk_counter = CLK_PER_BIT - 1) then
                        s_clk_counter <= 0;

                        -- Check if we have sent all 8 data bits
                        if (s_bit_counter = 7) then
                            s_state <= ST_STOP_BIT;
                        else
                            s_bit_counter <= s_bit_counter + 1;
                        end if;
                    else
                        s_clk_counter <= s_clk_counter + 1;
                    end if;

                when ST_STOP_BIT =>
                    tx_o <= '1'; -- Drive the line high for the stop bit

                    -- Wait for one full bit time
                    if (s_clk_counter = CLK_PER_BIT - 1) then
                        s_clk_counter <= 0;
                        s_state       <= ST_IDLE; -- Transmission complete, return to idle
                    else
                        s_clk_counter <= s_clk_counter + 1;
                    end if;

            end case;
        end if;
    end process uart_process;

end architecture rtl;
