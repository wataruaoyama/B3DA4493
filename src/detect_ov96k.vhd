Library IEEE;
USE IEEE.std_logic_1164.ALL;
USE WORK.ALL;
USE IEEE.std_logic_unsigned.ALL;

ENTITY detect_ov96k IS
PORT(
	XDSD : in std_logic;
	MCLK : in std_logic;
	LRCK : in std_logic;
	CLK_SEL : in std_logic;
	OV96K : out std_logic);
END detect_ov96k;

ARCHITECTURE RTL OF detect_ov96k IS

signal cnt : std_logic_vector(8 downto 0);
signal iov96k,dov96k : std_logic;

BEGIN

process(MCLK,XDSD) begin
	if XDSD = '0' then
		iov96k <= '0';
		cnt <= "000000000";
	elsif (MCLK'event and MCLK='1') then
		if LRCK = '0' then
			iov96k <= iov96k;
			cnt <= "000000000";
		else
			if cnt = "001111111" then
				iov96k <= '0';
				cnt <= cnt;
			else
				cnt <= cnt + 1;
				iov96k <= '1';
			end if;
		end if;
	end if;
end process;

process(LRCK) begin
	if LRCK'event and LRCK='0' then
		dov96k <= iov96k;
	end if;
end process;
ov96k <= dov96k;

end RTL;
			
				