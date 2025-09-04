module controlUnit(
    input [6:0]Op,funct7,
    input [2:0]funct3,

    output RegWrite,ALUSrc,MemWrite,Branch,
    output [1:0]ImmSrc,
    output [2:0]ALUControl,
    output [1:0]ResultSrc // Changed from 1 bit to 2 bits
);
    localparam [6:0] OPCODE_LOAD   = 7'b0000011;
    localparam [6:0] OPCODE_STORE  = 7'b0100011;
    localparam [6:0] OPCODE_RTYPE  = 7'b0110011;
    localparam [6:0] OPCODE_ITYPE  = 7'b0010011;
    localparam [6:0] OPCODE_BRANCH = 7'b1100011;
    localparam [6:0] OPCODE_JAL    = 7'b1101111;
    localparam [6:0] OPCODE_JALR   = 7'b1100111;

    wire [1:0]ALUOp;

    // RegWrite: Cho phép ghi vào thanh ghi đích (rd) nếu là lệnh load, R-type, hoặc I-type
    assign RegWrite = (Op == OPCODE_LOAD | Op == OPCODE_RTYPE | Op == OPCODE_ITYPE | Op == OPCODE_JAL | Op == OPCODE_JALR) ? 1'b1 :
                                                              1'b0 ;
    // ImmSrc: Chọn kiểu sinh immediate (00: I-type, 01: S-type, 10: B-type)
    assign ImmSrc = (Op == OPCODE_STORE) ? 2'b01 : 
                    (Op == OPCODE_BRANCH) ? 2'b10 :    
                    (Op == OPCODE_JAL) ? 2'b11 :
                                         2'b00 ;
    // ALUSrc: Chọn nguồn thứ 2 cho ALU (1: immediate, 0: thanh ghi)
    assign ALUSrc = (Op == OPCODE_LOAD | Op == OPCODE_STORE | Op == OPCODE_ITYPE | Op == OPCODE_JALR) ? 1'b1 :
                                                            1'b0 ;
    // MemWrite: Cho phép ghi dữ liệu vào bộ nhớ (chỉ lệnh store)
    assign MemWrite = (Op == OPCODE_STORE) ? 1'b1 :
                                           1'b0 ;
    // Branch: Cho phép nhảy có điều kiện (chỉ lệnh branch)
    assign Branch = (Op == OPCODE_BRANCH) ? 1'b1 :
                                         1'b0 ;
    // ALUOp: Chọn chế độ hoạt động của ALU (10: R-type, 01: branch, 00: mặc định)
    assign ALUOp = (Op == OPCODE_RTYPE) ? 2'b10 :
                   (Op == OPCODE_BRANCH) ? 2'b01 :
                                        2'b00 ;
    // ALUControl: Xác định phép toán cụ thể cho ALU dựa trên ALUOp, funct3, funct7
    assign ALUControl = 
        (ALUOp == 2'b00) ? 3'b000 : // 00: Mặc định (cộng), dùng cho load/store/I-type
        (ALUOp == 2'b01) ? 3'b001 : // 01: Lệnh branch (so sánh, thực hiện phép trừ)
        // Các trường hợp R-type (ALUOp == 2'b10):
        // Nếu funct3 == 000 và {op[5],funct7[5]} == 2'b11: SUB (trừ)
        ((ALUOp == 2'b10) & (funct3 == 3'b000) & ({Op[5],funct7[5]} == 2'b11)) ? 3'b001 : 
        // Nếu funct3 == 000 và {op[5],funct7[5]} != 2'b11: ADD (cộng)
        ((ALUOp == 2'b10) & (funct3 == 3'b000) & ({Op[5],funct7[5]} != 2'b11)) ? 3'b000 : 
        // Nếu funct3 == 010: SLT (so sánh nhỏ hơn)
        ((ALUOp == 2'b10) & (funct3 == 3'b010)) ? 3'b101 : 
        // Nếu funct3 == 110: OR
        ((ALUOp == 2'b10) & (funct3 == 3'b110)) ? 3'b011 : 
        // Nếu funct3 == 111: AND
        ((ALUOp == 2'b10) & (funct3 == 3'b111)) ? 3'b010 : 
        // Mặc định: cộng
        3'b000 ;

    // ResultSrc: 2-bit
    // 00: ALU result, 01: Data memory, 10: PC+4, 11: (unused)
    assign ResultSrc = (Op == OPCODE_LOAD) ? 2'b01 :
                       (Op == OPCODE_JAL || Op == OPCODE_JALR) ? 2'b10 :
                       2'b00;

endmodule
