module I2CMaster
(
	input rst,
	input inClock,
	input [23:0] inData,
	inout sda,
	inout scl,
	output reg ack, 		//returns 1 when data is recieved
	output reg rdy
);

	reg [1:0] txState, bytesCounter, ackNum;
	reg [7:0] txData;
	wire txReady, txAck;
	
	always @*
	begin
		case(bytesCounter)
			0: txData <= inData[23:16];	
			
			1: txData <= inData[15:8];
			
			2: txData <= inData[7:0];
			
			default: txData <= 1'b0;
			
		endcase
	end
	
	always @(posedge reset or posedge txReady)
	begin
		if (rst)
		begin
			txState <= 1'b0;
			bytesCounter <= 1'b0;
			ready <= 1'b0;
			ackNum <= 1'b0;
			ack <= 1'b0;
		end
		
		else
		begin
			case(txState)
				0: begin
					txState <= 2'd1;
					ready <= 1'b1;
					ackNum <= 1'b0;
				end
				
				1: begin
					if (bytesCounter == 2'd2)
					begin
						bytesCounter <= 1'b0;
						txState <= 2'd2;
					end
					
					else bytesCounter <= bytesCounter + 1'b1;
					ackNum = ackNum + txAck;
					ack <= (ackNum == 2'd3);
				end
				
				2: begin
					txState <= 2'd0;
					ready <= 1'b0;
				end
			endcase
		end
	end
	
	I2C_Logic txLogic
	(
		.rst(rst),
		.inClock(inClock),
		.inData(txData),
		.mode(txState),
		.sda(sda),
		.scl(scl),
		.ack(txAck),
		.ready(txReady)
	);

endmodule
