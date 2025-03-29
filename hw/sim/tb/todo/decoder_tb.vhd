library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library riscv;
use riscv.rv32e_pkg.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity decoder_tb is
    generic (runner_cfg : string);
end entity;

architecture tb of decoder_tb is

    constant CLK_PERIOD : time := 10.0 ns;

    signal inst_i      : std_logic_vector(XLEN - 1 downto 0) := (others => '0');
    signal rd_o        : std_logic_vector(4 downto 0);
    signal funct3_o    : std_logic_vector(2 downto 0);
    signal rs1_o       : std_logic_vector(4 downto 0);
    signal rs2_o       : std_logic_vector(4 downto 0);
    signal funct7_o    : std_logic_vector(6 downto 0);
    signal immediate_o : std_logic_vector(XLEN - 1 downto 0);
    signal c_inst_o    : std_logic;    -- for pc + 2
    signal op_op_o     : std_logic;
    signal op_jalr_o   : std_logic;
    signal op_imm_o    : std_logic;
    signal op_lui_o    : std_logic;
    signal op_auipc_o  : std_logic;
    signal op_jal_o    : std_logic;
    signal op_branch_o : std_logic;
    signal op_store_o  : std_logic;
    signal op_load_o   : std_logic;
    signal illegal_o   : std_logic;

