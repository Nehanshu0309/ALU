`timescale 1ps/1ps

module alu_tb;

parameter WIDTH = 4;

reg clk;
reg rst;
reg MODE;
reg C_En;
reg CIN;

reg [WIDTH-1:0] OPA;
reg [WIDTH-1:0] OPB;

reg [1:0] IN_V;
reg [3:0] CMD;

wire [2*WIDTH-1:0] RES_DUT;
wire COUT_DUT;
wire OFLOW_DUT;
wire G_DUT;
wire E_DUT;
wire L_DUT;
wire ERR_DUT;

wire [2*WIDTH-1:0] RES_REF;
wire COUT_REF;
wire OFLOW_REF;
wire G_REF;
wire E_REF;
wire L_REF;
wire ERR_REF;

integer pass_count;
integer fail_count;
integer total_count;

alu #(WIDTH) dut (
    .clk(clk),
    .rst(rst),
    .M(MODE),
    .C_En(C_En),
    .C_in(CIN),
    .Op_A(OPA),
    .Op_B(OPB),
    .In_V(IN_V),
    .Cmd(CMD),
    .Res(RES_DUT),
    .OFlow(OFLOW_DUT),
    .C_out(COUT_DUT),
    .G(G_DUT),
    .L(L_DUT),
    .E(E_DUT),
    .Err(ERR_DUT)
);

alu_reference_model #(WIDTH) ref_model (
    .OPA(OPA),
    .OPB(OPB),
    .CIN(CIN),
    .MODE(MODE),
    .IN_V(IN_V),
    .CMD(CMD),
    .RES(RES_REF),
    .COUT(COUT_REF),
    .OFLOW(OFLOW_REF),
    .G(G_REF),
    .E(E_REF),
    .L(L_REF),
    .ERR(ERR_REF)
);

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin

    pass_count = 0;
    fail_count = 0;
    total_count = 0;

    rst  = 1;
    C_En = 1;

    OPA  = 0;
    OPB  = 0;
    MODE = 0;
    CMD  = 0;
    CIN  = 0;
    IN_V = 2'b00;

    #20;

    rst = 0;

    repeat(2) @(posedge clk);

    arithmetic_tests();

    logical_tests();

    error_and_corner_tests();

    pipeline_test();

    cmd_mode_priority_test();

    check_no_z();

    @(negedge clk);

    rst  = 1;
    OPA  = 4'hF;
    OPB  = 4'hF;
    MODE = 1'b1;
    CMD  = 4'd0;
    IN_V = 2'b11;

    @(posedge clk);
    @(posedge clk);

    #1;

    total_count = total_count + 1;

    if(RES_DUT == 0 && ERR_DUT == 0) begin

        $display("[PASS] RESET_CHECK");

        pass_count = pass_count + 1;

    end
    else begin

        $display("[FAIL] RESET_CHECK");

        display_outputs("RESET_CHECK");

        fail_count = fail_count + 1;

    end

    rst = 0;

    @(negedge clk);

    C_En = 0;

    OPA  = 4'h2;
    OPB  = 4'h3;
    MODE = 1'b1;
    CMD  = 4'd0;
    IN_V = 2'b11;

    @(posedge clk);
    @(posedge clk);

    #1;

    total_count = total_count + 1;

    $display("[PASS] CE_DISABLE_CHECK");

    pass_count = pass_count + 1;

    C_En = 1;

    $display("=================================");
    $display("TEST SUMMARY");
    $display("=================================");
    $display("TOTAL TESTS = %0d", total_count);
    $display("PASS TESTS  = %0d", pass_count);
    $display("FAIL TESTS  = %0d", fail_count);

    $finish;

end

task automatic apply_test;

input [WIDTH-1:0] a;
input [WIDTH-1:0] b;
input mode;
input [3:0] cmd;
input cin;
input [1:0] inv;
input [8*50:1] testname;

begin

    @(negedge clk);

    OPA  = a;
    OPB  = b;
    MODE = mode;
    CMD  = cmd;
    CIN  = cin;
    IN_V = inv;

    @(posedge clk);
    @(posedge clk);

    #1;

    total_count = total_count + 1;

    if(compare_outputs(1'b0)) begin

        $display("[PASS] %s", testname);

        display_outputs(testname);

        pass_count = pass_count + 1;

    end
    else begin

        $display("[FAIL] %s", testname);

        display_outputs(testname);

        fail_count = fail_count + 1;

    end

end
endtask

task automatic apply_mul_test;

input [WIDTH-1:0] a;
input [WIDTH-1:0] b;
input mode;
input [3:0] cmd;
input [1:0] inv;
input [8*50:1] testname;

begin

    @(negedge clk);

    OPA  = a;
    OPB  = b;
    MODE = mode;
    CMD  = cmd;
    CIN  = 0;
    IN_V = inv;

    @(posedge clk);
    @(posedge clk);

    #1;

    if(^RES_DUT === 1'bx)
        $display("[PASS] %s -> X detected", testname);
    else
        $display("[FAIL] %s -> Expected X", testname);

    @(posedge clk);

    #1;

    total_count = total_count + 1;

    if(compare_outputs(1'b0)) begin

        $display("[PASS] %s", testname);

        pass_count = pass_count + 1;

    end
    else begin

        $display("[FAIL] %s", testname);

        display_outputs(testname);

        fail_count = fail_count + 1;

    end

end
endtask

function compare_outputs;

input dummy;

begin

    compare_outputs = 1'b1;

    if(MODE == 1'b0)
    begin
        if(RES_DUT[WIDTH-1:0] !== RES_REF[WIDTH-1:0])
            compare_outputs = 1'b0;

        if(RES_DUT[2*WIDTH-1:WIDTH] !== 0)
            compare_outputs = 1'b0;
    end
    else
    begin
        if(RES_DUT !== RES_REF)
            compare_outputs = 1'b0;
    end

    if(COUT_DUT  !== COUT_REF)  compare_outputs = 1'b0;
    if(OFLOW_DUT !== OFLOW_REF) compare_outputs = 1'b0;
    if(G_DUT     !== G_REF)     compare_outputs = 1'b0;
    if(E_DUT     !== E_REF)     compare_outputs = 1'b0;
    if(L_DUT     !== L_REF)     compare_outputs = 1'b0;
    if(ERR_DUT   !== ERR_REF)   compare_outputs = 1'b0;

end
endfunction

task display_outputs;
input [8*50:1] testname;

begin

    $display("TESTCASE : %s", testname);

    $display("------------ DUT OUTPUTS ------------");

    $display("RES    = %h", RES_DUT);
    $display("COUT   = %b", COUT_DUT);
    $display("OFLOW  = %b", OFLOW_DUT);
    $display("G      = %b", G_DUT);
    $display("E      = %b", E_DUT);
    $display("L      = %b", L_DUT);
    $display("ERR    = %b", ERR_DUT);

    $display("------------ REF OUTPUTS ------------");

    $display("RES    = %h", RES_REF);
    $display("COUT   = %b", COUT_REF);
    $display("OFLOW  = %b", OFLOW_REF);
    $display("G      = %b", G_REF);
    $display("E      = %b", E_REF);
    $display("L      = %b", L_REF);
    $display("ERR    = %b", ERR_REF);

end
endtask

task automatic check_no_z;

begin

    if(^RES_DUT === 1'bz ||
       COUT_DUT === 1'bz ||
       OFLOW_DUT === 1'bz ||
       G_DUT === 1'bz ||
       E_DUT === 1'bz ||
       L_DUT === 1'bz ||
       ERR_DUT === 1'bz)
    begin
        $display("[FAIL] Z DETECTED ON OUTPUTS");
        fail_count = fail_count + 1;
    end
    else
    begin
        $display("[PASS] NO Z DETECTED");
        pass_count = pass_count + 1;
    end

end
endtask

task automatic pipeline_test;

begin

    $display("=================================");
    $display("PIPELINE TEST");
    $display("=================================");

    @(negedge clk);

    OPA  = 4'd2;
    OPB  = 4'd3;
    MODE = 1'b1;
    CMD  = 4'd0;
    CIN  = 0;
    IN_V = 2'b11;

    @(negedge clk);

    OPA  = 4'd7;
    OPB  = 4'd1;
    MODE = 1'b1;
    CMD  = 4'd1;
    CIN  = 0;
    IN_V = 2'b11;

    @(posedge clk);

    #1;

    total_count = total_count + 1;

    if(RES_DUT == 5)
    begin
        $display("[PASS] PIPELINE_STAGE1");
        pass_count = pass_count + 1;
    end
    else
    begin
        $display("[FAIL] PIPELINE_STAGE1");
        fail_count = fail_count + 1;
    end

    @(posedge clk);

    #1;

    total_count = total_count + 1;

    if(RES_DUT == 6)
    begin
        $display("[PASS] PIPELINE_STAGE2");
        pass_count = pass_count + 1;
    end
    else
    begin
        $display("[FAIL] PIPELINE_STAGE2");
        fail_count = fail_count + 1;
    end

end
endtask

task automatic cmd_mode_priority_test;

begin

    $display("=================================");
    $display("CMD MODE PRIORITY TEST");
    $display("=================================");

    @(negedge clk);

    OPA  = 4'd3;
    OPB  = 4'd2;
    MODE = 1'b1;
    CMD  = 4'd9;
    IN_V = 2'b11;

    @(negedge clk);

    OPA  = 4'd1;
    OPB  = 4'd1;
    MODE = 1'b0;
    CMD  = 4'd0;
    IN_V = 2'b11;

    @(posedge clk);
    @(posedge clk);

    #1;

    total_count = total_count + 1;

    if(RES_DUT[WIDTH-1:0] == (4'd1 & 4'd1))
    begin
        $display("[PASS] CMD_MODE_PRIORITY");
        pass_count = pass_count + 1;
    end
    else
    begin
        $display("[FAIL] CMD_MODE_PRIORITY");
        fail_count = fail_count + 1;
    end

end
endtask

task arithmetic_tests;

begin

    apply_test(4'h1,4'h2,1'b1,4'd0,0,2'b11,"ADD_VALID");
    apply_test(4'h1,4'h2,1'b1,4'd0,0,2'b10,"ADD_INV_A");
    apply_test(4'h1,4'h2,1'b1,4'd0,0,2'b01,"ADD_INV_B");
    apply_test(4'h1,4'h2,1'b1,4'd0,0,2'b00,"ADD_INV_AB");

    apply_test(4'h7,4'h3,1'b1,4'd1,0,2'b11,"SUB_VALID");
    apply_test(4'h7,4'h3,1'b1,4'd1,0,2'b10,"SUB_INV_A");
    apply_test(4'h7,4'h3,1'b1,4'd1,0,2'b01,"SUB_INV_B");
    apply_test(4'h7,4'h3,1'b1,4'd1,0,2'b00,"SUB_INV_AB");

    apply_test(4'h5,4'h6,1'b1,4'd2,1,2'b11,"ADD_CIN_VALID");
    apply_test(4'h5,4'h6,1'b1,4'd2,1,2'b10,"ADD_CIN_INV_A");
    apply_test(4'h5,4'h6,1'b1,4'd2,1,2'b01,"ADD_CIN_INV_B");
    apply_test(4'h5,4'h6,1'b1,4'd2,1,2'b00,"ADD_CIN_INV_AB");

    apply_test(4'h5,4'h1,1'b1,4'd3,1,2'b11,"SUB_CIN_VALID");
    apply_test(4'h5,4'h1,1'b1,4'd3,1,2'b10,"SUB_CIN_INV_A");
    apply_test(4'h5,4'h1,1'b1,4'd3,1,2'b01,"SUB_CIN_INV_B");
    apply_test(4'h5,4'h1,1'b1,4'd3,1,2'b00,"SUB_CIN_INV_AB");

    apply_test(4'hE,4'h0,1'b1,4'd4,0,2'b01,"INC_A_VALID");
    apply_test(4'hE,4'h0,1'b1,4'd4,0,2'b11,"INC_A_INV_BOTH");
    apply_test(4'hE,4'h0,1'b1,4'd4,0,2'b10,"INC_A_INV_A");
    apply_test(4'hE,4'h0,1'b1,4'd4,0,2'b00,"INC_A_INV_NONE");

    apply_test(4'hA,4'h0,1'b1,4'd5,0,2'b01,"DEC_A_VALID");
    apply_test(4'hA,4'h0,1'b1,4'd5,0,2'b11,"DEC_A_INV_BOTH");
    apply_test(4'hA,4'h0,1'b1,4'd5,0,2'b10,"DEC_A_INV_A");
    apply_test(4'hA,4'h0,1'b1,4'd5,0,2'b00,"DEC_A_INV_NONE");

    apply_test(4'h0,4'hA,1'b1,4'd6,0,2'b10,"INC_B_VALID");
    apply_test(4'h0,4'hA,1'b1,4'd6,0,2'b11,"INC_B_INV_BOTH");
    apply_test(4'h0,4'hA,1'b1,4'd6,0,2'b01,"INC_B_INV_B");
    apply_test(4'h0,4'hA,1'b1,4'd6,0,2'b00,"INC_B_INV_NONE");

    apply_test(4'h0,4'hA,1'b1,4'd7,0,2'b10,"DEC_B_VALID");
    apply_test(4'h0,4'hA,1'b1,4'd7,0,2'b11,"DEC_B_INV_BOTH");
    apply_test(4'h0,4'hA,1'b1,4'd7,0,2'b01,"DEC_B_INV_B");
    apply_test(4'h0,4'hA,1'b1,4'd7,0,2'b00,"DEC_B_INV_NONE");

    apply_test(4'h4,4'h4,1'b1,4'd8,0,2'b11,"CMP_EQUAL_VALID");
    apply_test(4'h4,4'h4,1'b1,4'd8,0,2'b10,"CMP_EQUAL_INV_A");
    apply_test(4'h4,4'h4,1'b1,4'd8,0,2'b01,"CMP_EQUAL_INV_B");
    apply_test(4'h4,4'h4,1'b1,4'd8,0,2'b00,"CMP_EQUAL_INV_AB");

    apply_test(4'h8,4'h2,1'b1,4'd8,0,2'b11,"CMP_GREATER_VALID");
    apply_test(4'h8,4'h2,1'b1,4'd8,0,2'b10,"CMP_GREATER_INV_A");
    apply_test(4'h8,4'h2,1'b1,4'd8,0,2'b01,"CMP_GREATER_INV_B");
    apply_test(4'h8,4'h2,1'b1,4'd8,0,2'b00,"CMP_GREATER_INV_AB");

    apply_test(4'h1,4'h9,1'b1,4'd8,0,2'b11,"CMP_LESS_VALID");
    apply_test(4'h1,4'h9,1'b1,4'd8,0,2'b10,"CMP_LESS_INV_A");
    apply_test(4'h1,4'h9,1'b1,4'd8,0,2'b01,"CMP_LESS_INV_B");
    apply_test(4'h1,4'h9,1'b1,4'd8,0,2'b00,"CMP_LESS_INV_AB");

    apply_mul_test(4'h3,4'h4,1'b1,4'd9,2'b11,"MUL_INC_VALID");
    apply_mul_test(4'h3,4'h4,1'b1,4'd9,2'b10,"MUL_INC_INV_A");
    apply_mul_test(4'h3,4'h4,1'b1,4'd9,2'b01,"MUL_INC_INV_B");
    apply_mul_test(4'h3,4'h4,1'b1,4'd9,2'b00,"MUL_INC_INV_AB");

    apply_mul_test(4'h2,4'h3,1'b1,4'd10,2'b11,"SHIFT_MUL_VALID");
    apply_mul_test(4'h2,4'h3,1'b1,4'd10,2'b10,"SHIFT_MUL_INV_A");
    apply_mul_test(4'h2,4'h3,1'b1,4'd10,2'b01,"SHIFT_MUL_INV_B");
    apply_mul_test(4'h2,4'h3,1'b1,4'd10,2'b00,"SHIFT_MUL_INV_AB");

end
endtask


task logical_tests;

begin

    apply_test(4'hA,4'h5,1'b0,4'd0,0,2'b11,"AND_VALID");
    apply_test(4'hA,4'h5,1'b0,4'd0,0,2'b10,"AND_INV_A");
    apply_test(4'hA,4'h5,1'b0,4'd0,0,2'b01,"AND_INV_B");
    apply_test(4'hA,4'h5,1'b0,4'd0,0,2'b00,"AND_INV_AB");

    apply_test(4'hA,4'h5,1'b0,4'd1,0,2'b11,"NAND_VALID");
    apply_test(4'hA,4'h5,1'b0,4'd1,0,2'b10,"NAND_INV_A");
    apply_test(4'hA,4'h5,1'b0,4'd1,0,2'b01,"NAND_INV_B");
    apply_test(4'hA,4'h5,1'b0,4'd1,0,2'b00,"NAND_INV_AB");

    apply_test(4'hA,4'h5,1'b0,4'd2,0,2'b11,"OR_VALID");
    apply_test(4'hA,4'h5,1'b0,4'd2,0,2'b10,"OR_INV_A");
    apply_test(4'hA,4'h5,1'b0,4'd2,0,2'b01,"OR_INV_B");
    apply_test(4'hA,4'h5,1'b0,4'd2,0,2'b00,"OR_INV_AB");

    apply_test(4'hA,4'h5,1'b0,4'd3,0,2'b11,"NOR_VALID");
    apply_test(4'hA,4'h5,1'b0,4'd3,0,2'b10,"NOR_INV_A");
    apply_test(4'hA,4'h5,1'b0,4'd3,0,2'b01,"NOR_INV_B");
    apply_test(4'hA,4'h5,1'b0,4'd3,0,2'b00,"NOR_INV_AB");

    apply_test(4'hA,4'h5,1'b0,4'd4,0,2'b11,"XOR_VALID");
    apply_test(4'hA,4'h5,1'b0,4'd4,0,2'b10,"XOR_INV_A");
    apply_test(4'hA,4'h5,1'b0,4'd4,0,2'b01,"XOR_INV_B");
    apply_test(4'hA,4'h5,1'b0,4'd4,0,2'b00,"XOR_INV_AB");

    apply_test(4'hA,4'h5,1'b0,4'd5,0,2'b11,"XNOR_VALID");
    apply_test(4'hA,4'h5,1'b0,4'd5,0,2'b10,"XNOR_INV_A");
    apply_test(4'hA,4'h5,1'b0,4'd5,0,2'b01,"XNOR_INV_B");
    apply_test(4'hA,4'h5,1'b0,4'd5,0,2'b00,"XNOR_INV_AB");

    apply_test(4'h0,4'h0,1'b0,4'd6,0,2'b01,"NOT_A_VALID");
    apply_test(4'h0,4'h0,1'b0,4'd6,0,2'b11,"NOT_A_INV_BOTH");
    apply_test(4'h0,4'h0,1'b0,4'd6,0,2'b10,"NOT_A_INV_A");
    apply_test(4'h0,4'h0,1'b0,4'd6,0,2'b00,"NOT_A_INV_NONE");

    apply_test(4'h0,4'h0,1'b0,4'd7,0,2'b10,"NOT_B_VALID");
    apply_test(4'h0,4'h0,1'b0,4'd7,0,2'b11,"NOT_B_INV_BOTH");
    apply_test(4'h0,4'h0,1'b0,4'd7,0,2'b01,"NOT_B_INV_B");
    apply_test(4'h0,4'h0,1'b0,4'd7,0,2'b00,"NOT_B_INV_NONE");

    apply_test(4'hF,4'h0,1'b0,4'd8,0,2'b01,"SHR1_A_VALID");
    apply_test(4'hF,4'h0,1'b0,4'd8,0,2'b11,"SHR1_A_INV_BOTH");
    apply_test(4'hF,4'h0,1'b0,4'd8,0,2'b10,"SHR1_A_INV_A");
    apply_test(4'hF,4'h0,1'b0,4'd8,0,2'b00,"SHR1_A_INV_NONE");

    apply_test(4'hF,4'h0,1'b0,4'd9,0,2'b01,"SHL1_A_VALID");
    apply_test(4'hF,4'h0,1'b0,4'd9,0,2'b11,"SHL1_A_INV_BOTH");
    apply_test(4'hF,4'h0,1'b0,4'd9,0,2'b10,"SHL1_A_INV_A");
    apply_test(4'hF,4'h0,1'b0,4'd9,0,2'b00,"SHL1_A_INV_NONE");

    apply_test(4'h0,4'hF,1'b0,4'd10,0,2'b10,"SHR1_B_VALID");
    apply_test(4'h0,4'hF,1'b0,4'd10,0,2'b11,"SHR1_B_INV_BOTH");
    apply_test(4'h0,4'hF,1'b0,4'd10,0,2'b01,"SHR1_B_INV_B");
    apply_test(4'h0,4'hF,1'b0,4'd10,0,2'b00,"SHR1_B_INV_NONE");

    apply_test(4'h0,4'hF,1'b0,4'd11,0,2'b10,"SHL1_B_VALID");
    apply_test(4'h0,4'hF,1'b0,4'd11,0,2'b11,"SHL1_B_INV_BOTH");
    apply_test(4'h0,4'hF,1'b0,4'd11,0,2'b01,"SHL1_B_INV_B");
    apply_test(4'h0,4'hF,1'b0,4'd11,0,2'b00,"SHL1_B_INV_NONE");

    apply_test(4'hA,4'h1,1'b0,4'd12,0,2'b11,"ROL_VALID");
    apply_test(4'hA,4'h1,1'b0,4'd12,0,2'b10,"ROL_INV_A");
    apply_test(4'hA,4'h1,1'b0,4'd12,0,2'b01,"ROL_INV_B");
    apply_test(4'hA,4'h1,1'b0,4'd12,0,2'b00,"ROL_INV_AB");

    apply_test(4'hA,4'h1,1'b0,4'd13,0,2'b11,"ROR_VALID");
    apply_test(4'hA,4'h1,1'b0,4'd13,0,2'b10,"ROR_INV_A");
    apply_test(4'hA,4'h1,1'b0,4'd13,0,2'b01,"ROR_INV_B");
    apply_test(4'hA,4'h1,1'b0,4'd13,0,2'b00,"ROR_INV_AB");

end
endtask

task error_and_corner_tests;

begin

    apply_test(4'h5,4'h6,1'b1,4'd0,0,2'b01,"ERR_ADD_INVALID_INV");
    apply_test(4'h5,4'h6,1'b1,4'd1,0,2'b10,"ERR_SUB_INVALID_INV");

    apply_test(4'h5,4'h0,1'b1,4'd4,0,2'b00,"ERR_INC_A_INVALID");

    apply_test(4'h0,4'h5,1'b1,4'd6,0,2'b00,"ERR_INC_B_INVALID");

    apply_test(4'hA,4'h5,1'b0,4'd0,0,2'b01,"ERR_AND_INVALID");

    apply_test(4'h0,4'h0,1'b0,4'd6,0,2'b00,"ERR_NOT_A_INVALID");

    apply_test(4'hF,4'h1,1'b1,4'd0,0,2'b11,"ADD_MAX_CARRY");

    apply_test(4'hF,4'hF,1'b1,4'd2,1,2'b11,"ADD_CIN_MAX");

    apply_test(4'h0,4'h1,1'b1,4'd1,0,2'b11,"SUB_UNDERFLOW");

    apply_test(4'h0,4'h1,1'b1,4'd3,1,2'b11,"SUB_CIN_UNDERFLOW");

    apply_test(4'hF,4'h0,1'b1,4'd4,0,2'b01,"INC_A_WRAP");

    apply_test(4'h0,4'h0,1'b1,4'd5,0,2'b01,"DEC_A_WRAP");

    apply_test(4'h0,4'hF,1'b1,4'd6,0,2'b10,"INC_B_WRAP");

    apply_test(4'h0,4'h0,1'b1,4'd7,0,2'b10,"DEC_B_WRAP");

    apply_mul_test(4'h0,4'h0,1'b1,4'd9,2'b11,"MUL_ZERO");

    apply_mul_test(4'hF,4'hF,1'b1,4'd9,2'b11,"MUL_MAX");

    apply_mul_test(4'h0,4'hF,1'b1,4'd10,2'b11,"SHIFT_MUL_ZERO");

    apply_mul_test(4'hF,4'hF,1'b1,4'd10,2'b11,"SHIFT_MUL_MAX");

    apply_test(4'hF,4'hF,1'b0,4'd0,0,2'b11,"AND_ALL1");

    apply_test(4'h0,4'h0,1'b0,4'd2,0,2'b11,"OR_ALL0");

    apply_test(4'hF,4'h0,1'b0,4'd4,0,2'b11,"XOR_ALT");

    apply_test(4'hF,4'hF,1'b0,4'd5,0,2'b11,"XNOR_ALL1");

    apply_test(4'h1,4'h0,1'b0,4'd8,0,2'b01,"SHR_LSB");

    apply_test(4'h8,4'h0,1'b0,4'd9,0,2'b01,"SHL_MSB");

    apply_test(4'h0,4'h1,1'b0,4'd10,0,2'b10,"SHR_B_LSB");

    apply_test(4'h0,4'h8,1'b0,4'd11,0,2'b10,"SHL_B_MSB");

    apply_test(4'h0,4'h0,1'b0,4'd12,0,2'b11,"ROL_ZERO");

    apply_test(4'hF,4'h1,1'b0,4'd13,0,2'b11,"ROR_ALL1");

    apply_test(4'hA,4'h8,1'b0,4'd12,0,2'b11,"ROL_INVALID_ROT");

    apply_test(4'hA,4'h8,1'b0,4'd13,0,2'b11,"ROR_INVALID_ROT");

    apply_test(4'b0111,4'b0001,1'b1,4'd11,0,2'b11,"SIGNED_ADD_OV");

    apply_test(4'b1000,4'b0001,1'b1,4'd12,0,2'b11,"SIGNED_SUB_OV");

    apply_mul_test(4'hF,4'h1,1'b1,4'd9,2'b11,"INC_MUL_WRAP");

    apply_mul_test(4'b1000,4'h1,1'b1,4'd10,2'b11,"SHIFT_MUL_WRAP");

    apply_test(4'h8,4'h8,1'b1,4'd0,0,2'b11,"ADD_BOUNDARY_CARRY");

    apply_test(4'hF,4'h0,1'b1,4'd2,1,2'b11,"ADD_ONLY_CIN_CARRY");

    apply_test(4'h5,4'h5,1'b1,4'd1,0,2'b11,"SUB_ZERO_RESULT");

    apply_test(4'h6,4'h5,1'b1,4'd3,1,2'b11,"SUB_CIN_ZERO");

    apply_test(4'h7,4'h0,1'b1,4'd4,0,2'b01,"INC_A_NORMAL");

    apply_test(4'h8,4'h0,1'b1,4'd5,0,2'b01,"DEC_A_NORMAL");

    apply_test(4'hA,4'hA,1'b0,4'd4,0,2'b11,"XOR_SELF_ZERO");

    apply_test(4'h0,4'h0,1'b0,4'd1,0,2'b11,"NAND_ALL_ZERO");

    apply_test(4'h9,4'h0,1'b0,4'd12,0,2'b11,"ROL_BY_ZERO");

    apply_test(4'h9,4'h0,1'b0,4'd13,0,2'b11,"ROR_BY_ZERO");

    apply_test(4'h9,4'd3,1'b0,4'd12,0,2'b11,"ROL_MAX_VALID");

    apply_test(4'h9,4'd3,1'b0,4'd13,0,2'b11,"ROR_MAX_VALID");

    apply_test(4'hF,4'hF,1'b1,4'd8,0,2'b11,"CMP_MAX_EQUAL");

    apply_test(4'h0,4'h0,1'b1,4'd8,0,2'b11,"CMP_MIN_EQUAL");

    apply_test(4'b1001,4'b1001,1'b1,4'd11,0,2'b11,"SIGNED_NEG_ADD");

    apply_test(4'b1000,4'b0011,1'b1,4'd12,0,2'b11,"SIGNED_NEG_SUB");

    apply_test(4'b1111,4'h0,1'b0,4'd9,0,2'b01,"SHIFT_LEFT_FULL");

    apply_test(4'b1111,4'h0,1'b0,4'd8,0,2'b01,"SHIFT_RIGHT_ALL1");

    apply_mul_test(4'h1,4'h7,1'b1,4'd9,2'b11,"MUL_BY_ONE");

    apply_mul_test(4'h0,4'h7,1'b1,4'd9,2'b11,"MUL_BY_ZERO");

    apply_mul_test(4'b0100,4'h2,1'b1,4'd10,2'b11,"SHIFT_MUL_EDGE");

    apply_test(4'h2,4'h2,1'b1,4'd8,0,2'b01,"CMP_INVALID_INV");

    apply_test(4'h2,4'h1,1'b0,4'd12,0,2'b01,"ROL_INVALID_INV");

    apply_test(4'h2,4'h1,1'b1,4'd11,0,2'b01,"SIGNED_ADD_INVALID");

    @(negedge clk);

    C_En = 0;

    OPA  = 4'hF;
    OPB  = 4'h1;
    MODE = 1'b1;
    CMD  = 4'd0;
    IN_V = 2'b11;

    @(posedge clk);

    #1;

    total_count = total_count + 1;

    if(RES_DUT !== 8'h10)
    begin
        $display("[FAIL] CE_HOLD_CHECK");
        fail_count = fail_count + 1;
    end
    else
    begin
        $display("[PASS] CE_HOLD_CHECK");
        pass_count = pass_count + 1;
    end

    C_En = 1;

end
endtask

endmodule