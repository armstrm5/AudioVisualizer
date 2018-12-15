module I2C_Logic
(
	input rst,
	input en,
	input inClock,
	input [7:0] inData,
	input [1:0] mode,
		 
	inout sda,
	inout scl,

	output reg ack,
	output reg ready
);

	reg SDApull, SCLpull;
	reg [3:0] s;
	reg [1:0] bitState;

	assign sda = SDApull ? 1'b0 : 1'bz;
	assign scl = SCLpull ? 1'b0 : 1'bz;

	always @(posedge reset or posedge inClock)
	begin
		if (reset)
		begin
			s = 1'b0;
			ack <= 1'b0;
			ready <= 1'b0;
			bitState <= 1'b0;
			SCLpull <= 1'b0;
			SDApull <= 1'b0;
		end
		
		else
		begin
			case(mode)
				// Start 
				0: begin 
					case(s)
						0: begin
							SCLpull <= 1'b0;
							ready <= 1'b0;
						end
						
						1: SDApull <= 1'b1;

						2: begin
							SCLpull <= 1'b1;
							ready <= 1'b1;
						end
					endcase
					
					if (s == 2'd2) 
						s <= 1'b0;
					else 
						s <= s + 1'b1;
				end
				
				1: begin
				
					// First cycle
				if (s == 4'd0 && bitState == 2'd0)
					begin
						ready <= 1'b0;
						ack <= 1'b0;
					end
				
				//if we send bits
					if (state != 4'd8)
					begin
						case(bitState)
			0: SDApull <= ~(inData >> (3'd7 - state));
							
			1: SCLpull <= 1'b0;	
							
			3: begin
				SCLpull <= 1'b1;
				state <= state + 1'b1;
				end
			endcase
			end
					
			// If Ack is recieved
			else
				begin
				case(bitState)											0: SDApull <= 1'b0;
							
					1: SCLpull <= 1'b0;
						
					2: ack <= ~sda;
							
					3: begin												SCLpull <= 1'b1;
						state <= 1'b0;
						ready <= 1'b1;
							
					end
						
				endcase
						
			end
					
			bitState <= bitState + 1'b1;
				end

				// Stop
				2: begin
					case(state)
						0: begin
							SDApull <= 1'b1;
							ready <= 1'b0;
						end
						
						1: SCLpull <= 1'b0;

						2: begin
							SDApull <= 1'b0;
							ready <= 1'b1;
						end
					endcase
					
					if (s == 2'd2) s <= 1'b0;
					else
					 s <= s + 1'b1;
				end
			endcase
		end
	end			
endmodule
