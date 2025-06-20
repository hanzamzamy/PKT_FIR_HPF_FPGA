library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tx_packet_gen is
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
end entity tx_packet_gen;

architecture rtl of tx_packet_gen is

    -- Transmitter state machine
	 -- Each state has explicit start and wait
    type T_STATE is (
        ST_IDLE,
        ST_SEND_SYNC,
        ST_WAIT_SYNC,
        ST_SEND_BYTE_0,
        ST_WAIT_BYTE_0,
        ST_SEND_BYTE_1,
        ST_WAIT_BYTE_1,
        ST_SEND_BYTE_2,
        ST_WAIT_BYTE_2
    );
    signal s_state      : T_STATE := ST_IDLE;
    signal s_next_state : T_STATE := ST_IDLE;

    constant C_SYNC_BYTE : std_logic_vector(7 downto 0) := x"AA";

    -- Internal registers for each byte transmitted
    signal r_byte_0 : std_logic_vector(7 downto 0);
    signal r_byte_1 : std_logic_vector(7 downto 0);
    signal r_byte_2 : std_logic_vector(7 downto 0);

begin

    -- Sequential Logic for State and Data
    state_reg_proc: process(clk_i, rst_i)
    begin
        if (rst_i = '1') then
            s_state <= ST_IDLE;
        elsif rising_edge(clk_i) then
            s_state <= s_next_state;
            
            -- Latch the data when a valid pulse comes in
            if (data_valid_i = '1') then
                r_byte_0 <= unfiltered_data_i(7 downto 0);
                r_byte_1 <= filtered_data_i(7 downto 0);
                r_byte_2 <= unfiltered_data_i(11 downto 8) & filtered_data_i(11 downto 8);
            end if;
        end if;
    end process state_reg_proc;


    -- Combinational Logic for Outputs and Next State
    next_state_and_output_logic_proc: process(s_state, data_valid_i, uart_busy_i, r_byte_0, r_byte_1, r_byte_2)
    begin
        -- Default assignments
        uart_start_o <= '0';
        uart_data_o  <= (others => '0');
        s_next_state <= s_state; -- Default to staying in the current state

        case s_state is
            when ST_IDLE =>
                if (data_valid_i = '1' and uart_busy_i = '0') then
                    s_next_state <= ST_SEND_SYNC;
                end if;

            when ST_SEND_SYNC =>
                uart_data_o  <= C_SYNC_BYTE;
                uart_start_o <= '1';
                s_next_state <= ST_WAIT_SYNC; -- Unconditionally go to WAIT state next

            when ST_WAIT_SYNC =>
                uart_data_o <= C_SYNC_BYTE; -- Hold the data output stable
                if (uart_busy_i = '0') then -- Go to next state after UART transmit complete
                    s_next_state <= ST_SEND_BYTE_0;
                end if;

            when ST_SEND_BYTE_0 =>
                uart_data_o  <= r_byte_0;
                uart_start_o <= '1';
                s_next_state <= ST_WAIT_BYTE_0;

            when ST_WAIT_BYTE_0 =>
                uart_data_o <= r_byte_0;
                if (uart_busy_i = '0') then
                    s_next_state <= ST_SEND_BYTE_1;
                end if;

            when ST_SEND_BYTE_1 =>
                uart_data_o  <= r_byte_1;
                uart_start_o <= '1';
                s_next_state <= ST_WAIT_BYTE_1;

            when ST_WAIT_BYTE_1 =>
                uart_data_o <= r_byte_1;
                if (uart_busy_i = '0') then
                    s_next_state <= ST_SEND_BYTE_2;
                end if;

            when ST_SEND_BYTE_2 =>
                uart_data_o  <= r_byte_2;
                uart_start_o <= '1';
                s_next_state <= ST_WAIT_BYTE_2;

            when ST_WAIT_BYTE_2 =>
                uart_data_o <= r_byte_2;
                if (uart_busy_i = '0') then
                    s_next_state <= ST_IDLE; -- Packet complete, return to idle
                end if;
                
        end case;
    end process next_state_and_output_logic_proc;

end architecture rtl;