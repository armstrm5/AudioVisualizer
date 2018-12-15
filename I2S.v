module I2S #(wordSize = 16)
(
	input rst,
	input codecBitClock,
	input codecLRClock,
	input codecData,
	
	output reg dataReady,
	output reg [wordSize-1:0] outDataLeft,
	output reg [wordSize-1:0] outDataRight
);

	localparam buffSize = 32;

	reg oldRLClock;
	reg [buffSize-1:0] buffer;
	
	wire [buffSize-1:0] nextBuffer;
	
	assign nextBuffer = {buffer[buffSize-2:0], codecData};
	
	always @(posedge reset or posedge codecBitClock)
	begin
		if (reset)
		begin
			outDataLeft <= 1'b0;
			outDataRight <= 1'b0;
			oldRLClock <= codecLRClock;
			dataReady <= 1'b0;
		end
		
		else
		begin
			buffer <= nextBuffer;
			oldRLClock <= codecLRClock;
			
			if (codecLRClock != oldRLClock)
			begin
				if (oldRLClock)
				begin
					outDataLeft <= nextBuffer[buffSize-1:buffSize-wordSize-2];
					
					dataRdy <= 1'b0;
					
				end
				
				else
				begin
					outDataRight <= nextBuffer[buffSize-1:buffSize-wordSize-2];
					
					dataRdy <= 1'b1;
					
				end
			end
		end
	end

endmodule
