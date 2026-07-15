
/* ----------------------------------------------------------------------------
 * Copyright (c) 2026 Sohaib Ali Jaffery
 * 
 * Author:  Sohaib Ali Jaffery <sohaibjaffery@outlook.com>
 * GitHub:  github.com/SohaibAliJaffery
 * 
 * This file is part of a single-cycle RV32I processor implementation.
 * ------------------------------------------------------------------------- */


module data_memory (
    input   logic           clk,
    input   logic [31:0]    addr,

    input   logic [31:0]    data_in,
    input   logic [3:0]     wr_en,      // Write enable for each byte (4 bits for 4 bytes)

    output  logic [31:0]    data_out 
);


    RamSp #(
        .RAM_WIDTH(32),
        .RAM_ADDR_BITS(9),
        .DATA_FILE("data_memory.mem"),
        .INIT_START_ADDR(0),
        .INIT_END_ADDR(10)
    ) ram_inst (
        .Clk(clk),
        .WrEn(wr_en),
        .Addr(addr[10:2]),
        .WrData(data_in),
        .RdData(data_out)
    );
    
endmodule

