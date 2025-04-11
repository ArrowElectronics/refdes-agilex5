--------------------------------------------------------------------------------
--
-- File: cust_PwmRegisters.vhd
-- File history:
--      1.0 : 07/30/2014 - Inital Release
--
-- Description: 
--
-- This module implements the 24-bit counter, period, and pulse width registers.
--
-- Author: Naji Naufel
--
--------------------------------------------------------------------------------

library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.math_real.all;
use IEEE.std_logic_misc.ALL;

entity cust_PwmRegisters is
 	GENERIC(
      NUM_CHANNELS  : INTEGER := 8;
		CHANNEL_WIDTH : integer := 14;
      ADDR_WIDTH    : integer := 4);
    Port ( SysClk           : in  STD_LOGIC;
           SysReset         : in  STD_LOGIC;
           PwmEn            : in  STD_LOGIC_VECTOR (NUM_CHANNELS-1 downto 0);
           rawPwmEn_reg     : in  STD_LOGIC_VECTOR (NUM_CHANNELS-1 downto 0);
           ClrPin           : in  STD_LOGIC_VECTOR (NUM_CHANNELS-1 downto 0);
           InvertPin        : in  STD_LOGIC_VECTOR (NUM_CHANNELS-1 downto 0);
           CounterEn        : in  STD_LOGIC;
           WrEn             : in  STD_LOGIC;
           Addr             : IN  std_logic_vector(ADDR_WIDTH-1 downto 0);
           DataIn           : in  STD_LOGIC_VECTOR (31 downto 0);
           CounterValue     : out  STD_LOGIC_VECTOR (CHANNEL_WIDTH-1 downto 0);
           PeriodRegDataOut : out  STD_LOGIC_VECTOR (CHANNEL_WIDTH-1 downto 0);
           PulseRegDataOut : out  STD_LOGIC_VECTOR (NUM_CHANNELS*CHANNEL_WIDTH-1 downto 0);
           PWMOUT           : out  STD_LOGIC_VECTOR (NUM_CHANNELS-1 downto 0);
           PulseRegMatch    : out  STD_LOGIC_VECTOR (NUM_CHANNELS-1 downto 0);
           ClrCounter       : out  STD_LOGIC);
end cust_PwmRegisters;

architecture Behavioral of cust_PwmRegisters is

----------------------------------------------------------------------------
-- Signal Declaration

   signal  ClrCounter_int       : std_logic;
	signal  CounterEn_p          : std_logic;
	signal  dCounterEn           : std_logic;
   signal  PulseRegMatch_int    : std_logic_vector (NUM_CHANNELS-1 downto 0);
   signal  PwmOut_int           : std_logic_vector (NUM_CHANNELS-1 downto 0);
   signal  CounterValue_int     : STD_LOGIC_VECTOR (CHANNEL_WIDTH-1 downto 0);
   signal  PeriodRegDataOut_int : STD_LOGIC_VECTOR (CHANNEL_WIDTH-1 downto 0);
   signal  PulseRegDataOut_int : STD_LOGIC_VECTOR (NUM_CHANNELS*CHANNEL_WIDTH-1 downto 0);

----------------------------------------------------------------------------
begin

   ClrCounter       <= ClrCounter_int;
   PulseRegMatch    <= PulseRegMatch_int;
   PeriodRegDataOut <= PeriodRegDataOut_int;
   PulseRegDataOut <= PulseRegDataOut_int;
   
   ClrCounter_int <= '1' when ((PeriodRegDataOut_int = CounterValue_int) AND or_reduce(PwmEn) = '1') else '0';
	CounterEn_p    <= '1' when (CounterEn = '1' AND dCounterEn = '0') else '0';

	process (PulseRegDataOut_int, CounterValue_int, PwmEn, PwmOut_int, InvertPin)
	begin
		for j in 0 to (NUM_CHANNELS-1) loop
			if ((PulseRegDataOut_int((j+1)*CHANNEL_WIDTH-1 downto j*CHANNEL_WIDTH) = CounterValue_int) AND (PwmEn(j) = '1') AND
					PulseRegDataOut_int((j+1)*CHANNEL_WIDTH-1 downto j*CHANNEL_WIDTH) /= 0) then
				PulseRegMatch_int(j) <= '1';
			else
				PulseRegMatch_int(j) <= '0';
			end if;
			PWMOUT(j) <= PwmOut_int(j) XOR InvertPin(j);
		end loop;
	end process;

   CounterValue <= CounterValue_int;
   
