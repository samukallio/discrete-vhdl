library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Texas Instruments SN74HC573
-- Octal Transparent D-Type Latch With 3-State Outputs

entity sn74hc573 is
  generic (
    -- Timing requirements (default: VCC = 4.5 V, 25 degrees)
    constant t_w: Time := 20 ns;      -- Pulse duration, LE high
    constant t_su: Time := 13 ns;     -- Setup time, data before LE falling edge
    constant t_h: Time := 5 ns;       -- Hold time, data after LE falling edge

    -- Switching characteristics (default: VCC = 4.5 V, CL = 10 pF, 25 degrees)
    constant t_pd: Time := 44 ns;     -- From D or LE rising edge to any Q
    constant t_en: Time := 38 ns;     -- From OE falling edge to any Q
    constant t_dis: Time := 38 ns);   -- From OE rising edge to any Q

  port (
    -- OE is active low, LE is active high
    OE, LE : in std_logic;
    D : in std_logic_vector(7 downto 0);
    Q : out std_logic_vector(7 downto 0));
end entity sn74hc573;

architecture behavioral of sn74hc573 is
  signal D_latched : std_logic_vector(7 downto 0);
begin
  process ( LE, D )
  begin
    if rising_edge(LE) or (LE = '1' and D'event) then
      D_latched <= D;
    end if;

    if falling_edge(LE) then
      assert LE'delayed'stable(t_w)
        report "pulse duration, latch enable high: t_w = " &
          Time'image(LE'delayed'last_event) & " < " & Time'image(t_w)
        severity error;

      assert D'stable(t_su)
        report "setup time, data before latch enable falling edge: t_su = " &
          Time'image(D'last_event) & " < " & Time'image(t_su)
        severity error;
    end if;

    if LE = '0' and D'event then
      assert LE'stable(t_h)
        report "hold time, data after latch enable falling edge: t_h = " &
          Time'image(LE'last_event) & " < " & Time'image(t_h)
        severity error;
    end if;
  end process;

  process ( OE, D_latched )
  begin
    if falling_edge(OE) or (OE = '0' and D_latched'event) then
      Q <= transport D_latched
        after maximum(
          t_pd - D_latched'last_event,
          t_en - OE'last_event);
    end if;

    if rising_edge(OE) then
      Q <= transport "ZZZZZZZZ"
        after t_dis;
    end if;
  end process;

end architecture behavioral;