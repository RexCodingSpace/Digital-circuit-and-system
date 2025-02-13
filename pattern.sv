`timescale 1ns/10ps
module pattern(
  // output signals
	clk,
	rst_n,
    in_number,
    mode,
    in_valid,
  // input signals
	out_valid,
	out_result
);

output logic  clk,rst_n,in_valid;
output logic signed [3:0] in_number ;
output logic [1:0] mode;
logic signed [3:0] in [0:3];
logic signed [3:0] in1,in2,in3,in4;
logic signed [3:0] tmp;
logic signed [3:0] innumber [0:3] ;
input out_valid;
input signed [5:0] out_result;
logic signed [5:0] golden;


//================================================================
// parameters & integer
//================================================================
integer PATNUM = 100;
integer CYCLE = 10;
integer total_latency,latency;
integer i,j;
integer patcount;


//================================================================
// initial
//================================================================

always	#(CYCLE/2.0) clk = ~clk;
initial	clk = 0;


initial begin
	in_valid = 0;
	rst_n = 1;
	force clk = 0;
	reset_task;
	release clk;
	total_latency = 0; 
    @(negedge clk);
	for (patcount=0;patcount<PATNUM;patcount=patcount+1)begin
		input_task;
		wait_outvalid;
		check_ans;
		outvalid_rst;
		@(negedge clk);
	end

	YOU_PASS_task;  
    $finish;
end

//================================================================
// task
//================================================================



// let rst_n = 0 for 3 cycles & check SPEC1(All output signals should be reset after the reset signal is asserted)
task reset_task ; begin
    //finish the task here vvv
    // Assert reset signal rst_n
    rst_n = 0;
    // Wait for 3 cycles
	#(CYCLE*3); 
	
    // Reset all output signals here
	rst_n=1;
    mode=0;
    in_valid=0;
	in_number=0;
    // Add more output signals if needed
	if(out_result !== 0 || out_valid !== 0) begin
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		$display ("                                                                    SPEC 1 FAIL                                                              ");
		$display ("                                                                       Reset                                                                ");
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		$finish;
	end
	//finish the task here vvv
end endtask

//generate random inputs & assign to in_number in the specific cycle & calculate the golden value
task input_task ; begin
	
    //finish the task here vvv
	
//generate mode and input
	for(i = 0; i < 4; i = i + 1) begin
	 	innumber[i]= $urandom_range(7,-8);
		in[i]=innumber[i];
	end
	mode=$urandom_range(3,0);

//input
	i=0;
	in_valid=1;	
	for(i = 0; i < 4; i = i + 1) begin
		in_number = innumber[i];
		@ (negedge clk);
	end
	in_valid=0;
	
	
	
//sorting
	for(i=0;i<4;i=i+1)begin
		for(j=i+1;j<4;j=j+1)begin
			if(in[i]<in[j])begin
				in[i]=in[i];
				in[j]=in[j];
			end else begin
				tmp=in[i];
				in[i]=in[j];
				in[j]=tmp;
			end
		end
	end

	for(i=0;i<4;i=i+1)begin
		if(i===0)begin
		in1=in[0];
		end else if (i===1)begin
		in2=in[1];
		end else if (i===2)begin
		in3=in[2];
		end else begin
		in4=in[3];
		end
		
	end

	case (mode)

		0:begin
			golden = in[0] + in[1];
		end
		1:begin
			golden = in[1] - in[0];
		end
		2:begin
			golden = in[3] - in[2];
		end
		3:begin
			golden = in[0] - in[3];
		end

		default: golden=0;
	endcase
	//finish the task here vvv
end endtask

// check SPEC2 (The out_valid must be high for exact 1 cycles during output)
task outvalid_rst;begin
    //finish the task here vvv
    // Wait for out_valid to be high
    // Wait for one cycle
	if (out_valid === 1) begin
	#CYCLE;
	end
    // Check if out_valid remains high
    if (out_valid === 1) begin
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        $display ("                                                                    SPEC 2 FAIL                                                              ");
        $display ("                                                         Output should be zero after check                                                  ");
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
     	$finish;
    end
	// @(posedge out_valid);

	//finish the task here vvv
end endtask

// check SPEC3 (Outvalid cannot overlap with in_valid)

    //finish the task here vvv
always @(posedge clk)begin
	if(in_valid === 1 && out_valid === 1) begin
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		$display ("                                                                    SPEC 3 FAIL                                                               ");
		$display ("                                                Outvalid should be zero before give data finish                                            ");
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		$finish;
	end
end    
	


//check SPEC4 (The execution latency should not over 100 cycles)
task wait_outvalid ; begin
    //finish the task here vvv
    latency = 0;
	// wait out valid
	while(!out_valid) begin
		@ (negedge clk);
		latency = latency + 1;
		// check latency is over MAX_LATENCY
		if(latency > 100) begin
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		$display ("                                                                    SPEC 4 FAIL                                                               ");
		$display ("                                                  The execution latency are over 100  cycles                                            ");
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		$finish;
		end
		if(out_valid)begin
			break;
		end
	end
	latency=0;
	//finish the task here vvv
end endtask

// check SPEC5 (The output should be correct when out_valid is high)
task check_ans ; begin
    if(out_valid === 1) begin
        if (golden!== out_result)begin
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $display ("                                                                    SPEC 5 FAIL                                                             ");
            $display ("                                                                    YOUR:  %d                                                 ",out_result);
            $display ("                                                                    GOLDEN: %d                                                    ",golden);
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
			$finish;
		end
    end
end endtask



/*
$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
$display ("                                                                    SPEC 1 FAIL                                                              ");
$display ("                                                                       Reset                                                                ");
$display ("--------------------------------------------------------------------------------------------------------------------------------------------");

$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
$display ("                                                                    SPEC 2 FAIL                                                              ");
$display ("                                                         Output should be zero after check                                                  ");
$display ("--------------------------------------------------------------------------------------------------------------------------------------------");

$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
$display ("                                                                    SPEC 3 FAIL                                                               ");
$display ("                                                Outvalid should be zero before give data finish                                            ");
$display ("--------------------------------------------------------------------------------------------------------------------------------------------");

$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
$display ("                                                                    SPEC 4 FAIL                                                               ");
$display ("                                                  The execution latency are over 100  cycles                                            ");
$display ("--------------------------------------------------------------------------------------------------------------------------------------------");

$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
$display ("                                                                    SPEC 5 FAIL                                                             ");
$display ("                                                                    YOUR:  %d                                                 ",out_result);
$display ("                                                                    GOLDEN: %d                                                    ",golden);
$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
*/

task YOU_PASS_task;begin

$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
$display ("                                                               Congratulations!                						             ");
$display ("                                                        You have passed all patterns!          						             ");
$display ("                                                                time: %8t ns                                                        ",$time);
$display ("--------------------------------------------------------------------------------------------------------------------------------------------");

$finish;	
end endtask

endmodule


