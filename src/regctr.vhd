Library IEEE;
USE IEEE.std_logic_1164.ALL;
USE WORK.ALL;
USE IEEE.std_logic_unsigned.ALL;

ENTITY regctr IS
PORT(
		RESET : IN std_logic;
		CLK : IN std_logic;
		CLK_MSEC : IN std_logic;
		XDSD : IN std_logic;
		DEM0 : IN std_logic;
		DEM1 : IN std_logic;
		SD : IN std_logic;
		SLOW : IN std_logic;
		SSLOW : IN std_logic;
		DSDD : IN std_logic;
		SC0 : IN std_logic;
		SC1 : IN std_logic;
		SC2 : IN std_logic;
		ATT : IN std_logic_vector(7 downto 0);
		CSN : OUT std_logic;
		CCLK : OUT std_logic;
		CDTI : OUT std_logic);
END regctr;

ARCHITECTURE RTL OF regctr IS


signal icclk,d_csn,cen,edge_timer,rstn,ddp,delay_clk_msec : std_logic;
signal regaddrcnt_en : std_logic;
signal dcounter_sys5,icsn,rstdp,vlmbp : std_logic;
signal delay : std_logic_vector(1 downto 0);
signal regd : std_logic_vector(7 downto 0);
signal siftreg : std_logic_vector(15 downto 0);
signal regaddrcnt : std_logic_vector(4 downto 0);
signal counter_sys : std_logic_vector(10 downto 0);
signal rstb : std_logic_vector( 1 downto 0);
signal rstnbit,adpebit : std_logic;

constant counter_sys_val : std_logic_vector(10 downto 0) := "10101100000";
constant regaddrcnt_val : std_logic_vector(4 downto 0) := "10101";
constant adpe : integer := 0;

type states IS ( clear,count1,count2);
signal present_state: states;
signal next_state: states;

BEGIN

CCLK <= icclk;
CSN <= icsn;

