module AM_gen (
    input clk,
    input rst,
    input [1:0] speed,
    input [2:0] volume,
    output reg [15:0] AM_audio
);

reg [15:0] next_AM_audio, AM_audio_abs;
reg [31:0] cnt;
wire [31:0] cnt_max = ((speed == 2'd1) ? (1<<22) >> 1 : (1<<21) >> 1) << 2;
reg up;
reg [31:0] vol_step = 1;

always @(posedge clk, posedge rst) begin
    if (rst) begin
        cnt <= 0;
        AM_audio <= vol_step;
        up <= 1;
    end else begin
        cnt <= cnt + 1;
        
        AM_audio <= next_AM_audio;
        if (cnt == cnt_max) begin
            up <= ~up;
            cnt <= 0;
        end
    end
end

always @(*) begin
    if (up == 1) begin
        if (cnt % 2 == 0)
            next_AM_audio = AM_audio | (1<<15);
        else begin
            case (volume)
                3'd1: begin
                    if ((AM_audio ^ (1<<15)) + vol_step > 16'h1000)
                        next_AM_audio = 16'h1000;
                    else
                        next_AM_audio = (AM_audio ^ (1<<15)) + vol_step;
                end
                3'd2: begin
                    if ((AM_audio ^ (1<<15)) + vol_step > 16'h2000)
                        next_AM_audio = 16'h2000;
                    else
                        next_AM_audio = (AM_audio ^ (1<<15)) + vol_step;
                end
                3'd3: begin
                    if ((AM_audio ^ (1<<15)) + vol_step > 16'h4000)
                        next_AM_audio = 16'h4000;
                    else
                        next_AM_audio = (AM_audio ^ (1<<15)) + vol_step;
                end
                3'd4: begin
                    if ((AM_audio ^ (1<<15)) + vol_step > 16'h5000)
                        next_AM_audio = 16'h5000;
                    else
                        next_AM_audio = (AM_audio ^ (1<<15)) + vol_step;
                end
                3'd5: begin
                    if ((AM_audio ^ (1<<15)) + vol_step > 16'h6000)
                        next_AM_audio = 16'h6000;
                    else
                        next_AM_audio = (AM_audio ^ (1<<15)) + vol_step;
                end
                default: next_AM_audio = AM_audio;
            endcase
        end
    end else begin
        if (cnt % 2 == 0)
            next_AM_audio = (AM_audio | (1<<15));
        else begin
            if ((AM_audio ^ (1<<15)) - vol_step < 1)
                next_AM_audio = 1;
            else
                next_AM_audio = (AM_audio ^ (1<<15)) - vol_step;
        end
    end
end
    
endmodule