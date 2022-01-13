module note_gen(
    clk, // clock from crystal
    rst, // active high reset
    volume, 
    note_div_left, // div for note generation
    note_div_right,
    is_noise,
    is_AM,
    speed,
    audio_left,
    audio_right
);

    // I/O declaration
    input clk; // clock from crystal
    input rst; // active low reset
    input [2:0] volume;
    input [21:0] note_div_left, note_div_right; // div for note generation
    input is_noise;
    input is_AM;
    input [1:0] speed;
    output reg [15:0] audio_left;
    output [15:0] audio_right;


    wire [3:0] random3, random2, random1, random0;
    LFSR rng3(.clk(clk), .rst(rst), .seed(4'b1010), .random(random3));
    LFSR rng2(.clk(clk), .rst(rst), .seed(4'b1110), .random(random2));
    LFSR rng1(.clk(clk), .rst(rst), .seed(4'b1111), .random(random1));
    LFSR rng0(.clk(clk), .rst(rst), .seed(4'b1100), .random(random0));

    // Declare internal signals
    reg [21:0] note_cnt, noise_cnt;
    reg note_clk, noise_clk;

    wire [31:0] noise_cnt_max = 1_0000_0000 / (random0 << 4);
    wire [31:0] noise_cnt_duty = noise_cnt_max * 250/1000; // original 125
    always @(posedge clk, posedge rst) begin
        noise_cnt <= noise_cnt + 1;
        if (rst)
            noise_cnt <= 0;
        else begin
            if (noise_cnt < noise_cnt_max) begin
                if (noise_cnt < noise_cnt_duty)
                    noise_clk <= 1; 
                else
                    noise_clk <= 0; 
            end else
                noise_cnt <= 0;
        end
    end

    wire [31:0] note_cnt_duty = note_div_left * 250/1000; //original 250
    always @(posedge clk, posedge rst) begin
        note_cnt <= note_cnt + 1;
        if (rst)
            note_cnt <= 0;
        else begin
            if (note_cnt < note_div_left) begin
                if (note_cnt < note_cnt_duty)
                    note_clk <= 1; 
                else
                    note_clk <= 0; 
            end else
                note_cnt <= 0;
        end
    end

    wire [15:0] AM_audio; 
    AM_gen AMGenInst(
        .clk(clk),
        .rst(rst),
        .speed(speed),
        .volume(volume),
        .note_div_left(note_div_left),
        .AM_audio(AM_audio)
    );

    always @(*) begin
        if(note_div_left == 22'd1) begin
            audio_left = 16'h0000;
        end else if (is_AM) begin
            audio_left = AM_audio;
        end else if (is_noise) begin
            audio_left = (noise_clk == 1'b0) ? {3'b101, random3[0], random2, random1, random0}
                                        : {3'b011, random3[0], random2, random1, random0};
        end else begin
            if(volume==1) begin
                audio_left = (note_clk == 1'b0) ? 16'hF000 : 16'h1000;
            end else if(volume==2) begin
                audio_left = (note_clk == 1'b0) ? 16'hE000 : 16'h2000;
            end else if(volume==3) begin
                audio_left = (note_clk == 1'b0) ? 16'hC000 : 16'h4000;
            end else if(volume==4) begin
                audio_left = (note_clk == 1'b0) ? 16'hB000 : 16'h5000;
            end else if(volume==5) begin
                audio_left = (note_clk == 1'b0) ? 16'hA000 : 16'h6000;
            end else begin
                audio_left = 16'h0000;
            end
        end
    end

    assign audio_right = audio_left;

endmodule