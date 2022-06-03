-- null_algo
--
-- Do-nothing top level algo for testing, with measurement of latency.
--
-- Dave Newbold, July 2013, modified by Marco Riggirello, May 2022

library IEEE;
use IEEE.STD_LOGIC_1164.all;

use work.ipbus.all;
use work.emp_data_types.all;
use work.emp_project_decl.all;

use work.emp_device_decl.all;
use work.emp_ttc_decl.all;

use work.ipbus_reg_types.all;

entity emp_payload is
  port(
    clk         : in  std_logic;        -- ipbus signals
    rst         : in  std_logic;
    ipb_in      : in  ipb_wbus;
    ipb_out     : out ipb_rbus;
    clk_payload : in  std_logic_vector(2 downto 0);
    rst_payload : in  std_logic_vector(2 downto 0);
    clk_p       : in  std_logic;        -- data clock
    rst_loc     : in  std_logic_vector(N_REGION - 1 downto 0);
    clken_loc   : in  std_logic_vector(N_REGION - 1 downto 0);
    ctrs        : in  ttc_stuff_array;
    bc0         : out std_logic;
    d           : in  ldata(4 * N_REGION - 1 downto 0);  -- data in
    q           : out ldata(4 * N_REGION - 1 downto 0);  -- data out
    gpio        : out std_logic_vector(29 downto 0);  -- IO to mezzanine connector
    gpio_en     : out std_logic_vector(29 downto 0)  -- IO to mezzanine connector (three-state enables)
    );

end emp_payload;

architecture rtl of emp_payload is

  type dr_t is array(PAYLOAD_LATENCY downto 0) of ldata(3 downto 0);
  signal counter_reg : ipb_reg_v(0 downto 0);
  signal q_int : ldata(4 * N_REGION - 1 downto 0);
--  signal ipb_to_slaves : ipb_wbus_array(0 downto 0);
--  signal ipb_from_slaves : ipb_rbus_array(0 downto 0);
  signal c_reg : ipb_reg_v(0 downto 0) := (others => (others => '0'));

begin

--  fabric : entity work.ipbus_fabric_simple
--    generic map(NSLV=>1, strobe_gap=>false, decode_base=>0, decode_bits=>1)
--    port map(ipb_in=>ibp_in, ipb_out=>ipb_out, ipb_to_slaves=>ipb_to_slaves, ipb_from_slaves=>ipb_from_slaves);
  
  dummy_latency : entity work.latency_on_pin_fsm
    port map(clk=>clk_p, reset=>c_reg(0)(0), algo_data_in=>d(0), algo_data_out=>q_int(0), y_pin=>gpio(0), latency_count=>counter_reg(0));  
  
  ipb_counter_reg : entity work.ipbus_syncreg_v
    generic map(N_CTRL=>1, N_STAT=>1)
    port map(clk=>clk, rst=>rst, ipb_in=>ipb_in, ipb_out=>ipb_out, slv_clk=>clk_p, d=>counter_reg, q=>c_reg);

  gen : for i in 1 downto 0 generate

    constant ich : integer := i * 4 + 3;
    constant icl : integer := i * 4;
    signal dr    : dr_t;

    attribute SHREG_EXTRACT       : string;
    attribute SHREG_EXTRACT of dr : signal is "no";  -- Don't absorb FFs into shreg

  begin

    dr(0) <= d(ich downto icl);

    process(clk_p)                      -- Mother of all shift registers
    begin
      if rising_edge(clk_p) then
        dr(PAYLOAD_LATENCY downto 1) <= dr(PAYLOAD_LATENCY - 1 downto 0);
      end if;
    end process;

    q_int(ich downto icl) <= dr(PAYLOAD_LATENCY);
    q(ich downto icl) <= q_int(ich downto icl); 
  end generate gen;

  bc0 <= '0';

  gpio_en(0) <= '1';
  gpio_en(29 downto 1) <= (others => '0');
  gpio(29 downto 1)    <= (others => '0');

end rtl;
