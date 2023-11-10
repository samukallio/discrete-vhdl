library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- AS6C1008 Test Bench --------------------------------------------------------

entity AS6C1008_test is
end entity AS6C1008_test;

architecture main of AS6C1008_test is
  signal address: unsigned(16 downto 0);
  signal data: std_logic_vector(7 downto 0);
  signal WE, CE, OE: std_ulogic;
begin
  sram: entity work.AS6C1008(behavioral)
    port map (
      address => address,
      data => data,
      WE => WE,
      CE => CE,
      OE => OE);

  process
  begin
    -- Initialize
    CE <= '0';
    OE <= '1';
    WE <= '1';
    wait for 100 ns;

    for i in 0 to 1000 loop
      address <= to_unsigned(i, 18);
      data <= std_ulogic_vector(to_unsigned(i mod 256, 8));
      WE <= '0';
      wait for 50 ns;
      WE <= '1';
      wait for 1 ns;
    end loop;

    data <= "ZZZZZZZZ";
    OE <= '0';
    wait for 100 ns;

    for i in 0 to 1000 loop
      address <= to_unsigned(i, 18);
      wait for 55 ns;
      assert data = std_ulogic_vector(to_unsigned(i mod 256, 8));
    end loop;

    -- Done
    report "AS6C1008 tests complete" severity note;
    wait;
  end process;
end architecture main;
