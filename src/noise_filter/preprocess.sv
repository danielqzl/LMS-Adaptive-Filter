

module preprocess #(
    parameter DRP_ADDR = 7'h10
)(
    input  logic clk, rst_n, clk_en,
    output logic signed [15:0] out,
    drp_if.master drp
);

    // Internal Signals 
    logic drp_data_rdy;
    logic [15:0] drp_data;
    logic q_empty, q_full;
    logic [15:0] q_out;

    // drp_transceiver
    drp_transceiver u_drp (
        .clk(clk),  .rst_n(rst_n), 
        .clk_en(clk_en),
        .rd_req(~q_full),
        .addr(DRP_ADDR),
        .rd_data_rdy(drp_data_rdy),
        .rd_data(drp_data),
        .wr_en(1'b0), 
        .wr_data('0),
        .drp(drp)
    );

    sync_fifo #(
        .DEPTH(4), 
        .WIDTH(16)
    ) u_buffer (
        .clk(clk), .rst_n(rst_n),
        .clr(1'b0), .clk_en(clk_en),

        .wr_en(drp_data_rdy), 
        .wr_data(drp_data),
        .full(q_full),

        .rd_en(~q_empty),
        .rd_data(q_out),
        .empty(q_empty)
    );

    adc_to_q15 u_convert (
        .clk(clk), .rst_n(rst_n),
        .clk_en(clk_en),
        .adc_in(q_out[11:0]),
        .out(out)
    );

endmodule


module adc_to_q15 (
    input  logic clk, rst_n, clk_en,
    input  logic [11:0] adc_in,
    output logic signed [15:0] out 
);

    logic signed [15:0] q_15;

    // Convert ADC to signed centered at 0 (-2048 -> +2047)
    logic signed [12:0] adc_signed;
    assign adc_signed = $signed({1'b0, adc_in}) - 13'sd2048;

    // Scale to Q1.15:
    // adc_signed range: 2047 -> 1.0 in Q1.15
    // q15 = adc_signed / 2047 * 32767 = adc_signed * 16
    always_comb begin
        if (adc_signed == -16'sd2048)
            q_15 = -16'sd32768;
        else
            q_15 = adc_signed <<< 4; // multiply by 16
    end
    

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            out <= '0;
        end else if (clk_en) begin
            out <= q_15; 
        end
    end

endmodule