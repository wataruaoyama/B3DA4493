Library IEEE;
USE IEEE.std_logic_1164.ALL;
USE WORK.ALL;
USE IEEE.std_logic_unsigned.ALL;

ENTITY ctr449 IS
PORT(RESET,CLK_10M,XDSD,DEM0,DEM1 : IN std_logic;
		SD,SLOW : IN std_logic;
		SSLOW,DSDD,SC0,SC1,SC2 : IN std_logic;
		DATA_DSDL,LRCK_DSDR,CLK_SEL,BCK_DSDCLK,LRCK0 : IN std_logic;
		CLK_22M,CLK_24M,CPOK : IN std_logic;
		DZFR : IN std_logic;
		PHA : IN std_logic;
		PHB : IN std_logic;
		MUTE_IN : std_logic;
		CSN,CCLK,CDTI : OUT std_logic;
		MCLK,SCK,BCLK,DATA,LRCK,ENCLK_22M,ENCLK_24M : OUT std_logic;
		LED_DSD : OUT std_logic;
		LED_PCM : OUT std_logic;
		LED_96K : OUT std_logic;
		PDN : OUT std_logic;
		MUTE : OUT std_logic);
END ctr449;

ARCHITECTURE RTL OF ctr449 IS

component regctr
	PORT(RESET,CLK,CLK_MSEC,XDSD,DEM0,DEM1 : IN std_logic;
		SD,SLOW,SSLOW,DSDD,SC0,SC1,SC2 : IN std_logic;
		ATT : IN std_logic_vector(7 downto 0);
		CSN,CCLK,CDTI : OUT std_logic);
end component;

component clkgen 
	PORT(RESET,CLK,CLK_24M,CLK_22M,CPOK,CLK_SEL : IN std_logic;
		CLK_MSEC,ENCLK_24M,ENCLK_22M,MCLK,SCK : OUT std_logic);
end component;

component attcnt
	port(
			CLK : IN std_logic;
			RESET_N : IN std_logic;
			A : IN std_logic;
			B : IN std_logic;
			CNTUP : OUT std_logic;
			CNTDWN : OUT std_logic;
			Q : OUT std_logic_vector(7 downto 0));
end component;

component detect_ov96k
	PORT(
			XDSD : in std_logic;
			MCLK : in std_logic;
			LRCK : in std_logic;
			CLK_SEL : in std_logic;
			OV96K : out std_logic);
end component;

signal clk,clk_msec,iMCLK,iSCK,ilrck,iMUTE,ov96k : std_logic;
signal att : std_logic_vector(7 downto 0);

begin

	R1 : regctr port map (RESET => reset,CLK => CLK_10M,CLK_MSEC => clk_msec,XDSD => xdsd,
								DEM0 => dem0,DEM1 => dem1,SD => sd,SLOW => slow,
								SSLOW => sslow,DSDD => dsdd,SC0 => sc0,SC1 => sc1,SC2 => sc2,ATT => att,
								CSN => csn,CCLK => cclk,CDTI => cdti); 

	C1 : clkgen port map (RESET => reset,CLK => CLK_10M,CLK_24M => clk_24m,CLK_22M => clk_22m,
								CPOK => cpok,CLK_SEL => clk_sel,CLK_MSEC => clk_msec,
								ENCLK_22M => enclk_22m,ENCLK_24M => enclk_24m,MCLK => iMCLK,SCK => iSCK);
								
	A1 : attcnt port map (CLK => CLK_10M,RESET_N => reset,A => PHA, B => PHB,Q => att);
	
	D1 : detect_ov96k port map (XDSD => xdsd,MCLK => isck,LRCK => ilrck,CLK_SEL => clk_sel,OV96K => ov96k );
	
	ilrck <= LRCK0 when XDSD = '1' else LRCK_DSDR;
	LRCK <= ilrck;
	DATA <= DATA_DSDL;
	BCLK <= BCK_DSDCLK;

	MCLK <= iMCLK when CPOK = '1' else 'Z';
	SCK <= iSCK when CPOK = '1' else 'Z';
	
	LED_DSD <= XDSD when RESET = '1' else '1';
	LED_PCM <= not XDSD when RESET = '1' else '1';
	LED_96K <= not ov96k when RESET = '1' else '1';
--	LED_96K <= '1';
	
	MUTE <= 'Z' when (RESET and DZFR and not MUTE_IN) = '1' else '0';
	PDN <= RESET;

end RTL;