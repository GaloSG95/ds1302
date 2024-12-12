-- Project      : 
-- Design       : 
-- Verification : 
-- Reviewers    : 
-- Module       : ds1302_ctrl_tb.vhdl
-- Parent       : none
-- Children     : ds1302_ctrl.vhdl
-- Description  :

library ieee;
use ieee.std_logic_1164.all;

entity ds1302_ctrl_tb is
end entity ds1302_ctrl_tb;

architecture arch of ds1302_ctrl_tb is

  constant CLK_FREQ : real := 100.0e6;
  constant PERIOD   : time := 1.0/CLK_FREQ*1.0e9 ns;
  constant TVECTOR  : std_logic_vector(7 downto 0):= "10011001";

  component top is
    Port ( 
    clk     : IN    STD_LOGIC;
    rst     : IN    STD_LOGIC;
    sclk    : out   std_logic;
    ce      : out   std_logic;
    io      : inout std_logic;
    start   : in    std_logic;
    rw      : in    std_logic;
    addr    : in    std_logic_vector(4 downto 0);
    din     : in    std_logic_vector(7 downto 0);
    dout    : out   std_logic_vector(7 downto 0);
    dvalid  : out   std_logic;
    busy    : out   std_logic);
  end component;

  signal clk      : std_logic := '0';
  signal rst      : std_logic;
  signal sclk     : std_logic;
  signal ce       : std_logic;
  signal io_buff  : std_logic;
  signal start    : std_logic;
  signal rw       : std_logic;
  signal addr     : std_logic_vector(4 downto 0);
  signal din      : std_logic_vector(7 downto 0);
  signal dout     : std_logic_vector(7 downto 0);
  signal dvalid   : std_logic;
  signal busy     : std_logic;
  signal rmessage : std_logic_vector(15 downto 0);
begin

  uut : top
    PORT MAP( clk     => clk,
              rst     => rst,
              sclk    => sclk,
              ce      => ce,
              io      => io_buff,
              start   => start,
              rw      => rw,
              addr    => addr,
              din     => din,
              dout    => dout,
              dvalid  => dvalid,
              busy    => busy);

  clk <= not clk after PERIOD/2.0;

  reset_process : process
  begin
    rst <= '1';
    wait for PERIOD;
    rst <= '0';
    wait;
  end process;

  -- Timing checks, see RS1302 data sheet.
  t_HI_proc : process(sclk)
  begin
    if falling_edge(sclk) then
      assert sclk'delayed'stable(25 ns) report "Clock High Time < 25 ns" severity warning;
    end if;
  end process t_HI_proc;

  t_LO_proc : process(sclk)
  begin
    if rising_edge(sclk) then
      assert sclk'delayed'stable(25 ns) report "Clock Low Time < 25 ns" severity warning;
    end if;
  end process t_LO_proc;

  t_SU_proc : process (sclk)
  begin
    if rising_edge(sclk) then
      assert io_buff'stable(70 ns) report "Data Input Setup Time < 70 ns" severity warning;
    end if;
  end process t_SU_proc;

  t_HD_proc : process
  begin
    wait until rising_edge(sclk);
    wait for 50 ns;
    assert io_buff'stable(50 ns) report "Data Input Hold Time < 50 ns" severity warning;
  end process t_HD_proc;

  -- Receive data and compare to transmitted data
  data_verification_proc : process
    --variable rmessage : std_logic_vector(15 downto 0):=(others => '0');
    variable command  : std_logic_vector(7 downto 0);
  begin
    io_buff <= 'Z';
    rw      <= '0';
    addr    <= "01110";
    din     <= "10011001";
    command := rw & addr & '0' & '1';
    
    wait until falling_edge(rst);
    -- begin write
    for idx in 0 to 1 loop
      
      start <= '1';
      wait until rising_edge(busy);
      start <= '0';
      assert ce = '1' report "CE not set HIGH" severity warning;

      for idx in 15 downto 0 loop
        wait until rising_edge(sclk);
        rmessage <= io_buff  & rmessage(15 downto 1);
      end loop;
 
      wait until falling_edge(busy);
      -- check data
      assert rmessage(15 downto 8) = din report "incorrect data" severity warning;
      -- wait to start second
      wait for 100 ns;
      io_buff <= 'Z';
    end loop;
    -- Force testbench to stop when the transmission is finished.
    report "Testbench finished!" severity failure;
  end process data_verification_proc;

end architecture arch;