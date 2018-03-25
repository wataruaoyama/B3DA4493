Library IEEE;
USE IEEE.std_logic_1164.ALL;
USE WORK.ALL;
USE IEEE.std_logic_unsigned.ALL;

ENTITY clkgen IS
PORT(
		RESET : IN std_logic;
		CLK : IN std_logic;
		CLK_24M : IN std_logic;
		CLK_22M : IN std_logic;
		CPOK : IN std_logic;
		CLK_SEL : IN std_logic;
		CLK_MSEC : OUT std_logic;
		ENCLK_24M : OUT std_logic;
		ENCLK_22M : OUT std_logic;
		MCLK : OUT std_logic;
		SCK : OUT std_logic);
END clkgen;

ARCHITECTURE RTL OF clkgen IS

signal iMCLK,iSCK : std_logic;
signal counter_msec : std_logic_vector(16 downto 0);

BEGIN

--Generate 100msec timer
process(RESET,CLK) BEGIN
	if(RESET = '0') then
		counter_msec <= "00000000000000000";
	elsif(CLK'event and CLK='1') then
		counter_msec <= counter_msec + '1';
	end if;
end process;

CLK_MSEC <= counter_msec(15);	-- about 6msec. 
--CLK_MSEC <= counter_msec(13);	-- For simulation only

ENCLK_22M <= not CLK_SEL;
ENCLK_24M <= CLK_SEL;

iMCLK <= CLK_22M when CLK_SEL = '0' else CLK_24M;
MCLK <= iMCLK;
SCK <= iMCLK;

end RTL;