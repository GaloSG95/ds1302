-- Project      : 
-- Design       : 
-- Verification : 
-- Reviewers    : 
-- Module       : ds1302_ctrl.vhdl
-- Parent       : none
-- Children     : none
-- Description  :

LIBRARY ieee;

USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY ds1302_ctrl IS
    PORT (
        clk     : IN    STD_LOGIC;
        rst     : IN    STD_LOGIC;
        sclk    : out   std_logic;
        ce      : out   std_logic;
        i_buff  : out   std_logic;  -- write with t = 0
        o_buff  : in    std_logic;  -- read with t = 1
        t_buff  : out   std_logic;  -- enable to read
        -- controller interface
        start   : in    std_logic;
        rw      : in    std_logic;
        addr    : in    std_logic_vector(4 downto 0);
        din     : in    std_logic_vector(7 downto 0);
        dout    : out   std_logic_vector(7 downto 0);
        dvalid  : out   std_logic;
        busy    : out   std_logic);
END ENTITY ds1302_ctrl;

ARCHITECTURE serial_communication OF ds1302_ctrl IS
    -- constants
    CONSTANT SCLK_PERIOD        : UNSIGNED(4 DOWNTO 0)          := "11001";      -- d'25
    CONSTANT FULL_MES_LENGTH    : unsigned                      := "1111";
    CONSTANT COMMAND_LENGTH     : unsigned                      := "1000";
    -- types
    TYPE state_type IS (IDLE_E, COMMAND_E, WRITE_E, READ_E, DONE_E);
    SIGNAL state : state_type;
    -- signals
    SIGNAL sclk_reg             : STD_LOGIC;
    SIGNAL sclk_counter         : UNSIGNED(4 DOWNTO 0);
    SIGNAL dout_reg             : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL dvalid_reg           : STD_LOGIC;
    SIGNAL transition           : STD_LOGIC;                    -- Frequently used condition
    signal command              : std_logic_vector(7 downto 0);
BEGIN
    -- Concurrent Conditional Assignments
    sclk        <= sclk_reg;
    transition  <= '1' WHEN (sclk_counter = SCLK_PERIOD - 1) AND (sclk_reg = '1') ELSE '0';
    command     <= rw & addr & '0' & '1';
    -- SPI CLOCK GENERATOR 1 MHz
    sclk_gen : PROCESS (clk, rst)
    BEGIN
        IF rst = '1' THEN
            sclk_counter <= (OTHERS => '0');
            sclk_reg <= '0';
        ELSIF rising_edge(clk) THEN
            IF sclk_counter >= SCLK_PERIOD - 1 THEN
                sclk_counter <= (OTHERS => '0');
                sclk_reg <= NOT sclk_reg;
            ELSE
                sclk_counter <= sclk_counter + 1;
            END IF;
        END IF;
    END PROCESS;

    state_machine : PROCESS (clk, rst)
        VARIABLE bit_counter : UNSIGNED(3 DOWNTO 0);
        VARIABLE message     : STD_LOGIC_VECTOR(15 DOWNTO 0);
    BEGIN
        IF rst = '1' THEN
            bit_counter := FULL_MES_LENGTH;
            message     := (others => '0');
            ce          <= '0';
            i_buff      <= '0';  -- write with t = 0
            t_buff      <= '0';  -- enable to read
            busy        <= '0';
            dout_reg    <= (others => '0');   
            dvalid_reg  <= '0';
            state       <= IDLE_E;
        ELSIF rising_edge(clk) THEN
            CASE(state) IS
                WHEN IDLE_E =>
                    IF transition = '1' and start = '1' THEN
                        busy    <= '1';
                        message := command & din;
                        ce      <= '1';
                        i_buff  <= message(to_integer(bit_counter));
                        state   <= COMMAND_E;
                    END IF;
                WHEN COMMAND_E =>
                    i_buff <= message(to_integer(bit_counter));
                    IF transition = '1' THEN
                        -- check before count down
                        IF bit_counter = COMMAND_LENGTH THEN
                            if command(7) = '1' then
                                t_buff      <= '1';
                                state       <= READ_E;
                            else
                                state       <= WRITE_E;
                            end if;
                        END IF;
                        -- count down
                        bit_counter := bit_counter - 1;
                    END IF;
                WHEN WRITE_E =>
                    i_buff <= message(to_integer(bit_counter));
                    IF transition = '1' THEN
                        IF bit_counter = "0000" THEN
                            state       <= DONE_E;
                            bit_counter := FULL_MES_LENGTH;
                        ELSE
                            bit_counter := bit_counter - 1;
                        END IF;
                    END IF;
                WHEN READ_E =>
                    IF transition = '1' THEN
                        message(7 downto 0) := o_buff & message(7 downto 1);
                        IF bit_counter = "0000" THEN
                            dout_reg    <= message(7 downto 0);
                            dvalid_reg  <= '1';
                            state       <= DONE_E;
                            bit_counter := FULL_MES_LENGTH;
                        ELSE
                            bit_counter := bit_counter - 1;
                        END IF;
                    END IF;
                WHEN DONE_E =>
                    ce      <= '0';
                    busy    <= '0';
                    t_buff  <= '0'; 
                    IF transition = '1' THEN
                        dvalid_reg  <= '0';
                        state       <= IDLE_E;
                    END IF;
                WHEN OTHERS => -- fault recovery
                    state <= IDLE_E;
            END CASE;
        END IF;
    END PROCESS;

    dout_reg_proc : PROCESS (clk, rst)
    BEGIN
        IF rst = '1' THEN
            dout    <= (others => '0');
            dvalid  <= '0';
        ELSIF rising_edge(clk) THEN
            dvalid <= dvalid_reg;
            IF dvalid_reg = '1' THEN
                dout <= dout_reg;
            END IF;
        END IF;
    END PROCESS;
END ARCHITECTURE;