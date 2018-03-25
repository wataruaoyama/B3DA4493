Library IEEE;
USE IEEE.std_logic_1164.ALL;
USE WORK.ALL;
USE IEEE.std_logic_unsigned.ALL;

ENTITY detect_fs IS
PORT(
	XDSD : in std_logic;
	MCLK : in std_logic;
	LRCK : in std_logic;
	CLK_SEL : in std_logic;
	OV96K : out std_logic);
END detect_fs;

ARCHITECTURE RTL OF detect_fs IS

SIGNAL ld,q,cen : std_logic;
SIGNAL cnt : std_logic_vector(8 downto 0);
SIGNAL en_fs176,en_fs88,en_fs44,en_fs32 : std_logic;
SIGNAL fs176,fs88,fs44,fs32 : std_logic;

BEGIN

ld <= LRCK and not q;

process(MCLK,XDSD,LRCK) BEGIN
	if(XDSD = '0') then
		q <= '1';
	elsif(MCLK'event and MCLK='1') then
		q <= LRCK;
	end if;
end process;

process(MCLK,XDSD,ld) BEGIN
	if(XDSD = '0') then
		cen <= '0';
	elsif(MCLK'event and MCLK='1') then
		if(ld = '1') then
			cen <= '1';
		end if;
	end if;
end process;		

process(MCLK,XDSD,cen) BEGIN
	if(XDSD = '0') then
		cnt <= (others => '0');
	elsif(MCLK'event and MCLK='1') then
		if(cen = '1') then
			if(ld = '1') then
				cnt <= (others => '0');
			elsif(cnt = "111111111") then
				cnt <= "111111111";
			else
				cnt <= cnt + '1';
			end if;
		end if;
	end if;
end process;

process(cnt) begin
	if(cnt = "001000010") then
		en_fs176 <= '1';
	elsif(cnt = "010000010") then
		en_fs88 <= '1';
	elsif(cnt = "100000010") then
		en_fs44 <= '1';
	elsif(cnt = "110000001") then
		en_fs32 <= '1';
	else
		en_fs176 <= '0';
		en_fs88 <= '0';
		en_fs44 <= '0';
		en_fs32 <= '0';
	end if;
end process;	

process(MCLK,XDSD,en_fs176,en_fs88,en_fs44,en_fs32) BEGIN
	if(XDSD = '0') then
		fs176 <= '1';
		fs88 <= '1';
		fs44 <= '1';
		fs32 <= '1';
	elsif(MCLK'event and MCLK='1') then
		if(en_fs176 = '1') then
			if(LRCK = '0') then
				fs176 <= '0';
			else
				fs176 <= '1';
			end if;
		end if;
		
		if(en_fs88 = '1') then
			if(LRCK = '0') then
				fs88 <= '0';
			else
				fs88 <= '1';
			end if;
		end if;
		
		if(en_fs44 = '1') then
			if(LRCK = '0') then
				fs44 <= '0';
			else
				fs44 <= '1';
			end if;
		end if;
		
		if(en_fs32 = '1') then
			if(LRCK = '0') then
				fs32 <= '0';
			else
				fs32 <= '1';
			end if;
		end if;
	end if;
end process;

--process (XDSD,fs176,fs88,fs44,fs32) BEGIN
--	if(XDSD = '0') then
--		OSR <= 'Z';
--	elsif(fs176 = '0') then
--		OSR <= '1';
--	elsif(fs88 = '0') then
--		OSR <= 'Z';
--	elsif(fs44 = '0') then
--		OSR <= '0';
--	elsif(fs32 = '0') then
--		OSR <= '0';
--	end if;
--end process;

process (CLK_SEL,fs176,fs88) begin
	if(CLK_SEL = '1') then
		if(fs88 = '0') then
			ov96K <= '1';
		elsif(fs176 = '0') then
			ov96K <= '1';
		else
			ov96K <= '0';
		end if;
	else
		if(fs176 = '0') then
			ov96K <= '1';
		else
			ov96K <= '0';
		end if;
	end if;
end process;
	
end RTL;
			
				