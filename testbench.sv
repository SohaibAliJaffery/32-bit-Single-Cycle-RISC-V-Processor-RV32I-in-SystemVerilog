/* ----------------------------------------------------------------------------
 * Copyright (c) 2026 Sohaib Ali Jaffery
 * 
 * Author:  Sohaib Ali Jaffery <sohaibjaffery@outlook.com>
 * GitHub:  github.com/SohaibAliJaffery
 * 
 * This file is part of a single-cycle RV32I processor implementation.
 * ------------------------------------------------------------------------- */

`timescale 1ns/1ps

module testbench;

	logic clk;
	logic rst_n;

	localparam logic [31:0] EXPECTED_X1 = 32'd5;
	localparam logic [31:0] EXPECTED_X2 = 32'd10;
	localparam logic [31:0] EXPECTED_X3 = 32'd15;
	localparam logic [31:0] EXPECTED_MEM0 = 32'd5;
	localparam logic [31:0] EXPECTED_MEM1 = 32'd10;
	localparam logic [31:0] EXPECTED_MEM2 = 32'd15;

	rv32i_singlecycle dut (
		.clk(clk),
		.rst_n(rst_n)
	);

	initial begin
		clk = 1'b0;
		forever #5 clk = ~clk;
	end

	initial begin
		rst_n = 1'b0;
		#20;
		rst_n = 1'b1;

		repeat (8) @(posedge clk);
		#1;

		$display("x1 expected=%0d actual=%0d", EXPECTED_X1, dut.regfile.reg_array[1]);
		$display("x2 expected=%0d actual=%0d", EXPECTED_X2, dut.regfile.reg_array[2]);
		$display("x3 expected=%0d actual=%0d", EXPECTED_X3, dut.regfile.reg_array[3]);
		$display("mem[0] expected=%0d actual=%0d", EXPECTED_MEM0, dut.data_mem.ram_inst.RamArray[0]);
		$display("mem[1] expected=%0d actual=%0d", EXPECTED_MEM1, dut.data_mem.ram_inst.RamArray[1]);
		$display("mem[2] expected=%0d actual=%0d", EXPECTED_MEM2, dut.data_mem.ram_inst.RamArray[2]);

		if (dut.regfile.reg_array[1] !== EXPECTED_X1 ||
			dut.regfile.reg_array[2] !== EXPECTED_X2 ||
			dut.regfile.reg_array[3] !== EXPECTED_X3 ||
			dut.data_mem.ram_inst.RamArray[0] !== EXPECTED_MEM0 ||
			dut.data_mem.ram_inst.RamArray[1] !== EXPECTED_MEM1 ||
			dut.data_mem.ram_inst.RamArray[2] !== EXPECTED_MEM2) begin
			$error("Final state mismatch");
		end else begin
			$display("PASS: register file and data memory match expected values");
		end

		$finish;
	end

endmodule

