
/* ----------------------------------------------------------------------------
 * Copyright (c) 2026 Sohaib Ali Jaffery
 * 
 * Author:  Sohaib Ali Jaffery <sohaibjaffery@outlook.com>
 * GitHub:  github.com/SohaibAliJaffery
 * 
 * This file is part of a single-cycle RV32I processor implementation.
 * ------------------------------------------------------------------------- */

module immediate_generator (
    input   logic [31:0] instruction,
    output  logic [31:0] imm_i,
    output  logic [31:0] imm_s,
    output  logic [31:0] imm_b,
    output  logic [31:0] imm_u,
    output  logic [31:0] imm_j
);

    // I-type immediate
    assign imm_i = {{20{instruction[31]}}, instruction[31:20]};
    
    // S-type immediate
    assign imm_s = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
    
    // B-type immediate
    assign imm_b = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
    
    // U-type immediate
    assign imm_u = {instruction[31:12], 12'b0};
    
    // J-type immediate
    assign imm_j = {{11{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};

endmodule