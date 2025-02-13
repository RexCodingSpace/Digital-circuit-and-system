`timescale 1ns/10ps
module huffman( 
    clk, 
    reset, 
    gray_valid, 
    gray_data, 
    CNT_valid, 
    CNT,
    code_valid, 
    HC, 
    M, 
    in_Aid_all, 
    in_CNT_all, 
    out_Aid_all, 
    out_CNT_all
);

input               clk;
input               reset;
input               gray_valid;
input       [7:0]   gray_data;

output reg          CNT_valid;
output reg  [47:0]  CNT;
output reg          code_valid;
output reg  [47:0]  HC;
output reg  [47:0]  M;

// ===============================================================
//      SORT(6 input)
// ===============================================================
output reg [47:0]   in_Aid_all;
output reg [47:0]   in_CNT_all;

input      [47:0]   out_Aid_all;
input      [47:0]   out_CNT_all;

reg [7:0] in_Aid [5:0];
reg [7:0] in_CNT [5:0];
//sortID,sortCNT
reg [7:0] out_Aid [5:0];
reg [7:0] out_CNT [5:0];

always @(*) begin
    in_Aid_all = {in_Aid[5], in_Aid[4], in_Aid[3], in_Aid[2], in_Aid[1], in_Aid[0]};
    in_CNT_all = {in_CNT[5], in_CNT[4], in_CNT[3], in_CNT[2], in_CNT[1], in_CNT[0]};
end

always @(*) begin
    {out_Aid[5], out_Aid[4], out_Aid[3], out_Aid[2], out_Aid[1], out_Aid[0]} = out_Aid_all;
    {out_CNT[5], out_CNT[4], out_CNT[3], out_CNT[2], out_CNT[1], out_CNT[0]} = out_CNT_all;
end
// ===============================================================
//      Reg & Wire Declaration
// ===============================================================
integer i;
reg [2:0] current_state,next_state;
reg [7:0] count; // Counter for the 100 pixels
reg [7:0] pixel_counts [5:0]; // Counts for A1 to A6
reg [2:0]combCNT;
reg [1:0] cnts;
reg [3:0] treecnt;

reg [7:0] SortID[5:0];
reg [7:0] SortCNT[5:0];

reg [7:0] ID [5:0];
reg [7:0] Code [5:0];
reg [7:0] Mask [5:0];
reg [7:0] Pointer [5:0];
// ===============================================================
//      FSM state
// ===============================================================

//You can modify the FSM state
localparam IDLE = 'd0;
localparam READ = 'd1;
localparam SORT = 'd2;
localparam COMB  = 'd3;
localparam OUT  = 'd4;

//================================================================
//      FSM design
//================================================================

always @(posedge clk or posedge reset) begin
    if (reset) begin
        current_state <= IDLE;
    end else begin
        current_state <= next_state;
    end
end

always @(*) begin
    case (current_state)
        IDLE: begin
            if (gray_valid) begin
                next_state=READ;
            end else begin
                next_state = current_state;
            end
        end 

        READ: begin
            if (count=='d100) begin
                next_state = COMB;
            end else begin
                next_state = current_state;
            end
        end

        SORT: begin
            if (combCNT=='d6) begin
                next_state = OUT;
            end else begin
                if (cnts==1) begin //改
                    next_state=COMB;
                end else begin
                    next_state = current_state;
                end
            end
        end

        COMB: begin
            if (combCNT=='d6) begin //改
                next_state = OUT;
            end else begin
                next_state = SORT;
            end
        end

        OUT: begin
            if (code_valid=='d0) begin
                next_state = IDLE;
            end else begin
                next_state = current_state;
            end
        end

        default: begin
            next_state = IDLE;
        end
    endcase
end


// ===============================================================
//      Design
// ===============================================================
// State READ: Counting pixel occurrences
always @(posedge clk or posedge reset) begin
    if(reset)begin
        for (i = 0; i < 6; i = i + 1) begin
            pixel_counts[i] <= 8'd0;
        end
        count<=0;
    end else if(next_state==IDLE)begin  //歸零可以用for loop
        for (i = 0; i < 6; i = i + 1) begin
            pixel_counts[i] <= 8'd0;
        end
        count<=0;
    end else if (next_state==READ||current_state == READ) begin
        if (gray_valid) begin
            case (gray_data)
                'd01: pixel_counts[0] <= pixel_counts[0] + 1;
                'd02: pixel_counts[1] <= pixel_counts[1] + 1;
                'd03: pixel_counts[2] <= pixel_counts[2] + 1;
                'd04: pixel_counts[3] <= pixel_counts[3] + 1;
                'd05: pixel_counts[4] <= pixel_counts[4] + 1;
                'd06: pixel_counts[5] <= pixel_counts[5] + 1;
                default: begin
                    pixel_counts[0] <= pixel_counts[0] ;
                    pixel_counts[1] <= pixel_counts[1] ;
                    pixel_counts[2] <= pixel_counts[2] ;
                    pixel_counts[3] <= pixel_counts[3] ;
                    pixel_counts[4] <= pixel_counts[4] ;
                    pixel_counts[5] <= pixel_counts[5] ; 
                end
            endcase
            count <= count + 1;
        end
    end else begin
        pixel_counts[0] <= pixel_counts[0] ;
        pixel_counts[1] <= pixel_counts[1] ;
        pixel_counts[2] <= pixel_counts[2] ;
        pixel_counts[3] <= pixel_counts[3] ;
        pixel_counts[4] <= pixel_counts[4] ;
        pixel_counts[5] <= pixel_counts[5] ; 
    end
end


always @(posedge clk or posedge reset) begin
    if (reset) begin
    // Initialize Huffman related registers
        ID[0] <= 8'd1; ID[1] <= 8'd2; ID[2] <= 8'd3; ID[3] <= 8'd4; ID[4] <= 8'd5; ID[5] <= 8'd6;
        Code[0] <= 8'd0; Code[1] <= 8'd0; Code[2] <= 8'd0; Code[3] <= 8'd0; Code[4] <= 8'd0; Code[5] <= 8'd0;
        Mask[0] <= 8'd0; Mask[1] <= 8'd0; Mask[2] <= 8'd0; Mask[3] <= 8'd0; Mask[4] <= 8'd0; Mask[5] <= 8'd0;
        Pointer[0] <= 8'd0; Pointer[1] <= 8'd0; Pointer[2] <= 8'd0; Pointer[3] <= 8'd0; Pointer[4] <= 8'd0; Pointer[5] <= 8'd0;
    end else if(current_state==IDLE)begin  //歸零可以用for loop
        ID[0] <= 8'd1; ID[1] <= 8'd2; ID[2] <= 8'd3; ID[3] <= 8'd4; ID[4] <= 8'd5; ID[5] <= 8'd6;
        Code[0] <= 8'd0; Code[1] <= 8'd0; Code[2] <= 8'd0; Code[3] <= 8'd0; Code[4] <= 8'd0; Code[5] <= 8'd0;
        Mask[0] <= 8'd0; Mask[1] <= 8'd0; Mask[2] <= 8'd0; Mask[3] <= 8'd0; Mask[4] <= 8'd0; Mask[5] <= 8'd0;
        Pointer[0] <= 8'd0; Pointer[1] <= 8'd0; Pointer[2] <= 8'd0; Pointer[3] <= 8'd0; Pointer[4] <= 8'd0; Pointer[5] <= 8'd0;
    end else if (current_state==SORT&&cnts==1)begin
        //已經處理的，for省去程式碼的複雜度
        for(i=0;i<=5;i=i+1)begin
            if(ID[i]>6&&ID[i]<'d127)begin
                ID[i]<=treecnt;
                Code[i]<=Code[i]+'d2**(Pointer[i]);
                Pointer[i]<=Pointer[i]+1;
                Mask[i]<=Mask[i]+'d2**(Pointer[i]);
            end else begin
                ID[i]=ID[i];
            end
        end
        //新的
        ID[out_Aid[0]-1]<=treecnt;
        ID[out_Aid[1]-1]<=treecnt;
        if(combCNT==1)begin
            Code[out_Aid[0]-1]<=1;
            Code[out_Aid[1]-1]<=0;
            Mask[out_Aid[0]-1]<=1;
            Mask[out_Aid[1]-1]<=1;
            Pointer[out_Aid[0]-1]<=Pointer[out_Aid[0]-1]+1;
            Pointer[out_Aid[1]-1]<=Pointer[out_Aid[1]-1]+1;
        end else if (ID[out_Aid[1]-1]<7) begin
            Code[out_Aid[1]-1]<=0;
            Pointer[out_Aid[1]-1]<=Pointer[out_Aid[1]-1]+1;
            Mask[out_Aid[1]-1]<=1;
        end else begin 
            Code[out_Aid[0]-1]<=1;
            Pointer[out_Aid[0]-1]<=Pointer[out_Aid[0]-1]+1;
            Mask[out_Aid[0]-1]<=1;
        end
    end else begin
       ID[0]<=ID[0];
    end
end

// State SORT: Sorting and Huffman coding
always @(posedge clk or posedge reset) begin
    if (reset) begin
        for (i = 0; i < 6; i = i + 1) begin
            in_Aid[i] <= 8'd0;
            in_CNT[i] <= 8'd0;
        end    
    end else if (current_state == SORT&&cnts==0) begin
        // Sorting input data
        in_Aid[0] <= SortID[0];
        in_Aid[1] <= SortID[1];
        in_Aid[2] <= SortID[2];
        in_Aid[3] <= SortID[3];
        in_Aid[4] <= SortID[4];
        in_Aid[5] <= SortID[5];

        in_CNT[0] <= SortCNT[0];
        in_CNT[1] <= SortCNT[1];
        in_CNT[2] <= SortCNT[2];
        in_CNT[3] <= SortCNT[3];
        in_CNT[4] <= SortCNT[4];
        in_CNT[5] <= SortCNT[5];
    end else begin
        in_Aid[0] <= in_Aid[0];
        in_Aid[1] <= in_Aid[0];
        in_Aid[2] <= in_Aid[0];
        in_Aid[3] <= in_Aid[0];
        in_Aid[4] <= in_Aid[0];
        in_Aid[5] <= in_Aid[0];

        in_CNT[0] <= in_CNT[0];
        in_CNT[1] <= in_CNT[0];
        in_CNT[2] <= in_CNT[0];
        in_CNT[3] <= in_CNT[0];
        in_CNT[4] <= in_CNT[0];
        in_CNT[5] <= in_CNT[0];
    end
end

always@(posedge clk or posedge reset) begin
    if(reset)begin
        cnts<=0;
    end else if (current_state==SORT)begin
        cnts<=cnts+1;
    end else begin 
        cnts<=0;
    end
end

always@(posedge clk or posedge reset) begin
    if(reset)begin
        treecnt<=6;
    end else if (current_state==IDLE)begin
        treecnt<=6;
    end else if (current_state==COMB)begin
        treecnt<=treecnt+1;
    end else begin 
        treecnt<=treecnt;
    end
end

always @(posedge clk or posedge reset) begin
    if (reset) begin
        combCNT<='d0;

        SortID[0] <= ID[0];
        SortID[1] <= ID[1];
        SortID[2] <= ID[2];
        SortID[3] <= ID[3];
        SortID[4] <= ID[4];
        SortID[5] <= ID[5];

        SortCNT[0] <= pixel_counts[0];
        SortCNT[1] <= pixel_counts[1];
        SortCNT[2] <= pixel_counts[2];
        SortCNT[3] <= pixel_counts[3];
        SortCNT[4] <= pixel_counts[4];
        SortCNT[5] <= pixel_counts[5];
    end else if (current_state==READ)begin 

        combCNT<='d0;
        SortID[0] <= ID[0];
        SortID[1] <= ID[1];
        SortID[2] <= ID[2];
        SortID[3] <= ID[3];
        SortID[4] <= ID[4];
        SortID[5] <= ID[5];

        SortCNT[0] <= pixel_counts[0];
        SortCNT[1] <= pixel_counts[1];
        SortCNT[2] <= pixel_counts[2];
        SortCNT[3] <= pixel_counts[3];
        SortCNT[4] <= pixel_counts[4];
        SortCNT[5] <= pixel_counts[5];
    
    end else if (current_state==COMB)begin
        if(combCNT==0)begin
            SortID[0] <= SortID[0];
            SortID[1] <= SortID[1];
            SortID[2] <= SortID[2];
            SortID[3] <= SortID[3];
            SortID[4] <= SortID[4];
            SortID[5] <= SortID[5];

            SortCNT[0] <= SortCNT[0];
            SortCNT[1] <= SortCNT[1];
            SortCNT[2] <= SortCNT[2];
            SortCNT[3] <= SortCNT[3];
            SortCNT[4] <= SortCNT[4];
            SortCNT[5] <= SortCNT[5];
            combCNT<=combCNT+'d1;
        end else begin
            SortID[1]<=treecnt;
            SortID[0]<='d127;
            SortCNT[1]<=SortCNT[1]+SortCNT[0];
            SortCNT[0]<='d127;
            combCNT<=combCNT+'d1;
        end
    end else if (current_state==SORT&&cnts==1) begin

        SortID[0] <= out_Aid[0];
        SortID[1] <= out_Aid[1];
        SortID[2] <= out_Aid[2];
        SortID[3] <= out_Aid[3];
        SortID[4] <= out_Aid[4];
        SortID[5] <= out_Aid[5];

        SortCNT[0] <= out_CNT[0];
        SortCNT[1] <= out_CNT[1];
        SortCNT[2] <= out_CNT[2];
        SortCNT[3] <= out_CNT[3];
        SortCNT[4] <= out_CNT[4];
        SortCNT[5] <= out_CNT[5];
    end else begin 
        SortID[0] <= SortID[0];
        SortID[1] <= SortID[1];
        SortID[2] <= SortID[2];
        SortID[3] <= SortID[3];
        SortID[4] <= SortID[4];
        SortID[5] <= SortID[5];

        SortCNT[0] <= SortCNT[0];
        SortCNT[1] <= SortCNT[1];
        SortCNT[2] <= SortCNT[2];
        SortCNT[3] <= SortCNT[3];
        SortCNT[4] <= SortCNT[4];
        SortCNT[5] <= SortCNT[5];
    end
end


// State OUT: Generating Huffman codes and masks
always @(posedge clk or posedge reset) begin
    if (reset) begin
        CNT <= 48'd0;
        HC <= 48'd0;
        M <= 48'd0;
        CNT_valid <= 0;
        code_valid <= 0;
    end else if (current_state == OUT) begin
        // Update CNT with sorted counts
        CNT <= {pixel_counts[0], pixel_counts[1], pixel_counts[2], pixel_counts[3], pixel_counts[4], pixel_counts[5]};
        CNT_valid <= 1;

        // Generate Huffman codes and masks (given values)
        HC <= {Code[0], Code[1], Code[2], Code[3], Code[4], Code[5]}; // Example Huffman codes
        M <= {Mask[0], Mask[1], Mask[2], Mask[3], Mask[4], Mask[5]}; // Example masks
        code_valid <= 1;
    end else begin
        CNT <= 48'd0;
        HC <= 48'd0;
        M <= 48'd0;
        CNT_valid <= 0;
        code_valid <= 0;
    end
end

endmodule


