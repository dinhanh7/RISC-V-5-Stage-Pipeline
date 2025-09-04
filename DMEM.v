
module DMEM(    
    input clk,rst,WE,
    input [31:0]A,WD,
    output [31:0]RD
    );



    reg [31:0] mem [0:63];

    always @ (posedge clk)
    begin
        if(WE)
            mem[A[31:2]] <= WD;
    end

    assign RD = (~rst) ? 32'd0 : mem[A[31:2]];

    initial begin
        mem[0] = 32'h00000000;
        //mem[40] = 32'h00000002;
    end


endmodule

