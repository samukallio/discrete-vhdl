library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Texas Instruments SN74HC688
-- 8-Bit Identity Comparator

entity sn74hc688 is
  generic (
    -- Switching characteristics (default: VCC = 4.5 V, CL = 50 pF, 25 degrees)
    constant t_pd_PQ_PnotQ: Time := 42 ns;   -- From P,Q to P!=Q
    constant t_pd_OE_PnotQ: Time := 24 ns);  -- From OE to P!=Q

  port (
    OE : in std_ulogic;
    P, Q : in std_ulogic_vector(7 downto 0);
    PnotQ : out std_ulogic);
end entity sn74hc688;

architecture behavioral of sn74hc688 is
begin
  process ( OE, P, Q )
    variable t_pd : Time;
  begin
    if rising_edge(OE) then
      PnotQ <= transport '1' after t_pd_OE_PnotQ;

    elsif OE = '0' then
      t_pd := 0 ns;
      t_pd := maximum(t_pd, t_pd_PQ_PnotQ - P'last_event);
      t_pd := maximum(t_pd, t_pd_PQ_PnotQ - Q'last_event);
      t_pd := maximum(t_pd, t_pd_OE_PnotQ - OE'last_event);

      PnotQ <= transport
        '0' after t_pd when P = Q else
        '1' after t_pd;
    end if;
  end process;
end architecture behavioral;