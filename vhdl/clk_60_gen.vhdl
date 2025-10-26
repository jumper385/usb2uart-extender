library ieee;
use ieee.std_logic_1164.all;

entity clk_60_gen is
	port (
		rst_n_i : in std_logic;
		clk_100_i : in std_logic;
		clk_60_o : out std_logic
	);
end entity clk_60_gen;

architecture rtl of clk_60_gen is

	component SB_PLL40_CORE is
		generic (
			FEEDBACK_PATH : string := "SIMPLE";
			PLLOUT_SELECT : string := "GENCLK";
			DIVR : integer := 4; -- 100 -> 60 MHz
			DIVF : integer := 47;
			DIVQ : integer := 4;
			FILTER_RANGE : integer := 4
		);
		port (
			REFERENCECLK : in std_logic;
			PLLOUTCORE : out std_logic;
			PLLOUTGLOBAL : out std_logic;
			EXTFEEDBACK : in std_logic;
			DYNAMICDELAY : in std_logic_vector(7 downto 0);
			LOCK : out std_logic;
			BYPASS : in std_logic;
			RESETB : in std_logic
			-- EXTFEDBACK / dynamic delay pins omitted (unused)
		);
	end component SB_PLL40_CORE;

	signal clk_60_core : std_logic;

begin

	u_pll_100_to_60: component SB_PLL40_CORE
	generic map (
		FEEDBACK_PATH => "SIMPLE",
		PLLOUT_SELECT => "GENCLK",
		DIVR => 4, -- (100 MHz)/(4+1) = 20 MHz pre, see formula
		DIVF => 47, -- (47+1) = 48
		DIVQ => 4, -- /16 -> 20*48/16 = 60 MHz
		FILTER_RANGE => 4
	)
	port map (
		REFERENCECLK => clk_100_i,
		PLLOUTCORE => clk_60_core, -- local fabric
		PLLOUTGLOBAL => open, -- global clock tree
		EXTFEEDBACK => '0',
		DYNAMICDELAY => "00000000",
		LOCK => open,
		BYPASS => '0',
		RESETB => rst_n_i -- active-low reset (1 = run)
	);

	clk_60_o <= clk_60_core;

end architecture rtl;
