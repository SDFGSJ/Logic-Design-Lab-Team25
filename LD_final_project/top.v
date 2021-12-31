module top(
    input clk,
    input rst,      // BTNC
    input play,     // BTNU: play/pause
    input speedup,  // BTNR
    input speeddown,// BTNL
    input loop, //temp loop effect
    inout PS2_DATA,
    inout PS2_CLK,
    input [15:0] sw,
    output [15:0] led,
    output audio_mclk, // master clock
    output audio_lrck, // left-right clock
    output audio_sck,  // serial clock
    output audio_sdin, // serial audio data input
    output [6:0] DISPLAY,
    output [3:0] DIGIT
);
    wire [511:0] key_down;
    wire [8:0] last_change;
    wire key_valid;
    KeyboardDecoder keydecode1(
        .key_down(key_down),
        .last_change(last_change),
        .key_valid(key_valid),
        .PS2_DATA(PS2_DATA),
        .PS2_CLK(PS2_CLK),
        .rst(rst),
        .clk(clk)
    );


    // Internal Signal
    wire [15:0] audio_in_left, audio_in_right;
    wire [11:0] ibeatNum;               // Beat counter
    wire [31:0] freqL, freqR;           // Raw frequency, produced by music module
    reg [21:0] freq_outL, freq_outR;    // Processed frequency, adapted to the clock rate of Basys3

    //clocks
    wire play_clk;    //for playing music
    wire display_clk;   //for 7 segment
    clock_divider #(.n(13)) display(.clk(clk), .clk_div(display_clk));  //7-segment display

    wire [2:0] volume, octave;
    wire play_pause;
    wire play_debounced, loop_debounced;    //loop only have debounced
    wire play_1p;
    debounce play_or_pause_de(.clk(clk), .pb(play), .pb_debounced(play_debounced));
    debounce loop_de(.clk(clk), .pb(loop), .pb_debounced(loop_debounced));
    onepulse play_or_pause_op(.clk(clk), .signal(play_debounced), .op(play_1p));


    //[in] clk, rst, play_1p
    //[out] play_pause
    play_pause_controller playPauseCtrl(
        .clk(clk),
        .rst(rst),
        .play_1p(play_1p),
        .play_or_pause(play_pause)
    );


    //debounce, onepulse inside this module
    //[in] clk, rst, speedup, speeddown
    //[out] play_clk
    speed_controller speedCtrl(
        .clk(clk),
        .rst(rst),
        .speedup(speedup),
        .speeddown(speeddown),
        .play_clk(play_clk)
    );


    //[in] clk, rst, play_pause, loop_debounced, loop_width
    //[out] beat number
    //wire [2:0] loop_width;  //3 bits
    reg [2:0] loop_width, loop_width_next;
    player_control #(.LEN(64)) playerCtrl(
        .clk(play_clk),
        .rst(rst),
        .play_pause(play_pause),
        .loop_de(loop_debounced),
        .loop_width(loop_width),
        .ibeat(ibeatNum)
    );


    //Music module
    //[in]  beat number, play_pause, sw
    //[out] left & right raw frequency, led
    music_example musicExCtrl(
        .clk(clk),
        .rst(rst),
        .ibeatNum(ibeatNum),
        .en(play_pause),
        .switch(sw),
        .toneL(freqL),
        .toneR(freqR),
        .led(led)
    );


    //[in] clk, rst, key_down, last_change, key_valid
    //[out] volume, octave
    volume_octave_controller volOctCtrl(
        .clk(clk),
        .rst(rst),
        .key_down(key_down),
        .last_change(last_change),
        .key_valid(key_valid),
        .volume(volume),
        .octave(octave)
    );


    // freq_outL, freq_outR
    // Note gen makes no sound, if freq_out = 50000000 / `silence = 1
    always @(*) begin
        freq_outL = 50000000 / freqL;
        if(octave==1) begin
            freq_outL = 50000000 / (freqL/2);
        end else if(octave==2) begin
            freq_outL = 50000000 / freqL;
        end else if(octave==3) begin
            freq_outL = 50000000 / (freqL*2);
        end
    end

    always @(*) begin
        freq_outR = 50000000 / freqR;
        if(octave==1) begin
            freq_outR = 50000000 / (freqR/2);
        end else if(octave==2) begin
            freq_outR = 50000000 / freqR;
        end else if(octave==3) begin
            freq_outR = 50000000 / (freqR*2);
        end
    end

    //[in] display_clk, volume, octave, loop_width
    //[out] DIGIT, DISPLAY
    seven_segment_controller sevenSegCtrl(
        .display_clk(display_clk),
        .volume(volume),
        .octave(octave),
        .loop_width(loop_width),
        .DIGIT(DIGIT),
        .DISPLAY(DISPLAY)
    );


    // Note generation
    // [in]  processed frequency
    // [out] audio wave signal (using square wave here)
    note_gen noteGen(
        .clk(clk), 
        .rst(rst), 
        .volume(volume),
        .note_div_left(freq_outL), 
        .note_div_right(freq_outR), 
        .audio_left(audio_in_left),     // left sound audio
        .audio_right(audio_in_right)    // right sound audio
    );


    // Speaker controller
    speaker_control speakerCtrl(
        .clk(clk), 
        .rst(rst), 
        .audio_in_left(audio_in_left),      // left channel audio data input
        .audio_in_right(audio_in_right),    // right channel audio data input
        .audio_mclk(audio_mclk),            // master clock
        .audio_lrck(audio_lrck),            // left-right clock
        .audio_sck(audio_sck),              // serial clock
        .audio_sdin(audio_sdin)             // serial audio data input
    );

    parameter [8:0] KEY_CODES[0:4] = {
        9'b0_0111_0010,	//2 => 72
		9'b0_0111_1010,	//3 => 7A
		9'b0_0110_1011,	//4 => 6B
		9'b0_0111_0011,	//5 => 73
		9'b0_0111_0100	//6 => 74
    };
    reg [2:0] key_num;
	always @ (*) begin
        case(last_change)
            KEY_CODES[0] : key_num = 3'b000;   //2
            KEY_CODES[1] : key_num = 3'b001;   //3
            KEY_CODES[2] : key_num = 3'b010;   //4
            KEY_CODES[3] : key_num = 3'b011;   //5
            KEY_CODES[4] : key_num = 3'b100;   //6
            default : key_num = 3'b111;
        endcase
    end
    
    always @(posedge clk, posedge rst) begin
		if (rst) begin
			loop_width <= 4;
		end else begin
			loop_width <= loop_width_next;
		end
	end
    always @(*) begin
		loop_width_next = loop_width;
		if(key_valid && key_down[last_change]) begin
            if(key_num!=3'b111) begin
                if(key_num == 3'b000) begin	//2
					loop_width_next = 2;
				end else if (key_num == 3'b001) begin	//3
					loop_width_next = 3;
				end else if (key_num == 3'b010) begin	//4
					loop_width_next = 4;
				end else if (key_num == 3'b011) begin	//5
					loop_width_next = 5;
				end else if (key_num == 3'b100) begin	//6
					loop_width_next = 6;
				end
			end
		end
	end
endmodule