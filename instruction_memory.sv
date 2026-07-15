/* ----------------------------------------------------------------------------
 * Copyright (c) 2026 Sohaib Ali Jaffery
 * 
 * Author:  Sohaib Ali Jaffery <sohaibjaffery@outlook.com>
 * GitHub:  github.com/SohaibAliJaffery
 * 
 * This file is part of a single-cycle RV32I processor implementation.
 * ------------------------------------------------------------------------- */


module instruction_memory (
    input   logic           clk,
    input   logic [31:0]    addr,

    output  logic [31:0]    data_out 
);


    RamSp #(
        .RAM_WIDTH(32),
        .RAM_ADDR_BITS(9),
        .DATA_FILE("instruction_memory.mem"),
        .INIT_START_ADDR(0),
        .INIT_END_ADDR(10)
    ) ram_inst (
        .Clk(clk),
        .WrEn(4'b0000),         // No write enable for instruction memory
        .Addr(addr[10:2]),      // Assuming word-aligned addresses
        .WrData(32'b0),         // No write data for instruction memory
        .RdData(data_out)
    );
    
endmodule
