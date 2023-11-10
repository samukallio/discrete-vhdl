library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- SN74HC191 Test Bench -------------------------------------------------------

entity sn74hc191_test is
end entity sn74hc191_test;

architecture behavior of sn74hc191_test is
  signal CLK : std_ulogic;
  signal LOAD : std_ulogic;
  signal CTEN : std_ulogic;
  signal DU : std_ulogic;
  signal MAXMIN : std_ulogic;
  signal RCO : std_ulogic;
  signal D : std_ulogic_vector(3 downto 0);
  signal Q : std_ulogic_vector(3 downto 0);
begin
  dut: entity work.SN74HC191(behavioral)
    port map (
      CLK => CLK,
      LOAD => LOAD,
      CTEN => CTEN,
      DU => DU,
      RCO => RCO,
      MAXMIN => MAXMIN,
      D => D,
      Q => Q);

  process
  begin
    -- Initialize
    CLK <= '0';
    LOAD <= '1';
    DU <= '0';
    CTEN <= '0';
    D <= "0000";
    wait for 100 ns;

    -- Load count
    LOAD <= '0';
    wait for 44 ns;
    LOAD <= '1';
    assert Q = "0000";
    assert RCO = '1';
    wait for 30 ns;

    -- Count from 0 to 15
    for k in 1 to 15 loop
      CLK <= '1';

      -- Check count output
      wait for 41 ns;
      assert Q = std_ulogic_vector(to_unsigned(k, 4));

      -- Check /RCO = 1 always when clock is high
      assert RCO = '1';

      CLK <= '0';
      wait for 23 ns;

      -- Check /RCO = 0 iff Q = 1111 and clock is low
      if k < 15 then
        assert RCO = '1';
        wait for 1 ns;
        assert RCO = '1';
      else
        assert RCO = '1';
        wait for 1 ns;
        assert RCO = '0';
      end if;

    end loop;

    -- Check /CTEN = 1 implies /RCO = 1
    CTEN <= '1';
    wait for 39 ns;
    assert RCO = '1';

    -- Check /CTEN = 0 implies /RCO = 0 (when Q = 1111)
    CTEN <= '0';
    wait for 39 ns;
    assert RCO = '0';

    -- TODO add tests for counting down

    -- Load counter with 1010
    D <= "1010";
    LOAD <= '0';
    wait for 53 ns;
    assert Q = "1010";

    --
    report "SN74HC191 tests complete" severity note;
    wait;
  end process;
end architecture behavior;
