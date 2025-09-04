module datapath (

);
    wire [31:0] ins;
    wire [1:0] ImmSrc;
    wire [31:0] Imm_Ext;


    always @(ImmSrc or ins) begin
        case (ImmSrc)
            2'b00: Imm_Ext = {{20{ins[31]}}, ins[31:20]}; // I-type
            2'b01: Imm_Ext = {{20{ins[31]}}, ins[31:25], ins[11:7]}; // S-type
            2'b10: Imm_Ext = {{20{ins[31]}}, ins[7], ins[30:25], ins[11:8], 1'b0}; // B-type
            2'b11: Imm_Ext = {{12{ins[31]}}, ins[19:12], ins[20], ins[30:21], 1'b0}; // J-type 
            //chua co jalr
            default: Imm_Ext = 32'b0;
        endcase
    end

endmodule
