library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Texas Instruments SN74HC244
-- Octal Buffers and Line Drivers With 3-State Outputs

entity sn74hc244 is
  generic (
    -- Switching characteristics (default: VCC = 4.5 V, CL = 50 pF, 25 degrees)
    constant t_pd: Time := 29 ns;
    constant t_en: Time := 38 ns;
    constant t_dis: Time := 38 ns;
    constant t_t: Time := 15 ns);

  port (
    OE1, OE2 : in std_ulogic;
    A1, A2 : in std_ulogic_vector(3 downto 0);
    Y1, Y2 : out std_ulogic_vector(3 downto 0));
end entity sn74hc244;

architecture behavioral of sn74hc244 is
begin
  process ( OE1, A1 )
  begin
    if A1'event and OE1 = '1' then
      Y1 <= transport A1 after maximum(t_pd, t_en - OE1'last_event);
    elsif rising_edge(OE1) then
      Y1 <= transport A1 after maximum(t_en, t_pd - A1'last_event);
    elsif falling_edge(OE1) then
      Y1 <= transport "ZZZZ" after t_dis;
    end if;
  end process;

  process ( OE1, A1 )
  begin
    if A2'event and OE2 = '1' then
      Y2 <= transport A2 after maximum(t_pd, t_en - OE2'last_event);
    elsif rising_edge(OE2) then
      Y2 <= transport A2 after maximum(t_en, t_pd - A2'last_event);
    elsif falling_edge(OE2) then
      Y2 <= transport "ZZZZ" after t_dis;
    end if;
  end process;
end architecture behavioral;