module intermediateBadgeMain( // TODO
	input clk,
	input rst,
	input start,
	input g_control,
	input [4:0] r_control,
	output reg [6:0] g_out,
	output reg [15:0] r_out,
	output reg reg_w_en,
	output reg mem_wren
);

// Instantiate memory (Note: This takes a clock cycle)
reg [7:0] mem_address;
reg [31:0] mem_data;
//reg mem_wren;
wire [31:0] mem_out;
Mem my_mem(mem_address, clk, mem_data, mem_wren, mem_out);

// Instantiate ALU
reg [31:0] alu_l_in;
reg [31:0] alu_r_in;
reg [4:0] alu_control;
wire [31:0] alu_result;
alu my_alu(alu_l_in, alu_r_in, alu_control, alu_result);

// Instantiate register file (Note: This takes a clock cycle!)
reg [31:0] reg_w_data;
reg [4:0] reg_w_add;
//reg reg_w_en;
reg [4:0] reg_rl_add;
reg [4:0] reg_rr_add;
wire [31:0] reg_rl_data;
wire [31:0] reg_rr_data;
registerFile my_registers(clk, rst, reg_w_data, reg_w_add, reg_w_en, reg_rl_add, reg_rr_add, reg_rl_data, reg_rr_data);

// FSM states
reg [6:0] S;
reg [6:0] NS;

// Define states of FSM 
parameter START = 7'd0,
			 FETCH = 7'd1,
			 FETCH_BUF = 7'd2,
			 DECODE = 7'd3,
			 RR_ALU = 7'd4,
			 RI_ALU = 7'd5,
			 LUI_ALU = 7'd6,
			 AUIPC_ALU = 7'd7,
			 LW = 7'd8,
			 SW = 7'd9,
			 JAL = 7'd10,
			 JALR = 7'd11,
			 BR_ALU = 7'd12,
			 GET_REG_RR_ALU = 7'd13,
			 CALC_RR_ALU = 7'd14,
			 STORE_REG_RR_ALU = 7'd15,
			 GET_REG_RI_ALU = 7'd16,
			 CALC_RI_ALU = 7'd17,
			 STORE_REG_RI_ALU = 7'd18,
			 PC_INC = 7'd19,
			 GET_REG_LUI_ALU = 7'd20,
			 CALC_LUI_ALU = 7'd21,
			 STORE_REG_LUI_ALU = 7'd22,
			 GET_REG_AUIPC_ALU = 7'd23,
			 CALC_AUIPC_ALU = 7'd24,
			 STORE_REG_AUIPC_ALU = 7'd25,
			 GET_REG_LW = 7'd26,
			 GET_ADD_LW = 7'd27,
			 GET_WORD_LW = 7'd28,
			 LW_BUFF = 7'd29,
			 GET_REG_SW = 7'd30,
			 GET_ADD_SW = 7'd31,
			 STORE_WORD_SW = 7'd32,
			 SW_BUFF = 7'd33,
			 GET_REG_JAL = 7'd34,
			 CALC_JAL = 7'd35,
			 STORE_REG_JAL = 7'd36,
			 GET_REG_JALR = 7'd37,
			 CALC_JALR = 7'd38,
			 STORE_REG_JALR = 7'd39,
			 GET_REG_BR_ALU = 7'd40,
			 CALC_BR_ALU = 7'd41,
			 DECIDE_BR = 7'd42,
			 ERROR = 7'b1111111;
			 
// Define program counter/instruction register:
reg [7:0] PC;
reg [31:0] IR;
			 
