-- Import the necessary libraries
library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.ALL;

-- Declare entity
entity tb_game_controller is
end tb_game_controller;

architecture behaviour of tb_game_controller is
-- Component declaration of Device Under Test (DUT)
	component game_controller is
		Port (
			clk             : in std_logic; -- Clock for the system
		        rst             : in std_logic; -- Resets the state machine
		
		        -- Inputs
		        shoot           : in std_logic; -- User shoot
		        move_left       : in std_logic; -- User left
		        move_right      : in std_logic; -- User right
				  
			pixel_x         : in integer; -- X position of the cursor
			pixel_y		: in integer; -- Y position of the cursor
			ship_hit_fsm	: in integer;
	        
			-- Outputs
		        pixel_color		: out std_logic_vector (2 downto 0)
		);
	end component;

	-- Inputs
	signal clk_in		: std_logic;
	signal rst_in		: std_logic;
	signal shoot_in		: std_logic;
	signal move_left_in	: std_logic;
	signal move_right_in	: std_logic;
	signal pixel_x_in	: integer;
	signal pixel_y_in	: integer;
	signal ship_hit_fsm_in 	: integer;

	-- Outputs
	signal pixel_color_out	: std_logic_vector (2 downto 0);

	-- Helpers
	constant clk_period : time := 10 ns;
	type state is (init, pre_game, gameplay, game_over);
	type alien_array is array(59 downto 0) of integer;

begin

	game_controller_instance : game_controller
	port map (
		clk => clk_in,
		rst => rst_in,
		shoot => shoot_in,
		move_left => move_left_in,
		move_right => move_right_in,
		pixel_x => pixel_x_in,
		pixel_y => pixel_y_in,
		ship_hit_fsm => ship_hit_fsm_in,
		pixel_color => pixel_color_out
		
	);

	-- This process creates a clock signal
	clk_process: process
	begin
		clk_in <= '0';
		wait for clk_period/2;
		clk_in <= '1';
		wait for clk_period/2;
	end process;

	-- This initializes the system by holding the reset high for 2 clock periods
	initialize: process
	begin
		wait for clk_period;
		rst_in <= '1';
		wait for clk_period;
		rst_in <= '0';
		wait for clk_period;
	end process;

	-- This is the actual unit test
	test: process

	alias tb_current_state: state is <<signal game_controller_instance.current_state : state>>;
	alias tb_score: integer is <<signal game_controller_instance.score : integer>>;
	alias tb_aliens_y_pos: integer is <<signal game_controller_instance.aliens(0).y_pos : integer>>;

	begin
		assert tb_current_state = init report "Error" severity Error;

		-- init passes straight into pre_game
		wait for clk_period*2;
		assert tb_current_state = pre_game report "Error" severity Error;

		wait for clk_period;   -- reset

		-- Pre_game passes into gameplay when shoot is pressed
		shoot_in <= '1';
		wait for clk_period;
		assert tb_current_state = gameplay report "Error" severity Error;

		shoot_in <= '0';   -- reset
		wait for clk_period;

		-- check that gameplay passes into game_over when aliens are all dead
		tb_score <= 60;
		wait for clk_period;
		assert tb_current_state = game_over report "Error" severity Error;

		tb_score <= 0;				-- reset
		tb_current_state <= init;
		wait for clk_period*3;
		shoot_in <= '1';
		wait for clk_period*2;
		shoot_in <= '0';
		wait for clk_period;
		
		-- check that gameplay passes into game_over when aliens reach bottom
		tb_aliens_y_pos <=  500;			
		wait for clk_period;
		assert tb_current_state = game_over report "Error" severity Error;
		wait for clk_period;

		tb_score <= 0;				-- reset
		tb_current_state <= init;
		wait for clk_period*3;
		shoot_in <= '1';
		wait for clk_period*2;
		shoot_in <= '0';
		wait for clk_period;

		-- Check that gameplay passes into game_over when ship is hit

		tb_ship_hit_fsm <= 1;
		wait for clk_period;
		assert tb_current_state = game_over report "Error" severity Error;
		wait for clk_period;

		-- check that game_over passes into init when shoot is pressed

		tb_aliens_y_pos <= 0;
		shoot_in <= '1';
		wait for clk_period;

		tb_aliens_y_pos <= 0;
		shoot_in <= '1';
		wait for clk_period;
		
		assert tb_current_state = init report "Error" severity Error;

		-- Stop the simulation
		assert false report "Game controller test success!" severity failure;
	end process;
end behaviour;
