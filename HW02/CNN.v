module CNN(
    //input
    input                           clk,
    input                           rst_n,
    input                           in_valid,
    input      signed   [15:0]      in_data,
    input                           opt,
    //output
    output reg                      out_valid, 
    output reg signed   [15:0]      out_data	
);

///////////////////////////////////////////////////////
//                   Parameter                       //
///////////////////////////////////////////////////////

//You can modify the states.
parameter IDLE = 3'd0;
parameter READ = 3'd1;
parameter CALC = 3'd2;
parameter MaxP = 3'd3;
parameter OUT  = 3'd4;
integer i, j;
///////////////////////////////////////////////////////
//                       FSM                         //
///////////////////////////////////////////////////////

//You can modify the reg name for your convenience.
reg [2:0] current_state, next_state;

///////////////////////////////////////////////////////
//                   wire & reg                      //
///////////////////////////////////////////////////////
reg [5:0] in_cnt;
reg [1:0] out_cnt;
reg [2:0] x_cnt, y_cnt;
reg [1:0] kernal_xcnt, kernal_ycnt;
reg [1:0] out_x, out_y;
reg signed [15:0] image_buffer [0:5][0:5];
reg signed [15:0] kernal_buffer [0:2][0:2];
reg [2:0] x, y;
reg signed [15:0]Feature_map [0:3][0:3];
reg signed [15:0]RELU_map [0:3][0:3];
reg signed [15:0]Maxp_map [0:1][0:1];
reg signed [15:0]current_map ;
reg signed [15:0]current_map1 ;
reg [2:0] F_xcnt, F_ycnt;
reg current_opt;
reg [3:0]RELU_cnt;
//write down the wire and reg you need here.


///////////////////////////////////////////////////////
//                   FSM design                      //
///////////////////////////////////////////////////////

//If you don't know how to design FSM, you can refer to lab04. 

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        current_state <= IDLE;
    end else begin
        current_state <= next_state;
    end
end