-----------------------------------------------------------------------------------------------

-- Register the CounterEn signal for generating a pulse
process (SysClk, SysReset)
  begin
     if (SysReset = '1') then
		 dCounterEn	<= '0';
     elsif (rising_edge (SysClk)) then
		 dCounterEn	<= CounterEn;
     end if;
  end process;

	  
process (SysClk, SysReset)
  begin
     if (SysReset = '1') then
         PeriodRegDataOut_int  <= (others => '0');
     elsif (rising_edge (SysClk)) then
        if (WrEn = '1' AND Addr = 3) then
           -- Avalon does not drive A1:A0 bits
           PeriodRegDataOut_int  <= DataIn(CHANNEL_WIDTH-1 downto 0);
        end if;
     end if;
  end process;

process (SysClk, SysReset)
  begin
     if (SysReset = '1') then
         PulseRegDataOut_int   <= (others => '0');
     elsif (rising_edge (SysClk)) then
        if (WrEn = '1') then
          -- Avalon does not drive A1:A0 bits
				  if (Addr > 3) then
             --if (Addr = conv_std_logic_vector(k,integer(ceil(log2(real(NUM_CHANNELS+4)))))) then
               PulseRegDataOut_int((conv_integer(Addr)-3)*CHANNEL_WIDTH-1 downto (conv_integer(Addr)-4)*CHANNEL_WIDTH)  <= DataIn(CHANNEL_WIDTH-1 downto 0);
           end if;
        end if;
     end if;
  end process;


-----------------------------------------------------------------------
-- Free-Running Counter
-----------------------------------------------------------------------
   process (SysClk, SysReset)
   begin
      if (SysReset = '1') then
         CounterValue_int  <= (others => '0');
      elsif (rising_edge (SysClk)) then
         if (ClrCounter_int = '1' AND (or_reduce(rawPwmEn_reg) = '1')) then
            CounterValue_int  <= conv_std_logic_vector(1,CHANNEL_WIDTH);
         elsif (ClrCounter_int = '1' AND (or_reduce(rawPwmEn_reg) = '0')) then
            CounterValue_int  <= (others => '0');
         elsif (CounterEn = '1') then
            CounterValue_int  <= CounterValue_int + 1;
         else
            CounterValue_int  <= (others => '0');
         end if;
      end if;
   end process;

-------------------------------------------------------------------------
-- PWM Output Pins
-------------------------------------------------------------------------
   process (SysClk, SysReset)
   begin
      if (SysReset = '1') then
		  for m in 0 to (NUM_CHANNELS-1) loop
          PwmOut_int(m)  <= '0';
		  end loop;
      elsif (rising_edge (SysClk)) then
        for m in 0 to (NUM_CHANNELS-1) loop
			 if (CounterEn_p = '1' AND PwmEn(m) = '1' AND rawPwmEn_reg(m) = '1' AND 
					PulseRegDataOut_int((m+1)*CHANNEL_WIDTH-1 downto (m)*CHANNEL_WIDTH)  /= (CounterValue_int'length => '0')) then
            PwmOut_int(m)  <= '1';
          elsif (PulseRegMatch_int(m) = '1' OR ClrPin(m) = '1') then
            PwmOut_int(m)  <= '0';
          elsif (ClrCounter_int = '1' AND rawPwmEn_reg(m) = '1' AND PulseRegDataOut_int((m+1)*CHANNEL_WIDTH-1 downto (m)*CHANNEL_WIDTH)  /= (CounterValue_int'length => '0')) then
            PwmOut_int(m)  <= '1';
          end if;
        end loop;
      end if;
   end process;


end Behavioral;
