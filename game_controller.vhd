-----------------------------------
-- Author: Shabbir Hussain
-- Email: shabbir.hussain@mail.mcgill.ca
-- Description: This entity implements the Finite State Machine
--              that will control the game
-----------------------------------

-- Import the necessary libraries
library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.ALL;


-- Declare entity
entity game_controller is
    Generic(

			-----------GRAPHICS-----------------------
		
			LETTER_WIDTH        : integer := 8;
			SPRITE_WIDTH	    : integer := 32;
			SPRITE_HEIGHT	    : integer := 16;
			
			BULLET_SIZE        : integer := 8;
			
			SCORE_LETTER_HEIGHT  : integer := 16;
			SCORE_VALUE_HEIGHT   : integer := 32;
			
			
			ALIEN_HEIGHT_TOP  	: integer := 80;
			ALIEN_HEIGHT_BOTTOM : integer := 432;
			
			SHIP_HEIGHT   : integer := 448;
			DIV_HEIGHT	  : integer := 458;
			LIVES_HEIGHT  : integer := 480;	
			
			ROW_MSB		  : integer := 3;
			ROW_LSB       : integer := 1;
			COL_MSB       : integer := 4;
			COL_LSB       : integer := 1;			

         SCREEN_WIDTH  : integer := 640;
         SCREEN_HEIGHT : integer := 480;		


			---------------GAMEPLAY----------------------

			ADDRESS_WIDTH 		: integer := 3;				
			ALIEN_MOVE_DELAY 	: integer := 8;
			ALIEN_DOWN_DELAY 	: integer := 8;
         NUM_ALIENS    		: integer := 60   

           );
    Port (
        clk             : in std_logic; -- Clock for the system
        rst             : in std_logic; -- Resets the state machine

        -- Inputs
        shoot           : in std_logic; -- User shoot
        move_left       : in std_logic; -- User left
        move_right      : in std_logic; -- User right
		  
		  pixel_x         : in integer; -- X position of the cursor
		  pixel_y		   : in integer; -- Y position of the cursor
        
		  -- Outputs
        pixel_color		: out std_logic_vector (2 downto 0);
		  current_state_num: out std_logic_vector (2 downto 0)
         
         );
end game_controller;

