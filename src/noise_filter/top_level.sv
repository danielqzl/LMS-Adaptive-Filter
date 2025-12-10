module noise_filter_ip #(
    parameter N_TAPS = 4,
    parameter CLK_CYCLE = 128,
    parameter STEP_SIZE = 655,
    parameter DRP_ADDR_D = 7'h10,
    parameter DRP_ADDR_N = 7'h11
)(
    input  logic clk, rst_n,
    
    input  logic lms_en,
    output logic signed [15:0] out_s,
    output logic out_valid,

    drp_if.master drp_d,
    drp_if.master drp_n
);

    // ----------------------------------------------------
    // Clock Enable 
    // ----------------------------------------------------
    logic [15:0] clk_cntr;
    logic clk_en, clk_en_d1;
    always_ff @(posedge clk) begin : u_clk_cntr
        if (!rst_n) begin
            clk_en <= 1'b0;
            clk_cntr <= '0;
        end else if (clk_cntr == CLK_CYCLE - 1) begin
            clk_en <= 1'b1;
            clk_cntr <= '0;
        end else begin 
            clk_en <= 1'b0;
            clk_cntr <= clk_cntr + 1;
        end
    end


    logic signed [15:0] d;
    logic signed [15:0] n;

    noise_filter #(
        .N(N_TAPS), 
        .DATA_WIDTH(16)
    ) u_filter  (
        .clk(clk), 
        .rst_n(rst_n),
        .lms_en(lms_en), 
        .clk_en(clk_en),
        .step_size(STEP_SIZE),
        .d(d), 
        .ref_s(n),    
        .out(out_s)
    );


    preprocess #(
        .DRP_ADDR(DRP_ADDR_D)
    ) u_prep_d (
        .clk(clk),  .rst_n(rst_n), 
        .clk_en(clk_en),
        .out(d),
        .drp(drp_d)
    );

    preprocess  #(
        .DRP_ADDR(DRP_ADDR_N)
    ) u_prep_n (
        .clk(clk),  .rst_n(rst_n), 
        .clk_en(clk_en),
        .out(n),
        .drp(drp_n)
    );

    // output 
    always_ff @(posedge clk) clk_en_d1 <= clk_en;
    
    assign out_valid = clk_en_d1;

endmodule
