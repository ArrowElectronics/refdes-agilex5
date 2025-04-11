--------------------------------------------------------------------------------
--
-- File: cust_pwm_top.vhd
-- File history:
--      1.0 : 07/30/2014 - Initial release
--
-- Description: 
--
-- This module implements an 8-channel 24-bit PWM with one PERIOD register 
-- and 8 individual PULSE WIDTH registers. It interfaces to the Avalon-MM Bus.
-- 0x00 - Control Register - [7:0]   = Invert Pin
--                           [15:8]  = Clear Pin
--                           [23:16] = Enable PWM
-- 0x04 - Status Register - [8]    = Period Reached Flag
--                          [7:0]  = Pulse Width Match Occured
-- 0x08 - Counter Register
-- 0x0C - Period Register
-- 0x10 - Pulse 0 Register
-- 0x14 - Pulse 1 Register
-- 0x18 - Pulse 2 Register
-- 0x1C - Pulse 3 Register
-- 0x20 - Pulse 4 Register
-- 0x24 - Pulse 5 Register
-- 0x28 - Pulse 6 Register
-- 0x2C - Pulse 7 Register
--
-- Author: Naji Naufel
--
--------------------------------------------------------------------------------

library IEEE;

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.math_real.all;

entity cust_pwm is
GENERIC(
   NUM_CHANNELS  : INTEGER := 12;
   CHANNEL_WIDTH : integer := 24;
   ADDR_WIDTH    : integer := 4);
port (
    -- Global signals
    SysClk                      : in  std_logic;
    SysReset                    : in  std_logic;
    -- External Module I/O
    PwmOut                      : out std_logic_vector(NUM_CHANNELS-1 downto 0);
    -- Avalon-MM Bus Inputs
    -- Avalon does not drive A1:A0 bits
    Address                     : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
    WriteEn                     : in  std_logic;
    ReadEn                      : in  std_logic;
    ChipSelect                  : in  std_logic;
    WriteData                   : in  std_logic_vector(31 downto 0);
    -- Avalon-MM Bus Outputs
    ReadData                    : out std_logic_vector(31 downto 0);
    interrupt                   : out std_logic;
    WaitRequest                 : out std_logic
);
end cust_pwm;

architecture RTL of cust_pwm is

      COMPONENT cust_PwmCSR
        GENERIC(
          NUM_CHANNELS  : INTEGER := 8;
		    CHANNEL_WIDTH : integer := 14;
          ADDR_WIDTH    : integer := 4);
      PORT(
         SysClk             : IN std_logic;
         SysReset           : IN std_logic;
         DataIn             : IN std_logic_vector(31 downto 0);
         RdEn               : IN std_logic;
         WrEn               : IN std_logic;
         Addr               : IN std_logic_vector(ADDR_WIDTH-1 downto 0);
         PulseOccured       : IN std_logic_vector(NUM_CHANNELS-1 downto 0);
         PeriodExpired      : IN std_logic;          
         CounterEn          : OUT std_logic;
         PwmEn              : OUT std_logic_vector(NUM_CHANNELS-1 downto 0);
         rawPwmEn_reg       : out STD_LOGIC_VECTOR (NUM_CHANNELS-1 downto 0);
         ClrPin             : OUT std_logic_vector(NUM_CHANNELS-1 downto 0);
         InvertPin          : OUT std_logic_vector(NUM_CHANNELS-1 downto 0);
         ControlRegDataOut  : OUT std_logic_vector(CHANNEL_WIDTH-1 downto 0);
         StatusRegDataOut   : OUT std_logic_vector(NUM_CHANNELS downto 0);
         Interrupt          : OUT std_logic
         );
      END COMPONENT;

      COMPONENT cust_PwmDataMux
        GENERIC(
          NUM_CHANNELS  : INTEGER := 8;
		    CHANNEL_WIDTH : integer := 14;
          ADDR_WIDTH    : integer := 4);
      PORT(
         SysClk             : IN std_logic;
         SysReset           : IN std_logic;
         RdEn               : IN std_logic;
         ControlRegDataOut  : IN std_logic_vector(CHANNEL_WIDTH-1 downto 0);
         StatusRegDataOut   : IN std_logic_vector(NUM_CHANNELS downto 0);
         Addr               : IN std_logic_vector(ADDR_WIDTH-1 downto 0);
         PulseRegDataOut    : IN std_logic_vector(NUM_CHANNELS*CHANNEL_WIDTH-1 downto 0);
          CounterDataReg    : IN std_logic_vector(CHANNEL_WIDTH-1 downto 0);
         PeriodDataReg      : IN std_logic_vector(CHANNEL_WIDTH-1 downto 0);          
         DataOut            : OUT std_logic_vector(31 downto 0)
         );
      END COMPONENT;

      COMPONENT cust_PwmRegisters
        GENERIC(
          NUM_CHANNELS  : INTEGER := 8;
		    CHANNEL_WIDTH : integer := 14;
          ADDR_WIDTH    : integer := 4);
      PORT(
         SysClk           : IN std_logic;
         SysReset         : IN std_logic;
         PwmEn            : IN std_logic_vector(NUM_CHANNELS-1 downto 0);
         rawPwmEn_reg     : IN STD_LOGIC_VECTOR (NUM_CHANNELS-1 downto 0);
         ClrPin           : IN std_logic_vector(NUM_CHANNELS-1 downto 0);
         InvertPin        : IN std_logic_vector(NUM_CHANNELS-1 downto 0);
         CounterEn        : in  STD_LOGIC;
         WrEn             : IN std_logic;
         Addr             : IN std_logic_vector(ADDR_WIDTH-1 downto 0);
         DataIn           : IN std_logic_vector(31 downto 0);          
         CounterValue     : OUT std_logic_vector(CHANNEL_WIDTH-1 downto 0);
         PeriodRegDataOut : OUT std_logic_vector(CHANNEL_WIDTH-1 downto 0);
         PulseRegDataOut  : OUT std_logic_vector(NUM_CHANNELS*CHANNEL_WIDTH-1 downto 0);
         PWMOUT           : OUT std_logic_vector(NUM_CHANNELS-1 downto 0);
         PulseRegMatch    : OUT std_logic_vector(NUM_CHANNELS-1 downto 0);
         ClrCounter       : OUT std_logic
         );
      END COMPONENT;


  --USER signal declarations added here, as needed for user logic
   signal CounterEn        : std_logic;
   signal PulseOccured     : std_logic_vector (NUM_CHANNELS-1 downto 0);
   signal PeriodExpired    : std_logic;
   signal PwmEn            : std_logic_vector (NUM_CHANNELS-1 downto 0);
   signal rawPwmEn_reg     : std_logic_vector (NUM_CHANNELS-1 downto 0);
   signal ClrPin           : std_logic_vector (NUM_CHANNELS-1 downto 0);
   signal InvertPin        : std_logic_vector (NUM_CHANNELS-1 downto 0);
   signal CounterValue     : std_logic_vector (CHANNEL_WIDTH-1 downto 0);
   signal PulseRegDataOut  : std_logic_vector (NUM_CHANNELS*CHANNEL_WIDTH-1 downto 0);
   signal PeriodRegDataOut : std_logic_vector (CHANNEL_WIDTH-1 downto 0);
   signal ControlRegDataOut: std_logic_vector (CHANNEL_WIDTH-1 downto 0);
   signal StatusRegDataOut : std_logic_vector (NUM_CHANNELS downto 0);

   --signal interrupt        : std_logic;
   signal RdEn, WrEn       : std_logic;
   signal pready_int       : std_logic;
   signal DataIn           : std_logic_vector (31 downto 0);
   signal DataOut          : std_logic_vector (31 downto 0);
   signal Addr             : std_logic_vector (ADDR_WIDTH-1 downto 0);

   attribute keep : boolean;
   attribute keep of WrEn : signal is true;
   attribute keep of Addr : signal is true;