architecture behaviour of game_controller is

	-- Declare sprite rom, Declared using insert Template
	component sprite_rom
	generic ( addrwidth : integer := 6; datawidth : integer := 16 );
	port
	(
		clk			:	 in std_logic;
		sprite_addr		:	 in std_logic_vector(2 downto 0);
		sprite_row		:	 in std_logic_vector(2 downto 0);
		sprite_col		:	 in std_logic_vector(3 downto 0);
		sprite_bit		:	 out std_logic
	);
	end component;

    component clock_divider is
    generic ( slow_factor : integer := 5000000 );
    Port (
        clk             : in std_logic; -- Clock for the system
        slow_clk        : out std_logic -- Slow clock value
         );
    end component;

	 -- This procedure maps a Base 10 digit onto the screen
	 procedure draw_digit ( x,score,digit_offset: in integer; 
									sprite_addr: out std_logic_vector(2 downto 0); 
									sprite_col : out std_logic_vector (3 downto 0) ) is
	 variable LSB : integer;
	 variable temp_col : std_logic_vector(31 downto 0);
	 begin
			 LSB := score mod 10;
			 case LSB is
				when 0 =>
					sprite_addr := "010";
					temp_col := std_logic_vector(to_unsigned((x - digit_offset), 32));
					sprite_col := temp_col(COL_MSB downto COL_LSB);
				when 1 =>
					sprite_addr := "010";
					temp_col := std_logic_vector(to_unsigned((x - digit_offset+LETTER_WIDTH), 32));
					sprite_col := temp_col(COL_MSB downto COL_LSB);

				when 2 =>
					sprite_addr := "010";
					sprite_addr := "010";
					temp_col := std_logic_vector(to_unsigned((x - digit_offset+LETTER_WIDTH*3), 32));
					sprite_col := temp_col(COL_MSB downto COL_LSB);
					
				when 4 =>
					sprite_addr := "011";
					temp_col := std_logic_vector(to_unsigned((x - digit_offset), 32));
					sprite_col := temp_col(COL_MSB downto COL_LSB);
					
					temp_col := std_logic_vector(to_unsigned((x - digit_offset+LETTER_WIDTH*2), 32));
					sprite_col := temp_col(COL_MSB downto COL_LSB);

				when 3 =>
				when 5 =>
					sprite_addr := "011";
					temp_col := std_logic_vector(to_unsigned((x - digit_offset+LETTER_WIDTH), 32));
					sprite_col := temp_col(COL_MSB downto COL_LSB);
				when 6 =>
					sprite_addr := "011";
					temp_col := std_logic_vector(to_unsigned((x - digit_offset+LETTER_WIDTH*2), 32));
					sprite_col := temp_col(COL_MSB downto COL_LSB);
				when 7 =>
					sprite_addr := "011";
					temp_col := std_logic_vector(to_unsigned((x - digit_offset+LETTER_WIDTH*3), 32));
					sprite_col := temp_col(COL_MSB downto COL_LSB);
				when 8 => 
					sprite_addr := "100";
					temp_col := std_logic_vector(to_unsigned((x - digit_offset), 32));
					sprite_col := temp_col(COL_MSB downto COL_LSB);
				when 9 =>
					sprite_addr := "100";
					temp_col := std_logic_vector(to_unsigned((x - digit_offset+LETTER_WIDTH), 32));
					sprite_col := temp_col(COL_MSB downto COL_LSB);
				when others =>
					sprite_addr := "010";
					temp_col := std_logic_vector(to_unsigned((x - digit_offset), 32));
					sprite_col := temp_col(COL_MSB downto COL_LSB);
			 end case;
	 end procedure draw_digit;

	 -- Signals to access the ROM
	 signal sprite_addr 	:	 std_logic_vector(2 downto 0);
	 signal sprite_row		:	 std_logic_vector(2 downto 0);
	 signal sprite_col		:	 std_logic_vector(3 downto 0);
	 signal sprite_bit		:	 std_logic;

     -- Signal to access the slow clk
     signal slow_clk    : std_logic;

    -- A record is a composite of multiple types
    type sprite is
        record
            x_pos      : integer;
            y_pos      : integer;
            -- Width = 16 px
            -- Height = 8 px
            visible    : std_logic;
        end record;

    -- Declare all the sprites
    signal ship : sprite;

    signal ship_bullet : sprite;

    type alien_array is array(NUM_ALIENS-1 downto 0) of sprite;
    signal aliens : alien_array;

	
    signal alien_bullet : sprite;

    type state is ( init, pre_game, gameplay, game_over);

    -- Declare game variables
	 signal ship_hit_fsm : integer;
	 signal lives_fsm : integer;
    signal score : integer; -- Max 9999
    signal aliens_move_right : std_logic;
	 signal aliens_move_down : std_logic;
    signal current_state : state;
	-- signal score_reg : integer;


    signal row_color : std_logic_vector(2 downto 0);
	 
	 

