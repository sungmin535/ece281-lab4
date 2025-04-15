library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


-- Lab 4
entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(15 downto 0);
        btnU    :   in std_logic; -- master_reset
        btnL    :   in std_logic; -- clk_reset
        btnR    :   in std_logic; -- fsm_reset
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is

    -- signal declarations

    signal slow_clk : std_logic;
    signal s_clk : std_logic;
    signal seg_count : unsigned(16 downto 0) := (others => '0');
    signal floor1, floor2 : std_logic_vector(3 downto 0);
    signal disp_val : std_logic_vector(3 downto 0);
    signal disp_sel : std_logic_vector(3 downto 0);
    signal reset_clk, reset_fsm : std_logic;
    constant UNUSED : std_logic_vector(3 downto 0) := "1111";
    constant SEG_LIMIT : natural := 50000;
    constant CLK_DIV   : natural := 25000000;
    
	-- component declarations
	
	component sevenseg_decoder is
        port(
            i_Hex : in std_logic_vector(3 downto 0);
            o_seg_n : out std_logic_vector(6 downto 0)
        );
    end component;
    
    component elevator_controller_fsm is
        port(
            i_clk : in std_logic;
            i_reset : in std_logic;
            is_stopped : in std_logic;
            go_up_down : in std_logic;
            o_floor : out std_logic_vector(3 downto 0)
        );
    end component;
    
    component TDM4 is
        generic (k_WIDTH : natural := 4 );
        port(
            i_clk : in std_logic;
            i_reset : in std_logic;
            i_D3 : in std_logic_vector(k_WIDTH-1 downto 0);
            i_D2 : in std_logic_vector(k_WIDTH-1 downto 0);
            i_D1 : in std_logic_vector(k_WIDTH-1 downto 0);
            i_D0 : in std_logic_vector(k_WIDTH-1 downto 0);
            o_data : out std_logic_vector(k_WIDTH-1 downto 0);
            o_sel : out std_logic_vector(3 downto 0)
        );
    end component;
    
    component clock_divider is
        generic ( k_DIV : natural := 25000000 );
        port(
            i_clk : in std_logic;
            i_reset : in std_logic;
            o_clk : out std_logic
        );
    end component;
    
begin
    reset_clk <= btnU or btnL;
    reset_fsm <= btnU or btnR;
    
    clk_div_inst: clock_divider
        generic map (k_DIV => CLK_DIV)
        port map(
            i_clk => clk,
            i_reset => reset_clk,
            o_clk => slow_clk
        );
    
    process(clk)
    begin
        if rising_edge(clk) then
            if seg_count = to_unsigned(SEG_LIMIT -1, 17) then
                seg_count <= (others => '0');
                s_clk <= not s_clk;
            else
                seg_count <= seg_count + 1;
            end if;
        end if;
    end process;
    
    fsm1: elevator_controller_fsm
        port map(
            i_clk => slow_clk,
            i_reset => reset_fsm,
            is_stopped => sw(0),
            go_up_down => sw(1),
            o_floor => floor1
        );
    
    fsm2: elevator_controller_fsm
        port map(
            i_clk => slow_clk,
            i_reset => reset_fsm,
            is_stopped => sw(14),
            go_up_down => sw(15),
            o_floor => floor2
        );
    
    tdm_inst: TDM4
        generic map ( k_WIDTH => 4 )
        port map(
            i_clk => s_clk,
            i_reset => btnU,
            i_D3 => UNUSED,
            i_D2 => floor2,
            i_D1 => UNUSED,
            i_D0 => floor1,
            o_data => disp_val,
            o_sel => disp_sel
        );
    
    seg_dec_inst: sevenseg_decoder
        port map(
            i_Hex => disp_val,
            o_seg_n => seg
        );
    
    an <= disp_sel;
    
    led(15) <= slow_clk;
    led(3 downto 0) <= floor1;
    led(7 downto 4) <= floor2;
    led(14 downto 8) <= (others => '0');
    
end top_basys3_arch;
