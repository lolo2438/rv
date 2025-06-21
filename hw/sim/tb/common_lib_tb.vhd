library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

library common;
use common.fnct.all;

entity common_lib_tb is
  generic (runner_cfg : string);
end entity;

architecture tb of common_lib_tb is
begin

  main : process
    variable std_ascend : std_logic_vector(0 to 3);
    variable std_descend : std_logic_vector(3 downto 0);
  begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop
      if run("clog2") then
        check_equal(clog2(1), 0);
        check_equal(clog2(4), 2);
        check_equal(clog2(16), 4);
        check_equal(clog2(256), 8);

      elsif run("priority_encoder") then
        std_ascend := "1010";
        check_equal(priority_encoder(std_ascend), std_logic_vector'("10"), "ASCEND, MSB=2");

        std_ascend := "0101";
        check_equal(priority_encoder(std_ascend), std_logic_vector'("11"), "ASCEND, MSB=3");

        std_descend := "1010";
        check_equal(priority_encoder(std_descend), std_logic_vector'("11"), "DESCEND, MSB=3");

        std_descend := "0101";
        check_equal(priority_encoder(std_descend), std_logic_vector'("10"), "DESCEND, MSB=2");

        std_ascend := "0000";
        check_equal(priority_encoder(std_ascend), std_logic_vector'("XX"));

        std_descend := "0000";
        check_equal(priority_encoder(std_descend), std_logic_vector'("XX"));

      elsif run("bit_reverse") then
        std_ascend := "1000";
        check_equal(bit_reverse(std_ascend), std_logic_vector'("0001"));

        std_ascend := "0001";
        check_equal(bit_reverse(std_ascend), std_logic_vector'("1000"));

        std_descend := "1000";
        check_equal(bit_reverse(std_descend), std_logic_vector'("0001"));

        std_descend := "0001";
        check_equal(bit_reverse(std_descend), std_logic_vector'("1000"));

      elsif run("one_hot_encoder") then
        std_ascend := "1111";
        check_equal(one_hot_encoder(std_ascend), std_logic_vector'(x"0001"), "ascend 1111");

        std_ascend := "1010";
        check_equal(one_hot_encoder(std_ascend), std_logic_vector'(x"0400"), "ascend 1010");

        std_ascend := "0101";
        check_equal(one_hot_encoder(std_ascend), std_logic_vector'(x"0020"), "ascend 0101");

        std_ascend := "0000";
        check_equal(one_hot_encoder(std_ascend), std_logic_vector'(x"8000"), "ascend 0000");

        std_ascend := "1000";
        check_equal(one_hot_encoder(std_ascend), std_logic_vector'(x"4000"), "ascend 1000");

        std_descend := "1111";
        check_equal(one_hot_encoder(std_descend), std_logic_vector'(x"8000"), "descend 1111");

        std_descend := "1010";
        check_equal(one_hot_encoder(std_descend), std_logic_vector'(x"0400"), "descend 1010");

        std_descend := "0101";
        check_equal(one_hot_encoder(std_descend), std_logic_vector'(x"0020"), "descend 0101");

        std_descend := "0000";
        check_equal(one_hot_encoder(std_descend), std_logic_vector'(x"0001"), "descend 0000");

      elsif run("one_hot_decoder") then
        std_ascend := "0001";
        check_equal(one_hot_decoder(std_ascend), std_logic_vector'(b"11"), "ascend 0001");

        std_ascend := "0010";
        check_equal(one_hot_decoder(std_ascend), std_logic_vector'(b"10"), "ascend 0010");

        std_ascend := "0100";
        check_equal(one_hot_decoder(std_ascend), std_logic_vector'(b"01"), "ascend 0100");

        std_ascend := "1000";
        check_equal(one_hot_decoder(std_ascend), std_logic_vector'(b"00"), "ascend 1000");

        std_ascend := "1111";
        check_equal(one_hot_decoder(std_ascend), std_logic_vector'(b"XX"), "ascend 1111");

        std_ascend := "0110";
        check_equal(one_hot_decoder(std_ascend), std_logic_vector'(b"XX"), "ascend 0110");

        std_ascend := "0000";
        check_equal(one_hot_decoder(std_ascend), std_logic_vector'(b"XX"), "ascend 0000");

        std_descend := "0001";
        check_equal(one_hot_decoder(std_descend), std_logic_vector'(b"00"), "descend 0001");

        std_descend := "0010";
        check_equal(one_hot_decoder(std_descend), std_logic_vector'(b"01"), "descend 0010");

        std_descend := "0100";
        check_equal(one_hot_decoder(std_descend), std_logic_vector'(b"10"), "descend 0100");

        std_descend := "1000";
        check_equal(one_hot_decoder(std_descend), std_logic_vector'(b"11"), "descend 1000");

        std_descend := "0000";
        check_equal(one_hot_decoder(std_descend), std_logic_vector'(b"XX"), "descend 0000");

        std_descend := "1111";
        check_equal(one_hot_decoder(std_descend), std_logic_vector'(b"XX"), "descend 1111");

        std_descend := "0110";
        check_equal(one_hot_decoder(std_descend), std_logic_vector'(b"XX"), "descend 0110");

      end if;
    end loop;

    test_runner_cleanup(runner);
  end process;

end architecture;
