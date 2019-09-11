----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    21:29:12 04/23/2011 
-- Design Name: 
-- Module Name:    audiotop - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity audiotop is
	port (
		clk	:	in std_logic;
		reset	:	in std_logic;
		PWADDA_in : in std_logic;
		sdin	:	in std_logic;
		sdout	:	out std_logic;
		mclk	:	out std_logic;
		lrck	:	out std_logic;
		sclk	:	out std_logic;
	   PWADDA_out : out std_logic;
	   start : in std_logic;
	   bitsdata : out std_logic_vector(15 downto 0);
	   led : out std_logic_vector(5 downto 0)
	);
end audiotop;


architecture Behavioral of audiotop is
	
	component clkgen
		port (
		clk	:	in std_logic;	--100MHz
		reset	:	in std_logic;
		sclk	:	out std_logic;
		mclk	:	out std_logic;
		lrck	:	out std_logic;
		bit_cntr: out std_logic_vector(4 downto 0);
		subcycle_cntr: out std_logic_vector(1 downto 0)
		
		);
	end component;
	
	component rom1
	port (
		clka: IN std_logic;
		addra: IN std_logic_VECTOR(10 downto 0);
		douta: OUT std_logic_VECTOR(15 downto 0));
	end component;
	
	component rom2
	port (
		clka: IN std_logic;
		addra: IN std_logic_VECTOR(16 downto 0);
		douta: OUT std_logic_VECTOR(15 downto 0));
	end component;
	

	
	signal lrck_int: std_logic;	-- internal left/right codec channel select
   signal sclk_i: std_logic; -- internal codec data shift clock
   signal data_reg: std_logic; -- internal data stream to the codec DAC
   signal PWADDA_in_i: std_logic; 
	signal bit_cntr: std_logic_vector(4 downto 0);
   signal subcycle_cntr: std_logic_vector(1 downto 0);
	
	-- for fz
	signal blockIdx: std_logic_vector(10 downto 0);
	signal keyIdx: std_logic_vector(16 downto 0);
	signal incBlockIdx: std_logic;
	signal incKeyIdx: std_logic;
	signal rom1addr: std_logic_vector(10 downto 0);
	signal rom2addr: std_logic_vector(16 downto 0);
	signal rom1data: std_logic_vector(15 downto 0);
	signal rom2data: std_logic_vector(15 downto 0);
	signal data0: std_logic_vector(15 downto 0);
	signal data1: std_logic_vector(15 downto 0);
	signal data2: std_logic_vector(15 downto 0);
	signal data3: std_logic_vector(15 downto 0);
	signal data: std_logic_vector(15 downto 0);
	signal shiftOut: std_logic;
	signal dataCnt: std_logic_vector(3 downto 0);
	signal incDataCnt: std_logic;
	signal lrck_i: std_logic;
	signal rstBlockIdx: std_logic;
	signal rstKeyIdx: std_logic;
	signal rstDataCnt: std_logic;
	signal getDataSum: std_logic;
	
	type states is (stReset,stWaitPre,stWait,stReadData,
		stReadData0,stReadData1,stReadData2,stReadData3,stAddData,
		stIdleL,stDataL,stRstdatacnt,stIdleR,stDataR,stAddKeyIdx,stCheckKeyIdx,
		stAddBlockIdx,stCheckBlockIdx
	);
	signal pr_state,nx_state:states;
	
begin

         PWADDA_out<= PWADDA_in_i;
         PWADDA_in_i<= not PWADDA_in;
	
      clkgeb:  clkgen	PORT MAP  (
				clk => clk,
				reset => reset,
				mclk => mclk,
				sclk => sclk_i,
				lrck => lrck_i,
				bit_cntr => bit_cntr,
				subcycle_cntr => subcycle_cntr
			);
			
			
	fzrom1 : rom1
		port map (
			clka => clk,
			addra => rom1addr,
			douta => rom1data
			);
			
	fzrom2 : rom2
		port map (
			clka => clk,
			addra => rom2addr,
			douta => rom2data
			);
			
--	process(sclk_i)
--	begin
--	 if sclk_i'event and sclk_i='1' then
--	 data_reg<=sdin;
--	 end if;
--	 end process;
--	 
--	 sclk<=sclk_i;
--	 lrck<=lrck_i;
--	 sdout<=data_reg;
	 
	process(reset,sclk_i)
	begin
		if reset = '1' then
			pr_state<=stReset;
		elsif sclk_i'event and sclk_i='0' then
			pr_state<=nx_state;
			if rstDataCnt='1' then
				dataCnt<=(others => '0');
			elsif incDataCnt='1' then
				dataCnt<=dataCnt+1;
			end if;
			if incKeyIdx='1' then
				keyIdx<=keyIdx+1;
			end if;
			if incBlockIdx='1' then
				blockIdx<=blockIdx+1;
			end if;
			if shiftOut='1' then
				data<=data(14 downto 0)&'0';
			end if;
			if rstBlockIdx='1' then
				blockIdx<=(others => '0');
			end if;
			if rstKeyIdx='1' then
				keyIdx<=(others => '0');
			end if;
			if getDataSum='1' then
--				data<=data0+data1+data2+data3;
				data<=data0+data1+data3;
				bitsdata<=data;
