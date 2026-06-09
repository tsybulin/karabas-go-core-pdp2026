
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

entity ps2 is
   port(
      base_addr : in std_logic_vector(17 downto 0);
      ivec : in std_logic_vector(8 downto 0);

      br : out std_logic;
      bg : in std_logic;
      int_vector : out std_logic_vector(8 downto 0);

      bus_addr_match : out std_logic;
      bus_addr : in std_logic_vector(17 downto 0);
      bus_dati : out std_logic_vector(15 downto 0);
      bus_dato : in std_logic_vector(15 downto 0);
      bus_control_dati : in std_logic;
      bus_control_dato : in std_logic;
      bus_control_datob : in std_logic;

      ps2k_upd : in std_logic;
      ps2k_dat : in std_logic_vector(7 downto 0);

      reset : in std_logic;
      clk : in std_logic;
		clk50 : in std_logic
   );
end ps2;

architecture implementation of ps2 is


-- regular bus interface

signal base_addr_match : std_logic;
signal interrupt_trigger : std_logic := '0';
type interrupt_state_type is (
   i_idle,
   i_req,
   i_wait
);
signal interrupt_state : interrupt_state_type := i_idle;


-- local data

signal ps2_scancode : std_logic_vector(7 downto 0);
signal ps2_rxdone : std_logic;
signal ps2_rxie : std_logic;

	signal F_wr    : std_logic := '0' ;
	signal F_rd    : std_logic := '0' ;
	signal F_full  : std_logic ;
	signal F_empty : std_logic ;
	signal F_dati  : std_logic_vector(7 downto 0) := "00000000" ;
	signal F_dato  : std_logic_vector(7 downto 0) ;
	
begin

   base_addr_match <= '1' when base_addr(17 downto 2) = bus_addr(17 downto 2) else '0';
   bus_addr_match <= base_addr_match;

   process(clk, reset) begin
      if clk = '1' and clk'event then
			F_rd <= '0' ;
			
         if reset = '1' then

            ps2_rxdone <= '0';
            ps2_rxie <= '0';
            ps2_scancode <= (others => '0');

            br <= '0';
            interrupt_trigger <= '0';
            interrupt_state <= i_idle;

         else

            case interrupt_state is

               when i_idle =>

                  br <= '0';
                  if ps2_rxie = '1' and ps2_rxdone = '1' then
                     if interrupt_trigger = '0' then
                        interrupt_state <= i_req;
                        br <= '1';
                        interrupt_trigger <= '1';
                     end if;
                  else
                     interrupt_trigger <= '0';
                  end if;

               when i_req =>
                  if bg = '1' then
                     int_vector <= ivec;
                     br <= '0';
                     interrupt_state <= i_wait;
                  end if;

               when i_wait =>
                  if bg = '0' then
                     interrupt_state <= i_idle;
                  end if;

               when others =>
                  interrupt_state <= i_idle;

            end case;

            if base_addr_match = '1' and bus_control_dati = '1' then
               case bus_addr(2 downto 1) is
                  when "00" =>
                     bus_dati <= "00000000" & ps2_rxdone & ps2_rxie & "000000";
                  when "01" =>
                     ps2_rxdone <= '0';
                     bus_dati <= "00000000" & ps2_scancode;
                  when others =>
                     bus_dati <= "0000000000000000";
               end case;

            end if;

            if base_addr_match = '1' and bus_control_dato = '1' then
               if bus_control_datob = '0' or (bus_control_datob = '1' and bus_addr(0) = '0') then
                  case bus_addr(2 downto 1) is
                     when "00" =>
                        ps2_rxie <= bus_dato(6);
                     when others =>
                        null;
                  end case;
               end if;
            end if;
				
				if F_rd = '1' then
					ps2_scancode <= ps2k_dat ;
					ps2_rxdone <= '1';
				end if ;
				
				if F_empty = '0' and ps2_rxdone = '0' then
					F_rd <= '1' ;
				end if ;

			end if ;
		end if;
   end process;
	
	KFIFO : entity work.afifo
	generic map (
		DSIZE => 8,
		ASIZE => 4
	) port map (
		i_wclk => clk50,
		i_wrst_n => '1',
		i_wr => F_wr,
		i_wdata => F_dati,
		
		i_rclk => clk,
		i_rrst_n => '1',
		i_rd => F_rd,
		o_rdata => F_dato,
		
		o_wfull => F_full,
		o_rempty => F_empty
	) ;

	process (clk50) begin
		if clk50 = '1' and clk50'event then
			F_wr <= '0' ;
			
			if ps2k_upd = '1' then
				if F_full = '0' then
					F_dati <= ps2k_dat ;
					F_wr <= '1' ;
				end if ;
			end if ;
		end if ;
	end process ;

end implementation;

