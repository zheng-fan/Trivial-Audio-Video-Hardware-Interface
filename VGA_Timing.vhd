library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

library unisim;
use unisim.all;

entity SVGA_Timing_Generation is
	generic (
		VIDEO_MODE : integer := 0  -- modify by Ryan original : 6
		);
	port (
		nRST        : in  std_logic ;
		Pixel_Clock : in  std_logic ;
		Hsync       : out std_logic ;
		Vsync       : out std_logic ;
		DE          : out std_logic ;
		HA_out      : out std_logic ;
		VA_out      : out std_logic ;
		Pre_DE		: out std_logic ; 
		Delay_DE : out std_logic ;
		Pixel_Addr  : out std_logic_vector(7 downto 0)
		);
	
end entity SVGA_Timing_Generation;

architecture IMP of SVGA_Timing_Generation is
	
	subtype MODES is integer range 0 to 16;
	type    CONST_ARRAY is array(MODES) of integer;
	
	-- Mode  0  640 X  480 @ 60Hz with a 25.175MHz pixel clock
	-- Mode  1  640 X  480 @ 72Hz with a 31.500MHz pixel clock
	-- Mode  2  640 X  480 @ 75Hz with a 31.500MHz pixel clock
	-- Mode  3  640 X  480 @ 85Hz with a 36.000MHz pixel clock
	-- Mode  4  800 X  600 @ 56Hz with a 38.100MHz pixel clock
	-- Mode  5  800 X  600 @ 60Hz with a 40.000MHz pixel clock
	-- Mode  6  800 X  600 @ 72Hz with a 50.000MHz pixel clock
	-- Mode  7  800 X  600 @ 75Hz with a 49.500MHz pixel clock -- Strange Pixel Clock
	-- Mode  8  800 X  600 @ 85Hz with a 56.250MHz pixel clock
	-- Mode  9 1024 X  768 @ 60Hz with a 65.000MHz pixel clock
	-- Mode 10 1024 X  768 @ 70Hz with a 75.000MHz pixel clock
	-- Mode 11 1024 X  768 @ 75Hz with a 78.750MHz pixel clock
	-- Mode 12 1024 X  768 @ 85Hz with a 94.500MHz pixel clock
	-- Mode 13 1280 X 1024 @ 60Hz with a 96.000MHz pixel clock -- Add by Ryan 
	-- Mode 14  2048 X 1536 @ 60Hz with a 130MHz pixel clock
	
	
	constant H_ACTIVE_TABLE : CONST_ARRAY :=
	( 0 => 640, 1 => 640, 2 => 640, 3 => 640,
	4 => 800, 5 => 800, 6 => 800, 7 => 800, 8 => 800,
	9 => 1024, 10 => 1024, 11 => 1024, 12 => 1024, 13 => 1280,14=>1024,15=>200,16=>720);
	
	constant H_ACTIVE : integer := H_ACTIVE_TABLE(VIDEO_MODE);
	
	constant H_FRONT_PORCH_TABLE : CONST_ARRAY :=
	(0  => 16,
	1  => 24,
	2  => 16,
	3  => 32,
	4  => 32,
	5  => 40,
	6  => 56,
	7  => 16,
	8  => 32,
	9  => 24,
	10 => 24,
	11 => 16,
	12 => 48,
	13 => 16,
	14 =>24,
	15 =>10,
	16 =>48);
	
	constant H_FRONT_PORCH : integer := H_FRONT_PORCH_TABLE(VIDEO_MODE);
	
	constant H_SYNCH_TABLE : CONST_ARRAY :=
	(0  => 96,
	1  => 40,
	2  => 96,
	3  => 48,
	4  => 128,
	5  => 128,
	6  => 120,
	7  => 80,
	8  => 64,
	9  => 136,
	10 => 136,
	11 => 96,
	12 => 96,
	13 => 48,
	14 =>136,
	15 =>6,
	16 =>128);
	
	constant H_SYNCH : integer := H_SYNCH_TABLE(VIDEO_MODE);
	
	constant H_BACK_PORCH_TABLE : CONST_ARRAY :=
	( 0  => 48,
	1  => 128,
	2  => 48,
	3  => 112,
	4  => 128,
	5  => 88,
	6  => 64,
	7  => 160,
	8  => 152,
	9  => 160,
	10 => 144,
	11 => 176,
	12 => 208,
	13 => 116,
	14 =>160,
	15 =>40,
	16 =>64);
	
	constant H_BACK_PORCH : integer := H_BACK_PORCH_TABLE(VIDEO_MODE);
	
	constant H_TOTAL_TABLE : CONST_ARRAY :=
	( 0  => 800,
	1  => 832,
	2  => 800,
	3  => 832,
	4  => 1088,
	5  => 1056,
	6  => 1040,
	7  => 1056,
	8  => 1048,
	9  => 1344,
	10 => 1328,
	11 => 1312,
	12 => 1376,
	13 => 1460,
	14 =>1344,
	15 =>256,
	16 =>960);
	
	constant H_TOTAL : integer := H_TOTAL_TABLE(VIDEO_MODE);
	
	constant V_ACTIVE_TABLE : CONST_ARRAY :=
	( 0  => 480,
	1  => 480,
	2  => 480,
	3  => 480,
	4  => 600,
	5  => 600,
	6  => 600,
	7  => 600,
	8  => 600,
	9  => 768,
	10 => 768,
	11 => 768,
	12 => 768,
	13 => 50,
	14 =>1536,
	15 =>600,
	16 =>480);
	
	
	constant V_ACTIVE : integer := V_ACTIVE_TABLE(VIDEO_MODE);
	
	constant V_FRONT_PORCH_TABLE : CONST_ARRAY :=
	( 0  => 12,  -- modify by Ryan original : 11
	1  => 9,
	2  => 11,
	3  => 1,
	4  => 1,
	5  => 1,
	6  => 37,
	7  => 1,
	8  => 1,
	9  => 8,
	10 => 3,
	11 => 1,
	12 => 1,
	13 => 2,
	14 =>6,
	15 =>8,
	16 =>6);
	
	constant V_FRONT_PORCH : integer := V_FRONT_PORCH_TABLE(VIDEO_MODE);
	
	constant V_SYNCH_TABLE : CONST_ARRAY :=
	( 0  => 2,
	1  => 3,
	2  => 2,
	3  => 3,
	4  => 4,
	5  => 4,
	6  => 6,
	7  => 2,
	8  => 3,
	9  => 6,--1
	10 => 6,
	11 => 3,
	12 => 3,
	13 => 2,
	14 =>12,
	15 =>2,
	16 =>2);
	
	
	constant V_SYNCH : integer := V_SYNCH_TABLE(VIDEO_MODE);
	
	constant V_BACK_PORCH_TABLE : CONST_ARRAY :=
	( 0  => 31,
	1  => 28,
	2  => 32,
	3  => 25,
	4  => 14,
	5  => 23,
	6  => 23,
	7  => 21,
	8  => 27,
	9  => 24,--29
	10 => 29,
	11 => 28,
	12 => 36,
	13 => 2,
	14 =>58,
	15 =>20,
	16 =>12);
	
	
	constant V_BACK_PORCH : integer := V_BACK_PORCH_TABLE(VIDEO_MODE);
	
	
	constant V_TOTAL_TABLE : CONST_ARRAY :=
	( 0  => 525,  -- modify by Ryan original : 524
	1  => 520,
	2  => 525,
	3  => 509,
	4  => 619,
	5  => 628,
	6  => 666,
	7  => 624,
	8  => 631,
	9  => 806,
	10 => 806,
	11 => 800,
	12 => 808,
	13 => 56,
	14 =>1612,
	15 =>630,
	16 =>500);
	
	
	constant V_TOTAL : integer := V_TOTAL_TABLE(VIDEO_MODE) ;
	
	signal pixel_count : natural range 0 to H_TOTAL - 1 ;
	signal line_count  : natural range 0 to V_TOTAL - 1 ;
	
	signal HA : std_logic := '0' ;
	signal VA : std_logic := '0' ;
	
	signal HA_i : std_logic := '0' ;
	signal VA_i : std_logic := '0' ;
	
	
	signal HA_ii : std_logic := '0' ;
	signal VA_ii : std_logic := '0' ;	
	
	
