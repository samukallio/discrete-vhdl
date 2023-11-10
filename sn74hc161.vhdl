library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Texas Instruments SN74HC161
-- 4-bit Synchronous Binary Counter

entity sn74hc161 is
  generic (
    -- Timing requirements (default: VCC = 4.5 V, 25 degrees)
    constant t_w_CLK: Time := 16 ns;    -- Pulse duration (CLK H/L)
    constant t_w_CLR: Time := 16 ns;    -- Pulse duration (CLR L)
    constant t_su_D: Time := 30 ns;     -- Data setup before CLK rising edge
    constant t_su_LOAD: Time := 27 ns;  -- LOAD setup before CLK rising edge
    constant t_su_ENP: Time := 34 ns;   -- ENP setup before CLK rising edge
    constant t_su_ENT: Time := 34 ns;   -- ENT setup before CLK rising edge
    constant t_su_CLR: Time := 25 ns;   -- CLR setup before CLK rising edge

    -- Switching characteristics (default: VCC = 4.5 V, CL = 50 pF, 25 degrees)
    constant t_pd_CLK_Q: Time := 41 ns;
    constant t_pd_CLK_RCO: Time := 43 ns;
    constant t_pd_ENT_RCO: Time := 39 ns;
    constant t_pd_CLR_Q: Time := 42 ns;
    constant t_pd_CLR_RCO: Time := 44 ns);

  port (
    CLK : in std_ulogic;
    CLR, LOAD : in std_ulogic;
    ENP, ENT : in std_ulogic;
    RCO : out std_ulogic;
    D : in std_ulogic_vector(3 downto 0);
    Q : out std_ulogic_vector(3 downto 0) := "0000");
end entity sn74hc161;

architecture behavioral of sn74hc161 is
  signal Q_reg : std_ulogic_vector(3 downto 0) := "0000";
begin
  process ( CLK, CLR )
  begin
    if falling_edge(CLR) then
      Q_reg <= transport "0000";
    end if;

    if CLK'event then
      assert CLK'delayed'stable(t_w_CLK)
        report "clock pulse duration: t_CLK = " &
          Time'image(CLK'delayed'last_event) & " < " & Time'image(t_w_CLK)
        severity error;
    end if;

    if CLR = '1' and rising_edge(CLK) then
      -- timing requirement checks
      assert ENP'stable(t_su_ENP)
        report "ENP stable before clock edge: t_su_ENP = " &
          Time'image(ENP'last_event) & " < " & Time'image(t_su_ENP)
        severity error;

      assert ENT'stable(t_su_ENT)
        report "ENT stable before clock edge: t_su_ENT = " &
          Time'image(ENT'last_event) & " < " & Time'image(t_su_ENT)
        severity error;

      assert CLR'stable(t_su_CLR)
        report "CLR inactive before clock edge: t_su_CLR = " &
          Time'image(CLR'last_event) & " < " & Time'image(t_su_CLR)
        severity error;

      assert LOAD'stable(t_su_LOAD)
        report "LOAD stable before clock edge: t_su_LOAD = " &
          Time'image(LOAD'last_event) & " < " & Time'image(t_su_LOAD)
        severity error;

      if LOAD = '0' then
        assert D'stable(t_su_D)
          report "data stable before clock edge: t_su_D = " &
            Time'image(D'last_event) & " < " & Time'image(t_su_D)
          severity error;

        Q_reg <= transport D;

      elsif ENP = '1' and ENT = '1' then
        Q_reg <= transport std_ulogic_vector((unsigned(Q_reg) + 1) mod 16);
      end if;
    end if;
  end process;

  -- RCO output process
  process ( Q_reg, ENT )
    variable t_pd : Time;
  begin
    t_pd := maximum(
      t_pd_ENT_RCO - ENT'last_event,
      t_pd_CLK_RCO - CLK'last_event);

    if CLR = '0' then
      t_pd := maximum(t_pd, t_pd_CLR_RCO - CLR'last_event);
    end if;

    if Q_reg = "1111" and ENT = '1' then
      RCO <= transport '1' after maximum(t_pd, 0 ns);
    else
      RCO <= transport '0' after maximum(t_pd, 0 ns);
    end if;
  end process;

  -- Q output process
  process ( Q_reg )
    variable t_pd : Time;
  begin
    if CLR = '0' then
      t_pd := maximum(
        t_pd_CLK_Q - CLK'last_event,
        t_pd_CLR_Q - CLR'last_event);
    else
      t_pd := t_pd_CLK_Q;
    end if;

    Q <= transport Q_reg after maximum(t_pd, 0 ns);
  end process;

end architecture behavioral;