/* ----------------------------------------------------------------------------
 * Copyright (c) 2026 Sohaib Ali Jaffery
 * 
 * Author:  Sohaib Ali Jaffery <sohaibjaffery@outlook.com>
 * GitHub:  github.com/SohaibAliJaffery
 * 
 * This file is part of a single-cycle RV32I processor implementation.
 * ------------------------------------------------------------------------- */

`timescale 1ns/1ps

`include "rv32i_defs.svh"



module rv32i_singlecycle (
    input  logic           clk,
    input  logic           rst_n
);


    

    //---------------------------------
    // PC register
    //---------------------------------
    logic [31:0] pc_reg;
    logic [31:0] pc_next;               // Next PC value
    logic [31:0] pc_plus4;              // PC + 4 value
    logic [31:0] pc_branch;             // Branch target address
    logic [31:0] pc_jal;                // JAL target address

    // Shared control and datapath signals
    logic [31:0] imm_i;
    logic [31:0] imm_s;
    logic [31:0] imm_b;
    logic [31:0] imm_u;
    logic [31:0] imm_j;
    logic [31:0] alu_result;            // Result from ALU
    logic [1:0]  RegWBSel;              // Mux select for write-back data
    logic [3:0]  AluSel;                // Control signal for ALU
    logic        Branch;                // Identifies a branch instruction
    logic [31:0] data_mem_out_ext;      // Extended data from memory


    logic        BranchPCSel;           // Control signal for branch selection
    logic        JalrPCSel;             // Control signal for JALR selection
    logic        JalPCSel;              // Control signal for JAL selection


    assign pc_branch = pc_reg + imm_b;  // Branch target address calculation
    assign pc_jal = pc_reg + imm_j;     // JAL target address calculation

    // PC update logic
    always_comb begin
        if (JalrPCSel) begin
            pc_next = {alu_result[31:1], 1'b0};       // For JALR, use ALU result as next PC
        end else if (BranchPCSel) begin
            pc_next = pc_branch;                        // For branch, use branch target address
        end else if (JalPCSel) begin
            pc_next = pc_jal;                           // For JAL, use JAL target address
        end else begin
            pc_next = pc_plus4;                         // Default case: PC + 4
        end
    end
    

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) pc_reg <= 32'b0;
        
        else       pc_reg <= pc_next;
    end

    assign pc_plus4 = pc_reg + 4;



    //---------------------------------
    // Instructions
    //-------------------------------
    
    logic [31:0] instruction;   // Current instruction

    // Split it into parts so that it is easier to decode

    logic [6:0] opcode;
    assign opcode = instruction[6:0];
    logic [2:0] funct3;
    assign funct3 = instruction[14:12];
    logic [6:0] funct7;
    assign funct7 = instruction[31:25];

    immediate_generator imm_gen (
        .instruction(instruction),
        .imm_i(imm_i),
        .imm_s(imm_s),
        .imm_b(imm_b),
        .imm_u(imm_u),
        .imm_j(imm_j)
    );

    instruction_memory inst_mem (
        .clk(clk),
        .addr(pc_reg),
        .data_out(instruction)
    );

    //--------------------------------
    // Immediate Multiplexer
    //--------------------------------
    logic [2:0]  ImmSel;
    logic [31:0] imm_mux_out;

    always_comb begin
        case (ImmSel)
            3'b000: imm_mux_out = imm_i;
            3'b001: imm_mux_out = imm_s;
            3'b010: imm_mux_out = imm_b;
            3'b011: imm_mux_out = imm_u;
            3'b100: imm_mux_out = imm_j;
            default: imm_mux_out = 32'b0;
        endcase
    end


    //--------------------------------
    // Register File
    //-------------------------------- 

    logic [31:0]    data1, data2;   // Data read from registers
    logic           wr_en;          // Write enable for register file 
    logic [31:0]    data_in;        // Data to write to register file

    reg_file regfile (
        .clk(clk),
        .addr1(instruction[19:15]),         // rs1
        .addr2(instruction[24:20]),         // rs2
        .data_in(data_in),                    // Data to write 
        .wr_en(wr_en),                      // Write enable 
        .wr_addr(instruction[11:7]),        // Write address 
        .data1(data1),                      // Data from rs1
        .data2(data2)                       // Data from rs2
    );

    // Reg writeback select mux

    always_comb begin : REG_WB_MUX
        case (RegWBSel)
            2'b00: data_in = alu_result;            // ALU result
            2'b01: data_in = data_mem_out_ext;      // Data from memory
            2'b10: data_in = pc_plus4;              // PC + 4 (for JAL and JALR)
            2'b11: data_in = imm_u;                 // U-type immediate (for LUI)
            default: data_in = 32'b0;
        endcase
    end


    //--------------------------------
    // ALU
    //--------------------------------

    //SrcA Mux:
    logic [31:0]    srcA;   // ALU inputs
    logic           AuipcSel;

    assign srcA = (AuipcSel) ? pc_reg : data1; // PC or register value



    // SrcB Mux:
    logic [31:0]    srcB;   // ALU inputs
    logic           SrcSel;

    assign srcB = (SrcSel) ? imm_mux_out : data2; // Immediate or register value
    


    alu alu_unit (
        .SrcA(srcA), 
        .SrcB(srcB), 
        .ALUControl(AluSel), 
        .ALUResult(alu_result)
    );


    //--------------------------------
    // Control Unit
    //--------------------------------

    logic           MemWrite;       // Control signal for memory write

    controller ctrl_unit (
        .instruction(instruction),
        .RegWrite(wr_en),
        .RegWBSelect(RegWBSel),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .Branch(Branch),             
        .ALUControl(AluSel),
        .JalrPCSel(JalrPCSel),
        .JalPCSel(JalPCSel),         
        .BranchPCSel(),              
        .SrcSel(SrcSel),
        .ImmSel(ImmSel),
        .AuipcSel(AuipcSel)
    );


    //---------------------------------
    // Branch Evaluation Logic
    //---------------------------------
    logic branch_taken;    // True if the specific branch condition is met

    always_comb begin
        branch_taken = 1'b0; // Default to not taken

        if (Branch) begin
            case (funct3)
                // BEQ: Branch if rs1 == rs2 (ALU subtraction result is 0)
                `FUNCT3_BEQ: branch_taken = (alu_result == 32'b0); 
                
                // BNE: Branch if rs1 != rs2 (ALU subtraction result is not 0)
                `FUNCT3_BNE: branch_taken = (alu_result != 32'b0); 
                
                // BLT: Branch if rs1 < rs2 (ALU SLT result is 1)
                `FUNCT3_BLT: branch_taken = (alu_result == 32'b1); 
                
                // BGE: Branch if rs1 >= rs2 (ALU SLT result is 0)
                `FUNCT3_BGE: branch_taken = (alu_result == 32'b0); 
                
                // BLTU: Branch if rs1 < rs2, unsigned (ALU SLTU result is 1)
                `FUNCT3_BLTU: branch_taken = (alu_result == 32'b1); 
                
                // BGEU: Branch if rs1 >= rs2, unsigned (ALU SLTU result is 0)
                `FUNCT3_BGEU: branch_taken = (alu_result == 32'b0); 
                
                default: branch_taken = 1'b0;
            endcase
        end
    end

    // The final PC select signal is high only if it's a branch and the condition is met
    assign BranchPCSel = Branch & branch_taken;


    //--------------------------------
    // Data Memory
    //--------------------------------

    logic [31:0]    data_mem_out;                   // Data read from data memory
    

    logic [31:0] mem_write_data;
    logic [3:0]  MemWrEn;

    always_comb begin
        MemWrEn = 4'b0000;
        mem_write_data = 32'b0;

        if (MemWrite) begin
            case (funct3)
                `FUNCT3_SB: begin // Store Byte
                    // Replicate the lowest byte across all 4 lanes
                    mem_write_data = {4{data2[7:0]}}; 
                    // Shift a single '1' to the correct byte lane
                    MemWrEn = 4'b0001 << alu_result[1:0]; 
                end
                
                `FUNCT3_SH: begin // Store Halfword
                    // Replicate the lowest halfword across both lanes
                    mem_write_data = {2{data2[15:0]}}; 
                    // Enable the upper or lower 2 bytes based on address bit 1
                    MemWrEn = (alu_result[1]) ? 4'b1100 : 4'b0011; 
                end
                
                `FUNCT3_SW: begin // Store Word
                    mem_write_data = data2;
                    MemWrEn = 4'b1111;
                end
                
                default: begin
                    mem_write_data = data2;
                    MemWrEn = 4'b1111;
                end
            endcase
        end
    end

    data_memory data_mem (
        .clk(clk),
        .addr(alu_result),
        .data_in(mem_write_data),
        .wr_en(MemWrEn),
        .data_out(data_mem_out)
    );

    //---------------------------------------------------------
    // Load Data Extraction and Extension
    //---------------------------------------------------------
    always_comb begin
        // Default: pass the raw 32-bit word directly (used for LW)
        data_mem_out_ext = data_mem_out;

        case (funct3)
            `FUNCT3_LB: begin // Load Byte (Sign-Extended)
                case (alu_result[1:0])
                    2'b00: data_mem_out_ext = {{24{data_mem_out[7]}},  data_mem_out[7:0]};
                    2'b01: data_mem_out_ext = {{24{data_mem_out[15]}}, data_mem_out[15:8]};
                    2'b10: data_mem_out_ext = {{24{data_mem_out[23]}}, data_mem_out[23:16]};
                    2'b11: data_mem_out_ext = {{24{data_mem_out[31]}}, data_mem_out[31:24]};
                endcase
            end
            
            `FUNCT3_LBU: begin // Load Byte Unsigned (Zero-Extended)
                case (alu_result[1:0])
                    2'b00: data_mem_out_ext = {24'b0, data_mem_out[7:0]};
                    2'b01: data_mem_out_ext = {24'b0, data_mem_out[15:8]};
                    2'b10: data_mem_out_ext = {24'b0, data_mem_out[23:16]};
                    2'b11: data_mem_out_ext = {24'b0, data_mem_out[31:24]};
                endcase
            end
            
            `FUNCT3_LH: begin // Load Halfword (Sign-Extended)
                // For half-words, we only look at bit 1 of the address
                case (alu_result[1])
                    1'b0: data_mem_out_ext = {{16{data_mem_out[15]}}, data_mem_out[15:0]};
                    1'b1: data_mem_out_ext = {{16{data_mem_out[31]}}, data_mem_out[31:16]};
                endcase
            end
            
            `FUNCT3_LHU: begin // Load Halfword Unsigned (Zero-Extended)
                case (alu_result[1])
                    1'b0: data_mem_out_ext = {16'b0, data_mem_out[15:0]};
                    1'b1: data_mem_out_ext = {16'b0, data_mem_out[31:16]};
                endcase
            end
            
            `FUNCT3_LW: begin // Load Word
                data_mem_out_ext = data_mem_out;
            end
            
            default: begin
                data_mem_out_ext = data_mem_out;
            end
        endcase
    end

    
endmodule
