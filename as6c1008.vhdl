library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Alliance Memory AS6C1008-55
-- 128K x 8 Bit Low Power CMOS SRAM

entity as6c1008 is
  generic (
    -- Timing requirements.
    constant t_RC: Time := 55 ns;     -- Read Cycle Time
    constant t_WC: Time := 55 ns;     -- Write Cycle Time
    constant t_AS: Time := 0 ns;      -- Address Set-up Time
    constant t_AW: Time := 50 ns;     -- Address Valid to End of Write
    constant t_CW: Time := 50 ns;     -- Chip Enable to End of Write
    constant t_WP: Time := 45 ns;     -- Write Pulse Width
    constant t_DW: Time := 25 ns;     -- Data to Write Time Overlap

    -- Switching characteristics.
    constant t_AA: Time := 55 ns;     -- Address Access Time
    constant t_ACE: Time := 55 ns;    -- Chip Enable Access Time
    constant t_OE: Time := 30 ns;     -- Output Enable Access Time
    constant t_CLZ: Time := 10 ns;    -- Chip Enable to Output in Low-Z
    constant t_OLZ: Time := 5 ns;     -- Output Enable to Output in Low-Z
    constant t_CHZ: Time := 20 ns;    -- Chip Disable to Output in High-Z
    constant t_OHZ: Time := 20 ns;    -- Output Disable to Output in High-Z
    constant t_OH: Time := 10 ns;     -- Output Hold from Address Change
    constant t_WR: Time := 0 ns;      -- Write Recovery Time
    constant t_DH: Time := 0 ns;      -- Data Hold from End of Write Time
    constant t_OW: Time := 5 ns;      -- Output Active from End of Write
    constant t_WHZ: Time := 20 ns);   -- Write to Output in High-Z

  port (
    address: in unsigned(16 downto 0);
    data: inout std_logic_vector(7 downto 0);
    we, ce, oe: in std_ulogic );
end entity;

architecture behavioral of as6c1008 is
  type memory_type is array(0 to 2**17-1) of std_logic_vector(7 downto 0);

  function init return memory_type is
    variable memory : memory_type;
    variable mem_addr : integer;
    variable mem_data : integer;
  begin
    for i in 0 to 255 loop
      for j in 0 to 511 loop
        mem_addr := i*512 + j;
        mem_data := (i mod 16)*16 + (j mod 16);
        memory(mem_addr) := std_logic_vector(to_unsigned(mem_data, 8));
      end loop;
    end loop;
    return memory;
  end function init;

  signal memory : memory_type := init; -- (others => (others => '0'));

begin
  main: process ( ce, we, oe, address )
    variable delay : Time;
  begin
    -- Standby mode.
    if ce = '1' then
      data <= transport "ZZZZZZZZ" after t_CHZ;

    -- Write mode.
    elsif we = '0' then
      -- Entering write mode.
      if we'event or ce'event then
        data <= transport "ZZZZZZZZ" after t_WHZ;

      -- Check that the address didn't change during the write cycle.
      elsif address'event then
        report "address changed during write cycle"
          severity error;
      end if;

    -- Read mode.
    elsif oe = '0' then
      -- Output goes to indeterminate low-impedance state at one of
      --   1) t_CLZ after CE became active,
      --   2) t_OLZ after OE became active,
      --   3) t_OW after WE became inactive, or
      --   4) t_OH after the address changed,
      -- whichever is latest.
      delay := maximum(0 ns, t_CLZ - ce'last_event);
      delay := maximum(delay, t_OLZ - oe'last_event);
      delay := maximum(delay, t_OW - we'last_event);
      delay := maximum(delay, t_OH - address'last_event);
      data <= transport "XXXXXXXX" after delay;

      -- Data becomes available at one of
      --   1) t_ACE after CE became active,
      --   2) t_OE after OE became active,
      --   3) t_AA after the address changed,
      -- whichever is latest.
      delay := maximum(0 ns, t_ACE - ce'last_event);
      delay := maximum(delay, t_OE - oe'last_event);
      delay := maximum(delay, t_AA - address'last_event);
      data <= transport memory(to_integer(address)) after delay;

      -- Check read cycle timing.
      if address'event then
        assert address'delayed'stable(t_RC)
          report "read cycle time: t_RC = " &
            Time'image(address'delayed'last_event) & " < " & Time'image(t_RC)
          severity error;
      end if;

    -- Output disable mode.
    else
      data <= transport "ZZZZZZZZ" after t_OHZ;

    end if;

    -- Write cycle ending?
    if (ce = '0' and rising_edge(we)) or
       (we = '0' and rising_edge(ce)) or
       (rising_edge(we) and rising_edge(ce)) then

      -- Check that the chip has been enabled for long enough.
      assert ce'delayed'stable(t_CW)
        report "chip enable to end of write: t_CW = "
          & Time'image(ce'delayed'last_event) & " < " & Time'image(t_CW)
        severity error;

      -- Check that the write pulse was long enough.
      assert we'delayed'stable(t_WP)
        report "write pulse width: t_WP = "
          & Time'image(we'delayed'last_event) & " < " & Time'image(t_WP)
        severity error;

      -- Check that the address has been stable for long enough.
      assert address'stable(t_AW)
        report "address valid to end of write: t_AW = "
          & Time'image(address'last_event) & " < " & Time'image(t_AW)
        severity error;

      -- Check that the data has been stable for long enough.
      assert data'stable(t_DW)
        report "data to write time overlap: t_DW = "
          & Time'image(data'last_event) & " < " & Time'image(t_DW)
        severity error;

      -- Perform write.
      memory(to_integer(address)) <= data;
    end if;
  end process;
end architecture;

