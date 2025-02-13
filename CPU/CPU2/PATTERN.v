//############################################################################
//   2024 Digital Circuit and System Lab
//   HW04        : Single Cycle CPU
//   Author      : Ceres Lab 2024 MS1 Student
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   Date        : 2024/05/28
//   Version     : v1.0
//   File Name   : PATTERN.v
//   Module Name : PATTERN
//############################################################################

`define CYCLE_TIME 5.5

module PATTERN(
    //Output Port
    clk,
    rst_n,
    data_read,
    instruction,
    //Input Port
    data_wen,
    data_addr,
    inst_addr,
    data_write
);
//==============================================//
//          Input & Output Declaration          //
//==============================================//
output reg clk, rst_n;
output [31:0] data_read;
output [31:0] instruction;

input data_wen;
input [31:0] data_addr, inst_addr;
input [31:0] data_write;

//==============================================//
//               Parameter & Integer            //
//==============================================//
// User modification
integer   SEED = 587;
integer   MAX_LATENCY = 100000;

// PATTERN operation
parameter CYCLE = `CYCLE_TIME;

// PATTERN CONTROL
integer cycle_time = CYCLE;
integer total_latency;
integer latency;
integer i_pat;
integer i, j, k, l;
integer out_valid_count;

//==============================================//
//                 Signal Declaration           //
//==============================================//
parameter INST_r = "../00_TESTBED/DATA/instruction.dat";

parameter DATA_r = "../00_TESTBED/DATA/init_data.dat";
parameter DATA_g = "../00_TESTBED/DATA/golden_data.dat";


reg [31:0] DATA_golden [0:1023];

initial $readmemh(DATA_r, u_DataMemory.Mem);
initial $readmemh(INST_r, u_InstMem.Mem);
initial $readmemh(DATA_g, DATA_golden);

//==============================================//
//                 String control               //
//==============================================//
// Should use %0s
string reset_color          = "\033[1;0m";
string txt_black_prefix     = "\033[1;30m";
string txt_red_prefix       = "\033[1;31m";
string txt_green_prefix     = "\033[1;32m";
string txt_yellow_prefix    = "\033[1;33m";
string txt_blue_prefix      = "\033[1;34m";
string txt_magenta_prefix   = "\033[1;35m";
string txt_cyan_prefix      = "\033[1;36m";

string bkg_black_prefix     = "\033[40;1m";
string bkg_red_prefix       = "\033[41;1m";
string bkg_green_prefix     = "\033[42;1m";
string bkg_yellow_prefix    = "\033[43;1m";
string bkg_blue_prefix      = "\033[44;1m";
string bkg_white_prefix     = "\033[47;1m";

//==============================================//
//                main function                 //
//==============================================//
initial begin
	reset_task;

	// initial variable
	total_latency = 0;
	
	// start to test

	wait_out_valid_task; // wait out_valid pull high
	check_ans_task; // check answer
	total_latency = total_latency + latency;
	pass_task;
end

 

//==============================================//
//            Clock and Reset Function          //
//==============================================//
// clock
always begin
	#(CYCLE/2);
	clk = ~clk;
end

// reset task
task reset_task; begin	
	// initiaize signal
	clk = 0;
	rst_n = 1;

	// force clock to be 0, do not flip in half cycle
	force clk = 0;

	#(CYCLE*3);
	
	// reset
	rst_n = 0;  #(CYCLE*4); // wait 4 cycles to check output signal
	// check reset

	// release reset
	rst_n = 1; #(CYCLE*3);
	
	// release clock
	release clk; repeat(5) @ (negedge clk);
end endtask

// wait out valid task
task wait_out_valid_task; begin
	latency = 0;
	// wait out valid
	while(inst_addr !== 32) begin
		@ (negedge clk);
		latency = latency + 1;
		// check latency is over MAX_LATENCY
		if(latency > MAX_LATENCY) begin
			$display("%0s================================================================", txt_red_prefix);
			$display("                             FAIL"                           );
			$display("    the execution latency is over %4d cycles at %-8d ps  ", MAX_LATENCY, $time*1000);
			$display("================================================================%0s", reset_color);
			$finish;
		end
	end
	#(CYCLE*5);
end endtask

// check answer task in 4 cycle
task check_ans_task ; begin
	$writememh("../00_TESTBED/DATA/data_out.dat", u_DataMemory.Mem);
	for(i = 0; i < 1024; i = i + 1) begin
		if(DATA_golden[i] !== u_DataMemory.Mem[i]) begin
			$display("%0s================================================================", txt_red_prefix);
			$display("                             FAIL"                           );
			$display("    the data memory is not correct at address %4d at %-8d ps  ", i, $time*1000);
			$display("================================================================%0s", reset_color);
			$finish;
		end
	end
	repeat({$random(SEED)} % 3 + 2) @ (negedge clk);
end endtask

//==============================================//
//            Pass and Finish Function          //
//==============================================//
// pass task
task pass_task; begin
	$display("%0s========================================================", txt_magenta_prefix);
	$display("                      Congratulations!!");
    $display("                     All Pattern Test Pass");
	$display("                       Cycle time = %-2d ns", cycle_time);
	$display("          Your execution cycles = %-4d cycles", total_latency);
	$display("======================================================== %0s", reset_color);
	$finish;
end	endtask

DataMemory u_DataMemory(
	//inputs
	.clock(clk),
	.address(data_addr),
	.MemWrite(data_wen),
	.MemRead(!data_wen),
	.WriteData(data_write),
	//outputs
	.ReadData(data_read)
);

InstMem u_InstMem(
	//inputs
	.clock(clk),
	.rst_n(rst_n),
	.address(inst_addr),
	//outputs
	.inst(instruction)
);

endmodule

module DataMemory (clock, address, MemWrite, MemRead, WriteData, ReadData);

	input clock;
	input [31:0] address;
	input MemWrite, MemRead;
	input [31:0] WriteData; 
	
	output reg [31:0] ReadData;

	reg [31:0] Mem [0:1023]; //32 bits memory with 1024 entries
	
	always @ (posedge clock) begin
		if (MemWrite == 1)
			Mem[address] <= WriteData;
	end
	
	always @(*) begin
		if (MemRead == 1)
			ReadData <= Mem[address];
		else
			ReadData <= 0;
	end	
endmodule

module InstMem(clock, address, inst , rst_n);

	input clock;
	input rst_n;
	input [31:0] address;
	
	output reg [31:0]	inst;
	
	reg [31:0] Mem [0:1023];
	
	always @(*) begin
		if(!rst_n) begin
			inst <= Mem[0];
		end
		else begin
			inst <= Mem[address];
		end
	end
endmodule