library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Texas Instruments SN74HC151
-- 8-Line to 1-Line Data Selector/Multiplexer

entity sn74hc151 is
  generic (
    -- Switching characteristics (default: VCC = 4.5 V, CL = 50 pF, 25 degrees)
    constant t_pd_ABC_YW: Time := 50 ns;  -- From A,B,C to Y,W
    constant t_pd_D_YW: Time := 39 ns;    -- From D0-D7 to Y,W
    constant t_pd_G_YW: Time := 25 ns);   -- From G to Y,W

  port (
    ABC : in unsigned(2 downto 0);
    G : in std_ulogic;
    D : in std_ulogic_vector(7 downto 0);
    Y, W : out std_ulogic);
end entity sn74hc151;

architecture behavioral of sn74hc151 is
begin
  process ( ABC,G,D )
    variable t_pd : Time;
  begin
    if rising_edge(G) then
      Y <= transport '0' after t_pd_G_YW;
      W <= transport '1' after t_pd_G_YW;

    elsif G = '0' then
      t_pd := 0 ns;
      t_pd := maximum(t_pd, t_pd_ABC_YW - ABC'last_event);
      t_pd := maximum(t_pd, t_pd_G_YW - G'last_event);
      t_pd := maximum(t_pd, t_pd_D_YW - D'last_event);

      Y <= transport D(to_integer(ABC)) after t_pd;
      W <= transport not(D(to_integer(ABC))) after t_pd;
    end if;
  end process;
end architecture behavioral;