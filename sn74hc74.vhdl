library ieee;
use ieee.std_logic_1164.all;

-- Texas Instruments SN74HC74 (one half)
-- Dual D-Type Positive-Edge-Triggered Flip-Flops With Clear and Preset

entity sn74hc74_half is
  generic (
    -- Timing requirements (default: VCC = 4.5 V, 25 degrees)
    constant t_w_PRE : Time := 25 ns;       -- Pulse width (PRE low)
    constant t_w_CLR : Time := 25 ns;       -- Pulse width (CLR low)
    constant t_w_CLK : Time := 20 ns;       -- Pulse width (CLK high or low)
    constant t_su_D : Time := 25 ns;        -- Data stable before CLK
    constant t_su_PRE : Time := 6 ns;       -- PRE inactive before CLK
    constant t_su_CLR : Time := 6 ns;       -- CLR inactive before CLK
    constant t_h_D : Time := 0 ns;          -- Hold time after CLK edge

    -- Switching characteristics (default: VCC = 4.5 V, CL = 50 pF, 25 degrees)
    constant t_pd_PRE_Q : Time := 58 ns;    -- PRE to Q or !Q
    constant t_pd_CLR_Q : Time := 58 ns;    -- CLR to Q or !Q
    constant t_pd_CLK_Q : Time := 44 ns );  -- CLK to Q or !Q

  port (
    D, CLK, CLR, PRE : in std_ulogic;
    Q : out std_ulogic := '0';
    notQ : out std_ulogic := '1' );
end entity sn74hc74_half;

architecture behavioral of sn74hc74_half is
begin
  process ( CLK, CLR, PRE )
  begin
    if falling_edge(CLR) then
      Q <= not PRE after t_pd_CLR_Q;
      notQ <= '1' after t_pd_CLR_Q;
    elsif falling_edge(PRE) then
      Q <= '1' after t_pd_PRE_Q;
      notQ <= not CLR after t_pd_PRE_Q;
    end if;

    if CLR = '1' and PRE = '1' and rising_edge(CLK) then
      assert CLR'stable(t_su_CLR)
        report "CLR inactive before clock edge: t_su_CLR = " &
          Time'image(CLR'delayed'last_event) & " < " & Time'image(t_su_CLR)
        severity error;

      assert PRE'stable(t_su_PRE)
        report "PRE inactive before clock edge: t_su_PRE = " &
          Time'image(PRE'delayed'last_event) & " < " & Time'image(t_su_PRE)
        severity error;

      assert D'stable(t_su_D)
        report "D1 stable before clock edge: t_su_D = " &
          Time'image(D'delayed'last_event) & " < " & Time'image(t_su_D)
        severity error;

      if D = '1' then
        Q <= '1' after t_pd_CLK_Q;
        notQ <= '0' after t_pd_CLK_Q;
      else
        Q <= '0' after t_pd_CLK_Q;
        notQ <= '1' after t_pd_CLK_Q;
      end if;
    end if;

    if rising_edge(CLR) then
      assert CLR'delayed'stable(t_w_CLR)
        report "CLR pulse width: t_w_CLR = " &
          Time'image(CLR'delayed'last_event) & " < " & Time'image(t_w_CLR)
        severity error;
    end if;

    if rising_edge(PRE) then
      assert PRE'delayed'stable(t_w_PRE)
        report "PRE pulse width: t_w_PRE = " &
          Time'image(PRE'delayed'last_event) & " < " & Time'image(t_w_PRE)
        severity error;
    end if;

    if CLK'event then
      assert CLK'delayed'stable(t_w_CLK)
        report "CLK pulse width: t_w_CLK = " &
          Time'image(CLK'delayed'last_event) & " < " & Time'image(t_w_CLK)
        severity error;
    end if;
  end process;
end architecture behavioral;

-- SN74HC74 -------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity sn74hc74 is
  port (
    D1, CLK1, CLR1, PRE1 : in std_ulogic;
    Q1, notQ1 : out std_ulogic;
    D2, CLK2, CLR2, PRE2 : in std_ulogic;
    Q2, notQ2 : out std_ulogic );
end entity sn74hc74;

architecture behavioral of sn74hc74 is
begin
  ff1 : entity work.sn74hc74_half(behavioral)
    port map (
      CLK => CLK1, CLR => CLR1, PRE => PRE1,
      D => D1, Q => Q1, notQ => notQ1 );

  fff : entity work.sn74hc74_half(behavioral)
    port map (
      CLK => CLK2, CLR => CLR2, PRE => PRE2,
      D => D2, Q => Q2, notQ => notQ2 );
end architecture behavioral;
