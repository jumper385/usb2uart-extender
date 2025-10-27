library ieee;
use ieee.std_logic_1164.all;

entity top is
	port (
		rst_n_i : in std_logic;
		clk_100_i : in std_logic;
		clk_60_i : in std_logic;

		uart_rx_i : in std_logic;
		uart_tx_o : out std_logic;

		usb_main_dp : inout std_logic;
		usb_main_dn : inout std_logic;
		usb_main_ls : out std_logic;
		usb_main_host : out std_logic;

		led_g_o : out std_logic;
		led_b_o : out std_logic;

		align_tx_o : out std_logic;
		align_rx_o : out std_logic;
		lt_sel_mode_i : in std_logic -- used to invert rx signal input
	);
end top;

architecture rtl of top is

	  component usb_serial_top is
    generic (
      DEBUG : string := "FALSE"
    );
    port (
      rstn          : in    std_logic;
      clk           : in    std_logic;

      -- USB pins/control
      usb_dp_pull   : out   std_logic;
      usb_dp        : inout std_logic;
      usb_dn        : inout std_logic;

      -- status / reset out
      usb_rstn      : out   std_logic;

      -- CDC RX (host -> device)
      recv_data     : out   std_logic_vector(7 downto 0);
      recv_valid    : out   std_logic;

      -- CDC TX (device -> host)
      send_data     : in    std_logic_vector(7 downto 0);
      send_valid    : in    std_logic;
      send_ready    : out   std_logic;

      -- debug (optional)
      debug_en      : out   std_logic;
      debug_data    : out   std_logic_vector(7 downto 0);
      debug_uart_tx : out   std_logic
    );
  end component;

	component UART is
		generic (
			CLK_FREQ     : integer := 60_000_000;
			BAUD_RATE : INTEGER := 115200;
			PARITY_BIT : STRING := "none";
			USE_DEBOUNCER : BOOLEAN := True
		);
		port (
			CLK : in STD_LOGIC;
			RST : in STD_LOGIC;
			UART_TXD : out STD_LOGIC;
			UART_RXD : in STD_LOGIC;
			DIN : in STD_LOGIC_VECTOR(7 downto 0);
			DIN_VLD : in STD_LOGIC;
			DIN_RDY : out STD_LOGIC;
			DOUT : out STD_LOGIC_VECTOR(7 downto 0);
			DOUT_VLD : out STD_LOGIC;
			FRAME_ERROR : out STD_LOGIC;
			PARITY_ERROR : out STD_LOGIC
		);
	end component UART;

  signal usb_dp_pull_s : std_logic;
  signal usb_rstn_s    : std_logic;

	signal uart_din_s : std_logic_vector(7 downto 0);
	signal uart_dout_s : std_logic_vector(7 downto 0);
  signal uart_rx_valid_s  : std_logic;
	signal uart_tx_valid_s : std_logic;
	signal uart_rx_rdy_s : std_logic;
	signal clk_25_s : std_logic;
	signal counter : integer;
	signal uart_tx_rdy: std_logic;

	signal tctr : integer;
	signal uart_rx_s : std_logic;

begin

	proc_uart_dec: process(uart_rx_i, lt_sel_mode_i)
	begin
		-- invert uart signal if in LT Attachement Mode
		if (lt_sel_mode_i = '1') then
			uart_rx_s <= not uart_rx_i;
			led_b_o <= '1';
		else
			uart_rx_s <= uart_rx_i;
			led_b_o <= '0';
		end if;
	end process;

  u_usb_serial : usb_serial_top
    port map (
      rstn          => rst_n_i,         -- active-low
      clk           => clk_60_i,        -- 60 MHz

      usb_dp_pull   => usb_dp_pull_s,   -- drive external pull-up circuit if used
      usb_dp        => usb_main_dp,
      usb_dn        => usb_main_dn,

      usb_rstn      => usb_rstn_s,      -- 1=connected, 0=disconnected

      recv_data     => uart_din_s,
      recv_valid    => uart_rx_valid_s,

      send_data     => uart_dout_s,
      send_valid    => uart_tx_valid_s,
      send_ready    => open,            -- ignore backpressure like the example

      debug_en      => open,
      debug_data    => open,
      debug_uart_tx => open        -- routed to your UART TX pin in PCF
    );

	uart_inst: component UART
	port map (
		CLK => clk_60_i,
		RST => not rst_n_i,

		UART_TXD => uart_tx_o,
		UART_RXD => not uart_rx_i,

		DIN => uart_din_s,
		DIN_VLD => uart_rx_valid_s,
		DIN_RDY => uart_tx_rdy,

		DOUT => uart_dout_s,
		DOUT_VLD => uart_tx_valid_s,
		FRAME_ERROR => open,
		PARITY_ERROR => open 
	);

	usb_main_ls <= '0'	;
	usb_main_host <= '1';

	led_g_o <= uart_rx_i;
	align_tx_o <= uart_rx_i;
	align_rx_o <= uart_tx_o;

end architecture;
