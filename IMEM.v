module IMEM(
    input rst,
    input  [31:0] A,
    output [31:0] RD
);
    reg [31:0] RAM[0:63];
    initial
       $readmemh("D:riscvtest.txt",RAM);
// 00500093  // 0x0000: addi x1, x0, 5
// 00a00113  // 0x0004: addi x2, x0, 10
// 002081b3  // 0x0008: add  x3, x1, x2
// 00302023  // 0x000C: sw   x3, 0(x0)
// 00002203  // 0x0010: lw   x4, 0(x0)
// 00418463  // 0x0014: beq  x3, x4, +8   -> 0x001C
// 0020c463  // 0x0018: blt  x1, x2, +8   -> 0x0020
// 00100293  // 0x001C: addi x5, x0, 1
// 00c000ef  // 0x0020: jal  x1, +12      -> 0x002C (x1 = 0x0024)
// 00000313  // 0x0024: addi x6, x0, 0    ; NOP / return target
// 00200293  // 0x0028: addi x5, x0, 2    ; label_blt
// 00008067  // 0x002C: jalr x0, 0(x1)    ; return to 0x0024
    assign RD = (rst == 1'b0) ? 32'b0 : RAM[A[31:2]]; // word aligned
endmodule