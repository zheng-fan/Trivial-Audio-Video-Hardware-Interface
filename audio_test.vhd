--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   14:53:21 05/19/2017
-- Design Name:   
-- Module Name:   D:/FPGA/my_vga2/audio_test.vhd
-- Project Name:  my_vga2
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: top
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY audio_test IS
END audio_test;
 
ARCHITECTURE behavior OF audio_test IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT top
    PORT(
         clk : IN  std_logic;
         Rst : IN  std_logic;
         PClk_out : OUT  std_logic;
         Vsync : OUT  std_logic;
         Hsync : OUT  std_logic;
         dvd_psave : OUT  std_logic;
         vga_blank : OUT  std_logic;
         vga_csync : OUT  std_logic;
         Vga_R : OUT  std_logic_vector(7 downto 0);
         Vga_G : OUT  std_logic_vector(7 downto 0);
         Vga_B : OUT  std_logic_vector(7 downto 0);
         PWADDA_in : IN  std_logic;
         sdin : IN  std_logic;
         sdout : OUT  std_logic;
         mclk : OUT  std_logic;
         lrck : OUT  std_logic;
         sclk : OUT  std_logic;
         PWADDA_out : OUT  std_logic;
         start : IN  std_logic;
			led : out std_logic_vector(5 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal Rst : std_logic := '0';
   signal PWADDA_in : std_logic := '0';
   signal sdin : std_logic := '0';
   signal start : std_logic := '0';

 	--Outputs
   signal PClk_out : std_logic;
   signal Vsync : std_logic;
   signal Hsync : std_logic;
   signal dvd_psave : std_logic;
   signal vga_blank : std_logic;
   signal vga_csync : std_logic;
   signal Vga_R : std_logic_vector(7 downto 0);
   signal Vga_G : std_logic_vector(7 downto 0);
   signal Vga_B : std_logic_vector(7 downto 0);
   signal sdout : std_logic;
   signal mclk : std_logic;
   signal lrck : std_logic;
   signal sclk : std_logic;
   signal PWADDA_out : std_logic;

   -- Clock period definitions
   constant clk_period : time := 10 ns;
   constant mclk_period : time := 10 ns;
   constant sclk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: top PORT MAP (
          clk => clk,
          Rst => Rst,
          PClk_out => PClk_out,
          Vsync => Vsync,
          Hsync => Hsync,
          dvd_psave => dvd_psave,
          vga_blank => vga_blank,
          vga_csync => vga_csync,
          Vga_R => Vga_R,
          Vga_G => Vga_G,
          Vga_B => Vga_B,
          PWADDA_in => PWADDA_in,
          sdin => sdin,
          sdout => sdout,
          mclk => mclk,
          lrck => lrck,
          sclk => sclk,
          PWADDA_out => PWADDA_out,
          start => start
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 
--   mclk_process :process
--   begin
--		mclk <= '0';
--		wait for mclk_period/2;
--		mclk <= '1';
--		wait for mclk_period/2;
--   end process;
 
--   sclk_process :process
--   begin
--		sclk <= '0';
--		wait for sclk_period/2;
--		sclk <= '1';
--		wait for sclk_period/2;
--   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
		Rst<='1';
      wait for 1000 ns;
		Rst<='0';
      wait for 1000 ns;
		start<='1';
      wait for 1000 ns;
		start<='0';
		

--      wait for clk_period*1000;

      -- insert stimulus here 

      wait;
   end process;

END;
