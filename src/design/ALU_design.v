module ALU_design #(
    parameter WIDTH     = 8,
    parameter CMD_WIDTH = 4
)(
    input  wire [WIDTH-1:0] OPA,
    input  wire [WIDTH-1:0] OPB,
    input  wire             CIN,
    input  wire             CLK,
    input  wire             RST,
    input  wire             CE,
    input  wire             MODE,
    input  wire [1:0]       INP_VALID,
    input  wire [CMD_WIDTH-1:0] CMD,

    output reg  [(2*WIDTH)-1:0] RES,
    output reg                  OFLOW,
    output reg                  COUT,
    output reg                  G,
    output reg                  L,
    output reg                  E,
    output reg                  ERR
);

    reg [(2*WIDTH)-1:0] next_res;
    reg                 next_oflow;
    reg                 next_cout;
    reg                 next_g;
    reg                 next_l;
    reg                 next_e;
    reg                 next_err;
    
    reg [(2*WIDTH)-1:0] mult_res_d;
    reg                 mult_valid_d;
    
    function [WIDTH-1:0] rol;
        input [WIDTH-1:0] data;
        input [$clog2(WIDTH)-1:0] shift;

        begin
            rol = (data << shift) | (data >> (WIDTH-shift));
        end
    endfunction
    
    function [WIDTH-1:0] ror;
        input [WIDTH-1:0] data;
        input [$clog2(WIDTH)-1:0] shift;

        begin
            ror = (data >> shift) | (data << (WIDTH-shift));
        end
    endfunction
    
    always @(*)
    begin

        next_res    = 0;
        next_oflow  = 0;
        next_cout   = 0;
        next_g      = 0;
        next_l      = 0;
        next_e      = 0;
        next_err    = 1'b0;
        
        case(INP_VALID)
            2'b00:
            begin
                if(!MODE)
                begin
                case(CMD)
                4'd12:
                begin
                     next_res[WIDTH-1:0] =
                                rol(OPA, OPB[$clog2(WIDTH)-1:0]);
                     next_err = 1'b1;
                end
                4'd13:
                begin
                     next_res[WIDTH-1:0] =
                                ror(OPA, OPB[$clog2(WIDTH)-1:0]);
                     next_err = 1'b1;
                end
                default:
                begin
                     next_res = 0;
                     next_err = 1'b1;
                end
                endcase
                end
                else
                begin
                next_res = 0;
                next_err = 1'b1;
                end
            end
            
            2'b01:
            begin
                if(MODE) begin
                case(CMD)
                        4'd4:
                        begin
                            next_res = OPA + 1'b1;
                            if(next_res > 2**WIDTH - 1)
                               next_res = 0;
                            else
                               next_res = next_res;
                        end
                        
                        4'd5:
                        begin
                            next_res = OPA - 1'b1;
                            if(OPA==0)
                               next_res = (2**WIDTH) - 1;
                            else
                               next_res = next_res;
                        end
                        default:
                        begin
                            next_res = 0;
                            next_err = 1'b1;
                        end
                endcase
                end
                else
                begin
                case(CMD)
                        4'd6:
                        begin
                            next_res[WIDTH-1:0] = ~OPA;
                        end
                        4'd8:
                        begin
                            next_res[WIDTH-1:0] = OPA >> 1;
                        end
                        4'd9:
                        begin
                            next_res[WIDTH-1:0] = OPA << 1;
                        end
                        4'd12:
                        begin
                        next_res[WIDTH-1:0] =
                                rol(OPA, OPB[$clog2(WIDTH)-1:0]);
                        next_err = 1'b1;
                        end
                        4'd13:
                        begin
                         next_res[WIDTH-1:0] =
                                ror(OPA, OPB[$clog2(WIDTH)-1:0]);
                         next_err = 1'b1;
                        end
                        default:
                        begin
                            next_res = 0;
                            next_err = 1'b1;
                        end
                endcase
                end
            end
            
            2'b10:
            begin
                if(MODE)
                begin
                case(CMD)
                        4'd6:
                        begin
                            next_res = OPB + 1'b1;
                            if(next_res > 2**WIDTH - 1)
                               next_res = 0;
                            else
                               next_res = next_res;
                        end
                        
                        4'd7:
                        begin
                            next_res = OPB - 1'b1;
                            if(OPB==0)
                               next_res = (2**WIDTH) - 1;
                            else
                               next_res = next_res;
                        end
                        default:
                        begin
                            next_res = 0;
                            next_err = 1'b1;
                        end
                 endcase
                 end
                 else
                begin
                case(CMD)
                        4'd7:
                        begin
                            next_res[WIDTH-1:0] = ~OPB;
                        end
                        4'd10:
                        begin
                            next_res[WIDTH-1:0] = OPB >> 1;
                        end
                        4'd11:
                        begin
                            next_res[WIDTH-1:0] = OPB << 1;
                        end
                        4'd12:
                        begin
                        next_res[WIDTH-1:0] =
                                rol(OPA, OPB[$clog2(WIDTH)-1:0]);
                        next_err = 1'b1;
                        end
                        4'd13:
                        begin
                         next_res[WIDTH-1:0] =
                                ror(OPA, OPB[$clog2(WIDTH)-1:0]);
                         next_err = 1'b1;
                        end
                        default:
                        begin
                            next_res = 0;
                            next_err = 1'b1;
                        end
                endcase
                end
            end

            2'b11:
            begin
                if(MODE)
                begin

                    case(CMD)
                    
                        4'd0:
                        begin
                            next_res = OPA + OPB;
                            if(OPA + OPB > 2**WIDTH - 1)
                                next_cout = 1;
                            else
                                next_cout = 0;

                            next_oflow =
                                (~OPA[WIDTH-1] &
                                 ~OPB[WIDTH-1] &
                                  next_res[WIDTH-1]) |

                                (OPA[WIDTH-1] &
                                 OPB[WIDTH-1] &
                                ~next_res[WIDTH-1]);
                        end
                        4'd1:
                        begin
                            next_res = OPA - OPB;
                            next_oflow =(OPB > OPA)?1:0;
                        end
                        
                        4'd2:
                        begin
                            next_res = OPA + OPB + CIN;
                            if(OPA + OPB + CIN > 2**WIDTH - 1)
                                next_cout = 1;
                            else
                                next_cout = 0;
                        end
                        
                        4'd3:
                        begin
                            next_res = OPA - OPB - CIN;
                            next_oflow =(OPB > OPA)?1:0;
                        end
                        
                        4'd4:
                        begin
                            next_res = OPA + 1'b1;
                            if(next_res > 2**WIDTH - 1)
                               next_res = 0;
                            else
                               next_res = next_res;
                        end
                        
                        4'd5:
                        begin
                            next_res = OPA - 1'b1;
                            if(OPA==0)
                               next_res = (2**WIDTH) - 1;
                            else
                               next_res = next_res;
                        end
                        
                        4'd6:
                        begin
                            next_res = OPB + 1'b1;
                            if(next_res > 2**WIDTH - 1)
                               next_res = 0;
                            else
                               next_res = next_res;
                        end
                        
                        4'd7:
                        begin
                            next_res = OPB - 1'b1;
                            if(OPB==0)
                               next_res = (2**WIDTH) - 1;
                            else
                               next_res = next_res;
                        end
                        
                        4'd8:
                        begin
                            if(OPA > OPB)
                                next_g = 1'b1;

                            else if(OPA < OPB)
                                next_l = 1'b1;

                            else
                                next_e = 1'b1;
                        end

                        4'd9:
                        begin
                            next_res = (OPA + 1'b1) * (OPB + 1'b1);
                        end
                        
                        4'd10:
                        begin
                            next_res = (OPA << 1'b1) * OPB;
                        end
                        
                        4'd11:
                        begin
                            next_res = $signed(OPA) + $signed(OPB);

                            next_oflow = (OPA[WIDTH-1] == OPB[WIDTH-1]) && (next_res[WIDTH-1] != OPA[WIDTH-1]);

                            if(next_res == 0)
                                next_e = 1'b1;

                            else if($signed(OPA) > $signed(OPB))
                                next_g = 1'b1;

                            else
                                next_l = 1'b1;
                        end
                        
                        4'd12:
                        begin
                            next_res
                                = $signed(OPA) - $signed(OPB);

                            next_oflow =
                                (OPA[WIDTH-1] !=OPB[WIDTH-1]) && (next_res[WIDTH-1] != OPA[WIDTH-1]);

                            if(next_res == 0)
                                next_e = 1'b1;

                            else if($signed(OPA) > $signed(OPB))
                                next_g = 1'b1;

                            else
                                next_l = 1'b1;
                        end
                        default:
                        begin
                            next_res = 0;
                            next_err = 1'b1;
                        end

                    endcase
                end
                
                else
                begin

                    case(CMD)

                        4'd0:
                        begin
                            next_res[WIDTH-1:0] = OPA & OPB;
                        end

                        4'd1:
                        begin
                            next_res[WIDTH-1:0] = ~(OPA & OPB);
                        end

                        4'd2:
                        begin
                            next_res[WIDTH-1:0] = OPA | OPB;
                        end

                        4'd3:
                        begin
                            next_res[WIDTH-1:0] = ~(OPA | OPB);
                        end

                        4'd4:
                        begin
                            next_res[WIDTH-1:0] = OPA ^ OPB;
                        end

                        4'd5:
                        begin
                            next_res[WIDTH-1:0] = ~(OPA ^ OPB);
                        end

                        4'd6:
                        begin
                            next_res[WIDTH-1:0] = ~OPA;
                        end

                        4'd7:
                        begin
                            next_res[WIDTH-1:0] = ~OPB;
                        end

                        4'd8:
                        begin
                            next_res[WIDTH-1:0] = OPA >> 1;
                        end

                        4'd9:
                        begin
                            next_res[WIDTH-1:0] = OPA << 1;
                        end

                        4'd10:
                        begin
                            next_res[WIDTH-1:0] = OPB >> 1;
                        end

                        4'd11:
                        begin
                            next_res[WIDTH-1:0] = OPB << 1;
                        end
                        
                        4'd12:
                        begin
                            next_res[WIDTH-1:0] =
                                rol(OPA, OPB[$clog2(WIDTH)-1:0]);

                            if(|OPB[WIDTH-1:$clog2(WIDTH)+1])
                                next_err = 1'b1;
                            else
                                next_err = 1'b0;
                        end

                        4'd13:
                        begin
                            next_res[WIDTH-1:0] =
                                ror(OPA, OPB[$clog2(WIDTH)-1:0]);

                            if(|OPB[WIDTH-1:$clog2(WIDTH)+1])
                                next_err = 1'b1;
                            else
                                next_err = 1'b0;
                        end

                        default:
                        begin
                            next_res = 0;
                            next_err = 1;
                        end

                    endcase
                end
            end
            
            default:
            begin
                next_res = 0;
            end

        endcase
    end
    always @(posedge CLK or posedge RST)
    begin

        if(RST)
        begin
            RES          <= 0;
            OFLOW        <= 0;
            COUT         <= 0;
            G            <= 0;
            L            <= 0;
            E            <= 0;
            ERR          <= 0;

            mult_res_d   <= 0;
            mult_valid_d <= 0;
        end

        else if(CE)
        begin
            if(mult_valid_d)
            begin
                RES <= mult_res_d;
                mult_valid_d <= 1'b0;
            end
            
            else if(MODE &&
                   (CMD == 4'd9 ||
                    CMD == 4'd10) &&
                    INP_VALID == 2'b11)
            begin
                mult_res_d <= next_res;
                mult_valid_d <= 1'b1;
                RES <= {(2*WIDTH){1'bx}};
            end
            
            else
            begin
                RES <= next_res;
            end
            
            OFLOW <= next_oflow;
            COUT  <= next_cout;
            G     <= next_g;
            L     <= next_l;
            E     <= next_e;
            ERR   <= next_err;

        end

    end

endmodule