


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;


entity clkgen is
	generic
	(
		MCLK_DURATION: positive := 8;
		LRCK_DURATION:	positive := 128
	);
	port
	(
		-- interface I/O signals
		clk: in std_logic;		-- clock input
		reset: in std_logic;	-- synchronous active-high reset
		-- codec chip clock signals
		mclk: out std_logic;	-- master clock output to codec
		sclk: out std_logic;	-- serial data clock to codec
		lrck: out std_logic;	-- left/right codec channel select
		bit_cntr: out std_logic_vector(4 downto 0);
		subcycle_cntr: out std_logic_vector(1 downto 0)
	);
end clkgen;

architecture Behavioral of clkgen is
--signal lrck_int: std_logic;
signal seq_mclk: std_logic_vector(2 downto 0);
signal seq: std_logic_vector(6 downto 0);	
signal clk_int,mclk_int,lrck_int: std_logic;

begin

	--gen_clock:

	clk_int <= clk;
	mclk_int <= seq_mclk(2);

	process(clk_int,seq_mclk,seq,reset)
	begin
		if(clk_int'event and clk_int = '1') then
			if(reset = '1') then	-- synchronous reset
				seq_mclk <= (others=>'0');
				seq <= (others=>'0');
				lrck_int <= '1';
			else
				if(seq_mclk=MCLK_DURATION-1) then
					seq_mclk <= (others => '0');
--				elsif(seq_mclk = 3) then
					if(seq=LRCK_DURATION-1) then
						seq <= (others=>'0');
						lrck_int <= not(lrck_int);
					else
						seq <= seq+1;
						lrck_int <= lrck_int;
					end if;
				end if;
				seq_mclk <= seq_mclk + 1;
			end if;
		end if;
	end process;

	lrck <= lrck_int;
	mclk <= mclk_int;
	sclk <= seq(1);		-- the serial data shift clock is 1/4 of the master clock
--	bit_cntr <= bit_cntr_int;
	bit_cntr <= seq(6 downto 2);
	subcycle_cntr <= seq(1 downto 0);

end Behavioral;