begin
	
	-- map signals
	sprite_rom_inst : sprite_rom
	port map(
		clk => clk,
		sprite_addr => sprite_addr,	
		sprite_row => sprite_row,	 
		sprite_col => sprite_col,		
		sprite_bit => sprite_bit		
	
	);

    -- Instatiate the clk_div
    clk_div: clock_divider
    port map (
        clk => clk,
        slow_clk => slow_clk
             );

    -- FSM process
    FSM: process(clk,rst)
    begin
        if(rst = '1') then
            current_state <= init;
        elsif rising_edge(clk) then
		      -- Implement an FSM according to the following rules
				-- Start state is init
				-- Init => pregame immediately (ie. init lasts only 1 clock cycle)
				-- pregame => gameplay if shoot button is pressed
				-- gameplay => game_over if aliens reach the bottom, or are all killed
				-- game_over => init if shoot button is pressed
				
			-- MODIFY CASE STATEMENT BELOW TO MATCH THE PRECEDING COMMENTS
            case current_state is
                when init  =>
                     current_state <= pre_game;
							--if(lives_fsm = 0) then
								--lives_fsm <= 3;
							--end if;
                when pre_game =>
							if (shoot = '1') then
								current_state <= gameplay;
							end if;
                when gameplay =>
							for alien in aliens'range loop
								if ((aliens(alien).visible = '1') and (aliens(alien).y_pos = (ALIEN_HEIGHT_BOTTOM))) then	
									--if (lives_fsm  > 0) then
										--lives_fsm <= lives_fsm - 1;
									current_state <= game_over;
								 end if;
								--end if;
							end loop;
						
						   if (alien_bullet.visible = '1') and (alien_bullet.x_pos >= ship.x_pos) and (alien_bullet.x_pos <= ship.x_pos + SPRITE_WIDTH) and (alien_bullet.y_pos >= ship.y_pos) and (alien_bullet.y_pos <= (ship.y_pos + SPRITE_WIDTH)) then
								--if (lives_fsm > 0) then
									--lives_fsm <= lives_fsm - 1;
									ship_hit_fsm <= 1;
									current_state <= game_over;
								--end if;
								--score_reg <= score;
							end if;

							if (score = 60) then		
								current_state <= game_over;
							end if;
							if(ship_hit_fsm = 1) then
								current_state <= game_over;
							end if;
                when game_over =>
							if (shoot = '1') then
								current_state <= init;
							end if;
            end case;
        end if;
    end process;

   
    Update: process(clk, current_state)
	 	 variable alien_index    : integer := 0;
		 variable alien_offset_x : integer := 0;
 		 variable alien_offset_y : integer := 0;
		 variable score_register : integer;
		 variable lives: integer;
		 variable ship_hit: integer;
		
		 
		 variable alien_move_ctr : integer := 0;
		 variable alien_down_ctr : integer := 0;
		 
		 variable alien_bullet_shift : integer := 0;
		 
		 variable aliens_move_right : std_logic := '1';
		 variable aliens_move_down : std_logic := '0';

    begin
	     if rising_edge(clk) then
			  if (current_state = init) then         
					-- Reset game
					score <= 0;
					lives := 3;
					alien_down_ctr := 0;
					alien_move_ctr := 0;
					aliens_move_right := '1';
					aliens_move_down := '0';

					-- Put ship mid
					ship.x_pos <= 155;
					ship.y_pos <= SHIP_HEIGHT;
					ship.visible <= '1';

					-- Set bullets invisible
					ship_bullet.x_pos <= 0;
					ship_bullet.y_pos <= 0;
					ship_bullet.visible <= '0';

					alien_bullet.x_pos <= 0;
					alien_bullet.y_pos <= 0;
					alien_bullet.visible <= '0';

					-- Place aliens in grid
					-- 5 rows
					alien_index := 0;
					alien_offset_x := 0;
					alien_offset_y := ALIEN_HEIGHT_TOP;
					for i in 0 to 4 loop
						 -- 12 columns
						 for j in 0 to 11 loop
							  aliens(alien_index+j).x_pos <= alien_offset_x;
							  aliens(alien_index+j).y_pos <= alien_offset_y;
							  aliens(alien_index+j).visible <= '1';
							  
							  alien_offset_x := alien_offset_x + SPRITE_WIDTH;
							  
						 end loop;
						 alien_offset_x := 0;
						 alien_offset_y := alien_offset_y + SPRITE_HEIGHT;
						 alien_index :=  alien_index + 12;
					end loop;
			  
	 
			  elsif (current_state = gameplay and slow_clk = '1') then
				
				--if(lives > 0) then
					--score <= score_register;
				--end if;

				  --ADD GAME LOGIC HERE. HINTS PROVIDEDS
				alien_move_ctr := alien_move_ctr + 1;  
				  --------------update alien movement counter-------------------------
				if (alien_move_ctr > ALIEN_MOVE_DELAY) then
							
						 alien_move_ctr := 0;
				 
						 if (aliens(11).x_pos >= (SCREEN_WIDTH - SPRITE_WIDTH) and (aliens_move_right = '1')) then
							for alien in aliens'range loop
								aliens(alien).y_pos <= aliens(alien).y_pos + SPRITE_HEIGHT;
							end loop;
							aliens_move_right := '0';
							
						 elsif ((aliens(0).x_pos <= SPRITE_WIDTH/2) and (aliens_move_right = '0')) then 
							for alien in aliens' range loop
								aliens(alien).y_pos <= aliens(alien).y_pos + SPRITE_HEIGHT;
							end loop;
							aliens_move_right := '1';
						
						 elsif (aliens_move_right = '0') then
							for alien in aliens'range loop
									aliens(alien).x_pos <= aliens(alien).x_pos - SPRITE_WIDTH;
							end loop;
					
					    elsif (aliens_move_right = '1') then
							for alien in aliens'range loop
								aliens(alien).x_pos <= aliens(alien).x_pos + SPRITE_WIDTH;
							end loop;
							
						 end if;
						
				end if;
				
				--for alien in aliens' range loop
				--if aliens reach bottom, moves aliens back up to top of screen 
					--if ((aliens(alien).visible = '1') and (aliens(alien).y_pos = (ALIEN_HEIGHT_BOTTOM))) then	
						--lives := lives -1;
						--for i in 0 to 4 loop
							-- 12 columns
							--for j in 0 to 11 loop
								--aliens(alien_index+j).x_pos <= alien_offset_x;
								--aliens(alien_index+j).y_pos <= alien_offset_y;
								--alien_offset_x := alien_offset_x + SPRITE_WIDTH;
							  
							--end loop;
							--alien_offset_x := 0;
							--alien_offset_y := alien_offset_y + SPRITE_HEIGHT;
							--alien_index :=  alien_index + 12;
						--end loop;
					--end if;
				--end loop;					
				-- alien_move_ctr divides the clk divider even more such that the aliens are slower than bullets or ship movements
				  
				  -- if(alien_move_ctr > ALIEN_MOVE_DELAY){
				  --		Move aliens either left/right or down
				  -- 
				  --		hint: the following line moves the aliens down. (see for loop above for more hints)
				  --     aliens(alien_index+j).y_pos <= aliens(alien_index+j).y_pos + SPRITE_HEIGHT;
				  --
				  --     hint: the following line moves the aliens to the right
				  --     aliens(alien_index+j).x_pos <= aliens(alien_index+j).x_pos + SPRITE_WIDTH;
				  -- 
				  --     hint: these if statements can be long and have more nested if statements					
				  -- }
				  

				  ----------------------------Update ship------------------------
			   if ((move_left = '1') AND ((ship.x_pos - SPRITE_WIDTH/2) > 0)) then
						ship.x_pos <= ship.x_pos - SPRITE_WIDTH/2;
				end if;	
				if ((move_right = '1') AND ((SCREEN_WIDTH - ship.x_pos - SPRITE_WIDTH/2) > 0)) then
						ship.x_pos <= ship.x_pos + SPRITE_WIDTH/2;
				end if;
			
				  -- if ( the left button is pressed and the ship has room to the left){
				  --		ship.x_pos = ship.x_pos - SPRITE_WIDTH/2;
				  -- else if( the right button is pressed and the ship has room to move to the right){
				  -- 		ship.x_pos = ship.x_pos + SPRITE_WIDTH/2;
				  ---}
			
				  
				  ---------------------------Shoot bullet-----------------------------
				if ((ship_bullet.visible = '0') and (shoot = '1')) then
					ship_bullet.x_pos <= ship.x_pos + SPRITE_WIDTH/2;
					ship_bullet.y_pos <= ship.y_pos;
					ship_bullet.visible <= '1';
					alien_bullet_shift := alien_bullet_shift + 1;
			   end if;
				  
				if (ship_bullet.visible = '1') then
					ship_bullet.y_pos <= ship_bullet.y_pos - BULLET_SIZE;
				end if;
				
				if (ship_bullet.y_pos = ALIEN_HEIGHT_TOP) then
							ship_bullet.visible <= '0';
			   end if;
				  
				  -----------------Alien Shoot Bullet-----------------
				  
			   if (alien_bullet_shift > 60) then
					alien_bullet_shift := 0;
			   end if;
				
				if (shoot = '1' and alien_bullet.visible = '0') then
						alien_bullet.x_pos <= aliens(alien_bullet_shift).x_pos + SPRITE_WIDTH/2;
						alien_bullet.y_pos <= aliens(alien_bullet_shift).y_pos;
						alien_bullet.visible <= '1';
				end if;
				
			   if (alien_bullet.visible = '1') then 
						alien_bullet.y_pos <= alien_bullet.y_pos + SPRITE_HEIGHT;
			   end if;
				
			   if (alien_bullet.y_pos >= SCREEN_HEIGHT) then
						alien_bullet.visible <= '0';
				end if;
		
				  
				  ----------------------Check bullet collision-------------------------
			   for alien in aliens'range loop
					--collision for ship bullet
			 		if (aliens(alien).visible = '1' and (ship_bullet.x_pos >= aliens(alien).x_pos) and (ship_bullet.x_pos <= aliens(alien).x_pos + SPRITE_WIDTH) and aliens(alien).y_pos = ship_bullet.y_pos) then 
								ship_bullet.visible <= '0';
								score <= score + 1;
								aliens(alien).visible <= '0';
								ship_bullet.x_pos <= 0;
								ship_bullet.y_pos <= 0;
								--if(lives > 0) then
									--score_register := score;
								--elsif(lives = 0) then
									--score_register := 0;
								--end if;
					end if;
				end loop;
					----------------------------bonus---------------------------
					--collision for alien bullet
				if ((alien_bullet.visible = '1') and (alien_bullet.x_pos >= ship.x_pos) and (alien_bullet.x_pos) <= (ship.x_pos + SPRITE_WIDTH) and (alien_bullet.y_pos >= ship.y_pos) and (alien_bullet.y_pos <= (ship.y_pos + SPRITE_WIDTH))) then
					alien_bullet.visible <= '0';
					alien_bullet.x_pos <= 0;
					alien_bullet.y_pos <= 0;
					ship_bullet.x_pos <= 0;
					ship_bullet.y_pos <= 0;
					ship_bullet.visible <= '0';
					ship_hit := 1;
					--lives_fsm <= lives_fsm - 1;
					--lives := lives - 1;
					--
				end if;
					

		
				end if;
			end if;
    end process;
	 
	
--------------------------------------DRAW SCREEN-------------------------------------------	
     draw: process(clk, rst)
		variable x_std : std_logic_vector(31 downto 0);
		variable y_std : std_logic_vector(31 downto 0);
		variable sprite_addr_formal	:	 STD_LOGIC_VECTOR(2 DOWNTO 0);
		variable sprite_col_formal		:	 STD_LOGIC_VECTOR(3 DOWNTO 0);
		variable sprite_row_temp		:	 STD_LOGIC_VECTOR(31 DOWNTO 0);
		variable sprite_col_temp		:	 STD_LOGIC_VECTOR(31 DOWNTO 0);
		variable alien_index : integer := 0;		
		
		begin
		  -- Draw nothing when rst
	     if rst = '1' then
				sprite_addr <= "000"; -- Addr of S	
				sprite_row <=  "000"; 
				sprite_col <=  "0000";
				row_color <= "000";
				
				sprite_addr_formal := "000";
				sprite_col_formal := "0000";
				
        elsif rising_edge(clk) then
		  		x_std := std_logic_vector(to_unsigned(pixel_x, 32));
				y_std := std_logic_vector(to_unsigned(pixel_y, 32));
				
				-- Draw score letters
				if( pixel_y < SCORE_LETTER_HEIGHT) then
					-- Draw SCORE
				   if (pixel_x < LETTER_WIDTH*4) then		
						row_color <= "111";
						sprite_addr <= "000"; -- Addr of SCOR	
						sprite_row <=  y_std(ROW_MSB downto ROW_LSB); 
						sprite_col <=  x_std(COL_MSB downto COL_LSB);					
						
					elsif (pixel_x < LETTER_WIDTH*8) then
						row_color <= "111";
						sprite_addr <= "001"; -- Addr of E
						sprite_row <=  y_std(ROW_MSB downto ROW_LSB); 
						sprite_col <=  x_std(COL_MSB downto COL_LSB);
					else
						row_color <= "000";				
				   end if;

				-- Draw score value
				elsif (pixel_y < SCORE_VALUE_HEIGHT) then
					row_color <= "111"; -- White
					if (pixel_x < LETTER_WIDTH) then	
						row_color <= "111";
						sprite_row <=  y_std(ROW_MSB downto ROW_LSB);
					   draw_digit ( pixel_x,score/1000,0,sprite_addr_formal,sprite_col_formal);
						sprite_addr <= sprite_addr_formal;
						sprite_col  <= sprite_col_formal;
						
					elsif (pixel_x < LETTER_WIDTH*2) then
						row_color <= "111";
						sprite_row <=  y_std(ROW_MSB downto ROW_LSB);
					   draw_digit ( pixel_x,score/100,LETTER_WIDTH,sprite_addr_formal,sprite_col_formal);
						sprite_addr <= sprite_addr_formal;
						sprite_col  <= sprite_col_formal;

					elsif (pixel_x < LETTER_WIDTH*3) then
						row_color <= "111";
						sprite_row <=  y_std(ROW_MSB downto ROW_LSB);
					   draw_digit ( pixel_x,score/10,LETTER_WIDTH*2,sprite_addr_formal,sprite_col_formal);
						sprite_addr <= sprite_addr_formal;
						sprite_col  <= sprite_col_formal;
						 
					elsif (pixel_x < LETTER_WIDTH*4) then
						row_color <= "111";
						sprite_row <=  y_std(ROW_MSB downto ROW_LSB);
					   draw_digit ( pixel_x,score,LETTER_WIDTH*3,sprite_addr_formal,sprite_col_formal);
						sprite_addr <= sprite_addr_formal;
						sprite_col  <= sprite_col_formal;
						
					else
						row_color <= "000";				
				   end if;

				-- Draw Aliens and bullets
				elsif (pixel_y >= ALIEN_HEIGHT_TOP and pixel_y < ALIEN_HEIGHT_BOTTOM) then
					row_color <= "000";
										
					-- Draw bullet from Alien
					if(pixel_y >= alien_bullet.y_pos and pixel_y < alien_bullet.y_pos+BULLET_SIZE and
					   pixel_x >= alien_bullet.x_pos and pixel_x < alien_bullet.x_pos+BULLET_SIZE) then
						
						row_color <= "111" and (alien_bullet.visible & alien_bullet.visible & alien_bullet.visible); -- White if visible
						sprite_addr <= "111"; -- Addr of bullet	
						sprite_row_temp :=  std_logic_vector(to_unsigned((pixel_x - alien_bullet.y_pos), 32));
						sprite_row <= sprite_row_temp(ROW_MSB downto ROW_LSB);	
						sprite_col_temp :=  std_logic_vector(to_unsigned((pixel_x - alien_bullet.x_pos), 32));
						sprite_col <= sprite_col_temp(COL_MSB downto COL_LSB);
					end if;
					
					-- Draw alien
					if(pixel_y >= aliens(0).y_pos and pixel_y < aliens(59).y_pos + SPRITE_HEIGHT and
				      pixel_x >= aliens(0).x_pos and pixel_x < aliens(11).x_pos+SPRITE_WIDTH) then
						
						alien_index := (((pixel_y-aliens(0).y_pos)/SPRITE_HEIGHT)*12)+(((pixel_x-aliens(0).x_pos)/SPRITE_WIDTH) mod 12);
						row_color <= "010" and (aliens(alien_index).visible & aliens(alien_index).visible & aliens(alien_index).visible); -- Green
						sprite_addr <= "110"; -- Addr of alien	
						sprite_row <=  y_std(ROW_MSB downto ROW_LSB); 
						sprite_col_temp :=  std_logic_vector(to_unsigned((pixel_x - aliens(alien_index).x_pos), 32));
						sprite_col <= sprite_col_temp(COL_MSB downto COL_LSB);
					end if;
					
					-- Draw bullet from Ship
					if(pixel_y >= ship_bullet.y_pos and pixel_y < ship_bullet.y_pos+BULLET_SIZE and
					   pixel_x >= ship_bullet.x_pos and pixel_x < ship_bullet.x_pos+BULLET_SIZE) then
						
						row_color <= "111" and (ship_bullet.visible & ship_bullet.visible & ship_bullet.visible); -- White if visible
						sprite_addr <= "111"; -- Addr of bullet	
						sprite_row_temp :=  std_logic_vector(to_unsigned((pixel_x - ship_bullet.y_pos), 32));
					   sprite_row <= sprite_row_temp(ROW_MSB downto ROW_LSB);	
						sprite_col_temp :=  std_logic_vector(to_unsigned((pixel_x - ship_bullet.x_pos), 32));
						sprite_col <= sprite_col_temp(COL_MSB downto COL_LSB);
					end if;

				-- Draw ship
				elsif (pixel_y >= SHIP_HEIGHT-SPRITE_HEIGHT and pixel_y < SHIP_HEIGHT) then
					if (pixel_x >= ship.x_pos and pixel_x < ship.x_pos + SPRITE_WIDTH) then	
						row_color <= "100";
						sprite_addr <= "101"; -- Addr of ship	
						sprite_row <=  y_std(ROW_MSB downto ROW_LSB); 
						sprite_col_temp :=  std_logic_vector(to_unsigned((pixel_x - ship.x_pos), 32));
						sprite_col <= sprite_col_temp(COL_MSB downto COL_LSB);
					else 
						row_color <= "000"; 
					end if;
					row_color <= "100"; -- Red

				-- Draw dividing line
				elsif (pixel_y > DIV_HEIGHT-4  and pixel_y < DIV_HEIGHT) then
						row_color <= "110";
						sprite_addr <= "000"; -- Addr of 1 bit	
						sprite_row <=  "001"; 
						sprite_col <=  "0001";

            end if;
        end if;
    end process;

    pixel_color <= row_color and (sprite_bit & sprite_bit & sprite_bit);



end behaviour;