begin

    dut : entity work.decoder(rtl)
    port map(
        inst_i      => inst_i,

        rd_o        => rd_o,
        funct3_o    => funct3_o,
        rs1_o       => rs1_o,
        rs2_o       => rs2_o,
        funct7_o    => funct7_o,
        immediate_o => immediate_o,
        c_inst_o    => c_inst_o,
        op_op_o     => op_op_o,
        op_jalr_o   => op_jalr_o,
        op_imm_o    => op_imm_o,
        op_lui_o    => op_lui_o,
        op_auipc_o  => op_auipc_o,
        op_jal_o    => op_jal_o,
        op_branch_o => op_branch_o,
        op_store_o  => op_store_o,
        op_load_o   => op_load_o
    );


    main : process
        variable rd, rs1, rs2 : std_logic_vector(4 downto 0);
        variable opcode : std_logic_vector(6 downto 0);
        variable funct3 : std_logic_vector(2 downto 0);
        variable funct7 : std_logic_vector(6 downto 0);
        variable imm : std_logic_vector(31 downto 0);

        variable rdp, rs1p, rs2p : std_logic_Vector(2 downto 0);
        variable c_funct3 : std_logic_vector(2 downto 0);

        procedure verify_ctrl_sig (opcode_i : std_logic_vector(6 downto 0)) is
            variable op_v, jalr_v, imm_v, lui_v, auipc_v, jal_v,
                    branch_v, store_v, load_v : std_logic := '0';
        begin

            case opcode_i is
                when b"0110011" => op_v     := '1';
                when b"1100111" => jalr_v   := '1';
                when b"0010011" => imm_v    := '1';
                when b"0110111" => lui_v    := '1';
                when b"0010111" => auipc_v  := '1';
                when b"1101111" => jal_v    := '1';
                when b"1100011" => branch_v := '1';
                when b"0100011" => store_v  := '1';
                when b"0000011" => load_v   := '1';
                when others =>
            end case;

            check(op_op_o      = op_v,     "Wrong op_o");
            check(op_jalr_o    = jalr_v,   "Wrong jalr_o");
            check(op_imm_o     = imm_v,    "Wrong imm_o");
            check(op_lui_o     = lui_v,    "Wrong lui_o");
            check(op_auipc_o   = auipc_v,  "Wrong auipc_o");
            check(op_jal_o     = jal_v,    "Wrong jal_o");
            check(op_branch_o  = branch_v, "Wrong branch_o");
            check(op_store_o   = store_v,  "Wrong store_o");
            check(op_load_o    = load_v,   "Wrong load_o");
        end procedure;
    begin
        test_runner_setup(runner, runner_cfg);

        while test_suite loop

            -- RV32I
            if run("lui x5, 0xADEAD") then
                rd      := REG_X5;
                imm     := x"ADEAD000";
                opcode  := b"0110111";
                inst_i  <= imm(31 downto 12) & rd & opcode;

                wait for 1 ps;

                check_equal(rd_o, rd, "Checking rd");
                check_equal(immediate_o, imm, "Checking immediate");
                check_equal(c_inst_o, '0', "Not a c instruction");
                verify_ctrl_sig(opcode);

            elsif run("auipc x15, 0xEBEEF") then
                rd      := REG_X15;
                imm     := x"EBEEF000";
                opcode  := b"0010111";
                inst_i  <= imm(31 downto 12) & rd & opcode;
                wait for 1 ps;

                check_equal(rd_o, rd, "Checking rd");
                check_equal(immediate_o, imm, "Checking immediate");
                check_equal(c_inst_o, '0', "Not a c instruction");
                verify_ctrl_sig(opcode);

            elsif run("jal x1, 0xABCDC") then
                rd      := REG_X1;
                imm     := x"FFFABCDC";
                opcode  := b"1101111";
                inst_i  <= imm(20) & imm(10 downto 1) & imm(11) & imm(19 downto 12) & rd & opcode;
                wait for 1 ps;

                check_equal(rd_o, rd, "Checking rd");
                check_equal(immediate_o, imm, "Checking immediate");
                check_equal(c_inst_o, '0', "Not a c instruction");
                verify_ctrl_sig(opcode);

            elsif run("jalr x3, 0x123(x1)") then
                rd      := REG_X3;
                rs1     := REG_X1;
                funct3  := "000";
                imm     := x"00000123";
                opcode  := b"1100111";
                inst_i  <= imm(11 downto 0) & rs1 & funct3 & rd & opcode;
                wait for 1 ps;

                check_equal(rd_o, rd, "Checking rd");
                check_equal(rs1_o, rs1, "Checking rs1");
                check_equal(funct3_o, funct3, "Checking funct3");
                check_equal(immediate_o, imm, "Checking immediate");
                check_equal(c_inst_o, '0', "Not a c instruction");
                verify_ctrl_sig(opcode);

            elsif run("beq x7, x0, 0x32") then
                rs1     := REG_X7;
                rs2     := REG_X0;
                funct3  := b"001";
                imm     := x"00000032";
                opcode  := b"1100011";
                inst_i  <= imm(12) & imm(10 downto 5) & rs2 & rs1 & funct3 & imm(4 downto 1) & imm(11) & opcode;
                wait for 1 ps;

                check_equal(rs2_o, rs2, "Checking rs2");
                check_equal(rs1_o, rs1, "Checking rs1");
                check_equal(funct3_o, funct3, "Checking funct3");
                check_equal(immediate_o, imm, "Checking immediate");
                check_equal(c_inst_o, '0', "Not a c instruction");
                verify_ctrl_sig(opcode);

            elsif run("bne x9, x5, 0xABC") then
                rs1     := REG_X9;
                rs2     := REG_X5;
                funct3  := b"001";
                imm     := x"FFFFFABC";
                opcode  := b"1100011";
                inst_i  <= imm(12) & imm(10 downto 5) & rs2 & rs1 & funct3 & imm(4 downto 1) & imm(11) & opcode;
                wait for 1 ps;

                check_equal(rs2_o, rs2, "Checking rs2");
                check_equal(rs1_o, rs1, "Checking rs1");
                check_equal(funct3_o, funct3, "Checking funct3");
                check_equal(immediate_o, imm, "Checking immediate");
                check_equal(c_inst_o, '0', "Not a c instruction");
                verify_ctrl_sig(opcode);

            elsif run("blt x9, x5, 0xDEE") then
                rs1     := REG_X9;
                rs2     := REG_X5;
                funct3  := b"100";
                imm     := x"FFFFFDEE";
                opcode  := b"1100011";
                inst_i  <= imm(12) & imm(10 downto 5) & rs2 & rs1 & funct3 & imm(4 downto 1) & imm(11) & opcode;
                wait for 1 ps;

                check_equal(rs2_o, rs2, "Checking rs2");
                check_equal(rs1_o, rs1, "Checking rs1");
                check_equal(funct3_o, funct3, "Checking funct3");
                check_equal(immediate_o, imm, "Checking immediate");
                check_equal(c_inst_o, '0', "Not a c instruction");
                verify_ctrl_sig(opcode);

            elsif run("bge x9, x5, 0x322") then
                rs1     := REG_X9;
                rs2     := REG_X5;
                funct3  := b"101";
                imm     := x"00000322";
                opcode  := b"1100011";
                inst_i  <= imm(12) & imm(10 downto 5) & rs2 & rs1 & funct3 & imm(4 downto 1) & imm(11) & opcode;
                wait for 1 ps;

                check_equal(rs2_o, rs2, "Checking rs2");
                check_equal(rs1_o, rs1, "Checking rs1");
                check_equal(funct3_o, funct3, "Checking funct3");
                check_equal(immediate_o, imm, "Checking immediate");
                check_equal(c_inst_o, '0', "Not a c instruction");
                verify_ctrl_sig(opcode);

            elsif run("bltu x4, x9, 0x568") then
                rs1     := REG_X4;
                rs2     := REG_X9;
                funct3  := b"110";
                imm     := x"00000568";
                opcode  := b"1100011";
                inst_i  <= imm(12) & imm(10 downto 5) & rs2 & rs1 & funct3 & imm(4 downto 1) & imm(11) & opcode;
                wait for 1 ps;

                check_equal(rs2_o, rs2, "Checking rs2");
                check_equal(rs1_o, rs1, "Checking rs1");
                check_equal(funct3_o, funct3, "Checking funct3");
                check_equal(immediate_o, imm, "Checking immediate");
                check_equal(c_inst_o, '0', "Not a c instruction");
                verify_ctrl_sig(opcode);

            elsif run("bgeu x8, x8, 0x800") then
                rs1     := REG_X8;
                rs2     := REG_X8;
                funct3  := b"111";
                imm     := x"FFFFF800";
                opcode  := b"1100011";
                inst_i  <= imm(12) & imm(10 downto 5) & rs2 & rs1 & funct3 & imm(4 downto 1) & imm(11) & opcode;
                wait for 1 ps;

                check_equal(rs2_o, rs2, "Checking rs2");
                check_equal(rs1_o, rs1, "Checking rs1");
                check_equal(funct3_o, funct3, "Checking funct3");
                check_equal(immediate_o, imm, "Checking immediate");
                check_equal(c_inst_o, '0', "Not a c instruction");
                verify_ctrl_sig(opcode);

            elsif run("lb x11, 0x123(x2)") then
                rd      := REG_X11;
                rs1     := REG_X2;
                funct3  := b"000";
                imm     := x"00000123";
                opcode  := b"0000011";
                inst_i  <= imm(11 downto 0) & rs1 & funct3 & rd & opcode;
                wait for 1 ps;

                check_equal(rd_o, rd, "Checking rd");
                check_equal(rs1_o, rs1, "Checking rs1");
                check_equal(funct3_o, funct3, "Checking funct3");
                check_equal(immediate_o, imm, "Checking immediate");
                check_equal(c_inst_o, '0', "Not a c instruction");
                verify_ctrl_sig(opcode);

            elsif run("lh x11, 0x456(x2)") then
                rd      := REG_X11;
                rs1     := REG_X2;
                funct3  := b"001";
                imm     := x"00000456";
                opcode  := b"0000011";
                inst_i  <= imm(11 downto 0) & rs1 & funct3 & rd & opcode;
                wait for 1 ps;

                check_equal(rd_o, rd, "Checking rd");
                check_equal(rs1_o, rs1, "Checking rs1");
                check_equal(funct3_o, funct3, "Checking funct3");
                check_equal(immediate_o, imm, "Checking immediate");
                check_equal(c_inst_o, '0', "Not a c instruction");
                verify_ctrl_sig(opcode);

            elsif run("lw x11, 0xABC(x2)") then
                rd      := REG_X11;
                rs1     := REG_X2;
                funct3  := b"010";
                imm     := x"FFFFFABC";
                opcode  := b"0000011";
                inst_i  <= imm(11 downto 0) & rs1 & funct3 & rd & opcode;
                wait for 1 ps;

                check_equal(rd_o, rd, "Checking rd");
                check_equal(rs1_o, rs1, "Checking rs1");
                check_equal(funct3_o, funct3, "Checking funct3");
                check_equal(immediate_o, imm, "Checking immediate");
                check_equal(c_inst_o, '0', "Not a c instruction");
                verify_ctrl_sig(opcode);

            elsif run("lbu x11, 0xDEF(x2)") then
                rd      := REG_X11;
                rs1     := REG_X2;
                funct3  := b"100";
                imm     := x"FFFFFDEF";
                opcode  := b"0000011";
                inst_i  <= imm(11 downto 0) & rs1 & funct3 & rd & opcode;
                wait for 1 ps;

                check_equal(rd_o, rd, "Checking rd");
                check_equal(rs1_o, rs1, "Checking rs1");
                check_equal(funct3_o, funct3, "Checking funct3");
                check_equal(immediate_o, imm, "Checking immediate");
                check_equal(c_inst_o, '0', "Not a c instruction");
                verify_ctrl_sig(opcode);

            elsif run("lhu x11, 0xFED(x2)") then
                rd      := REG_X11;
                rs1     := REG_X2;
                funct3  := b"101";
                imm     := x"FFFFFFED";
                opcode  := b"0000011";
                inst_i  <= imm(11 downto 0) & rs1 & funct3 & rd & opcode;
                wait for 1 ps;

                check_equal(rd_o, rd, "Checking rd");
                check_equal(rs1_o, rs1, "Checking rs1");
                check_equal(funct3_o, funct3, "Checking funct3");
                check_equal(immediate_o, imm, "Checking immediate");
                check_equal(c_inst_o, '0', "Not a c instruction");
                verify_ctrl_sig(opcode);

            elsif run("sb x8, 0xABC(x2)") then
                rs2     := REG_X8;
                rs1     := REG_X2;
                funct3  := b"000";
                imm     := x"FFFFFABC";
                opcode  := b"0100011";
                inst_i  <= imm(11 downto 5) & rs2 & rs1 & funct3 & imm(4 downto 0) & opcode;
                wait for 1 ps;

                check_equal(rs2_o, rs2, "Checking rs2");
                check_equal(rs1_o, rs1, "Checking rs1");
                check_equal(funct3_o, funct3, "Checking funct3");
                check_equal(immediate_o, imm, "Checking immediate");
                check_equal(c_inst_o, '0', "Not a c instruction");
                verify_ctrl_sig(opcode);

            elsif run("sh x8, 0x123(x2)") then
                rs2     := REG_X8;
                rs1     := REG_X2;
                funct3  := b"001";
                imm     := x"00000123";
                opcode  := b"0100011";
                inst_i  <= imm(11 downto 5) & rs2 & rs1 & funct3 & imm(4 downto 0) & opcode;
                wait for 1 ps;

                check(rs2_o = rs2, "rs2_o /= rs2");
                check(rs1_o = rs1, "rs1_o /= rs1");
                check(funct3_o = funct3, "funct3_o /= funct3");
                check(immediate_o = imm, "Wrong immediate");
                check_equal(c_inst_o, '0', "Not a c instruction");
                verify_ctrl_sig(opcode);

            elsif run("sw x8, 0xFFF(x2)") then
                rs2     := REG_X8;
                rs1     := REG_X2;
                funct3  := b"010";
                imm     := x"FFFFFFFF";
                opcode  := b"0100011";
                inst_i  <= imm(11 downto 5) & rs2 & rs1 & funct3 & imm(4 downto 0) & opcode;
                wait for 1 ps;

                check_equal(rs2_o, rs2, "Checking rs2");
                check_equal(rs1_o, rs1, "Checking rs1");
                check_equal(funct3_o, funct3, "Checking funct3");
                check_equal(immediate_o, imm, "Checking immediate");
                check_equal(c_inst_o, '0', "Not a c instruction");
                verify_ctrl_sig(opcode);

            elsif run("addi x5, x0, 0x432") then
                rd      := REG_X5;
                rs1     := REG_X0;
                funct3  := b"000";
                imm     := x"00000432";
                opcode  := b"0010011";
                inst_i  <= imm(11 downto 0) & rs1 & funct3 & rd & opcode;
                wait for 1 ps;

                check_equal(rd_o, rd, "Checking rd");
                check_equal(rs1_o, rs1, "Checking rs1");
                check_equal(funct3_o, funct3, "Checking funct3");
                check_equal(immediate_o, imm, "Checking immediate");
                check_equal(c_inst_o, '0', "Not a c instruction");
                verify_ctrl_sig(opcode);

            elsif run("slti x5, x0, 0x800") then
                rd      := REG_X5;
                rs1     := REG_X0;
                funct3  := b"010";
                imm     := x"FFFFF800";
                opcode  := b"0010011";
                inst_i  <= imm(11 downto 0) & rs1 & funct3 & rd & opcode;
                wait for 1 ps;

                check_equal(rd_o, rd, "Checking rd");
                check_equal(rs1_o, rs1, "Checking rs1");
                check_equal(funct3_o, funct3, "Checking funct3");
                check_equal(immediate_o, imm, "Checking immediate");
                check_equal(c_inst_o, '0', "Not a c instruction");
                verify_ctrl_sig(opcode);

            elsif run("sltiu x14, x0, 0x800") then
                rd      := REG_X14;
                rs1     := REG_X0;
                funct3  := b"011";
                imm     := x"FFFFF800";
                opcode  := b"0010011";
                inst_i  <= imm(11 downto 0) & rs1 & funct3 & rd & opcode;
                wait for 1 ps;

                check_equal(rd_o, rd, "Checking rd");
                check_equal(rs1_o, rs1, "Checking rs1");
                check_equal(funct3_o, funct3, "Checking funct3");
                check_equal(immediate_o, imm, "Checking immediate");
                check_equal(c_inst_o, '0', "Not a c instruction");
                verify_ctrl_sig(opcode);

            elsif run("xori x14, x0, 0x321") then
                rd      := REG_X14;
                rs1     := REG_X0;
                funct3  := b"100";
                imm     := x"00000321";
                opcode  := b"0010011";
                inst_i  <= imm(11 downto 0) & rs1 & funct3 & rd & opcode;
                wait for 1 ps;

                check_equal(rd_o, rd, "Checking rd");
                check_equal(rs1_o, rs1, "Checking rs1");
                check_equal(funct3_o, funct3, "Checking funct3");
                check_equal(immediate_o, imm, "Checking immediate");
                check_equal(c_inst_o, '0', "Not a c instruction");
                verify_ctrl_sig(opcode);

            elsif run("andi x13, x0, 0x789") then
                rd      := REG_X13;
                rs1     := REG_X0;
                funct3  := b"110";
                imm     := x"00000789";
                opcode  := b"0010011";
                inst_i  <= imm(11 downto 0) & rs1 & funct3 & rd & opcode;
                wait for 1 ps;

                check_equal(rd_o, rd, "Checking rd");
                check_equal(rs1_o, rs1, "Checking rs1");
                check_equal(funct3_o, funct3, "Checking funct3");
                check_equal(immediate_o, imm, "Checking immediate");
                check_equal(c_inst_o, '0', "Not a c instruction");
                verify_ctrl_sig(opcode);

            elsif run("slli x13, x3, 5") then
                rd      := REG_X13;
                rs1     := REG_X3;
                funct3  := b"001";
                imm     := x"00000005";
                opcode  := b"0010011";
                inst_i  <= imm(11 downto 0) & rs1 & funct3 & rd & opcode;
                wait for 1 ps;

                check_equal(rd_o, rd, "Checking rd");
                check_equal(rs1_o, rs1, "Checking rs1");
                check_equal(funct3_o, funct3, "Checking funct3");
                check_equal(immediate_o, imm, "Checking immediate");
                check_equal(c_inst_o, '0', "Not a c instruction");
                verify_ctrl_sig(opcode);

            elsif run("srli x13, x3, 31") then
                rd      := REG_X13;
                rs1     := REG_X3;
                funct3  := b"101";
                imm     := x"0000001F";
                opcode  := b"0010011";
                inst_i  <= imm(11 downto 0) & rs1 & funct3 & rd & opcode;
                wait for 1 ps;

                check_equal(rd_o, rd, "Checking rd");
                check_equal(rs1_o, rs1, "Checking rs1");
                check_equal(funct3_o, funct3, "Checking funct3");
                check_equal(immediate_o, imm, "Checking immediate");
                check_equal(c_inst_o, '0', "Not a c instruction");
                verify_ctrl_sig(opcode);

            elsif run("srai x13, x3, 31") then
                rd      := REG_X13;
                rs1     := REG_X3;
                funct3  := b"101";
                imm     := x"0000041F";
                opcode  := b"0010011";
                inst_i  <= imm(11 downto 0) & rs1 & funct3 & rd & opcode;
                wait for 1 ps;

                check_equal(rd_o, rd, "Checking rd");
                check_equal(rs1_o, rs1, "Checking rs1");
                check_equal(funct3_o, funct3, "Checking funct3");
                check_equal(immediate_o, imm, "Checking immediate");
                check_equal(c_inst_o, '0', "Not a c instruction");
                verify_ctrl_sig(opcode);

            elsif run("add x13, x3, x1") then
                rd      := REG_X13;
                rs1     := REG_X3;
                rs2     := REG_X1;
                funct3  := b"000";
                funct7  := b"0000000";
                opcode  := b"0110011";
                inst_i  <= funct7 & rs2 & rs1 & funct3 & rd & opcode;
                wait for 1 ps;

                check_equal(rd_o, rd, "Checking rd");
                check_equal(rs1_o, rs1, "Checking rs1");
                check_equal(rs2_o, rs2, "Checking rs2");
                check_equal(funct3_o, funct3, "Checking funct3");
                check_equal(funct7_o, funct7, "Checking funct7");
                check_equal(c_inst_o, '0', "Not a c instruction");
                verify_ctrl_sig(opcode);

            elsif run("sub x12, x3, x1") then
                rd      := REG_X12;
                rs1     := REG_X3;
                rs2     := REG_X1;
                funct3  := b"000";
                funct7  := b"0100000";
                opcode  := b"0110011";
                inst_i  <= funct7 & rs2 & rs1 & funct3 & rd & opcode;
                wait for 1 ps;

                check_equal(rd_o, rd, "Checking rd");
                check_equal(rs1_o, rs1, "Checking rs1");
                check_equal(rs2_o, rs2, "Checking rs2");
                check_equal(funct3_o, funct3, "Checking funct3");
                check_equal(funct7_o, funct7, "Checking funct7");
                check_equal(c_inst_o, '0', "Not a c instruction");
                verify_ctrl_sig(opcode);

            elsif run("sll x12, x3, x1") then
                rd      := REG_X12;
                rs1     := REG_X3;
                rs2     := REG_X1;
                funct3  := b"001";
                funct7  := b"0000000";
                opcode  := b"0110011";
                inst_i  <= funct7 & rs2 & rs1 & funct3 & rd & opcode;
                wait for 1 ps;

                check_equal(rd_o, rd, "Checking rd");
                check_equal(rs1_o, rs1, "Checking rs1");
                check_equal(rs2_o, rs2, "Checking rs2");
                check_equal(funct3_o, funct3, "Checking funct3");
                check_equal(funct7_o, funct7, "Checking funct7");
                check_equal(c_inst_o, '0', "Not a c instruction");
                verify_ctrl_sig(opcode);

            elsif run("slt x12, x3, x1") then
                rd      := REG_X12;
                rs1     := REG_X3;
                rs2     := REG_X1;
                funct3  := b"010";
                funct7  := b"0000000";
                opcode  := b"0110011";
                inst_i  <= funct7 & rs2 & rs1 & funct3 & rd & opcode;
                wait for 1 ps;

                check_equal(rd_o, rd, "Checking rd");
                check_equal(rs1_o, rs1, "Checking rs1");
                check_equal(rs2_o, rs2, "Checking rs2");
                check_equal(funct3_o, funct3, "Checking funct3");
                check_equal(funct7_o, funct7, "Checking funct7");
                check_equal(c_inst_o, '0', "Not a c instruction");
                verify_ctrl_sig(opcode);

            elsif run("sltu x12, x3, x1") then
                rd      := REG_X12;
                rs1     := REG_X3;
                rs2     := REG_X1;
                funct3  := b"011";
                funct7  := b"0000000";
                opcode  := b"0110011";
                inst_i  <= funct7 & rs2 & rs1 & funct3 & rd & opcode;
                wait for 1 ps;

                check_equal(rd_o, rd, "Checking rd");
                check_equal(rs1_o, rs1, "Checking rs1");
                check_equal(rs2_o, rs2, "Checking rs2");
                check_equal(funct3_o, funct3, "Checking funct3");
                check_equal(funct7_o, funct7, "Checking funct7");
                check_equal(c_inst_o, '0', "Not a c instruction");
                verify_ctrl_sig(opcode);

            elsif run("xor x12, x3, x1") then
                rd      := REG_X12;
                rs1     := REG_X3;
                rs2     := REG_X1;
                funct3  := b"100";
                funct7  := b"0000000";
                opcode  := b"0110011";
                inst_i  <= funct7 & rs2 & rs1 & funct3 & rd & opcode;
                wait for 1 ps;

                check_equal(rd_o, rd, "Checking rd");
                check_equal(rs1_o, rs1, "Checking rs1");
                check_equal(rs2_o, rs2, "Checking rs2");
                check_equal(funct3_o, funct3, "Checking funct3");
                check_equal(funct7_o, funct7, "Checking funct7");
                check_equal(c_inst_o, '0', "Not a c instruction");
                verify_ctrl_sig(opcode);

            elsif run("srl x12, x3, x1") then
                rd      := REG_X12;
                rs1     := REG_X3;
                rs2     := REG_X1;
                funct3  := b"101";
                funct7  := b"0000000";
                opcode  := b"0110011";
                inst_i  <= funct7 & rs2 & rs1 & funct3 & rd & opcode;
                wait for 1 ps;

                check_equal(rd_o, rd, "Checking rd");
                check_equal(rs1_o, rs1, "Checking rs1");
                check_equal(rs2_o, rs2, "Checking rs2");
                check_equal(funct3_o, funct3, "Checking funct3");
                check_equal(funct7_o, funct7, "Checking funct7");
                check_equal(c_inst_o, '0', "Not a c instruction");
                verify_ctrl_sig(opcode);

            elsif run("sra x12, x3, x1") then
                rd      := REG_X12;
                rs1     := REG_X3;
                rs2     := REG_X1;
                funct3  := b"101";
                funct7  := b"0100000";
                opcode  := b"0110011";
                inst_i  <= funct7 & rs2 & rs1 & funct3 & rd & opcode;
                wait for 1 ps;

                check_equal(rd_o, rd, "Checking rd");
                check_equal(rs1_o, rs1, "Checking rs1");
                check_equal(rs2_o, rs2, "Checking rs2");
                check_equal(funct3_o, funct3, "Checking funct3");
                check_equal(funct7_o, funct7, "Checking funct7");
                check_equal(c_inst_o, '0', "Not a c instruction");
                verify_ctrl_sig(opcode);

            elsif run("or x12, x3, x1") then
                rd      := REG_X12;
                rs1     := REG_X3;
                rs2     := REG_X1;
                funct3  := b"110";
                funct7  := b"0000000";
                opcode  := b"0110011";
                inst_i  <= funct7 & rs2 & rs1 & funct3 & rd & opcode;
                wait for 1 ps;

                check_equal(rd_o, rd, "Checking rd");
                check_equal(rs1_o, rs1, "Checking rs1");
                check_equal(rs2_o, rs2, "Checking rs2");
                check_equal(funct3_o, funct3, "Checking funct3");
                check_equal(funct7_o, funct7, "Checking funct7");
                check_equal(c_inst_o, '0', "Not a c instruction");
                verify_ctrl_sig(opcode);

            elsif run("and x12, x3, x1") then
                rd      := REG_X12;
                rs1     := REG_X3;
                rs2     := REG_X1;
                funct3  := b"111";
                funct7  := b"0000000";
                opcode  := b"0110011";
                inst_i  <= funct7 & rs2 & rs1 & funct3 & rd & opcode;
                wait for 1 ps;

                check_equal(rd_o, rd, "Checking rd");
                check_equal(rs1_o, rs1, "Checking rs1");
                check_equal(rs2_o, rs2, "Checking rs2");
                check_equal(funct3_o, funct3, "Checking funct3");
                check_equal(funct7_o, funct7, "Checking funct7");
                check_equal(c_inst_o, '0', "Not a c instruction");
                verify_ctrl_sig(opcode);

            -- RV32C
            -- C0
        elsif run("c.addi4spn x8, 0x58") then
                -- Expands to: addi rd', x2, nzuimm[9:2]
                c_funct3    := b"000";
                imm         := x"00000058";
                rdp         := b"000";
                inst_i      <= x"XXXX" & c_funct3 & imm(5 downto 4) & imm(9 downto 6) & imm(2) & imm(3) & rdp & b"00";
                wait for 1 ps;

                check_equal(rd_o, b"01" & rdp, "Checking rd");
                check_equal(rs1_o, REG_X2, "Checking rs1");
                check_equal(funct3_o, FUNCT3_ADDSUB, "Checking funct3");
                check_equal(immediate_o, imm, "Checking immediate");
                check_equal(c_inst_o, '1', "Is a C instruction");
                verify_ctrl_sig(OP_IMM);

            --elsif run("c.fld") then
                -- Expands to: fld rd',offset[6:2](rs1')

            elsif run("c.lw x9, 124(x10)") then
                -- Expands to: lw rd', offset[6:2](rs1')
                c_funct3 := b"010";
                rs1p     := b"010";
                rdp      := b"001";
                imm      := x"0000007C";
                inst_i  <= x"XXXX" & c_funct3 & imm(5 downto 3) & rs1p & imm(2) & imm(6) & rdp & b"00";
                wait for 1 ps;

                check_equal(rd_o, b"01" & rdp, "Checking rd");
                check_equal(rs1_o, b"01" & rs1p, "Checking rs1");
                check_equal(funct3_o, FUNCT3_LW, "Checking funct3");
                check_equal(immediate_o, imm, "Checking immediate");
                check_equal(c_inst_o, '1', "Is a C instruction");
                verify_ctrl_sig(OP_LOAD);

            --elsif run("c.flw") then
                -- Expands to: flw rd',offset[6:2](rs1')

            --elsif run("c.fsd") then
                -- Expands to: fsd rs2', offset[6:2](rs1')

            elsif run("c.sw x11, 32(x12)") then
                -- Expands to: sw rs2', offset[6:2](rs1')
                c_funct3 := b"110";
                rs1p     := b"100";
                rs2p     := b"011";
                imm      := x"00000020";
                inst_i <= x"XXXX" & c_funct3 & imm(5 downto 3) & rs1p & imm(2) & imm(6) & rs2p & b"00";
                wait for 1 ps;

                check_equal(rs2_o, b"01" & rs2p, "Checking rs2");
                check_equal(rs1_o, b"01" & rs1p, "Checking rs1");
                check_equal(funct3_o, FUNCT3_SW, "Checking funct3");
                check_equal(immediate_o, imm, "Checking immediate");
                check_equal(c_inst_o, '1', "Is a C instruction");
                verify_ctrl_sig(OP_STORE);

            --elsif run("c.fsw") then
                -- Expands to: fsw rs2', offset[6:2](rs1')

            -- C1
        elsif run("c.addi x4, -3") then
                -- expands to: addi rd, rd, nzimm[5:0]
                rd := REG_X4;
                imm := x"FFFFFFFD";
                c_funct3 := b"000";

                inst_i <= x"XXXX" & c_funct3 & imm(5) & rd & imm(4 downto 0) & b"01";
                wait for 1 ps;

                check_equal(rd_o, rd, "rd /= rd_o");
                check_equal(rs1_o, rd, "rs1 /= rd");
                check_equal(immediate_o, imm, "immediate_o /= imm");
                check_equal(funct3_o, FUNCT3_ADDSUB, "funct3_o /= 0");
                check_equal(c_inst_o, '1', "Is a C instruction");
                verify_ctrl_sig(OP_IMM);

            elsif run("c.jal 64") then
                -- expands to: jal x1, offset[11:1]
                imm := x"00000040";
                c_funct3 := b"001";

                inst_i <= x"XXXX" & c_funct3 & imm(11) & imm(4) & imm(9 downto 8) & imm(10) & imm(6) & imm(7) & imm(3 downto 1) & imm(5) & b"01";
                wait for 1 ps;
                check_equal(rd_o, REG_X1, "rd /= x1");
                check_equal(immediate_o, imm, "immediate_o /= imm");
                check(funct3_o = b"000", "funct3_o /= 0");
                check_equal(c_inst_o, '1', "Is a C instruction");
                verify_ctrl_sig(OP_JAL);

            elsif run("c.li x2, 3") then
                -- expands to: addi rd, x0, imm[5:0]
                rd := REG_X2;
                imm := x"00000003";
                c_funct3 := b"010";

                inst_i <= x"XXXX" & c_funct3 & imm(5) & rd & imm(4 downto 0) & b"01";
                wait for 1 ps;

                check_equal(rd_o, rd, "rd /= rd_o");
                check_equal(rs1_o, REG_X0, "rs1 /= 0");
                check_equal(immediate_o, imm, "immediate_o /= imm");
                check_equal(funct3_o, FUNCT3_ADDSUB, "funct3_o /= 0");
                check_equal(c_inst_o, '1', "Is a C instruction");
                verify_ctrl_sig(OP_IMM);

            elsif run("c.addi16sp 0x90") then
                -- expands to: addi x2, x2, nzimm[9:4]
                imm := x"00000090";
                c_funct3 := b"011";
                inst_i <= x"XXXX" & c_funct3 & imm(9) & REG_X2 & imm(4) & imm(6) & imm(8 downto 7) & imm(5) & b"01";
                wait for 1 ps;

                check_equal(rd_o, REG_X2, "rd_o /= x2");
                check_equal(rs1_o, REG_X2, "rs1_o /= x2");
                check_equal(immediate_o, imm, "immediate_o /= imm");
                check_equal(funct3_o, FUNCT3_ADDSUB, "funct3_o /= 0");
                check_equal(c_inst_o, '1', "Is a C instruction");
                verify_ctrl_sig(OP_IMM);

            elsif run("c.lui x1, -53248") then
                -- expands to lui rd, nzimm[17:12]
                imm         := x"FFFF3000";
                c_funct3    := b"011";
                inst_i      <= x"XXXX" & c_funct3 & imm(17) & REG_X1 & imm(16 downto 12) & b"01";
                wait for 1 ps;

                check_equal(rd_o, REG_X1, "rd_o /= x1");
                check_equal(immediate_o, imm, "immediate_o /= imm");
                check_equal(c_inst_o, '1', "Is a C instruction");
                verify_ctrl_sig(OP_LUI);

            elsif run("c.srli x9, 8") then
                -- expands to srli rd', rd' shamt[5:0]
                imm         := x"00000008";
                c_funct3    := b"100";
                rdp         := b"001";

                inst_i <= x"XXXX" & c_funct3 & imm(5) & b"00" & rdp & imm(4 downto 0) & b"01";
                wait for 1 ps;

                check_equal(rd_o, b"01" & rdp, "rd_o /= rd");
                check_equal(rs1_o, b"01" & rdp, "rs1_o /= rd");
                check_equal(immediate_o, imm, "immediate-o /= imm");
                check_equal(funct3_o, FUNCT3_SR, "funct3 /= 5");
                check_equal(funct7_o, std_logic_vector'(b"0000000"), "wrong funct7");
                check_equal(c_inst_o, '1', "Is a C instruction");
                verify_ctrl_sig(OP_IMM);

            elsif run("c.srai x9, 8") then
                -- expands to srai rd', rd', shamt[5:0]
                imm := x"00000408";
                c_funct3 := b"100";
                rdp := b"001";

                inst_i <= x"XXXX" & c_funct3 & imm(5) & b"01" & rdp & imm(4 downto 0) & b"01";
                wait for 1 ps;

                check_equal(rd_o, b"01" & rdp, "rd_o /= rd");
                check_equal(rs1_o, b"01" & rdp, "rs1_o /= rd");
                check_equal(immediate_o, imm, "immediate-o /= imm");
                check_equal(funct3_o, FUNCT3_SR, "funct3 /= 5");
                check_equal(funct7_o, std_logic_vector'(b"0100000"), "wrong funct7");
                check_equal(c_inst_o, '1', "Is a C instruction");
                verify_ctrl_sig(OP_IMM);

            elsif run("c.andi x15, 1F") then
                -- expands to andi rd', rd', imm[5:0]
                imm := x"FFFFFFFF";
                c_funct3 := b"100";
                rdp := b"111";

                inst_i <= x"XXXX" & c_funct3 & imm(5) & b"10" & rdp & imm(4 downto 0) & b"01";
                wait for 1 ps;

                check_equal(rd_o, b"01" & rdp, "rd_o /= rd");
                check_equal(rs1_o, b"01" & rdp, "rs1_o /= rd");
                check_equal(immediate_o, imm, "immediate-o /= imm");
                check_equal(funct3_o, FUNCT3_AND, "funct3 /= 7");
                check_equal(c_inst_o, '1', "Is a C instruction");
                verify_ctrl_sig(OP_IMM);

            elsif run("c.sub x12, x8") then
                -- expands to sub rd', rd', rs2'
                rdp := b"011";
                rs2p := b"000";
                c_funct3 := b"100";
                inst_i <= x"XXXX" & c_funct3 & '0' & b"11" & rdp & b"00" & rs2p & b"01";
                wait for 1 ps;

                check_equal(rd_o, b"01" & rdp, "rd_o /= rd");
                check_equal(rs1_o, b"01" & rdp, "rs1_o /= rd");
                check_equal(rs2_o, b"01" & rs2p, "rs2_o /= rs2");
                check_equal(funct3_o, FUNCT3_ADDSUB, "funct3 /= 0");
                check_equal(funct7_o, std_logic_vector'(b"0100000"), "funct7 /= sub");
                check_equal(c_inst_o, '1', "Is a C instruction");
                verify_ctrl_sig(OP_OP);

            elsif run("c.xor x12, x8") then
                -- expands to xor rd', rd', rs2'
                rdp := b"011";
                rs2p := b"000";
                c_funct3 := b"100";
                inst_i <= x"XXXX" & c_funct3 & '0' & b"11" & rdp & b"01" & rs2p & b"01";
                wait for 1 ps;

                check_equal(rd_o, b"01" & rdp, "rd_o /= rd");
                check_equal(rs1_o, b"01" & rdp, "rs1_o /= rd");
                check_equal(rs2_o, b"01" & rs2p, "rs2_o /= rs2");
                check_equal(funct3_o, FUNCT3_XOR, "funct3 /= 4");
                check_equal(funct7_o, std_logic_vector'(b"0000000"), "funct7 /= 0");
                check_equal(c_inst_o, '1', "Is a C instruction");
                verify_ctrl_sig(OP_OP);

            elsif run("c.or x12, x8") then
                -- expands to or rd', rd', rs2'
                rdp := b"011";
                rs2p := b"000";
                c_funct3 := b"100";
                inst_i <= x"XXXX" & c_funct3 & '0' & b"11" & rdp & b"10" & rs2p & b"01";
                wait for 1 ps;

                check_equal(rd_o, b"01" & rdp, "rd_o /= rd");
                check_equal(rs1_o, b"01" & rdp, "rs1_o /= rd");
                check_equal(rs2_o, b"01" & rs2p, "rs2_o /= rs2");
                check_equal(funct3_o, FUNCT3_OR, "funct3 /= 6");
                check_equal(funct7_o, std_logic_vector'(b"0000000"), "funct7 /= 0");
                check_equal(c_inst_o, '1', "Is a C instruction");
                verify_ctrl_sig(OP_OP);

            elsif run("c.and x12, x8") then
                -- expands to and rd', rd', rs2'
                rdp := b"011";
                rs2p := b"000";
                c_funct3 := b"100";
                inst_i <= x"XXXX" & c_funct3 & '0' & b"11" & rdp & b"11" & rs2p & b"01";
                wait for 1 ps;

                check_equal(rd_o, b"01" & rdp, "rd_o /= rd");
                check_equal(rs1_o, b"01" & rdp, "rs1_o /= rd");
                check_equal(rs2_o, b"01" & rs2p, "rs2_o /= rs2");
                check_equal(funct3_o, FUNCT3_AND, "funct3 /= 7");
                check_equal(funct7_o, std_logic_vector'(b"0000000"), "funct7 /= 0");
                check_equal(c_inst_o, '1', "Is a C instruction");
                verify_ctrl_sig(OP_OP);

            elsif run("c.j -64") then
                -- expands to jal x0, offset[11:1]
                imm := x"FFFFFFC0";
                c_funct3 := b"101";

                inst_i <= x"XXXX" & c_funct3 & imm(11) & imm(4) & imm(9 downto 8) & imm(10) & imm(6) & imm(7) & imm(3 downto 1) & imm(5) & b"01";
                wait for 1 ps;
                check_equal(rd_o, REG_X0, "rd /= x0");
                check_equal(immediate_o, imm, "immediate_o /= imm");
                check_equal(funct3_o, std_logic_vector'(b"000"), "funct3_o /= 0");
                check_equal(c_inst_o, '1', "Is a C instruction");
                verify_ctrl_sig(OP_JAL);

            elsif run("c.beqz x10, 32") then
                -- expands to beq rs1', x0, offset[8:1]
                imm         := x"00000020";
                rs1p        := b"010";
                c_funct3    := b"110";
                inst_i      <= x"XXXX" & c_funct3 & imm(8) & imm(4 downto 3) & rs1p & imm(7 downto 6) & imm(2 downto 1) & imm(5) & b"01";
                wait for 1 ps;

                check_equal(rs1_o, REG_X10, "rs1 /= x10");
                check_equal(rs2_o, REG_X0, "rs2 /= x0");
                check_equal(immediate_o, imm, "immediate_o /= imm");
                check_equal(funct3_o, FUNCT3_BEQ, "funct3_o /= 0");
                check_equal(c_inst_o, '1', "Is a C instruction");
                verify_ctrl_sig(OP_BRANCH);

            elsif run("c.bnez x10, -32") then
                -- expands to bnez rs1', x0, offset[8:1]
                imm := x"FFFFFFE0";
                rs1p := b"010";
                c_funct3 := b"111";
                inst_i <= x"XXXX" & c_funct3 & imm(8) & imm(4 downto 3) & rs1p & imm(7 downto 6) & imm(2 downto 1) & imm(5) & b"01";
                wait for 1 ps;

                check_equal(rs1_o, REG_X10, "rs1 /= x10");
                check_equal(rs2_o, REG_X0, "rs2 /= x0");
                check_equal(immediate_o, imm, "immediate_o /= imm");
                check_equal(funct3_o, FUNCT3_BNE, "funct3_o /= 1");
                check_equal(c_inst_o, '1', "Is a C instruction");
                verify_ctrl_sig(OP_BRANCH);

            -- C2

        elsif run("c.slli x5, 15") then
                -- expands to slli rd, rd, shamt[5:0]
                rd := REG_X5;
                imm := x"0000000F";
                c_funct3 := b"000";

                inst_i <= x"XXXX" & c_funct3 & imm(5) & rd & imm(4 downto 0) & b"10";
                wait for 1 ps;

                check_equal(rd_o, rd, "rd_o /= rd");
                check_equal(rs1_o, rd, "rs1_o =/ rd");
                check_equal(immediate_o, imm, "immediate_o /= immediate");
                check_equal(funct3_o, std_logic_vector'(b"001"), "funct3 /= 1");
                check_equal(c_inst_o, '1', "Is a C instruction");
                verify_ctrl_sig(OP_IMM);

            --elsif run("c.fldsp") then
                -- Expands to: fld rd',offset[6:2](x2)

            elsif run("c.lwsp x15, 80") then
                -- Expands to: lw rd',offset[6:2](x2)
                c_funct3 := b"010";
                rd       := b"01111";
                imm      := x"0000007C";
                inst_i <= x"XXXX" & c_funct3 & imm(5) & rd & imm(4 downto 2) & imm(7 downto 6) & b"10";
                wait for 1 ps;

                check_equal(rd_o, rd, "rd_o /= rd");
                check_equal(rs1_o, REG_SP, "rs1 /= SP");
                check_equal(funct3_o, FUNCT3_LW, "funct3 /= funct3_lw");
                check_equal(immediate_o, imm, "imm /= 80");
                check_equal(c_inst_o, '1', "Is a C instruction");
                verify_ctrl_sig(OP_LOAD);

            --elsif run("c.flwsp") then
                -- Expands to: flw rd',offset[6:2](x2)

            elsif run("c.jr x4") then
                -- expands to: jalr x0,0(rs1)
                c_funct3 := b"100";
                rs1 := REG_X4;
                rs2 := (others => '0');
                imm := (others => '0');
                inst_i <= x"XXXX" & c_funct3 & '0' & rs1 & rs2 & b"10";
                wait for 1 ps;

                check_equal(rd_o, REG_X0, "rd /= 0");
                check_equal(rs1_o, rs1, "rs1 /= 4");
                check_equal(rs2_o, rs2, "rs2 /= rs2");
                check_equal(immediate_o, imm, "immediate_o /= imm");
                check_equal(funct3_o, std_logic_vector'(b"000"), "funct3 /= 0");
                check_equal(c_inst_o, '1', "Is a C instruction");
                verify_ctrl_sig(OP_JALR);

            elsif run("c.mv x3, x8") then
                -- expands to add rd, x0, rs2
                c_funct3 := b"100";
                rs1 := REG_X0;
                rs2 := REG_X8;
                rd  := REG_X3;
                inst_i <= x"XXXX" & c_funct3 & '0' & rd & rs2 & b"10";

                wait for 1 ps;

                check_equal(rd_o, rd, "rd_o /= rd");
                check_equal(rs1_o, rs1, "rs1_o /= rs1");
                check_equal(rs2_o, rs2, "rs2_o /= rs2");
                check_equal(funct3_o, FUNCT3_ADDSUB, "funct3 /= 0");
                check_equal(c_inst_o, '1', "Is a C instruction");
                verify_ctrl_sig(OP_OP);

        --    elsif run("c.ebreak") then
                -- expands to EBREAK
                --c_funct3 := b"100";

            elsif run("c.jalr x4") then
                -- expands to: jalr x1, 0(rs1)
                c_funct3 := b"100";
                rs1 := REG_X4;
                rs2 := (others => '0');
                imm := (others => '0');
                inst_i <= x"XXXX" & c_funct3 & '1' & rs1 & rs2 & b"10";
                wait for 1 ps;

                check_equal(rd_o, REG_X1, "rd /= 1");
                check_equal(rs1_o, rs1, "rd /= 0");
                check_equal(rs2_o, rs2, "rs2 /= rs2");
                check_equal(immediate_o, imm, "immediate_o /= imm");
                check_equal(funct3_o, std_logic_vector'(b"000"), "funct3 /= 0");
                check_equal(c_inst_o, '1', "Is a C instruction");
                verify_ctrl_sig(OP_JALR);

            elsif run("c.add x3, x8") then
                -- expands to: add rd, rd, rs2
                c_funct3 := b"100";
                rd  := REG_X3;
                rs1 := rd;
                rs2 := REG_X8;
                inst_i <= x"XXXX" & c_funct3 & '1' & rd & rs2 & b"10";

                wait for 1 ps;

                check_equal(rd_o, rd, "rd_o /= rd");
                check_equal(rs1_o, rs1, "rs1_o /= rs1");
                check_equal(rs2_o, rs2, "rs2_o /= rs2");
                check_equal(funct3_o, FUNCT3_ADDSUB, "funct3 /= 0");
                check_equal(c_inst_o, '1', "Is a C instruction");
                verify_ctrl_sig(OP_OP);

            --elsif run("c.fsdsp") then
                -- Expands to: fsd rs2', offset[6:2](x2)

            elsif run("c.swsp x7, 4") then
                -- Expands to: sw rs2', offset[6:2](x2)
                c_funct3 := b"110";
                rs2     := b"00111";
                imm      := x"00000004";
                inst_i <= x"XXXX" & c_funct3 & imm(5 downto 2) & imm(7 downto 6) & rs2 & b"10";
                wait for 1 ps;

                check_equal(rs2_o, rs2, "rs2_o /= rs2");
                check_equal(rs1_o, REG_SP, "rs1_o /= SP");
                check_equal(funct3_o, FUNCT3_SW, "funct3 /= funct3_lw");
                check_equal(immediate_o, imm, "imm /= 4");
                check_equal(c_inst_o, '1', "Is a C instruction");
                verify_ctrl_sig(OP_STORE);
            --elsif run("c.fswsp") then
                -- Expands to: fsw rs2', offset[6:2](x2)

            -- Erronous decodings

            end if;
        end loop;

        test_runner_cleanup(runner);
    end process;

end architecture tb;