--				data<=data1;
			end if;
		end if;
	end process;
	
	process(pr_state,start,
		rom1addr,rom2addr,rom1data,
		rom2data,dataCnt,lrck_i,keyIdx,blockIdx,data)
		variable tempmul: std_logic_vector(21 downto 0);
		variable tempmul2: std_logic_vector(32 downto 0);
	begin
		case pr_state is
			when stReset =>
				if start='1' then
					nx_state<=stWaitPre;
					incBlockIdx<='0';
					incKeyIdx<='0';
					rstBlockIdx<='1';
					rstKeyIdx<='1';
--					led<="010101";
				else
					nx_state<=stReset;
					led<=(others => '0');
--					led<="011010";
				end if;
--				led<=(others => '0');
			when stWaitPre =>
				if lrck_i='1' then
					nx_state<=stWait;
				else
					nx_state<=stWaitPre;
				end if;
			when stWait =>
				rstBlockIdx<='0';
				rstKeyIdx<='0';
				if lrck_i='0' then
					nx_state<=stReadData0;
--					led<="101010";
				else
					nx_state<=stWait;
--					led<="010101";
				end if;
			when stReadData0 =>
				rstBlockIdx<='0';
				nx_state<=stReadData1;
				tempmul:=conv_std_logic_vector(4,11)*blockIdx;
				rom1addr<=tempmul(10 downto 0)+conv_std_logic_vector(0,11);
				tempmul2:=rom1data*conv_std_logic_vector(3120,17);
				rom2addr<=tempmul2(16 downto 0)+keyIdx;
				data0<=rom2data;
			when stReadData1 =>
				nx_state<=stReadData2;
				tempmul:=conv_std_logic_vector(4,11)*blockIdx;
				rom1addr<=tempmul(10 downto 0)+conv_std_logic_vector(1,11);
				tempmul2:=rom1data*conv_std_logic_vector(3120,17);
				rom2addr<=tempmul2(16 downto 0)+keyIdx;
				data1<=rom2data;
			when stReadData2 =>
				nx_state<=stReadData3;
				tempmul:=conv_std_logic_vector(4,11)*blockIdx;
				rom1addr<=tempmul(10 downto 0)+conv_std_logic_vector(2,11);
				tempmul2:=rom1data*conv_std_logic_vector(3120,17);
				rom2addr<=tempmul2(16 downto 0)+keyIdx;
				data2<=rom2data;
			when stReadData3 =>
				nx_state<=stAddData;
				tempmul:=conv_std_logic_vector(4,11)*blockIdx;
				rom1addr<=tempmul(10 downto 0)+conv_std_logic_vector(3,11);
				tempmul2:=rom1data*conv_std_logic_vector(3120,17);
				rom2addr<=tempmul2(16 downto 0)+keyIdx;
				data3<=rom2data;
			when stAddData =>
				nx_state<=stIdleL;
				getDataSum<='1';
				shiftOut<='0';
				rstDataCnt<='1';
				incDataCnt<='0';
			when stIdleL =>
				rstDataCnt<='0';
				getDataSum<='0';
				if lrck_i='1' then
					nx_state<=stDataL;
					sdout<=data(15);
					shiftOut<='1';
					incDataCnt<='1';
				else
					nx_state<=stIdleL;
				end if;
			when stDataL =>
				if dataCnt=15 then
					nx_state<=stRstdatacnt;
					sdout<='0';
					getDataSum<='1';
					shiftOut<='0';
					incDataCnt<='0';
				else
					nx_state<=stDataL;
					sdout<=data(15);
					shiftOut<='1';
					incDataCnt<='1';
				end if;
			when stRstdatacnt => -- I don't know why I need this.
				nx_state<=stIdleR;
				rstDataCnt<='1';
			when stIdleR =>
				rstDataCnt<='0';
				getDataSum<='0';
				if lrck_i='0' then
					nx_state<=stDataR;
					sdout<=data(15);
					shiftOut<='1';
					incDataCnt<='1';
				else
					nx_state<=stIdleR;
				end if;
			when stDataR =>
				if dataCnt=15 then
					nx_state<=stAddKeyIdx;
					sdout<='0';
					incKeyIdx<='1';
					incDataCnt<='0';
				else
					nx_state<=stDataR;
					sdout<=data(15);
					shiftOut<='1';
					incDataCnt<='1';
				end if;
			when stAddKeyIdx =>
				nx_state<=stCheckKeyIdx;
				incKeyIdx<='0';
--				led<="111000";
			when stCheckKeyIdx =>
				if keyIdx/=3119 then
					nx_state<=stReadData0;
				else
					nx_state<=stAddBlockIdx;
					incBlockIdx<='1';
					rstKeyIdx<='1';
				end if;
			when stAddBlockIdx =>
				nx_state<=stCheckBlockIdx;
				incBlockIdx<='0';
				rstKeyIdx<='0';
			when stCheckBlockIdx =>
				nx_state<=stReadData0;
				if blockIdx=511 then
					rstBlockIdx<='1';
				end if;
			when others => NULL;
		end case;
	end process;
	
	 sclk<=sclk_i;
	 lrck<=lrck_i;

end Behavioral;
