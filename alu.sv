
/* ----------------------------------------------------------------------------
 * Copyright (c) 2026 Sohaib Ali Jaffery
 * 
 * Author:  Sohaib Ali Jaffery <sohaibjaffery@outlook.com>
 * GitHub:  github.com/SohaibAliJaffery
 * 
 * This file is part of a single-cycle RV32I processor implementation.
 * ------------------------------------------------------------------------- */

module alu(
    input  logic [31:0] SrcA, SrcB, 
    input  logic [3:0]  ALUControl, 
    output logic [31:0] ALUResult 
);

  always_comb case(ALUControl)

    4'b0000: ALUResult = SrcA + SrcB;
    4'b0001: ALUResult = SrcA - SrcB;
    4'b0010: ALUResult = SrcA & SrcB;
    4'b0011: ALUResult = SrcA | SrcB;
    4'b0100: ALUResult = SrcA ^ SrcB;                       // XOR
    4'b0101: ALUResult = (SrcA < SrcB) ? 1 : 0;
    4'b0110: ALUResult = SrcA << SrcB[4:0];                 // Shift left logical
    4'b0111: ALUResult = SrcA >> SrcB[4:0];                 // Shift right logical
    4'b1000: ALUResult = $signed(SrcA) >>> SrcB[4:0];       // Shift right arithmetic

    // Set less than unsigned
    4'b1001: begin
        if (SrcA < SrcB) begin
            ALUResult = 1;
        end else begin
            ALUResult = 0;
        end
        end

    // Set less than signed
    4'b1010: begin
        if ($signed(SrcA) < $signed(SrcB)) begin
            ALUResult = 1;
        end else begin
            ALUResult = 0;
        end
        end




    default: ALUResult = 32'bx;

  endcase
  
 

endmodule