module noise_decider (
    input [11:0] ibeatNum,
    output reg is_noise
);

always @(*) begin
    if (ibeatNum < 4)
        is_noise = 1;
    else if (ibeatNum < 8)
        is_noise = 1;
    else if (ibeatNum < 12)
        is_noise = 1;
    else if (ibeatNum < 16)
        is_noise = 1;
    else if (ibeatNum < 20)
        is_noise = 0;
    else if (ibeatNum < 24)
        is_noise = 0;
    else if (ibeatNum < 28)
        is_noise = 0;
    else if (ibeatNum < 32)
        is_noise = 0;
    else if (ibeatNum < 36)
        is_noise = 1;
    else if (ibeatNum < 40)
        is_noise = 1;
    else if (ibeatNum < 44)
        is_noise = 1;
    else if (ibeatNum < 48)
        is_noise = 1;
    else if (ibeatNum < 52)
        is_noise = 1;
    else if (ibeatNum < 56)
        is_noise = 1;
    else if (ibeatNum < 60)
        is_noise = 1;
    else if (ibeatNum < 64)
        is_noise = 1;
    else
        is_noise = 0;
end
    
endmodule