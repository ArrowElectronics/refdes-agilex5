--------------------------------------------------------------------------------
--
-- File: cust_PwmDataMux.vhd
-- File history:
--      1.0 : 07/30/2014 - Initial Release
--
-- Description: 
--
-- Author: Naji Naufel
--
--------------------------------------------------------------------------------

library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.math_real.all;

entity cust_PwmDataMux is
 	GENERIC(
      NUM_CHANNELS  : INTEGER := 8;
		CHANNEL_WIDTH : integer := 14;
      ADDR_WIDTH    : integer := 4);
    Port ( SysClk           : in  STD_LOGIC;
           SysReset         : in  STD_LOGIC;
           RdEn             : in  STD_LOGIC;
           ControlRegDataOut: in  STD_LOGIC_VECTOR (CHANNEL_WIDTH-1 downto 0);
           StatusRegDataOut : in  STD_LOGIC_VECTOR (NUM_CHANNELS  downto 0);
           Addr             : IN  std_logic_vector(ADDR_WIDTH-1 downto 0);
           PulseRegDataOut  : in  STD_LOGIC_VECTOR (NUM_CHANNELS*CHANNEL_WIDTH-1 downto 0);
           CounterDataReg   : in  STD_LOGIC_VECTOR (CHANNEL_WIDTH-1 downto 0);
           PeriodDataReg    : in  STD_LOGIC_VECTOR (CHANNEL_WIDTH-1 downto 0);
           DataOut          : out  STD_LOGIC_VECTOR (31 downto 0)
    );
end cust_PwmDataMux;

architecture Behavioral of cust_PwmDataMux is

----------------------------------------------------------------------------
-- Signal Declaration
   signal DataOut_int  : std_logic_vector (31 downto 0);
   
----------------------------------------------------------------------------

begin

DataOut  <= DataOut_int when (RdEn = '1') else (others => '0');

-- Data MUX
   process (ControlRegDataOut, Addr, StatusRegDataOut, PulseRegDataOut,
            CounterDataReg, PeriodDataReg)
   begin
      -- Avalon does not drive A1:A0 bits
		--for j in 0 to (NUM_CHANNELS+4) loop
			if (conv_integer(Addr) = 0) then
				DataOut_int <= (DataOut_int'left downto ControlRegDataOut'length => '0') & ControlRegDataOut;
			elsif (conv_integer(Addr) = 1) then
				DataOut_int <= (DataOut_int'left downto StatusRegDataOut'length => '0') & StatusRegDataOut;
			elsif (conv_integer(Addr) = 2) then
				DataOut_int <= (DataOut_int'left downto CounterDataReg'length => '0') & CounterDataReg;
			elsif (conv_integer(Addr) = 3) then
				DataOut_int <= (DataOut_int'left downto PeriodDataReg'length => '0') & PeriodDataReg;
			--elsif (conv_integer(Addr) > 3 AND conv_integer(Addr) <= (NUM_CHANNELS+4)) then
			elsif (conv_integer(Addr) = 4) then
				DataOut_int <= (DataOut_int'left downto CHANNEL_WIDTH => '0') & (PulseRegDataOut((conv_integer(Addr)-3)*CHANNEL_WIDTH-1 downto (conv_integer(Addr)-4)*CHANNEL_WIDTH));
				--DataOut_int <= "000000000000000000" & (PulseRegDataOut((j-3)*CHANNEL_WIDTH-1 downto (j-4)*CHANNEL_WIDTH));
			else
				DataOut_int <= (others => '0');
			end if;
		--end loop;
		
--               case (conv_integer(Addr)) is
--         -- Avalon does not drive A1:A0 bits
--         when 0 => DataOut_int <= (ControlRegDataOut);
--         when 1 => DataOut_int <= (StatusRegDataOut);
--         when 2 => DataOut_int <= (CounterDataReg);
--         when 3 => DataOut_int <= (PeriodDataReg);
--      for j in 4 to (NUM_CHANNELS+4) generate
--         when j => DataOut_int <= (PulseRegDataOut((j-3)*CHANNEL_WIDTH-1 downto (j-4)*CHANNEL_WIDTH));
--      end generate;
--         when others => DataOut_int <= (others => '0');
--               end case;
   
   end process;

end Behavioral;

