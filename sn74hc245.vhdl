library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Octal Bus Transceivers With 3-state Outputs
entity SN74HC245 is
  -- maximum delays at VCC = 4.5V, CL = 50 pF
  generic (
    -- switching characteristics
    constant t_pd: Time := 26 ns;     -- from A to B or B to A
    constant t_en: Time := 58 ns;     -- from OE falling edge to any A or B
    constant t_dis: Time := 50 ns);   -- from OE rising edge to any A or B

  port (
    OE : in std_ulogic;
    DIR : in std_ulogic;
    A, B : inout std_logic_vector(7 downto 0));
end entity SN74HC245;

architecture behavioral of SN74HC573A is
begin
  process ( OE, DIR, A, B )
  begin
    if rising_edge(OE) then
      A <= transport "XXXXXXXX" after t_dis;
      B <= transport "XXXXXXXX" after t_dis;
    end if;

    if DIR = '0' then
      if falling_edge(OE) or (OE = '0' and B'event) then
        A <= transport B after maximum(
          t_pd - B'last_event,
          t_en - OE'last_event);
      end if;
    else
      if falling_edge(OE) or (OE = '0' and A'event) then
        B <= transport A after maximum(
          t_pd - A'last_event,
          t_en - OE'last_event);
      end if;
    end if;
  end process;

end architecture behavioral;