begin


	Inst_PwmCSR: cust_PwmCSR 
     GENERIC MAP(
        NUM_CHANNELS  => NUM_CHANNELS,
		  CHANNEL_WIDTH => CHANNEL_WIDTH,
		  ADDR_WIDTH    => ADDR_WIDTH)
     PORT MAP(
		SysClk            => SysClk,
		SysReset          => SysReset,
		DataIn            => DataIn,
		RdEn              => RdEn,
		WrEn              => WrEn,
		Addr              => Addr,
		PulseOccured      => PulseOccured,
		PeriodExpired     => PeriodExpired,
		CounterEn         => CounterEn,
		PwmEn             => PwmEn,
		rawPwmEn_reg      => rawPwmEn_reg,
		ClrPin            => ClrPin,
		InvertPin         => InvertPin,
		ControlRegDataOut => ControlRegDataOut,
		StatusRegDataOut  => StatusRegDataOut,
		Interrupt         => Interrupt
	);

	Inst_PwmDataMux: cust_PwmDataMux 
    GENERIC MAP(
        NUM_CHANNELS  => NUM_CHANNELS,
		  CHANNEL_WIDTH => CHANNEL_WIDTH,
		  ADDR_WIDTH    => ADDR_WIDTH)
    PORT MAP(
		SysClk            => SysClk,
		SysReset          => SysReset,
		RdEn              => RdEn,
		ControlRegDataOut => ControlRegDataOut,
		StatusRegDataOut  => StatusRegDataOut,
		Addr              => Addr,
		PulseRegDataOut   => PulseRegDataOut,
		CounterDataReg    => CounterValue,
		PeriodDataReg     => PeriodRegDataOut,
		DataOut           => DataOut
	);

	Inst_PwmRegisters: cust_PwmRegisters 
     GENERIC MAP(
        NUM_CHANNELS  => NUM_CHANNELS,
		  CHANNEL_WIDTH => CHANNEL_WIDTH,
		  ADDR_WIDTH    => ADDR_WIDTH)
     PORT MAP(
		SysClk            => SysClk,
		SysReset          => SysReset,
		PwmEn             => PwmEn,
		rawPwmEn_reg      => rawPwmEn_reg,
		ClrPin            => ClrPin,
		InvertPin         => InvertPin,
      CounterEn         => CounterEn,
		WrEn              => WrEn,
		Addr              => Addr,
		DataIn            => DataIn,
		CounterValue      => CounterValue,
		PeriodRegDataOut  => PeriodRegDataOut,
		PulseRegDataOut   => PulseRegDataOut,
		PWMOUT            => PwmOut,
		PulseRegMatch     => PulseOccured,
		ClrCounter        => PeriodExpired
	);

  --IP2Bus_IntrEvent(0)<= interrupt;
  --SysReset           <= SysReset;
  ReadData           <= DataOut;
  WaitRequest        <= not pready_int;
  Addr               <= Address;
  WrEn               <= ChipSelect and WriteEn;
  RdEn               <= ChipSelect and ReadEn;
  DataIn             <= WriteData;

-- ************************************************************************
-- 1-cycle PREADY turnaround time
-- ************************************************************************
   process (SysClk, SysReset)
   begin
      if (rising_edge (SysClk)) then
         if (SysReset = '1') then
            pready_int      <= '0';
         elsif (ChipSelect='1' AND pready_int='0') then
            pready_int      <= '1';
         else
            pready_int      <= '0';
         end if;
      end if;
   end process;


end RTL;
