library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library riscv;
use riscv.rv32e_pkg.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity alu_tb is
	generic (runner_cfg : string);
end entity;

architecture tb of alu_tb is

	constant CLK_PERIOD : time := 10.0 ns;

	signal funct7_i : std_logic_vector(6 downto 0);
	signal funct3_i : std_logic_vector(2 downto 0);
	signal op_op_i  : std_logic;
	signal op_imm_i : std_logic;

	signal op_store_i : std_logic;
	signal op_load_i  : std_logic;
	signal op_auipc_i  : std_logic;

	signal imm_i : std_logic_vector(31 downto 0);
	signal rs1_i : std_logic_vector(31 downto 0);
	signal rs2_i : std_logic_vector(31 downto 0);
	signal pc_i : std_logic_vector(31 downto 0);

	signal alu_o : std_logic_vector(31 downto 0);

begin

	dut : entity work.alu(rtl)
		port map(
			funct7_i => funct7_i,
			funct3_i => funct3_i,
			op_op_i  => op_op_i,
			op_imm_i => op_imm_i,

			op_store_i => op_store_i,
			op_load_i => op_load_i,
			op_auipc_i => op_auipc_i,

			imm_i => imm_i,
			rs1_i => rs1_i,
			rs2_i => rs2_i,
			pc_i => pc_i,

			alu_o => alu_o
		);


	main                   : process
		variable in1, in2, res : unsigned(31 downto 0);

	begin
		test_runner_setup(runner, runner_cfg);
		while test_suite loop
			if run("addi") then
				in1 := x"00001234";
				in2 := x"00004321";
				res := in1 + in2;

				funct3_i <= FUNCT3_ADDSUB;
				op_op_i  <= '0';
				op_imm_i <= '1';

				imm_i <= std_logic_vector(in2);
				rs1_i <= std_logic_vector(in1);
				rs2_i <= x"00000000";

				wait for 10 ns;
				check_equal(alu_o, res, "Checking alu out");

			elsif run("sub") then
				in1 := x"00001234";
				in2 := x"00004321";
				res := in1 - in2;

				funct7_i <= FUNCT7_SUB;
				funct3_i <= FUNCT3_ADDSUB;
				op_op_i  <= '1';
				op_imm_i <= '0';

				imm_i <= x"00000000";
				rs1_i <= std_logic_vector(in1);
				rs2_i <= std_logic_vector(in2);

				wait for 10 ns;
				check_equal(alu_o, res, "Checking alu out");

			elsif run("add") then
				in1 := x"00001234";
				in2 := x"00004321";
				res := in1 + in2;

				funct7_i <= FUNCT7_ADD;
				funct3_i <= FUNCT3_ADDSUB;
				op_op_i  <= '1';
				op_imm_i <= '0';

				imm_i <= x"00000000";
				rs1_i <= std_logic_vector(in1);
				rs2_i <= std_logic_vector(in2);

				wait for 10 ns;
				check_equal(alu_o, res, "Checking alu out");

			elsif run("sll") then
				in1 := x"00001234";
				in2 := x"00004321";
				res := shift_left(in1, to_integer(in2(4 downto 0)));

				funct3_i <= FUNCT3_SLL;
				op_op_i  <= '1';
				op_imm_i <= '0';

				imm_i <= x"00000000";
				rs1_i <= std_logic_vector(in1);
				rs2_i <= std_logic_vector(in2);

				wait for 10 ns;
				check_equal(alu_o, res, "Checking alu out");

			elsif run("slli") then
				in1 := x"00001234";
				in2 := x"00004321";
				res := shift_left(in1, to_integer(in2(4 downto 0)));

				funct3_i <= FUNCT3_SLL;
				op_op_i  <= '0';
				op_imm_i <= '1';

				imm_i <= std_logic_vector(in2);
				rs1_i <= std_logic_vector(in1);
				rs2_i <= x"00000000";

				wait for 10 ns;
				check_equal(alu_o, res, "Checking alu out");

			elsif run("srl") then
				in1 := x"00001234";
				in2 := x"00004321";
				res := shift_right(in1, to_integer(in2(4 downto 0)));

				funct7_i <= FUNCT7_SRL;
				funct3_i <= FUNCT3_SR;
				op_op_i  <= '1';
				op_imm_i <= '0';

				imm_i <= x"00000000";
				rs1_i <= std_logic_vector(in1);
				rs2_i <= std_logic_vector(in2);

				wait for 10 ns;
				check_equal(alu_o, res, "Checking alu out");

			elsif run("srli") then
				in1 := x"00001234";
				in2 := x"00004321";
				res := shift_right(in1, to_integer(in2(4 downto 0)));

				funct7_i <= FUNCT7_SRL;
				funct3_i <= FUNCT3_SR;
				op_op_i  <= '0';
				op_imm_i <= '1';

				imm_i <= std_logic_vector(in2);
				rs1_i <= std_logic_vector(in1);
				rs2_i <= x"00000000";

				wait for 10 ns;
				check_equal(alu_o, res, "Checking alu out");

			elsif run("sra") then
				in1 := x"00001234";
				in2 := x"00004321";
				res := shift_right(in1, to_integer(in2(4 downto 0)));

				funct7_i <= FUNCT7_SRA;
				funct3_i <= FUNCT3_SR;
				op_op_i  <= '1';
				op_imm_i <= '0';

				imm_i <= x"00000000";
				rs1_i <= std_logic_vector(in1);
				rs2_i <= std_logic_vector(in2);

				wait for 10 ns;
				check_equal(alu_o, res, "Checking alu out");

			elsif run("srai") then
				in1 := x"00001234";
				in2 := x"00004321";
				res := shift_right(in1, to_integer(in2(4 downto 0)));

				funct7_i <= FUNCT7_SRA;
				funct3_i <= FUNCT3_SR;
				op_op_i  <= '0';
				op_imm_i <= '1';

				imm_i <= std_logic_vector(in2);
				rs1_i <= std_logic_vector(in1);
				rs2_i <= x"00000000";

				wait for 10 ns;
				check_equal(alu_o, res, "Checking alu out");

			elsif run("and") then
				in1 := x"00001234";
				in2 := x"00004321";
				res := in1 and in2;

				funct3_i <= FUNCT3_AND;
				op_op_i  <= '1';
				op_imm_i <= '0';

				imm_i <= x"00000000";
				rs1_i <= std_logic_vector(in1);
				rs2_i <= std_logic_vector(in2);

				wait for 10 ns;
				check_equal(alu_o, res, "Checking alu out");

			elsif run("andi") then
				in1 := x"00001234";
				in2 := x"00004321";
				res := in1 and in2;

				funct3_i <= FUNCT3_AND;
				op_op_i  <= '0';
				op_imm_i <= '1';

				imm_i <= std_logic_vector(in2);
				rs1_i <= std_logic_vector(in1);
				rs2_i <= x"00000000";

				wait for 10 ns;
				check_equal(alu_o, res, "Checking alu out");

			elsif run("or") then
				in1 := x"00005A5A";
				in2 := x"0000A5A5";
				res := in1 or in2;

				funct3_i <= FUNCT3_OR;
				op_op_i  <= '1';
				op_imm_i <= '0';

				imm_i <= x"00000000";
				rs1_i <= std_logic_vector(in1);
				rs2_i <= std_logic_vector(in2);

				wait for 10 ns;
				check_equal(alu_o, res, "Checking alu out");

			elsif run("ori") then
				in1 := x"00001234";
				in2 := x"00004321";
				res := in1 or in2;

				funct3_i <= FUNCT3_OR;
				op_op_i  <= '0';
				op_imm_i <= '1';

				imm_i <= std_logic_vector(in2);
				rs1_i <= std_logic_vector(in1);
				rs2_i <= x"00000000";

				wait for 10 ns;
				check_equal(alu_o, res, "Checking alu out");

			elsif run("xor") then
				in1 := x"00001234";
				in2 := x"00004321";
				res := in1 xor in2;

				funct3_i <= FUNCT3_XOR;
				op_op_i  <= '1';
				op_imm_i <= '0';

				imm_i <= x"00000000";
				rs1_i <= std_logic_vector(in1);
				rs2_i <= std_logic_vector(in2);

				wait for 10 ns;
				check_equal(alu_o, res, "Checking alu out");

			elsif run("xori") then
				in1 := x"00001234";
				in2 := x"00004321";
				res := in1 xor in2;

				funct3_i <= FUNCT3_XOR;
				op_op_i  <= '0';
				op_imm_i <= '1';

				imm_i <= std_logic_vector(in2);
				rs1_i <= std_logic_vector(in1);
				rs2_i <= x"00000000";

				wait for 10 ns;
				check_equal(alu_o, res, "Checking alu out");

			elsif run("slt should do one") then
				in1 := x"00001234";
				in2 := x"00004321";
				res := x"00000001";

				funct3_i <= FUNCT3_SLT;
				op_op_i  <= '1';
				op_imm_i <= '0';

				imm_i <= x"00000000";
				rs1_i <= std_logic_vector(in1);
				rs2_i <= std_logic_vector(in2);

				wait for 10 ns;
				check_equal(alu_o, res, "Checking alu out");

			elsif run("slt should do zero") then
				in1 := x"00004321";
				in2 := x"00001234";
				res := x"00000000";

				funct3_i <= FUNCT3_SLT;
				op_op_i  <= '1';
				op_imm_i <= '0';

				imm_i <= x"00000000";
				rs1_i <= std_logic_vector(in1);
				rs2_i <= std_logic_vector(in2);

				wait for 10 ns;
				check_equal(alu_o, res, "Checking alu out");

			elsif run("slti should do one") then
				in1 := x"00001234";
				in2 := x"00004321";
				res := x"00000001";

				funct3_i <= FUNCT3_SLT;
				op_op_i  <= '0';
				op_imm_i <= '1';

				imm_i <= std_logic_vector(in2);
				rs1_i <= std_logic_vector(in1);
				rs2_i <= x"00000000";

				wait for 10 ns;
				check_equal(alu_o, res, "Checking alu out");

			elsif run("slti should do zero") then
				in1 := x"00004321";
				in2 := x"00001234";
				res := x"00000000";

				funct3_i <= FUNCT3_SLT;
				op_op_i  <= '0';
				op_imm_i <= '1';

				imm_i <= std_logic_vector(in2);
				rs1_i <= std_logic_vector(in1);
				rs2_i <= x"00000000";

				wait for 10 ns;
				check_equal(alu_o, res, "Checking alu out");

			elsif run("sltu should do one") then
				in1 := x"00001234";
				in2 := x"00004321";
				res := x"00000001";

				funct3_i <= FUNCT3_SLTU;
				op_op_i  <= '1';
				op_imm_i <= '0';

				imm_i <= x"00000000";
				rs1_i <= std_logic_vector(in1);
				rs2_i <= std_logic_vector(in2);

				wait for 10 ns;
				check_equal(alu_o, res, "Checking alu out");

			elsif run("sltu should do zero") then
				in1 := x"00004321";
				in2 := x"00001234";
				res := x"00000000";

				funct3_i <= FUNCT3_SLTU;
				op_op_i  <= '1';
				op_imm_i <= '0';

				imm_i <= x"00000000";
				rs1_i <= std_logic_vector(in1);
				rs2_i <= std_logic_vector(in2);

				wait for 10 ns;
				check_equal(alu_o, res, "Checking alu out");

			elsif run("sltiu should do one") then
				in1 := x"00001234";
				in2 := x"00004321";
				res := x"00000001";

				funct3_i <= FUNCT3_SLTU;
				op_op_i  <= '0';
				op_imm_i <= '1';

				imm_i <= std_logic_vector(in2);
				rs1_i <= std_logic_vector(in1);
				rs2_i <= x"00000000";

				wait for 10 ns;
				check_equal(alu_o, res, "Checking alu out");

			elsif run("sltiu should do zero") then
				in1 := x"00004321";
				in2 := x"00001234";
				res := x"00000000";

				funct3_i <= FUNCT3_SLTU;
				op_op_i  <= '0';
				op_imm_i <= '1';

				imm_i <= std_logic_vector(in2);
				rs1_i <= std_logic_vector(in1);
				rs2_i <= x"00000000";

				wait for 10 ns;
				check_equal(alu_o, res, "Checking alu out");

			elsif run("store should result in rs1 + imm") then
				in1 := x"A5A5A5A5";
				in2 := x"00005A5A";
				res := in1 + in2;

				op_op_i    <= '0';
				op_imm_i   <= '0';
				op_store_i <= '1';
				op_load_i  <= '0';
				op_auipc_i <= '0';

				imm_i <= std_logic_vector(in2);
				rs1_i <= std_logic_vector(in1);
				rs2_i <= x"00000000";

				wait for 10 ns;
				check_equal(alu_o, res, "Checking alu out");

			elsif run("load should result in rs1 + imm") then
				in1 := x"A5A5A5A5";
				in2 := x"5A5A0000";
				res := in1 + in2;

				op_op_i    <= '0';
				op_imm_i   <= '0';
				op_store_i <= '0';
				op_load_i  <= '1';
				op_auipc_i <= '0';

				imm_i <= std_logic_vector(in2);
				rs1_i <= std_logic_vector(in1);
				rs2_i <= x"00000000";

				wait for 10 ns;
				check_equal(alu_o, res, "Checking alu out");
			end if;
		end loop;

		test_runner_cleanup(runner);
	end process;
end architecture tb;
