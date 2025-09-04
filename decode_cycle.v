module decode_cycle(    // Khai báo input/output
    input clk, rst, RegWriteW,           // clk: clock, rst: reset, RegWriteW: tín hiệu ghi thanh ghi ở stage W
    input [4:0] RDW,                     // Địa chỉ thanh ghi đích ở stage W
    input [31:0] InstrD, PCD, PCPlus4D, ResultW, // Lệnh, PC, PC+4, dữ liệu ghi về từ stage W

    output RegWriteE,ALUSrcE,MemWriteE,ResultSrcE,BranchE, // Các tín hiệu điều khiển cho stage E
    output [2:0] ALUControlE,            // Tín hiệu điều khiển ALU cho stage E
    output [31:0] RD1_E, RD2_E, Imm_Ext_E, // Dữ liệu đọc từ thanh ghi, immediate mở rộng
    output [4:0] RS1_E, RS2_E, RD_E,     // Địa chỉ các thanh ghi nguồn và đích
    output [31:0] PCE, PCPlus4E,         // PC và PC+4 chuyển sang stage E
);


    // Khai báo wire tạm thời cho stage D
    wire RegWriteD,ALUSrcD,MemWriteD,ResultSrcD,BranchD;
    wire [1:0] ImmSrcD;
    wire [2:0] ALUControlD;
    wire [31:0] RD1_D, RD2_D, Imm_Ext_D;

    // Đăng ký pipeline giữa D và E
    reg RegWriteD_r,ALUSrcD_r,MemWriteD_r,ResultSrcD_r,BranchD_r;
    reg [2:0] ALUControlD_r;
    reg [31:0] RD1_D_r, RD2_D_r, Imm_Ext_D_r;
    reg [4:0] RD_D_r, RS1_D_r, RS2_D_r;
    reg [31:0] PCD_r, PCPlus4D_r;


    // Khối điều khiển: giải mã lệnh để sinh tín hiệu điều khiển
    controlUnit control (
                            .Op(InstrD[6:0]),
                            .RegWrite(RegWriteD),
                            .ImmSrc(ImmSrcD),
                            .ALUSrc(ALUSrcD),
                            .MemWrite(MemWriteD),
                            .ResultSrc(ResultSrcD),
                            .Branch(BranchD),
                            .funct3(InstrD[14:12]),
                            .funct7(InstrD[31:25]),
                            .ALUControl(ALUControlD)
                            );

    // File thanh ghi: đọc 2 thanh ghi nguồn, ghi thanh ghi đích nếu cần
    reg [31:0] Register [31:0];

    always @ (posedge clk)
    begin
        Register[0] = 32'h00000000;
        if(RegWriteW & (RDW != 5'h00))
            Register[RDW] <= ResultW;
    end
    assign RD1_D = (rst==1'b0) ? 32'd0 : Register[InstrD[19:15]];
    assign RD2_D = (rst==1'b0) ? 32'd0 : Register[InstrD[24:20]];

    // Register_File rf (
    //                     .clk(clk),
    //                     .rst(rst),
    //                     .WE3(RegWriteW),      // Tín hiệu ghi thanh ghi (từ stage W)
    //                     .WD3(ResultW),        // Dữ liệu ghi về (từ stage W)
    //                     .A1(InstrD[19:15]),   // Địa chỉ thanh ghi nguồn 1
    //                     .A2(InstrD[24:20]),   // Địa chỉ thanh ghi nguồn 2
    //                     .A3(RDW),             // Địa chỉ thanh ghi đích (từ stage W)
    //                     .RD1(RD1_D),          // Dữ liệu đọc ra 1
    //                     .RD2(RD2_D)           // Dữ liệu đọc ra 2
    //                     );

    // Khối mở rộng immediate (sign-extend)
    always @(ImmSrcD or InstrD) begin
        case (ImmSrcD)
            2'b00: Imm_Ext_D = {{20{InstrD[31]}}, InstrD[31:20]}; // I-type
            2'b01: Imm_Ext_D = {{20{InstrD[31]}}, InstrD[31:25], InstrD[11:7]}; // S-type
            2'b10: Imm_Ext_D = {{20{InstrD[31]}}, InstrD[7], InstrD[30:25], InstrD[11:8], 1'b0}; // B-type
            2'b11: Imm_Ext_D = {{12{InstrD[31]}}, InstrD[19:12], InstrD[20], InstrD[30:21], 1'b0}; // J-type 
            //chua co jalr
            default: Imm_Ext_D = 32'b0;
        endcase
    end
    // Sign_Extend extension (
    //                     .In(InstrD[31:0]),
    //                     .Imm_Ext(Imm_Ext_D),
    //                     .ImmSrc(ImmSrcD)
    //                     );


    // Đăng ký pipeline giữa Decode và Execute
    always @(posedge clk or negedge rst) begin
        if(rst == 1'b0) begin
            // Reset tất cả các thanh ghi pipeline
            RegWriteD_r <= 1'b0;
            ALUSrcD_r <= 1'b0;
            MemWriteD_r <= 1'b0;
            ResultSrcD_r <= 1'b0;
            BranchD_r <= 1'b0;
            ALUControlD_r <= 3'b000;
            RD1_D_r <= 32'h00000000; 
            RD2_D_r <= 32'h00000000; 
            Imm_Ext_D_r <= 32'h00000000;
            RD_D_r <= 5'h00;
            PCD_r <= 32'h00000000; 
            PCPlus4D_r <= 32'h00000000;
            RS1_D_r <= 5'h00;
            RS2_D_r <= 5'h00;
        end
        else begin
            // Lưu giá trị từ stage D sang E
            RegWriteD_r <= RegWriteD;
            ALUSrcD_r <= ALUSrcD;
            MemWriteD_r <= MemWriteD;
            ResultSrcD_r <= ResultSrcD;
            BranchD_r <= BranchD;
            ALUControlD_r <= ALUControlD;
            RD1_D_r <= RD1_D; 
            RD2_D_r <= RD2_D; 
            Imm_Ext_D_r <= Imm_Ext_D;
            RD_D_r <= InstrD[11:7];         // Địa chỉ thanh ghi đích
            PCD_r <= PCD; 
            PCPlus4D_r <= PCPlus4D;
            RS1_D_r <= InstrD[19:15];       // Địa chỉ thanh ghi nguồn 1
            RS2_D_r <= InstrD[24:20];       // Địa chỉ thanh ghi nguồn 2
        end
    end

    // Gán giá trị từ các thanh ghi pipeline ra cổng output cho stage E
    assign RegWriteE = RegWriteD_r;
    assign ALUSrcE = ALUSrcD_r;
    assign MemWriteE = MemWriteD_r;
    assign ResultSrcE = ResultSrcD_r;
    assign BranchE = BranchD_r;
    assign ALUControlE = ALUControlD_r;
    assign RD1_E = RD1_D_r;
    assign RD2_E = RD2_D_r;
    assign Imm_Ext_E = Imm_Ext_D_r;
    assign RD_E = RD_D_r;
    assign PCE = PCD_r;
    assign PCPlus4E = PCPlus4D_r;
    assign RS1_E = RS1_D_r;
    assign RS2_E = RS2_D_r;

endmodule
