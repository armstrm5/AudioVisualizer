module FFTDisplay
(
	input CLOCK_50,
	input AUD_ADCDAT,
	input AUD_ADCLRCK,
	input AUD_XCK,
	
	output AUD_BLCK,
	inout I2C_SCLK,
	inout I2C_SDAT,
	input [3:0] KEY,
	output [8:0] LEDG,
	output [17:0] LEDR,
	input [17:0] SW,
	output [7:0] VGA_R,
	output [7:0] VGA_G,
	output [7:0] VGA_B,
	output VGA_BLANK_N,
	output VGA_SYNC_N,
	output VGA_CLK,
	output VGA_HS,
	output VGA_VS
);

	localparam MIC_WORD_SIZE = 16;
	localparam FILTER_WORD_SIZE = 18;

	wire signed [MIC_WORD_SIZE-1:0] micData, leftData, rightData, fftInData;
	wire [FILTER_WORD_SIZE-1:0] filterInData, filterOutData;
	wire [MIC_WORD_SIZE-1:0] fftInDataAbs, fftOutData;
	wire configReady, i2cClock, codecClock, sampleRate, filterClock, reset;
	wire [25:0] LEDS;
	wire [9:0] fftSampleNumber;
	
	assign reset = ~KEY[0];
	assign AUD_XCK = codecClock;
	assign {LEDR, LEDG[7:0]} = LEDS;
	
	assign LEDS = ~(26'h3FF_FFFF << fftInDataAbs[9:5]);
	assign filterInData = $signed(micData);
	assign fftInData = SW[17] ? micData : filterOutData[MIC_WORD_SIZE-1:0];
	assign micData = SW[16] ? leftData : rightData;
	assign fftInDataAbs = (fftInData[MIC_WORD_SIZE-1] ? -fftInData : fftInData);
	
	
	//COnfigure CLocks
	
	ClockDivider #(.DIVIDER(500))  cd0(.reset(reset), .inClock(CLOCK_50), .outClock(i2cClock));
	ClockDivider #(.DIVIDER(4))    cd1(.reset(reset), .inClock(CLOCK_50), .outClock(codecClock));
	ClockDivider #(.DIVIDER(256))  cd2(.reset(reset), .inClock(CLOCK_50), .outClock(filterClock));
	ClockDivider #(.DIVIDER(1024)) cd3(.reset(reset), .inClock(CLOCK_50), .outClock(sampleRate));
	
	
	//INstatiate modules
	Codec cc0
	(
		.reset(reset),
		.inClock(i2cClock),
		.sda(I2C_SDAT),
		.scl(I2C_SCLK),
		.ready(configReady)
		//.ackNum(LEDS[3:0])
	);
	
	I2S #(.wordSize(MIC_WORD_SIZE)) i2sr0 
	(
		.reset(~configReady), 		// Disable receiver while codec is configuring
		.codecBitClock(AUD_BCLK),
		.codecLRClock(AUD_ADCLRCK),
		.codecData(AUD_ADCDAT),
		.outDataLeft(leftData),
		.outDataRight(rightData)
 	);
	
	VGAGenerator vgag0
	(
		.reset(~configReady),
		.inClock(CLOCK_50),
		.rColor(VGA_R),
		.gColor(VGA_G),
		.bColor(VGA_B),
		.hSync(VGA_HS),
		.pixelClock(VGA_CLK),
		.vSync(VGA_VS),
		.blankN(VGA_BLANK_N),
		.syncN(VGA_SYNC_N),
		.bgColor(SW[2:0]),
		.vramWriteClock(sampleRate),
		.vramWriteAddr(fftSampleNumber),
		.vramInData(fftOutData)
	);
	
	IirFilter iirf0
	(
		.reset(~configReady),
		.inClock(filterClock),
		.inData(filterInData),
		.outData(filterOutData)
	);
	
	
	
	FFT #(.wordSize(MIC_WORD_SIZE)) fft0
	(
		.reset(~configReady),
		.inClock(sampleRate),
		.sampleNumber(fftSampleNumber),
		.inData(fftInData),
		.outData(fftOutData)
	);
	
endmodule
