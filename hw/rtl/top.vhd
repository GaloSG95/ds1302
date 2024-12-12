library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity top is
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
end top;

architecture arch of top is

component ds1302_ctrl IS
    PORT (
        clk     : IN    STD_LOGIC;
        rst     : IN    STD_LOGIC;
        sclk    : out   std_logic;
        ce      : out   std_logic;
        i_buff  : out   std_logic;
        o_buff  : in    std_logic;
        t_buff  : out   std_logic;
        start   : in    std_logic;
        rw      : in    std_logic;
        addr    : in    std_logic_vector(4 downto 0);
        din     : in    std_logic_vector(7 downto 0);
        dout    : out   std_logic_vector(7 downto 0);
        dvalid  : out   std_logic;
        busy    : out   std_logic);
END component;

signal i_buff : std_logic;
signal o_buff : std_logic;
signal t_buff : std_logic;
begin

   IOBUF_inst : IOBUF
   generic map (
      DRIVE => 12,
      IOSTANDARD => "DEFAULT",
      SLEW => "SLOW")
   port map (
      O => o_buff,
      IO => io,
      I => i_buff,
      T => t_buff
   );

    ds1302_ctrl_inst : ds1302_ctrl
    PORT MAP(
                clk     => clk,
                rst     => rst,
                sclk    => sclk,
                ce      => ce,
                i_buff  => i_buff,
                o_buff  => o_buff,
                t_buff  => t_buff,
                start   => start,
                rw      => rw,
                addr    => addr,
                din     => din,
                dout    => dout,
                dvalid  => dvalid,
                busy    => busy);
end arch;
