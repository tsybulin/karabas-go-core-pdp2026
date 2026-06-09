
--
-- Copyright (c) 2008-2023 Sytse van Slooten
--
-- Permission is hereby granted to any person obtaining a copy of these VHDL source files and
-- other language source files and associated documentation files ("the materials") to use
-- these materials solely for personal, non-commercial purposes.
-- You are also granted permission to make changes to the materials, on the condition that this
-- copyright notice is retained unchanged.
--
-- The materials are distributed in the hope that they will be useful, but WITHOUT ANY WARRANTY;
-- without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
--

-- $Revision$

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use work.pdp2011.all;

entity vt100_top is
   port(
      vgao : out std_logic ;
      vgah : out std_logic;
      vgav : out std_logic;
		vgaclk : out std_logic;
		vga_blank : out std_logic;

      ps2k_upd : in std_logic;
      ps2k_dat : in std_logic_vector(7 downto 0);
		
		audio : buffer std_logic := '1';

      clkin : in std_logic;
		c0		: in std_logic;

      tx : out std_logic;
      rx : in std_logic;
      resetbtn : in std_logic
   );
end vt100_top;

architecture implementation of vt100_top is

signal reset: std_logic;
signal vga_hsync : std_logic;
signal vga_vsync : std_logic;
signal vga_fb : std_logic;
signal vga_ht : std_logic;

signal vtbell : std_logic ;
signal bell_counter : integer range 0 to 32767 := 0;
signal bell_duration : integer range 0 to 950 := 940;

component vt10x is
   port(
      vga_hsync : out std_logic;                                     -- horizontal sync
      vga_vsync : out std_logic;                                     -- vertical sync
      vga_fb : out std_logic;                                        -- output - full
      vga_ht : out std_logic;                                        -- output - half
		vgaclk : out std_logic;
		vga_blank : out std_logic;

-- serial port
      tx : out std_logic;                                            -- transmit
      rx : in std_logic;                                             -- receive
      rts : out std_logic;                                           -- request to send
      cts : in std_logic := '0';                                     -- clear to send
      bps : in integer range 1200 to 230400 := 9600;                 -- bps rate - don't set to more than 38400
      force7bit : in integer range 0 to 1 := 0;                      -- zero out high order bit on transmission and reception
      rtscts : in integer range 0 to 1 := 0;                         -- conditional compilation switch for rts and cts signals; also implies to include core that implements a silo buffer

-- ps2 keyboard
      ps2k_upd : in std_logic;
      ps2k_dat : in std_logic_vector(7 downto 0);

-- debug & blinkenlights
      ifetch : out std_logic;                                        -- ifetch : the cpu is running an instruction fetch cycle
      iwait : out std_logic;                                         -- iwait : the cpu is in wait state
      teste : in std_logic := '0';                                   -- teste : display 24*80 capital E without changing the display buffer
      testf : in std_logic := '0';                                   -- testf : display 24*80 all pixels on
      vtbell : out std_logic;                                        -- BEL
      vga_bl : out std_logic_vector(9 downto 0);                     -- blinkenlight vector

-- vt type code : 100 or 105
      vttype : in integer range 100 to 105 := 100;                   -- vt100 or vt105
      vga_cursor_block : in std_logic := '1';                        -- cursor is block ('1') or underline ('0')
      vga_cursor_blink : in std_logic := '0';                        -- cursor blinks ('1') or not ('0')
      have_act_seconds : in integer range 0 to 7200 := 900;          -- auto screen off time, in seconds; 0 means disabled
      have_act : in integer range 1 to 2 := 2;                       -- auto screen off counter reset by keyboard and serial port activity (1) or keyboard only (2)

-- clock & reset
      cpuclk : in std_logic;                                         -- cpuclk : should be around 10MHz, give or take a few
      clk50mhz : in std_logic;                                       -- clk50mhz : used for vga signal timing
      reset : in std_logic                                           -- reset
   );
end component;

begin
   vt0: vt10x port map(
      vga_hsync => vga_hsync,
      vga_vsync => vga_vsync,
      vga_fb => vga_fb,
      vga_ht => vga_ht,
		vgaclk => vgaclk,
		vga_blank => vga_blank,

      rx => rx,
      tx => tx,
		bps => 115200,

      ps2k_upd => ps2k_upd,
      ps2k_dat => ps2k_dat,
      teste => '0',
      testf => '0',
      vga_cursor_block => '0',
      vga_cursor_blink => '1',

      vttype => 100,
		vtbell => vtbell,

      cpuclk => c0,
      clk50mhz => clkin,
      reset => reset
   );

   reset <= (not resetbtn);

	vgao <= '1' when vga_fb = '1' else '0' ;
   vgav <= vga_vsync;
   vgah <= vga_hsync;
	
	process(c0) begin
		if c0 = '1' and c0'event then
			if vtbell = '0' then
				bell_duration <= 940 ;
			else
				if bell_duration > 900 then
					bell_duration <= 0 ;
				end if ;
			end if ;

			if bell_duration < 900 then
				bell_counter <= bell_counter + 1 ;
				if bell_counter > 1785 then
					bell_counter <= 0 ;
					audio <= not audio ;
					bell_duration <= bell_duration + 1 ;
				end if ;
			end if ;
		end if ;
	end process ;

end implementation;

