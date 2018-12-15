module Codec
(
	input rst,
	input inclk,
	inout sda,
	inout scl,
	output reg rdy,
	output reg [3:0] ackNum
);

	localparam ADDR = 8'h34;

	reg I2C_clkDisable;
	reg [23:0] data;
	reg [2:0] s;
	wire txReady, ack;
	
	I2CMaster i2cm1
	(
		.reset(reset),
		.inClock(I2C_clkDisable ? 1'b0 : inClock),
		.inData(data),
		.sda(sda),
		.scl(scl),
		.ready(txReady),
		.ack(ack)
	);

	always @(posedge txReady or posedge reset)
	begin
		if (rst)
		begin
			I2C_clkDisable <= 1'b0;
			s <= 1'b0;
			ready <= 1'b0;
			data <= 8'h00;
			ackNum <= 1'b0;
		end
	
		else
		begin
			case(s)	
				
				3'h0: data <= {ADDR, 7'h04, 9'b0_0000_0100};	// Send Analogue Audio Path  reg
				
				3'h1: data <= {ADDR, 7'h07, 9'b0_0100_0010};	// Send Digital Audio Interface reg
				
				3'h2: data <= {ADDR, 7'h09, 9'b0_0000_0001};	// Send Active reg
				
				3'h3: data <= {ADDR, 7'h06, 9'b0_0011_1001};	// Send Power Down reg
				
				3'h4: data <= {ADDR, 7'h00, 9'b0_0001_0111};	// Send Left Line reg
				
				3'h5: data <= {ADDR, 7'h01, 9'b0_0001_0111};	// Send Right Line reg
				
			endcase
			
			if (s == 3'h6)
			begin
				ready <= 1'b1;
				I2C_clkDisable <= 1'b1;
			end
			
			else s <= s + 1'b1;
			ackNum <= ackNum + ack; 
		end
	end

endmodule
