-- latency_on_pin_fsm
--
-- To measure the payload lateny via gpio
--
-- Marco Riggirello, May 2022

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity latency_on_pin_fsm is
  port(
    clk           : in  std_logic;
    rst           : in  std_logic;
    algo_data_in  : in  std_logic := '0';
    algo_data_out : in  std_logic := '0';
    latency_pin   : out std_logic := '0';
    latency_count : out std_logic_vector(31 downto 0)
  );

end latency_on_pin_fsm;

architecture rtl of latency_on_pin_fsm is

  type state_t is (waiting_for_in, waiting_for_out, done);
  signal current_state, next_state : state_t;
  signal counter_enable : std_logic;
  signal count_uint : unsigned(31 downto 0);

begin

  next_state_logic : process(current_state, algo_data_in, algo_data_out)
  begin
    case current_state is
      when waiting_for_in =>
        if algo_data_in = '1' then
          next_state <= waiting_for_out;
        else
          next_state <= waiting_for_in;
        end if;
      when waiting_for_out =>
        if algo_data_out = '1' then
          next_state <= done;
        else
          next_state <= waiting_for_out;
        end if;
      when done =>
        next_state <= done;
      when others =>
        next_state <= waiting_for_in;
    end case;
  end process next_state_logic;

  latency_pin_logic : process(current_state)
  begin
    case current_state is
      when waiting_for_in =>
        latency_pin <= '0';
        counter_enable <= '0';
      when waiting_for_out =>
        latency_pin <= '1';
        counter_enable <= '1';
      when done =>
        latency_pin <= '0';
        counter_enable <= '0';
      when others =>
        latency_pin <= '0';
        counter_enable <= '0';
    end case;
  end process latency_pin_logic;

  state_register : process(clk, rst)
  begin
    if rst = '1' then
      current_state <= waiting_for_in;
    elsif rising_edge(clk) then
      current_state <= next_state;
    end if;
  end process state_register;

  clock_counter : process(clk, rst, counter_enable)
  begin
    if rst = '1' then
      count_uint <= (others => '0');
    elsif rising_edge(clk) then
      if counter_enable = '1' then
        count_uint <= count_uint + 1;
      end if;
    end if;
  end process clock_counter;

  latency_count <= std_logic_vector(count_uint);

end rtl;
