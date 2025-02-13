//==============================================//
//           Top CPU Module Declaration         //
//==============================================//
module CPU(
    // Input Ports
    clk,
    rst_n,
    data_read,
    instruction,
    // Output Ports
    data_wen,
    data_addr,
    inst_addr,
    data_write
);

    input clk;
    input rst_n;
    input [31:0] instruction;
    input [31:0] data_read;
    output reg data_wen;
    output reg [31:0] data_addr;
    output reg [31:0] inst_addr;
    output reg [31:0] data_write;

    // 寄存器和內部變量
    reg [31:0] pc;
    reg signed [31:0] reg_file [0:31];
    reg [31:0] cnt;

    reg [31:0] IF_ID_pc;
    reg [31:0] IF_ID_instr;
    reg [31:0] ID_EX_instr;
    reg [31:0] EX_MEM_instr;

    reg [31:0] ID_EX_pc;
    reg [31:0] ID_EX_reg_data2;
    wire [31:0] ID_EX_sign_ext_imm= {{16{ID_EX_instr[15]}}, ID_EX_instr[15:0]};
    wire [5:0] ID_EX_opcode=ID_EX_instr[31:26];//check
    wire [4:0] ID_EX_rs=ID_EX_instr[25:21];
    wire [4:0] ID_EX_rt=ID_EX_instr[20:16];
    wire [4:0] ID_EX_rd=ID_EX_instr[15:11];
    wire [5:0] ID_EX_funct=ID_EX_instr[5:0];
    wire[25:0] ID_EX_address=ID_EX_instr[25:0];

    reg [31:0] EX_MEM_alu_result;
    reg [31:0] EX_MEM_pc;
    reg [31:0] EX_MEM_reg_data2;
    wire [31:0] EX_MEM_sign_ext_imm = {{16{EX_MEM_instr[15]}}, EX_MEM_instr[15:0]};;
    wire [5:0] EX_MEM_opcode=EX_MEM_instr[31:26];
    wire [4:0] EX_MEM_rd=EX_MEM_instr[15:11];
    wire [4:0] EX_MEM_rt=EX_MEM_instr[20:16];
    reg EX_MEM_zero;

    // 初始化
    integer i;

//beq不馬上跳會多跑兩個instruction
    //pc count
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            pc<=0;
        else begin
            if(instruction[31:26]==6'b000010)
                pc <= {2'b00, pc[31:28],instruction[25:0]};
            else begin
                if(cnt>='d1)begin 
                    case (ID_EX_opcode)
                        6'b000100: pc <= (EX_MEM_zero ? pc + 1 + ID_EX_sign_ext_imm-2  : pc + 1); // beq
                        default:pc <= pc + 1;
                    endcase
                end else begin
                    pc<=pc;
                end
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            cnt<=0;
        else begin 
            cnt<=cnt+1;
        end
    end

    always @(*) begin
        inst_addr = pc;
    end

    //（IF）
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            IF_ID_pc <= 0;
            IF_ID_instr<=0;
        end else begin
            IF_ID_instr <= instruction;
            IF_ID_pc <= pc;
        end
    end


    //（ID）
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ID_EX_pc <= 0;
            ID_EX_reg_data2 <= 0;
            ID_EX_instr<=0;
        end else begin
            ID_EX_pc <= IF_ID_pc;
            ID_EX_reg_data2 <= reg_file[IF_ID_instr[20:16]];//rt
            ID_EX_instr<=IF_ID_instr;
        end
    end

    always@(posedge clk or negedge rst_n)begin
        if (!rst_n) begin
            EX_MEM_instr<=0;
        end else begin
            EX_MEM_instr<=ID_EX_instr;
        end
    end

    always@(*)begin
        EX_MEM_zero = ((reg_file[ID_EX_rs] - reg_file[ID_EX_rt]) == 0);
    end

    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            EX_MEM_alu_result<=0;
        end else begin
            case(ID_EX_opcode)
                6'b000000: begin // R型指令
                    case (ID_EX_funct)
                        6'b100000: EX_MEM_alu_result <= reg_file[ID_EX_rs] + reg_file[ID_EX_rt]; // add
                        6'b101010: EX_MEM_alu_result <= (reg_file[ID_EX_rs] < reg_file[ID_EX_rt]) ? 1 : 0; // slt
                        default: EX_MEM_alu_result <= EX_MEM_alu_result;
                    endcase
                end
                6'b001000: EX_MEM_alu_result <= reg_file[ID_EX_rs] + ID_EX_sign_ext_imm; // addi
                6'b100011: EX_MEM_alu_result <= reg_file[ID_EX_rs] + ID_EX_sign_ext_imm; // lw
                6'b101011: EX_MEM_alu_result <= reg_file[ID_EX_rs] + ID_EX_sign_ext_imm; // sw
                6'b000100: EX_MEM_alu_result <= reg_file[ID_EX_rs] - reg_file[ID_EX_rt]; // beq
                6'b000010: EX_MEM_alu_result <= {2'b00, pc[31:28], ID_EX_address}; // j
                default: EX_MEM_alu_result <= EX_MEM_alu_result;
            endcase
        end
    end

    //（MEM）
    always@(*)begin
        data_addr = EX_MEM_alu_result;  
        case (EX_MEM_opcode)
            6'b101011: data_wen = 1; //sw
            default: data_wen = 0;
        endcase
    end

    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            data_write <= 0;
        end else begin
            data_write <= ID_EX_reg_data2;  
        end
    end



    //（WB）
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1) begin
                reg_file[i] <= 0;
            end
        end else begin
            if(EX_MEM_instr!='d0)begin
                case (EX_MEM_opcode)
                    6'b000000: reg_file[EX_MEM_rd] <= EX_MEM_alu_result; // R型指令
                    6'b001000: reg_file[EX_MEM_rt] <= EX_MEM_alu_result; // addi
                    6'b100011: reg_file[EX_MEM_rt] <= data_read; // lw
                    default:begin
                        for (i = 0; i < 32; i = i + 1) begin
                            reg_file[i] <= reg_file[i] ;
                        end
                    end
                endcase
            end else begin
                for (i = 0; i < 32; i = i + 1) begin
                    reg_file[i] <= reg_file[i] ;
                end
            end
        end
    end

endmodule
