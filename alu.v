module alu(
	input [31:0] l_in,
	input [31:0] r_in,
	input [4:0] control,
	output [31:0] result
);

always@(*)
begin
	case (control)
	begin
		5'd0: result = l_in + r_in; // Addition
		5'd1: result = l_in - r_in; // Subtraction
		5'd2: result = l_in & r_in; // Bitwise AND
		5'd3: result = l_in | r_in; // Bitwise OR
		5'd4: result = l_in ^ r_in; // Bitwise XOR
		5'd5: // Signed less than
		begin
			case ({l_in[31], r_in[31])
				2'b00: 
				begin
					if (l_in < r_in)
						result = l_in;
					else
						result = r_in;
				end
				2'b01: result = r_in;
				2'b10: result = l_in;
				2'b11:
				begin
					if (l_in < r_in)
						result = r_in;
					else
						result = l_in;
				end
			endcase
		end
		5'd6: // Unsigned less than
		begin
			if (l_in < r_in)
				result = l_in
			else
				result = r_in
		end
		5'd7: // Shift right (sign extend) (TODO)
		5'd8: // Shift right (append zeros) (TODO)
		5'd9: // Shift left (append zeros) (TODO)
		5'd10: // Signed multiplication (TODO)
		5'd11: // Load constant into upper bits of a word (TODO)
		5'd12: // Check equal
		begin
			result[31:1] = 31'b0;
			if (l_in == r_in)
				result[0] = 1'b1;
			else
				result[0] = 1'b0;
		end
		5'd13: // Check not equal
		begin
			result[31:1] = 31'b0;
			if (l_in == r_in)
				result[0] = 1'b0;
			else
				result[0] = 1'b1;
		end
		5'd14: // Check signed less than
		begin
			result[31:1] = 31'b0;
			case ({l_in[31], r_in[31])
				2'b00: 
				begin
					if (l_in < r_in)
						result[0] = 1'b1;;
					else
						result[0] = 1'b0;
				end
				2'b01: result[0] = 1'b0;
				2'b10: result[0] = 1'b1;
				2'b11:
				begin
					if (l_in < r_in)
						result[0] = 1'b0;
					else
						result[0] = 1'b1;
				end
			endcase
		end
		5'd15: // Check signed greater than or equal
		begin
			result[31:1] = 31'b0;
			case ({l_in[31], r_in[31])
				2'b00: 
				begin
					if (l_in < r_in)
						result[0] = 1'b0;;
					else
						result[0] = 1'b1;
				end
				2'b01: result[0] = 1'b1;
				2'b10: result[0] = 1'b0;
				2'b11:
				begin
					if (l_in < r_in)
						result[0] = 1'b1;
					else
						result[0] = 1'b0;
				end
			endcase
		end
		5'd16: // Check unsigned less than
		begin
			result[31:1] = 31'b0;
			if (l_in < r_in)
				result[0] = 1'b1;
			else
				result[0] = 1'b0;
		end
		5'd17: // Check unsigned greater than or equal
		begin
			result[31:1] = 31'b0;
			if (l_in < r_in)
				result[0] = 1'b0;
			else
				result[0] = 1'b1;
		end
		default: result = 32'd0;
	end
end

endmodule 
