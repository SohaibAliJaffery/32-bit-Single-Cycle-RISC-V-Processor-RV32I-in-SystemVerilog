
/* ----------------------------------------------------------------------------
 * Copyright (c) 2026 Sohaib Ali Jaffery
 * 
 * Author:  Sohaib Ali Jaffery <sohaibjaffery@outlook.com>
 * GitHub:  github.com/SohaibAliJaffery
 * 
 * This file is part of a single-cycle RV32I processor implementation.
 * ------------------------------------------------------------------------- */

module reg_file (
    input   logic           clk,
    input   logic [4:0]     addr1,
    input   logic [4:0]     addr2,
    input   logic [31:0]    data_in,
    input   logic           wr_en,
    input   logic [4:0]     wr_addr,

    output  logic [31:0]    data1,
    output  logic [31:0]    data2
);

    logic [31:0] reg_array [31:0] = '{default: 32'h0};

    always_ff @(posedge clk) begin
        if (wr_en && wr_addr != 0) begin
            reg_array[wr_addr] <= data_in;
        end
    end

    // Read ports
    assign data1 = (addr1 == 5'b0) ? 32'b0 : reg_array[addr1];
    assign data2 = (addr2 == 5'b0) ? 32'b0 : reg_array[addr2];
  
    
endmodule

