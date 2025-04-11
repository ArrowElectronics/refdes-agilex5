--------------------------------------------------------------------------------
--
-- File: cust_PwmCSR.vhd
-- File history:
--      1.0 : 07/30/2014 - Initial release
--
-- Description: 
--
-- This module implements the Control and Status register
-- Control Register - [7:0]   = Invert Pin
--                    [15:8]  = Clear Pin
--                    [23:16] = Enable PWM
-- Status Register  - [8]     = Period Reached Flag
--                    [7:0]   = Pulse Width Match Occured
--
--------------------------------------------------------------------------------

library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.math_real.all;
use IEEE.std_logic_misc.ALL;

entity cust_PwmCSR is
 	GENERIC(
      NUM_CHANNELS  : INTEGER := 8;
		CHANNEL_WIDTH : integer := 14;
      ADDR_WIDTH    : integer := 4);
    Port ( SysClk           : in  STD_LOGIC;
           SysReset         : in  STD_LOGIC;
           DataIn           : in  STD_LOGIC_VECTOR (31 downto 0);
           RdEn             : in  STD_LOGIC;
           WrEn             : in  STD_LOGIC;
           Addr             : IN  std_logic_vector(ADDR_WIDTH-1 downto 0);
           PulseOccured     : in  STD_LOGIC_VECTOR (NUM_CHANNELS-1 downto 0);
           PeriodExpired    : in  STD_LOGIC;
           CounterEn        : out  STD_LOGIC;
           PwmEn            : out  STD_LOGIC_VECTOR (NUM_CHANNELS-1 downto 0);
           rawPwmEn_reg     : out  STD_LOGIC_VECTOR (NUM_CHANNELS-1 downto 0);
           ClrPin           : out  STD_LOGIC_VECTOR (NUM_CHANNELS-1 downto 0);
           InvertPin        : out  STD_LOGIC_VECTOR (NUM_CHANNELS-1 downto 0);
           ControlRegDataOut : out  STD_LOGIC_VECTOR (CHANNEL_WIDTH-1 downto 0);
           StatusRegDataOut : out  STD_LOGIC_VECTOR (NUM_CHANNELS downto 0);
           Interrupt        : out  STD_LOGIC
);
end cust_PwmCSR;

architecture Behavioral of cust_PwmCSR is

---------------------------------------------------------------------------------
-- Signal Declaration
   signal StatusRegDataOut_int   : std_logic_vector (NUM_CHANNELS downto 0);
   signal PwmEn_int, PwmEn_reg   : std_logic_vector (NUM_CHANNELS-1 downto 0);
   --signal rawPwmEn_reg           : std_logic_vector (NUM_CHANNELS-1 downto 0);
   signal ClrPin_int             : std_logic_vector (NUM_CHANNELS-1 downto 0);
   signal InvertPin_int          : std_logic_vector (NUM_CHANNELS-1 downto 0);

---------------------------------------------------------------------------------

begin

   CounterEn   <= or_reduce(PwmEn_int);

   ControlRegDataOut <= (ControlRegDataOut'left downto PwmEn_int'length => '0') & PwmEn_int;

   StatusRegDataOut  <= StatusRegDataOut_int;
   
   Interrupt         <= or_reduce(StatusRegDataOut_int);

   InvertPin         <= InvertPin_int;
   PwmEn             <= PwmEn_int;
   rawPwmEn_reg      <= PwmEn_reg;
   ClrPin            <= ClrPin_int;

-- Control Register
   process (SysClk)
   begin
      if (rising_edge (SysClk)) then
         if (SysReset = '1') then
            PwmEn_reg      <= (others => '0');
            InvertPin_int  <= (others => '0');
         elsif (WrEn='1' AND Addr=0) then
            PwmEn_reg      <= DataIn(NUM_CHANNELS-1 downto 0);
            InvertPin_int  <= DataIn(2*NUM_CHANNELS-1 downto NUM_CHANNELS);
         end if;
      end if;
   end process;

   -- ClrPin is a self-clearing bit
   process (SysClk)
   begin
      if (rising_edge (SysClk)) then
         if (SysReset = '1') then
             ClrPin_int     <= (others => '0');
         elsif (WrEn='1' AND Addr=0) then
             ClrPin_int     <= (others => '0');
	 else
             ClrPin_int     <= (others => '0');
         end if;
      end if;
   end process;


-- Status Register
   process (SysClk, SysReset)
   begin
      if (rising_edge (SysClk)) then
         if (SysReset = '1') then
            StatusRegDataOut_int <= (others => '0');
         -- Avalon does not drive A1:A0 bits
         elsif (WrEn='1' AND Addr=1) then
           for j in 0 to NUM_CHANNELS-1 loop
             if (DataIn(j) = '1') then
               StatusRegDataOut_int(j) <= '0';
             end if;
           end loop;
         else
           for k in 0 to (NUM_CHANNELS-1) loop
             if (PulseOccured(k) = '1') then
               StatusRegDataOut_int(k) <= '1';
             end if;
           end loop;
             if (PeriodExpired = '1') then
               StatusRegDataOut_int(NUM_CHANNELS) <= '1';
             end if;         
         end if;
      end if;
   end process;
  
 -- Only allow disabling PWM channels upon a period expiration
   process (SysClk, SysReset)
   begin
      if (rising_edge (SysClk)) then
         if (SysReset = '1') then
            PwmEn_int <= (others => '0');
         elsif (PeriodExpired = '1' OR or_reduce(PwmEn_int) = '0') then
            PwmEn_int <= PwmEn_reg;
         end if;
      end if;
   end process;
 
end Behavioral;