--Generate CSN
process(RESET,CLK) BEGIN
	if(RESET = '0') then
		counter_sys <= "11111111111";
	elsif(CLK'event and CLK='1') then
		if(cen = '1') then
			if(counter_sys = counter_sys_val) then	-- Stereo mode
				counter_sys <= counter_sys;
			else
				counter_sys <= counter_sys + '1';
			end if;
		else
			counter_sys <= "11111111111";
		end if;
	end if;
end process;

process(RESET,CLK) begin
	if(RESET = '0') then
		dcounter_sys5 <= '1';
	elsif(CLK'event and CLK = '1') then
		dcounter_sys5 <= counter_sys(5);
	end if;
end process;

icsn <= counter_sys(5) and dcounter_sys5;

--Generate ICCLK
process(RESET,CLK) begin
	if(RESET = '0') then
		icclk <= '1';
	elsif(CLK'event and CLK='1') then
		if(cen = '1' and counter_sys(5) = '0') then
			icclk <= not icclk;
		else
			icclk <= '1';
		end if;
	end if;
end process;

process(CLK) begin
	if(CLK'event and CLK='1') then
		delay_clk_msec <= clk_msec;
	end if;
end process;

edge_timer <= clk_msec and not delay_clk_msec;

process(CLK) begin
	if(CLK'event and CLK='1') then
		delay(1) <= delay(0);
		delay(0) <= XDSD;
	end if;
end process;

ddp <= delay(1) xor delay(0);

--State machine to generate count enable signal for counter_sys
process(CLK,RESET) begin
	if (RESET = '0') then
		present_state <= clear;
	elsif (CLK'event and CLK = '1') then
		present_state <= next_state;
	end if;
end process;

process(present_state,ddp,delay_clk_msec,counter_sys,edge_timer) begin
	case present_state is
		when clear => 
			cen <= '0';
			rstn <= '1';
			if(ddp = '1' and delay_clk_msec = '1') then
				next_state <= count1;
			elsif(ddp = '0' and edge_timer = '1') then
				next_state <= count2;
			elsif(ddp = '1' and edge_timer = '0') then
				next_state <= count1;
			else
				next_state <= present_state;
			end if;
		when count1 => 
			cen <= '1';
			rstn <= '0';
			if(counter_sys =counter_sys_val) then	--CLK*2*32*22-32=1376
				next_state <= clear;
			else
				next_state <= present_state;
			end if;
		when count2 =>
			cen <= '1';
			rstn <= '1';
			if(counter_sys =counter_sys_val) then	--CLK*2*32*22-32=1376
				next_state <= clear;
			else
				next_state <= present_state;
			end if;
	end case;
end process;

MANUAL : if(adpe /= 1) generate
	process(regaddrcnt,rstdp,rstn) begin
		if(regaddrcnt = "00000") then
			rstdp <= rstn;
		else
			rstdp <= '1';
		end if;
	end process;

	rstnbit <= rstdp;
	adpebit <= '0';
end generate;

AUTO : if(adpe = 1) generate
	process(RESET,CLK) begin
		if RESET='0' then
			rstb <= "00";
		elsif(CLK'event and CLK='1') then
			if edge_timer = '1' then
				if rstb = "10" then
					rstb <= rstb;
				else
					rstb <= rstb + '1';
				end if;
			end if;
		end if;
	end process;

	rstnbit <= rstb(1);
	adpebit <= '1';
end generate;

--Resister address counter enable signal
Process(counter_sys(5 downto 0)) begin
		if(counter_sys(5 downto 0) = "100000") then
			regaddrcnt_en <= '1';
		else
			regaddrcnt_en <= '0';
		end if;
end process;

--Resister address counter
process(RESET,CLK) begin
	if(RESET = '0') then
		regaddrcnt <= "00000";
	elsif(CLK'event and CLK = '1') then
		if(regaddrcnt_en = '1' and cen = '1') then
			if(regaddrcnt = regaddrcnt_val) then
				regaddrcnt <= "00000";
			else
				regaddrcnt <= regaddrcnt + '1';
			end if;
		else
			regaddrcnt <= regaddrcnt;
		end if;
	end if;
end process;

vlmbp <= '0' when XDSD = '1' else DSDD;
			
--Select external jumper status
process(regaddrcnt,rstnbit,SD,DEM1,DEM0,XDSD,SLOW,SSLOW,SC0,SC1,SC2,vlmbp,ATT,adpebit) begin
	if(regaddrcnt = "00000") then
		regd(7) <= '1';	--ACKS ;Auto mode
		regd(6) <= '0';	--EXDF
		regd(5) <= '0';	--ECS
		regd(4) <= '0';
		regd(3) <= '1';	--DIF2
		regd(2) <= '1';	--DIF1
		regd(1) <= '1';	--DIF0
		regd(0) <= rstnbit;	--RSTN
	elsif(regaddrcnt = "00001") then
		regd(7) <= '1';	--DZFE
		regd(6) <= '1';	--DZFM
		regd(5) <= SD;		--SD
		regd(4) <= '0';	--DFS1
		regd(3) <= '1';	--DFS0
		regd(2) <= not DEM1;	--DEM1 ;Default off '0'
		regd(1) <= DEM0;	--DEM0 ;Default off '1'
		regd(0) <= '0';	--SMUTE
	elsif(regaddrcnt = "00010") then
		regd(7) <= not XDSD;	--DP
		regd(6) <= '0';		--ADP
		regd(5) <= '0';		--DCKS
		regd(4) <= '0';		--DCKB
		regd(3) <= '0';		--MONO
		regd(2) <= '1';		--DZFB
		regd(1) <= '0';		--SELLR
		regd(0) <= not SLOW;		--SLOW
	elsif(regaddrcnt = "00011") then
		regd <= ATT;	--ATT(7:0)
	elsif(regaddrcnt = "00100") then
		regd <= ATT;	--ATT(7:0)
	elsif(regaddrcnt = "00101") then
		regd(7) <= '0';	--INVL
		regd(6) <= '0';	--INVR
		regd(5) <= '0';
		regd(4) <= '0';
		regd(3) <= '0';
		regd(2) <= '0';
		regd(1) <= '1';	--DFS2
		regd(0) <= not SSLOW;	--SSLOW
	elsif(regaddrcnt = "00110") then
		regd(7) <= '1';	--DDM
		regd(6) <= '1';	--DML
		regd(5) <= '1';	--DMR
		regd(4) <= '0';	--DDMOE
		regd(3) <= '0';	--DDMT1
		regd(2) <= '0';	--DDMT0
		regd(1) <= vlmbp;	--DSDD
		regd(0) <= '0';	--DSDSEL0
	elsif(regaddrcnt = "00111") then
		regd(7) <= '0';
		regd(6) <= '0';
		regd(5) <= '0';
		regd(4) <= '0';
		regd(3) <= '0';	--GC2
		regd(2) <= '0';	--GC1
		regd(1) <= '0';	--GC0
		regd(0) <= '0';	--SYNCE
	elsif(regaddrcnt = "01000") then
		regd(7) <= '0';
		regd(6) <= '0';
		regd(5) <= '0';
		regd(4) <= '0';
		regd(3) <= '0';
		regd(2) <= not SC2;	--SC2
		regd(1) <= not SC1;	--SC1
		regd(0) <= not SC0;	--SC0
	elsif(regaddrcnt = "01001") then
		regd(7) <= '0';
		regd(6) <= '0';
		regd(5) <= '0';
		regd(4) <= '0';
		regd(3) <= '0';
		regd(2) <= '0';
		regd(1) <= '1';	--DSDF
		regd(0) <= '1';	--DSDSEL1
-- From resister address "0AH" to "15H" is about for ak4493
	elsif(regaddrcnt = "01010") then
		regd(7) <= '0';	--TDM1
		regd(6) <= '0';	--TDM0
		regd(5) <= '0';	--SDS1
		regd(4) <= '0';	--SDS2
		regd(3) <= '0';
		regd(2) <= '1';	--PW
		regd(1) <= '0';
		regd(0) <= '0';
	elsif(regaddrcnt = "01011") then
		regd(7) <= '0';	--ATS1
		regd(6) <= '0';	--ATS0
		regd(5) <= '0';
		regd(4) <= '0';	--SDS0
		regd(3) <= '0';
		regd(2) <= '0';
		regd(1) <= '0';
		regd(0) <= '0';	--TEST
	elsif(regaddrcnt = "01100") then
		regd(7) <= '0';
		regd(6) <= '0';
		regd(5) <= '0';
		regd(4) <= '0';
		regd(3) <= '0';
		regd(2) <= '0';
		regd(1) <= '0';
		regd(0) <= '0';
	elsif(regaddrcnt = "01101") then
		regd(7) <= '0';
		regd(6) <= '0';
		regd(5) <= '0';
		regd(4) <= '0';
		regd(3) <= '0';
		regd(2) <= '0';
		regd(1) <= '0';
		regd(0) <= '0';
	elsif(regaddrcnt = "01110") then
		regd(7) <= '0';
		regd(6) <= '0';
		regd(5) <= '0';
		regd(4) <= '0';
		regd(3) <= '0';
		regd(2) <= '0';
		regd(1) <= '0';
		regd(0) <= '0';
	elsif(regaddrcnt = "01111") then
		regd(7) <= '0';
		regd(6) <= '0';
		regd(5) <= '0';
		regd(4) <= '0';
		regd(3) <= '0';
		regd(2) <= '0';
		regd(1) <= '0';
	elsif(regaddrcnt = "10000") then
		regd(7) <= '0';
		regd(6) <= '0';
		regd(5) <= '0';
		regd(4) <= '0';
		regd(3) <= '0';
		regd(2) <= '0';
		regd(1) <= '0';
	elsif(regaddrcnt = "10001") then
		regd(7) <= '0';
		regd(6) <= '0';
		regd(5) <= '0';
		regd(4) <= '0';
		regd(3) <= '0';
		regd(2) <= '0';
		regd(1) <= '0';
	elsif(regaddrcnt = "10010") then
		regd(7) <= '0';
		regd(6) <= '0';
		regd(5) <= '0';
		regd(4) <= '0';
		regd(3) <= '0';
		regd(2) <= '0';
		regd(1) <= '0';
	elsif(regaddrcnt = "10011") then
		regd(7) <= '0';
		regd(6) <= '0';
		regd(5) <= '0';
		regd(4) <= '0';
		regd(3) <= '0';
		regd(2) <= '0';
		regd(1) <= '0';
	elsif(regaddrcnt = "10100") then
		regd(7) <= '0';
		regd(6) <= '0';
		regd(5) <= '0';
		regd(4) <= '0';
		regd(3) <= '0';
		regd(2) <= '0';
		regd(1) <= '0';
	elsif(regaddrcnt = "10101") then	
		regd(7) <= adpebit;	--ADPE
		regd(6) <= '0';	--ADPT1
		regd(5) <= '0';	--ADPT0
		regd(4) <= '0';
		regd(3) <= '0';
		regd(2) <= '0';
		regd(1) <= '0';
		regd(0) <= '0';
	else
--		regd <= regd;
		regd <= "11111111";
	end if;
end process;

--process(RESET,CLK) begin
--	if(RESET = '0') then
--		chipaddr <= '0';
--	elsif(CLK'event and CLK = '1') then
--		if(cen = '1') then
--			if(AK4490 = '1' and counter_sys ="01001100000") then
--				chipaddr <= '1';
--			elsif(AK4490 ='0' and counter_sys = "01111100000") then
--				chipaddr <= '1';
--			else
--				chipaddr <= chipaddr;
--			end if;
--		else
--			chipaddr <= '0';
--		end if;
--	end if;
--end process;

--Parallel to serial convetor to generate CDTI
process(RESET,CLK) begin
	if(RESET = '0') then
		siftreg <= "1111111111111111";
	elsif(CLK'event and CLK = '1') then
		if(counter_sys(5) = '1') then
			siftreg(15) <= '0';
			siftreg(14) <= '0';
			siftreg(13) <= '1';
			siftreg(12) <= regaddrcnt(4);
			siftreg(11) <= regaddrcnt(3);
			siftreg(10) <= regaddrcnt(2);
			siftreg(9) <= regaddrcnt(1);
			siftreg(8) <= regaddrcnt(0);
			siftreg(7) <= regd(7);
			siftreg(6) <= regd(6);
			siftreg(5) <= regd(5);
			siftreg(4) <= regd(4);
			siftreg(3) <= regd(3);
			siftreg(2) <= regd(2);
			siftreg(1) <= regd(1);
			siftreg(0) <= regd(0);
		else
			if(icclk = '1') then
				siftreg(1) <= siftreg(0);
				siftreg(2) <= siftreg(1);
				siftreg(3) <= siftreg(2);
				siftreg(4) <= siftreg(3);
				siftreg(5) <= siftreg(4);
				siftreg(6) <= siftreg(5);
				siftreg(7) <= siftreg(6);
				siftreg(8) <= siftreg(7);
				siftreg(9) <= siftreg(8);
				siftreg(10) <= siftreg(9);
				siftreg(11) <= siftreg(10);
				siftreg(12) <= siftreg(11);
				siftreg(13) <= siftreg(12);
				siftreg(14) <= siftreg(13);
				siftreg(15) <= siftreg(14);
				CDTI <= siftreg(15);
			else
				siftreg <= siftreg;
			end if;
		end if;
	end if;
end process;

end RTL;