library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Texas Instruments SN74HC191
-- 4-bit Synchronous Up/Down Binary Counter with Asynchronous Load

entity sn74hc191 is
  generic (
    -- Timing requirements (default: VCC = 4.5 V, 25 degrees)
    constant t_w_CLK: Time := 24 ns;    -- Pulse duration (CLK H/L)
    constant t_w_LOAD: Time := 24 ns;   -- Pulse duration (LOAD L)
    constant t_su_DATA: Time := 30 ns;  -- Data setup before LOAD rising edge
    constant t_su_CTEN: Time := 41 ns;  -- CTEN setup before CLK rising edge
    constant t_su_DU: Time := 41 ns;    -- D/U setup before CLK rising edge
    constant t_su_LOAD: Time := 30 ns;  -- CLR setup before CLK rising edge
    constant t_h: Time := 5 ns;         -- Hold time for all inputs

    -- Switching characteristics (default: VCC = 4.5 V, CL = 50 pF, 25 degrees)
    constant t_pd_LOAD_Q: Time := 40 ns; -- max=53, typ=40
    constant t_pd_D_Q: Time := 48 ns;
    constant t_pd_CLK_RCO: Time := 24 ns;
    constant t_pd_CLK_Q: Time := 38 ns;
    constant t_pd_CLK_MAXMIN: Time := 50 ns;
    constant t_pd_DU_RCO: Time := 46 ns;
    constant t_pd_DU_MAXMIN: Time := 38 ns;
    constant t_pd_CTEN_RCO: Time := 26 ns );

  port (
    CLK : in std_ulogic;
    CTEN : in std_ulogic;
    DU : in std_ulogic;
    LOAD : in std_ulogic;
    RCO : out std_ulogic;
    MAXMIN : out std_ulogic;
    D : in std_ulogic_vector(3 downto 0);
    Q : out std_ulogic_vector(3 downto 0) := "0000");
end entity sn74hc191;

architecture behavioral of sn74hc191 is
  signal Q_reg : std_ulogic_vector(3 downto 0) := "0000";
begin
  process ( CLK, D, LOAD )
  begin
    if LOAD = '0' then
      Q_reg <= transport D;
    end if;

    if rising_edge(LOAD) then
      assert D'stable(t_su_DATA)
        report "data stable before LOAD edge: t_su_DATA = " &
          Time'image(D'last_event) & " < " & Time'image(t_su_DATA)
        severity error;

      assert LOAD'delayed'stable(t_w_LOAD)
        report "LOAD pulse duration: t_w_LOAD = " &
          Time'image(LOAD'delayed'last_event) & " < " & Time'image(t_w_LOAD)
        severity error;
    end if;

    if CLK'event then
      assert CLK'delayed'stable(t_w_CLK)
        report "clock pulse duration: t_w_CLK = " &
          Time'image(CLK'delayed'last_event) & " < " & Time'image(t_w_CLK)
        severity error;
    end if;

    if LOAD = '1' and rising_edge(CLK) then
      -- timing requirement checks
      assert CTEN'stable(t_su_CTEN)
        report "CTEN stable before clock edge: t_su_CTEN = " &
          Time'image(CTEN'last_event) & " < " & Time'image(t_su_CTEN)
        severity error;

      assert LOAD'stable(t_su_LOAD)
        report "LOAD inactive before clock edge: t_su_LOAD = " &
          Time'image(LOAD'last_event) & " < " & Time'image(t_su_LOAD)
        severity error;

      assert DU'stable(t_su_DU)
        report "DU stable before clock edge: t_su_DU = " &
          Time'image(DU'last_event) & " < " & Time'image(t_su_DU)
        severity error;

      if CTEN = '0' then
        Q_reg <= transport std_ulogic_vector((unsigned(Q_reg) + 1) mod 16);
      end if;
    end if;
  end process;

  -- RCO output process
  process ( Q_reg, DU, CTEN, CLK )
    variable t_pd : Time;
  begin
    t_pd := maximum(0 ns, t_pd_CLK_RCO - CLK'last_event);
    t_pd := maximum(t_pd, t_pd_CTEN_RCO - CTEN'last_event);
    t_pd := maximum(t_pd, t_pd_DU_RCO - DU'last_event);

    if DU = '0' and Q_reg = "1111" and CTEN = '0' then
      RCO <= transport CLK after t_pd;
    elsif DU = '1' and Q_reg = "0000" and CTEN = '0' then
      RCO <= transport CLK after t_pd;
    else
      RCO <= transport '1' after t_pd;
    end if;
  end process;

  -- MAX/MIN output process
  process ( Q_reg, DU )
    variable t_pd : Time;
  begin
    t_pd := maximum(0 ns, t_pd_CLK_MAXMIN - CLK'last_event);
    t_pd := maximum(t_pd, t_pd_DU_MAXMIN - DU'last_event);

    if DU = '0' and Q_reg = "1111" then
      MAXMIN <= transport '1' after t_pd;
    elsif DU = '1' and Q_reg = "0000" then
      MAXMIN <= transport '1' after t_pd;
    else
      MAXMIN <= transport '0' after t_pd;
    end if;
  end process;

  -- Q output process
  process ( Q_reg, LOAD )
    variable t_pd : Time;
  begin
    if LOAD = '0' then
      t_pd := maximum(0 ns, t_pd_LOAD_Q - LOAD'last_event);
      t_pd := maximum(t_pd, t_pd_D_Q - D'last_event);
    else
      t_pd := maximum(0 ns, t_pd_CLK_Q - CLK'last_event);
    end if;

    Q <= transport Q_reg after t_pd;
  end process;

end architecture behavioral;