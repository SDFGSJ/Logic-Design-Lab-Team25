module note_gen(
    clk, // clock from crystal
    rst, // active high reset
    volume, 
    note_div_left, // div for note generation
    note_div_right,
    is_noise,
    audio_left,
    audio_right
);

    // I/O declaration
    input clk; // clock from crystal
    input rst; // active low reset
    input [2:0] volume;
    input [21:0] note_div_left, note_div_right; // div for note generation
    input is_noise;
    output reg [15:0] audio_left, audio_right;


    wire [3:0] random3, random2, random1, random0;
    LFSR rng3(.clk(clk), .rst(rst), .seed(4'b1010), .random(random3));
    LFSR rng2(.clk(clk), .rst(rst), .seed(4'b1110), .random(random2));
    LFSR rng1(.clk(clk), .rst(rst), .seed(4'b1111), .random(random1));
    LFSR rng0(.clk(clk), .rst(rst), .seed(4'b1100), .random(random0));

    // Declare internal signals
    reg [21:0] clk_cnt_next, clk_cnt;
    reg [21:0] clk_cnt_next_2, clk_cnt_2;
    reg [21:0] clk_cnt_noise;
    reg b_clk, b_clk_next;
    reg c_clk, c_clk_next;
    reg noise_clk;

    wire [31:0] noise_freq = 1_0000_0000 / 100;

    // Note frequency generation
    // clk_cnt, clk_cnt_2, b_clk, c_clk
    always @(posedge clk or posedge rst)
        if (rst == 1'b1)
            begin
                clk_cnt <= 22'd0;
                clk_cnt_2 <= 22'd0;
                b_clk <= 1'b0;
                c_clk <= 1'b0;
            end
        else
            begin
                clk_cnt <= clk_cnt_next;
                clk_cnt_2 <= clk_cnt_next_2;
                b_clk <= b_clk_next;
                c_clk <= c_clk_next;
            end
    
    // clk_cnt_next, b_clk_next
    always @*
        if (clk_cnt == note_div_left)
            begin
                clk_cnt_next = 22'd0;
                b_clk_next = ~b_clk;
            end
        else
            begin
                clk_cnt_next = clk_cnt + 1'b1;
                b_clk_next = b_clk;
            end

    // clk_cnt_next_2, c_clk_next
    always @*
        if (clk_cnt_2 == note_div_right)
            begin
                clk_cnt_next_2 = 22'd0;
                c_clk_next = ~c_clk;
            end
        else
            begin
                clk_cnt_next_2 = clk_cnt_2 + 1'b1;
                c_clk_next = c_clk;
            end

    wire [31:0] cnt_max = noise_freq;
    wire [31:0] cnt_duty = cnt_max * 125/1000;
    always @(posedge clk, posedge rst) begin
        clk_cnt_noise <= clk_cnt_noise + 1;
        if (rst)
            clk_cnt_noise <= 0;
        else begin
            if (clk_cnt_noise < cnt_max) begin
                if (clk_cnt_noise < cnt_duty)
                    noise_clk <= 1; 
                else
                    noise_clk <= 0; 
            end else
                clk_cnt_noise <= 0;
        end
    end
        
        

    always @(*) begin
        if(note_div_left == 22'd1) begin
            audio_left = 16'h0000;
        end else if (is_noise) begin
            //audio_left = {random3, random2, random1, random0};
            audio_left = (noise_clk == 1'b0) ? {1'b1, random3[2:0], random2, random1, random0}
                                        : {1'b0, random3[2:0], random2, random1, random0};
            // case (volume)
            //     1: audio_left = (b_clk == 1'b0) ? {4'hF, random2, random1, random0} : {4'h1, random2, random1, random0};
            //     2: audio_left = (b_clk == 1'b0) ? {4'hE, random2, random1, random0} : {4'h2, random2, random1, random0};
            //     3: audio_left = (b_clk == 1'b0) ? {4'hC, random2, random1, random0} : {4'h4, random2, random1, random0};
            //     4: audio_left = (b_clk == 1'b0) ? {4'hB, random2, random1, random0} : {4'h5, random2, random1, random0};
            //     5: audio_left = (b_clk == 1'b0) ? {4'hA, random2, random1, random0} : {4'h6, random2, random1, random0};
            //     default: audio_left = 16'h0000;
            // endcase
        end else begin
            if(volume==1) begin
                audio_left = (b_clk == 1'b0) ? 16'hF000 : 16'h1000;
            end else if(volume==2) begin
                audio_left = (b_clk == 1'b0) ? 16'hE000 : 16'h2000;
            end else if(volume==3) begin
                audio_left = (b_clk == 1'b0) ? 16'hC000 : 16'h4000;
            end else if(volume==4) begin
                audio_left = (b_clk == 1'b0) ? 16'hB000 : 16'h5000;
            end else if(volume==5) begin
                audio_left = (b_clk == 1'b0) ? 16'hA000 : 16'h6000;
            end else begin
                audio_left = 16'h0000;
            end
        end
    end

    always @(*) begin
        if(note_div_right == 22'd1) begin
            audio_right = 16'h0000;
        end else if (is_noise) begin
            audio_right = (noise_clk == 1'b0) ? {1'b1, random3[2:0], random2, random1, random0}
                                        : {1'b0, random3[2:0], random2, random1, random0};
            // case (volume)
            //     1: audio_right = (c_clk == 1'b0) ? {4'hF, random2, random1, random0} : {4'h1, random2, random1, random0};
            //     2: audio_right = (c_clk == 1'b0) ? {4'hE, random2, random1, random0} : {4'h2, random2, random1, random0};
            //     3: audio_right = (c_clk == 1'b0) ? {4'hC, random2, random1, random0} : {4'h4, random2, random1, random0};
            //     4: audio_right = (c_clk == 1'b0) ? {4'hB, random2, random1, random0} : {4'h5, random2, random1, random0};
            //     5: audio_right = (c_clk == 1'b0) ? {4'hA, random2, random1, random0} : {4'h6, random2, random1, random0};
            //     default: audio_right = 16'h0000;
            // endcase
        end else begin
            if(volume==1) begin
                audio_right = (c_clk == 1'b0) ? 16'hF000 : 16'h1000;
            end else if(volume==2) begin
                audio_right = (c_clk == 1'b0) ? 16'hE000 : 16'h2000;
            end else if(volume==3) begin
                audio_right = (c_clk == 1'b0) ? 16'hC000 : 16'h4000;
            end else if(volume==4) begin
                audio_right = (c_clk == 1'b0) ? 16'hB000 : 16'h5000;
            end else if(volume==5) begin
                audio_right = (c_clk == 1'b0) ? 16'hA000 : 16'h6000;
            end else begin
                audio_right = 16'h0000;
            end
        end
    end
endmodule