always @(*) begin
    case (current_state)
        IDLE: begin
            if (in_valid) begin
                next_state=READ;
            end else begin
                next_state = current_state;
            end
        end 

        READ: begin
            if (in_cnt==6'd45) begin
                next_state = CALC;
            end else begin
                next_state = current_state;
            end
        end

        CALC: begin
            if (RELU_cnt==4'd15&&x_cnt==3'd2&&y_cnt==3'd2) begin //改
                next_state = MaxP;
            end else begin
                next_state = current_state;
            end
        end

        MaxP: begin
            if (out_x==1&&out_y==1&&x_cnt==1&&y_cnt==1) begin //改
                next_state = OUT;
            end else begin
                next_state = current_state;
            end
        end

        OUT: begin
            if (out_x==1&&out_y==1) begin
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

///////////////////////////////////////////////////////
//                     design                        //
///////////////////////////////////////////////////////

//write down your design here.



////Pointer////
//x,y分開寫會比較好，不要寫在同一個always
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        x_cnt<=0;
        y_cnt<=0;
        in_cnt<=0;
        kernal_xcnt<=0;
        kernal_ycnt<=0;
        F_xcnt<=0;
        F_ycnt<=0;
        x<=0;
        y<=0;
        out_x<=0;
        out_y<=0;
    end else if (next_state==IDLE) begin 
        in_cnt<=0;
        Feature_map[3][3]<=0;
        x_cnt<=0;
        y_cnt<=0;
        kernal_xcnt<=0;
        kernal_ycnt<=0;
        F_xcnt<=0;
        F_ycnt<=0;
        x<=0;
        y<=0;
        out_x<=0;
        out_y<=0;
    end else if (next_state==READ) begin
        in_cnt<=in_cnt+1;
        if(in_cnt==0)begin
            x_cnt<=x_cnt+1;
            current_opt=opt;
        end else if (in_cnt < 6'd36) begin
            if(x_cnt==3'd5)begin
                x_cnt <= 3'd0;
                if(y_cnt==3'd5)begin
                    y_cnt<=3'd0;
                end else begin
                    y_cnt<=y_cnt+1;
                end
            end else begin
                x_cnt<=x_cnt+1;
            end
        end else begin
            if(kernal_xcnt==3'd2)begin
                kernal_xcnt<=3'd0;
                if(kernal_ycnt==3'd2)begin
                    kernal_ycnt<=0;
                end else begin
                    kernal_ycnt<=kernal_ycnt+1;
                end
            end else begin
                kernal_xcnt<=kernal_xcnt+1;
            end
        end
    end else if (current_state==CALC) begin
        if(x_cnt==3'd2)begin
            x_cnt<=0;
            if(y_cnt==3'd2)begin
                y_cnt<=0;
                if(x==3'd3)begin
                    x<=0;
                    if(y==3'd3)begin
                        y<=0;
                    end else begin
                        y<=y+1;
                    end
                end else begin
                    x<=x+1;
                end
            end else begin
                y_cnt<=y_cnt+1;
            end
        end else begin
            x_cnt<=x_cnt+1;
        end
    end else if(current_state==MaxP) begin
        if(x_cnt==3'd1)begin
            x_cnt<=0;
            if(y_cnt==3'd1)begin
                y_cnt<=0;
                if(x==3'd2)begin
                    x<=0;
                    out_x<=0;
                    if(y==3'd2)begin
                        y<=0;
                        out_y<=0;
                    end else begin
                        y<=3'd2;
                        out_y<=1;
                    end
                end else begin
                    x<=3'd2;
                    out_x<=1;
                end
            end else begin
                y_cnt<=y_cnt+1;
            end
        end else begin
            x_cnt<=x_cnt+1;
        end
    end else if(current_state==OUT) begin
        if(out_x==3'd1)begin
            out_x<=0;
            if(out_y==3'd1)begin
                out_y<=0;
                end else begin
                out_y<=out_y+1;
                end
        end else begin
            out_x<=out_x+1;
        end
    end else begin
        out_cnt<=out_cnt;
    end
end
////execute////feature
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        current_map<=0;
        RELU_cnt<=0;
        for (i = 0; i <= 3; i = i + 1) begin
            for (j = 0; j <= 3; j = j + 1) begin
                RELU_map[i][j] <= 8'd0;
            end
        end
    end else if (current_state==IDLE)begin
        RELU_cnt<=0;
    end else if(current_state==CALC)begin
        if(x_cnt==3'd2&&y_cnt==3'd2)begin
            current_map<=0;
            Feature_map[x][y]<=current_map+image_buffer[x+x_cnt][y+y_cnt]*kernal_buffer[x_cnt][y_cnt];
            if(current_map+image_buffer[x+x_cnt][y+y_cnt]*kernal_buffer[x_cnt][y_cnt]<0)begin
                if(current_opt==0)begin
                    RELU_map[x][y]<=0;
                    RELU_cnt<=RELU_cnt+1;
                end else begin
                    RELU_map[x][y]<=current_map+image_buffer[x+x_cnt][y+y_cnt]*kernal_buffer[x_cnt][y_cnt];
                    RELU_cnt<=RELU_cnt+1; 
                end
            end else begin
                RELU_map[x][y]<=current_map+image_buffer[x+x_cnt][y+y_cnt]*kernal_buffer[x_cnt][y_cnt]; 
                RELU_cnt<=RELU_cnt+1;
            end
        end else begin
            current_map<=current_map+image_buffer[x+x_cnt][y+y_cnt]*kernal_buffer[x_cnt][y_cnt];
        end
    end else begin
        current_map<=0;
    end
end
/////////////////////////

////MaxP////
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        for (i = 0; i <= 1; i = i + 1) begin
            for (j = 0; j <= 1; j = j + 1) begin
                Maxp_map[i][j] <= 8'd0;
            end
        end
    end else if (next_state==MaxP||current_state==MaxP) begin
        if(x_cnt==3'd1&&y_cnt==3'd1)begin
            current_map1<=0;
            if(current_map1<RELU_map[x+x_cnt][y+y_cnt])begin
                Maxp_map[out_x][out_y]<=RELU_map[x+x_cnt][y+y_cnt];
            end else begin
                Maxp_map[out_x][out_y]<=current_map1;
            end
        end else if(x_cnt==0&&y_cnt==0) begin
            current_map1<=RELU_map[x+x_cnt][y+y_cnt];
        end else begin
            if(current_map1<RELU_map[x+x_cnt][y+y_cnt])begin
                current_map1<=RELU_map[x+x_cnt][y+y_cnt];
            end else begin
                current_map1<=current_map1;
            end
        end
    end else begin
        current_map1<=current_map1;
    end
end


        



////////////

///// Image Input /////

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i <= 5; i = i + 1) begin
            for (j = 0; j <= 5; j = j + 1) begin
                image_buffer[i][j] <= 8'd0;
            end
        end
        for (i = 0; i <= 3; i = i + 1) begin
            for (j = 0; j <= 3; j = j + 1) begin
                Feature_map[i][j] <= 8'd0;
            end
        end
    end else if (next_state == READ) begin
        if(in_cnt>=6'd36)begin
            kernal_buffer[kernal_xcnt][kernal_ycnt] <= in_data;
        end else begin
            image_buffer[x_cnt][y_cnt] <= in_data;
        end
    end else begin
        image_buffer[x_cnt][y_cnt] <= image_buffer[x_cnt][y_cnt];
    end
end
///////////////////////

///// Image Output /////
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_data <= 16'd0;
        out_valid<= 1'd0;
    end else if (current_state == OUT) begin
        out_data <= Maxp_map[out_x][out_y];
        out_valid<= 1'd1;
    end else begin
        out_valid<=0;
        out_data<=0;
    end
end
////////////////////////



endmodule
