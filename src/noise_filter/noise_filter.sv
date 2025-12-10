module noise_filter #(
    parameter N = 10,
    parameter DATA_WIDTH = 16
)(
    input  logic clk, rst_n,
    input  logic lms_en, clk_en,
    input  logic signed [DATA_WIDTH-1:0] step_size,
    input  logic signed [DATA_WIDTH-1:0] d,   // input signal (signal + noise) 
    input  logic signed [DATA_WIDTH-1:0] ref_s,       // reference signal (noise)
    output logic signed [DATA_WIDTH-1:0] out     // output signal  
);

    logic signed [DATA_WIDTH-1:0] w [N];  // weights 
    logic signed [DATA_WIDTH-1:0] x_lms;  // reference signal (delayed)
    logic signed [DATA_WIDTH-1:0] e;      // error 
    logic signed [DATA_WIDTH-1:0] y;      // filter output 
    logic signed [DATA_WIDTH-1:0] ref_d;  // delayed input for lms 

    fir 
    //fir_mac
    #(
        .N(N),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_filter (
        .clk(clk), .rst_n(rst_n), 
        .en(clk_en),
        .x_in(ref_s),
        .weights(w),
        .y(y)
    );

    lms #(
        .N(N),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_lms (
        .clk(clk), .rst_n(rst_n), 
        .clk_en(clk_en),
        .enable(lms_en),
        .step_size(step_size),
        .e(e),
        .x_in(x_lms),
        .weights(w)
    );

    assign x_lms = ref_s;
    
    
    always_ff @(posedge clk)begin
        if (!rst_n) 
            e <= '0;
        else if (clk_en)
            e <= d - y;
    end
    
    assign out = e;

endmodule

