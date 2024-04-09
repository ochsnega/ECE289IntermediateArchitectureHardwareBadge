module intermediateBadgeMain( // TODO
	input clk,
	input rst,
	input start
	
);

// Instantiate memory (Note: This takes a clock cycle)
reg [7:0] mem_address;
reg [31:0] mem_data;
reg mem_wren;
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
reg reg_w_en;
reg [4:0] reg_rl_add;
reg [4:0] reg_rr_add;
wire [31:0] reg_rl_data;
wire [31:0] reg_rr_data;
registerFile my_registers(clk, rst, reg_w_data, reg_w_add, reg_w_en, reg_rl_add, reg_rr_add, reg_rl_data, reg_rr_data);

// FSM states
reg [6:0] S;
reg [6:0] NS;

// Define states of FSM (TODO)
parameter START = 7'd0, // TODO
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

// Choose next state (TODO)
always@(*)
begin
	case (S)
		START: NS = FETCH;
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
		endcase
	end
end

endmodule 