begin  -- architecture IMP
	
	----***----***----***----***----***----***----***----***----***--------
	-- Pattern CLK = 1280 x 1024 x 60Hz = 78643200
	-- OSC = 48MHz, use DCM CLK2X_OUT = 96MHz
	-- 96MHz / 60Hz / 1096 Hsync = 1460 CLK
	----***----***----***----***----***----***----***----***----***--------
	
	-- CREATE THE HORIZONTAL LINE PIXEL COUNTER
	pixel_count_count : process (nRST, Pixel_Clock) is
	begin
		if nRST = '0' then
			pixel_count <= 0 ;
			
		elsif Rising_Edge(Pixel_Clock) then
			if (pixel_count = (H_TOTAL - 1)) then
				pixel_count <= 0 ;
				-- reset pixel counter
			else
				pixel_count <= pixel_count + 1 ;
				
			end if ;
		end if ;
	end process pixel_count_count ;
	
	Pixel_Addr(7 downto 0) <= conv_std_logic_vector(pixel_count, 8) ;
	
	-- CREATE THE HORIZONTAL SYNCH PULSE
	Hsync_Handle : process (nRST, Pixel_Clock) is
	begin
		if nRST = '0' then
			Hsync <= '0' ;                 -- remove h_synch
			
		elsif Rising_Edge(Pixel_Clock) then
			if (pixel_count = (H_SYNCH - 1)) then
				Hsync <= '0' ;               -- start of h_synch
				
			elsif (pixel_count = (H_TOTAL - 1)) then
				Hsync <= '1' ;               -- end of h_synch
				
			end if ;
		end if ;
	end process Hsync_Handle ;
	
	-- CREATE THE Horizontal Active
	HA_Handle : process (nRST, Pixel_Clock) is
	begin
		if nRST = '0' then
			HA <= '0' ;                 -- remove DE
			
		elsif Rising_Edge(Pixel_Clock) then
			if (pixel_count = (H_SYNCH + H_FRONT_PORCH - 1)) then
				HA <= '1' ;               -- start of DE
				
			elsif (pixel_count = (H_TOTAL - H_BACK_PORCH - 1)) then
				HA <= '0' ;               -- end of DE
				
			end if ;
		end if ;
	end process HA_Handle ;
	
	HA_out <= HA;
	VA_out <= VA;
	-- CREATE THE VERTICAL FRAME LINE COUNTER
	Line_Count_Handle : process (nRST, Pixel_Clock) is
	begin
		if nRST = '0' then
			line_count <= 0 ;
			
		elsif Rising_Edge(Pixel_Clock) then
			if ((line_count = (V_TOTAL - 1)) and (pixel_count = (H_TOTAL - 1))) then
				-- last pixel in last line of frame 
				line_count <= 0 ;                -- reset line counter
				
			elsif ((pixel_count = (H_TOTAL - 1))) then
				-- last pixel but not last line
				line_count <= line_count + 1 ;   -- increment line counter
				
			end if ;
		end if ;
	end process Line_Count_Handle ;
	
	-- CREATE THE VERTICAL SYNCH PULSE
	Vsync_Handle : process (nRST, Pixel_Clock) is
	begin
		if nRST = '0' then
			Vsync <= '0' ;
			-- remove v_synch
		elsif Rising_Edge(Pixel_Clock) then
			if ((line_count = (V_SYNCH -1) and
				(pixel_count = H_TOTAL - 1))) then     -- start of v_synch
				Vsync <= '0' ;
				
			elsif ((line_count = (0)) and
				(pixel_count = (H_TOTAL - 1))) then  -- end of v_synch
				Vsync <= '1' ;
				
			end if ;
		end if ;
	end process Vsync_Handle ;
	
	-- CREATE THE Vertical Valid
	VA_Handle : process (nRST, Pixel_Clock) is
	begin
		if nRST = '0' then
			VA <= '0' ;
			-- remove VA
		elsif Rising_Edge(Pixel_Clock) then
			if (line_count = (V_SYNCH + V_BACK_PORCH - 1)) then			   -- start of VA
				VA <= '1' ;
				
			elsif (line_count = (V_TOTAL - V_FRONT_PORCH - 1)) then  -- end of VA
				VA <= '0' ;
				
			end if ;
		end if ;
	end process VA_Handle ;
	
	DE <= HA and VA ;
	
	
	
	-- CREATE THE Horizontal Active
	HA_Handle_I : process (nRST, Pixel_Clock) is
	begin
		if nRST = '0' then
			HA_i <= '0' ;                 -- remove DE
			
		elsif Rising_Edge(Pixel_Clock) then
			if (pixel_count = (H_SYNCH + H_FRONT_PORCH-1 )) then
				HA_i <= '1' ;               -- start of DE
				
			elsif (pixel_count = (H_TOTAL - H_BACK_PORCH - 1)) then
				HA_i <= '0' ;               -- end of DE
				
			end if ;
		end if ;
	end process HA_Handle_I ;
	
	
	-- CREATE THE Vertical Valid
	VA_Handle_I : process (nRST, Pixel_Clock) is
	begin
		if nRST = '0' then
			VA_i <= '0' ;
			-- remove VA
		elsif Rising_Edge(Pixel_Clock) then
			if (line_count = (V_SYNCH + V_BACK_PORCH-2 )) then			   -- start of VA
				VA_i <= '1' ;
				
			elsif (line_count = (V_TOTAL - V_FRONT_PORCH-2 )) then  -- end of VA
				VA_i <= '0' ;
				
			end if ;
		end if ;
	end process VA_Handle_I ;
	
	Pre_DE<=HA_i and VA_i;	
	
	
	
	-- CREATE THE Horizontal Active
	HA_Handle_II : process (nRST, Pixel_Clock) is
	begin
		if nRST = '0' then
			HA_ii <= '0' ;                 -- remove DE
			
		elsif Rising_Edge(Pixel_Clock) then
			if (pixel_count = (H_SYNCH + H_FRONT_PORCH - 2)) then
				HA_ii <= '1' ;               -- start of DE
				
			elsif (pixel_count = (H_TOTAL - H_BACK_PORCH - 2)) then
				HA_ii <= '0' ;               -- end of DE
				
			end if ;
		end if ;
	end process HA_Handle_II ;	
	
	
	Delay_DE<=HA_ii and VA;		
	
	
end architecture IMP ;



