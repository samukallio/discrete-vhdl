library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- SN74HC161 Test Bench -------------------------------------------------------

entity sn74hc161_test is
end entity sn74hc161_test;

architecture behavior of sn74hc161_test is
  signal CLK : std_ulogic;
  signal CLR, LOAD : std_ulogic;
  signal ENP, ENT : std_ulogic;
  signal RCO : std_ulogic;
  signal D : std_ulogic_vector(3 downto 0);
  signal Q : std_ulogic_vector(3 downto 0);
begin
  dut: entity work.SN74HC161(behavioral)
    port map (
      CLK => CLK,
      CLR => CLR,
      LOAD => LOAD,
      ENP => ENP,
      ENT => ENT,
      RCO => RCO,
      D => D,
      Q => Q);

  process
  begin
    -- Initialize
    CLK <= '0';
    CLR <= '1';
    LOAD <= '1';
    ENP <= '1';
    ENT <= '1';
    D <= "0000";
    wait for 100 ns;

    -- Clear count
    CLR <= '0';
    wait for 44 ns;
    CLR <= '1';
    assert Q = "0000";
    assert RCO = '0';
    wait for 25 ns;

    -- Count from 0 to 15
    for k in 1 to 15 loop
      CLK <= '1';

      -- Check count output
      wait for 41 ns;
      assert Q = std_ulogic_vector(to_unsigned(k, 4));

      -- Check RCO = 1 iff Q = 1111
      wait for 2 ns;
      if k < 15 then
        assert RCO = '0';
      else
        assert RCO = '1';
      end if;

      CLK <= '0';
      wait for 16 ns;
    end loop;

    -- Check ENT = 0 implies RCO = 0
    ENT <= '0';
    wait for 39 ns;
    assert RCO = '0';

    -- Check ENT = 1 implies RCO = 1 (when Q = 1111)
    ENT <= '1';
    wait for 39 ns;
    assert RCO = '1';

    -- Load counter with 1010
    D <= "1010";
    LOAD <= '0';
    wait for 30 ns;
    assert Q = "1111";

    CLK <= '1';
    wait for 41 ns;
    assert Q = "1010";
    CLK <= '0';
    LOAD <= '1';
    wait for 27 ns;

    -- Count after loading
    CLK <= '1';
    wait for 41 ns;
    assert Q = "1011";
    CLK <= '0';
    wait for 16 ns;

    -- Load counter with 1111
    D <= "1111";
    LOAD <= '0';
    wait for 30 ns;
    CLK <= '1';
    wait for 41 ns;
    assert Q = "1111";
    wait for 2 ns;
    assert RCO = '1';
    CLK <= '0';
    wait for 27 ns;

    --
    report "SN74HC161 tests complete" severity note;
    wait;
  end process;
end architecture behavior;
