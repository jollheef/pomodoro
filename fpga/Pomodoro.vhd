-- @file main.go
-- @author Mikhail Klementyev jollheef<AT>riseup.net
-- @license GNU GPLv3
-- @date July, 2016
-- @brief Pomodoro timer
-- Use with caution, because the project is developed for education purposes.

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity Pomodoro is
	port (
		clk : in std_logic;
		rst : in std_logic;
		dataout : out std_logic_vector(7 downto 0);
		en : out std_logic_vector(7 downto 0);
		btn : in std_logic_vector(7 downto 0);
		bell : out std_logic
	);
end Pomodoro;

architecture arch of Pomodoro is
	signal div_cnt : std_logic_vector(24 downto 0 );
	signal data4 : std_logic_vector(3 downto 0);
	signal dataout_xhdl1 : std_logic_vector(7 downto 0);
	signal en_xhdl : std_logic_vector(7 downto 0);
	signal cntfirst : std_logic_vector(3 downto 0);
	signal cntsecond : std_logic_vector(3 downto 0);
	signal cntthird : std_logic_vector(3 downto 0);
	signal cntlast : std_logic_vector(3 downto 0);
	signal first_over : std_logic;
	signal second_over : std_logic;
	signal third_over : std_Logic;
	signal last_over : std_logic;

	signal relax : std_logic;
	signal switch1, switch2, switch3 : std_logic;

	signal silent : std_logic;
	signal switch4, switch5, switch6 : std_logic;

	signal bell_tmp : std_logic;
begin
	dataout <= dataout_xhdl1;
	en <= en_xhdl;
	bell <= bell_tmp;

-- Alert if 4600+ for work and 1500+ for relax
process (clk, rst, cntthird, cntlast)
begin
	if (rst = '0' or silent = '0') then
		bell_tmp <= '1';
	elsif rising_edge(clk) then
		if ((relax = '1' and cntlast = "0100" and cntthird = "0110") or
		    (relax = '0' and cntlast = "0001" and cntthird = "0101")) then
			bell_tmp <= not bell_tmp;
		else
			bell_tmp <= '1';
		end if;
	end if;
end process;

process(clk, btn)
begin
	if rising_edge(clk) then
		switch1 <= btn(0);
		switch2 <= switch1;
		switch3 <= switch2;

		switch4 <= btn(7);
		switch5 <= switch4;
		switch6 <= switch5;
	end if;
end process;

relax <= switch1 and switch2 and switch3;
silent <= switch4 and switch5 and switch6;

process (clk, rst)
begin
	if (rst = '0') then
		div_cnt <= "0000000000000000000000000";
	elsif (clk'EVENT and clk = '1') then
		div_cnt <= div_cnt + 1;
	end if;
end process;

process (div_cnt(24), rst, last_over)
begin
	if (rst = '0') then
		cntfirst <= "0000";
		first_over <= '0';
	elsif (div_cnt(24)'EVENT and div_cnt(24) = '1') then
		if (cntfirst = "1001" or last_over = '1') then
			cntfirst <= "0000";
			first_over <= '1';
		else
			first_over <= '0';
			cntfirst <= cntfirst + 1;
		end if;
	end if;
end process;

process (first_over, rst)
begin
	if (rst = '0') then
		cntsecond <= "0000";
		second_over <= '0';
	elsif (first_over'EVENT and first_over = '1') then
		if (cntsecond = "1001") then
			cntsecond <= "0000";
			second_over <= '1';
		else
			second_over <= '0';
			cntsecond <= cntsecond + 1;
		end if;
	end if;
end process;

process (second_over, rst)
begin
	if (rst = '0') then
		cntthird <= "0000";
		third_over <= '0';
	elsif (second_over'EVENT and second_over = '1') then
		if (cntthird = "1001") then
			cntthird <= "0000";
			third_over <= '1';
		else
			third_over <= '0';
			cntthird <= cntthird + 1;
		end if;
	end if;
end process;

process (third_over, rst)
begin
	if (rst = '0') then
		cntlast <= "0000";
		last_over <= '0';
	elsif (third_over'EVENT and third_over = '1') then
		if (cntlast = "1001") then
			cntlast <= "0000";
			last_over <= '1';
		else
			last_over <= '0';
			cntlast <= cntlast + 1;
		end if;
	end if;
end process;

process (rst, clk, div_cnt(19 downto 18))
begin
	if (rst = '0') then
		en_xhdl <= "11111110";
	elsif (clk'EVENT and clk = '1') then
		if (relax = '1') then
			case div_cnt(19 downto 18) is
				when"00" => en_xhdl <= "11111110";
				when"01" => en_xhdl <= "11111101";
				when"10" => en_xhdl <= "11111011";
				when"11" => en_xhdl <= "11110111";
			end case;
		else
			case div_cnt(19 downto 18) is
				when"00" => en_xhdl <= "11101111";
				when"01" => en_xhdl <= "11011111";
				when"10" => en_xhdl <= "10111111";
				when"11" => en_xhdl <= "01111111";
			end case;
		end if;
	end if;
end process;

process (en_xhdl, cntfirst, cntsecond, cntthird, cntlast)
begin
	case en_xhdl is
		when "11111110" => data4 <= cntfirst;
		when "11111101" => data4 <= cntsecond;
		when "11111011" => data4 <= cntthird;
		when "11110111" => data4 <= cntlast;
		when "11101111" => data4 <= cntfirst;
		when "11011111" => data4 <= cntsecond;
		when "10111111" => data4 <= cntthird;
		when "01111111" => data4 <= cntlast;
		when others => data4 <= "1010";
	end case;
end process;

process (data4)
begin
	case data4 is
		when "0000" =>
			dataout_xhdl1 <= "11000000";
		when "0001" =>
			dataout_xhdl1 <= "11111001";
		when "0010" =>
			dataout_xhdl1 <= "10100100";
		when "0011" =>
			dataout_xhdl1 <= "10110000";
		when "0100" =>
			dataout_xhdl1 <= "10011001";
		when "0101" =>
			dataout_xhdl1 <= "10010010";
		when "0110" =>
			dataout_xhdl1 <= "10000010";
		when "0111" =>
			dataout_xhdl1 <= "11111000";
		when "1000" =>
			dataout_xhdl1 <= "10000000";
		when "1001" =>
			dataout_xhdl1 <= "10010000";
		when "1010" =>
			dataout_xhdl1 <= "10000000";
		when "1011" =>
			dataout_xhdl1 <= "10010000";
		when "1100" =>
			dataout_xhdl1 <= "01100011";
		when "1101" =>
			dataout_xhdl1 <= "10000101";
		when "1110" =>
			dataout_xhdl1 <= "01100001";
		when "1111" =>
			dataout_xhdl1 <= "01110001";
		when others =>
			dataout_xhdl1 <= "00000011";
	end case;
end process;
end arch;
