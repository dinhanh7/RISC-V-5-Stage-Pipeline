module fetch_cycle(    // Khai báo input & output
    input clk, rst;                // clk: xung clock, rst: tín hiệu reset
    input PCSrcE;                  // Chọn nguồn cập nhật PC (nhảy hay tuần tự)
    input [31:0] PCTargetE;        // Địa chỉ nhảy nếu có branch
    output [31:0] InstrD;          // Lệnh xuất ra cho stage Decode
    output [31:0] PCD, PCPlus4D;   // PC và PC+4 xuất ra cho stage Decode
    );



    // Khai báo wire tạm thời
    wire [31:0] PC_F, PCPlus4F;
    wire [31:0] InstrF;

    // Đăng ký lưu giá trị tạm thời giữa các stage
    reg [31:0] InstrF_reg;
    reg [31:0] PCF_reg, PCPlus4F_reg;
    reg [31:0] PCF; // Sửa wire thành reg


    // Bộ chọn PC (PC Mux): chọn giữa PC+4 (bình thường) hoặc PCTargetE (branch)
    assign PC_F = PCSrcE ? PCTargetE : PCPlus4F;
    // Mux PC_MUX (.a(PCPlus4F),
    //             .b(PCTargetE),
    //             .s(PCSrcE),
    //             .c(PC_F)
    //             );

    // Thanh ghi PC: cập nhật giá trị PC ở mỗi cạnh lên của clock
    always @(posedge clk)
    begin
        if(rst == 1'b0)
            PCF <= 32'b0; // Reset PC về 0
        else
            PCF <= PC_F;       // Cập nhật PC mới
    end
    // PC_Module Program_Counter (
    //             .clk(clk),
    //             .rst(rst),
    //             .PC(PCF),
    //             .PC_Next(PC_F)
    //             );

    // Bộ nhớ lệnh: đọc lệnh tại địa chỉ PCF
    IMEM imem (
        .rst(rst),
        .A(PCF),
        .RD(InstrF)
    );

    // Bộ cộng PC: tính PC+4 (địa chỉ lệnh tiếp theo)
    assign PCPlus4F = PCF + 32'h00000004;
    // PC_Adder PC_adder (
    //             .a(PCF),
    //             .b(32'h00000004),
    //             .c(PCPlus4F)
    //             );

    // Đăng ký pipeline giữa Fetch và Decode
    always @(posedge clk or negedge rst) begin
        if(rst == 1'b0) begin
            InstrF_reg <= 32'h00000000;
            PCF_reg <= 32'h00000000;
            PCPlus4F_reg <= 32'h00000000;
        end
        else begin
            InstrF_reg <= InstrF;
            PCF_reg <= PCF;
            PCPlus4F_reg <= PCPlus4F;
        end
    end


    // Gán giá trị từ các thanh ghi pipeline ra cổng output
    assign  InstrD = (rst == 1'b0) ? 32'h00000000 : InstrF_reg;
    assign  PCD = (rst == 1'b0) ? 32'h00000000 : PCF_reg;
    assign  PCPlus4D = (rst == 1'b0) ? 32'h00000000 : PCPlus4F_reg;


endmodule