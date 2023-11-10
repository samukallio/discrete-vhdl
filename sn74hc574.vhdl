library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Texas Instruments SN74HC574
-- Octal Transparent D-Type Latches With 3-State Outputs

entity sn74hc574 is
  generic (
    -- Timing requirements (default: VCC = 4.5 V, 25 degrees)
    constant t_w: Time := 16 ns;      -- Clock pulse duration
    constant t_su: Time := 20 ns;     -- Data setup before clock edge
    constant t_h: Time := 5 ns;       -- Data hold after clock edge

    -- Switching characteristics (default: VCC = 4.5 V, CL = 50 pF, 25 degrees)
    constant t_pd: Time := 36 ns;     -- From CLK to any Q
    constant t_en: Time := 30 ns;     -- From OE low to any Q
    constant t_dis: Time := 30 ns);   -- From OE high to any Q

  port (
    CLK, OE : in std_ulogic;
    D : in std_ulogic_vector(7 downto 0);
    Q : out std_logic_vector(7 downto 0) := "ZZZZZZZZ");
end entity sn74hc574;

architecture behavioral of sn74hc574 is
  -- Internal flip-flop register
  signal R : std_ulogic_vector(7 downto 0);
begin
  -- Handle latching data on CLK edge
  process ( CLK )
  begin
    assert CLK'delayed'stable(t_w)
      report "clock pulse width: t_w = " &
        Time'image(CLK'delayed'last_event) & " < " & Time'image(t_w)
      severity error;

    if rising_edge(CLK) then
      assert D'stable(t_su)
        report "data setup before clock edge: t_su = " &
          Time'image(D'last_event) & " < " & Time'image(t_su)
        severity error;

      R <= transport D;
    end if;
  end process;

  -- Check data hold time after clock edge
  process ( D )
  begin
    assert CLK = '0' or CLK'stable(t_h)
      report "data hold after clock edge: t_h = " &
        Time'image(CLK'last_event) & " < " & Time'image(t_w)
      severity error;
  end process;

  -- Drive the outputs
  process ( R, OE )
  begin
    if falling_edge(OE) or (OE = '0' and R'event) then
      Q <= transport R after maximum(
        t_en - OE'last_event,
        t_pd - CLK'last_event);
    end if;

    if rising_edge(OE) then
      Q <= transport "ZZZZZZZZ" after t_dis;
    end if;
  end process;
end architecture behavioral;