// Move to next state
always@(posedge clk or negedge rst)
begin
	if (rst == 1'b0)
		S <= START;
	else
		S <= NS;
end

// Choose next state
always@(*)
begin
	case (S)
		START:
		begin
			if (start == 1'b1)
			begin
				NS = FETCH;
			end
			else
			begin
				NS = START;
			end
		end
		FETCH: NS = FETCH_BUF;
		FETCH_BUF: NS = DECODE;
		DECODE:
		begin
		case (IR[6:0])
			7'b0110011: NS = RR_ALU;
			7'b0010011: NS = RI_ALU;
			7'b0110111: NS = LUI_ALU;
			7'b0010111: NS = AUIPC_ALU;
			7'b0000011: NS = LW;
			7'b0100111: NS = SW;
			7'b1101111: NS = JAL;
			7'b1100111: NS = JALR;
			7'b1100011: NS = BR_ALU;
			default: NS = ERROR;
		endcase
		end
		RR_ALU: NS = GET_REG_RR_ALU; // Register-Register ALU Instructions
		GET_REG_RR_ALU: NS = CALC_RR_ALU;
		CALC_RR_ALU: NS = STORE_REG_RR_ALU;
		STORE_REG_RR_ALU: NS = PC_INC;
		RI_ALU: NS = GET_REG_RI_ALU; // Register-Imediate ALU Instructions
		GET_REG_RI_ALU: NS = CALC_RI_ALU;
		CALC_RI_ALU: NS = STORE_REG_RI_ALU;
		STORE_REG_RI_ALU: NS = PC_INC;
		LUI_ALU: NS = GET_REG_LUI_ALU; // LUI ALU Instruction
		GET_REG_LUI_ALU: NS = CALC_LUI_ALU;
		CALC_LUI_ALU: NS = STORE_REG_LUI_ALU;
		STORE_REG_LUI_ALU: NS = PC_INC;
		AUIPC_ALU: NS = GET_REG_AUIPC_ALU; // AUIPC ALU Instruction
		GET_REG_AUIPC_ALU: NS = CALC_AUIPC_ALU;
		CALC_AUIPC_ALU: NS = STORE_REG_AUIPC_ALU; 
		STORE_REG_AUIPC_ALU: NS = PC_INC;
		LW: NS = GET_REG_LW; // LW Instruction
		GET_REG_LW: NS = GET_ADD_LW;
		GET_ADD_LW: NS = GET_WORD_LW;
		GET_WORD_LW: NS = LW_BUFF;
		LW_BUFF: NS = PC_INC;
		SW: NS = GET_REG_SW; // SW Instruction
		GET_REG_SW: NS = GET_ADD_SW;
		GET_ADD_SW: NS = STORE_WORD_SW;
		STORE_WORD_SW: NS = SW_BUFF;
		SW_BUFF: NS = PC_INC;
		JAL: NS = GET_REG_JAL; // JAL Instruction
		GET_REG_JAL: NS = CALC_JAL; 
		CALC_JAL: NS = STORE_REG_JAL; // Note this state changes the PC, so no need to go to a PC changing state.
		STORE_REG_JAL: NS = FETCH;
		JALR: NS = GET_REG_JALR; // JALR Instruction
		GET_REG_JALR: NS = CALC_JALR;
		CALC_JALR: NS = STORE_REG_JALR; // Note this state changes the PC, so no need to go to a PC changing state.
		STORE_REG_JALR: NS = FETCH;
		BR_ALU: NS = GET_REG_BR_ALU; // Branch ALU Instructions
		GET_REG_BR_ALU: NS = CALC_BR_ALU;
		CALC_BR_ALU: NS = DECIDE_BR;
		DECIDE_BR: NS = FETCH;
		PC_INC: NS = FETCH; // Increment PC
		ERROR: NS = ERROR;
		default: NS = ERROR; // Catch Errors
	endcase
end

// What happens in each state (TODO)
always@(posedge clk or negedge rst)
begin
	if (rst == 1'b0) // Reset variables (TODO)
	begin
		PC <= 8'b0;
		IR <= 32'b0;
		mem_address <= 8'b0;
		mem_data <= 32'b0;
		mem_wren <= 1'b0;
		alu_l_in <= 32'b0;
		alu_r_in <= 32'b0;
		alu_control <= 5'b0;
		reg_w_data <= 32'b0;
		reg_w_add <= 5'b0;
		reg_w_en <= 1'b0;
		reg_rl_add <= 5'b0;
		reg_rr_add <= 5'b0;
	end
	else
	begin
	case (S) // Change variables for each state (TODO)
		FETCH: 
		begin
			mem_address <= PC;
			mem_wren <= 1'b0;
			IR <= mem_out;
		end
		FETCH_BUF:
		begin
			IR <= mem_out;
		end
		PC_INC:
		begin
			reg_w_en <= 1'b0;
			mem_wren <= 1'b0;
			PC <= PC + 1'b1;
		end
		RR_ALU: // Register-Register ALU Instructions
		begin
		case (IR[14:12])
			3'b000: 
			begin
			case (IR[31:25])
				7'b0000000: alu_control <= 5'd0;
				7'b0100000: alu_control <= 5'd1;
				7'b0000001: alu_control <= 5'd10;
				default: alu_control <= 5'd31;
			endcase
			end
			3'b001: alu_control <= 5'd9;
			3'b010: alu_control <= 5'd5;
			3'b011: alu_control <= 5'd6;
			3'b100: alu_control <= 5'd4;
			3'b101:
			begin
			case (IR[31:25])
				7'b0100000: alu_control <= 5'd7;
				7'b0000000: alu_control <= 5'd8;
				default: alu_control <= 5'd31;
			endcase
			end
			3'b110: alu_control <= 3;
			3'b111: alu_control <= 2;
		endcase
		end
		GET_REG_RR_ALU:
		begin
			reg_rl_add <= IR[19:15];
			reg_rr_add <= IR[24:20];
		end
		CALC_RR_ALU:
		begin
			alu_l_in <= reg_rl_data;
			alu_r_in <= reg_rr_data;
			reg_w_data <= alu_result;
		end
		STORE_REG_RR_ALU:
		begin
			reg_w_data <= alu_result;
			reg_w_add <= IR[11:7];
			reg_w_en <= 1'b1;
		end
		RI_ALU: // Register-Immediate ALU Instructions
		begin
		case (IR[14:12])
			3'b000: alu_control <= 5'd0;
			3'b001: alu_control <= 5'd9;
			3'b010: alu_control <= 5'd5;
			3'b011: alu_control <= 5'd6;
			3'b100: alu_control <= 5'd4;
			3'b101:
			begin
			case (IR[31:25])
				7'b0100000: alu_control <= 5'd7;
				7'b0000000: alu_control <= 5'd8;
				default: alu_control <= 5'd31;
			endcase
			end
			3'b110: alu_control <= 5'd3;
			3'b111: alu_control <= 5'd2;
		endcase
		end
		GET_REG_RI_ALU:
		begin
			reg_rl_add <= IR[19:15];
		case (IR[31])
			1'b0: alu_r_in <= {20'h0, IR[31:20]};
			1'b1: alu_r_in <= {20'hfffff, IR[31:20]};
		endcase
		end
		CALC_RI_ALU:
		begin
			alu_l_in <= reg_rl_data;
			reg_w_data <= alu_result;
		end
		STORE_REG_RI_ALU:
		begin
			reg_w_data <= alu_result;
			reg_w_add <= IR[11:7];
			reg_w_en <= 1'b1;
		end
		LUI_ALU: alu_control <= 5'd11; // LUI ALU Instruction
		CALC_LUI_ALU:
		begin
			alu_r_in <= {12'b0, IR[31:12]};
			reg_w_data <= alu_result;
		end
		STORE_REG_LUI_ALU:
		begin
			reg_w_data <= alu_result;
			reg_w_add <= IR[11:7];
			reg_w_en <= 1'b1;
		end
		AUIPC_ALU: alu_control <= 5'd11; // AUIPC ALU Instruction
		CALC_AUIPC_ALU:
		begin
			alu_r_in <= {12'b0, IR[31:12]};
			reg_w_data <= alu_result + PC;
		end
		STORE_REG_AUIPC_ALU:
		begin
			reg_w_data <= alu_result + PC;
			reg_w_add <= IR[11:7];
			reg_w_en <= 1'b1;
		end
		LW: // Load Word Instruction
		begin
			reg_rl_add <= IR[19:15];
		case (IR[31])
			1'b0: mem_address <= {reg_rl_data[31], reg_rl_data[6:0]} + {1'b0, IR[26:25], IR[11:7]};
			1'b1: mem_address <= {reg_rl_data[31], reg_rl_data[6:0]} + {1'b1, IR[26:25], IR[11:7]};
		endcase
		end
		GET_REG_LW:
		begin
		case (IR[31])
			1'b0: mem_address <= {reg_rl_data[31], reg_rl_data[6:0]} + {1'b0, IR[26:25], IR[11:7]};
			1'b1: mem_address <= {reg_rl_data[31], reg_rl_data[6:0]} + {1'b1, IR[26:25], IR[11:7]};
		endcase
		end
		GET_ADD_LW:
		begin
		case (IR[31])
			1'b0: mem_address <= {reg_rl_data[31], reg_rl_data[6:0]} + {1'b0, IR[26:25], IR[11:7]};
			1'b1: mem_address <= {reg_rl_data[31], reg_rl_data[6:0]} + {1'b1, IR[26:25], IR[11:7]};
		endcase
			reg_w_data <= mem_out;
		end
		GET_WORD_LW:
		begin
			reg_w_data <= mem_out;
			reg_w_en <= 1'b1;
			reg_w_add <= IR[11:7];
		end
		LW_BUFF: 
		begin
			reg_w_en <= 1'b0;
		end
		SW: // Store Word Instruction
		begin
			reg_rl_add <= IR[19:15]; // Mem address
			reg_rr_add <= IR[24:20]; // Mem data
		end
		GET_REG_SW: 
		begin
		case (IR[31])
			1'b0: mem_address <= {reg_rl_data[31], reg_rl_data[6:0]} + {1'b0, IR[26:25], IR[11:7]};
			1'b1: mem_address <= {reg_rl_data[31], reg_rl_data[6:0]} + {1'b1, IR[26:25], IR[11:7]};
		endcase
		end
		GET_ADD_SW:
		begin
		case (IR[31])
			1'b0: mem_address <= {reg_rl_data[31], reg_rl_data[6:0]} + {1'b0, IR[26:25], IR[11:7]};
			1'b1: mem_address <= {reg_rl_data[31], reg_rl_data[6:0]} + {1'b1, IR[26:25], IR[11:7]};
		endcase
			mem_data <= reg_rr_data;
		end
		STORE_WORD_SW:
		begin
			mem_wren <= 1'b1;
		end
		SW_BUFF:
		begin
			mem_wren <= 1'b0;
		end
		JAL: // JAL Instruction
		begin
			reg_w_data <= {24'b0, PC + 8'd4};
			reg_w_add <= IR[11:7];
			reg_w_en <= 1'b1;
		end
		GET_REG_JAL:
		begin
			PC <= PC + {IR[31], IR[18:12]};
			reg_w_en <= 1'b0;
		end
		JALR: // JALR Instruction
		begin
			reg_w_data <= {24'b0, PC + 8'd4};
			reg_w_add <= IR[11:7];
			reg_w_en <= 1'b1;
			reg_rl_add <= IR[19:15];
		end
		GET_REG_JALR:
		begin
			reg_w_en <= 1'b0;
			PC <= ({reg_rl_data[31], reg_rl_data[6:0]} + {IR[31], IR[26:20]}) & 8'hfe;
		end
		BR_ALU:
		begin
		case (IR[14:12])
			3'b000: alu_control <= 5'd12;
			3'b001: alu_control <= 5'd13;
			3'b100: alu_control <= 5'd14;
			3'b101: alu_control <= 5'd15;
			3'b110: alu_control <= 5'd16;
			3'b111: alu_control <= 5'd17;
			default: alu_control <= 5'd31;
		endcase
			reg_rl_add <= IR[19:15];
			reg_rr_add <= IR[24:20];
		end
		GET_REG_BR_ALU:
		begin
			reg_rl_add <= IR[19:15];
			reg_rr_add <= IR[24:20];
			alu_l_in <= reg_rl_data;
			alu_r_in <= reg_rr_data;
		end
		CALC_BR_ALU:
		begin
			alu_l_in <= reg_rl_data;
			alu_r_in <= reg_rr_data;
		end
		DECIDE_BR:
		begin
			if (alu_result[0] == 1'b1)
			begin
				PC <= PC + {IR[31], IR[26:25], IR[11:7]};
			end
			else
			begin
				PC <= PC + 8'd4;
			end
		end
		ERROR: alu_control <= 5'd20;
		default:
		begin
			PC <= 8'b0;
			IR <= 32'b0;
			mem_address <= 8'b0;
			mem_data <= 32'b0;
			mem_wren <= 1'b0;
			alu_l_in <= 32'b0;
			alu_r_in <= 32'b0;
			alu_control <= 5'b0;
			reg_w_data <= 32'b0;
			reg_w_add <= 5'b0;
			reg_w_en <= 1'b0;
			reg_rl_add <= 5'b0;
			reg_rr_add <= 5'b0;
		end
	endcase
	end
end


// Input/output handling (multiplexor for showing state of system/each signal)
// Green LED
always@(*)
begin
	if (g_control == 1'b1)
	begin
		g_out = S;
	end
	else
	begin
		g_out = NS;
	end
end

// Red LED
always@(*)
begin
case (r_control)
	5'b00000: r_out = IR[31:16];
	5'b00001: r_out = IR[15:0];
	5'b00010: r_out = {8'b0, PC};
	5'b00011: r_out = {8'b0, mem_address};
	5'b00100: r_out = mem_data[31:16];
	5'b00101: r_out = mem_data[15:0];
	5'b00110: r_out = mem_out[31:16];
	5'b00111: r_out = mem_out[15:0];
	5'b01000: r_out = alu_l_in[31:16];
	5'b01001: r_out = alu_l_in[15:0];
	5'b01010: r_out = alu_r_in[31:16];
	5'b01011: r_out = alu_r_in[15:0];
	5'b01100: r_out = alu_result[31:16];
	5'b01101: r_out = alu_result[15:0];
	5'b01110: r_out = {11'b0, alu_control};
	5'b01111: r_out = {11'b0, reg_w_add};
	5'b10000: r_out = reg_w_data[31:16];
	5'b10001: r_out = reg_w_data[15:0];
	5'b10010: r_out = {11'b0, reg_rl_add};
	5'b10011: r_out = {11'b0, reg_rr_add};
	5'b10100: r_out = reg_rl_data[31:16];
	5'b10101: r_out = reg_rl_data[15:0];
	5'b10110: r_out = reg_rr_data[31:16];
	5'b10111: r_out = reg_rr_data[15:0];
	default: r_out = 16'b0;
endcase
end



endmodule 