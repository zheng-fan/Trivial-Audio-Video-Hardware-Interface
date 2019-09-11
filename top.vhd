library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity top is
    Port ( clk : in  STD_LOGIC;
           Rst : in  STD_LOGIC;
			  PClk_out : out std_logic;
			  Vsync : out std_logic;
			  Hsync : out std_logic;
			  dvd_psave, vga_blank, vga_csync  : out std_logic;
			  Vga_R : out std_logic_vector(7 downto 0);
			  Vga_G : out std_logic_vector(7 downto 0);
			  Vga_B : out std_logic_vector(7 downto 0);
			  --for audio
			  PWADDA_in : in std_logic;
			  sdin	:	in std_logic;
			  sdout	:	out std_logic;
			  mclk	:	out std_logic;
			  lrck	:	out std_logic;
			  sclk	:	out std_logic;
			  PWADDA_out : out std_logic;
			  start : in std_logic;
			  led : out std_logic_vector(5 downto 0)
			  );
end top;

architecture Behavioral of top is

--- audio component below
component audiotop
	port
	(
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
end component;

--- VGA component below
	COMPONENT SVGA_Timing_Generation
	PORT(
		nRST : IN std_logic;
		Pixel_Clock : IN std_logic;          
		Hsync : OUT std_logic;
		Vsync : OUT std_logic;
		DE : OUT std_logic;
		HA_out : out std_logic;
		VA_out : out std_logic;
		Pre_DE : OUT std_logic;
		Delay_DE : OUT std_logic;
		Pixel_Addr : OUT std_logic_vector(7 downto 0)
		);
	END COMPONENT;
	
component clk25mhz
port
 (-- Clock in ports
  CLK_IN1           : in     std_logic;
  -- Clock out ports
  CLK_OUT1          : out    std_logic;
  -- clock original
  CLK_OUT2          : out    std_logic
 );
end component;

	
	component BmpROM
	port (
	clka: IN std_logic;
	addra: IN std_logic_VECTOR(14 downto 0);
	douta: OUT std_logic_VECTOR(23 downto 0));
	end component;
	
	signal Hsync_i :std_logic;
	signal Vsync_i :std_logic;
	signal DE_i : std_logic;
	signal PClk : std_logic;
	signal H_De,V_De : std_logic;
	signal Pix_Addr : integer range 0 to 640;
	signal Line_Addr : integer range 0 to 480;
	signal Line_cnt_flag : std_logic;
	signal VgaR :  std_logic_vector(7 downto 0);
	signal VgaG :  std_logic_vector(7 downto 0);
	signal VgaB :  std_logic_vector(7 downto 0);	
	
	signal adrVideoMem : std_logic_vector(14 downto 0):="000000000000000";
	signal BmpData  : std_logic_vector(23 downto 0);
	
  constant Hsize:integer:=200;		-- Horizontal logo size (pixels)
  constant Vsize:integer:=106;		-- Vertical logo size (pixels)
  signal Rstn_n :std_logic;
  constant Horigin:integer:=(640-Hsize)/2;		-- Horizontal logo origin (pixels) 300
  constant Vorigin:integer:=480-(Vsize+50);		-- Vertical logo origin (pixels) 240
  
  constant WaveHsize:integer:=200;
  constant WaveVsize:integer:=200;
  constant WaveHorigin:integer:=(640-WaveHsize)/2;	
  constant WaveVorigin:integer:=50;
  
  signal adrVideoPixel: integer range 0 to Hsize-1;
  signal adrVideoLine: integer range 0 to Vsize-1;
  signal clk2 :std_logic;
  
--  type mat is array(WaveVsize-1 downto 0) of std_logic_vector(0 to WaveHsize-1); --for wave
--  signal wavpix : mat;
	type hIntegerVec is array(0 to WaveHsize-1) of integer;
	signal hh : hIntegerVec := (others => 0);
--  signal wavpix : mat := (others => (others => '0'));
  type rgbbits is array(0 to WaveHsize-1) of std_logic_vector(23 downto 0);
  constant color : rgbbits:=(
  "000011110000110111111101","000011110000110111111101","000000100000110111111101","000000100000110111111101","000000100010000011111101","000000100010000011111101","000000100010111011111101","000000100010111011111101","000000100100001011111101","000000100100001011111101","000000100100111011111101","000000100100111011111101","000000100101100011111101","000000100101100011111101","000000100110101011111101","000000100110101011111101","000000100111100111111101","000000100111100111111101","000000101000110111111101","000000101000110111111101","000000101001100111111101","000000101001100111111101","000000101010001011111101","000000101010001011111101","000000101011010111111101","000000101011010111111101","000000101100001111111101","000000101100001111111101","000000101101011111111101","000000101101011111111101","000000101110010011111101","000000101110010011111101","000000101110110111111101","000000101110110111111101","000000101111111111111110","000000101111111111111110","000000101111110111101101","000000101111110111101101","000000101111110111011010","000000101111110111011010","000000101111110111001010","000000101111110111001010","000000101111110110111000","000000101111110110111000","000000101111110110110001","000000101111110110110001","000000101111110110100010","000000101111110110100010","000000101111110110001111","000000101111110110001111","000000101111110110000000","000000101111110110000000","000000101111110101101101","000000101111110101101101","000000101111110101100101","000000101111110101100101","000000101111110101011000","000000101111110101011000","000000101111110101000101","000000101111110101000101","000000101111110100110101","000000101111110100110101","000000101111110100100011","000000101111110100100011","000000101111110100011011","000000101111110100011011","000000001111110100001011","000000001111110100001011","000001101111110100000000","000001101111110100000000","000110001111110100000010","000110001111110100000010","001010011111110100000010","001010011111110100000010","001110111111110100000010","001110111111110100000010","010011001111110100000010","010011001111110100000010","010100101111110100000010","010100101111110100000010","011000101111110100000010","011000101111110100000010","011101001111110100000010","011101001111110100000010","100001111111110100000010","100001111111110100000010","100101111111110100000010","100101111111110100000010","100111001111110100000010","100111001111110100000010","101011011111110100000010","101011011111110100000010","101111111111110100000010","101111111111110100000010","110100011111110100000010","110100011111110100000010","111000101111110100000010","111000101111110100000010","111001111111110100000010","111001111111110100000010","111111001111111100000010","111111001111111100000010","111111101111001000000010","111111101111001000000010","111111011101111100000010","111111011101111100000010","111111011101000100000010","111111011101000100000010","111111011011111000000010","111111011011111000000010","111111011011001000000010","111111011011001000000010","111111011010100000000010","111111011010100000000010","111111011001010100000010","111111011001010100000010","111111011000011100000010","111111011000011100000010","111111010111001100000010","111111010111001100000010","111111010110011000000010","111111010110011000000010","111111010101110100000010","111111010101110100000010","111111010100101100000010","111111010100101100000010","111111010011110000000010","111111010011110000000010","111111010010100000000010","111111010010100000000010","111111010001101100000010","111111010001101100000010","111111010001001000000010","111111010001001000000010","111111010000000000000001","111111010000000000000001","111111010000001000010011","111111010000001000010011","111111010000001000100101","111111010000001000100101","111111010000001000110101","111111010000001000110101","111111010000001001001000","111111010000001001001000","111111010000001001001111","111111010000001001001111","111111010000001001011101","111111010000001001011101","111111010000001001110000","111111010000001001110000","111111010000001010000000","111111010000001010000000","111111010000001010010010","111111010000001010010010","111111010000001010011010","111111010000001010011010","111111010000001010100111","111111010000001010100111","111111010000001010111011","111111010000001010111011","111111010000001011001010","111111010000001011001010","111111010000001011011100","111111010000001011011100","111111010000001011100100","111111010000001011100100","111111110000001011110100","111111110000001011110100","111110010000001011111111","111110010000001011111111","111001110000001011111101","111001110000001011111101","110101110000001011111101","110101110000001011111101","110001000000001011111101","110001000000001011111101","101101000000001011111101","101101000000001011111101","101011100000001011111101","101011100000001011111101","100111010000001011111101","100111010000001011111101","100011000000001011111101","100011000000001011111101","011110010000001011111101","011110010000001011111101","011010000000001011111101","011010000000001011111101","011000110000001011111101","011000110000001011111101","010100110000001011111101","010100110000001011111101","010000010000001011111101","010000010000001011111101","001011100000001011111101","001011100000001011111101","000111000000001011111101","000111000000001011111101","001001100000111111111101","001001100000111111111101"
  );
  signal bitsdata : std_logic_vector(15 downto 0);
  
  signal lrck_i : std_logic;
  signal shiftdata : std_logic;
  signal wavcnt : std_logic_vector(7 downto 0) := (others =>'0');
begin
   dvd_psave <= '1' ;   -- Power Save Control,'1' active 
   vga_csync <= '0' ;   -- control G,'1' active
   vga_blank <= '1' ;   -- if '0',input is ignored
--	Vsync<=Vsync_i;
--	Hsync<=Hsync_i;
	Rstn_n<=not Rst;
	Inst_SVGA_Timing_Generation: SVGA_Timing_Generation PORT MAP(
		nRST => Rstn_n,
		Pixel_Clock => PClk,
		Hsync => Hsync_i,
		Vsync => Vsync_i,
		DE => DE_i,
		HA_out=>H_De,
		VA_out=>V_DE,
		Pre_DE => open,
		Delay_DE => open,
		Pixel_Addr => open
	);
		
	Inst_clk25mhz : clk25mhz
  port map
   (-- Clock in ports
    CLK_IN1            =>Clk,
    -- Clock out ports
    CLK_OUT1           => PClk,
	 -- clock original
    CLK_OUT2           => clk2
	 );
	 
	BMP_ROM : BmpROM
		port map (
			clka => Pclk,
			addra => adrVideoMem,
			douta => BmpData);
	
	fz_audio : audiotop
		port map (
			clk => clk2,
			reset => Rst,
			PWADDA_in => PWADDA_in,
			sdin => sdin,
			sdout => sdout,
			mclk => mclk,
			lrck => lrck_i,
			sclk => sclk,
			PWADDA_out => PWADDA_out,
			start => start,
			bitsdata => bitsdata,
			led => led
		);
			
	
	process(PClk,Rstn_n,DE_i)
		begin
			if Rstn_n='0' or DE_i='0' then
				Pix_Addr<=0;
 				Line_cnt_flag<='0';
			elsif rising_edge(PClk) then
				if DE_i='1' then
					Pix_Addr<=Pix_Addr + 1;
					if Pix_Addr=638 then
						Line_cnt_flag<='1';
					elsif Pix_Addr=639 then
						Pix_Addr<=0;
						Line_cnt_flag<='0';
					end if;
				end if;
			end if;
	end process;


		process(PClk,Rstn_n,Line_cnt_flag,V_De)
		begin
			if Rstn_n='0' or V_De='0' then
				Line_Addr<=479;
			elsif rising_edge(PClk) then 
				if V_De='1' and Line_cnt_flag='1' then
					Line_Addr<=Line_Addr - 1;
				end if;
			end if;
	end process;
	
--	Vga_R<="11111111" when Pix_Addr=319 or Line_Addr=239 else "00000000";
--	Vga_G<="11111111" when Pix_Addr=319 or Line_Addr=239 else "00000000";
--	Vga_B<="11111111" when Pix_Addr=319 or Line_Addr=239 else "00000000";
	
	PClk_out<=not PClk;
	

process(Rstn_n,De_i,Pclk,Pix_Addr, Line_Addr)
	variable height : integer;
	variable width : integer;
begin
if Rstn_n='0' or De_i='0' then
		adrVideoPixel <= 0   ;
		adrVideoLine <= 0  ;
	   adrVideoMem <= (others=>'0');
		VgaR<="00000000";
		VgaG<="00000000";
		VgaB<="00000000";	
elsif Pclk'event and Pclk='1' then
		if DE_i='1' then	-- in the active screen
			if (Pix_Addr >= Horigin  and Pix_Addr < Horigin + Hsize ) and	 -- during logo 
				(Line_Addr >= Vorigin and Line_Addr < Vorigin + Vsize ) 	then		 -- image
					  adrVideoPixel <= Pix_Addr - Horigin   ;
					  adrVideoLine <= Line_Addr - Vorigin   ;
					  adrVideoMem <= conv_std_logic_vector(adrVideoPixel+adrVideoLine*Hsize,15);
					  VgaR<=BmpData(7 downto 0);
					  VgaG<=BmpData(15 downto 8);
					  VgaB<=BmpData(23 downto 16);
			elsif (Pix_Addr >= WaveHorigin  and Pix_Addr < WaveHorigin + WaveHsize ) and
				(Line_Addr >= WaveVorigin and Line_Addr < WaveVorigin + WaveVsize ) 	then
					height:=Line_Addr-WaveVorigin;
					width:=Pix_Addr-WaveHorigin;
					if height < hh(width) then
--						led<=(others => '1');
						VgaR<=color(width)(23 downto 16);
						VgaG<=color(width)(15 downto 8);
						VgaB<=color(width)(7 downto 0);
--						VgaR<=(others => '1');
--						VgaG<=(others => '1');
--						VgaB<=(others => '1');
					else
						VgaR<="00000000";
						VgaG<="00000000";
						VgaB<="00000000";
					end if;
			else
					  VgaR<="00000000";
					  VgaG<="00000000";
					  VgaB<="00000000";
			end if;
		end if;
	end if;
end process;
			
process(Pclk)
	begin
		if Pclk'event and Pclk='1' then
			Vga_R<=VgaR;
			Vga_G<=VgaG;
			Vga_B<=VgaB;
			Vsync<=Vsync_i;
			Hsync<=Hsync_i;
		end if;
end process;

  lrck <= lrck_i;

process(lrck_i)
begin
	if rising_edge(lrck_i) then
		wavcnt<=wavcnt+'1';
		if wavcnt="00000000" then
			shiftdata<='0';
		end if;
		if wavcnt="00001000" then
			shiftdata<='1';
		end if;
	end if;
end process;

--process(shiftdata)
--	variable tmp : integer;
--begin
--	if rising_edge(shiftdata) then
--		for i in WaveVsize-1 downto 0 loop
--			wavpix(i)(0 to WaveHsize-2)<=wavpix(i)(1 to WaveHsize-1);
--		end loop;
--		tmp:=conv_integer(bitsdata)/328;
--		for i in WaveVsize-1 downto 0 loop
--			if i < tmp then
--				wavpix(i)(WaveHsize-1)<='1';
--			else
--				wavpix(i)(WaveHsize-1)<='0';
--			end if;
--		end loop;
--	end if;
--end process;

process(Rstn_n,shiftdata)
begin
	if (Rstn_n = '0') then
		hh<=(others => 0);
	end if;
	if rising_edge(shiftdata) then
		hh(0 to WaveHsize-2)<=hh(1 to WaveHsize-1);
		hh(WaveHsize-1)<=conv_integer(bitsdata)/328;
	end if;
end process;

end Behavioral;
