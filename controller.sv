/* ----------------------------------------------------------------------------
 * Copyright (c) 2026 Sohaib Ali Jaffery
 * 
 * Author:  Sohaib Ali Jaffery <sohaibjaffery@outlook.com>
 * GitHub:  github.com/SohaibAliJaffery
 * 
 * This file is part of a single-cycle RV32I processor implementation.
 * ------------------------------------------------------------------------- */

`include "rv32i_defs.svh"

module controller (
    input  logic [31:0]     instruction,

    // Control signals
    output logic            RegWrite,
    output logic [1:0]      RegWBSelect,
    output logic            MemWrite,
    output logic [3:0]      ALUControl,
    output logic            JalrPCSel,
    output logic            JalPCSel,
    output logic            BranchPCSel,
    output logic            SrcSel,
    output logic [2:0]      ImmSel,
    output logic            AuipcSel,
    output logic            MemRead,
    output logic            Branch
);

    // Extract different fields from the instruction
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;

    assign opcode = instruction[6:0];
    assign funct3 = instruction[14:12];
    assign funct7 = instruction[31:25];

    always_comb begin
        // Default values
        RegWrite    = 0;
        RegWBSelect = 2'b00;
        MemWrite    = 0;
        MemRead     = 0;
        ALUControl  = 4'b0000;
        JalrPCSel   = 0;
        JalPCSel    = 0;
        BranchPCSel = 0;
        SrcSel      = 0;
        ImmSel     = 3'b000;
        AuipcSel    = 0;
        Branch      = 0;

        case (opcode)
            `OPCODE_OP: begin
                RegWrite = 1;
                RegWBSelect = 2'b00;
                case (funct3)
                    `FUNCT3_ADD_SUB: ALUControl = (funct7 == `FUNCT7_SUB) ? 4'b0001 : 4'b0000;
                    `FUNCT3_SLL:     ALUControl = 4'b0110;
                    `FUNCT3_SLT:     ALUControl = 4'b1010;
                    `FUNCT3_SLTU:    ALUControl = 4'b1001;
                    `FUNCT3_XOR:     ALUControl = 4'b0100;
                    `FUNCT3_SRL_SRA: ALUControl = (funct7 == `FUNCT7_SRA) ? 4'b1000 : 4'b0111;
                    `FUNCT3_OR:      ALUControl = 4'b0011;
                    `FUNCT3_AND:     ALUControl = 4'b0010;
                    default:         ALUControl = 4'bxxxx;
                endcase
            end

            `OPCODE_OP_IMM: begin
                RegWrite = 1;
                RegWBSelect = 2'b00;
                SrcSel = 1;

                case (funct3)
                    `FUNCT3_ADDI:    ALUControl = 4'b0000;
                    `FUNCT3_SLTI:    ALUControl = 4'b1010;
                    `FUNCT3_SLTIU:   ALUControl = 4'b1001;
                    `FUNCT3_XORI:    ALUControl = 4'b0100;
                    `FUNCT3_ORI:     ALUControl = 4'b0011;
                    `FUNCT3_ANDI:    ALUControl = 4'b0010;
                    `FUNCT3_SLLI:    ALUControl = 4'b0110;
                    `FUNCT3_SRLI_SRAI: ALUControl = (funct7 == `FUNCT7_SRA) ? 4'b1000 : 4'b0111;
                    default:         ALUControl = 4'bxxxx;
                endcase
            end

            `OPCODE_LOAD: begin // Load
                RegWrite = 1;
                RegWBSelect = 2'b01; // Select data from data memory
                MemRead = 1;
                SrcSel = 1;
                ALUControl = 4'b0000; // ADD operation for address calculation
            end

            `OPCODE_STORE: begin // Store
                MemWrite = 1;
                SrcSel = 1;
                ImmSel = 3'b001; 
                ALUControl = 4'b0000; // ADD operation for address calculation
            end

            `OPCODE_BRANCH: begin // Branch
                Branch = 1;
                case (funct3)
                    `FUNCT3_BEQ,
                    `FUNCT3_BNE:  ALUControl = 4'b0001; // SUB operation for comparison
                    `FUNCT3_BLT,
                    `FUNCT3_BGE:  ALUControl = 4'b1010;
                    `FUNCT3_BLTU,
                    `FUNCT3_BGEU: ALUControl = 4'b1001;
                    default:      ALUControl = 4'bxxxx;
                endcase
            end

            `OPCODE_JALR: begin
                RegWrite = 1;
                RegWBSelect = 2'b10;
                JalrPCSel = 1;
                SrcSel = 1;
                ALUControl = 4'b0000;
            end

            `OPCODE_JAL: begin
                RegWrite = 1;
                JalPCSel = 1;
                RegWBSelect = 2'b10; // Write PC+4 to rd

                
            end

            `OPCODE_LUI: begin
                RegWrite = 1;
                RegWBSelect = 2'b11;
                ImmSel = 3'b011; // Select U-type immediate
            end

            `OPCODE_AUIPC: begin
                RegWrite = 1;
                AuipcSel = 1;
                SrcSel = 1;
                ImmSel = 3'b011; // Select U-type immediate
                ALUControl = 4'b0000;
            end

            default: begin
                
                // Handle other opcodes if necessary
                // I'll think of handling other opcodes later
            end
        endcase
    end

endmodule